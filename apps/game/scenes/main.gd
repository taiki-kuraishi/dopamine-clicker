class_name Main
extends Node
## ゲームの起動点（main scene）。子の [GameScreen] を Autoload の [code]Game[/code]（[GameState]）につなぐだけの薄い scene。
##
## カードのクリックを [method GameState.click] に送り、残高の変化と獲得を画面に出す。状態とセーブは持たない。

## 子のゲーム画面。
@onready var _screen: GameScreen = %GameScreen


## ゲーム画面とゲームの状態をつなぎ、読み込みを終えていれば今の残高を出す。
## まだなら、読み込みを終えたときの [signal GameState.balance_changed] で出る。
func _ready() -> void:
	# クリックを状態に、残高の変化と獲得を画面に渡す
	_screen.card_clicked.connect(Game.click)
	Game.balance_changed.connect(_screen.show_balance)
	Game.gained.connect(_screen.show_gain)

	# 読み込み済みの残高はもう signal で来ないので、ここで出す
	if Game.is_loaded:
		_screen.show_balance(Game.balance)
