# 阶段 2 · 0.1.0-dev.2 验证

2026-10-12；Windows 11 Pro 26200，Core Ultra 5 225、Intel Graphics / 驱动32.0.101.6881、32GB RAM；Godot4.6.3标准版。开发候选，未发布；不替代真人试玩和最低设备验收。dev.1的记录保持历史状态。

## 更新与回归

标题、设置、房间、结算与操作提示改为中文，随包提供完整Noto Sans SC字体及OFL声明。音量和震屏保存到user://settings.cfg；仅保存偏好，不是肉鸽进度存档。自动测试与截图改用user://automated-tests，避免覆盖正常偏好；原生包不能向PCK内的res://写配置。

姿态时钟由物理tick推进，避免低渲染帧率漏掉落地等短姿态；暂停冻结时钟。新增设置保存/覆盖/读取、范围钳制、错误类型、未知schema、中文字符和无渲染tick姿态检查。

源码与中文空格路径的独立exe+pck各 **256项断言通过**，无SCRIPT ERROR/ERROR；各包含20次房间重开、10次夹具流程、10次实际战斗控制器通关。战斗控制器不直接修改HP；该结果不代表真人难度平衡通过。输入采样30/60/120Hz的固定模拟运动结果维持一致，见dev.1报告中的方法说明。

复现：

```powershell
pwsh -File tools/validate-prototype.ps1 -Godot .tools/godot/Godot_v4.6.3-stable_win64_console.exe -WindowsTemplate .tools/windows_release_x86_64.exe
pwsh -File tools/capture-prototype.ps1 -Godot .tools/godot/Godot_v4.6.3-stable_win64_console.exe
pwsh -File tools/capture-prototype.ps1 -Godot .tools/godot/Godot_v4.6.3-stable_win64_console.exe -Mode rate -Fps 30
```

最后一条分别将Fps改为60、120。GPU运行创建即最小化的Windows主窗口，并核验最小化状态；子视口1280×720使用真实OpenGL渲染，非headless dummy。

## 真实时间 GPU 离屏限帧

每组420物理tick（约3.5秒），物理120Hz，实时系统时钟统计渲染回调间隔；使用--max-fps、关闭vsync，**不使用--fixed-fps**。包含移动、刹车、自由空间长跳及一次普攻，逐帧强制绘制子视口。

| 帧率上限 | 实测平均FPS | 帧间隔P95 ms | 移动1秒距离 | 长跳高度 | 攻击事件tick |
| --- | --- | --- | --- | --- | --- |
| 30 | 30.467 | 44.471 | 446.0003 | 205.4809 | 330 / 339 / 366 |
| 60 | 60.379 | 25.453 | 446.0003 | 205.4809 | 330 / 339 / 366 |
| 120 | 119.358 | 13.341 | 446.0003 | 205.4809 | 330 / 339 / 366 |

三组运动/事件一致。GPU夹具起始地面高度与逻辑测试有微小差异，因此不将其205.4809与逻辑长跳205.5374视为同一基线。P95是短场景渲染回调间隔，不能等同GPU耗时、屏幕呈现时间或阶段7两小时基准；30/60上限下也不应套用阶段7的P95≤20ms门槛。

16张真实GPU截图覆盖中文标题/设置、房间及各短姿态、攻击三段、翻滚、暂停、死亡、胜利。原图在artifacts/gpu；缩小拼板见[evidence/stage02-dev2-gpu-contact.png](evidence/stage02-dev2-gpu-contact.png)。未用静帧声称连续动画手感通过。

## 交付与剩余门槛

本地工具在干净提交后重建开发ZIP，BUILD.json记录同一源码SHA，SHA256SUMS包含exe、pck、说明及全部许可。归档内容校验和解压后独立启动另行执行；不会自动创建Tag/Release。

待验：真实键鼠与暂停释放链路、连续动作手感、声音听感、干净Windows VM、最低档硬件、正式发布下载链路。最终手绘资源、手柄与肉鸽进度存档按后续阶段实现；阶段2门禁未关闭，不进入阶段3量产。
