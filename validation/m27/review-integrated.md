# M27 独立整合评审（六项反例已闭环）

2026-10-10。评审者没有参与本轮章节实现。权威源码是 `outputs/duoduo-game`，本报告仅写在 `work/m27`；不修改产品、Git、部署、正式存档。快照文件哈希见 `review-snapshot-sha256.json`。整合方正在并行修改，下面行号与首轮 QA 快照对应，不能把已修问题再次冒充当前缺陷。

## 结论与证据边界

首轮及追加比较反例共发现 **6 个主要问题**，其中5类由自建反例运行证实，提示可达性先由路由代码定位、修后已用InputEvent核对。没有发现P0。六项现已在下表的已测边界内关闭，原始RED全部保留。**这不是整款游戏、最终入口、Web或人类体验验收。** root正在整合从头连续旅程和第一章工具教学；新lobby及C1输入/表现改动不在本评审旧快照的通过范围内（C1早线索相关interact/schema未变）。下列问题正文保留首轮缺陷描述，不表示当前仍未修。

| 问题 | 独立修复复测证据 | 关闭范围 |
| --- | --- | --- |
| R1 早看线索无法保存 | `review-c1-input-green-write.log` 3/0；写进程退出后 `review-c1-input-green-read.log` 2/0 | 合法驿站fixture起，InputEvent走向线索、互动、文件写入、另一进程正常读回；未伪称从开场连续玩到此处 |
| R2 phase倒退/坏档 | `review-counterexamples-green.log` 8/0 中原C5坏档；`review-revisit-phase-green.log` 4/0 | 拒绝完成事实退回approach；C2后桥扣/C3工具架自然回访不倒退且可保存；未声称穷尽所有非法组合 |
| R3 翻阅/失焦余轴 | `review-counterexamples-green.log`；`review-control-edges-green.log` 11/0 | 十字键、PageUp可翻旧记录；摇杆归中停滚；失焦松杆后再聚焦不继续滚（879→879，axis=0） |
| R4 盾牌owner | `review-control-edges-green.log` 11/0 | G/Tab/up、Q回切、手柄模式LB/Y/up均释放原owner；失焦取消，恢复不重举 |
| R5 提示入口/梯度 | `review-hint-routes.log` 50/0；`review-c4-hint-routes-latest.log` 29/0；`review-c4-hint-context.log` 10/0 | C5七上下文及C4四上下文以V/Y进入三级提示，封顶且不改机关/盾；C4已稳光/已撑布不会误导重复操作，恢复断光会提示重架光源 |
| R6 缺对照却下结论 | `review-c4-comparison-green.log` 7/0 | 主线+隔离分光不能推进；中途JSON恢复不发明连通观测；第三次补连通分光后推进，诊断及待战斗一起恢复 |

首轮哈希见 `review-snapshot-sha256.json`；修后与本次最新补测快照见 `review-green-snapshot-sha256.json`、`review-final-tested-source.json`。没有为凑统计重复运行未变化的用例，也不将交叠断言相加冒充测试覆盖率。

- 官方 Godot 4.7.2；独立副本 `work/m27/review-qa`；`override.cfg` 明确 `DuoduoCatsCourtyard-qa-m27-review`。运行日志实际 `OS.get_user_data_dir()` 为 `/Users/wangyuanlong/Library/Application Support/DuoduoCatsCourtyard-qa-m27-review`。没有读取正式 namespace。
- 自建 `review_counterexamples.gd` 完整执行：8 checks / 5 failed，5 个失败断言对应前 4 类问题。脚本中 C1 与坏档是受控状态反例；journal 和盾用 Godot `InputEventKey` / `InputEventJoypadButton` 经过真实 lobby/router。
- `review-phase-matrix.gd` 为额外状态一致性反例：完成事实换成早期 phase 后，旧快照 C2/C3/C4 大量状态仍通过，C5 的 approach/withdraw 也通过。没有把“所有早期 phase 都应该一律拒绝”当作需求；应结合实际可达互动来校验或规范化。
- 已在root协调的串行空档做过原生渲染与引擎InputEvent；本次续评只运行headless。真实 OS 输入、Web、实体手柄与人类主观体验尚未在本评审中完成。以下“小学生视角”为基于界面/规则负担的成人代理分析，不是实际儿童测试；不给伪造分数或 fun accepted。
- 首次 QA 导入拷到正在修的 journal 类型推断旧错误，后同步 root 已修 `toggle:bool`；这不是本轮当前产品缺陷。完整反例日志无 script error；含系统字体枚举的 FreeType 噪声，不能据此推断画面不显示中文（UI使用项目字体，滚动布局已计算）。

