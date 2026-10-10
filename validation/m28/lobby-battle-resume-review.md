# M28 独立 Lobby 战斗恢复验收

2026-10-11。SOLO 与 DUAL 均通过实际产品 Lobby 的新建、退出、继续、战斗安全段恢复以及返回故事来源。新增测试是 `outputs/duoduo-game/tests/m28_lobby_battle_resume_test.gd`；未改产品代码或主通关脚本。本项没有启动 GUI，没有操作 Git、部署或正式存档。

## 验收范围和前置 fixture

每个人数模式运行三个不同 Godot OS 进程，共六个进程。成功路径均由真实「退出」按钮结束进程，没有直接测试 `quit()`、直接发出按钮 signal、调用 Lobby 章节启动方法来替代菜单输入。

1. `prepare`：真实鼠标事件选择「新旅程 · 一个人 / 两个人」，确认产品生成新 run ID、人数正确、进入序章；真实 Escape 暂停。然后保存一个经过生产 `chapter_one_checkpoint.restore` 依赖校验的合法第一章 `battle` checkpoint，并写入该 run 的章节继续指针。此步骤是明确允许的入口 fixture，**不是从序章或第一章解谜实际走到战斗**。它不修改任何 live 章节或 Arena state。
2. `segment`：新进程启动真实 Lobby，通过「继续单人旅程 / 继续双人旅程」读取存档；章节自身恢复后发出战斗请求。使用普通 WASD/方向键及 F/J、Q/K、G/U、E/Space 输入清第一段。继续进入第二段并打出实际伤害，在其尚未清除时 Escape 暂停，再点击「退出」。
3. `resume`：第三个进程通过相同普通继续菜单读取相同 run/模式；确认只恢复已清的第一段，处于 `intermission`，没有遗留敌人、未清段伤害或直接通关。普通确认进入第二段，敌人从满血开始；再以普通战斗输入清段、走出口并确认，返回同一个第一章 `station`。验证章节成果和探索记事仍存在、继续指针仍属原 run、第二段真实胜利已由产品持久化。

战斗驱动复用主线验收的 NormalBattlePilot 方法，只发 InputEvent；通过真实 Arena `_physics_process` 推进。不调用 driver.frame、battle.step、arena.configure，不直接写 battle.phase/wave/hp/intermission/positions/enemies 来满足断言。这里的策略是已知解输入验证，不表示真人难度、盲玩成功、主观好玩或真人耗时。

## 实际结果

| 模式 | prepare PID | segment PID | resume PID | 日志报告断言 | 结果 |
| --- | ---: | ---: | ---: | ---: | --- |
| SOLO | 53725 | 53731 | 53740 | 11 + 19 + 25 | 全过，六个 Exit 标记之一到三 |
| DUAL | 53741 | 53752 | 53763 | 11 + 19 + 25 | 全过，六个 Exit 标记之四到六 |

六个进程均 exit 0，日志合计报告 110 条断言、0 failed；打印报告后还会校验 Exit 按钮仍可见，runner 要求实际 Exit signal 观察标记及进程结束。最终日志没有 `SCRIPT ERROR:` 或 `ERROR:`。

- SOLO run：`story-run-1791652116816-1251484`。
- DUAL run：`story-run-1791652121074-1171119`。
- 两模式退出前都已在第二段把 thorn 从 5 HP 打到 4 HP，weaver 保持 5/5；该未完成段没有被算作胜利。
- 两模式重启都恢复为 cleared=1、wave=1、phase=intermission、敌人为空；确认后只运行 wave=2，敌人满血。完成后结果均 cleared=2、outcome=complete，真实 Lobby stage=`chapter-one`、故事 phase=`station`。
- 成果 `equipment`、`supported`、`branch_clear` 保留，原 fixture 记事保留，恢复提示允许追加。SOLO 一实体和 DUAL 两名真人输入实体均检查通过。

## 隔离和可复验文件

实际每次启动首先打印并强制匹配：

`/Users/wangyuanlong/Library/Application Support/DuoduoCatsCourtyard-qa-m28-lobby-battle-resume`

只有通过 OS namespace gate 才实例化 Lobby 或访问存档。QA 项目为 `work/m28/lobby-battle-resume-qa`，override.cfg 使用上述独立自定义目录。执行程序为现有 `work/runtime/Godot.app/Contents/MacOS/Godot`，版本 `4.7.2.stable.official.ed1daf0bf`。固定 60 FPS、time_scale=1，日志全部显式写入 workspace。

发现 Lobby 的旧庭院导入分支会从绝对 M6–M10 目录探测迁移源。因此最终测试在 Lobby 入树之前，仅把无关旧庭院 checkpoint.path 改为 `user://qa-no-legacy-courtyard.json`，使该导入条件不成立；故事与战斗存储仍保持产品默认路径和调用链。初轮在此隔离补强前执行过旧迁移的只读候选探测，没有向任何正式路径写入；最终六进程已全部绕过该分支。这个 QA 防护没有修改产品源文件。

复跑入口：`python3 work/m28/run_lobby_battle_resume_qa.py`。它复制产品到 QA，导入后按 SOLO prepare/segment/resume、DUAL prepare/segment/resume 顺序执行；每个进程限时 150 秒，任何错误、缺少 namespace/Exit 标记、非零退出均失败。运行需要对上面唯一 QA 用户目录的写权限；首次普通 sandbox 被该目录写保护阻止后，已按明确 QA 范围获批运行。

证据目录：`work/m28/lobby-battle-resume-logs/`。

- `solo-prepare.log`、`solo-segment.log`、`solo-resume.log` 和对应 dual 日志：完整引擎 stdout/stderr、实际 namespace、PID、断言结果和 Exit 标记。
- `qa-lobby-resume-solo.json` / `qa-lobby-resume-dual.json`：从唯一 QA 用户目录复制的独立 receipt，含 run、三个 PID、第一段结果、第二段部分伤害和最终故事返回结果。
- `evidence.json`：上述收据以及被测 QA 源文件 SHA256，保留测试时的产品快照证据。最终测试源仅在运行后改了一段退出说明注释。
- `solo-prepare-sandbox-write-blocked.log`：最初因 QA 用户目录写权限不足的失败，不是产品错误。
- `solo-resume-initial-history-assertion.log`：最初误要求 history 完全相等；检查发现生产恢复会追加提示后，测试改为旧记事必须仍包含，不曾改产品。

## 剩余边界

六进程的正常退出仍有 Godot `ObjectDB instances were leaked at exit` 警告（本次 2–25 个），但没有资源 ERROR、脚本错误、恢复失败或进程悬挂。让测试调用栈先退出再点击产品 Exit 没有消除警告；未把其归因为已证实的产品或测试问题，已通知根代理，留作退出资源生命周期检查。本任务不擅自改 Lobby/产品修复。

本项只覆盖第一章 first 战斗的两个模式和中途退出后的真实 Lobby 恢复；shell/reserve 完整主线入口及 15 帧 GUI 验收由根代理的独立工作负责。checkpoint fixture、普通输入恢复验证和全篇输入通关证据保持分别陈述。

工作已完成，停止编辑。
