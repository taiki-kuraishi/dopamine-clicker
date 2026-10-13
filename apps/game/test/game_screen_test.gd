extends GdUnitTestSuite
## [GameScreen] のフィードの送り・カードのクリック・残高と獲得の表示のテスト。
##
## headless では InputEvent が届かないので、入力は [Feed] の送りと押下のメソッドを直接呼んで再現する。

## ゲーム画面のシーン。
const _SCENE_PATH: String = "res://scenes/game_screen.tscn"
## 送りの Tween が終わるのを待つ長さ（ミリ秒）。[constant Feed.SCROLL_DURATION] より長くしてある。
const _SCROLL_WAIT_MILLIS: int = 500

## テストごとに作り直すゲーム画面の scene runner。
var _runner: GdUnitSceneRunner = null
## テスト中のゲーム画面。
var _screen: GameScreen = null
## テスト中のゲーム画面のフィード。
var _feed: Feed = null


## テストごとに、新しいゲーム画面を開く。
func before_test() -> void:
	_runner = scene_runner(_SCENE_PATH)
	_screen = _runner.scene() as GameScreen
	_feed = _runner.find_child("Feed") as Feed


## 次へ送ると、行き先が 1 番になり、Tween が終わると 1 番のカードが画面の上端に収まる。
func test_go_next_shows_next_card() -> void:
	# Act
	_feed.go_next()
	await await_millis(_SCROLL_WAIT_MILLIS)

	# Assert
	assert_int(_feed.current_index).is_equal(1)
	assert_int(_card_at_top().number).is_equal(1)


## 次へ送ってから前へ戻すと、0 番のカードが画面の上端に戻る。
func test_go_previous_after_go_next_shows_first_card() -> void:
	# Arrange
	_feed.go_next()
	await await_millis(_SCROLL_WAIT_MILLIS)

	# Act
	_feed.go_previous()
	await await_millis(_SCROLL_WAIT_MILLIS)

	# Assert
	assert_int(_feed.current_index).is_equal(0)
	assert_int(_card_at_top().number).is_equal(0)


## 0 番で前へ戻そうとしても、0 番のまま動かない。
func test_go_previous_at_first_card_stays() -> void:
	# Act
	_feed.go_previous()
	await await_millis(_SCROLL_WAIT_MILLIS)

	# Assert
	assert_int(_feed.current_index).is_equal(0)
	assert_float(_feed.scroll_offset).is_equal(0.0)


## ホイールを下へ回すと次へ、上へ回すと前へ、1 枚ずつ送られる。
func test_scroll_by_wheel_moves_one_card(button_index: MouseButton, expected_index: int, test_parameters: Array = [
	[MOUSE_BUTTON_WHEEL_DOWN, 2],
	[MOUSE_BUTTON_WHEEL_UP, 0],
]) -> void:
	# Arrange
	_feed.go_next()
	await await_millis(_SCROLL_WAIT_MILLIS)

	# Act
	_feed.scroll_by_wheel(button_index)
	await await_millis(_SCROLL_WAIT_MILLIS)

	# Assert
	assert_int(_feed.current_index).is_equal(expected_index)
	assert_int(_card_at_top().number).is_equal(expected_index)


## 送りの Tween の途中で回したホイールは無視され、1 枚ぶんしか送られない。
func test_scroll_by_wheel_during_scroll_is_ignored() -> void:
	# Arrange
	_feed.scroll_by_wheel(MOUSE_BUTTON_WHEEL_DOWN)

	# Act
	_feed.scroll_by_wheel(MOUSE_BUTTON_WHEEL_DOWN)
	await await_millis(_SCROLL_WAIT_MILLIS)

	# Assert
	assert_int(_feed.current_index).is_equal(1)


## ドラッグ中に回したホイールは無視され、送りの行き先は変わらない。
func test_scroll_by_wheel_while_dragging_is_ignored() -> void:
	# Arrange
	_feed.begin_press(Vector2(150, 500))
	_feed.move_press(Vector2(150, 450))

	# Act
	_feed.scroll_by_wheel(MOUSE_BUTTON_WHEEL_DOWN)

	# Assert
	assert_int(_feed.current_index).is_equal(0)


## 0 番で下へドラッグしても、0 番より前には引っ張れない。
func test_drag_down_at_first_card_does_not_scroll() -> void:
	# Arrange
	_feed.begin_press(Vector2(150, 300))

	# Act
	_feed.move_press(Vector2(150, 500))

	# Assert
	assert_float(_feed.scroll_offset).is_equal(0.0)


## 上へドラッグしている間は、カードが指の移動ぶんだけ動く。
func test_drag_up_scrolls_with_pointer() -> void:
	# Arrange
	_feed.begin_press(Vector2(150, 500))

	# Act
	_feed.move_press(Vector2(150, 178))

	# Assert
	assert_float(_feed.scroll_offset).is_equal(322.0)


## カードの高さの 2 割を超えて上へドラッグして離すと、次のカードへ送られる。
func test_release_after_long_drag_up_shows_next_card() -> void:
	# Arrange
	_feed.begin_press(Vector2(150, 500))
	_feed.move_press(Vector2(150, 300))

	# Act
	_feed.end_press(Vector2(150, 300))
	await await_millis(_SCROLL_WAIT_MILLIS)

	# Assert
	assert_int(_feed.current_index).is_equal(1)
	assert_int(_card_at_top().number).is_equal(1)


