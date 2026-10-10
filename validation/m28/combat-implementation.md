# M28 战斗实现合同与进度

2026-10-11。实现依据 rebuild-spec.md 与 combat-review.md 的 B 方案。本文随真实结果更新，不把接口提案标为已完成。

## 给根集成的接口（固定）

```gdscript
arena.configure({
    "id": "first", # first / shell / reserve / practice
    "mode": "solo", # solo / dual，须与 session.single_player 一致
    "available_role_ids": [0, 1], # 只有已经入队角色；0朵朵/1团团/2圆圆
    "selected_role_id": 0, # SOLO初始出战；DUAL此字段可忽略
    "current_cat": 1, # DUAL P2初始猫；SOLO保留为探索返回偏好
    "story_run_id": "...", "return_chapter": 1, "return_phase": "battle",
    "cleared_segments": 0, # 0/1/2，只用于已核实的段进展，不能伪造完成
    "title": "驿站前 · 荆棘拦路", "destination": "小路露出来了。",
    "allow_next_level": true
})
var result: Dictionary = arena.result()
# {encounter_id, mode, completed_segments, outcome, selected_role_id,
#  current_cat, story_run_id, return_chapter, return_phase}
```

- `configure(context)->bool` 校验后才替换战斗；错误保留已有状态并返回 false。mode不匹配拒绝。正式主线调用此接口，之后不要直接改 hp/positions/story_encounter/wave_total。
- `arena.next_level_requested` 保持无参数原信号；仅在 phase=complete 后再次按互动触发。根回调读取 `arena.result()` 并校验 `outcome=="complete"`、encounter_id/返回章，再推进对应清路事实。
- `arena.result()` 是只读新字典；没有任何自动章节／存档写入。`completed_segments` 为真实已清段数；结束仅完成普通战斗，不修改探索角色、工具、修复或发现。
- `arena.configure_solo(bool)` 暂留旧挑战包装，配置 practice 已入队三人，不保证旧AI设计测试继续成立。`restart()` 复用当前完整 context 的新开局，而非退回 practice。
- 保留诊断兼容字段 `battle.positions[role_id]`、`battle.hp[owner_slot]`、`battle.current_cat`、`solo.human_slot=0`。**SOLO hp[1] 为闲置兼容格，绝不参与生存/伤害/准备/救援；唯一真血条为 hp[0]。** 新逻辑必须遍历 `battle.deployed_slots()`；`battle.actor(slot)` 读 roster，可在 SOLO 返回猫。
- 新 `battle.role_slot(role_id)` 返回部署玩家槽或 -1；`battle.available_roles()`、`battle.deployed_slots()`、`battle.request_switch(slot)`；换人无隐藏攻击。探索继续自己的 PartyState，不接此 roster。
- 设置合同：`arena.shake_enabled` 只管镜头，`arena.rumble_enabled` 只管手柄振动；`arena.audio.muted` 仍管声音。局部 shake_button 已移除，交由发布暂停设置。调用 configure 后父层可按设置重新应用；不在每帧覆写。
- 未要求修改 session_state；十字方向在 event_router 映射为现有轴接口。键盘 U 为P2角色技；G为SOLO/P1角色技。按下/释放实例归属在 Arena/战斗适配器实现，不修改 root 的 signal签名。

## 文件范围

独占 battle_roster/state/attacks/space/encounter、solo_battle、arena、enemy_visual/pose、combat_sprite、event_router、新 battle helper、tests/m28_*combat*。为避免影响旧引用，Space 保留旧默认静态工具，新增布局实例包装；旧 battle_garden 保留，新 battle_terrain 对当前部署集合与实例空间工作。不编辑 lobby/探索state/actor_view/素材/Git/部署。

## 当前进度：实现完成，等根集成/渲染审查

