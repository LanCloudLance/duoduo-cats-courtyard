# M26 动作与第二至第五章素材制作记录

目标是修复角色像立绘滑动，以及第一章以后机关与场景未完成的表现。延续现有绘本风格、朵朵冒险/家居服装、黑猫团团和白猫圆圆两只曼基康的短腿轮廓；不改剧情、音乐、谜题和战斗规则。

下表保存最终接受图的生成编号和提示约束摘要，并非逐字提示词转录。所有图都使用原生 imagegen 生成；本仓库 PNG 与接受的原图像素一致，未用脚本改色、裁切或重绘。运行时根据 JSON 使用 AtlasTexture 区域；第三章背景依据真实碰撞分段映射。导入配置使用有损 Web 纹理压缩，原始 PNG 保留。

| 文件 | 生成编号 | 最终提示约束 |
| --- | --- | --- |
| duoduo-motion.png | 07a81b09-a559-4935-b43e-905ce74e36e2 | Adventure outfit girl pose sheet; final runtime retains four tool interactions. |
| duoduo-front.png | 038ae03b-5377-4d6f-a86f-24f02b3455cc | Eight front three-quarter walking poses, opposite lead legs, fixed outfit and body proportions, 4 by 2 magenta chroma sheet. |
| duoduo-rear.png | b1d269b6-4968-44d1-85df-c676bf251ebe | Eight rear walking poses matching front adventure girl, alternating feet, 4 by 2 magenta chroma sheet. |
| tuantuan-motion.png | bdf4fe5a-73a5-4352-9dca-426566ce6067 | Black Munchkin older brother, adventure outfit pose sheet, four final tool interactions retained. |
| tuantuan-cycle.png | 1e994c7e-97e3-491e-98ba-f8bd732e8e32 | Black short-legged Munchkin, eight front and eight rear walking poses, opposite lead paws, stable outfit, magenta chroma background. |
| yuanyuan-cycle.png | c79c69f8-83ac-46cb-a40a-46eb193cf247 | White short-legged Munchkin younger brother, eight front and eight rear walking poses, opposite lead paws, stable outfit, magenta chroma background. |
| yuanyuan-motion-chroma.png | 91e1b4f6-ba02-4e48-abc6-08baccfb154a | White Munchkin four distinct tool interaction poses, matching adventure outfit, magenta chroma to remove white halos. |
| home-motion.png | 75437a71-3525-4b1e-adb6-4e39606d8f13 | Three rows of eight home walking poses: Duoduo in established black dress, bare black and white short-legged cats, transparent background, storybook illustration. |
| mechanisms.png | 19a902dd-745b-47c7-8601-0ec63f748abe | Sixteen isolated wood and brass mechanisms, lanterns, winches, doors, carts, gears and hinges; readable shapes on transparent background. |
| support.png | 135bcee2-5206-40af-9201-5627ab594e9c | Six isolated support props including friendly squirrel merchant and lantern spirit, lantern cover, branch assembly and parchment route map; transparent storybook cutouts. |
| floor-pieces.png | 3ca0ed8f-f023-4253-a2c8-fdf14024e7b1 | Top-down wooden walkway and pit modules, rectangular walkable faces, matching warm storybook material, transparent isolation. |
| chapter-two.png | 0c1c1382-db90-4197-b540-88edef45862d | Morning forest riverbank and clocktower bridge setting; broad open play area, hand-painted wood and vegetation, no characters or UI. |
| chapter-three.png | 0ee4d428-e75f-4330-bfc7-73b0acc36cd3 | Clocktower interior cutaway, wooden platforms, deep shaft, clockwork atmosphere and broad playable floor, no characters or UI. |
| chapter-four.png | 0f28c6d6-7598-4a30-9f78-c85066e2313a | Twilight market sheltered by tree roots, warm wooden stalls and lanterns, open central floor, no characters or UI. |
| chapter-five.png | b144037c-68b0-4789-99ad-b607dc69277d | Hollow tree maintenance workshop, wood and brass shelves, friendly fairy-tale lantern lighting, open playable center, no characters or UI. |

## 迭代与筛选

初始动作图存在同侧腿重复和生成白边，不能把帧数当成完整步态。补生成独立正/背面步态，按真实相反侧伸腿选帧，重新标注区域与共同地面投影。冒险白猫工具动作改用色键图以清除白边。淘汰的白猫 alpha 图保留在工作区 QA，未进入运行包。朵朵和团团早期图只保留四个工具动作依赖，不承担最终步态。

步态以位移驱动，停步与暂停不继续播放，传送不产生跑步；上行有独立背面，横向按方向镜像。家居图只提供正面三分之四视角，上行复用该视角，部分帧同侧腿重复，仍需后续完善。慢速能看出切帧，详见 validation/m26/animation-review.md。

机关不只是放进背景：桥叶、受光器、齿轮、抱持灯芯、门、树心木臂与关卡状态关联。落差与平台资产经过碰撞边界核对，长竖坑采用端盖和比例中段，避免整体缩扁。

元数据包含区域和锚点，PNG 原图及 SHA-256 见 M26-asset-provenance.json。当前角色衣服仍嵌在动作图中，完整自由换装需要进一步拆分服装与方向动作。
