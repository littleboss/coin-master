class_name Peg
extends StaticBody2D
## 钉子：StaticBody2D + 圆碰撞。美术 32px（peg.png），碰撞半径必须是 12（不是 16）。

const SPRITE := preload("res://assets/pegs/peg.png")
const SPRITE_SIZE := 32.0

var radius: float = 12.0


func configure(p_radius: float, _p_color: Color, material: PhysicsMaterial) -> void:
	radius = p_radius
	collision_layer = 2
	collision_mask = 0
	physics_material_override = material
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	cs.shape = circle
	add_child(cs)

	var sprite := Sprite2D.new()
	sprite.texture = SPRITE
	sprite.texture_filter = TEXTURE_FILTER_LINEAR
	sprite.centered = true
	# 32px 图对半径 12 的碰撞略大一圈，这是美术光晕，不要缩放碰撞。
	add_child(sprite)
