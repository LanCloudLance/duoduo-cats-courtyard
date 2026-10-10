# M27：Godot 运行时闭环与游戏设计 skills 调研

调研日期：2026-10-10。范围：Godot 4.7.2、GDScript、2D、原生与 Web；不迁移引擎。此报告是公开一手资料与部分源码核查，不代表任何工具已经安装、连接或在朵朵工程验收。本次没有执行下载仓库的代码，没有改游戏、Git 或全局配置。

## 决策

**先在独立 QA checkout 实证 `letsagents/godot-mcp`。** 它补充现有 Godot CLI + CUA 最缺的能力：输入之后，直接读活场景节点、脚本变量、错误栈，并把同一状态的画面取回来。首轮只要跑通四件事：按键输入、状态变化、截图、错误采集。

**仅当编辑器依赖成为阻碍时，第二候选选 `Erodenn/godot-mcp-runtime`。** 它可直接启动游戏进程、批量输入、保存无损 PNG，适合重复原生回归。无需同时装两套桥。

GUT/GdUnit4 先作为测试结构参考；当前已有大量项目测试，新增框架只有在参数化、异步场景测试或报告能力确实缺失时才有收益。Skills 只选文末两套材料的少数内容，不整体接管现有流程。

## 已核实的六个候选

“支持”列区分作者兼容声明与作者实测；维护证据只反映本次可见记录，不把抓取时间当最后提交时间。

