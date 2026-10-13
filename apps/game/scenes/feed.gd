class_name Feed
extends Panel
## スマホの画面に縦に並ぶカードのフィード。上下のドラッグ・ホイール・上下キーで 1 枚ずつ送り、カードのクリックを知らせる。
##
## カードは無限に続き、0 番より前は無い。2 枚の [FeedCard] を使い回し、見えている位置に合わせて番号を差し替える。[br]
## headless では InputEvent が届かないので、入力はすべて [method go_next]・[method go_previous]・
## [method scroll_by_wheel]・[method begin_press]・[method move_press]・[method end_press] に渡してから処理する。

## カードがクリックされたときに emit される。[param position] はフィードの座標でのクリック位置。
## ドラッグになった押下では emit されない。
signal card_clicked(position: Vector2)

## 押してから離すまでにこの距離（px）を超えて動いたら、クリックではなくドラッグとして扱う。
const DRAG_THRESHOLD: float = 8.0
## ドラッグを離したとき、カードの高さに対してこの割合を超えて動いていたら次（前）のカードへ送る。
const FLIP_RATIO: float = 0.2
## 1 枚ぶん送る Tween の長さ（秒）。
const SCROLL_DURATION: float = 0.28

## 送りの行き先の番号。Tween の途中でも行き先を指す。
var current_index: int:
	get:
		return _index
## 先頭のカード（0 番）の上端から、画面の上端までの距離（px）。0 以上になる。
var scroll_offset: float:
	get:
		return _scroll

## 送りの行き先の番号。
var _index: int = 0
## 先頭のカードの上端から画面の上端までの距離（px）。
var _scroll: float = 0.0
## 左ボタンを押していて、まだ離していないとき true。
var _pressing: bool = false
## 今の押下が [constant DRAG_THRESHOLD] を超えて動き、ドラッグになったとき true。
var _dragging: bool = false
## 今の押下を始めた位置（フィードの座標）。
var _press_position: Vector2 = Vector2.ZERO
## ドラッグを始めた時点の [member _scroll]。
var _drag_start_scroll: float = 0.0
## 送りの Tween。動いていないときは null。
var _scroll_tween: Tween = null

## 使い回す 2 枚のカード。番号 n のカードは [code]_cards[n % 2][/code] が出す。
@onready var _cards: Array[FeedCard] = [$CardA as FeedCard, $CardB as FeedCard]


## 0 番のカードが画面に収まった状態でカードを並べる。
func _ready() -> void:
	_layout_cards()


## 次のカードへ 1 枚送る。Tween の途中なら、その行き先の次へ送り直す。
func go_next() -> void:
	_index += 1
	_animate_to_index()


## 前のカードへ 1 枚戻る。行き先が 0 番のときは何もしない。
func go_previous() -> void:
	if _index == 0:
		return
	_index -= 1
	_animate_to_index()


## フィードの座標 [param position] で押下を始める。
func begin_press(position: Vector2) -> void:
	_pressing = true
	_dragging = false
	_press_position = position


## 押下中の位置を [param position] に動かす。[constant DRAG_THRESHOLD] を超えて動いたらドラッグとして
## カードを指に付いて動かす。動かせるのは行き先の前後 1 枚ぶんまでで、0 番より前には引っ張れない。
func move_press(position: Vector2) -> void:
	if not _pressing:
		return

	# しきい値を超えるまではクリックの候補のまま動かさない
	if not _dragging:
		if _press_position.distance_to(position) <= DRAG_THRESHOLD:
			return
		_dragging = true
		_kill_scroll_tween()
		_drag_start_scroll = _scroll

	# 指の移動ぶんだけ、行き先の前後 1 枚の範囲でカードを動かす
	var card_height: float = size.y
	var lowest: float = maxf(0.0, (_index - 1) * card_height)
	var highest: float = (_index + 1) * card_height
	_set_scroll(clampf(_drag_start_scroll - (position.y - _press_position.y), lowest, highest))


