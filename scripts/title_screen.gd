extends CanvasLayer
## 标题：开始 / 继续 / 皮肤店 / 退出。键盘、手柄、触摸都能点。

signal start_pressed
signal continue_pressed
signal shop_pressed
signal quit_pressed

var _continue_btn: Button
var _start_btn: Button


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func refresh() -> void:
	if _continue_btn:
		_continue_btn.disabled = not GameState.has_save_file()


func focus_default() -> void:
	if _start_btn:
		_start_btn.grab_focus()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.05, 0.08, 0.92)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(420, 0)
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)

	var title := Label.new()
	title.text = "Coin Master 2D"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.2))
	box.add_child(title)

	var sub := Label.new()
	sub.text = "街机投币机"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 22)
	sub.add_theme_color_override("font_color", Color(0.0, 0.94, 1.0, 0.9))
	box.add_child(sub)

	var hint := Label.new()
	hint.text = "空格 / A / 点击  ·  Esc / Start 暂停"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.75, 0.78, 0.9, 0.8))
	box.add_child(hint)

	_start_btn = _btn("开始", func() -> void: Sfx.play_ui(); start_pressed.emit())
	box.add_child(_start_btn)
	_continue_btn = _btn("继续", func() -> void: Sfx.play_ui(); continue_pressed.emit())
	box.add_child(_continue_btn)
	box.add_child(_btn("皮肤店", func() -> void: Sfx.play_ui(); shop_pressed.emit()))
	box.add_child(_btn("退出", func() -> void: Sfx.play_ui(); quit_pressed.emit()))
	refresh()


func _btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 48)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(cb)
	return b
