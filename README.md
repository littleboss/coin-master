# Coin Master 2D / 街机投币机

Godot 4 P0 可玩切片：把金币从桌顶投进钉板，掉进 1x / 2x / 移动 10x 槽，或掉进回收坑（不退币）。

## 用 Godot 4 打开并运行

1. 安装 [Godot 4.2+](https://godotengine.org/download)（GDScript，不要用 C# 版也行，脚本是 `.gd`）。
2. 启动编辑器 → **Import** → 选本仓库根目录（有 `project.godot` 的那一层）。
3. 主场景已设为 `res://scenes/main.tscn`。按 **F5**（或顶部 Play）即可玩。
4. 清屏色 / 世界背景是 `#0d0e15`。

无头冒烟（可选，需 Godot 在 `PATH` 里）：

```bash
godot --headless --resolution 1280x720 --path . -- --smoke
```

## 操作（InputMap）

动作名在 `project.godot` 的 `[input]`，游戏启动时 `InputRouter` 也会再注册一遍，避免编辑器版本差异丢绑定。

| 动作 | 键位 | 行为 |
| --- | --- | --- |
| `toss_coin` | 鼠标左键、空格、手柄 **A**（`JOY_BUTTON_A`） | 投一枚币，扣 1 金币 |
| `aim_left` | **A**、方向键左、左摇杆左 | 瞄准准星左移 |
| `aim_right` | **D**、方向键右、左摇杆右 | 瞄准准星右移 |

补充规则：

- **高度锁死**：无论点击/触摸的 Y 是多少，币永远从**桌顶**落下，只钳制 X 到台面内宽。
- **鼠标 / 触摸**：在点击/触点的 X 立即投下。
- **空格 / 手柄 A**：从当前瞄准 X 投下。瞄准默认在正中。
- **手机**：隐藏屏幕投币按钮，点哪里投哪里。触摸 vs 鼠标/键盘/手柄会自动切换。不需要虚拟摇杆。
- 冷却 **0.2s**。金币用 `RigidBody2D` 对象池，不会无上限 `instantiate`。

## 台面与期望值

- 三行交错 `StaticBody2D` 圆钉，避免直瞄幸运/头奖槽。
- 底部槽（`Area2D`，每枚币只计一次）：
  - **1x** 中间约 55–60%，调试色 `#ffd700` 30% 透明（打平）。
  - **2x** 左右合计约 30%，`#ff007f`。
  - **10x** 约 10% 宽，沿底部来回移动，`#00f0ff`，命中有少量一次性青色粒子。
- **MISS 回收带**覆盖底边：不算分、不退币。没有它 EV 会爆。

碰撞圆半径 **28px**（不是 32）。弹力（restitution / bounce）在 **0.4–0.6**。

## 美术资源

来自 Pixel 的 `cursor/add-coin-skins-atlas-36d0`（PR #1）。导入一律：Filter **Linear**，**Mipmaps off**，**Lossless**。换 PNG 不用改碰撞。

| 路径 | 尺寸 | 用法 |
| --- | --- | --- |
| `assets/coins/coin_skins.png` | 256×64，一行 4 格 | P0 投币只用 cell 0 `Rect2(0, 0, 64, 64)`。碰撞半径 **28** |
| `assets/pegs/peg.png` | 32×32 | 钉板 Sprite。碰撞半径 **12**（不是 16） |
| `assets/slots/slot_normal.png` | 128×48 | 1x 槽 |
| `assets/slots/slot_lucky.png` | 128×48 | 2x 槽 |
| `assets/slots/slot_jackpot.png` | 128×48 | 移动 10x 槽 |
| `assets/ui/hud_panel_9patch.png` | 32×32 | HUD 九宫格，`patch_margin` **12**（中间 8×8 拉伸），内容边距 12 |

其它皮肤格（粉 / 青 / 钢）留给以后解锁。

## 存档

账号余额存在 **`user://save.cfg`**（桌面大约是 `~/.local/share/godot/app_userdata/Coin Master 2D/`），**不会**写进 `res://`。新档 50 金币。关掉再开应保留余额。

## 目录

```
autoload/    GameState, InputRouter, PlatformManager（Steam/商店 no-op）
scenes/      main, playfield, coin, hud
scripts/     玩法脚本
assets/      金币图集、九宫格面板、物理材质
```

## P0 明确不做

Go 后端、真实排行榜、皮肤商店、Steamworks / IAP。本地 `user://` 即可。
