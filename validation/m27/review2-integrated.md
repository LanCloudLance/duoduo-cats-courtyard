# M27 第二轮独立评审：R7/R8 已闭环，N1–N4 已独立复核

2026-10-10。本评审没有编写本轮产品实现，只写 `work/m27` 下报告与独立 QA 脚本。原六项 RED→GREEN 保存在 `review-integrated.md`，不重复计为新发现。第二轮新发现两个 P1（R7/R8），均已由 root 修改产品并由本评审独立复测；保留原始 RED。总计仍为 8 个主要问题，没有新增未关闭的 P0/P1。

第二轮副本为 `review2-qa`，作者 handoff 仅作定位参考。当前结论依据自己的不同顺序、坏档、实际写入失败、引擎 InputEvent 和状态边界测试，不拿作者 GREEN 当独立实证。第二轮未打开 GUI、未修改产品/Git/部署，也未访问正式存档。所有本评审启动的本轮运行进程已正常结束；系统全局 `ps` 在普通沙箱下被拒绝，因此这里不声称查过其他作者所有进程。

## 结论与证据等级

- **N1 / C3：** 高度、入射方向、镜角与接收面是真实几何关系。八配置矩阵、背面错射、配置不能补锁均通过。新布局里，先高锁→暂停实际写盘→正常重进→低锁，后半段全部走位、转镜、稳光用 InputEvent，17/0；不存在强制低先高后的特殊脚本顺序。布局变化曾造成 R8 中心按钮被邻近拉环抢占，已修复。
- **N2 / C4：** 三块结果牌只来自已完成观测；提前撤光不会获得结论。连通→隔离→主线的不同次序可推进，重复不重复授予，恢复记忆而不恢复临时电荷。真实玩法记录与当前供能明确分开。
- **N3 / C2：** 临时受力从撑扣转给朵朵，再由远端永久锁接管。正常输入下，受压时猫不能拔扣；显式撑住后可拿同一枚扣；失焦取消承重会安全回落，棘轮高度保留，可从局部继续；远端锁定后撤掉身体/灯光仍牢固。20/0。
- **N4 / 战斗：** 自建 24/0，覆盖到期帧、真实威胁重新举盾、两侧真通路、攻击不能穿桩、切猫共享位置与状态、真实命中标记→普通剑不消耗→正常蓄力重拍接力、标记自然消失。还验证了实时 G→Tab→G 松开→到期与备用猫在预告区域内透明度恢复。
- **全旅程与教学：** 正常从头/继续、单/双模式、单独选关与旅程隔离；序章自然拉到 38.25 的进度跨独立进程恢复，重新拉完后进入同 run 的新 C1；C1 的 R 工具与 G 提示分开，Tab 保持动作名牌存在。新旅程指针写失败也已经有可见错误与恢复闭环。

上面“正常输入”均指 Godot `InputEventKey` / `InputEventMouseButton` 经过现有 router，**不是 OS 键鼠、Web、实体手柄或真人首通**。有些脚本从合法章节中段 fixture 起，并非从序章一路自然玩到该段；表中单独说明。读取 `Label.is_visible_in_tree()` 和 `modulate.a` 是引擎 UI 属性证据，不是视觉截图。N1/N2/N4 本轮原生版面与 Web 由 root 另行检查，本评审没有冒充独立目测或人类体验接受。

## R7 / P1：新旅程位置写失败，却没有可见恢复提示（已关闭）

### RED 与复现

原 `ui/lobby.gd` 的 `save_story_location` 没有处理 `story_progress.save()` 失败；内部 `StoryJourney.last_error` 没有传到可见 HUD/继续入口。独立脚本 `review2_journey_write_failure.gd` 5 checks / 1 failed，日志 `review2-journey-write-failure.log`。

1. 在唯一 QA namespace 中写入旧指针 `story-run-111-555`。
2. 只把这份 QA manifest 的 `.tmp` 目标设置为目录，产生实际文件写入失败；不改正式权限或正式文件。
3. 从头开始新的 solo 旅程。新 run 的章节文件可以保存，但旅程 manifest 仍指旧 run。
4. 旧 manifest 字节不变是正确的原子保护。内部报“旅程位置未写入；本次仍可继续”，可见消息、暂停原因、footer 和继续按钮均未说明问题。
5. view 内部 `save_status` 可变成“序章途中进度已记录”；它不是普通序章 HUD 上正在显示的文字，原缺陷不应夸大成截图出现该提示。

专业视角：章节可写不代表旅程入口可以找回它。静默失败会使原本隔离良好的新 run 从正常继续流程中“丢失”。小学生代理视角：我重新开了一次、搬门挡、拉地毯，回来点继续却去了上一次，无法从游戏反馈理解原因。

### 修复与独立 GREEN

