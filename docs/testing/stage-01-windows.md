# 阶段 1 Windows 技术验证

日期：2026-10-12（Asia/Shanghai）；执行对象：stage-01-windows-preproduction 分支的最小技术探针，不是游戏原型。

## 环境

- Windows 11 专业版 10.0.26200，Intel Core Ultra 5 225，Intel Graphics，驱动 32.0.101.6881，物理内存 33,696,006,144 bytes。
- Godot 4.6.3.stable.official.7d41c59c4，标准版 x86_64，PowerShell。
- 引擎 ZIP 来自官方 godotengine/godot-builds 4.6.3-stable；SHA-512 与官方 SHA512-SUMS.txt 一致：`d44ea7ef5bab754cacd49d581b6062836b2eea12a82e1d183aebfad9cd8c7db2bd82513337bd657d6d2d5c04d46239c0570b029faf1343e81e8a2fa7b85dd83b`。
- Windows release 模板来自同版官方 export_templates.tpz，HTTP Range 提取 `templates/windows_release_x86_64.exe`，解压长度104659456及ZIP CRC32=2610372866匹配目录。未下载完整1.25GB模板包，因此**没有完成整个模板ZIP的SHA-512校验**。模板exe的SHA-256与下面导出的exe相同。

## 实际执行

```powershell
pwsh -NoProfile -File tools/validate.ps1 -Godot .tools/godot/Godot_v4.6.3-stable_win64_console.exe -WindowsTemplate .tools/windows_release_x86_64.exe
```

| 用例 | 实际结果 | 证据 |
| --- | --- | --- |
| 引擎锁版/校验 | 4.6.3 stable、官方ZIP校验一致 | 本报告与本地校验文件 |
| headless编辑器导入 | 退出0，无SCRIPT ERROR/ERROR | artifacts/import.log |
| SVG纹理载入与尺寸 | Texture2D非空，64×64 | artifacts/source-probe.log |
| AnimationPlayer轨道 | 0.15s时x=15、0.30s时x=30 | 同上，failures=[] |
| Windows release导出 | exe+pck导出成功，无错误 | artifacts/export.log |
| 中文空格路径独立包启动 | builds/windows/测试 空格/emberfall-probe.exe --headless；退出0，全部断言通过 | artifacts/exported-probe.log |
| 无弹窗 | 全部Godot使用headless，导出程序用隐藏进程并等候日志 | tools/validate.ps1 |

导出包日志：

```json
{"display":"headless","engine":"4.6.3-stable (official)","failures":[],"os":"Windows","passed":true,"playable":false,"probe":"windows-preproduction-1","visual_quality_tested":false}
```

本地构建 SHA-256：

| 文件 | SHA-256 |
| --- | --- |
| emberfall-probe.exe | 91724f15024a3a545e28ccd83134403d31ce2323a38e51c95e4dfa282f732ab6 |
| emberfall-probe.pck | 585e5ffd7d6e3eb014555a6b9398acc012dc9ad1a122a4f0bd058398972fd8d9 |

原始机器日志和二进制保留在本地忽略目录，公开仓库仅保存该脱敏测试摘要。此包没有可玩流程，不发布为v0.1.0，不创建Release。

## 已修复及未覆盖

第一次沙箱导入无法写标准Godot配置目录，改用正常权限运行后通过；未更改用户安全设置。最初PowerShell直接调用GUI子系统exe无法可靠等待/捕获输出，验证器已改为隐藏进程、60秒超时、独立日志和退出码校验，再导出重跑通过。

未验证：干净虚拟机、最低档硬件、真实GPU离屏截图/灯光、GPU帧率、声音、手柄、人物动作质量、碰撞/战斗和手感。默认headless是dummy渲染，不能把本记录当成这些项目的通过证据。角色生成API的默认地址曾返回401；用户随后指定兼容接口，图像结果另见美术审核记录。
