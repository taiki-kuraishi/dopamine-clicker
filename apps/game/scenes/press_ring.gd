class_name PressRing
extends Control
## カードをクリックした位置に出る白い輪。少し広がりながら消え、消えたら自分を解放する。
##
## 自分の原点を輪の中心にして描くので、[member Control.position] をクリックした位置に置いて使う。

## 輪の外側の半径（px）。
const OUTER_RADIUS: float = 52.0
## 輪の太さ（px）。
const RING_WIDTH: float = 6.0
## 輪の色。
const RING_COLOR: Color = Color.WHITE
## 影を下へずらす距離（px）。
const SHADOW_OFFSET: float = 8.0
## 影の色。
const SHADOW_COLOR: Color = Color("241c33", 0.14)
## 出た瞬間の大きさ（最後の大きさに対する比）。
const START_SCALE: float = 0.7
## 出てから消えるまでの長さ（秒）。
const DURATION: float = 0.6
## 消え始めるまでの長さ（秒）。
const FADE_DELAY: float = 0.3
## 輪と影の弧を折れ線にするときの分割数。
const _ARC_SEGMENTS: int = 48


## 広がりながら消える Tween を始め、終わったら自分を解放する。
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	scale = Vector2.ONE * START_SCALE
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2.ONE, DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, DURATION - FADE_DELAY).set_delay(FADE_DELAY)
	tween.finished.connect(queue_free)


## 影と輪を描く。
func _draw() -> void:
	draw_colored_polygon(_shadow_polygon(), SHADOW_COLOR)
	draw_arc(Vector2.ZERO, OUTER_RADIUS - RING_WIDTH / 2.0, 0.0, TAU, _ARC_SEGMENTS, RING_COLOR, RING_WIDTH, true)


## 影の形を返す。輪の外形を下へずらした円のうち、輪の外形からはみ出る下側の三日月。
func _shadow_polygon() -> PackedVector2Array:
	# 2 つの円の交点は、中心どうしの中間の高さにある
	var half_chord: float = sqrt(OUTER_RADIUS * OUTER_RADIUS - SHADOW_OFFSET * SHADOW_OFFSET / 4.0)
	var shifted_center: Vector2 = Vector2(0.0, SHADOW_OFFSET)
	var shifted_from: float = atan2(-SHADOW_OFFSET / 2.0, half_chord)
	var outline_from: float = atan2(SHADOW_OFFSET / 2.0, half_chord)

	# ずらした円の下側を右の交点から左の交点へ、輪の外形の下側を左の交点の次から右の交点の手前へたどる
	var points: PackedVector2Array = PackedVector2Array()
	for step: int in _ARC_SEGMENTS + 1:
		var angle: float = lerpf(shifted_from, PI - shifted_from, float(step) / _ARC_SEGMENTS)
		points.append(shifted_center + Vector2.from_angle(angle) * OUTER_RADIUS)
	for step: int in range(1, _ARC_SEGMENTS):
		var angle: float = lerpf(PI - outline_from, outline_from, float(step) / _ARC_SEGMENTS)
		points.append(Vector2.from_angle(angle) * OUTER_RADIUS)
	return points
