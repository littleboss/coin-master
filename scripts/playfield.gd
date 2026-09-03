class_name Playfield
extends Node2D
## 台面：墙、7-6-7 交错钉、底部 1x/2x/移动 10x 槽、miss 回收带。
## 投币高度锁在桌顶；横向瞄准钳在内宽。
## 钉/槽宽度按「手感 EV≈0.9」排：miss ~40%、1x ~45%、2x ~13%、10x 叠层约 10% 内宽。
## 不改倍率、不改随机数，只调布局。

const PEG_RADIUS := 12.0
const PEG_ROWS := 3
const PEG_COUNTS: Array[int] = [7, 6, 7]
const WALL_THICKNESS := 28.0
const SLOT_HEIGHT := 48.0
const JACKPOT_HEIGHT := 48.0
const JACKPOT_WIDTH_FRAC := 0.10
const JACKPOT_PERIOD := 2.4
# 两个 2x 合计约 13%；1x 约 45%；剩下约 42% 是 miss 缝。
const LUCKY_WIDTH_FRAC := 0.065
const NORMAL_WIDTH_FRAC := 0.45

var table: Rect2 = Rect2(200, 64, 880, 620)
var drop_y: float = 80.0
var inner_left: float = 228.0
var inner_right: float = 1052.0

var spawner: CoinSpawner
var _jackpot: ScoreSlot
var _aim_x: float = 640.0

@onready var _pegs: Node2D = $Pegs
@onready var _slots: Node2D = $Slots
@onready var _bounds: StaticBody2D = $Bounds
@onready var _coins: Node2D = $Coins
@onready var _spawner_node: CoinSpawner = $CoinSpawner


func _ready() -> void:
	_layout_from_viewport()
	_build_bounds()
	_build_pegs()
	_build_slots_and_sink()
	_setup_spawner()
	InputRouter.toss_requested.connect(_on_toss_requested)
	queue_redraw()


func _process(_delta: float) -> void:
	_aim_x = spawner.aim_world_x(InputRouter.aim_t)
	queue_redraw()


func _layout_from_viewport() -> void:
	var vp := get_viewport_rect().size
	# 给顶部 HUD 留空，左右留边。expand 拉伸下 16:9 / 16:10 / 19.5:9 都能用。
	var margin_x := maxf(36.0, vp.x * 0.07)
	var margin_top := maxf(72.0, vp.y * 0.11)
	var margin_bot := maxf(18.0, vp.y * 0.03)
	table = Rect2(
		margin_x,
		margin_top,
		vp.x - margin_x * 2.0,
		vp.y - margin_top - margin_bot
	)
	inner_left = table.position.x + WALL_THICKNESS
	inner_right = table.position.x + table.size.x - WALL_THICKNESS
	drop_y = table.position.y + 10.0


func _build_bounds() -> void:
	_bounds.collision_layer = 2
	_bounds.collision_mask = 0
	_bounds.physics_material_override = preload("res://assets/physics/wall_physics.tres")
	var left := table.position.x + WALL_THICKNESS * 0.5
	var right := table.position.x + table.size.x - WALL_THICKNESS * 0.5
	var mid_y := table.position.y + table.size.y * 0.5
	_add_wall_rect(Vector2(left, mid_y), Vector2(WALL_THICKNESS, table.size.y))
	_add_wall_rect(Vector2(right, mid_y), Vector2(WALL_THICKNESS, table.size.y))
	# 顶沿只做很薄的左右挡头，中间开口让币从桌顶落下。
	var top_y := table.position.y + 8.0
	_add_wall_rect(Vector2(left, top_y), Vector2(WALL_THICKNESS, 16.0))
	_add_wall_rect(Vector2(right, top_y), Vector2(WALL_THICKNESS, 16.0))


func _add_wall_rect(center: Vector2, size: Vector2) -> void:
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	cs.shape = rect
	cs.position = center
	_bounds.add_child(cs)


func _build_pegs() -> void:
	var peg_mat := preload("res://assets/physics/peg_physics.tres")
	# 先避开墙和币半径，再加两侧 miss 边道，让币更容易从钉林两侧漏下去。
	var inset := Coin.RADIUS + PEG_RADIUS + 18.0
	var usable_left := inner_left + inset
	var usable_right := inner_right - inset
	var gutter := (usable_right - usable_left) * 0.11
	usable_left += gutter
	usable_right -= gutter
	var usable_w := usable_right - usable_left
	var y0 := table.position.y + table.size.y * 0.20
	var y_step := table.size.y * 0.14
	# 跟机柜图一样的 7-6-7。画面只用 peg.png，不再传调试色。
	for row in PEG_ROWS:
		var count: int = PEG_COUNTS[row]
		var y := y0 + float(row) * y_step
		var spacing: float
		var start_x: float
		if row % 2 == 0:
			spacing = usable_w / float(count - 1)
			start_x = usable_left
		else:
			spacing = usable_w / float(count)
			start_x = usable_left + spacing * 0.5
		for i in count:
			var peg := Peg.new()
			_pegs.add_child(peg)
			peg.position = Vector2(start_x + spacing * float(i), y)
			peg.configure(PEG_RADIUS, peg_mat)


