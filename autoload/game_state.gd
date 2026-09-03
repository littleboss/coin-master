extends Node
## 账号金币：投币扣 1，中奖按倍率返还。存档只写 user://，永远不要写 res://。
##
## 信号：
## - balance_changed: HUD 用来刷新顶部金币数
## - coin_scored: 某枚币结算时发出（倍率为 0 表示 miss，不返还）

signal balance_changed(new_balance: int)
signal coin_scored(multiplier: int)

const STARTING_BALANCE := 50
const TOSS_COST := 1
const SAVE_PATH := "user://save.cfg"
const SAVE_SECTION := "player"
const SAVE_KEY_BALANCE := "balance"
const SAVE_VERSION_SECTION := "save"
const SAVE_VERSION := 1

var balance: int = STARTING_BALANCE


func _ready() -> void:
	load_save()
	balance_changed.emit(balance)


func can_toss() -> bool:
	return balance >= TOSS_COST


func try_spend_toss() -> bool:
	if not can_toss():
		return false
	balance -= TOSS_COST
	_persist_and_notify()
	return true


func payout(multiplier: int) -> void:
	# 1x = 返还 1（打平）；2x / 10x 同理。miss 传 0，不返还。
	if multiplier > 0:
		balance += multiplier
		_persist_and_notify()
	coin_scored.emit(multiplier)


func load_save() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		balance = STARTING_BALANCE
		return
	balance = int(cfg.get_value(SAVE_SECTION, SAVE_KEY_BALANCE, STARTING_BALANCE))
	if balance < 0:
		balance = 0


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SAVE_VERSION_SECTION, "version", SAVE_VERSION)
	cfg.set_value(SAVE_SECTION, SAVE_KEY_BALANCE, balance)
	var err := cfg.save(SAVE_PATH)
	if err != OK:
		push_warning("GameState: 无法写入存档 %s (err=%s)" % [SAVE_PATH, err])


func _persist_and_notify() -> void:
	save()
	balance_changed.emit(balance)