- 已实装：部署 roster、单人三角色手动换人/双人猫候补、各玩家共享3HP、无单人AI；真实三普攻与三个角色技；启动/有效段换人缓冲；按角色实例与 generation 归属释放；三场不同地形/两段敌组；局部失败重试；完整 configure/result；紧凑HUD/安全边候补、动作身份和打断/控场反馈；Dpad与G/U角色技。
- 未改 session_state、探索 state、lobby、actor_view、任何素材或正式存档。第五章继续探索模型，不接 roster。未 Git/部署/GUI。
- 核验不是趣味或真人通过：下面是确定性普通输入和反例证据；根仍需实际渲染、主线入口/保存集成、独立审查。真实手柄/Windows/孩子体验未验。

### 隔离与运行

`python3 work/m28/combat-run.py <suite>` 每次从权威源复制到 `work/m28/combat-qa`，override使用独立名字。每个M28测试首先核验 `OS.get_user_data_dir()` 实际为 `/Users/wangyuanlong/Library/Application Support/DuoduoCatsCourtyard-qa-m28-combat`。唯一QA目录创建经过沙箱单项审批；没有触碰正式目录，没有写保存。

Godot官方4.7.2，headless，单进程150秒上限。最终重新导入已0引擎/脚本错误（`combat-import.log`）；QA用户目录为空，没有生成存档。单项只读进程检查确认没有遗留 combat-qa Godot进程。脚本错误/引擎错误即使退出码0也判失败。只终止本次执行的测试进程，未全局杀进程。初始导入错误与两版失败驾驶器证据保留，不把它们覆盖成通过。

### 已得到的结果

| 证据 | 实际结果 |
| --- | --- |
| `combat-m28_combat_contract_test.log` | 58检查，0失败：一实体、资源/运动继承、无换人赠伤、过期释放、蓄力取消、打断取消施法、三角色诱撞、局部重试、真实合作反事实、双人独立缓冲、普通键盘/Dpad/暂停、独立设置 |
| `combat-m28_combat_feedback_test.log` | 17检查，0失败：60/120Hz局部停顿与伙伴仍可移动；准备→挥扫动作；锁定方向不随换人重瞄；扑击不穿桩；重拍不穿硬壳；实测预算 |
| `combat-m28_combat_playthrough_test.log` | 21条完整两段+出口普通输入路径，0失败；P2返修后的团团shell纯普攻近敌路线1次局部重试，其余0重试。经 Input.parse_input_event → _input → router → arena；驾驶器无血量/位置/敌人状态写入。战斗状态探测仅用于已知解法选择 |
| `combat-session_state_test.log` / `combat-keyboard_test.log` / `combat-event_router_test.log` | 旧保留合同分别37/13/10，0失败 |

21路径为：SOLO first的朵朵/团团，shell和reserve的三位，分别纯普攻与可用角色技，共16；DUAL first猫1、shell/reserve猫1/2，共5。没有把尚未归队圆圆硬塞进first。返修后已知解法纯普攻SOLO约11.3–22.3秒/场，承伤0–3（最高项含一次重试）；带技能11.3–22秒；双人11.7–14.7秒，总承伤0–4。这是机器驾驶器时间，**不能当真人游玩时长**。圆圆重拍在单目标驾驶路径并不总更快；角色技的价值是宽角/空间/中断，不强迫每次都用。

固定靶12秒预算（每帧把靶复位，只做对照，不冒充实战DPS）：朵朵3.50、团团3.25、圆圆轻拍2.92、圆圆重拍2.50伤害/秒；75度分散双靶时重拍5.00，其他仍单靶预算。重拍单次45像素推动，轻拍13；持续12秒累计推动450 vs455，未把“每次更强”谎称“持续位移必更大”。

合作因果反例使用相同猫动作：真人举盾把冲锋停成背结窗口→猫可在后侧伤害；不举盾→该时机仍关闭/冲过，猫同次攻击没有对应伤害。另验证一人蓄力时另一人能缓冲普攻，失去伙伴须真人靠近互动救援。双人收益不依赖角色顺序密码。

