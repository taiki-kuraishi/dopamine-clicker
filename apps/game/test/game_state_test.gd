extends GdUnitTestSuite
## [GameState] の読み込み・クリック・ウィンドウを閉じたときのテスト。
##
## Autoload の [code]Game[/code] ではなく、ツリーに入れない別の [GameState] を作って使う（[method GameState._ready] の
## 本物の窓口で始めないため）。窓口は一時ディレクトリの [LocalGameGateway] か [DeferredGameGateway] にし、本物の
## user://save.json には触れない。ウィンドウを閉じる操作は [constant Node.NOTIFICATION_WM_CLOSE_REQUEST] を直接送って再現し、
## test runner ごと終わらないよう、[member GameState.quit_game] は呼ばれたことを記録するだけの Callable に差し替える。

## テストごとに作り直す、セーブファイルの保存先。
var _save_path: String = ""
## テスト中の状態が emit した signal を、名前と引数の文字列で順に記録したもの。
var _events: Array[String] = []


## テストごとに、一時ディレクトリを保存先にし、記録を空にする。
func before_test() -> void:
	_save_path = create_temp_dir("game_state_test").path_join("save.json")
	_events = []


## テストごとに、一時ディレクトリをセーブファイルごと消し、次のテストに残さない。
func after_test() -> void:
	clean_temp_dir()


## 窓口で始めると、読み込んだ残高が今の残高になり、balance_changed（残高）、loaded の順に emit される。
func test_start_loads_balance_and_emits_in_order() -> void:
	# Arrange
	_save_balance(7)
	var state: GameState = _new_state()

	# Act
	await state.start(_new_local_gateway())

	# Assert
	assert_bool(state.is_loaded).is_true()
	assert_int(state.balance).is_equal(7)
	assert_array(_events).is_equal(["balance_changed 7", "loaded"])


## 読み込みを終えた後にクリックすると、残高が 1 増え、balance_changed（残高）、gained（獲得量）の順に emit される。
func test_click_updates_balance_and_emits_in_order() -> void:
	# Arrange
	var state: GameState = _new_state()
	await state.start(_new_local_gateway())
	_events.clear()

	# Act
	await state.click()

	# Assert
	assert_int(state.balance).is_equal(1)
	assert_array(_events).is_equal(["balance_changed 1", "gained 1"])


## 読み込みを終える前のクリックは窓口に送らず、残高も変わらず、signal も emit されない。
func test_click_before_loaded_is_ignored() -> void:
	# Arrange
	var state: GameState = _new_state()
	var gateway: DeferredGameGateway = DeferredGameGateway.new(5)
	state.start(gateway)

	# Act
	await state.click()
	gateway.release_start()

	# Assert
	assert_int(state.balance).is_equal(5)
	assert_array(_events).is_equal(["balance_changed 5", "loaded"])


## 2 回続けてクリックすると、1 回目の結果を受け取るまで 2 回目は窓口に送らず、2 回とも窓口に届き、残高は 1、2 の順に出て巻き戻らない。
func test_clicks_are_sent_one_at_a_time_in_order() -> void:
	# Arrange
	var state: GameState = _new_state()
	var gateway: DeferredGameGateway = DeferredGameGateway.new(0)
	state.start(gateway)
	gateway.release_start()
	_events.clear()

	# Act
	state.click()
	state.click()
	var sent_before_first_result: int = gateway.click_count
	gateway.release_click()
	var sent_after_first_result: int = gateway.click_count
	gateway.release_click()

	# Assert
	assert_int(sent_before_first_result).is_equal(1)
	assert_int(sent_after_first_result).is_equal(2)
	assert_int(state.balance).is_equal(2)
	assert_array(_events).is_equal(["balance_changed 1", "gained 1", "balance_changed 2", "gained 1"])


## クリックの送り中に閉じられると、待ち行列を送り終えてから窓口を終え、終わってからゲームを終える。閉じた後のクリックは送らない。
func test_close_request_while_sending_clicks_waits_before_finish() -> void:
	# Arrange
	var state: GameState = _new_state()
	var gateway: DeferredGameGateway = DeferredGameGateway.new(0)
	state.start(gateway)
	gateway.release_start()
	_events.clear()
	state.click()
	state.click()

	# Act
	state.notification(NOTIFICATION_WM_CLOSE_REQUEST)
	state.click()
	var finished_while_sending: int = gateway.finish_count
	gateway.release_click()
	gateway.release_click()
	var events_while_finishing: Array[String] = _events.duplicate()
	gateway.release_finish()

	# Assert
	assert_int(finished_while_sending).is_equal(0)
	assert_int(gateway.click_count).is_equal(2)
	assert_int(gateway.finish_count).is_equal(1)
	assert_array(events_while_finishing).is_equal(["balance_changed 1", "gained 1", "balance_changed 2", "gained 1"])
	assert_array(_events).is_equal(["balance_changed 1", "gained 1", "balance_changed 2", "gained 1", "quit"])