当前证据位置：`ui/lobby.gd:98` 独立 `JourneySaveNotice`，`:521` 受影响继续按钮，`:528` 恢复入口保护，`:598` 自动重试，`:801` 保存并回读 run/chapter 才清警告。

同一个真实失败注入重测 `review2-journey-write-failure-green.log` **11/0**：

- 当前运行与暂停都存在可见的独立错误 Label；章节成功保存不能覆盖它。
- 当前模式的继续按钮 disabled，并解释当前冒险可按 Enter 继续；直接调用继续动作也不能跳回旧 run。
- 撤去 QA `.tmp` 阻塞后自动重试，实际文件读回新 run/chapter 一致才清警告、恢复按钮。
- `review2-retry-readback.log` **2/0**：写进程退出后另开进程，InputEvent 点击继续，进入重试成功的新 run，没有读回旧 run 或残留错误。

关闭范围是该可复现写入失败与恢复路径，不声称穷尽磁盘/浏览器存储失效种类。

## R8 / P1：C3 新布局的源控制中心被猫拉环目标抢占（已关闭）

### RED 与复现

新布局 `SEARCH_STAND=(885,530)`，`NARROW=(925,555)`，距离约 47.17。旧目标选择先检查所有角色距 NARROW < 52，再检查源控制 < 50，因此朵朵、圆圆站在画出的“升降 / 稳光”中心，会被当作在操作团团小环。

1. 合法出口侧厅已装灯架，朵朵站 SEARCH_STAND，按 E。
2. 实际 target 是 narrow，源高度没有改变，提示仍讲猫的小环。
3. 换圆圆到相同位置，面向右按 E，也不能稳光。

自己的 `review2-three-target-red.log` **2/2** 直接经引擎按键复现；`review2-geometry-memory-layout2.log` **58/3** 的三个失败是同一目标冲突带来的高锁、恢复、最终开门派生失败，不计成三个新问题。

专业视角：几何规则成立却在控制点中心无法使用，会让试验结果失去可信因果。小学生代理视角：我站在标着“升降 / 稳光”的地方，角色却说猫爪才能用；很容易误以为镜子原理或角色选择错了。

### 修复与独立 GREEN

当前 `game/chapter_three_state.gd:123` 中，朵朵/圆圆在源控制中央 42px 内优先得到 search；团团仍能用窄道环，外围保留错误角色反馈。

- 同一中心反例 `review2-three-target-green.log` **2/0**：朵朵升源、圆圆稳光成功。
- 新坐标与新 target 的 `review2-geometry-memory-targetfix.log` **58/0**：八配置、错误接收面、坏档与高先低后规则均过。
- 不站偏来规避问题：`review2-three-reverse-input.log` **17/0**，从合法已装架 fixture 开始，其后正常走到控制点、错误朝向尝试、升源、转低镜、团团高环、先高锁，暂停写入与正常重进后再解低锁。没有直接补锁、注入光束或模拟对话结论。

## 独立证据索引

| 文件 | 实际覆盖 | 结果 |
| --- | --- | --- |
| `review2-geometry-memory.log` | 初始布局规则矩阵、C4事实/电荷、序章与run坏档 | 58/0，仅旧 C3 坐标 |
| `review2-geometry-memory-layout2.log` | 新布局第一次原矩阵重跑 | 58/3，保留 R8 RED |
| `review2-geometry-memory-targetfix.log` | 当前布局/target：8组几何、背面错射、高先低后、无光不能补锁、非法配置原子拒绝；C4末段撤光与乱序观测；序章坏档；run id与mode | 58/0 |
| `review2-three-target-red.log` / `-green.log` | 真实 source 中央 InputEvent 反例 | 2/2 → 2/0 |
| `review2-three-reverse-input.log` | 合法出口侧厅 fixture 后全段实际走位/按键，高锁→暂停保存→正常恢复→低锁 | 17/0 |
| `review2-journey-writer.log` | 菜单鼠标 InputEvent：solo A→solo B→dual→继续solo；保留旧文件；自然序章拿门挡、安装、拉地毯38.25、暂停写盘 | 22/0 |
| `review2-journey-reader.log` | 独立进程恢复partial，无旧保持；重新拉完；进入同run新C1；单独旧C1隔离；R/G/Tab动作与名牌 | 22/0；退出有3 ObjectDB实例 warning，不声明资源零泄漏 |
| `review2-four-input.log` | 合法调查入口 fixture；后续源、连接、脉冲、撤光、暂停/恢复、诊断全部键盘 InputEvent；连通→隔离→主线 | 12/0 |
| `review2-journey-write-failure.log` / `-green.log` | QA真实临时文件写失败、旧指针保护、可见错误、章节保存不能覆盖、自动重试和实际回读 | 5/1 → 11/0 |
| `review2-retry-readback.log` | R7重试后新进程菜单继续 | 2/0 |
| `review2-two-handoff-input.log` | 合法前桥锁定/后扣在B的 fixture 后：显式撑住、唯一扣、失焦安全回落、局部恢复、远端永久锁与坏档 | 20/0 |
| `review2-n4-independent.log` | N4独立状态与实时输入反例，详细如下 | 24/0 |

