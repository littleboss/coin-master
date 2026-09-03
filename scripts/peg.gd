class_name Peg
extends StaticBody2D
## 钉子：StaticBody2D + 圆碰撞。三行交错钉板，挡住直瞄幸运/头奖槽。

var radius: float = 12.0
var fill: Color = Color(0.15, 0.85, 1.0, 0.9)


func configure(p_radius: float, p_color: Color, material: PhysicsMaterial) -> void:
	radius = p_radius
	fill = p_color
	collision_layer = 2
	collision_mask = 0
	physics_material_override = material
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	cs.shape = circle
	add_child(cs)
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, fill)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 20, Color(1, 1, 1, 0.45), 2.0, true)
	draw_circle(Vector2(-radius * 0.25, -radius * 0.25), radius * 0.28, Color(1, 1, 1, 0.22))
