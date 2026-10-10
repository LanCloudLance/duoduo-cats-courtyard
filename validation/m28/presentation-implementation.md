# M28 表现线实施记录

更新：2026-10-11。范围：表现/素材，不编辑探索 state、输入、战斗、总菜单或正式存档。

## 已完成的制作与正在接入

- 原生菜单基线证据已确认：`baseline-native-menu.png`；总菜单由根代理重做。
- 用内置 imagegen 制作且已复制到权威项目 `assets/visual-m28/`：`npc-states.png`（阿灯、摊主、栗婆婆各三状态）、`chapter-four-stages.png`（灯树室内/外修平台两舞台）、`home-rear.png`（三位家中背向步态）。原始生成物保留，未用 Python 改像素。
- M26 home motion 元数据已接入独立 rear 图，不再用 front 冒充背向；仍需动态渲染复核脚点/比例。
- 新 `story_stage_art.gd`：专用木铜器件绘制，真实接收器、承重柄、锁舌、装备架、开/空箱、铰接机盖、木灯纪念；不是替换为不相干现成图片。
- 新 `story_dialogue.gd`：玩家确认推进的关键对白卡，按 state.dialogue 显示。主线 view 正在接入并缩小常驻 HUD。
- adventure Actor 在主线改接已有 social_sprite；真正 sit/rest/pet 姿态已经有资源，停止压缩站姿冒充休息。
- C4 按 presentation.room 切市场/灯树室内/外修舞台；重画同一 state 的真实器件；C5 归家不再额外画小沙发。

## 与谜题线的已确认合同

`presentation()`：mechanisms[id,position,angle,load,lit,connection]、paths[id,points,width,state,roles]、observations、discoveries、social。

关键对白：`dialogue_active()`、`dialogue:Array[String]`、`dialogue_index`、`advance_dialogue()`。state.step 自冻结；view A 只推进，其他玩法输入不执行。social 持续到对话结束再衰减。H 记事/Esc 暂停由根 UI 控制，view 不改输入路由。

C5 家中：SOFA (400,415)、RACK (175,385)、BOWL (635,515)、纪念桌 (175,270)。`home_discoveries` 只来自实际发现；不给未获得纪念物。

## 当前未关闭

- 新代码解析、独立 userdir headless 结构测试尚未跑；当前不声称已集成通过。
- 新生成 NPC/背向图只做了原图检查，实际尺寸/动作切换/透明边须渲染复核。
- 新 C2–C5 path/器件与 state 接口仍在同步；不能只留旧 draw_world 补新热点名。
- 第五章机体递进和路网回扣、序章/第一章可选发现、同沙发休息仍在接入。
- 本线不操作 GUI；会提供隔离的渲染夹具交根代理运行，固定夹具不等于正常输入验收。

阶段状态：素材已制作，表现集成中，未验收。没有按文件/测试数量计算百分比。

## 第二次接入回读

- 新机制按实际 ID 显示：C2 `outer_bench/outer_ratchet/cart_hook` 与可用/临时/封闭外路；C3 旧图背面的斜光印迹；C5 近/远槽、预备台棘轮、隔离环、唯一撑扣与两卸重座。修正默认白色把锁误画为已锁、关闭机盖不显示、窄木条倒角产生交叉多边形三项真实错误。
- 关键对白期间玩法冻结但可确认，工具键不推进；社会行为使用真接近→接触→确认合同，view 保留步态。落座从互动脚点过渡到原背景沙发座面；复用同一原场景，未叠第二张沙发。
- `story_memory_scene.gd` 随 network 四句确认依次回看驿站、运输桥、钟楼、集市的原场景与已修结果。仅在状态确实 network_lit 后出现，非教程/提示。
- 小木灯有专用无魔力木件轮廓，赠物从 NPC 向角色手部过渡；擦爪有轻微软布动作。实际发现通过 `home_discoveries` 回家，不填未获得物品。
- C4 携灯读取真实 `lamp_position`；空灯座不再留一盏假灯。发现可选灯热点与phase舞台不一致（室内阶段只有不可见摊位/观景热点），已退回谜题线加真实往返子空间，这是尚未关闭的 P1。

验证：`work/m28/presentation-test.log` 最近读回 82 checks / 0 failed，实际 userdir=`DuoduoCatsCourtyard-qa-m28-presentation`，无 ERROR/WARNING。曾触发系统 sandbox 不允许新 QA 目录，按根代理已有授权使用 `require_escalated` 执行仅隔离 QA；未改正式目录。新增 `m28_presentation_render_test.gd` 提供 C2外路、C3重逢、C4三舞台、C5维修、全网回看和归家夹具，等待根代理实际渲染后看图。结构测试不代替实际画面、普通输入或儿童接受度。

## 第三轮实际渲染后的交接（表现线停止编辑）

根代理实际运行并回读 `presentation-render-v3.log`，15 张 `work/m28/render-v3/frame-*.png`；另 `social-render-v1.log` 为 18 帧门/走近/落座/擦爪状态夹具。根与独立视觉代理看图后，以下已关闭：三张停在黑色过场的错误证据；C2 英文内部 ID；平色方盒器件；家中灰格纪念排列与文字遮挡；回看桥面仍断开；归家完成后近身操作提示消失。夹具证明可见行为，不冒充普通输入通关。

新增两套实际纹理状态资产 `mechanism-states.png` 与 `equipment-states.png`，接收器、压力板、承重柄、隔离环、四态卸重座、有/无扣架、开/合机盖、箱体开/空、货车、装备架满/空具有不同轮廓和木铜材质。保留动态光、绳、风、锁舌和受力梁，不以“全部栅格化”作为完成标准。`journey-papers.png` 的旧图折页、货车纸记、摊位画和观景画置于原左桌面；旧蓝毛线球沿用原图，布灯与小木挂件为真实获得物。发现未取得不显示，也不凭空赠一辆玩具车。

C4 门由状态提供真实往返空间，当前房间决定热点和碰撞，靠近门→淡出→到达→淡入。C5 `load_frame` 读真实重心倾斜；`service_front` 东段常通已加入纹理绘制，近槽只封西段；`pilot_waiting` 让朵朵显示望灯 inspect，而非维护轮承重动作。父代理最新即时完成保存修复保留，本线未改其 save_record。

音频：新增 `story_audio.gd`（继承原有 garden_audio，战斗/BGM未改）按真实观察产生木件、金属锁扣、小灯、纸布、承重五种短音；继续使用 `scene.audio.muted`，暂停/离场 stop 并释放语音 stream。`work/m28/story-audio-test.log` 实际最终输出：**25 checks / 0 failed，无 ERROR/WARNING，实际 userdir 为 DuoduoCatsCourtyard-qa-m28-presentation**。覆盖五段非空非静音且互不相同的 16-bit/22050Hz PCM、真实事件分流、静音、set_active(false) 全停声。早版快速同帧 play/stop/free 有一对 WAV/Playback 引用退出警告；最终测试先经过真实播放帧再验证停声，并清理 stream，日志已干净。此测试不证明主观听感。

最近结构：84 checks / 0 failed；家中原步态回归：90 / 0（分别见 `presentation-test.log`、`presentation-home-regression.log`）。技术计数不是艺术质量或趣味得分。根另报告实际全篇单/双 667 干净通过，本线未重做 GUI，也不将该报告转换为真人儿童/硬件接受度。

交接状态：本线实现与修图结束，源码稳定。无本线已知未关闭的可见 P1；最终浏览器、独立总复审及整体发布仍由根代理验收。真人初见儿童、真实 Windows/双手柄、主观趣味、完整时长未测，不宣称通过。
