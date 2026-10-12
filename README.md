# Emberfall · 余烬之路

重新开发的横版 2D 动作肉鸽，Linux 桌面优先，兼顾 Windows。

**当前交付：第 2 阶段设计与技术基础工程。尚无可玩版本或正式 Release。**

已有启动菜单、安全测试房、移动／跳跃／闪避技术样例、流程状态与确定性房间计划验证。没有敌人、伤害、奖励、首领或存档，不构成完整游戏流程。

## 本地运行

安装标准版 Godot **4.6.3**，导入仓库根目录的 `project.godot`。启动菜单的 `Open technical room` 进入技术房。

```bash
godot --path .
```

WASD／方向键移动，Space 跳跃，Shift 闪避，Esc 暂停。界面英文为开发占位；中文字体与正式 UI 在玩法原型阶段补齐。

## 验证与 Linux 导出

```bash
python3 tools/validate.py --godot /path/to/godot
godot --headless --path . --editor --quit
mkdir -p builds/linux
godot --headless --path . --export-release "Linux x86_64" builds/linux/emberfall
./builds/linux/emberfall --headless --quit-after 60
```

导出前安装同版本导出模板。`validate.py` 会拒绝非 4.6.3 引擎，并检查导入、流程规则、碰撞／移动／跳跃、暂停与房间切换以及启动日志。无窗口测试不代表画面和手感已通过人工验收。

## 文档与记录

- [第 1 阶段 · 立项与开发计划](docs/stages/01-project-plan.md)
- [第 2 阶段 · 设计、架构与预研](docs/stages/02-design-and-architecture.md)
- [更新记录](CHANGELOG.md)
- [发行说明模板](docs/releases/TEMPLATE.md)
- [开发规则](AGENTS.md)
- [素材来源](assets/SOURCES.md)

下一阶段：实现菜单 → 安全房 → 战斗房 → 结算 → 重开的 `v0.1.0` 玩法闭环。
