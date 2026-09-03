extends Node
## 给 Pixel 的店内 / 局内截图。
##   godot --resolution 1280x720 --path . -- --shots
## 三态样例：金=使用中，粉=已拥有可装备，青/钢=未拥有显示价格。

const OUT_DIR := "/opt/cursor/artifacts"


func _ready() -> void:
	await get_tree().process_frame
	await _run()


func _run() -> void:
	var main := get_parent()
	DirAccess.make_dir_recursive_absolute(OUT_DIR)

	# 固定样例，让一张店图同时看到三种状态。
	var owned: Array[int] = [0, 1]
	GameState.unlocked_skins = owned
	GameState.equipped_skin = 0
	GameState.balance = 50
	GameState.save()
	GameState.skin_changed.emit(GameState.equipped_skin)
	GameState.balance_changed.emit(GameState.balance)

	main._open_shop(false)
	await get_tree().process_frame
	await get_tree().process_frame
	_save("shop_three_state.png")

	# 关掉商店会回标题；再进游玩拍机柜 + HUD。
	main._shop.close()
	await get_tree().process_frame
	main._enter_play()
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	if main._playfield.spawner:
		main._playfield.spawner.try_toss_at_x(main._playfield.spawner.aim_world_x(0.5))
	for i in 24:
		await get_tree().physics_frame
	_save("ingame_playfield.png")

	print("SHOTS OK")
	get_tree().quit(0)


func _save(filename: String) -> void:
	var img := get_viewport().get_texture().get_image()
	if img == null:
		push_error("shots: viewport image is null")
		get_tree().quit(1)
		return
	var path := OUT_DIR.path_join(filename)
	var err := img.save_png(path)
	print("  shot  ", path, " err=", err)
