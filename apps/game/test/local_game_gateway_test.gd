extends GdUnitTestSuite
## [LocalGameGateway] のクリックでの獲得・セーブの読み書き・保存の時機のテスト。
##
## 保存先は GdUnit の一時ディレクトリに、時刻は [member _now_msec] を返す Callable に差し替え、本物の
## user://save.json には触れない。

## テストごとに作り直す、セーブファイルを置く一時ディレクトリ。
var _save_dir: String = ""
## テスト中の窓口の保存先。
var _save_path: String = ""
## テスト中の窓口の時刻（ミリ秒）。
var _now_msec: int = 0


## テストごとに、一時ディレクトリを保存先にし、時刻を 0 に戻す。
func before_test() -> void:
	_save_dir = create_temp_dir("local_game_gateway_test")
	_save_path = _save_dir.path_join("save.json")
	_now_msec = 0


## テストごとに、一時ディレクトリをセーブファイルごと消し、次のテストに残さない。
func after_test() -> void:
	clean_temp_dir()


## セーブが無いときは残高 0 で始まり、クリックすると獲得量 1 と獲得後の残高 1 が返る。
func test_click_without_save_returns_gain_and_balance() -> void:
	# Arrange
	var gateway: LocalGameGateway = _new_gateway(_save_path)
	var started_balance: int = gateway.start()

	# Act
	var result: GameGateway.ClickResult = gateway.click()

	# Assert
	assert_int(started_balance).is_equal(0)
	assert_int(result.gained).is_equal(1)
	assert_int(result.balance).is_equal(1)


## 終えるときに保存し、同じ保存先で始め直すと、終える前と同じ残高で始まる。
func test_finish_saves_and_restart_restores_balance() -> void:
	# Arrange
	var first: LocalGameGateway = _new_gateway(_save_path)
	first.start()
	for _i: int in 3:
		first.click()
	first.finish()

	# Act
	var second: LocalGameGateway = _new_gateway(_save_path)
	var started_balance: int = second.start()

	# Assert
	assert_int(started_balance).is_equal(3)
	assert_int(second.click().balance).is_equal(4)


## セーブが壊れているときは残高 0 で始まり、次の保存で読めるセーブに上書きされる。
func test_broken_save_starts_from_zero_and_is_overwritten() -> void:
	# Arrange
	_write_save("not json")
	var gateway: LocalGameGateway = _new_gateway(_save_path)

	# Act
	var started_balance: int = gateway.start()
	gateway.click()
	gateway.finish()

	# Assert
	assert_int(started_balance).is_equal(0)
	assert_int(_saved_balance()).is_equal(1)


## 始めてから 10 秒未満のクリックでは保存せず、10 秒ちょうどのクリックで保存する。
func test_click_saves_after_interval_from_start() -> void:
	# Arrange
	var gateway: LocalGameGateway = _new_gateway(_save_path)
	gateway.start()

	# Act
	_now_msec = LocalGameGateway.AUTOSAVE_INTERVAL_MSEC - 1
	gateway.click()
	var saved_before_interval: bool = FileAccess.file_exists(_save_path)
	_now_msec = LocalGameGateway.AUTOSAVE_INTERVAL_MSEC
	gateway.click()

	# Assert
	assert_bool(saved_before_interval).is_false()
	assert_int(_saved_balance()).is_equal(2)


## クリックでの保存の後は、その保存から 10 秒たつまで次のクリックでは保存しない。
func test_click_saves_after_interval_from_last_save() -> void:
	# Arrange
	var gateway: LocalGameGateway = _new_gateway(_save_path)
	gateway.start()
	_now_msec = LocalGameGateway.AUTOSAVE_INTERVAL_MSEC
	gateway.click()

	# Act
	_now_msec = LocalGameGateway.AUTOSAVE_INTERVAL_MSEC * 2 - 1
	gateway.click()
	var balance_before_interval: int = _saved_balance()
	_now_msec = LocalGameGateway.AUTOSAVE_INTERVAL_MSEC * 2
	gateway.click()

	# Assert
	assert_int(balance_before_interval).is_equal(1)
	assert_int(_saved_balance()).is_equal(3)


## 保存先に書けなくても、クリックでの保存と終えるときの保存で止まらず、残高は増え続ける。
func test_write_failure_does_not_stop_game() -> void:
	# Arrange
	var unwritable_path: String = _save_dir.path_join("missing_dir/save.json")
	var gateway: LocalGameGateway = _new_gateway(unwritable_path)
	gateway.start()

	# Act
	_now_msec = LocalGameGateway.AUTOSAVE_INTERVAL_MSEC
	gateway.click()
	gateway.finish()
	var result: GameGateway.ClickResult = gateway.click()

	# Assert
	assert_bool(FileAccess.file_exists(unwritable_path)).is_false()
	assert_int(result.balance).is_equal(2)


## 保存先を [param save_path]、時刻を [member _now_msec] にした窓口を返す。
func _new_gateway(save_path: String) -> LocalGameGateway:
	return LocalGameGateway.new(save_path, func() -> int: return _now_msec)


## セーブファイルに [param text] をそのまま書く。開けなければテストを失敗させる。
func _write_save(text: String) -> void:
	var file: FileAccess = FileAccess.open(_save_path, FileAccess.WRITE)
	assert_object(file).is_not_null()
	file.store_string(text)
	file.close()


## セーブファイルを読み、その残高を返す。読めないときは -1 を返す。
func _saved_balance() -> int:
	var state: DopamineState = DopamineState.from_save_string(FileAccess.get_file_as_string(_save_path))
	if state == null:
		return -1
	return state.balance
