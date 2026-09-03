extends CanvasLayer
## 暂停：继续 / 皮肤店 / 静音 / 回标题。

signal resume_pressed
signal shop_pressed
signal title_pressed

var _mute_btn: Button
var _resume_btn: Button


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	_build()
	GameState.muted_changed.connect(_on_muted)
	_on_muted(GameState.muted)


func focus_default() -> void:
	if _resume_btn:
		_resume_btn.grab_focus()


func _on_muted(is_muted: bool) -> void:
	if _mute_btn:
		_mute_btn.text = "声音：关" if is_muted else "声音：开"


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(360, 0)
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)

	var title := Label.new()
	title.text = "暂停"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	box.add_child(title)

	_resume_btn = _btn("继续游戏", func() -> void: Sfx.play_ui(); resume_pressed.emit())
	box.add_child(_resume_btn)
	box.add_child(_btn("皮肤店", func() -> void: Sfx.play_ui(); shop_pressed.emit()))
	_mute_btn = _btn("声音：开", func() -> void: Sfx.play_ui(); GameState.toggle_mute())
	box.add_child(_mute_btn)
	box.add_child(_btn("返回标题", func() -> void: Sfx.play_ui(); title_pressed.emit()))


func _btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 48)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(cb)
	return b