N4 的 24 项包括：30/75/144Hz 到期帧立即重新判断，远处无威胁撤盾而真实正面冲锋允许重新举盾；快速切换四次不改变 active ground point/共享 HP/cooldown/无敌时间；备用猫选择可见冲锋线外的合法点，逐步运动受树桩与原 260 速度约束；第一桩上下两侧都可通；剑启动/命中与短扑不穿桩；通过实际 attack/step 生成标记、剑不消耗、正常蓄力和释放接出 combo、自然过期；首战无圆圆；运行中 G/Tab/G up 的短盾和预告透明度。标记测试未直接调用 strike 或写 mark_time。普通攻击规则是状态驱动，后三个控制动作与界面更新是实际引擎 InputEvent/处理帧；未声称完整战斗通关或 OS 输入。

自建 driver 错误同样保留，不计产品缺陷：`review2-geometry-memory-script-parse-attempt.log`/`-script-type-attempt.log` 是测试括号与 typed Array；`review2-journey-writer-coordinate-attempt.log` 是鼠标坐标未乘 viewport 变换；`review2-n4-script-attempt.log` 是把短命反馈事件在过期后当必要条件及错传 `_refresh` 参数；`review2-n4-view-refresh-attempt.log` 是只更新 HUD、未等实际角色处理帧。修正测试后完整复跑；没有修改产品迁就断言。

## 四项关系变式的专业评论与小学生代理回评

### 1. C3：由“换路线”推进到“改变条件后重新判断”

同一个低镜因源高度改变而接收不同入光方向；接收片开口与背面决定是否授予，先高后低仍可解。这让角色分工服务于一个可解释的光路，而不只是记按键顺序。R8 也证明：控制点命中关系本身就是教学的一部分，不能因几何矩阵正确就跳过真实输入。

小学生代理能沿光看出“到哪儿转错了”，无需先背光学术语。人物遮挡、镜面开口能否一眼认出需要真实画面支持；本轮独立 headless 证据不替代 root 的版面检查。

### 2. C4：实验记忆留在世界中，剧情因果更连贯

三牌分别保留“主线回流 / 连通旁路回流 / 隔离旁路留光”，旁注区分记录与正在供光。补罩前后证据也分开；阿灯先解释回收原因，再由实验确认未停，补罩后明确“外罩修好仍不足”。归途匣可用、主线未修好、朵朵决定留下并保留归途匣，因果比一段长解释更清楚。

小学生代理可指着并排结果比较，不需要在脑中保存三个短暂亮暗。风险仍是同屏名词密度：主线、旁路、外罩、灯匣同时出现时，场景短语和图形应承担主要信息，记事本负责详细回顾。当前没有证实新的误导路径，不能把成人措辞偏好包装成 P1。

### 3. C2：合作的内容是接过重量，而非多一次搬运

“撑扣→朵朵→永久锁”确实改变了承重关系；第一桥仍建立规则，第二桥在有限空间中应用新关系。棘轮保留抬升高度，错误后只需局部重接，避免用惩罚性重跑伪造内容长度。单人显式 brace 加保持动作，双人可以讨论何时交接，不要求毫秒同步。

小学生代理的核心问题应是“现在谁托着桥”。从受压不可拔到身体承重可拔，再到永久锁后可放手，操作后果一致；掉线/失焦不会留下悬空猫或复制扣子。这比一串“按R再Tab再R”的口令更容易建立理解。

### 4. N4：战斗已有选择和接力条件，空间可读性仍要按画面评估

真实树桩和不同敌人位置提供挡前方、绕侧处理施法的基础，没有用新血量或固定连招门槛堆内容。普通剑不消耗猫爪机会，换猫保留战斗位置，重拍需要真实时机与命中；短护盾有明确上限，真实危险下的 AI 防御保留。规则上，接力是可选择的收益而非密码。

小学生代理需要看见标记与攻击预告，才有机会作选择。备用猫侧后站位与穿过预告时变透明，是对拥挤的具体改善；不是“人物从不遮挡”的保证。本评审只独立检查候选点、位移、透明度属性和真实攻击后果，不能以 headless 坐标宣布忙乱战斗下可读性或手感接受。

## 内容、节奏与交付边界

上一轮最优先的四项可操作关系变式已进入本轮实现，并各有独立证据；不是仍停在建议文档。它们提高的是条件变化、比较和交接的密度，没有靠重复搬运、额外等条满或复制波次填充时间。本轮没有证据要求继续增加一轮风格性功能才能关闭 R7/R8。

