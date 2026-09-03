extends Node
## 流程：标题 → 游玩 → 暂停。Esc / 手柄 Start 暂停。--smoke 会跳过标题。

enum Screen { TITLE, PLAYING, PAUSED, SHOP }

var _screen: Screen = Screen.TITLE
var _title
var _pause
var _shop

@onready var _playfield: Playfield = $Playfield
@onready var _hud: Hud = $HUD


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.max_fps = 60
	Engine.physics_ticks_per_second = 60
	_playfield.process_mode = Node.PROCESS_MODE_PAUSABLE
	_hud.process_mode = Node.PROCESS_MODE_PAUSABLE
	_build_menus()
	_ensure_pause_action()
	_hud.pause_requested.connect(_on_pause_requested)
	if _wants_smoke():
		_enter_play()
		var smoke := preload("res://scripts/headless_smoke.gd").new()
		smoke.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(smoke)
	else:
		_enter_title()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	var pause := event.is_action_pressed("pause") or (
		event is InputEventKey and (event as InputEventKey).keycode == KEY_ESCAPE
	)
	if event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == JOY_BUTTON_START:
		pause = true
	if not pause:
		if _screen == Screen.SHOP and event.is_action_pressed("ui_cancel"):
			_shop.close()
			get_viewport().set_input_as_handled()
		return
	match _screen:
		Screen.PLAYING:
			_enter_pause()
			get_viewport().set_input_as_handled()
		Screen.PAUSED:
			_enter_play()
			get_viewport().set_input_as_handled()
		Screen.SHOP:
			_shop.close()
			get_viewport().set_input_as_handled()


func _build_menus() -> void:
	_title = preload("res://scripts/title_screen.gd").new()
	add_child(_title)
	_title.start_pressed.connect(_enter_play)
	_title.continue_pressed.connect(_enter_play)
	_title.shop_pressed.connect(func() -> void: _open_shop(false))
	_title.quit_pressed.connect(func() -> void: get_tree().quit())

	_pause = preload("res://scripts/pause_menu.gd").new()
	add_child(_pause)
	_pause.resume_pressed.connect(_enter_play)
	_pause.shop_pressed.connect(func() -> void: _open_shop(true))
	_pause.title_pressed.connect(_enter_title)

	_shop = preload("res://scripts/shop_screen.gd").new()
	add_child(_shop)
	_shop.closed.connect(_on_shop_closed)


func _enter_title() -> void:
	_screen = Screen.TITLE
	InputRouter.tossing_enabled = false
	if _playfield.spawner:
		_playfield.spawner.recycle_all()
	get_tree().paused = true
	_title.visible = true
	_title.refresh()
	_title.focus_default()
	_pause.visible = false
	_shop.visible = false
	_hud.visible = false


func _enter_play() -> void:
	_screen = Screen.PLAYING
	GameState.save()
	InputRouter.tossing_enabled = true
	get_tree().paused = false
	_title.visible = false
	_pause.visible = false
	_shop.visible = false
	_hud.visible = true


func _enter_pause() -> void:
	if _screen != Screen.PLAYING:
		return
	_screen = Screen.PAUSED
	InputRouter.tossing_enabled = false
	get_tree().paused = true
	_pause.visible = true
	_pause.focus_default()
	_shop.visible = false


func _on_pause_requested() -> void:
	if _screen == Screen.PLAYING:
		_enter_pause()


func _open_shop(from_pause: bool) -> void:
	_screen = Screen.SHOP
	InputRouter.tossing_enabled = false
	get_tree().paused = true
	_title.visible = false
	_pause.visible = false
	_shop.open(from_pause)


func _on_shop_closed() -> void:
	if _shop.came_from_pause():
		_screen = Screen.PAUSED
		_pause.visible = true
		_pause.focus_default()
		get_tree().paused = true
		InputRouter.tossing_enabled = false
	else:
		_enter_title()


func _ensure_pause_action() -> void:
	if not InputMap.has_action("pause"):
		InputMap.add_action("pause")
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.physical_keycode = KEY_ESCAPE
	if not _has_event("pause", esc):
		InputMap.action_add_event("pause", esc)
	var pkey := InputEventKey.new()
	pkey.keycode = KEY_P
	pkey.physical_keycode = KEY_P
	if not _has_event("pause", pkey):
		InputMap.action_add_event("pause", pkey)
	var start := InputEventJoypadButton.new()
	start.button_index = JOY_BUTTON_START
	if not _has_event("pause", start):
		InputMap.action_add_event("pause", start)


func _has_event(action: String, event: InputEvent) -> bool:
	for existing in InputMap.action_get_events(action):
		if existing.is_match(event, true):
			return true
	return false


func _wants_smoke() -> bool:
	if OS.get_cmdline_user_args().has("--smoke"):
		return true
	return OS.get_cmdline_args().has("--smoke")
