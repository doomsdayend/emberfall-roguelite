# ADR-001 · Windows 技术路线

日期：2026-10-12；状态：技术候选冻结，最小导出验证结果见测试报告。

## 引擎与工具

| 候选 | 适用性 | 成本/风险 | 结论 |
| --- | --- | --- | --- |
| Godot 4.6.3 标准版 | 2D 场景、Skeleton2D/AnimationPlayer、GDScript、Windows 模板、headless CLI | MIT；需自己保证动画事件去重、资产与导出一致 | 选定并锁版本 |
| Unity 6 系列 | 2D 动画和 Windows 工具链齐全 | 编辑器/包依赖较多，需另行核验授权与精确版本 | 本阶段不引入 |
| 自制运行时 | 可完全控制离屏渲染 | 编辑器、资产、输入和构建维护成本过高 | 不选 |

选择依据是当前项目的 2D 与自动构建需求，不追求最新版。所有新代码从零编写，沿用旧项目名称不等于复用旧实现。动画路线：Godot Skeleton2D + AnimationPlayer，关节遮盖层；大幅攻击/表情以替换绘制帧补充。源美术采用可编辑分层文件+透明 PNG；软件具体版本随首批资产实际制作登记，不伪填已安装。

## 模块边界

InputRouter 只生成意图；CharacterMotor 管运动/实体碰撞；ActionMachine 管时窗与取消；CombatResolver 管实例去重、无敌、伤害；Presentation 消费动作事件、不能反向决定伤害；EnemyBrain 生成敌方意图；RoomDirector 管门/刷怪/异常恢复；RunDirector 管局流程；BuildResolver 管词条与递归限额；SaveService 管事务/迁移；UI 与 Audio 仅消费状态；BuildTools 管验证/导出。

数据：动作含 id、duration_ms、startup_ms、active_ms、recovery_ms、combo_window、cancel_window、turn_window、damage、knockback、hit_shape、events；敌人含 id、brain、senses、telegraph、actions；房间含 id、bounds、entry、exit、platforms、spawn_slots、tags；物品含 id、kind、max_stack、trigger、cooldown、exclusive_tags、asset_id。禁止将动画名称直接当伤害开关。

存档含 schema、game_version、slot_id、profile、unlocks、currency、playtime、run（seed、generator_version、character、health、equipment、buffs、completed_rooms、checkpoint、claimed_transactions、settlement_id）。写临时文件→校验→备份→替换；迁移前留备份。

资源名采用角色_动作_武器_方向_vNN；源与导出分离，资产登记记录作者/许可/工具/锚点/动作事件/审核。日志用 JSON Lines，包含 build、session、event、room、action_instance；不得记录身份凭据或完整个人目录。

## 无窗口与离屏的边界

默认使用 `--headless --audio-driver Dummy` 做导入、逻辑/物理、动画数据、导出和最终包启动。Godot headless 使用 dummy 渲染，**不会生成可供画质验收的真实 GPU 截图**。

真实 GPU 离屏属于单独任务：优先隔离 Windows 测试机/虚拟显示会话，验证驱动与渲染器可用后采集 Viewport；本机不擅自创建可见窗口。未建立这一环境前不宣称图像、灯光或 FPS 合格。人工手感由用户自行启动试玩。headless CPU 时间不作为 GPU 帧时间。

## 官方参考

- https://godotengine.org/download/archive/4.6.3-stable/
- https://docs.godotengine.org/en/4.6/tutorials/editor/command_line_tutorial.html
- https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_windows.html

开发下载只使用官方发布资源；引擎 ZIP 校验官方 SHA-512，原生包另记 SHA-256。模板与引擎必须同版；不把工具二进制纳入 Git。
