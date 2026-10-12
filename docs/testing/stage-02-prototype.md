# 阶段 2 自动验证记录

日期：2026-10-12；版本0.1.0-dev.1；Godot4.6.3/Windows11，硬件同阶段1。此报告记录开发候选，不等同v0.1.0发布验收。

## 源码与原生包

```powershell
pwsh -File tools/validate-prototype.ps1 -Godot .tools/godot/Godot_v4.6.3-stable_win64_console.exe -WindowsTemplate .tools/windows_release_x86_64.exe
```

源码和中文空格路径下独立exe+pck均退出0、247项断言通过、无SCRIPT ERROR/ERROR。范围：安全首房、运动/土狼/落地缓冲/单向平台下穿/实体墙闪避/斜坡、攻击生效窗/实例去重/三连击/重击/空攻/打断/伤害免疫/闪避时窗、两种敌人的预警与生效、暂停/失焦/快照输入释放屏障、20次房间重开、10次夹具流转和10次实际战斗流程。

10次真实战斗流程由控制器逐物理帧输入移动和重击，从标题出发、过训练/两战斗房、击败精英后胜利回标题，不直接修改HP或跳过战斗。另10次夹具流转专门清敌检查门和场景清理，单独计数，不冒充战斗或真人试玩。重击控制器通关不能证明难度平衡、多种打法、真人手感或帧率性能通过。

| 输入采样Hz（物理均120Hz） | 1秒距离 | 长跳高 | 短跳高 |
| --- | --- | --- | --- |
| 30 | 446.0003 | 205.5374 | 35.8845 |
| 60 | 446.0003 | 205.5374 | 35.8845 |
| 120 | 446.0003 | 205.5374 | 35.8845 |

另外以--fixed-fps 30、60、120分别运行整套源码回归均247通过。这是固定步长/多物理tick及采样一致性检查，禁用实时同步，**不是**真实30/60/120 FPS限制、GPU性能或低档硬件测试。

## 真实GPU离屏

```powershell
pwsh -File tools/capture-prototype.ps1 -Godot .tools/godot/Godot_v4.6.3-stable_win64_console.exe
```

Windows DisplayServer、Intel(R) Graphics、OpenGL3.3/驱动32.0.101.6881；主窗口在创建配置中即设最小化，脚本复核main_window_minimized=true。在SubViewport.UPDATE_ALWAYS离屏子视口强制渲染/readback，无可见游戏窗口，也没有用dummy图代替GPU。

实际输出16张1280×720PNG：标题、设置、安全房、出生、起步、急停、转向、落地、交互、攻击预备/生效/恢复、翻滚、暂停、死亡、胜利。逐张查看，姿态变化和HUD/菜单可辨，攻击收势回位、死亡/胜利姿态更新正常；UI遮底板修复后复核。artifacts/gpu保留原图；evidence/stage02-gpu-contact.png为等比例缩小拼板。场景与姿态由截图夹具设置，不称这些静帧为完整实时试玩。

方法依据：[Window最小化模式](https://docs.godotengine.org/en/4.6/classes/class_window.html#enum-window-mode)、[SubViewport持续更新](https://docs.godotengine.org/en/4.6/classes/class_subviewport.html#enum-subviewport-updatemode)。主窗口配置在finally恢复，不改用户桌面设置。

## 已修复与边界

- 生效期间同攻击重复命中：实例目标集合去重并覆盖测试。
- 命中停顿丢失输入：停顿期间保存边沿，恢复时消费；暂停另行清除。
- 冻结后死亡姿态未刷新：停时不推进动画时钟，仍刷新姿态绘制。
- 生成GPU截图目录被导入：验证器创建artifacts/.gdignore隔离证据。
- headless的合成键盘事件不能可靠更新真实OS按键状态：改为验证相同输入快照路由，明确真实键鼠待验，不伪造设备通过。

尚未执行：真人键鼠/音频听感、真实FPS限制、干净Windows VM、最低档机器、手柄、完整中文字体、最终手绘动画和性能统计。原型动作视觉仅占位，通过单帧检查不等于附件A最终动作通过。阶段2发布门槛保持未关闭。

源码最终SHA及当前包校验在本地builds/emberfall-0.1.0-dev.1-windows-x64/BUILD.json和SHA256SUMS.txt；工具在干净提交后重建。仓库保存脱敏测试日志，发布前仍须Tag/Release/附件下载验证。
