class_name GameState
extends Node
## ゲーム全体で 1 つのゲームの状態。Autoload の [code]Game[/code] として登録する。
##
## 状態の正は [GameGateway] が持ち、ここは窓口に問い合わせた結果を持って signal で画面に知らせる。[br]
## 画面は接続するときに [member is_loaded] が true なら [member balance] を出し、まだなら [signal balance_changed]
## か [signal loaded] を待つ。読み込みはほかの scene より先に終わりうるので、signal だけでは渡さない。[br]
## クリックは 1 回ずつ順に窓口へ送る。送り中に押されたクリックは回数を待ち行列に積み、前の結果を受け取ってから送る。
## 結果は送った順にしか返ってこないので、残高は巻き戻らない。窓口を差し替えたら待ち行列は捨てる。
## ウィンドウを閉じる要求を受けたら、それ以降のクリックは受け付けず、待ち行列を送り終えてから窓口を終える。

## 残高が変わったときに emit される。[param balance] は変わった後の残高。読み込みを終えたときにも emit される。
signal balance_changed(balance: int)
## クリックでドーパミンを獲得したときに emit される。[param amount] は獲得した量。
signal gained(amount: int)
## 窓口の [method GameGateway.start] を終え、[member balance] が読み込んだ残高になったときに emit される。
signal loaded()
## 待ち行列のクリックを送り終えたとき、または窓口の差し替えで待ち行列を捨てたときに emit される。
signal _clicks_drained()

## 今の残高。[member is_loaded] が false の間は、前の窓口の残高か 0 のまま。
var balance: int:
	get:
		return _balance
## 今の窓口の [method GameGateway.start] を終えていれば true。
var is_loaded: bool:
	get:
		return _loaded
## ゲームを終える Callable。既定は SceneTree の quit。テストで差し替え、test runner ごと終わらないようにする。
var quit_game: Callable = _quit_tree

## 今の窓口。[method start] で差し替える。
var _gateway: GameGateway = null
## 今の残高。
var _balance: int = 0
## 今の窓口の読み込みを終えたとき true。
var _loaded: bool = false
## ウィンドウを閉じる要求を受けて、終える処理に入ったとき true。
var _closing: bool = false
## 窓口へまだ送っていないクリックの回数。
var _pending_clicks: int = 0
## クリックを窓口へ送っている途中（結果の await 中を含む）のとき true。
var _sending: bool = false


## 閉じる要求で窓口を終えてから終了できるよう、SceneTree の自動終了を止め、
## user://save.json に読み書きするローカルの窓口で始める。
func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	start(LocalGameGateway.new())


## ウィンドウを閉じる要求で、ゲームを終える。
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_close()


## 窓口を [param gateway] に差し替え、その [method GameGateway.start] を await して残高を読み込む。
## 差し替え前の窓口は終えず、まだ送っていないクリックは捨て、送り中のクリックの結果も捨てる。
## await の間にさらに差し替えられたら、読んだ残高は捨てる。[br]
## emit: [signal balance_changed]（読み込んだ残高）、続けて [signal loaded]
func start(gateway: GameGateway) -> void:
	# 読み込み中にし、前の窓口へのクリックの待ち行列を捨てる
	_gateway = gateway
	_loaded = false
	_pending_clicks = 0
	if _sending:
		_sending = false
		_clicks_drained.emit()

	# 窓口を始めて残高を受け取る。実装が coroutine かは基底の型からは分からないので、await 不要の warning を抑える
	@warning_ignore("redundant_await")
	var started_balance: int = await gateway.start()
	if gateway != _gateway:
		return

	# 読み込んだ残高にして知らせる
	_balance = started_balance
	_loaded = true
	balance_changed.emit(_balance)
	loaded.emit()


## 1 回クリックしたことを待ち行列に積み、送り中でなければ待ち行列が空になるまで 1 回ずつ窓口に送る。
## 1 回ごとに結果を await して残高を更新する。読み込みを終える前と、閉じる要求を受けた後は何もしない。
## await の間に窓口が差し替えられたら、結果は捨てて送るのをやめる。[br]
## emit: 1 回ごとに [signal balance_changed]（獲得後の残高）、続けて [signal gained]（獲得量）。
## 送り終えたら [signal _clicks_drained]
func click() -> void:
	if not _loaded or _closing:
		return

	# 押した回数を積み、送り中ならその送りに任せる
	_pending_clicks += 1
	if _sending:
		return
	_sending = true

	# 待ち行列が空になるまで、前の結果を受け取ってから次を送る。実装が coroutine かは基底の型からは分からないので、
	# await 不要の warning を抑える
	var gateway: GameGateway = _gateway
	while _pending_clicks > 0:
		_pending_clicks -= 1
		@warning_ignore("redundant_await")
		var result: GameGateway.ClickResult = await gateway.click()
		if gateway != _gateway:
			return
		_balance = result.balance
		balance_changed.emit(_balance)
		gained.emit(result.gained)

	# 送り終えたことを知らせる
	_sending = false
	_clicks_drained.emit()


## 待ち行列のクリックを送り終えるまで待ち、読み込みを終えていれば窓口の [method GameGateway.finish] を await してから
## [member quit_game] を呼ぶ。読み込み前なら窓口を終えずに [member quit_game] を呼ぶ。2 回目以降の呼び出しでは何もしない。
func _close() -> void:
	if _closing:
		return
	_closing = true

	# 押した分を窓口に送り終えるまで待つ
	while _sending:
		await _clicks_drained

	# 窓口が残すものを残し終えるまで待つ。実装が coroutine かは基底の型からは分からないので、await 不要の warning を抑える
	if _loaded:
		@warning_ignore("redundant_await")
		await _gateway.finish()

	# 終える
	quit_game.call()


## SceneTree を終了する。[member quit_game] の既定。
func _quit_tree() -> void:
	get_tree().quit()
