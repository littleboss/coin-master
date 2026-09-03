extends Node
## 无头冒烟：随主场景跑，才能用到 autoload。
##   godot --headless --resolution 1280x720 --path . -- --smoke

var _failed := 0


func _ready() -> void:
	await get_tree().process_frame
	await _run()


func _run() -> void:
	print("=== Coin Master 2D P0 smoke ===")
	_check("GameState starting balance const", GameState.STARTING_BALANCE == 50)
	_check("save path is user://", GameState.SAVE_PATH.begins_with("user://"))
	_check("toss cost 1", GameState.TOSS_COST == 1)
	_check("peg radius 12", is_equal_approx(Playfield.PEG_RADIUS, 12.0))
	_check("slot art height 48", is_equal_approx(Playfield.SLOT_HEIGHT, 48.0))
	_check("jackpot ~10% inner width", is_equal_approx(Playfield.JACKPOT_WIDTH_FRAC, 0.10))
	_check("jackpot period 2.4", is_equal_approx(Playfield.JACKPOT_PERIOD, 2.4))
	_check("peg rows 7-6-7", Playfield.PEG_COUNTS.size() == 3 and Playfield.PEG_COUNTS[0] == 7 and Playfield.PEG_COUNTS[1] == 6 and Playfield.PEG_COUNTS[2] == 7)
	_check("mercy amount 10", GameState.MERCY_AMOUNT == 10)
	_check("cooldown 0.2", is_equal_approx(CoinSpawner.TOSS_COOLDOWN, 0.20))
	_check("pool is bounded", CoinSpawner.POOL_SIZE > 0 and CoinSpawner.POOL_SIZE <= 64)
	_check("gold cell 0", CoinSkins.DEFAULT_TOSS_SKIN == Rect2(0, 0, 64, 64))
	_check("pink cell 1", CoinSkins.PINK == Rect2(64, 0, 64, 64))
	_check("cyan cell 2", CoinSkins.CYAN == Rect2(128, 0, 64, 64))
	_check("steel cell 3", CoinSkins.STEEL == Rect2(192, 0, 64, 64))

	var atlas: Texture2D = CoinSkins.ATLAS
	_check("atlas loads", atlas != null)
	if atlas:
		_check("atlas 256x64", atlas.get_width() == 256 and atlas.get_height() == 64)

	var coin_scene := load("res://scenes/coin.tscn") as PackedScene
	_check("coin.tscn loads", coin_scene != null)
	if coin_scene:
		var coin := coin_scene.instantiate() as RigidBody2D
		_check("coin is RigidBody2D", coin is RigidBody2D)
		var shape_node := coin.get_node_or_null("CollisionShape2D") as CollisionShape2D
		_check("has CollisionShape2D", shape_node != null)
		if shape_node and shape_node.shape is CircleShape2D:
			var circle := shape_node.shape as CircleShape2D
			_check("CircleShape2D radius 28", is_equal_approx(circle.radius, 28.0))
		else:
			_fail("CircleShape2D radius 28")
		var sprite := coin.get_node_or_null("Sprite2D") as Sprite2D
		_check("region enabled", sprite != null and sprite.region_enabled)
		if sprite:
			_check("P0 uses cell 0", sprite.region_rect == Rect2(0, 0, 64, 64))
		coin.free()

	var table_tex: Texture2D = load("res://assets/bg/table.png")
	_check("table art loads", table_tex != null)
	if table_tex:
		_check("table 1920x1080", table_tex.get_width() == 1920 and table_tex.get_height() == 1080)

	var logo_tex: Texture2D = load("res://assets/ui/logo.png")
	_check("logo art loads", logo_tex != null)
	if logo_tex:
		_check("logo 1536x1024", logo_tex.get_width() == 1536 and logo_tex.get_height() == 1024)

	var btn_tex: Texture2D = load("res://assets/ui/btn_9patch.png")
	_check("btn 9-patch loads", btn_tex != null)
	if btn_tex:
		_check("btn 9-patch 64x64", btn_tex.get_width() == 64 and btn_tex.get_height() == 64)

	var playfield := get_parent().get_node_or_null("Playfield") as Playfield
	_check("has Playfield", playfield != null)
	if playfield:
		_check("has 7-6-7 pegs", playfield.get_node("Pegs").get_child_count() == 20)
		_check("has slots", playfield.get_node("Slots").get_child_count() >= 4)
		_check("drop y is table top", playfield.drop_y <= playfield.table.position.y + 20.0)
		_check("spawner exists", playfield.spawner != null)
		var table_bg := playfield.get_node_or_null("BgLayer/Table") as TextureRect
		_check("playfield has table bg", table_bg != null)
		if table_bg:
			_check("table cover/center-crop", table_bg.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED)
			_check("table not stretched", table_bg.stretch_mode != TextureRect.STRETCH_SCALE)
		var title := get_parent().get_node_or_null("TitleScreen")
		_check("has title screen", title != null)
		if title:
			var logo := title.get("_logo") as TextureRect
			_check("logo letterbox/fit", logo != null and logo.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
			_check("logo not cover-crop banner", logo != null and logo.stretch_mode != TextureRect.STRETCH_KEEP_ASPECT_COVERED)
			var start_btn := title.get("_start_btn") as Button
			_check("title start is Button", start_btn != null)
			if start_btn:
				var normal := start_btn.get_theme_stylebox("normal") as StyleBoxTexture
				_check("title start uses 9-patch", normal != null and normal.texture == load("res://assets/ui/btn_9patch.png"))
				if normal:
					_check("btn texture_margin 16", is_equal_approx(normal.texture_margin_left, 16.0) and is_equal_approx(normal.texture_margin_top, 16.0) and is_equal_approx(normal.texture_margin_right, 16.0) and is_equal_approx(normal.texture_margin_bottom, 16.0))
					_check("btn content_margin ~12", is_equal_approx(normal.content_margin_left, 12.0) and is_equal_approx(normal.content_margin_top, 12.0))
					var hover := start_btn.get_theme_stylebox("hover") as StyleBoxTexture
					var pressed := start_btn.get_theme_stylebox("pressed") as StyleBoxTexture
					_check("hover/pressed same texture", hover != null and pressed != null and hover.texture == normal.texture and pressed.texture == normal.texture)
		if playfield._jackpot:
			var inner := playfield.inner_right - playfield.inner_left
			var frac := playfield._jackpot.slot_size.x / inner
			_check("jackpot width ~10%", frac > 0.08 and frac < 0.12)
			_check("jackpot pingpong 2.4", is_equal_approx(playfield._jackpot.pingpong_period, 2.4))
		if playfield.spawner:
			var before := GameState.balance
			var tossed := playfield.spawner.try_toss_at_x(playfield.spawner.aim_world_x(0.5))
			_check("toss spends 1", tossed and GameState.balance == before - 1)
			_check("active coin after toss", playfield.spawner.active_count() >= 1)
			await get_tree().physics_frame
			await get_tree().physics_frame
			var sample := _first_live_coin(playfield)
			if sample:
				print("  info  coin pos=", sample.global_position, " v=", sample.linear_velocity)
			# 冷却中再投应失败且不再扣费
			var mid := GameState.balance
			var second := playfield.spawner.try_toss_at_x(playfield.spawner.aim_world_x(0.5))
			_check("cooldown blocks second toss", not second and GameState.balance == mid)
			# 等这枚币落到槽/回收坑，确认池子会收回（物理循环真的在转）。
			var frames := 0
			var last_pos := Vector2.ZERO
			while frames < 480 and playfield.spawner.active_count() > 0:
				await get_tree().physics_frame
				frames += 1
				var live := _first_live_coin(playfield)
				if live:
					last_pos = live.global_position
			_check("coin recycled after fall", playfield.spawner.active_count() == 0)
			print("  info  settle frames=", frames, " balance=", GameState.balance, " last_pos=", last_pos)

	var bounce: PhysicsMaterial = load("res://assets/physics/coin_physics.tres")
	_check("coin bounce in 0.4-0.6", bounce != null and bounce.bounce >= 0.4 and bounce.bounce <= 0.6)
	_check("save still user://", GameState.SAVE_PATH.begins_with("user://") and not GameState.SAVE_PATH.begins_with("res://"))
	_check("gold skin free", GameState.SKIN_COSTS[0] == 0)
	_check("gold unlocked", GameState.is_unlocked(0))
	_check("pink costs 30", GameState.SKIN_COSTS[1] == 30)
	_check("cyan costs 80", GameState.SKIN_COSTS[2] == 80)
	_check("steel costs 150", GameState.SKIN_COSTS[3] == 150)
	_check("default equipped gold", GameState.equipped_skin == 0 or GameState.is_unlocked(GameState.equipped_skin))
	GameState.balance = 200
	_check("can unlock pink", GameState.try_unlock(1))
	_check("can equip pink", GameState.equip_skin(1) and GameState.equipped_skin == 1)
	_check("equipped region pink", GameState.equipped_region() == Rect2(64, 0, 64, 64))
	GameState.equip_skin(0)

	var shop := get_parent().get_node_or_null("ShopScreen")
	_check("has shop screen", shop != null)
	if shop:
		var owned: Array[int] = [0, 1]
		GameState.unlocked_skins = owned
		GameState.equipped_skin = 0
		GameState.balance = 50
		shop._refresh_cards()
		_check("gold starts owned", GameState.is_unlocked(0) and GameState.SKIN_COSTS[0] == 0)
		var gold_btn := shop._cards[0].find_child("Action", true, false) as Button
		var pink_btn := shop._cards[1].find_child("Action", true, false) as Button
		var cyan_btn := shop._cards[2].find_child("Action", true, false) as Button
		var steel_btn := shop._cards[3].find_child("Action", true, false) as Button
		_check("equipped is 使用中", gold_btn != null and gold_btn.text == "使用中" and gold_btn.disabled)
		_check("owned is 装备", pink_btn != null and pink_btn.text == "装备" and not pink_btn.disabled)
		_check("unowned cyan shows 80", cyan_btn != null and cyan_btn.text.contains("80"))
		_check("unowned steel shows 150", steel_btn != null and steel_btn.text.contains("150"))
		for i in 4:
			var preview := shop._cards[i].find_child("Preview", true, false) as TextureRect
			var atlas: AtlasTexture = null
			if preview:
				atlas = preview.texture as AtlasTexture
			_check("card %d uses atlas cell" % i, atlas != null and atlas.atlas == CoinSkins.ATLAS and atlas.region == Rect2(i * 64, 0, 64, 64))
		var gold_frame := shop._cards[0] as NinePatchRect
		_check("card frame is hud 9-patch", gold_frame != null and gold_frame.texture == load("res://assets/ui/hud_panel_9patch.png"))
		var gold_style := gold_btn.get_theme_stylebox("normal") as StyleBoxTexture
		_check("shop btn is btn_9patch", gold_style != null and gold_style.texture == load("res://assets/ui/btn_9patch.png"))
		if gold_style:
			_check("shop btn texture_margin 16", is_equal_approx(gold_style.texture_margin_left, 16.0))
			_check("shop btn content_margin 12", is_equal_approx(gold_style.content_margin_left, 12.0))

	GameState._mercy_used_this_session = false
	GameState.balance = 0
	GameState._persist_and_notify()
	_check("mercy grants 10 at 0", GameState.balance == GameState.MERCY_AMOUNT)
	GameState.balance = 0
	GameState._persist_and_notify()
	_check("mercy once per session", GameState.balance == 0)
	GameState.balance = GameState.STARTING_BALANCE
	GameState.save()

	if _failed == 0:
		print("SMOKE OK")
		get_tree().quit(0)
	else:
		print("SMOKE FAILED: %d check(s)" % _failed)
		get_tree().quit(1)


func _check(name: String, ok: bool) -> void:
	if ok:
		print("  PASS  ", name)
	else:
		_fail(name)


func _fail(name: String) -> void:
	_failed += 1
	print("  FAIL  ", name)


func _first_live_coin(playfield: Playfield) -> RigidBody2D:
	var coins := playfield.get_node("Coins")
	for child in coins.get_children():
		var rb := child as RigidBody2D
		if rb and rb.visible and rb.global_position.x > -1000.0:
			return rb
	return null
