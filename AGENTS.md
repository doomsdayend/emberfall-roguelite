# 开发约定

- 全新横版 2D 动作肉鸽；需求原文在 docs/requirements/original。有效修订见 docs/requirements/windows-amendment.md。
- 使用 Windows x86_64、PowerShell、Godot 4.6.3 标准版 / GDScript；不继承已删除的旧工程代码。
- 按 01—08 阶段顺序推进；阶段门槛未通过，不宣称通过或进入内容量产。
- 默认不自动打开游戏窗口。逻辑/导入/导出/包启动使用 --headless；它不提供真实 GPU 离屏画面，不能冒充画质或帧率测试。
- main 保持验证状态；阶段使用独立分支。公开仓库 doomsdayend/emberfall-roguelite 为用户指定目标。
- 每阶段同步设计、任务、测试、风险、交付报告及 CHANGELOG；未执行、未发布、待人工验收明确标记。
- 不提交引擎、缓存、凭据、个人存档及构建二进制。可玩版本遵循附件 B 的完整发布门禁。
- 最终手绘美术和动作按附件 A 验收，不用程序图形或静态立绘冒充正式资产。