## フィードの座標 [param position] で押下を終える。[br]
## ドラッグでなければクリックとして [signal card_clicked] を emit する。ドラッグなら、行き先から
## [constant FLIP_RATIO] を超えて動いた向きへ 1 枚送り、超えていなければ行き先へ戻す。
func end_press(position: Vector2) -> void:
	if not _pressing:
		return
	_pressing = false

	# ドラッグにならなかった押下はクリック
	if not _dragging:
		card_clicked.emit(position)
		return
	_dragging = false

	# 動いた向きと量で、送る・戻る・そのままを決めて Tween する
	var moved: float = _scroll - _index * size.y
	var flip_distance: float = size.y * FLIP_RATIO
	if moved > flip_distance:
		_index += 1
	elif moved < -flip_distance and _index > 0:
		_index -= 1
	_animate_to_index()


## ホイールのボタン [param button_index] を 1 枚の送りにする。下は次へ、上は前へ送る。
## 送りの Tween の途中とドラッグ中は送らない。ホイールでなければ何もしない。[br]
## 戻り値は [param button_index] がホイールの上下だったかどうか。
func scroll_by_wheel(button_index: MouseButton) -> bool:
	if button_index != MOUSE_BUTTON_WHEEL_DOWN and button_index != MOUSE_BUTTON_WHEEL_UP:
		return false

	# タッチパッドは 1 回のスワイプでホイールを何十回も送るので、送りの途中とドラッグ中は受け付けない
	if _dragging or _scroll_tween != null:
		return true
	if button_index == MOUSE_BUTTON_WHEEL_DOWN:
		go_next()
	else:
		go_previous()
	return true


## 画面上のマウスの押下・ドラッグ・ホイールを、送りと押下の処理に渡す。
func _gui_input(event: InputEvent) -> void:
	# 左ボタンの押下と離しを押下の処理に渡す
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null:
		if button.button_index == MOUSE_BUTTON_LEFT:
			if button.pressed:
				begin_press(button.position)
			else:
				end_press(button.position)
			accept_event()
		elif button.pressed and scroll_by_wheel(button.button_index):
			accept_event()
		return

	# 押したまま動かした位置を押下の処理に渡す
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null and _pressing:
		move_press(motion.position)
		accept_event()


## 画面の外で回したホイールと、上下キーを送りに渡す。
func _unhandled_input(event: InputEvent) -> void:
	# 画面の外のホイールも送りに使う
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null:
		if button.pressed and scroll_by_wheel(button.button_index):
			get_viewport().set_input_as_handled()
		return

	# 上下キーで 1 枚ずつ送る
	if event.is_action_pressed("ui_down"):
		go_next()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		go_previous()
		get_viewport().set_input_as_handled()


## 今の位置から行き先 [member _index] のカードまで Tween で動かす。
func _animate_to_index() -> void:
	_kill_scroll_tween()
	_scroll_tween = create_tween()
	_scroll_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_scroll_tween.tween_method(_set_scroll, _scroll, _index * size.y, SCROLL_DURATION)
	_scroll_tween.finished.connect(func() -> void: _scroll_tween = null)


## 動いている送りの Tween を止める。
func _kill_scroll_tween() -> void:
	if _scroll_tween == null:
		return
	_scroll_tween.kill()
	_scroll_tween = null


## 先頭からの距離を [param value] にして、カードを並べ直す。
func _set_scroll(value: float) -> void:
	_scroll = value
	_layout_cards()


## [member _scroll] で画面に掛かる 2 枚に番号を割り当て、縦の位置を合わせる。
func _layout_cards() -> void:
	var card_height: float = size.y
	var top_number: int = floori(_scroll / card_height)
	var top_y: float = top_number * card_height - _scroll

	# 上に掛かる番号と、その下の番号を、番号の偶奇で決まるカードに出す
	for offset: int in 2:
		var card_number: int = top_number + offset
		var card: FeedCard = _cards[card_number % 2]
		card.show_number(card_number)
		card.position.y = top_y + offset * card_height
