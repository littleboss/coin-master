extends CanvasLayer
## 标题：开始 / 皮肤店 / 退出。Logo 用 1536×1024 原图，不裁成横幅。

signal start_pressed
signal shop_pressed
signal quit_pressed

const LOGO_PATH := "res://assets/ui/logo.png"

var _start_btn: Button


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func refresh() -> void:
	pass


func focus_default() -> void:
	if _start_btn:
		_start_btn.grab_focus()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(480, 0)
	box.add_theme_constant_override("separation", 16)
	center.add_child(box)

	# 1536×1024 叠字 Logo：按比例完整显示，绝不裁成宽 Banner。
	# 图还没进仓库时用色块叠字占位，避免标题空白。
	if ResourceLoader.exists(LOGO_PATH):
		var logo := TextureRect.new()
		logo.texture = load(LOGO_PATH)
		logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo.custom_minimum_size = Vector2(540, 360)
		logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(logo)
	else:
		var stacked := Label.new()
		stacked.text = "COIN\nMASTER\n2D"
		stacked.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	b.custom_minimum_size = Vector2(0, 48)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(cb)
	return b
