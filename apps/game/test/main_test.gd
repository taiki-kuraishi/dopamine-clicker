extends GdUnitTestSuite
## [Main] がゲーム画面を Autoload の [code]Game[/code] につなぐ配線のテスト。
##
## [code]Game[/code] の窓口は、一時ディレクトリに保存して時刻を 0 に固定した [LocalGameGateway] か
## [DeferredGameGateway] に差し替え、本物の user://save.json には触れない。headless では InputEvent が届かないので、
## クリックは [signal GameScreen.card_clicked] を emit して再現する。

## メインのシーン。
const _SCENE_PATH: String = "res://scenes/main.tscn"

## テストごとに作り直す、セーブファイルの保存先。
var _save_path: String = ""


## テストごとに、一時ディレクトリを保存先にする。
func before_test() -> void:
	_save_path = create_temp_dir("main_test").path_join("save.json")


## テストごとに、一時ディレクトリをセーブファイルごと消し、次のテストに残さない。
func after_test() -> void:
	clean_temp_dir()


## 読み込みを終えてから画面を開くと、読み込んだ残高が出る。
func test_opening_after_load_shows_loaded_balance() -> void:
	# Arrange
	_save_balance(7)
	await Game.start(_new_local_gateway())

	# Act
	var main: Main = _open_main()

	# Assert
	assert_str(_amount_label(main).text).is_equal("7")


## 読み込みを終える前に画面を開くと、読み込みを終えたときに読み込んだ残高が出る。
func test_opening_before_load_shows_balance_when_loaded() -> void:
	# Arrange
	var gateway: DeferredGameGateway = DeferredGameGateway.new(12)
	Game.start(gateway)
	var main: Main = _open_main()

	# Act
	gateway.release_start()

	# Assert
	assert_str(_amount_label(main).text).is_equal("12")


## カードをクリックすると、残高が 1 増えて出て、「+1」の獲得が出る。
func test_click_shows_increased_balance_and_gain() -> void:
	# Arrange
	await Game.start(_new_local_gateway())
	var main: Main = _open_main()

	# Act
	(main.get_node("GameScreen") as GameScreen).card_clicked.emit()

	# Assert
	assert_str(_amount_label(main).text).is_equal("1")
	var popups: Array[GainPopup] = _gain_popups(main)
	assert_int(popups.size()).is_equal(1)
	assert_str((popups[0].get_node("AmountLabel") as Label).text).is_equal("+1")


## メインのシーンを開いてツリーに入れて返す。テストの終わりに解放される。
func _open_main() -> Main:
	var main: Main = (load(_SCENE_PATH) as PackedScene).instantiate() as Main
	auto_free(main)
	add_child(main)
	return main


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


## [param main] の残高のバッジで、残高の数値を出す Label を返す。獲得の演出の「+獲得量」の Label は含めない。
func _amount_label(main: Main) -> Label:
	return main.find_child("BalanceBadge", true, false).find_child("AmountLabel", true, false) as Label


## [param main] の獲得の演出の層にある、解放待ちでない [GainPopup] をすべて返す。
func _gain_popups(main: Main) -> Array[GainPopup]:
	var popups: Array[GainPopup] = []
	for child: Node in main.find_child("EffectLayer", true, false).get_children():
		var popup: GainPopup = child as GainPopup
		if popup != null and not popup.is_queued_for_deletion():
			popups.append(popup)
	return popups