| 候选 | 运行时输入／截图／状态／错误 | 4.7.2 与维护证据 | 接入成本、Codex 与结论 |
|---|---|---|---|
| [letsagents/godot-mcp](https://github.com/letsagents/godot-mcp) | key、mouse_button、action；游戏 JPEG；活树、ObjectID、属性、表达式；结构化错误栈、print、断点 | 作者矩阵：插件 1.0.0 在 **4.7.2** 通过编译/语法/79 单元断言、编辑器桥、Play/scene-tree e2e；**全 41 工具 e2e 是 4.7.1**。可见 12 commits，规模较小，不能据此推断成熟 | 中：Node ≥20 + Godot EditorPlugin + 正在运行的编辑器。stdio，作者给 Codex 配置。首选 QA 实证，MIT |
| [Erodenn/godot-mcp-runtime](https://github.com/Erodenn/godot-mcp-runtime) | 批量键鼠/动作/等待/UI 定位；PNG 与预览；实时 GDScript/Control 树；自己启动进程时可取 stdout/stderr | 声明 Godot 4.x；未发现 4.7.2 矩阵。可见 272 commits；历史页可核 2026-09-06 v3.2.5、macOS 遮挡截图修复，历史页可能缓存 | 低至中：Node ≥20 + Godot，临时注入 autoload，不要求编辑器插件。标准 MCP 可配置；当前未连接。第二候选，MIT |
| [Vollkorn-Games/godot-mcp](https://github.com/Vollkorn-Games/godot-mcp) | 批量键鼠/手柄、等待/信号；PNG；game_state、表达式、信号、性能；4.5+ Logger 错误栈 | 声明 Godot 4.x；未见 4.7.2 验证矩阵。114 commits；README 说明 CI 构建、测试、lint、格式、类型检查 | 中：Node 构建 + 运行时 receiver，工具面较宽。标准 MCP可适配；未连接。能力强但与前两者重叠，暂不优先，MIT |
| [GUT](https://github.com/bitwes/Gut) | GDScript 测试、断言、double/spy、参数化、JUnit；不提供通用 MCP 活游戏四件套 | **README 明确 9.7.1 / godot_4_7 分支对应 4.7.x**，覆盖4.7.2属于版本范围声明；不是本机实测。main 对应4.6.x，不能随手装main。可见975 commits | 中：addons/gut + 测试代码；Codex可通过 Godot CLI 运行，无需MCP。已有测试不为引入框架而搬迁，MIT |
| [GdUnit4](https://github.com/godot-gdunit-labs/gdUnit4) | GDScript/C#、mock、异步/场景测试；不等于活游戏 MCP 观测 | 6.2.x 矩阵列4.7/4.7.1，**未列4.7.2**；master可见v6.2.2并列4.8.dev7。只能作为待本机验证候选 | 中：Godot插件与测试结构；CLI可用，不是已连MCP。朵朵不需要C#优势，暂不引入，MIT |
| GDMaestro | 本次未取得可核对的一手工具规格 | 已尝试作者站 `https://asymptopia.dev/gdmaestro` 与根站，工具不可访问；未定位到可核对的作者公开源码/许可证 | 安装成本、4.7.2、Codex接口和复用条款均**未验证**。不能因第三方目录或演示宣称能力就入选，不安装 |

证据：[letsagents兼容矩阵](https://github.com/letsagents/godot-mcp/blob/main/docs/compatibility.md)、[MCP server](https://github.com/letsagents/godot-mcp/blob/main/mcp-server/README.md)、[Erodenn工具说明](https://github.com/Erodenn/godot-mcp-runtime/blob/main/docs/tools.md)、[Erodenn提交历史](https://github.com/Erodenn/godot-mcp-runtime/commits/main/)、[Vollkorn README](https://github.com/Vollkorn-Games/godot-mcp/blob/main/README.md)、[GUT版本表](https://github.com/bitwes/Gut#version-links)、[GdUnit4兼容表](https://github.com/godot-gdunit-labs/gdUnit4#compatibility-overview)。

## 首选桥的源码核查与接入边界

### 事实：并非完全不改项目

letsagents README 的“零侵入”意指无需人手写 autoload。实际 [plugin.gd](https://github.com/letsagents/godot-mcp/blob/main/addons/godot-mcp/plugin.gd) 在启用时设置 `autoload/McpRuntime` 并 `ProjectSettings.save()`，退出时清除并再次保存。它还要把 `addons/godot-mcp/` 放进工程并启用插件。因此应使用 QA checkout，记录启用前后 `project.godot` 与 addon 的变化，异常退出后也检查残留。正式 Web 导出不带这套工具。

编辑器持有本地 TCP bridge；游戏侧 autoload 通过内置 debug 协议回复。换场景/重启后节点 ObjectID 会变化，必须重新 `get_scene_tree`，不能缓存旧 ID 当稳定业务标识。`reload_plugin` 会断桥，需重连；`stop_scene` 后运行时查询应失败，不能把上一帧状态当新一轮证据。[架构](https://github.com/letsagents/godot-mcp/blob/main/docs/architecture.md)、[bridge源码](https://github.com/letsagents/godot-mcp/blob/main/addons/godot-mcp/mcp_bridge.gd)。

### 事实：输入三种含义不能混用

[mcp_runtime.gd](https://github.com/letsagents/godot-mcp/blob/main/addons/godot-mcp/mcp_runtime.gd) 的 key 与 mouse_button 调用 `Input.parse_input_event`；action 则调用 `Input.action_press/release`，**不会触发 `_input` / `_unhandled_input`**。所以“开门、确认、交互”优先发真实键位对应的 key 事件并配对释放，移动轮询可以另测 action。发送成功只是注入成功；必须再读状态证明游戏接受并完成行为。

这是引擎内合成事件，不是 OS/浏览器键盘。Godot官方也明确区分 `action_press` 与 `parse_input_event`。[官方Input文档](https://docs.godotengine.org/en/stable/classes/class_input.html)。

### 事实：不改全局配置也能实证，但要正确命名结果

MCP server 包入口是 `mcp-server/server.js`，构建脚本为 `tsc`，Node要求≥20；可用绝对路径启动本地 server，不必 `npm install -g`。客户端是 stdio；Godot bridge默认127.0.0.1:6510，编辑器与server可共同设置 `GODOT_MCP_BRIDGE_PORT`。本地编译/安装前仍需锁定源码版本和检查依赖。[package.json](https://github.com/letsagents/godot-mcp/blob/main/mcp-server/package.json)。

为了先证实 Godot 半边，可写很小的本地 socket 客户端连接 bridge；源码的报文格式如下。这仅叫“原生桥连接成功”，**不是 Codex 已注册 MCP 工具**：

```json
{"type":"call","id":1,"tool":"get_scene_tree","args":{}}
```

每条JSON后换行；返回 `type=result`、相同 `id`、`result` 或 `error`。`screenshot` 在这一层返回本地JPEG绝对路径；MCP server才读文件转image。`await_condition` 是server层对eval的轮询编排，直接bridge客户端要自行轮询。[报文源码](https://github.com/letsagents/godot-mcp/blob/main/addons/godot-mcp/mcp_bridge.gd)。

截图是降采样JPEG，适合判读布局与反馈，不适合像素级回归；后者用现有PNG捕获或Erodenn。错误/日志默认拉取后清空，归档阶段先用 `clear:false`，再记录时间与当前场景。[工具协议](https://github.com/letsagents/godot-mcp/blob/main/docs/tools.md)。

## 与现有 CLI + CUA 的增益

| 已有能力 | 桥补充什么 | 仍需保留什么 |
|---|---|---|
| CLI语法、导入、headless逻辑测试 | 正在运行的节点、时间序列状态与错误栈 | CLI作快速回归，避免每改一个数都启动编辑器 |
| CUA真实窗口/浏览器操作与截图 | 不靠画面猜测血量、任务状态、输入冷却、门锁条件 | CUA验证焦点、Canvas、Web按键、分辨率、首次用户手势/音频 |
| 当前项目专项探针 | 统一查询与调试协议，减少每次临时加日志 | 保留确定性探针和现有测试，不以工具调用计数代替质量 |

这里的增益是工程判断，尚未在本工程计时验证。Web运行环境不支持任意原生TCP；所查两套TCP桥不能直接视为Web桥。原生通过之后，仍用同一行为脚本在实际Web导出中操作并核对存档/画面。[Godot Web限制](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)。

## 两套参考 skills：只取有用部分

1. **[awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills)**：已读 [game-feel](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/disciplines/game-feel/SKILL.md) 与 [level-design](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/disciplines/level-design/SKILL.md)。前者要求反馈挂在离散事件上、按重要性分级并防止反馈阻塞输入；后者要求先测角色尺寸/能力、确定关键路径、先教学后验证、防软锁。这正好转成朵朵的“击中/格挡/打断/受伤必须可区分”和“观察规则→尝试→复用→组合”审查表。代码片段是参考，尤其全局time_scale hit-stop要检查重入/暂停恢复，不能照抄。README给Codex路径不代表本机会自动识别。**Apache-2.0**：复用保留LICENSE、适用NOTICE/署名并标记修改；具体以[LICENSE](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/LICENSE)为准。
2. **[Danm72/ai-gamedev-kit](https://github.com/Danm72/ai-gamedev-kit)**：README披露 `feature-breaker`、`look-critic`、`playtest-bot`。适合借鉴：完成条件必须有状态数字、视觉判断要有游戏内截图、数值调参先固定种子再用新种子复核。它明确说项目必须自备bot、policy、run_seeds和若干capture脚本；并非下载后就能自动玩朵朵。Godot API lookup指向4.7.2-stable，但bridge只把命令转给游戏提供的 `run_command`，不是通用完整实现。本次技能正文请求失败，因此此项只按作者README评估，使用前还需逐个读文件。可见仅1 commit，持续维护未证实。**MIT**：保留其版权和许可文本；[LICENSE](https://github.com/Danm72/ai-gamedev-kit/blob/main/LICENSE)。不要复制Unity迁移、macOS dylib注入、全局hook和agent调度部分。

没有推荐第三套：`vl4dt/godot-skills` 已看到4.7覆盖声明，但新增桥重叠；`bgrenat/godot-game-dev-studio` 聚合很多上游且发行许可证LGPL-3.0，本轮直接读更精确的上游原件更省核对成本。[前者README](https://github.com/vl4dt/godot-skills)、[后者README与来源说明](https://github.com/bgrenat/godot-game-dev-studio)。

## 下一阶段最小实证方案（尚未执行）

1. 在独立QA checkout记录 Godot `--version`、源码commit、启动参数、初始文件摘要、隔离user数据路径。固定插件源码commit，保存LICENSE；仅此副本启用插件。不要让测试读写玩家正式存档。
2. 开编辑器并连接本地bridge，记录一次 `get_play_status → play_scene → ping_game → get_scene_tree`。拿到实际场景路径与节点ID，保存原始JSON。
3. 选一个已存在的简单交互：截图A、读取角色/交互对象状态；从项目InputMap获得真实键位；发送key down，等实际状态改变，发key up；截图B、读同一业务指标。不能调用“直接完成任务/伤害/解锁”方法来冒充游玩。判断标准是状态与画面一致，且第二次可复现。
4. 对一处战斗反馈记录输入、伤害/硬直状态、反馈画面；对一处解谜记录错误尝试不解锁、正确条件才解锁。数值阈值依据当前设计设定，先不发明“最佳手感”数字。
5. 在单独QA测试场景触发一个明确的诊断错误，验证 `get_runtime_errors` 真能捕获文件/行号/栈；随后重开无诊断错误的游戏，确认正常流程无新增异常。不要在正式游戏中制造损坏。
6. Stop/Play再跑一次，证明ID和截图来自新进程；归档命令、JSON、截图、错误与文件变化，正常禁用插件后检查autoload清理。桥通过之后再测stdio `initialize → tools/list → tools/call`，分别报告桥、MCP协议、Codex工具注册三个层级。
7. 同一交互路径在实际Web导出用CUA按键再跑；用户亲自试玩决定规则是否有趣、反馈是否舒服。桥提供可观测证据，不代替体验验收。

采用判据：四类观测都拿到实际证据、stop/start后重现、失败能明确返回、QA变更可撤销，才保留此桥。若编辑器接口不稳则测Erodenn；若两者均不增加定位效率，就继续CLI+CUA+项目探针，不为了“有MCP”扩展依赖。

## 资料与复用记录

MIT工具的源码或实质性片段再分发须保留版权与许可文本：[letsagents LICENSE](https://github.com/letsagents/godot-mcp/blob/main/LICENSE)、[Erodenn LICENSE](https://github.com/Erodenn/godot-mcp-runtime/blob/main/LICENSE)、[Vollkorn LICENSE](https://github.com/Vollkorn-Games/godot-mcp/blob/main/LICENSE)、[GUT LICENSE](https://github.com/bitwes/Gut/blob/main/addons/gut/LICENSE.md)、[GdUnit4 LICENSE](https://github.com/godot-gdunit-labs/gdUnit4/blob/master/LICENSE)。README中的license声明已核对；实际引入时仍应以锁定版本中的完整许可文件为准。

本次GitHub API读取遇403，作者站与部分raw文件不可访问；没有绕过访问限制。维护日期与兼容性未确认处已经留空或标明。先前朵朵偏好只用于确定调查方向：规则发现/复用、操作反馈和真实试玩验收；未用历史发布数或测试数当作当前工程状态。
