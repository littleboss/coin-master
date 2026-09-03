extends Node
## 账号金币、皮肤、静音。存档只写 user://。

signal balance_changed(new_balance: int)
signal coin_scored(multiplier: int)
signal skin_changed(index: int)
signal muted_changed(is_muted: bool)
signal mercy_granted(amount: int)

const STARTING_BALANCE := 50
const TOSS_COST := 1
const MERCY_AMOUNT := 10
const SAVE_PATH := "user://save.cfg"
const SAVE_SECTION := "player"
const SAVE_VERSION_SECTION := "save"
const SAVE_VERSION := 2

const SKIN_COUNT := 4
const SKIN_COSTS: Array[int] = [0, 30, 80, 150]
const SKIN_NAMES: Array[String] = ["金", "粉", "青", "钢"]

var balance: int = STARTING_BALANCE
var equipped_skin: int = 0
var unlocked_skins: Array[int] = [0]
var muted: bool = false
var _mercy_used_this_session: bool = false


func _ready() -> void:
	load_save()
	_apply_mute()
	balance_changed.emit(balance)
	skin_changed.emit(equipped_skin)


func can_toss() -> bool:
	return balance >= TOSS_COST


func try_spend_toss() -> bool:
	if not can_toss():
		return false
	balance -= TOSS_COST
	_persist_and_notify()
	return true


func payout(multiplier: int) -> void:
	if multiplier > 0:
		balance += multiplier
		_persist_and_notify()
	coin_scored.emit(multiplier)


func is_unlocked(index: int) -> bool:
	return unlocked_skins.has(clampi(index, 0, SKIN_COUNT - 1))


func skin_cost(index: int) -> int:
	return SKIN_COSTS[clampi(index, 0, SKIN_COUNT - 1)]


func try_unlock(index: int) -> bool:
	index = clampi(index, 0, SKIN_COUNT - 1)
	if is_unlocked(index):
		return true
	var cost: int = SKIN_COSTS[index]
	if balance < cost:
		return false
	balance -= cost
	unlocked_skins.append(index)
	_persist_and_notify()
	return true


func equip_skin(index: int) -> bool:
	index = clampi(index, 0, SKIN_COUNT - 1)
	if not is_unlocked(index):
		return false
	if equipped_skin == index:
		return true
	equipped_skin = index
	save()
	skin_changed.emit(equipped_skin)
	return true


func set_muted(value: bool) -> void:
	if muted == value:
		_apply_mute()
		return
	muted = value
	_apply_mute()
	save()
	muted_changed.emit(muted)


func toggle_mute() -> void:
	set_muted(not muted)


func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func equipped_region() -> Rect2:
	return CoinSkins.region_for_index(equipped_skin)


func load_save() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		balance = STARTING_BALANCE
		equipped_skin = 0
		unlocked_skins = [0]
		muted = false
		return
	balance = int(cfg.get_value(SAVE_SECTION, "balance", STARTING_BALANCE))
	if balance < 0:
		balance = 0
	equipped_skin = clampi(int(cfg.get_value(SAVE_SECTION, "equipped_skin", 0)), 0, SKIN_COUNT - 1)
	muted = bool(cfg.get_value(SAVE_SECTION, "muted", false))
	unlocked_skins = [0]
	var raw: String = str(cfg.get_value(SAVE_SECTION, "unlocked", "0"))
	for part in raw.split(",", false):
		var idx := int(part)
		if idx >= 0 and idx < SKIN_COUNT and not unlocked_skins.has(idx):
			unlocked_skins.append(idx)
	if not is_unlocked(equipped_skin):
		equipped_skin = 0
	_maybe_grant_mercy()


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SAVE_VERSION_SECTION, "version", SAVE_VERSION)
	cfg.set_value(SAVE_SECTION, "balance", balance)
	cfg.set_value(SAVE_SECTION, "equipped_skin", equipped_skin)
	cfg.set_value(SAVE_SECTION, "muted", muted)
	var parts: PackedStringArray = []
	for idx in unlocked_skins:
		parts.append(str(idx))
	cfg.set_value(SAVE_SECTION, "unlocked", ",".join(parts))
	var err := cfg.save(SAVE_PATH)
	if err != OK:
		push_warning("GameState: 无法写入存档 %s (err=%s)" % [SAVE_PATH, err])


func _persist_and_notify() -> void:
	save()
	balance_changed.emit(balance)
	_maybe_grant_mercy()


func _maybe_grant_mercy() -> void:
	# 本局一次：余额到 0 时给 10 枚，避免卡死。不写入「已用过」，下次启动若仍为 0 还会再给。
	if _mercy_used_this_session or balance > 0:
		return
	_mercy_used_this_session = true
	balance = MERCY_AMOUNT
	save()
	balance_changed.emit(balance)
	mercy_granted.emit(MERCY_AMOUNT)


func _apply_mute() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), muted)