## カードの高さの 2 割までの上へのドラッグで離すと、今のカードに戻る。
func test_release_after_short_drag_returns_to_current_card() -> void:
	# Arrange
	_feed.begin_press(Vector2(150, 500))
	_feed.move_press(Vector2(150, 450))

	# Act
	_feed.end_press(Vector2(150, 450))
	await await_millis(_SCROLL_WAIT_MILLIS)

	# Assert
	assert_int(_feed.current_index).is_equal(0)
	assert_float(_feed.scroll_offset).is_equal(0.0)


## しきい値以内の動きで押して離すと、ゲーム画面の card_clicked が 1 回 emit される。
func test_press_and_release_in_place_emits_card_clicked() -> void:
	# Arrange
	var clicks: Array[int] = []
	_screen.card_clicked.connect(func() -> void: clicks.append(1))
	_feed.begin_press(Vector2(150, 300))
	_feed.move_press(Vector2(153, 304))

	# Act
	_feed.end_press(Vector2(153, 304))

	# Assert
	assert_int(clicks.size()).is_equal(1)


## ドラッグになった押下を離しても、card_clicked は emit されない。
func test_release_after_drag_does_not_emit_card_clicked() -> void:
	# Arrange
	var clicks: Array[int] = []
	_screen.card_clicked.connect(func() -> void: clicks.append(1))
	_feed.begin_press(Vector2(150, 300))
	_feed.move_press(Vector2(150, 280))

	# Act
	_feed.end_press(Vector2(150, 280))

	# Assert
	assert_int(clicks.size()).is_equal(0)


## クリックすると、クリックした位置に押下の輪が出る。
func test_click_shows_press_ring_at_click_position() -> void:
	# Act
	_feed.begin_press(Vector2(150, 300))
	_feed.end_press(Vector2(150, 300))

	# Assert
	var rings: Array[PressRing] = []
	for child: Node in _effect_layer().get_children():
		if child is PressRing:
			rings.append(child as PressRing)
	assert_int(rings.size()).is_equal(1)
	assert_vector(rings[0].get_global_rect().position).is_equal(_feed.get_global_transform() * Vector2(150, 300))


## 残高は 3 桁ごとに「,」で区切って出る。
func test_show_balance_groups_digits(balance: int, expected: String, test_parameters: Array = [
	[0, "0"],
	[999, "999"],
	[1000, "1,000"],
	[1234, "1,234"],
	[1234567, "1,234,567"],
	[9223372036854775807, "9,223,372,036,854,775,807"],
]) -> void:
	# Act
	_screen.show_balance(balance)

	# Assert
	assert_str(_amount_label().text).is_equal(expected)


## 獲得を出すと、最後にクリックした位置に「+獲得量」が出る。
func test_show_gain_starts_at_click_position() -> void:
	# Arrange
	_feed.begin_press(Vector2(150, 482))
	_feed.end_press(Vector2(150, 482))

	# Act
	_screen.show_gain(5)

	# Assert
	var popups: Array[GainPopup] = _gain_popups()
	assert_int(popups.size()).is_equal(1)
	var label: Label = popups[0].get_node("AmountLabel") as Label
	assert_str(label.text).is_equal("+5")
	assert_vector(label.get_global_rect().get_center()).is_equal_approx(_feed.get_global_transform() * Vector2(150, 482), Vector2.ONE)


## 獲得の「+獲得量」は残高の数値まで飛んで着き、こぼした点が消えると演出ごと消える。
func test_show_gain_reaches_balance_and_disappears() -> void:
	# Arrange
	_feed.begin_press(Vector2(150, 482))
	_feed.end_press(Vector2(150, 482))
	_screen.show_gain(1)
	var popup: GainPopup = _gain_popups()[0]
	var label: Label = popup.get_node("AmountLabel") as Label
	var landed: Array[Vector2] = []
	popup.arrived.connect(func() -> void: landed.append(label.get_global_rect().get_center()))

	# Act
	await await_signal_on(popup, "tree_exited", [], 3000)
	await get_tree().process_frame

	# Assert
	var badge: BalanceBadge = _runner.find_child("BalanceBadge") as BalanceBadge
	assert_int(landed.size()).is_equal(1)
	assert_vector(landed[0]).is_equal_approx(badge.get_gain_target(), Vector2.ONE)
	assert_int(_gain_popups().size()).is_equal(0)


## カードの色は番号から決まり、案 B の見本と同じ色になる。
func test_card_color_follows_number(number: int, expected: String, test_parameters: Array = [
	[0, "f76f6f"],
	[12, "6fb3f7"],
	[13, "f76f8b"],
]) -> void:
	# Act
	var color: Color = FeedCard.color_for(number)

	# Assert
	assert_str(color.to_html(false)).is_equal(expected)


## 画面の上端に収まっているカードを返す。どちらも収まっていなければ null を返す。
func _card_at_top() -> FeedCard:
	for card_name: String in ["CardA", "CardB"]:
		var card: FeedCard = _runner.find_child(card_name) as FeedCard
		if is_zero_approx(card.position.y):
			return card
	return null


## 残高の数値を出す Label を返す。
func _amount_label() -> Label:
	return _runner.find_child("AmountLabel") as Label


## 押下の輪と獲得の演出を置く層を返す。
func _effect_layer() -> Control:
	return _runner.find_child("EffectLayer") as Control


## 獲得の演出の層にある、解放待ちでない [GainPopup] をすべて返す。
func _gain_popups() -> Array[GainPopup]:
	var popups: Array[GainPopup] = []
	for child: Node in _effect_layer().get_children():
		var popup: GainPopup = child as GainPopup
		if popup != null and not popup.is_queued_for_deletion():
			popups.append(popup)
	return popups