### 发现与修复/迁移

1. 真缺陷：DUAL数组推断类型导致切猫报错；Arena跨对象typed ready数组赋值；失败后hurt锁阻止选人；P2蓄力曾挡住P1缓冲；持盾在剑启动中按下曾被丢弃；Dpad暂停释放可能残留。已修并新增反例。
2. 驾驶器缺陷：初版从死亡提前return而不重试；猫背面接近阈值高于攻击距离；预告出现就长期撤离，会在边缘织藤循环里不再进攻。修正驾驶策略后21路完成，未降敌人HP/伤害迎合它。失败文件 `combat-playthrough-initial-driver-failures.log`、`combat-playthrough-avoidance-failures.log` 保留。
3. 旧 `m20_enemy_motion_test` 首条失败：fixture默认 `_spawn` 近身位置现被190px抵达保护迁走，预期立即近战不成立。新反馈测试显式 `protect_arrival=false` 仅测试fixture并覆盖同一动作事实。旧测试没有改成假通过，日志保留。旧M27 mark/AI/猫X蓄力等断言按下表迁移。
4. 新test一度以累计位移推断重拍收益，实际预算否证；改成单次投入的位移与宽角伤害对照，并保留真实累计值。未据此无端加伤或推力。

### 根集成仍需检查

- 三场 root configure 参数、返回章节/phase/run-id 与 completed outcome校验；断点只信已核实cleared_segments，不把失败保存成清路。
- 真实渲染中看候补安全边/角色脚点、压缩HUD与危险地面是否相遮；三场使用同底图但不同布局、支架/树梯舞台线索，不声称已获美术验收。
- 实际音响/手柄校验；本轮复用原音效角色音高，控制事件伴随真实heavy，精扑有interrupt。镜头关闭不影响rumble，反之同理。

## 旧设计断言迁移

| 旧测试/假设 | 主动替代 |
| --- | --- |
| companion_test、solo_rules中 AI 输出/救援/接管第二槽 | SOLO一实体、闲置槽完全无伤害/目标/救援、失败需真人重试 |
| solo_input 中 human_slot=1、两槽轮流接管 | human_slot恒0，actor(0)变角色，方向/资源/动作归属不丢 |
| attack_identity/input 中猫X普攻=短扑或蓄力 | 猫X独立快抓/轻拍；LB精扑/蓄力拍，分别验证时机 |
| m27_battle_handoff 的离场AI盾、mark→switch伤害/独占接力 | 离场立即卸盾，switch不伤害，控场无需标记；实体共享脚点/恢复 |
| m27_battle_space备用猫战线避让 | 候补在安全边无战斗职责；镜头/目标/碰撞仅部署角色 |
| battle_driver/m27主线旧已知解法 | 新普通InputEvent驾驶器按新招式/三种战法完成，旧脚本不是产品规则 |

保留原文件不改断言。失败必须按“设计迁移／真实缺陷／驾驶器过期”归类并补新证据。

附加迁移：`m20_enemy_motion_test` 的默认近身_spawn fixture需显式关闭抵达保护；其动作时钟不变量由 M28 feedback保留。旧 `Battle.FIELD/EXIT` 静态常量现为布局实例属性，场景/诊断应使用 `battle.FIELD/EXIT`；旧默认波数3改为各场两段。

## 独立审查返修（2026-10-11）

已接受 `independent-combat-review.md` 三项P2，并新增 `m28_combat_review_regression_test.gd` 22项反证，0失败：

