# Emberfall · 余烬之路

从零开发的 Windows 横版 2D 动作肉鸽。当前为阶段 1 预制作，**没有可玩版本**。

- [有效需求修订](docs/requirements/windows-amendment.md)
- [游戏设计](docs/design/gdd.md)
- [技术与验证决策](docs/decisions/001-windows-foundation.md)
- [美术与动作制作规格](docs/design/art-direction.md)
- [阶段门禁与需求追踪](docs/design/roadmap.md)
- [阶段 1 报告](docs/stages/01-preproduction.md)

## 开发与验证

Godot 4.6.3 标准版（Windows x86_64），PowerShell 7 或 Windows PowerShell 5.1。源码无额外包管理依赖。

```powershell
pwsh -File tools/validate.ps1 -Godot 'C:\tools\Godot_v4.6.3-stable_win64_console.exe'
```

验证器只执行无窗口进程。导出预检需指定同版本的 Windows release 模板：

```powershell
pwsh -File tools/validate.ps1 -Godot 'C:\tools\Godot_v4.6.3-stable_win64_console.exe' -WindowsTemplate 'C:\templates\windows_release_x86_64.exe'
```

日志、探针结果和临时构建分别放在 artifacts、builds；不纳入 Git（脱敏摘要见 docs/testing/evidence）。当前探针仅验证最小资产与动画数据及 Windows 包启动，不是动作原型。

原始需求保持不变；Windows 修订具有更高优先级。仅通过自动化不能认定手感、美术质量、真实手柄输入或目标设备性能通过。