func _build_slots_and_sink() -> void:
	var inner_w := inner_right - inner_left
	var lucky_w := inner_w * LUCKY_WIDTH_FRAC
	var normal_w := inner_w * NORMAL_WIDTH_FRAC
	var jackpot_w := inner_w * JACKPOT_WIDTH_FRAC
	var slot_y := table.position.y + table.size.y - 70.0
	var jackpot_y := slot_y - 56.0

	# 缝：两侧 + 槽与槽之间。剩余宽度均分给 miss 开口（槽本身是 Area，缝里的币会掉进底部 sink）。
	var used := lucky_w * 2.0 + normal_w
	var leftover := maxf(inner_w - used, inner_w * 0.12)
	var side_gap := leftover * 0.30
	var mid_gap := leftover * 0.20

	var x := inner_left + side_gap
	_add_static_slot(x + lucky_w * 0.5, slot_y, lucky_w, 2, Color(1.0, 0.0, 0.5, 0.30), "2x")
	x += lucky_w + mid_gap
	_add_static_slot(x + normal_w * 0.5, slot_y, normal_w, 1, Color(1.0, 0.843, 0.0, 0.30), "1x")
	x += normal_w + mid_gap
	_add_static_slot(x + lucky_w * 0.5, slot_y, lucky_w, 2, Color(1.0, 0.0, 0.5, 0.30), "2x")

	_jackpot = ScoreSlot.new()
	_slots.add_child(_jackpot)
	_jackpot.position = Vector2((inner_left + inner_right) * 0.5, jackpot_y)
	_jackpot.configure(
		Vector2(jackpot_w, JACKPOT_HEIGHT),
		10,
		Color(0.0, 0.94, 1.0, 0.30),
		"10x",
		true,
		JACKPOT_PERIOD
	)
	_jackpot.set_travel_bounds(inner_left + jackpot_w * 0.5 + 8.0, inner_right - jackpot_w * 0.5 - 8.0)

	# 整宽回收带贴在最底。先碰到槽的币已被 consume，不会二次计分。
	var sink := MissSink.new()
	var sink_h := 56.0
	_slots.add_child(sink)
	sink.position = Vector2(table.position.x + table.size.x * 0.5, table.position.y + table.size.y - sink_h * 0.5)
	sink.configure(Vector2(table.size.x - 8.0, sink_h))


func _add_static_slot(cx: float, cy: float, width: float, multiplier: int, color: Color, text: String) -> void:
	var slot := ScoreSlot.new()
	_slots.add_child(slot)
	slot.position = Vector2(cx, cy)
	slot.configure(Vector2(width, SLOT_HEIGHT), multiplier, color, text, false)


func _setup_spawner() -> void:
	# 币半径 28，钳制时让圆心离开内壁至少 28+4，避免生成时卡墙。
	var pad := Coin.RADIUS + 4.0
	spawner = _spawner_node
	spawner.setup(_coins, drop_y, inner_left + pad, inner_right - pad)
	_aim_x = spawner.aim_world_x(InputRouter.aim_t)


func _on_toss_requested(use_aim: bool, screen_position: Vector2) -> void:
	if not InputRouter.tossing_enabled:
		return
	var world_x: float
	if use_aim:
		world_x = spawner.aim_world_x(InputRouter.aim_t)
	else:
		var world := get_viewport().get_canvas_transform().affine_inverse() * screen_position
		world_x = world.x
	spawner.try_toss_at_x(world_x)


func _draw() -> void:
	# 内台不透明，盖住机柜图上画的钉，避免和 peg.png 叠成「空心调试钉」。
	# 机柜霓虹边框仍露在 table 矩形外面。
	draw_rect(table, Color(0.04, 0.05, 0.10, 0.92), true)
	# 投币线（桌顶）
	var y := drop_y
	draw_line(Vector2(inner_left, y), Vector2(inner_right, y), Color(1, 1, 1, 0.12), 2.0)
	# 瞄准三角：只表示 X
	var tip := Vector2(_aim_x, drop_y + 6.0)
	var a := Vector2(_aim_x - 12.0, drop_y - 16.0)
	var b := Vector2(_aim_x + 12.0, drop_y - 16.0)
	draw_colored_polygon(PackedVector2Array([tip, a, b]), Color(1.0, 0.84, 0.0, 0.95))
	draw_line(Vector2(_aim_x, drop_y), Vector2(_aim_x, drop_y + 22.0), Color(1.0, 0.84, 0.0, 0.65), 2.0)
