# Emberfall · 余烬之路

从零开发的 Windows 横版 2D 动作肉鸽。阶段 1 预制作门槛已通过，阶段 2 已有固定房间开发候选 **0.1.0-dev.1（未发布）**。

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

## 阶段 2 开发候选

[阶段报告](docs/stages/02-action-prototype.md) · [动作参数](docs/design/prototype-actions.md) · [自动测试](docs/testing/stage-02-prototype.md) · [操作/人工检查](docs/testing/prototype-playtest.md)。普通启动进入标题；美术是表达动作的程序占位，正式手绘角色尚未制作。

```powershell
pwsh -File tools/validate-prototype.ps1 -Godot 'C:\tools\Godot_v4.6.3-stable_win64_console.exe' -WindowsTemplate 'C:\templates\windows_release_x86_64.exe'
pwsh -File tools/capture-prototype.ps1 -Godot 'C:\tools\Godot_v4.6.3-stable_win64_console.exe'
```

第一条验证源码与Windows包；第二条只在启动即最小化的窗口下建立真实GPU上下文，在离屏子视口捕获16张1280×720画面。人工手感、真实键鼠/声音与干净Windows环境尚待验证，未发布v0.1.0。

工具tools/package-prototype.ps1在干净提交后生成本地开发ZIP、源码SHA和校验；不创建Tag或Release。
