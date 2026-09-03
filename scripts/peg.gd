class_name Peg
extends StaticBody2D
## 钉子：StaticBody2D + 圆碰撞。画面只用 peg.png（32px），碰撞半径必须是 12。
## 不要 ColorRect / Polygon2D 空心调试钉。

const SPRITE := preload("res://assets/pegs/peg.png")

var radius: float = 12.0


func configure(p_radius: float, material: PhysicsMaterial) -> void:
	radius = p_radius
	collision_layer = 2
	collision_mask = 0
	physics_material_override = material
	var cs := CollisionShape2D.new()
	cs.name = "CollisionShape2D"
	var circle := CircleShape2D.new()
	circle.radius = radius
	cs.shape = circle
	add_child(cs)

	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = SPRITE
	sprite.texture_filter = TEXTURE_FILTER_LINEAR
	sprite.centered = true
	# 32px 图对半径 12 的碰撞略大一圈，这是美术光晕，不要缩放碰撞。
	add_child(sprite)