## 主要问题（6 项）

### R1 / P1：第一章先看线索这一合法玩法会使章内保存失效

证据：旧快照 `game/chapter_one_checkpoint.gd:27` 要求 `clue_seen ⇒ lit`，但 `chapter_one_state.gd` 的“白毛与脚印”在 station 时没有点灯前置。自建测试在 station 进入软垫互动后实际得到 `clue_seen=true, lit=false`，JSON roundtrip restore 返回 false。

复现：战斗后进入驿站 → 未修灯，先走到白毛软垫查看 → 继续探索并退出 → 该状态无法保存。最小测试用 enter_station 的受控合法阶段和正常 interact；后续应增加从真实键位走去软垫的复核。

专业评论：自由探索应扩大信息，不能暗中破坏可恢复性。一次可选观察就让后续安全点写入停止，玩家无法建立对存档的信任。

小学生视角：先追着白猫脚印走是很自然的动作，界面没有说“先修灯再看”，离开后重来会被理解为游戏忘记了我的努力。

可验证改法：线索可提前记住，移除错误依赖；完成阶段仍要求灯和线索齐全。分别测试先线索/后点灯及先点灯/后线索，双进程读回两条顺序的中途进度。

### R2 / P1（恢复门槛）：阶段与完成事实的组合可以通过校验、再把自己变成不可保存状态

证据：旧快照 `game/story_checkpoint.gd:59–78` 只对部分后期 phase 加了逆向约束。自建坏档：C5 restore_complete 后设置 `phase=approach, completed=false`，restore 接受；随后正常维护门 interact 进入 `shield`，`arm_locked=true` 仍在，下一份 checkpoint restore 反而拒绝。

复现：加载“后期机械事实 + 早期 approach”的文件 → 三位到维护门 → 互动 → 进入已经锁死却仍要求挡臂的阶段。额外矩阵见 `review-phase-matrix.log`。此为异常存档验证，不声称普通玩家已经自然产生同一文件。

专业评论：校验只看“晚阶段有早事实”不足以保证流程。恢复承诺包括把数据重建成一个可以继续玩的状态，而非接受后才失败。

小学生视角：读档后机器已经停住，目标却叫我再挡夹臂，画面和任务互相矛盾，没有可理解的补救。

可验证改法：定义各 phase 允许的事实区间，异常组合要原子拒绝并提示回到可信检查点，或明确规范化到唯一可继续 phase。别只收紧校验：C3回访工具架会无条件回写 walkway，C2再碰后桥扣会回写 hook，必须同时阻止普通回访造成倒退。验收包含坏档矩阵和自然回访后保存。

### R3 / P1：手柄能打开旅途记事，却无法翻到之前的内容

证据：`ui/story_journal.gd:8–23` 只有 ScrollContainer；open 默认滚至底部，没有焦点或手柄滚动；`ui/lobby.gd:379` 在 journal.active 直接返回。自建 Godot InputEvent 测试填入32条长记录：scroll_vertical=1605，max=2076，focus=null；12次手柄十字键上和6次PageUp后仍1605。

复现：累积超一屏记事 → H / 手柄返回打开 → 用十字键、左摇杆或键盘翻页查前文。首轮实证覆盖十字键与PageUp；摇杆缺少代码路径，但尚未单独运行断言。

专业评论：记事本的作用是降低记忆负担。只允许鼠标滚动，破坏了 PC 手柄优先的阅读和恢复闭环。

小学生视角：我忘了刚才一句话，按返回只看到最后几句，继续按方向也没反应，只能重复问/乱按机关。

可验证改法：记事页接管十字键/摇杆滚动，键盘方向和PageUp/PageDown可用，文案展示控制；滚动不能驱动角色。测试长记录两端可达、松杆停滚、关页不漏移动、断线/失焦不误恢复。

### R4 / P1：按住盾 → 换角色 → 松盾，会变成未声明的永久保持

