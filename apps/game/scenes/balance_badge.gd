class_name BalanceBadge
extends MarginContainer
## 残高を桁区切りの数値で出す、白い丸バッジ。下へずらした同形の面を影として敷く。
##
## 中身（飴玉のアイコン・数値・単位）は子の Container が並べ、バッジの大きさは中身に合わせて決まる。

## [method bounce] で一番大きくなったときの拡大率。
const BOUNCE_SCALE: float = 1.08
## [method bounce] で大きくなってから戻るまでの長さ（秒）。
const BOUNCE_DURATION: float = 0.24

## バッジの面の色。
@export var body_color: Color = Color.WHITE
## 影の面の色。
@export var shadow_color: Color = Color.BLACK
## 影の面を下へずらす距離（px）。
@export var shadow_offset: float = 10.0

## 面を描く StyleBox。
var _body_style: StyleBoxFlat = null
## 影を描く StyleBox。
var _shadow_style: StyleBoxFlat = null
## [method bounce] の Tween。弾んでいないときは null。
var _bounce_tween: Tween = null

## 残高の数値を出す Label。
@onready var _amount_label: Label = %AmountLabel


## 面と影の StyleBox を作る。
func _ready() -> void:
	_body_style = _make_pill_style(body_color)
	_shadow_style = _make_pill_style(shadow_color)


## 残高 [param balance] を桁区切りにして出す。
func show_balance(balance: int) -> void:
	_amount_label.text = format_count(balance)


## バッジを少し大きくしてから元の大きさに戻す。続けて呼ばれたら最初から弾み直す。
func bounce() -> void:
	if _bounce_tween != null:
		_bounce_tween.kill()
	pivot_offset = size / 2.0
	scale = Vector2.ONE
	_bounce_tween = create_tween()
	_bounce_tween.set_trans(Tween.TRANS_SINE)
	_bounce_tween.tween_property(self, "scale", Vector2.ONE * BOUNCE_SCALE, BOUNCE_DURATION / 2.0).set_ease(Tween.EASE_OUT)
	_bounce_tween.tween_property(self, "scale", Vector2.ONE, BOUNCE_DURATION / 2.0).set_ease(Tween.EASE_IN)
	_bounce_tween.finished.connect(func() -> void: _bounce_tween = null)


## 獲得の演出が飛んでいく先として、残高の数値の中心を global 座標で返す。
func get_gain_target() -> Vector2:
	return _amount_label.get_global_rect().get_center()


## [param value] を 3 桁ごとに「,」で区切った 10 進表記にして返す。負の値には先頭に「-」を付ける。
static func format_count(value: int) -> String:
	# 符号と数字を分ける。int64 の最小値は absi で正にできないので、文字列で分ける
	var digits: String = str(value)
	var sign_text: String = ""
	if digits.begins_with("-"):
		sign_text = "-"
		digits = digits.substr(1)

	# 末尾から 3 桁ごとに区切りを入れる
	var grouped: String = ""
	for i: int in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0:
			grouped += ","
		grouped += digits[i]
	return sign_text + grouped


## 影の面を下へずらして描き、その上にバッジの面を描く。
func _draw() -> void:
	draw_style_box(_shadow_style, Rect2(Vector2(0.0, shadow_offset), size))
	draw_style_box(_body_style, Rect2(Vector2.ZERO, size))


## 色 [param fill_color] で塗り、両端を半円にする StyleBox を作って返す。
static func _make_pill_style(fill_color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill_color
	# バッジの高さはフォントの行の高さで決まって固定できないので、どの高さより大きい角丸にして常に両端を半円にする
	style.set_corner_radius_all(9999)
	return style
