class_name LocalGameGateway
extends GameGateway
## 手元で完結するゲームの窓口。core の [DopamineState] を中で動かし、セーブファイルに読み書きする。
##
## [method start] でセーブを読み、無い・壊れているときは 0 から始める（壊れたファイルは退避せず、次の保存で上書きする）。
## [method finish] と、最後の保存から [constant AUTOSAVE_INTERVAL_MSEC] 以上たったあとの [method click] で保存する。
## 書けなかったときは push_warning を出すだけで続ける。セーブの形式は [method DopamineState.to_save_string] と
## [method DopamineState.from_save_string] に任せる。

## セーブファイルの既定の保存先。
const DEFAULT_SAVE_PATH: String = "user://save.json"
## クリックで保存するまでに、最後の保存から空ける時間（ミリ秒）。
const AUTOSAVE_INTERVAL_MSEC: int = 10000

## セーブファイルの保存先。
var _save_path: String = DEFAULT_SAVE_PATH
## 今の時刻をミリ秒の int で返す Callable。保存の時機の判定に使う。
var _clock: Callable = Time.get_ticks_msec
## 今のドーパミンの状態。[method start] でセーブから作る。
var _state: DopamineState = null
## 最後に保存を試みた時刻（[member _clock] のミリ秒）。まだ保存していなければ [method start] でセーブを読んだ時刻。
var _last_saved_msec: int = 0


## 保存先 [param save_path] と、今の時刻をミリ秒の int で返す [param clock] で窓口を作る。
## テストでは一時ディレクトリの保存先と、決めた時刻を返す Callable に差し替える。
func _init(save_path: String = DEFAULT_SAVE_PATH, clock: Callable = Time.get_ticks_msec) -> void:
	_save_path = save_path
	_clock = clock


## セーブから状態を作り、読んだ時刻を保存の時機の基準にして、残高を返す。
func start() -> int:
	_state = _load_state()
	_last_saved_msec = _clock.call()
	return _state.balance


## ドーパミンを獲得し、最後の保存から [constant AUTOSAVE_INTERVAL_MSEC] 以上たっていれば保存する。
## 獲得量と獲得後の残高を返す。null は返さない。
func click() -> GameGateway.ClickResult:
	# 獲得する
	var gained: int = _state.click()

	# 間隔があいていれば保存する
	var now_msec: int = _clock.call()
	if now_msec - _last_saved_msec >= AUTOSAVE_INTERVAL_MSEC:
		_save()
	return GameGateway.ClickResult.new(gained, _state.balance)


## 終える前に保存する。
func finish() -> void:
	_save()


## [member _save_path] のセーブから状態を作って返す。
## セーブが無い、または壊れていて読めないときは 0 の状態を返す。null は返さない。
func _load_state() -> DopamineState:
	# セーブが無ければ 0 から始める
	if not FileAccess.file_exists(_save_path):
		return DopamineState.new()

	# 読めないセーブは退避せず、0 から始めて次の保存で上書きする
	var state: DopamineState = DopamineState.from_save_string(FileAccess.get_file_as_string(_save_path))
	if state == null:
		return DopamineState.new()
	return state


## 状態をセーブ文字列にして [member _save_path] に書き、試みた時刻を [member _last_saved_msec] にする。
## 書けなかったときは push_warning を出すだけで続ける。
func _save() -> void:
	# 書けなくても次に試すのは間隔をあけてからにする
	_last_saved_msec = _clock.call()

	# ファイルを開いて書き、失敗したら警告だけ出す
	var file: FileAccess = FileAccess.open(_save_path, FileAccess.WRITE)
	if file == null:
		push_warning("セーブファイルを開けませんでした: %s (%s)" % [_save_path, error_string(FileAccess.get_open_error())])
		return
	if not file.store_string(_state.to_save_string()):
		push_warning("セーブファイルに書けませんでした: %s (%s)" % [_save_path, error_string(file.get_error())])
