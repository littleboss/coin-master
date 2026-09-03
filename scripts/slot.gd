class_name ScoreSlot
extends Area2D
## 计分槽。Area2D 检测金币；每枚币只计一次。
## 头奖槽会在底部来回平移（ping-pong）。

const JACKPOT_PARTICLE_COUNT := 18
const ART_SIZE := Vector2(128, 48)
const TEX_NORMAL := preload("res://assets/slots/slot_normal.png")
const TEX_LUCKY := preload("res://assets/slots/slot_lucky.png")
const TEX_JACKPOT := preload("res://assets/slots/slot_jackpot.png")

@export var multiplier: int = 1
@export var debug_color: Color = Color(1, 0.843, 0, 0.3)
@export var label_text: String = "1x"
@export var moving: bool = false
@export var move_speed: float = 160.0

var slot_size: Vector2 = Vector2(100, 44)
var _travel_min_x: float = 0.0
var _travel_max_x: float = 0.0
var _dir: float = 1.0
var _particles: CPUParticles2D
var _label: Label


func configure(
		p_size: Vector2,
		p_multiplier: int,
		p_color: Color,
		p_label: String,
		p_moving: bool = false,
		p_speed: float = 160.0
	) -> void:
	slot_size = p_size
	multiplier = p_multiplier
	debug_color = p_color
	label_text = p_label
	moving = p_moving
	move_speed = p_speed
	collision_layer = 4
	collision_mask = 1
	monitoring = true
	monitorable = true
	_build_visuals()
	body_entered.connect(_on_body_entered)


func set_travel_bounds(min_center_x: float, max_center_x: float) -> void:
	_travel_min_x = min_center_x
	_travel_max_x = max_center_x


func _build_visuals() -> void:
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = slot_size
	cs.shape = rect
	add_child(cs)

	var sprite := Sprite2D.new()
	sprite.texture = _texture_for_multiplier(multiplier)
	sprite.texture_filter = TEXTURE_FILTER_LINEAR
	sprite.centered = true
	# 美术是 128×48；槽的逻辑宽度按 EV 拉伸，换 PNG 不用改碰撞。
	sprite.scale = Vector2(slot_size.x / ART_SIZE.x, slot_size.y / ART_SIZE.y)
	add_child(sprite)

	_label = Label.new()
	_label.text = label_text
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.size = slot_size
	_label.position = -slot_size * 0.5
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.92))
	add_child(_label)

	if multiplier >= 10:
		_particles = CPUParticles2D.new()
		_particles.emitting = false
		_particles.one_shot = true
		_particles.explosiveness = 1.0
		_particles.amount = JACKPOT_PARTICLE_COUNT
		_particles.lifetime = 0.4
		_particles.direction = Vector2(0, -1)
		_particles.spread = 180.0
		_particles.gravity = Vector2(0, 280)
		_particles.initial_velocity_min = 90.0
		_particles.initial_velocity_max = 220.0
		_particles.scale_amount_min = 2.0
		_particles.scale_amount_max = 4.5
		_particles.color = Color(0.0, 0.94, 1.0, 1.0)
		add_child(_particles)


func _physics_process(delta: float) -> void:
	if not moving:
		return
	position.x += _dir * move_speed * delta
	if position.x >= _travel_max_x:
		position.x = _travel_max_x
		_dir = -1.0
	elif position.x <= _travel_min_x:
		position.x = _travel_min_x
		_dir = 1.0


func _on_body_entered(body: Node) -> void:
	var coin := body as Coin
	if coin == null:
		return
	if not coin.consume():
		return
	# 不在这里关掉整个槽的 monitoring：那会让其它币再也进不了这个槽。
	# 「一次一币」靠 coin.consume()。
	GameState.payout(multiplier)
	Sfx.play_slot(multiplier)
	if _particles:
		_particles.restart()
	coin.recycle_deferred()


func _texture_for_multiplier(mult: int) -> Texture2D:
	if mult >= 10:
		return TEX_JACKPOT
	if mult >= 2:
		return TEX_LUCKY
	return TEX_NORMAL
