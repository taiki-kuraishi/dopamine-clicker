@abstract
class_name GameGateway
extends RefCounted
## ゲームの窓口。ドーパミンの状態の正を持ち、[GameState] からの問い合わせに非同期で答える。
##
## 実装を差し替えて使う（今はローカルの [LocalGameGateway] だけ）。失敗は返さず、実装の中で扱う。[br]
## [method start] を await し終えてから [method click]・[method finish] を呼ぶ。
## 呼び出し側は、どのメソッドも await して呼ぶ（実装が coroutine でなくてもよい）。


## [method GameGateway.click] の結果。
class ClickResult extends RefCounted:
	## 今回獲得したドーパミンの量。
	var gained: int = 0
	## 獲得した後の残高。
	var balance: int = 0

	## 獲得量 [param p_gained] と獲得後の残高 [param p_balance] で結果を作る。
	func _init(p_gained: int, p_balance: int) -> void:
		gained = p_gained
		balance = p_balance


## 窓口を使い始め、今の残高を返す。
@abstract func start() -> int


## 1 回クリックしたことを伝え、獲得量と獲得後の残高を返す。null は返さない。
@abstract func click() -> ClickResult


## ゲームを終えることを伝える。終える前に残しておくべきものを残す。呼び出し側はこれを await し終えてからゲームを終了する。
@abstract func finish() -> void
