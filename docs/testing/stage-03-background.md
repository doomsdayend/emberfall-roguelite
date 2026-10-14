# 阶段 3 背景和皮肤预览验证

日期：2026-10-13；Godot4.6.3、Windows11、Intel Graphics/OpenGL，驱动32.0.101.6881。保持阶段2参数和碰撞，显式参数 `--art-slice-preview` 才启用绘制候选；项目版本仍是原型0.1.0-dev.2，本次不是v0.2.0成品。

```powershell
pwsh -File tools/validate-art-slice.ps1 -Godot .tools/godot/Godot_v4.6.3-stable_win64_console.exe -WindowsTemplate .tools/windows_release_x86_64.exe
pwsh -File tools/capture-prototype.ps1 -Godot .tools/godot/Godot_v4.6.3-stable_win64_console.exe -ArtSlice
```

源码和中文空格路径的独立exe+pck分别通过默认256项与预览658项断言，日志均无SCRIPT ERROR/ERROR。每次包括20次房间重开、10次夹具流程、10次实际战斗控制器通关。新增检查100次角度/方向切换，握柄和前手同点、贴图缩放不随姿态改变、左右镜像一致；越界目标限制到固定肢长，不伸长手臂。此检查不等同连续动画质量验收。

实际最小化Windows上下文、1280×720子视口强制渲染/读回，23张图覆盖标题、设置、安全房、跑步、上升/顶点/下降、受击、出生、起停、转向、落地、交互、普攻三段、重击及左向、翻滚、暂停、死亡和胜利。源码控制器用于摆姿；静态截图不能替代真人连续动作或性能测量。[审核拼板](evidence/stage03-art-slice-gpu-contact.png)保存13张代表图，其余原图在本地artifacts/gpu-art-slice。

实机审核发现并修复：背景的假平台/出口与实际几何不重合；皮肤依赖advance导致截图状态未更新。新远景不再含可交互环形门或前景浮台，地面/平台/斜坡/门绘制与原始碰撞坐标一致；HUD暗底改善亮炉光前文字可读性。皮肤与原型共用姿态计算，固定长度求解后挂接前手与武器。

证据：evidence/stage03-source-default.txt、stage03-source-skin.txt、stage03-exported-default.txt、stage03-exported-skin.txt、stage03-gpu-background.txt。引擎模板、生成API地址和凭据不入库。独立预览包保存在本地builds/windows/测试 空格/emberfall-art-preview.exe和同名pck；加 `-- --art-slice-preview` 启用美术候选。

尚待：贴图杂色和关节遮盖修复、完整动作与握持慢放检查、正式骨骼生产绑定、环境分层动态、其他敌人/精英/三招二阶段首领/房间增益、真人阶段3质量验收与正式发布。只记录实际自动化和静帧审核结果。

## 内容流程增量

`--stage3-slice --stage3-test` 源码运行时套件已通过：8 个房间可加载，三类敌人、精英和窑炉守门者首领存在，首领生命与阶段字段有效。独立 Windows 导出包的常规 256/672 项回归和导出检查通过；Stage 3 运行时套件当前记录为源码验证，仍需在试玩包中人工连续走完 8 房间并完成真人平衡验收。

Windows Intel/OpenGL 最小化离屏夹具新增 `-Stage3` 模式，覆盖位移敌人房、奖励炉台、精英闸门和首领第一阶段/熔渣线/冲锋状态；结果为 `GPU_STAGE3_RESULT passed=true`，审核拼板见 [stage03-runtime-gpu-contact.png](evidence/stage03-runtime-gpu-contact.png)，原始日志见 [stage03-runtime-gpu.txt](evidence/stage03-runtime-gpu.txt)。

追击者运行时预览新增一张 RGBA 裁切候选，离屏夹具现保存29张1280×720截图，覆盖追击者预警、攻击、受击和死亡状态。它保持原有碰撞体、生命值、攻击窗口和AI；参考阴影、单视图与最终分层/许可仍待处理。
