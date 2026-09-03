class_name MissSink
extends Area2D
## 回收坑：没进计分槽的币掉进来。不计分、不退币。没有它，期望值会爆。

func configure(size: Vector2) -> void:
	collision_layer = 4
	collision_mask = 1
	monitoring = true
	monitorable = false
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	cs.shape = rect
	add_child(cs)

	var vis := ColorRect.new()
	vis.size = size
	vis.position = -size * 0.5
	vis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vis.color = Color(0.35, 0.05, 0.2, 0.22)
	add_child(vis)

	var label := Label.new()
	label.text = "MISS"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = size
	label.position = -size * 0.5
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1, 0.4, 0.65, 0.55))
	add_child(label)

	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	var coin := body as Coin
	if coin == null:
		return
	if not coin.consume():
		return
	GameState.payout(0)
	coin.recycle_deferred()