证据：`game/story_chapter_view.gd:138–139` 把释放动作发送给 release 时的 current actor；`chapter_five_state.gd:301` 非朵朵 guard 直接返回。实际 InputEvent 顺序 G down → Tab → G up，输出 `controlled=1 shield_held=true`，释放断言失败。

专业评论：保持任务本身适合单人合作，但按住/松开的物理语义和“工具锁定保持”应清楚区分。当前相同按键顺序会悄悄改成锁定，难以预期输入状态。

小学生视角：手指已经松开，朵朵却一直举着盾；玩家无法知道是自动帮忙、卡键还是必须再切回来。

可验证改法：记录按下时的动作owner，释放同一owner；如果另设单人锁盾，使用显式工具切换和持续状态标记。测试G、手柄左肩、Tab和Q两种换回路径及焦点丢失。

### R5 / P1（教学闭环）：第五章提示方法存在，但玩家没有输入入口；后两章提示仍没有分层

证据：`story_chapter_view.gd:134–136` 唯一 request_hint 入口为G/左肩，C5分支改为guard；C5 tool也只绑定工具/盾。`chapter_five_state.gd:154` 的 request_hint 只能被程序直接调用。C4 request_hint 一次说出圆圆朝上、朵朵切线路/工具送光、团团隔离；C5同样一次给整段方法。`chapter_four_state.gd:380` 附近还按 single 硬写 R/T 送光，不随手柄模式改变。

专业评论：C2、C3建立的观察→规则→方法提示梯度在最复杂的后两章中断。用G举盾是合理的局部动作安排，但需要保留独立可发现的求助路径。

小学生视角：前面卡住能“想一想”，最后突然同一个键只是举盾；即便找到提示，长句中同时含三只角色、方位、按钮、机构名，阅读和工作记忆负担陡增。

可验证改法：提供始终可达的提示按钮/记事页动作和等价手柄键；按上下文记录0–3层，第一层只指观察点，第二层说明关系，第三层局部方法。画面按当前设备显示键位。验证在C5每阶段通过真实InputEvent逐层调用，且不举盾、不转轮、不消耗进度。

### R6 / P1：第四章仍可跳过关键对照实验，却宣布玩家没有观察过的因果

证据：独立 `review_c4_unwitnessed_comparison.gd` 从调查阶段合法fixture出发，只测主线一次，然后同时改为“分光+隔离”再测一次；从未送光到“分光+相连”的旁路，仍触发battle_one并说“主线和连着的旁路都会被吸空”。`review-c4-comparison-red.log` 明确trial_count=2。

专业评论：主线与隔离分光同时改变两个条件，不能把隔离的作用单独观察出来。已有比较系统是真的，但目前可以跳过证明核心关系的一组实验，叙事结论超出玩家取得的证据。

小学生视角：我只看到主线不亮、小灯亮了，游戏忽然说我见过“连着的小灯也会空”，容易把规则记成“转到分光就好”，不理解断开连接为何重要。

可验证改法：记录且要求连通分光被回收的独立事实，再和隔离分光留光比较；修复后同样两次实验不能推进，补上连通旁路实验才可以。保持可逆顺序，并持久化已经见过的结果。也可以限制结论只说已观察内容，但那会减弱本章因果教学，应由设计明确选择。

## 已改变的核心玩法与仍需体验复核的点

代码证据表明此前“点完等条满”的主要缺口已经有实质改变，不应沿用旧审计结论：

- C2 唯一撑扣从前绞盘卸下再用于后绞盘；永久桥锁接过重量后才能拔出。保留锁定成果使资源复用有安全试错基础。
- C3 同一光束必须从低处直射猫道换成高处反射桥锁，出口又复用反射规则；错误光路不会直接开桥。危险中撤光回安全台，保险保留。
- C4 确实有主线、连通分路、隔离分路和补罩后的可比较试光结果，不再只是三次对话置bool。
- C5 两枚销要换光路；三段折枝要重新选轮口；远灯要走过去主动确认。不是单纯增加等待。
- 战斗有 first/shell/reserve 不同配置和波间主动准备；本评审尚未用自身正常输入验证手感/拥挤，因此不以作者测试日志宣布接受。