## 読み込み中に窓口を差し替えると、前の窓口が後から返した残高は捨てられる。
func test_start_discards_result_of_replaced_gateway() -> void:
	# Arrange
	var state: GameState = _new_state()
	var old_gateway: DeferredGameGateway = DeferredGameGateway.new(100)
	state.start(old_gateway)
	var new_gateway: DeferredGameGateway = DeferredGameGateway.new(3)
	state.start(new_gateway)

	# Act
	old_gateway.release_start()
	var loaded_after_old_release: bool = state.is_loaded
	new_gateway.release_start()

	# Assert
	assert_bool(loaded_after_old_release).is_false()
	assert_int(state.balance).is_equal(3)
	assert_array(_events).is_equal(["balance_changed 3", "loaded"])


## ウィンドウが閉じられると窓口を終えてからゲームを終え、ローカルの窓口ならその時点の残高が保存される。
func test_close_request_finishes_gateway_and_saves() -> void:
	# Arrange
	var state: GameState = _new_state()
	await state.start(_new_local_gateway())
	await state.click()
	await state.click()

	# Act
	state.notification(NOTIFICATION_WM_CLOSE_REQUEST)

	# Assert
	var saved: DopamineState = DopamineState.from_save_string(FileAccess.get_file_as_string(_save_path))
	assert_object(saved).is_not_null()
	assert_int(saved.balance).is_equal(2)
	assert_str(_events[_events.size() - 1]).is_equal("quit")


## 窓口の finish が終わるまではゲームを終えず、終わったら 1 回だけ終える。待っている間の 2 回目の閉じる要求では finish を呼び直さない。
func test_close_request_quits_after_finish_completes() -> void:
	# Arrange
	var state: GameState = _new_state()
	var gateway: DeferredGameGateway = DeferredGameGateway.new(0)
	state.start(gateway)
	gateway.release_start()
	_events.clear()

	# Act
	state.notification(NOTIFICATION_WM_CLOSE_REQUEST)
	state.notification(NOTIFICATION_WM_CLOSE_REQUEST)
	var events_while_finishing: Array[String] = _events.duplicate()
	gateway.release_finish()

	# Assert
	assert_int(gateway.finish_count).is_equal(1)
	assert_array(events_while_finishing).is_empty()
	assert_array(_events).is_equal(["quit"])


## 読み込みを終える前に閉じられると、窓口を終えずにすぐゲームを終える。
func test_close_request_before_loaded_quits_without_finish() -> void:
	# Arrange
	var state: GameState = _new_state()
	var gateway: DeferredGameGateway = DeferredGameGateway.new(0)
	state.start(gateway)

	# Act
	state.notification(NOTIFICATION_WM_CLOSE_REQUEST)

	# Assert
	assert_int(gateway.finish_count).is_equal(0)
	assert_array(_events).is_equal(["quit"])
	gateway.release_start()


## ツリーに入れない [GameState] を作り、signal とゲームの終了を [member _events] に記録するようにして返す。
## テストの終わりに解放される。
func _new_state() -> GameState:
	var state: GameState = GameState.new()
	auto_free(state)
	state.balance_changed.connect(func(balance: int) -> void: _events.append("balance_changed %d" % balance))
	state.gained.connect(func(amount: int) -> void: _events.append("gained %d" % amount))
	state.loaded.connect(func() -> void: _events.append("loaded"))
	state.quit_game = func() -> void: _events.append("quit")
	return state


## 一時ディレクトリに保存し、時刻を 0 に固定したローカルの窓口を返す。
func _new_local_gateway() -> LocalGameGateway:
	return LocalGameGateway.new(_save_path, func() -> int: return 0)


## 残高 [param balance] のセーブを保存先に書く。
func _save_balance(balance: int) -> void:
	var dopamine: DopamineState = DopamineState.new()
	dopamine.balance = balance
	dopamine.total_earned = balance
	var file: FileAccess = FileAccess.open(_save_path, FileAccess.WRITE)
	assert_object(file).is_not_null()
	file.store_string(dopamine.to_save_string())
	file.close()
