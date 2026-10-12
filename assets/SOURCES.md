# 资产来源

| 资产 | 作者/来源 | 用途/许可 | 状态 |
| --- | --- | --- | --- |
| source/import_probe.svg | 本次从零编写的原创矢量探针 | 技术验证；随项目源码使用 | 不属于最终美术 |
| ../output/imagegen/emberblade-model-v01.png | 用户授权imagegen CLI，gpt-image-2，2026-10-12 | 原创提示词见docs/design/prompt-character.txt | 初稿，比例未通过 |
| ../output/imagegen/emberblade-model-v02.png | 同上；以上一稿为输入编辑 | prompt-character-refine.txt | 概念参考，比例待进一步核验 |
| ../output/imagegen/emberblade-model-v03.png | 同上；进一步比例修正 | prompt-character-proportion-v03.txt | 紧凑体态候选，动作一致性待修 |
| ../output/imagegen/emberblade-action-keys-v01.png | 同上；模型v02为参考输入 | prompt-poses.txt | 11姿势初稿；未通过最终审核 |
| ../output/imagegen/regions-concept-v01.png | 用户授权imagegen CLI，gpt-image-2 | prompt-environments.txt | 三区域风格参考，不是可用房间资产 |
| ../output/imagegen/camera-scale-review-v01.png | Pillow离线组合既有生成图 | tools/make_art_preview.py | 1280×720概念审核板，非实机截图 |
| ../output/imagegen/silhouette-scale-review-v01.png | Pillow提取缩放既有概念剪影 | tools/make_art_preview.py | 1280×720确定尺寸剪影比较 |

没有恢复旧仓库资产；没有下载其他游戏素材。生成图不宣称独占版权或已完成人工分层；正式使用前需来源与商用授权复核。正式角色动画、音频、字体尚未引入，需逐项登记后使用。用户提供的接口地址和密钥不保存进公开仓库。

| ../output/imagegen/emberblade-model-v04.png | imagegen CLI gpt-image-2，动作v02+模型v03参考编辑 | prompt-model-final.txt | 阶段1冻结概念 |
| ../output/imagegen/emberblade-action-keys-v02.png | imagegen CLI gpt-image-2，模型v03+动作v01参考编辑 | prompt-poses-refine.txt | 修正起跳/翻滚与比例的11姿势 |
| ../output/imagegen/*review-v02.png、model-proportion-review-v01.png | Pillow离线组合/人工标记既有图 | tools/make_art_preview.py | 尺寸/剪影/比例审核，非GPU截图 |
| source/emberblade-rig-spec.json | 本次原创16骨骼/8挂点坐标规范 | 源码同许可 | 技术绑定，非最终分层皮肤 |

| game/pose_visual.gd 程序姿态与场景绘制 | 本次原创代码，无第三方贴图 | 阶段2动作占位，不属于最终手绘 | 已记录GPU离屏审核 |
| game/prototype.gd 合成命中短音 | 本次正弦波/衰减生成 | 原型音效，无外部采样 | 听感待真人确认 |
| Godot4.6.3及内置回退字体 | 官方引擎二进制内置 | 官方MIT及第三方声明见docs/licenses | 随本地包复制；未新增第三方字体 |
