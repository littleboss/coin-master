extends CanvasLayer
## 标题：开始 / 皮肤店 / 退出。
## Logo 是 1536×1024 叠字锁，黑底完整信箱适配（fit / letterbox）。
## 绝不 Cover 裁切，也绝不拉成宽 Banner。

signal start_pressed
signal shop_pressed
signal quit_pressed

const LOGO_PATH := "res://assets/ui/logo.png"

var _start_btn: Button
var _logo: TextureRect


func _ready() -> void:
	name = "TitleScreen"
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func refresh() -> void:
	pass


func focus_default() -> void:
	if _start_btn:
		_start_btn.grab_focus()


func _build() -> void:
	# 不透明黑底：叠字锁周围的「信箱」就是这块黑，不要透出台面。
	var black := ColorRect.new()
	black.color = Color(0, 0, 0, 1)
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(black)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 28)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(box)

	# 剩余高度全给 Logo：KEEP_ASPECT_CENTERED = 完整放下，多出来的边是黑信箱。
	# COVERED 会裁掉叠字；SCALE 会拉扁。这两种都不要。
	if ResourceLoader.exists(LOGO_PATH):
		_logo = TextureRect.new()
		_logo.texture = load(LOGO_PATH)
		_logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_logo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_logo.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(_logo)
	else:
		var stacked := Label.new()
		stacked.text = "COIN\nMASTER\n2D"
		stacked.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stacked.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		stacked.size_flags_vertical = Control.SIZE_EXPAND_FILL
		stacked.add_theme_font_size_override("font_size", 48)
		stacked.add_theme_color_override("font_color", Color(1.0, 0.84, 0.2))
		box.add_child(stacked)

	var hint := Label.new()
	hint.text = "空格 / A / 点击投币  ·  Esc / Start 暂停"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.75, 0.78, 0.9, 0.8))
	box.add_child(hint)

	_start_btn = _btn("开始", func() -> void: Sfx.play_ui(); start_pressed.emit())
	box.add_child(_start_btn)
	box.add_child(_btn("皮肤店", func() -> void: Sfx.play_ui(); shop_pressed.emit()))
	box.add_child(_btn("退出", func() -> void: Sfx.play_ui(); quit_pressed.emit()))


func _btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(280, 56)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 22)
	NeonButton.apply(b)
	b.pressed.connect(cb)
	return b
