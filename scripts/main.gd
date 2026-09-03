extends Node
## 主场景：Playfield + HUD。锁 60 FPS，确认重力向下。

func _ready() -> void:
	Engine.max_fps = 60
	Engine.physics_ticks_per_second = 60
	# 2D 默认重力方向 (0, 1)，数值在项目设置里 980 px/s²。
	if ProjectSettings.has_setting("physics/2d/default_gravity_vector"):
		var g: Vector2 = ProjectSettings.get_setting("physics/2d/default_gravity_vector")
		if g.y <= 0.0:
			push_warning("Main: 重力向量不是向下，币可能不会落入槽位。")
	if _wants_smoke():
		var smoke := preload("res://scripts/headless_smoke.gd").new()
		add_child(smoke)


func _wants_smoke() -> bool:
	if OS.get_cmdline_user_args().has("--smoke"):
		return true
	return OS.get_cmdline_args().has("--smoke")
