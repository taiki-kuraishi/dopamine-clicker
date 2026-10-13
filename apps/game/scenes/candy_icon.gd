class_name CandyIcon
extends Control
## 残高の横に置く飴玉のアイコン。玉の丸に、左上のハイライトの丸を重ねて描く。
##
## 絵文字はフォントによって崩れるので、丸の重ね置きで描く。座標は 52px 四方の枠で決め、大きさに合わせて伸縮する。

## 図形の座標を決めている枠の一辺（px）。
const _VIEW_SIZE: float = 52.0
## 玉の中心（枠の座標）。
const _BODY_CENTER: Vector2 = Vector2(26.0, 26.0)
## 玉の半径（枠の座標）。
const _BODY_RADIUS: float = 20.0
## ハイライトの中心（枠の座標）。
const _HIGHLIGHT_CENTER: Vector2 = Vector2(18.0, 18.0)
## ハイライトの半径（枠の座標）。
const _HIGHLIGHT_RADIUS: float = 6.0

## 玉の色。
@export var body_color: Color = Color("f76f8b")
## ハイライトの色。
@export var highlight_color: Color = Color.WHITE


## 玉とハイライトの丸を、大きさに合わせて描く。
func _draw() -> void:
	var unit: float = minf(size.x, size.y) / _VIEW_SIZE
	draw_circle(_BODY_CENTER * unit, _BODY_RADIUS * unit, body_color, true, -1.0, true)
	draw_circle(_HIGHLIGHT_CENTER * unit, _HIGHLIGHT_RADIUS * unit, highlight_color, true, -1.0, true)
