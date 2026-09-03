# Coin Master 2D / 街机投币机

Godot 4 完整 P0：标题（开始 / 皮肤店 / 退出）→ 游玩 → 暂停（继续 / 皮肤店 / 回标题）。机柜背景、叠字 Logo、四格皮肤店、本地存档。

打开 **本分支** 再 F5（`master` 仍几乎是空 README）。

## 用 Godot 4.3 / 4.4 打开并运行

1. 安装 [Godot 4.3+](https://godotengine.org/download)（脚本是 GDScript，不必用 .NET 版）。
2. 编辑器 → **Import** → 选本仓库根目录（有 `project.godot` 的那一层）。
3. 主场景是 `res://scenes/main.tscn`。按 **F5** 从标题画面开始。
4. 清屏色 `#0d0e15`。机柜 PNG 用 **Cover / 居中裁切**（`KEEP_ASPECT_COVERED`），19.5:9 时左右裁、不拉伸变形。

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
| 标题 / 暂停 / 商店按钮 | 点击、触摸、手柄 **A**（`ui_accept`） | 开始、商店、退出、继续、回标题 |

触摸：隐藏「投币」按钮，点台面任意处即投；用 HUD「暂停」或系统返回键。

## 流程与经济

- **标题**：开始 / 皮肤店 / 退出。Logo 是 `assets/ui/logo.png`（1536×1024 叠字），按比例完整显示，**不裁成横幅**。
- **暂停**：继续 / 皮肤店 / 回标题。商店可以从标题或暂停进入。
- 起始 50 金币，每次投币 1。1x 打平，2x / 10x 按倍率返还，MISS 不退。
- 余额到 0 时，**本局一次**发 10 枚救济金，避免卡死。下次启动若仍为 0 会再发。
- 存档：`user://save.cfg`（余额、装备皮肤、已解锁、静音）。**绝不写 `res://`。**

皮肤只换外观，不改赔率。

## 台面手感（不伪造赔率）

钉阵 **7-6-7**，与机柜图一致。槽宽目标手感：miss ~40%、1x ~45%、2x ~13%；头奖槽仍约占内宽 10%，水平往返周期 **2.4s**。碰撞：币半径 **28**，钉半径 **12**。冷却 **0.2s**，对象池 24，目标 60 FPS。

## 皮肤店（同一张 `coin_skins.png`）

| 格 | 名字 | 价格 |
| --- | --- | --- |
| 0 `Rect2(0,0,64,64)` | 金 | 免费 |
| 1 `Rect2(64,0,64,64)` | 粉 | 30 |
| 2 `Rect2(128,0,64,64)` | 青 | 80 |
| 3 `Rect2(192,0,64,64)` | 钢 | 150 |

装备后投出去的币用对应 region。

## 美术路径

来自 Pixel 分支 / [PR #1](https://github.com/littleboss/coin-master/pull/1)（本 PR 只拷贝，不改那条 draft）：

| 文件 | 尺寸 | 用法 |
| --- | --- | --- |
| `assets/bg/table.png` | 1920×1080 | 全屏机柜，Cover 居中裁切 |
| `assets/ui/logo.png` | 1536×1024 | 标题叠字，不裁横幅 |
| `assets/coins/coin_skins.png` | 256×64 | 四格皮肤 |
| `assets/pegs/peg.png` | 32×32 | 钉图（碰撞仍 r=12） |
| `assets/slots/slot_*.png` | 128×48 | 1x / 2x / 10x |
| `assets/ui/hud_panel_9patch.png` | 32×32 | HUD 九宫格 |

导入：Filter Linear，Mipmaps off，Lossless。音效仍是程序生成占位。

## 导出（Linux / Windows）

仓库带了 `export_presets.cfg`。在编辑器里：

1. **Editor → Manage Export Templates** 下载与编辑器版本匹配的模板。
2. **Project → Export** → Linux 或 Windows Desktop。
3. 输出目录建议 `export/linux/`、`export/windows/`（已 gitignore）。
4. 勾选 embed PCK。架构 x86_64。

**不要**在这里做 iOS 签名。Steam / 商店 SDK 仍走 `PlatformManager` 空实现。

## 目录

```
autoload/   GameState, InputRouter, PlatformManager, Sfx
scenes/     main（含机柜背景）, playfield, coin, hud
scripts/    流程、标题、暂停、商店、玩法
assets/     机柜 / Logo / 图集 / 钉 / 槽 / HUD 九宫格
```
