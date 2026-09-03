extends SceneTree
## 无头冒烟：不依赖窗口。用 godot --headless --path . -s res://scripts/headless_smoke.gd

var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== Coin Master 2D P0 smoke ===")
	_check("GameState starting balance", GameState.STARTING_BALANCE == 50)
	_check("save path is user://", GameState.SAVE_PATH.begins_with("user://"))
	_check("toss cost 1", GameState.TOSS_COST == 1)
	_check("coin radius 28", is_equal_approx(Coin.RADIUS, 28.0))
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
		var coin := coin_scene.instantiate() as Coin
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

	var main_scene := load("res://scenes/main.tscn") as PackedScene
	_check("main.tscn loads", main_scene != null)

	var bounce: PhysicsMaterial = load("res://assets/physics/coin_physics.tres")
	_check("coin bounce in 0.4-0.6", bounce != null and bounce.bounce >= 0.4 and bounce.bounce <= 0.6)

	if _failed == 0:
		print("SMOKE OK")
		quit(0)
	else:
		print("SMOKE FAILED: %d check(s)" % _failed)
		quit(1)


func _check(name: String, ok: bool) -> void:
	if ok:
		print("  PASS  ", name)
	else:
		_fail(name)


func _fail(name: String) -> void:
	_failed += 1
	print("  FAIL  ", name)
