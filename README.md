# Coin Master 2D / 街机投币机

Godot 4 街机投币：标题 → 游玩 → 暂停，本地存档，四格皮肤店，程序生成音效。

## 用 Godot 4.4 打开并运行

1. 安装 [Godot 4.4](https://godotengine.org/download)（4.2+ 也能开；脚本是 GDScript，不必用 .NET 版）。
2. 编辑器 → **Import** → 选本仓库根目录（有 `project.godot` 的那一层）。
3. 主场景是 `res://scenes/main.tscn`。按 **F5** 从标题画面开始。
4. 清屏色 `#0d0e15`。

无头冒烟：

```bash
godot --headless --resolution 1280x720 --path . -- --smoke
```

## 操作

| 动作 | 键位 | 行为 |
| --- | --- | --- |
| `toss_coin` | 鼠标左键、空格、手柄 **A** | 投币，扣 1 |
| `aim_left` / `aim_right` | **A/D**、方向键、左摇杆 | 横向瞄准（高度永远是桌顶） |
| `pause` | **Esc**、**P**、手柄 **Start** | 暂停 / 继续 |
| 标题 / 暂停 / 商店按钮 | 点击、触摸、手柄 **A**（`ui_accept`） | 开始、继续、商店、退出、静音 |

触摸：隐藏「投币」按钮，点台面任意处即投；用 HUD「暂停」或系统返回键。

## 流程与经济

- **开始**：进入游玩（沿用 `user://` 存档，不强制清档）。
- **继续**：有存档才可点，同样进游玩。
- **退出**：结束进程（编辑器里会停 Play）。
- 起始 50 金币，每次投币 1。1x 打平，2x / 10x 按倍率返还，MISS 不退。
- 存档：`user://save.cfg`（余额、装备皮肤、已解锁、静音）。

## 皮肤店（同一张 `coin_skins.png`）

| 格 | 名字 | 价格 |
| --- | --- | --- |
| 0 `Rect2(0,0,64,64)` | 金 | 免费 |
| 1 `Rect2(64,0,64,64)` | 粉 | 30 |
| 2 `Rect2(128,0,64,64)` | 青 | 80 |
| 3 `Rect2(192,0,64,64)` | 钢 | 150 |

装备后投出去的币用对应 region。碰撞半径仍是 **28**。钉半径 **12**。冷却 **0.2s**，对象池 24，目标 60 FPS。

## 导出（Linux / Windows）

仓库带了 `export_presets.cfg`。在编辑器里：

1. **Editor → Manage Export Templates** 下载与 4.4 匹配的模板。
2. **Project → Export** → Linux 或 Windows Desktop。
3. 输出目录建议 `export/linux/`、`export/windows/`（已 gitignore）。
4. 勾选 embed PCK。架构 x86_64。

**不要**在这里做 iOS 签名。Steam / 商店 SDK 仍走 `PlatformManager` 空实现。

## 目录

```
autoload/   GameState, InputRouter, PlatformManager, Sfx
scenes/     main, playfield, coin, hud
scripts/    流程、标题、暂停、商店、玩法
assets/     Pixel 图集 / 钉 / 槽 / HUD 九宫格
```
