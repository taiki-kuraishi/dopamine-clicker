class_name DopamineState
extends RefCounted
## ドーパミンの残高と累計獲得を持ち、クリックでの獲得とセーブ文字列との相互変換を行う。
##
## ファイルへの読み書きは持たない。セーブ文字列をどこに保存するかは呼び出し側が決める。

## [member balance] が変わったときに emit される。[param balance] は変わった後の残高。
signal balance_changed(balance: int)

## 1 回のクリックで獲得するドーパミンの量。
const GAIN_PER_CLICK: int = 1
## [method to_save_string] が書き出し、[method from_save_string] が受け付けるセーブ形式の version。
const SAVE_VERSION: int = 1
## int64 の最大値の 10 進表記。セーブ文字列の件数が int64 に収まるかの判定に使う。
const _INT64_MAX_TEXT: String = "9223372036854775807"
## [method _parse_count] が件数を読めなかったことを表す戻り値。件数は負にならないので負の値を使う。
const _INVALID_COUNT: int = -1

## セーブ文字列の件数として受け付ける 10 進表記（符号なし・先頭 0 なし・19 桁まで）。
static var _count_pattern: RegEx = RegEx.create_from_string("^(0|[1-9][0-9]{0,18})\\z")

## 今持っているドーパミンの量。
var balance: int = 0
## これまでに獲得したドーパミンの合計。[member balance] 以上の値になる。
var total_earned: int = 0


## [constant GAIN_PER_CLICK] だけドーパミンを獲得し、[member balance] と [member total_earned] に足す。
## 足した後に [signal balance_changed] を emit する。[br]
## 戻り値は獲得した量。
func click() -> int:
	balance += GAIN_PER_CLICK
	total_earned += GAIN_PER_CLICK
	balance_changed.emit(balance)
	return GAIN_PER_CLICK


## 状態を、[constant SAVE_VERSION] 付きの JSON のセーブ文字列にして返す。
## [method from_save_string] に渡すと同じ状態に戻る。
func to_save_string() -> String:
	# Godot の JSON は数値を float で読み、2^53 を超える int が丸まるので、件数は 10 進文字列で保存する
	return JSON.stringify({
		"version": SAVE_VERSION,
		"balance": str(balance),
		"total_earned": str(total_earned),
	})


## [method to_save_string] が作ったセーブ文字列 [param text] から状態を作って返す。[br]
## 次のどれかに当たるときは [code]null[/code] を返す。[br]
## - JSON として読めない、または中身がオブジェクトでない[br]
## - version が [constant SAVE_VERSION] でない[br]
## - 残高・累計獲得が欠けている、または int64 に収まる 0 以上の 10 進文字列でない[br]
## - 残高が累計獲得より大きい
static func from_save_string(text: String) -> DopamineState:
	# JSON として読み、オブジェクトでなければ壊れた文字列として扱う
	var json: JSON = JSON.new()
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return null
	var data: Dictionary = json.data

	# 知らない version のセーブは読まない
	var version: Variant = data.get("version")
	if typeof(version) != TYPE_FLOAT or version != SAVE_VERSION:
		return null

	# 件数を読み、読めないものと残高が累計獲得を超えるものは壊れているとみなす
	var balance_value: int = _parse_count(data.get("balance"))
	var total_earned_value: int = _parse_count(data.get("total_earned"))
	if balance_value == _INVALID_COUNT or total_earned_value == _INVALID_COUNT:
		return null
	if balance_value > total_earned_value:
		return null

	# 読めた件数で状態を作る
	var state: DopamineState = DopamineState.new()
	state.balance = balance_value
	state.total_earned = total_earned_value
	return state


## セーブ文字列の件数 [param value] を int にして返す。
## 文字列でない、または int64 に収まる 0 以上の 10 進表記でないときは [constant _INVALID_COUNT] を返す。
static func _parse_count(value: Variant) -> int:
	# 10 進表記の文字列だけを受け付ける
	if typeof(value) != TYPE_STRING:
		return _INVALID_COUNT
	var text: String = value
	if _count_pattern.search(text) == null:
		return _INVALID_COUNT

	# String.to_int は int64 を超える 19 桁の値を黙って桁あふれさせるので、先に比べて弾く
	if text.length() == _INT64_MAX_TEXT.length() and text > _INT64_MAX_TEXT:
		return _INVALID_COUNT
	return text.to_int()
