class_name ScoreSlot
extends Area2D
## 计分槽。Area2D 检测金币；每枚币只计一次。
## 头奖槽会在底部来回平移（ping-pong）。
## 10x 才放 GPUParticles2D 火花；1x / 2x / miss 没有粒子。

const JACKPOT_PARTICLE_COUNT := 16
const JACKPOT_PARTICLE_LIFE := 0.35
const ART_SIZE := Vector2(128, 48)
const TEX_NORMAL := preload("res://assets/slots/slot_normal.png")
const TEX_LUCKY := preload("res://assets/slots/slot_lucky.png")
const TEX_JACKPOT := preload("res://assets/slots/slot_jackpot.png")
const SPARK_PATH := "res://assets/vfx/jackpot_spark.png"

@export var multiplier: int = 1
@export var debug_color: Color = Color(1, 0.843, 0, 0.3)
@export var label_text: String = "1x"
@export var moving: bool = false
@export var pingpong_period: float = 2.4

var slot_size: Vector2 = Vector2(100, 44)
var _travel_min_x: float = 0.0
var _travel_max_x: float = 0.0
var _travel_t: float = 0.0
var _particles: GPUParticles2D
var _label: Label


func configure(
		p_size: Vector2,
		p_multiplier: int,
		p_color: Color,
		p_label: String,
		p_moving: bool = false,
		p_period: float = 2.4
	) -> void:
	slot_size = p_size
	multiplier = p_multiplier
	debug_color = p_color
	label_text = p_label
	moving = p_moving
	pingpong_period = p_period
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
		_particles = _make_jackpot_burst()
		if _particles:
			add_child(_particles)


func _make_jackpot_burst() -> GPUParticles2D:
	# 只用 Pixel 的 32px 火花，不另做一张粒子图。
	if not ResourceLoader.exists(SPARK_PATH):
		return null
	var p := GPUParticles2D.new()
	p.name = "JackpotBurst"
	p.amount = JACKPOT_PARTICLE_COUNT
	p.lifetime = JACKPOT_PARTICLE_LIFE
	p.one_shot = true
	p.explosiveness = 1.0
	p.emitting = false
	p.texture = load(SPARK_PATH)
	p.local_coords = true
	var blend := CanvasItemMaterial.new()
	blend.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = blend
	var mat := ParticleProcessMaterial.new()
	mat.particle_flag_disable_z = true
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 6.0
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 70.0
	mat.initial_velocity_max = 170.0
	mat.gravity = Vector3(0, 160, 0)
	mat.scale_min = 0.45
	mat.scale_max = 1.05
	p.process_material = mat
	return p


func _physics_process(delta: float) -> void:
	if not moving:
		return
	var dist := _travel_max_x - _travel_min_x
	if dist <= 0.0 or pingpong_period <= 0.0:
		return
	_travel_t += delta
	# 全程往返 2.4s：1.2s 到头，1.2s 回来。
	position.x = _travel_min_x + pingpong(_travel_t * (2.0 * dist / pingpong_period), dist)


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
