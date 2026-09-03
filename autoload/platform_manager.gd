extends Node
## 商店 / 平台抽象。P0 只提供桌面 no-op，方便以后接 Steam / Google Play / App Store。
## 游戏逻辑不要直接调用 Steamworks 或商店 SDK，一律走这里。

enum StoreFront { DESKTOP, STEAM, GOOGLE_PLAY, APP_STORE }


func current_store() -> StoreFront:
	if OS.has_feature("android"):
		return StoreFront.GOOGLE_PLAY
	if OS.has_feature("ios"):
		return StoreFront.APP_STORE
	# Steamworks 以后在这里探测；现在桌面（含 Steam Deck 以桌面运行）都走 DESKTOP。
	return StoreFront.DESKTOP


func store_id() -> String:
	match current_store():
		StoreFront.STEAM:
			return "steam"
		StoreFront.GOOGLE_PLAY:
			return "google_play"
		StoreFront.APP_STORE:
			return "app_store"
		_:
			return "desktop"


func is_mobile() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")


func is_touch_primary() -> bool:
	return is_mobile() and DisplayServer.is_touchscreen_available()


func unlock_achievement(_achievement_id: String) -> void:
	pass


func submit_leaderboard(_board_id: String, _score: int) -> void:
	pass


func purchase_product(_product_id: String) -> void:
	pass


func restore_purchases() -> void:
	pass
