class_name CoinSpawner
extends Node2D
## 金币对象池。冷却 0.2s。池耗尽时拒绝投币（不扣费）。

const POOL_SIZE := 24
const TOSS_COOLDOWN := 0.20
const COIN_SCENE := preload("res://scenes/coin.tscn")

var drop_y: float = 80.0
var x_min: float = 220.0
var x_max: float = 1060.0

var _pool: Array[Coin] = []
var _available: Array[Coin] = []
var _cooldown_left: float = 0.0
var _coins_parent: Node2D


func setup(parent_for_coins: Node2D, p_drop_y: float, p_x_min: float, p_x_max: float) -> void:
	_coins_parent = parent_for_coins
	drop_y = p_drop_y
	x_min = p_x_min
	x_max = p_x_max
	_fill_pool()


func _fill_pool() -> void:
	for i in POOL_SIZE:
		var coin := COIN_SCENE.instantiate() as Coin
		_coins_parent.add_child(coin)
		coin.deactivate()
		coin.returned_to_pool.connect(_on_returned)
		_pool.append(coin)
		_available.append(coin)


func _process(delta: float) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left = maxf(0.0, _cooldown_left - delta)


func can_toss() -> bool:
	return _cooldown_left <= 0.0 and not _available.is_empty() and GameState.can_toss()


func try_toss_at_x(world_x: float) -> bool:
	if _cooldown_left > 0.0:
		return false
	if _available.is_empty():
		return false
	if not GameState.try_spend_toss():
		return false
	var coin: Coin = _available.pop_back()
	var x := clampf(world_x, x_min, x_max)
	# Y 永远是桌顶。调用方就算传入了点击 Y，这里也不用。
	coin.activate(Vector2(x, drop_y))
	_cooldown_left = TOSS_COOLDOWN
	Sfx.play_toss()
	return true


func clamp_x(world_x: float) -> float:
	return clampf(world_x, x_min, x_max)


func aim_world_x(aim_t: float) -> float:
	return lerpf(x_min, x_max, clampf(aim_t, 0.0, 1.0))


func _on_returned(coin: Coin) -> void:
	if coin in _available:
		return
	_available.append(coin)


func active_count() -> int:
	return POOL_SIZE - _available.size()


func recycle_all() -> void:
	for coin in _pool:
		if coin.is_pooled_active:
			coin.deactivate()
