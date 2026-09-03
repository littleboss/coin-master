extends CanvasLayer
## 皮肤店三态：未拥有显示价格；已拥有显示「装备」；当前装备显示「使用中」。
## 预览只用 coin_skins.png 的第 n 格 Rect2(n*64,0,64,64)，没有单独立绘。
## 卡框用 hud_panel_9patch；按钮用 btn_9patch（texture_margin 16 / content_margin 12）。

signal closed

const HUD_PANEL := preload("res://assets/ui/hud_panel_9patch.png")
const HUD_PATCH := 12
const LABEL_EQUIP := "装备"
const LABEL_IN_USE := "使用中"

var _from_pause: bool = false
var _cards: Array[Control] = []
var _back_btn: Button
var _balance: Label


func _ready() -> void:
	name = "ShopScreen"
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	GameState.balance_changed.connect(_on_balance)
	GameState.skin_changed.connect(func(_i: int) -> void: _refresh_cards())
	visible = false


func open(from_pause: bool) -> void:
	_from_pause = from_pause
	visible = true
	_refresh_cards()
	_on_balance(GameState.balance)
	if _back_btn:
		_back_btn.grab_focus()


func close() -> void:
	visible = false
	closed.emit()


func came_from_pause() -> bool:
	return _from_pause


func _on_balance(v: int) -> void:
	if _balance:
		_balance.text = "金币  %d" % v
	_refresh_cards()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.04, 0.07, 0.94)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	var header := HBoxContainer.new()
	box.add_child(header)
	var title := Label.new()
	title.text = "皮肤店"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.2))
	header.add_child(title)
	_balance = Label.new()
	_balance.add_theme_font_size_override("font_size", 24)
	_balance.add_theme_color_override("font_color", Color(1.0, 0.84, 0.2))
	header.add_child(_balance)

	var hint := Label.new()
	hint.text = "只换外观，不改变赔率。金色免费且开局已拥有。预览是图集格子，不是立绘。"
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.75, 0.78, 0.9, 0.85))
	box.add_child(hint)

	# 2×2：1280×720 截图时每张卡够大，四格皮肤并排也能看清。
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(grid)

	for i in GameState.SKIN_COUNT:
		var card := _make_card(i)
		grid.add_child(card)
		_cards.append(card)

	_back_btn = Button.new()
	_back_btn.text = "返回"
	_back_btn.custom_minimum_size = Vector2(220, 56)
	_back_btn.add_theme_font_size_override("font_size", 22)
	NeonButton.apply(_back_btn)
	_back_btn.pressed.connect(func() -> void: Sfx.play_ui(); close())
	var back_wrap := CenterContainer.new()
	back_wrap.add_child(_back_btn)
	box.add_child(back_wrap)


func _make_card(index: int) -> Control:
	# 卡框：HUD 那张 32×32 九宫格。按钮另用 btn_9patch。
	var frame := NinePatchRect.new()
	frame.name = "Card_%d" % index
	frame.texture = HUD_PANEL
	frame.patch_margin_left = HUD_PATCH
	frame.patch_margin_top = HUD_PATCH
	frame.patch_margin_right = HUD_PATCH
	frame.patch_margin_bottom = HUD_PATCH
	frame.custom_minimum_size = Vector2(280, 280)
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var inner := MarginContainer.new()
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.offset_left = 0
	inner.offset_top = 0
	inner.offset_right = 0
	inner.offset_bottom = 0
	inner.add_theme_constant_override("margin_left", 16)
	inner.add_theme_constant_override("margin_right", 16)
	inner.add_theme_constant_override("margin_top", 14)
	inner.add_theme_constant_override("margin_bottom", 14)
	frame.add_child(inner)
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	inner.add_child(v)

	var name_l := Label.new()
	name_l.name = "Name"
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_font_size_override("font_size", 22)
	name_l.add_theme_color_override("font_color", Color(1.0, 0.92, 0.75))
	name_l.text = GameState.SKIN_NAMES[index]
	v.add_child(name_l)

	# 预览 = 图集第 index 格，放大显示。不要换别的立绘图。
	var tex := TextureRect.new()
	tex.name = "Preview"
	tex.custom_minimum_size = Vector2(128, 128)
	tex.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tex.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var atlas := AtlasTexture.new()
	atlas.atlas = CoinSkins.ATLAS
	atlas.region = Rect2(index * CoinSkins.CELL_SIZE, 0, CoinSkins.CELL_SIZE, CoinSkins.CELL_SIZE)
	tex.texture = atlas
	v.add_child(tex)

	var cost := Label.new()
	cost.name = "Cost"
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost.add_theme_font_size_override("font_size", 18)
	cost.add_theme_color_override("font_color", Color(1.0, 0.84, 0.2))
	v.add_child(cost)

	var action := Button.new()
	action.name = "Action"
	action.custom_minimum_size = Vector2(0, 56)
	NeonButton.apply(action)
	action.pressed.connect(func() -> void: _on_card_action(index))
	v.add_child(action)
	return frame


func _on_card_action(index: int) -> void:
	Sfx.play_ui()
	if GameState.is_unlocked(index):
		GameState.equip_skin(index)
		return
	if GameState.try_unlock(index):
		GameState.equip_skin(index)


func _refresh_cards() -> void:
	for i in _cards.size():
		var card := _cards[i]
		var cost_l := card.find_child("Cost", true, false) as Label
		var action := card.find_child("Action", true, false) as Button
		var preview := card.find_child("Preview", true, false) as TextureRect
		_ensure_preview_cell(preview, i)
		if GameState.equipped_skin == i and GameState.is_unlocked(i):
			cost_l.text = ""
			action.text = LABEL_IN_USE
			action.disabled = true
		elif GameState.is_unlocked(i):
			cost_l.text = ""
			action.text = LABEL_EQUIP
			action.disabled = false
		else:
			var c: int = GameState.skin_cost(i)
			var price := "%d 金币" % c
			cost_l.text = price
			action.text = price
			action.disabled = GameState.balance < c


func _ensure_preview_cell(preview: TextureRect, index: int) -> void:
	if preview == null:
		return
	var want := Rect2(index * CoinSkins.CELL_SIZE, 0, CoinSkins.CELL_SIZE, CoinSkins.CELL_SIZE)
	var atlas := preview.texture as AtlasTexture
	if atlas == null or atlas.atlas != CoinSkins.ATLAS:
		atlas = AtlasTexture.new()
		atlas.atlas = CoinSkins.ATLAS
		preview.texture = atlas
	atlas.region = want
