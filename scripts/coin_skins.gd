class_name CoinSkins
extends RefCounted
## coin_skins.png 图集约定（Pixel 美术 / P0 占位图同一套 UV）。
##
## 文件：assets/coins/coin_skins.png
## 尺寸：256×64，一行 4 格，每格 64px。每格已烘焙 2px 透明边。
## 导入：Filter Linear，Mipmaps off，Lossless。
## 碰撞半径仍是 28，和格子大小无关。

const ATLAS := preload("res://assets/coins/coin_skins.png")
const CELL_SIZE := 64
const PAD_PX := 2

const GOLD := Rect2(0, 0, 64, 64)
const PINK := Rect2(64, 0, 64, 64)
const CYAN := Rect2(128, 0, 64, 64)
const STEEL := Rect2(192, 0, 64, 64)

## P0 投出去的币只用默认金色格。其它格留给以后的皮肤解锁。
const DEFAULT_TOSS_SKIN := GOLD


static func region_for_index(index: int) -> Rect2:
	var i := clampi(index, 0, 3)
	return Rect2(i * CELL_SIZE, 0, CELL_SIZE, CELL_SIZE)
