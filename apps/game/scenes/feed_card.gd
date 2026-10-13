class_name FeedCard
extends ColorRect
## フィードの 1 枚のカード。番号から決まる色で塗り、中央に「#番号」を出す。
##
## [Feed] が 2 枚を使い回し、送るたびに [method show_number] で番号を差し替える。

## カード色の彩度。
const SATURATION: float = 0.55
## カード色の明度。
const VALUE: float = 0.97
## 番号ごとに色相を進める角度（度）。黄金角なので、隣り合う番号の色が離れる。
const HUE_STEP_DEGREES: float = 137.508

## 今出している番号。
var number: int = 0

## 中央に「#番号」を出す Label。
@onready var _number_label: Label = $NumberLabel


## 番号 [param card_number] を出す。背景を [method color_for] の色にし、中央の文字を「#番号」にする。
func show_number(card_number: int) -> void:
	number = card_number
	color = color_for(card_number)
	_number_label.text = "#%d" % card_number


## 番号 [param card_number] のカードの背景色を返す。
static func color_for(card_number: int) -> Color:
	return Color.from_hsv(fmod(card_number * HUE_STEP_DEGREES, 360.0) / 360.0, SATURATION, VALUE)
