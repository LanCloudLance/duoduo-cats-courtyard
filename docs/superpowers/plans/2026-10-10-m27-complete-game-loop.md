# M27 Complete Game Loop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Independent domains may use superpowers:dispatching-parallel-agents.

**Goal:** 将已确认的五章游戏提升到可交付候选，闭环主要规则/控制/反馈/关卡缺陷。
**Architecture:** 保留Godot现有scene/state分离，以共享控制和checkpoint为基础，单独战斗模块和逐章规则。工具仅在隔离QA副本，release不包含bridge。多作者文件所有权明确，root集成/评审/部署。
**Tech Stack:** Godot4.7.2/GDScript、现有Web单线程、原生CLI/CUA；MCP候选经本机验证选用。
**Spec:** ../specs/2026-10-10-m27-complete-game-loop.md

## Global Constraints

- 朵朵主角、团团黑曼基康哥哥、圆圆白曼基康弟弟；序章/五章/回家，既定主线3–4小时是待校准预算，不填充等待。
- PC手柄优先、单人手动解谜/战斗AI、同屏双人。Godot4.7.2，不迁引擎。
- 正式保存与QA隔离；不带工具插件；原Site/受众保持，最终精确源码SHA。

## Review Focus

- 单人换角色但继续按住移动，不得停止输入或取消伙伴保持动作。
- 中途退出/损坏存档/模式切换，必须保留安全进度与恢复边界。
- 已解桥收光/归队不得使角色穿未解地形或永久卡死。
- 命中/受击/持续举盾，事件计时与可见画面方向必须一致。
- 错误实验/乱序到访/多人共同操作必须有真实状态结果，不因脚本固定步骤才能通关。

### Task 1: 工具实证与工程基线

**Files:** work/m27/tools、runtime、evidence；项目 .agents/skills/duoduo-game-loop；docs/art或docs/research保留来源/许可。
**Interfaces:** 原生桥NDJSON的play_scene/get_scene_tree/inspect_node/simulate_input/screenshot/get_runtime_errors；stdio initialize/tools/list/call单独验收。
- [ ] 核LICENSE、固定源码commit、读取skills正文，提取适用于本作的规则。
- [ ] QA工程单独userdir，键按下释放→状态变化→截图，两次restart后新对象读回；诊断错误仅测试场景。
- [ ] 保存bridge、MCP与Codex注册三个不同状态，不让README成功代替本机证据。

### Task 2: 控制/归队与中途保存

**Files:** game/story_chapter_base.gd、story_chapter_view.gd、新story_checkpoint.gd、ui/lobby.gd、tests/m27_checkpoint_test.gd、tests/m27_follow_test.gd。
**Interfaces:** state.checkpoint()->Dictionary、restore_checkpoint(value:Dictionary)->bool、chapter view checkpoint安全点与lobby继续菜单。
- [ ] RED: 单人永久路安全跟随/保持不跟随，未解路线不穿越；暂停不移动。
- [ ] RED: 章节进度退出重开恢复，错误版本/NaN/错误phase/越界拒绝并安全回退。
- [ ] 实现显式白名单状态字段、清理暂态输入/持守、合法安全位置、原子temp写入，保留旧通关记录迁移。
- [ ] GREEN并复跑现有m25通关/保存/跟随套件，正常输入重开验证。

### Task 3: 战斗控制与角色独特收益

**Files:** solo_battle.gd、battle_state.gd、battle_attacks.gd、arena.gd、enemy_visual.gd；相关tests/m27_combat_test.gd。
**Interfaces:** 保持现有press/step/attack/feedback API，角色重拍标记协作显式role==2，普通剑重击仍有自身破防。
- [ ] RED: 换人不清其他角色动作；hitstop期间位置/冷却/攻击/闪避均冻结；受击朝击退方向；朵朵三连不得显示/消费圆圆标记协作。
- [ ] 实现确定取消规则、保留按住轴状态、被击硬直/缓冲边界、反馈方向，记录实际DPS/开口/时间预算。
- [ ] GREEN，复跑现有输入/攻击/单人/AI/波次，连续渲染+不同策略量化。

### Task 4: 主线规则组合

**Files:** chapter_two/three/four/five_state.gd，必要新puzzle规则小类，ui/lobby.gd由root衔接。作者逐章负责，禁止修改共享层。
**Interfaces:** 保持base.step/move/walkable/target/interact/tool API；新增checkpoint字段需root白名单登记。
- [ ] 先按审计对常驻答案/等待阶段写行为反例，记录原路径。
- [ ] C2承重/调光、C3双猫光路、C4可逆分光证实收光/修罩、C5主动修复阶段复用前章规则。
- [ ] 每章正常输入单/双人完整路径，错误顺序/暂停/释放/重试/安全点通关，画面与判定一致。
- [ ] 新行为使旧预期改变时记录原因与新断言，不能为了新代码删失败。

### Task 5: 整合演出、装备、性能和最终评审

**Files:** 依据实际缺陷小范围actor/home/story/chapter/音频/UI；validation/m27-*；build_web.py只在导出需要时改。
**Interfaces:** 延续现有profile/options与完整旅程，主线工具不卸掉；每回合回归读取真实结果。
- [ ] 全旅程正常输入/失败恢复/模式隔离，依原设计逐条实装矩阵，持续缺陷队列。
- [ ] 原生实际动画、反馈范围、遮挡与渲染性能；Web release CUA操作/退出重开。
- [ ] 独立专业/小学生视角评审，问题→实现→不同路径复测；门槛未满足则新轮，不停在全绿。
- [ ] 通过后源/包一致、GitHub/原Site发布回读，交付剩余限制与用户可玩版。
