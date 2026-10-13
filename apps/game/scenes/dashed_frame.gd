class_name DashedFrame
extends Control
## 角丸の点線の枠。アップグレード欄を入れる場所の目印に使う。
##
## StyleBoxFlat は破線を描けないので、角丸の外周を折れ線にして、その上に短い線を並べて描く。

## 角の 1/4 円を折れ線にするときの分割数。
const _CORNER_SEGMENTS: int = 12

## 線の色。
@export var line_color: Color = Color.BLACK
## 線の太さ（px）。枠の内側に収まるように描く。
@export var line_width: float = 2.0
## 枠の外側の角丸の半径（px）。
@export var corner_radius: float = 44.0
## 1 本の線の長さ（px）。
@export var dash_length: float = 6.0
## 線と線の間の長さ（px）。
@export var gap_length: float = 6.0


## 外周に沿って、[member dash_length] の線を [member gap_length] の隙間を空けて描く。
func _draw() -> void:
	# 外周の折れ線と、始点から各頂点までの道のりを求める
	var outline: PackedVector2Array = _outline()
	var distances: PackedFloat32Array = PackedFloat32Array([0.0])
	for i: int in range(1, outline.size()):
		distances.append(distances[i - 1] + outline[i - 1].distance_to(outline[i]))
	var total: float = distances[distances.size() - 1]

	# 道のりを線 1 本と隙間 1 つの長さごとに区切り、各区切りの先頭に線を引く
	var start: float = 0.0
	while start < total:
		var end: float = minf(start + dash_length, total)
		draw_line(_point_at(outline, distances, start), _point_at(outline, distances, end), line_color, line_width, true)
		start += dash_length + gap_length


## 線の中心が通る、角丸の外周を時計回りに 1 周する折れ線を返す。最後の頂点は最初の頂点と同じ。
func _outline() -> PackedVector2Array:
	var inset: float = line_width / 2.0
	var rect: Rect2 = Rect2(Vector2(inset, inset), size - Vector2(line_width, line_width))
	var radius: float = clampf(corner_radius - inset, 0.0, minf(rect.size.x, rect.size.y) / 2.0)
	var centers: Array[Vector2] = [
		Vector2(rect.end.x - radius, rect.position.y + radius),
		Vector2(rect.end.x - radius, rect.end.y - radius),
		Vector2(rect.position.x + radius, rect.end.y - radius),
		Vector2(rect.position.x + radius, rect.position.y + radius),
	]

	# 右上・右下・左下・左上の順に、各角の 1/4 円を _CORNER_SEGMENTS 個の辺に分けて頂点を並べる
	var points: PackedVector2Array = PackedVector2Array()
	for corner: int in centers.size():
		var start_angle: float = -PI / 2.0 + corner * PI / 2.0
		for step: int in _CORNER_SEGMENTS + 1:
			var angle: float = start_angle + step * (PI / 2.0) / _CORNER_SEGMENTS
			points.append(centers[corner] + Vector2.from_angle(angle) * radius)
	points.append(points[0])
	return points


## 折れ線 [param outline] の上で、始点から道のり [param distance] の位置を返す。
## [param distances] は始点から各頂点までの道のり。
static func _point_at(outline: PackedVector2Array, distances: PackedFloat32Array, distance: float) -> Vector2:
	var index: int = clampi(distances.bsearch(distance), 1, outline.size() - 1)
	var segment_length: float = distances[index] - distances[index - 1]
	if segment_length <= 0.0:
		return outline[index]
	return outline[index - 1].lerp(outline[index], (distance - distances[index - 1]) / segment_length)