仍应诚实描述为五章可玩内容的技术与规则改善。**175–230分钟 / 3–4小时仍是原设计预算，不是本评审测得的内容时长。** 自动 driver 已知解法、部分 fixture 开始且有 time_scale，不具备首次游玩计时意义；完整未知解法首通、儿童理解、双人自然交流和主观乐趣都未由本评审验收。如果最终实际内容较短，应交付较短但完整的版本并明确范围，不倒推等待或重复段落去满足小时数。

## 可追溯性与复跑

官方 Godot 4.7.2；`override.cfg` 显式指定 `DuoduoCatsCourtyard-qa-m27-review`；每份日志实际输出 `OS.get_user_data_dir()` 为 `/Users/wangyuanlong/Library/Application Support/DuoduoCatsCourtyard-qa-m27-review`。不同脚本用不同 QA 记录前缀，正式 namespace 未读取/写入。

初始源快照 `review2-source-snapshot.json`，N1/N3/R7 中途同步 `review2-n1-n3-r7-source.json`，N1 target 修复哈希 `review2-n1-targetfix-sha256.txt`，N4 六文件快照 `review2-n4-tested-source.json`。第二轮收口时的 `review2-final-source-comparison.json` 对比当时产品 `game/ui` 的 55 个脚本与测试副本，全部一致；这是入口追加修改之前的快照，不能当作追加修改后的 55 文件版本。最后的继续入口补测另见下节及 `review2-entry-source.json`；两份证据都不代表55文件所有行为被覆盖。

复跑基本命令（writer 必须先于对应 reader；不把失败日志覆写成通过）：

```sh
work/runtime/Godot.app/Contents/MacOS/Godot --headless --path work/m27/review2-qa --script res://tests/review2_geometry_memory.gd
work/runtime/Godot.app/Contents/MacOS/Godot --headless --path work/m27/review2-qa --script res://tests/review2_three_reverse_input.gd
work/runtime/Godot.app/Contents/MacOS/Godot --headless --path work/m27/review2-qa --script res://tests/review2_n4_independent.gd
```

R1–R6 原证据、第二轮 R7/R8 的修复、上述成人代理评论应与 root 的完整 mainline、最终 Web/OS 证据分别汇总，不相互冒充验收。


## 最后入口追加独立核对（仅 lobby 变化）

root 随后修改 `ui/lobby.gd`，增加 `resume_story_entry(single)` 与 Web `mode=resume-journey-solo/dual` 分支。当前 lobby 哈希 `552eca821085015dd803fbda49ce3f4d8b836b0956813d7cb2987b3802530c94`；原收口 lobby 是 `c5d092171c2a8ac8399296fa07a17b86f213d3a248427f12ee9e7863df80de82`。`review2-entry-source.json` 对比确认其余 54 个 game/ui 脚本不变，当前测试副本与产品仍一致。原 `review2-final-source-comparison.json` 保持原记录，未覆盖旧时点。

独立脚本 `review2-qa/tests/review2_resume_entry.gd` 与 `review2-resume-entry.log`：**22 checks / 0 failed，exit 0**。每种情况均先建立合法旧庭院记录作为干扰项，再以本次独有 QA 前缀调用真实 `resume_story_entry`：

- 有效 solo 指针：恢复确切旧 run、jam 阶段与 rug_pull=33.5、门挡事实，保持动作不恢复；既不重置指针，也不误说“没有记录”。
- dual 指针不存在、solo 存在：进入新双人 home 序章；可见 prologue Label 明确说明该人数没有旅程记录；不读 solo 或旧庭院；原 solo 与庭院字节不变，新 dual 指针实际可回读。
- dual 指针含非法 run 路径：先被校验拒绝，再进入所请求人数的新 home；提示可见、新指针有效，solo 指针与章节 partial 文件均未改变。
- solo 文件内混入 dual mode：不能读取成双人；重新开始 solo，并保留真实 dual 指针与明确提示。

这是 headless 引擎中直接调用入口函数、读取真实 QA 文件与可见 UI 属性的证据；没有冒称鼠标输入或 Web 浏览器导航。Web query 分支通过源码核对：`mode=resume-journey-` 在旧庭院 `web_solo` fallback 之前调用该函数，solo/dual 判别正确；真实 Web 首页链接和浏览器启动仍由 root 核对。

首次运行未取得新回合 QA 目录写权限，测试夹具建立失败，其日志 `review2-resume-entry-permission-attempt.log` 保留，不计产品 RED 或覆盖率。随后仅申请既定 `DuoduoCatsCourtyard-qa-m27-review` 目录写权限，完整重跑得到上述22/0；未动正式 namespace。未重复整个规则矩阵，未增加 GUI 占用，无新增未关闭 P1。
