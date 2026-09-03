class_name Coin
extends RigidBody2D
## 对象池里的一枚币：RigidBody2D + CircleShape2D(半径 28)。
## 激活时从桌顶落下；碰到槽或 miss 后 deactivate，回到池里，绝不无限 new。

signal returned_to_pool(coin: Coin)

const RADIUS := 28.0
const MAX_LIFETIME := 10.0

var is_pooled_active: bool = false
var _consumed: bool = false
var _alive_time: float = 0.0


func _ready() -> void:
	# 保险：万一场景里没设 region，也锁到金色第 0 格。
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.texture_filter = TEXTURE_FILTER_LINEAR
		sprite.region_enabled = true
		if sprite.region_rect.size == Vector2.ZERO:
			sprite.region_rect = CoinSkins.DEFAULT_TOSS_SKIN


func activate(global_pos: Vector2) -> void:
	_consumed = false
	is_pooled_active = true
	_alive_time = 0.0
	# 空中速度为 0 时刚体可能立刻 sleeping，永远不往下掉。
	can_sleep = false
	freeze = true
	global_position = global_pos
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	visible = true
	collision_layer = 1
	collision_mask = 6
	var shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape:
		shape.disabled = false
	freeze = false
	sleeping = false
	# 极小角速度，避免每枚币看起来一模一样；只给竖直冲量，不改瞄准 X。
	angular_velocity = randf_range(-2.5, 2.5)
	apply_central_impulse(Vector2(randf_range(-16.0, 16.0), 60.0))


func consume() -> bool:
	## 一枚币只结算一次。槽和 miss 都会调用；第一个人赢。
	if _consumed or not is_pooled_active:
		return false
	_consumed = true
	return true


func deactivate() -> void:
	var should_emit := is_pooled_active
	is_pooled_active = false
	_consumed = true
	freeze = true
	sleeping = true
	can_sleep = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	visible = false
	collision_layer = 0
	collision_mask = 0
	var shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape:
		shape.disabled = true
	# 挪出视野，避免残留接触。
	global_position = Vector2(-10000.0, -10000.0)
	# 只有真正从场上回收时才回池，初始化 deactivate 不能把同一枚币塞进队列两次。
	if should_emit:
		returned_to_pool.emit(self)


func _physics_process(_delta: float) -> void:
	if not is_pooled_active:
		return
	_alive_time += _delta
	# 卡住或飞出台面时回收名额，避免池被占满。
	if _alive_time > MAX_LIFETIME or global_position.y > 4000.0 or global_position.x < -800.0 or global_position.x > 4000.0:
		if consume():
			recycle_deferred()


func recycle_deferred() -> void:
	call_deferred("deactivate")
