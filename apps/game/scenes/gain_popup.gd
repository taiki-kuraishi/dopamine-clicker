class_name GainPopup
extends Control
## 「+獲得量」の文字。始点から終点へ山なりに飛び、通った跡に丸い点をこぼす。点が消えたら自分を解放する。
##
## 自分の原点を始点・終点の座標の原点にして描くので、親と同じ座標になるように原点に置いて使う。

## 文字が終点に着いたときに emit される。
signal arrived()

## 始点から終点まで飛ぶ長さ（秒）。
const FLIGHT_DURATION: float = 0.7
## 点をこぼす間隔（px）。
const DOT_SPACING: float = 23.0
## 点の半径（px）。
const DOT_RADIUS: float = 4.5
## 点の色。こぼした直後の不透明度もこの色で決まる。
const DOT_COLOR: Color = Color("241c33", 0.32)
## こぼした点が消えるまでの長さ（秒）。
const DOT_LIFETIME: float = 0.5
## 山なりの軌跡の制御点の、始点から終点への横の比。案 B の軌跡（M640,520 Q420,462 250,240）から取った。
const ARC_CONTROL_X_RATIO: float = 0.56
## 山なりの軌跡の制御点の、始点から終点への縦の比。案 B の軌跡から取った。
const ARC_CONTROL_Y_RATIO: float = 0.2

## 飛び始めた位置。
var _start: Vector2 = Vector2.ZERO
## 着く位置を返す Callable。着く先はレイアウトや弾みで動くので、毎フレーム問い合わせる。
var _target: Callable = Callable()
## [method launch] からの経過時間（秒）。
var _elapsed: float = 0.0
## 文字が終点に着いたら true。
var _has_arrived: bool = false
## こぼした点の位置。
var _dot_positions: PackedVector2Array = PackedVector2Array()
## こぼした点ごとの、こぼした時点の [member _elapsed]。
var _dot_times: PackedFloat32Array = PackedFloat32Array()
## 最後に点をこぼした位置。
var _last_dot_position: Vector2 = Vector2.ZERO

## 「+獲得量」を出す Label。
@onready var _amount_label: Label = $AmountLabel


## 獲得量 [param amount] を「+獲得量」として、[param from] から飛ばし始める。
## [param target] は引数なしで着く位置（[Vector2]）を返す Callable で、飛んでいる間は毎フレーム呼ぶ。
func launch(amount: int, from: Vector2, target: Callable) -> void:
	_start = from
	_target = target

	# 文字を始点に置き、始点に最初の点をこぼす
	_amount_label.text = "+%d" % amount
	_amount_label.reset_size()
	_amount_label.position = from - _amount_label.size / 2.0
	_drop_dot(from)


## 文字を軌跡に沿って動かし、点を薄くし、すべて消えたら自分を解放する。[br]
## 文字が終点に着いたフレームで [signal arrived] を emit する。
func _process(delta: float) -> void:
	# 経過時間を進め、着くまでは文字を飛ばす
	_elapsed += delta
	if not _has_arrived:
		_fly()

	# 点の薄まりを描き直す
	queue_redraw()

	# 着いてから点が消えきったら解放する
	if _has_arrived and _elapsed >= FLIGHT_DURATION + DOT_LIFETIME:
		queue_free()


## 経過時間に合わせて文字を軌跡の上へ動かし、前の点から [constant DOT_SPACING] 進むごとに点をこぼす。
## 終点に着いたら文字を隠し、[signal arrived] を emit する。
func _fly() -> void:
	# 今の着く位置で山なりの軌跡（2 次ベジェ曲線）を引き、経過時間に合う位置へ文字を動かす
	var end: Vector2 = _target.call()
	var control: Vector2 = Vector2(lerpf(_start.x, end.x, ARC_CONTROL_X_RATIO), lerpf(_start.y, end.y, ARC_CONTROL_Y_RATIO))
	var progress: float = minf(_elapsed / FLIGHT_DURATION, 1.0)
	var eased: float = smoothstep(0.0, 1.0, progress)
	var point: Vector2 = _start.lerp(control, eased).lerp(control.lerp(end, eased), eased)
	_amount_label.position = point - _amount_label.size / 2.0

	# 前の点から間隔ぶん進むごとに、その間を埋めるように点をこぼす
	while _last_dot_position.distance_to(point) >= DOT_SPACING:
		_drop_dot(_last_dot_position.move_toward(point, DOT_SPACING))

	# 終点に着いたら文字を消して知らせる
	if progress >= 1.0:
		_has_arrived = true
		_amount_label.hide()
		arrived.emit()


## [param point] に点をこぼす。
func _drop_dot(point: Vector2) -> void:
	_dot_positions.append(point)
	_dot_times.append(_elapsed)
	_last_dot_position = point


## こぼした点を、こぼしてからの時間に合わせて薄くして描く。
func _draw() -> void:
	for i: int in _dot_positions.size():
		var remaining: float = 1.0 - (_elapsed - _dot_times[i]) / DOT_LIFETIME
		if remaining > 0.0:
			draw_circle(_dot_positions[i], DOT_RADIUS, Color(DOT_COLOR, DOT_COLOR.a * remaining), true, -1.0, true)
