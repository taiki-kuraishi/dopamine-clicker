class_name GameScreen
extends Control
## ゲームの画面。単色の背景の中央にスマホを置き、その画面にカードのフィードを出す。
## スマホの外の左に残高のバッジ、右にアップグレード欄の点線の枠を置く。
##
## ドーパミンの状態は持たない。カードのクリックを [signal card_clicked] で知らせ、残高と獲得は
## 呼び出し側から [method show_balance]・[method show_gain] で受け取って出す。

## フィードのカードがクリックされたときに emit される。ドラッグになった押下では emit されない。
signal card_clicked()

## 獲得の演出のシーン。
const _GAIN_POPUP_SCENE: PackedScene = preload("res://scenes/gain_popup.tscn")

## 獲得の演出を飛ばし始める位置（[member _effect_layer] の座標）。最後にクリックされた位置で、
## まだクリックされていなければフィードの中心。
var _gain_origin: Vector2 = Vector2.ZERO

## スマホの画面のフィード。
@onready var _feed: Feed = %Feed
## 残高のバッジ。
@onready var _balance_badge: BalanceBadge = %BalanceBadge
## 押下の輪と獲得の演出を置く層。スマホの画面の clip の外に置き、残高まで飛べるようにしている。
@onready var _effect_layer: Control = %EffectLayer


## フィードのクリックを受け取れるようにし、獲得の演出の始点をフィードの中心にしておく。
func _ready() -> void:
	_feed.card_clicked.connect(_on_feed_card_clicked)
	_gain_origin = _to_effect_layer(_feed.get_global_rect().get_center())


## 残高 [param balance] を、桁区切りにしてバッジに出す。
func show_balance(balance: int) -> void:
	_balance_badge.show_balance(balance)


## 獲得量 [param amount] を「+獲得量」として、最後にクリックされた位置から残高のバッジへ山なりに飛ばす。
## 着いたらバッジを弾ませる。
func show_gain(amount: int) -> void:
	var popup: GainPopup = _GAIN_POPUP_SCENE.instantiate() as GainPopup
	_effect_layer.add_child(popup)
	popup.arrived.connect(_balance_badge.bounce)
	popup.launch(amount, _gain_origin, func() -> Vector2: return _to_effect_layer(_balance_badge.get_gain_target()))


## フィードのクリック位置 [param position] に押下の輪を出し、獲得の演出の始点にしてから、
## [signal card_clicked] を emit する。
func _on_feed_card_clicked(position: Vector2) -> void:
	_gain_origin = _to_effect_layer(_feed.get_global_transform() * position)

	# 押下の輪をクリック位置に出す
	var ring: PressRing = PressRing.new()
	ring.position = _gain_origin
	_effect_layer.add_child(ring)

	card_clicked.emit()


## global 座標 [param global_point] を [member _effect_layer] の座標にして返す。
func _to_effect_layer(global_point: Vector2) -> Vector2:
	return _effect_layer.get_global_transform().affine_inverse() * global_point
