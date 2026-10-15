class_name DeferredGameGateway
extends GameGateway
## テスト用の窓口。[method start] は [method release_start] を、[method click] は [method release_click] を、
## [method finish] は [method release_finish] を呼ぶまで終わらない。読み込み前・クリックの送り中・終える途中の
## 振る舞いのテストに使う。

## [method release_start] で emit され、待っている [method start] を終わらせる。
signal _start_released()
## [method release_click] で emit され、待っている [method click] を終わらせる。
signal _click_released()
## [method release_finish] で emit され、待っている [method finish] を終わらせる。
signal _finish_released()

## [method click] が呼ばれた回数。
var click_count: int = 0
## [method finish] が呼ばれた回数。
var finish_count: int = 0

## 今の残高。
var _balance: int = 0


## [method start] が返す残高 [param balance] で窓口を作る。
func _init(balance: int) -> void:
	_balance = balance


## 待っている [method start] を終わらせる。
func release_start() -> void:
	_start_released.emit()


## 待っている [method click] を終わらせる。
func release_click() -> void:
	_click_released.emit()


## 待っている [method finish] を終わらせる。
func release_finish() -> void:
	_finish_released.emit()


## [method release_start] が呼ばれるまで待ち、作ったときの残高を返す。
func start() -> int:
	await _start_released
	return _balance


## 呼ばれた回数を数え、[method release_click] が呼ばれるまで待ってから、1 だけ獲得して獲得量と獲得後の残高を返す。
func click() -> GameGateway.ClickResult:
	click_count += 1
	await _click_released
	_balance += 1
	return GameGateway.ClickResult.new(1, _balance)


## 呼ばれた回数を数え、[method release_finish] が呼ばれるまで待つ。
func finish() -> void:
	finish_count += 1
	await _finish_released
