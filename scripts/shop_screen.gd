extends CanvasLayer
## 皮肤店：金免费，粉 30 / 青 80 / 钢 150。装备后投出去的币用对应图集格。

signal closed

var _from_pause: bool = false
var _cards: Array[Control] = []
var _back_btn: Button
var _balance: Label


func _ready() -> void:
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
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_bottom", 36)
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
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
	hint.text = "金色免费。只换外观，不改变赔率。解锁后装备，投出去的币用对应格子。"
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.75, 0.78, 0.9, 0.85))
	box.add_child(hint)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)

	for i in GameState.SKIN_COUNT:
		var card := _make_card(i)
		row.add_child(card)
		_cards.append(card)

	_back_btn = Button.new()
	_back_btn.text = "返回"
	_back_btn.custom_minimum_size = Vector2(200, 48)
	_back_btn.add_theme_font_size_override("font_size", 22)
	_back_btn.pressed.connect(func() -> void: Sfx.play_ui(); close())
	var back_wrap := CenterContainer.new()
	back_wrap.add_child(_back_btn)
	box.add_child(back_wrap)


func _make_card(index: int) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(180, 260)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)

	var name_l := Label.new()
	name_l.name = "Name"
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_font_size_override("font_size", 22)
	name_l.text = GameState.SKIN_NAMES[index]
	v.add_child(name_l)

	var tex := TextureRect.new()
	tex.name = "Preview"
	tex.custom_minimum_size = Vector2(96, 96)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var atlas := AtlasTexture.new()
	atlas.atlas = CoinSkins.ATLAS
	atlas.region = CoinSkins.region_for_index(index)
	tex.texture = atlas
	tex.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	v.add_child(tex)

	var cost := Label.new()
	cost.name = "Cost"
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost.add_theme_font_size_override("font_size", 16)
	v.add_child(cost)

	var action := Button.new()
	action.name = "Action"
	action.custom_minimum_size = Vector2(0, 40)
	action.pressed.connect(func() -> void: _on_card_action(index))
	v.add_child(action)
	return panel


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
		if GameState.is_unlocked(i):
			cost_l.text = "已解锁"
			if GameState.equipped_skin == i:
				action.text = "装备中"
				action.disabled = true
			else:
				action.text = "装备"
				action.disabled = false
		else:
			var c: int = GameState.skin_cost(i)
			cost_l.text = "%d 金币" % c
			action.text = "解锁"
			action.disabled = GameState.balance < c
