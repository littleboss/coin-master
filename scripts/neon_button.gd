class_name NeonButton
extends RefCounted
## Pixel 霓虹九宫格按钮：同一张 64×64 图用于 normal / hover / pressed。
## texture_margin 16 保住粉边和青角；content_margin 12 让文字离霓虹框远一点。

const TEX_PATH := "res://assets/ui/btn_9patch.png"
const TEXTURE_MARGIN := 16.0
const CONTENT_MARGIN := 12.0


static func apply(btn: Button) -> void:
	if btn == null:
		return
	if not ResourceLoader.exists(TEX_PATH):
		return
	var tex: Texture2D = load(TEX_PATH)
	# 同一张图，只改 modulate，避免做三套切片。
	btn.add_theme_stylebox_override("normal", _box(tex, Color(1.0, 1.0, 1.0, 1.0)))
	btn.add_theme_stylebox_override("hover", _box(tex, Color(1.18, 1.08, 1.28, 1.0)))
	btn.add_theme_stylebox_override("pressed", _box(tex, Color(0.72, 0.82, 1.12, 1.0)))
	btn.add_theme_stylebox_override("hover_pressed", _box(tex, Color(0.72, 0.82, 1.12, 1.0)))
	btn.add_theme_stylebox_override("focus", _box(tex, Color(1.12, 1.06, 1.22, 1.0)))
	btn.add_theme_stylebox_override("disabled", _box(tex, Color(0.48, 0.50, 0.58, 0.72)))
	btn.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.78, 0.92, 1.0, 1.0))
	btn.add_theme_color_override("font_focus_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_disabled_color", Color(0.65, 0.68, 0.75, 0.85))


static func _box(tex: Texture2D, modulate: Color) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = TEXTURE_MARGIN
	sb.texture_margin_top = TEXTURE_MARGIN
	sb.texture_margin_right = TEXTURE_MARGIN
	sb.texture_margin_bottom = TEXTURE_MARGIN
	sb.content_margin_left = CONTENT_MARGIN
	sb.content_margin_top = CONTENT_MARGIN
	sb.content_margin_right = CONTENT_MARGIN
	sb.content_margin_bottom = CONTENT_MARGIN
	sb.modulate_color = modulate
	sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	return sb