这些变化增加了可推理关系，但仍集中在少量固定机关、每章一屏或几个相连状态。3–4小时 / 175–230分钟仍只是设计预算，本评审没有首通盲测计时。不能把headless、受控driver或脚本快进时长当真实首通；也不建议靠延长等待、搬运和重复波次补预算。应先测不知解法的玩家在观察、尝试、移动、阅读、战斗各环节的真实时间，再决定是否需要新的关系变式。

## 修复复测记录

1. 修复复测1：同步权威源后在获得协调的GUI空档原生运行同一反例，`review-counterexamples-retest1-native.log` 为8 checks / 1 failed。早线索可恢复、C5 approach坏档拒绝、手柄十字键与PageUp滚动均通过；当时root尚未落松盾修复，唯一失败为R4。并保存了真实原生渲染的journal截图，仍是引擎合成输入，不是OS物理键盘。
2. R1加强验证：`review_c1_input_restart.gd` 从合法驿站入口fixture起，用实际InputEvent走到软垫并按E；原RED写3/1、独立进程读2/1；修后写3/0、写进程结束再独立进程读2/0。读回`phase=station, clue_seen=true, lit=false`，R1在该顺序的持久化闭环已关闭。
3. R4与R5入口：`review_control_edges.gd` 验证G→Tab→up、Q回切、手柄模式LB→Y→LB up、失焦取消/返回不重举盾均通过。journal V/Y均只增加hint，不换角色、不改机关facts。先测11项里有1项失败：journal向上滚动时失焦，失焦期间松杆，恢复焦点后旧scroll_axis=-1仍驱动滚动，886→829。属于R3相邻边界；root修复后独立同反例为11/0，879→879，axis=0，见 `review-control-edges-green.log`。
4. R2自然回访反例：`review-revisit-phase-red.log` 4 checks / 2 failed，C2后桥扣回访把window变hook，C3工具架回访把map变walkway；该快照仍可save，不谎称已经软锁，但提醒收紧phase schema前同步修正常互动的阶段倒退。修后同反例4/0，window/map分别保持，二者JSON恢复有效，见 `review-revisit-phase-green.log`。
5. 原生fixture复核：`review-four-render.log` 6张、`review-five-render.log`10张，exit0。独立肉眼确认C4隔离小灯与主线回收有差异；C5枝条弯曲与轮架缺口可以区分、远灯确有实体接点。观察到持续稳光猫仍写“等你”、高名牌遮机关的P2可读性问题，已反馈；root随后把保持状态文案改得更清楚，仍需最终画面再核。这些是静态fixture，不冒充连续玩法或儿童理解。
6. 额外独立战斗探针：`review-battle-probe.log`18 checks/0 failed，30/75/144Hz下攻击者动作/位置、目标行为timer/位置同停，旁边玩家仍可动；first/shell/reserve各60秒模拟零主动输入不能由AI清关；双人波间必须分别确认。该结果只支持规则和时序边界，不能代表渲染性能或主观手感。
7. R5全阶段提示：独立C5 UI fixture遍历approach/shield/lure/unjam/test/farewell/home，V/Y轮换请求1、2、3级且第4次封顶，50/0；独立C4同法覆盖market/investigate/exterior/test，29/0。它们是暂停态上下文fixture，不是假造后期facts的正常通关/存档证明。最后一版C4增加了光源与撑布状态上下文，本次同步后又测InputEvent 29/0，加10项定向规则测试确认提示不会让玩家撤掉已保持的动作，也不会把历史duct_seen当作当前仍有光。两份最新日志无ERROR/FAIL。
8. R6第三组对照：新的独立路径按主线→隔离分光→存档恢复→连通分光顺序验证：前两次不能诊断，restore不增加缺失见闻，最后补足后才可以推进；7/0。测试顺序特意不同于线性教学顺序，避免只证明作者预设主路径。
9. 续评启动前read-only pgrep无Godot进程；本次仅headless，没有开启窗口。恢复原精确QA namespace写权限后重跑最新两项，实际OS路径仍是qa-m27-review；正式namespace、产品文件、Git与部署均未改。

原始RED日志保留；每个GREEN只关闭对应边界，不代表人类乐趣接受。下一轮内容与体验建议见 `review-next-round.md`；其中设计提议没有实现，也不作为新增已确认缺陷计数。