- 精挡：主线硬壳比常挡多0.60秒暴露（相同推进后3.783 vs3.183秒），荆棘多0.45秒。相同“挡后越到背面、稍晚再挥剑”输入，精挡后实际造成1伤、常挡后已重新闭甲而0伤；不是仅换parry文字。正常挡依然可靠保命。
- 出口：保留clear→complete→返回的结果合同；complete HUD明确单人“E/A继续返回”，双人“任一位E/空格（或A）继续返回”。根仍只接无参next_level_requested并读result。
- 猫技：恢复末0.18秒的单格意图，role+generation归属，后来的普通攻击/角色技替换前一个意图，不堆队列。团团一次轻按即使已松开也可接扑；圆圆必须保持按住直到实际开始蓄力，排队时提前松开取消；不把等待时间算蓄力。角色切换/暂停/取消都会清除；窗外拒绝有短反馈，HUD呈现剩余角色技冷却。

### shell目标关系重做

没有加敌人数量/血量/伤害。仅shell：织藤花向前排荆棘/嫩芽建立**可见连藤**，只护正面；侧后方的任一角色普通攻击仍有效。打掉来源、真实打断来源/重拍压制、卷叶撞源或冲锋撞源可让连藤消失/短暂断开；实体桩的遮挡也阻断连线。前排正面弧、连线闪动和“连藤护住正面/连藤断开”读同一规则。没有角色颜色门或先后按键密码。

按独立报告原样保留的“只追最近、每0.2秒普攻、不看前摇、不闪避/角色技”反例：first仍可清完（定位为入门容错），shell三角均第1段失败/承伤3/被挡5；reserve仍第2段失败。不是用这个失败声称战斗好玩，它只否定旧shell被相同策略无取舍清完。

`m28_combat_strategy_test.gd` 六条普通InputEvent完整两段路线对照，全部完成；比较只改变目标优先级，均不用角色技：

| 角色 | 近敌优先（被挡/承伤/重试） | 后排优先（被挡/承伤/重试） |
| --- | --- | --- |
| 朵朵 | 3 / 2 / 0 | 0 / 1 / 0 |
| 团团 | 3 / 3 / 1 | 0 / 2 / 0 |
| 圆圆 | 4 / 0 / 0 | 0 / 2 / 0 |

后排优先减少地面威胁峰值2→1及正面反弹，但圆圆本次近敌绕侧路径更安全；两顺序并无唯一正确答案。团团近敌第一尝试失败文件 `combat-strategy-first-attempt.log`保留，最终明确计入一次局部重试，未把失败藏成零损通关。总21基础路径仍全部完成，唯一新增重试同上。

GUI取证脚本与15帧验收条件见 `combat-render-contract.md`，包括连藤、甲背、扑击、蓄力/接触/回收、出口双确认与DUAL舞台。作者只完成check-only，实际GUI运行/看图由根安排；没有冒充已查看像素。

## 候补裁头返修（2026-10-11，实际15帧review后）

根与独立visual reviewer确认旧候补脚点world y170投到屏幕约y140，朵朵/猫头部被固定顶栏遮住。作者查看了根QA的01-linked-front与15-dual-staging旧像素，复核同一现象。

只改候补摆位与板凳：`battle_layout.reserve_point(index)` 把候补放到场地左侧安全边（x=FIELD.left−78，y=FIELD.top+180+index×195）；`park_reserves`按同一坐标摆位；arena画独立小座位取同一位置。镜头、FIELD、STARTS、敌人/攻击/HP/换人规则均未改。角色身体与名牌整体处在可战斗几何之外，顶栏下方；战场主体大小不缩小。没有改actor_view或故事view。

新 `m28_combat_reserve_layout_test.gd` 在first/shell/reserve/practice、SOLO/DUAL与各可用角色组合检查120项，0失败：部署出生点等于原STARTS；候补完整保守轮廓/名牌不与FIELD相交，投影在固定顶栏与底栏之间且不裁左边。58项原战斗合同也0失败。这里是几何反证；新的实际15帧由根继续运行、看图后才确认像素通过。

GUI fixture的frames.json新增reserves数组（role/pos/body_rect/caption_rect），供逐帧比对候补，而不只记录部署角色。请复制本次4个源文件与新fixture后重跑：battle_layout、battle_state、arena、tests/m28_combat_render_preview；无需改关卡上下文。
