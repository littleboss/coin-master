extends Node
## 输入路由：PC / Steam Deck 用 InputMap；手机点哪投哪。
##
## toss_coin 绑定：鼠标左键、空格、手柄 A（JOY_BUTTON_A）。
## 瞄准：A/D、方向键、左摇杆。瞄准只改 X，投出高度永远是桌面顶端。
##
## 触摸用代码处理 InputEventScreenTouch，并关掉「触摸模拟鼠标」，避免连投两次。

signal toss_requested(use_aim: bool, screen_position: Vector2)
signal device_changed(kind: String)

enum DeviceKind { MOUSE, KEYBOARD, GAMEPAD, TOUCH }

const AIM_SPEED := 1.15
const STICK_DEADZONE := 0.22

var aim_t: float = 0.5
var current_device: DeviceKind = DeviceKind.MOUSE
var last_device_name: String = "mouse"

var _actions_ready := false


func _ready() -> void:
	_ensure_input_map()
	# 触摸自己处理；不要再生成鼠标事件，否则同一下会触发两次 toss_coin。
	Input.emulate_mouse_from_touch = false
	Input.emulate_touch_from_mouse = false
	if DisplayServer.is_touchscreen_available() and _looks_like_mobile():
		_set_device(DeviceKind.TOUCH)


func _looks_like_mobile() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")


func _process(delta: float) -> void:
	var axis := 0.0
	if InputMap.has_action("aim_left") and InputMap.has_action("aim_right"):
		axis = Input.get_axis("aim_left", "aim_right")
	# 左摇杆（即使没进 InputMap 也能读到 Steam Deck / 手柄）
	var stick := 0.0
	if Input.get_connected_joypads().size() > 0:
		stick = Input.get_joy_axis(Input.get_connected_joypads()[0], JOY_AXIS_LEFT_X)
		if absf(stick) < STICK_DEADZONE:
			stick = 0.0
		elif current_device != DeviceKind.GAMEPAD and absf(stick) > STICK_DEADZONE:
			_set_device(DeviceKind.GAMEPAD)
	var move := axis
	if absf(stick) > absf(axis):
		move = stick
	if absf(move) > 0.01:
		aim_t = clampf(aim_t + move * AIM_SPEED * delta, 0.0, 1.0)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		_set_device(DeviceKind.TOUCH)
		if touch.pressed:
			toss_requested.emit(false, touch.position)
			get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion and (event as InputEventMouseMotion).relative.length() > 1.0:
		if current_device == DeviceKind.TOUCH:
			_set_device(DeviceKind.MOUSE)
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			if _pointer_hit_button():
				return
			_set_device(DeviceKind.MOUSE)
			toss_requested.emit(false, mb.position)
			get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		_set_device(DeviceKind.KEYBOARD)
		if event.is_action_pressed("toss_coin") or (event as InputEventKey).keycode == KEY_SPACE:
			toss_requested.emit(true, Vector2.ZERO)
			get_viewport().set_input_as_handled()
		return

	if event is InputEventJoypadButton and event.pressed:
		_set_device(DeviceKind.GAMEPAD)
		var jb := event as InputEventJoypadButton
		if event.is_action_pressed("toss_coin") or jb.button_index == JOY_BUTTON_A:
			toss_requested.emit(true, Vector2.ZERO)
			get_viewport().set_input_as_handled()
		return

	if event is InputEventJoypadMotion:
		if absf((event as InputEventJoypadMotion).axis_value) > STICK_DEADZONE:
			_set_device(DeviceKind.GAMEPAD)


func request_toss_from_button() -> void:
	## HUD 投币按钮：按当前瞄准 X 投出（Y 仍然是桌顶）。
	toss_requested.emit(true, Vector2.ZERO)


func is_touch_mode() -> bool:
	return current_device == DeviceKind.TOUCH


func device_name() -> String:
	return last_device_name


func _pointer_hit_button() -> bool:
	var hovered := get_viewport().gui_get_hovered_control()
	return hovered != null and hovered is BaseButton


func _set_device(kind: DeviceKind) -> void:
	if kind == current_device:
		return
	current_device = kind
	match kind:
		DeviceKind.MOUSE:
			last_device_name = "mouse"
		DeviceKind.KEYBOARD:
			last_device_name = "keyboard"
		DeviceKind.GAMEPAD:
			last_device_name = "gamepad"
		DeviceKind.TOUCH:
			last_device_name = "touch"
	device_changed.emit(last_device_name)


func _ensure_input_map() -> void:
	if _actions_ready:
		return
	_actions_ready = true
	_add_action("toss_coin")
	_add_action("aim_left")
	_add_action("aim_right")

	_add_key("toss_coin", KEY_SPACE)
	_add_mouse_button("toss_coin", MOUSE_BUTTON_LEFT)
	_add_joy_button("toss_coin", JOY_BUTTON_A)

	_add_key("aim_left", KEY_A)
	_add_key("aim_left", KEY_LEFT)
	_add_joy_motion("aim_left", JOY_AXIS_LEFT_X, -1.0)

	_add_key("aim_right", KEY_D)
	_add_key("aim_right", KEY_RIGHT)
	_add_joy_motion("aim_right", JOY_AXIS_LEFT_X, 1.0)


func _add_action(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.5)


func _has_similar_event(action: String, event: InputEvent) -> bool:
	for existing in InputMap.action_get_events(action):
		if existing.device == event.device and existing.is_match(event, true):
			return true
	return false


func _add_event(action: String, event: InputEvent) -> void:
	if not _has_similar_event(action, event):
		InputMap.action_add_event(action, event)


func _add_key(action: String, keycode: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = keycode
	e.physical_keycode = keycode
	_add_event(action, e)


func _add_mouse_button(action: String, button: MouseButton) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = button
	_add_event(action, e)


func _add_joy_button(action: String, button: JoyButton) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	_add_event(action, e)


func _add_joy_motion(action: String, axis: JoyAxis, value: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	_add_event(action, e)
