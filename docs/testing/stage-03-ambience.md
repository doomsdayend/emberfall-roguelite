# 铸坊环境动态

验证结果：源码与独立Windows包默认模式各256项、美术预览各697项通过；Windows Intel Graphics/OpenGL最小化窗口离屏36帧通过。证据见 evidence/stage03-ambient-source.txt、stage03-ambient-exported.txt、stage03-ambient-gpu.txt。试玩包已重新导出，使用原参数 `-- --stage3-slice --art-slice-preview` 启用。

2026-10-14：根据试玩反馈，在显式美术预览模式中加入炉光起伏、缓慢向右上方流动的烟雾、随热流上升的火星。炉光绑定现有远景炉口，火星集中在炉口上方，烟雾保持低透明度；所有装饰均位于玩法与角色层后方，不修改碰撞、敌人行为或战斗随机数。

动态时间由游戏逻辑推进，暂停、失焦暂停和结算时冻结；继续游戏时恢复。基础背景仍为单张远景，新增的是环境动态装饰，完整分层场景仍待阶段 3 后续工作。

验证：使用 validate-art-slice.ps1 检查源码与 Windows 独立包，新增火星位置变化和暂停/恢复断言；使用 capture-prototype.ps1 -ArtSlice -Ambient 捕获真实 Intel/OpenGL 最小化窗口下36帧（12Hz采样，3秒），以 make_ambient_review.py 组合为[动态审核图](evidence/stage03-foundry-ambient.gif)。该短序列用于验证画面变化，不作为性能基准或完整场景验收。
