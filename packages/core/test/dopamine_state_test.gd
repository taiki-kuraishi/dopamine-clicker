extends GdUnitTestSuite
## [DopamineState] のクリックとセーブ文字列の変換のテスト。


## クリックすると、獲得量として 1 が返る。
func test_click_returns_gain_per_click() -> void:
	# Arrange
	var state: DopamineState = DopamineState.new()

	# Act
	var gained: int = state.click()

	# Assert
	assert_int(gained).is_equal(1)


## クリックすると、残高と累計獲得の両方に獲得量が足される。
func test_click_adds_gain_to_balance_and_total_earned() -> void:
	# Arrange
	var state: DopamineState = DopamineState.new()
	state.balance = 2
	state.total_earned = 5

	# Act
	state.click()

	# Assert
	assert_int(state.balance).is_equal(3)
	assert_int(state.total_earned).is_equal(6)


## クリックすると、足した後の残高を付けて balance_changed が 1 回 emit される。
func test_click_emits_balance_changed_with_new_balance() -> void:
	# Arrange
	var state: DopamineState = DopamineState.new()
	var emitted: Array[int] = []
	state.balance_changed.connect(func(balance: int) -> void: emitted.append(balance))

	# Act
	state.click()

	# Assert
	assert_array(emitted).is_equal([1])


## セーブ文字列にしてから戻すと、0・通常の値・int64 の最大値のどれでも残高と累計獲得が元と一致する。
func test_save_string_round_trips_counts(balance: int, total_earned: int, test_parameters: Array = [
	[0, 0],
	[3, 5],
	[9223372036854775807, 9223372036854775807],
]) -> void:
	# Arrange
	var state: DopamineState = DopamineState.new()
	state.balance = balance
	state.total_earned = total_earned

	# Act
	var restored: DopamineState = DopamineState.from_save_string(state.to_save_string())

	# Assert
	assert_object(restored).is_not_null()
	assert_int(restored.balance).is_equal(balance)
	assert_int(restored.total_earned).is_equal(total_earned)


## 壊れたセーブ文字列（JSON でない・件数の欠落や型違い・負・先頭 0・int64 超え・末尾改行・残高が累計超え）からは null が返る。
func test_from_save_string_returns_null_for_broken_text(text: String, test_parameters: Array = [
	[""],
	["not json"],
	["[]"],
	['{"version": 1, "total_earned": "5"}'],
	['{"version": 1, "balance": 3, "total_earned": "5"}'],
	['{"version": 1, "balance": "-1", "total_earned": "5"}'],
	['{"version": 1, "balance": "03", "total_earned": "5"}'],
	['{"version": 1, "balance": "1", "total_earned": "9223372036854775808"}'],
	['{"version": 1, "balance": "9223372036854775808\\n", "total_earned": "9223372036854775808\\n"}'],
	['{"version": 1, "balance": "6", "total_earned": "5"}'],
]) -> void:
	# Act
	var restored: DopamineState = DopamineState.from_save_string(text)

	# Assert
	assert_object(restored).is_null()


## version が無い・知らない値・文字列のセーブ文字列からは null が返る。
func test_from_save_string_returns_null_for_unknown_version(text: String, test_parameters: Array = [
	['{"balance": "3", "total_earned": "5"}'],
	['{"version": 2, "balance": "3", "total_earned": "5"}'],
	['{"version": "1", "balance": "3", "total_earned": "5"}'],
]) -> void:
	# Act
	var restored: DopamineState = DopamineState.from_save_string(text)

	# Assert
	assert_object(restored).is_null()
