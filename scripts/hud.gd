class_name Hud
extends CanvasLayer
## 余额、当前皮肤、头奖喊话。触摸隐藏投币按钮。暂停按钮给触摸用。

signal pause_requested

const HINT_POINTER := "点击投币 · A/D 瞄准 · Esc 暂停"
const HINT_KEY := "空格投币 · A/D 瞄准 · Esc 暂停"
const HINT_PAD := "A 投币 · 摇杆瞄准 · Start 暂停"
const HINT_TOUCH := "点任意位置投币"
const CALLOUT_JACKPOT := "JACKPOT!"

@onready var _safe: MarginContainer = $Root/SafeArea
@onready var _balance: Label = $Root/SafeArea/VBox/TopBar/Panel/PanelMargin/BalanceLabel
@onready var _skin: TextureRect = $Root/SafeArea/VBox/TopBar/SkinPanel/SkinMargin/SkinPreview
@onready var _hint: Label = $Root/SafeArea/VBox/BottomBar/HintLabel
@onready var _toss_button: Button = $Root/SafeArea/VBox/BottomBar/TossButton
@onready var _pause_button: Button = $Root/SafeArea/VBox/TopBar/PauseButton
@onready var _jackpot: Label = $Root/JackpotCallout

var _callout_tween: Tween


func _ready() -> void:
	_apply_safe_area()
	get_viewport().size_changed.connect(_apply_safe_area)
	GameState.balance_changed.connect(_on_balance_changed)
	GameState.coin_scored.connect(_on_coin_scored)
	GameState.skin_changed.connect(_on_skin_changed)
	GameState.mercy_granted.connect(_on_mercy_granted)
	InputRouter.device_changed.connect(_on_device_changed)
	_toss_button.pressed.connect(_on_toss_pressed)
	_pause_button.pressed.connect(_on_pause_pressed)
	_on_balance_changed(GameState.balance)
	_on_skin_changed(GameState.equipped_skin)
	_refresh_device_ui(InputRouter.device_name())
	_jackpot.visible = false
	_jackpot.pivot_offset = Vector2(220, 40)


func _apply_safe_area() -> void:
	var safe := DisplayServer.get_display_safe_area()
	var win := DisplayServer.window_get_size()
	var vp := get_viewport().get_visible_rect().size
	var pad := 12
	var left := pad
	var top := pad
	var right := pad
	var bottom := pad
	if win.x > 0 and win.y > 0 and safe.size != Vector2i.ZERO:
		left = maxi(pad, int(round(float(safe.position.x) / float(win.x) * vp.x)))
		top = maxi(pad, int(round(float(safe.position.y) / float(win.y) * vp.y)))
		var right_px := win.x - (safe.position.x + safe.size.x)
		var bot_px := win.y - (safe.position.y + safe.size.y)
		right = maxi(pad, int(round(float(right_px) / float(win.x) * vp.x)))
		bottom = maxi(pad, int(round(float(bot_px) / float(win.y) * vp.y)))
	_safe.add_theme_constant_override("margin_left", left)
	_safe.add_theme_constant_override("margin_top", top)
	_safe.add_theme_constant_override("margin_right", right)
	_safe.add_theme_constant_override("margin_bottom", bottom)


func _on_balance_changed(new_balance: int) -> void:
	_balance.text = "金币  %d" % new_balance
	_toss_button.disabled = new_balance < GameState.TOSS_COST


func _on_skin_changed(index: int) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = CoinSkins.ATLAS
	atlas.region = CoinSkins.region_for_index(index)
	_skin.texture = atlas


func _on_coin_scored(multiplier: int) -> void:
	if multiplier >= 10:
		_balance.modulate = Color(0.0, 0.94, 1.0)
		_show_jackpot()
	elif multiplier >= 2:
		_balance.modulate = Color(1.0, 0.0, 0.5)
	elif multiplier >= 1:
		_balance.modulate = Color(1.0, 0.84, 0.0)
	else:
		_balance.modulate = Color(0.85, 0.55, 0.7)
	var tween := create_tween()
	tween.tween_property(_balance, "modulate", Color.WHITE, 0.35)


func _on_mercy_granted(amount: int) -> void:
	_show_callout("MERCY +%d" % amount, Color(1.0, 0.82, 0.35, 1.0), 1.6)


func _show_jackpot() -> void:
	_show_callout(CALLOUT_JACKPOT, Color(0.0, 0.94, 1.0, 1.0), 0.55)


func _show_callout(text: String, color: Color, hold: float) -> void:
	if _callout_tween:
		_callout_tween.kill()
	_jackpot.text = text
	_jackpot.visible = true
	_jackpot.modulate = Color(color.r, color.g, color.b, 1.0)
	_jackpot.scale = Vector2(0.7, 0.7)
	_callout_tween = create_tween()
	_callout_tween.tween_property(_jackpot, "scale", Vector2.ONE, 0.12)
	_callout_tween.tween_interval(hold)
	_callout_tween.tween_property(_jackpot, "modulate", Color(color.r, color.g, color.b, 0.0), 0.35)
	_callout_tween.tween_callback(func() -> void:
		_jackpot.visible = false
		_jackpot.text = CALLOUT_JACKPOT
	)


func _on_device_changed(kind: String) -> void:
	_refresh_device_ui(kind)


func _refresh_device_ui(kind: String) -> void:
	var touch := kind == "touch"
	_toss_button.visible = not touch
	match kind:
		"touch":
			_hint.text = HINT_TOUCH
		"keyboard":
			_hint.text = HINT_KEY
		"gamepad":
			_hint.text = HINT_PAD
		_:
			_hint.text = HINT_POINTER


func _on_toss_pressed() -> void:
	InputRouter.request_toss_from_button()


func _on_pause_pressed() -> void:
	Sfx.play_ui()
	pause_requested.emit()
