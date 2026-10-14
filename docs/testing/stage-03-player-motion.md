# 真人反馈：站姿与手臂动作修正

2026-10-14：用户试玩反馈人物动作单一，站立姿态和手臂挥舞不自然。本次针对主角修正，不代表阶段 3 最终动作质量验收通过。

待机骨盆从低蹲位置抬回腿部可支撑的高度，左右脚保持同一地面，增加轻微呼吸。跑步重做步幅、抬脚与双臂反向摆动。调整双膝弯曲方向、收窄肩部挂点，肩挂点随躯干倾斜，手掌按前臂/握柄朝向旋转；仍使用固定长度肢体，不拉伸贴图。

三段地面攻击分别使用斜斩、上挑、横向重斩轨迹；重击使用头顶蓄力下劈，空攻带收腿姿态。每种动作都有蓄力、挥击、短暂随势和回收，骨盆、躯干、支撑脚和副手共同变化。时序读取现有 action_data，不更改伤害、命中窗口或碰撞参数。

源码与独立 Windows 包的默认模式各256项、皮肤预览各694项通过，均无SCRIPT ERROR/ERROR。Intel/OpenGL最小化窗口捕获97张图通过（包括原29张、两张待机、30张攻击关键帧、36张普攻采样）。验证日志保存在 evidence/stage03-player-motion-{source-default,source-skin,exported-default,exported-skin,gpu}.txt。

验证命令：

```powershell
& tools/validate-art-slice.ps1 -Godot .tools/godot/Godot_v4.6.3-stable_win64_console.exe -WindowsTemplate .tools/windows_release_x86_64.exe
& tools/capture-prototype.ps1 -Godot .tools/godot/Godot_v4.6.3-stable_win64_console.exe -ArtSlice
```

GPU 审核包含左右待机、五种攻击各六个关键时刻和普攻36个连续时间样本。原图为1280×720真实Intel/OpenGL离屏截图；[近景拼板](evidence/stage03-player-motion-review.png)放大1.5倍检查关节，[普攻慢放](evidence/stage03-slash-slow.gif)为采样动画约4倍慢放，不能替代真人实时手感判断。

仍需继续处理完整动作的转场和美术遮盖。主角动作已修正，敌人和首领的正式动作质量不在本次完成范围。用户需关闭旧进程再启动新包核对站姿、连续J三连击、K重击、空中J和左右翻向。
