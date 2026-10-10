# N2 第四章现场观测留痕 · 2026-10-10

实现仅改 `game/chapter_four_state.gd` 的叙事文案、home_offer 目标措辞、派生绘制方法。未改机制、见证 flags、阶段推进或 shared schema。

- `trial_records()` 从 main_return_seen / connected_split_seen / reserve_hold_seen 派生三枚固定铜牌，未见只有线路图，无结果字样。重复实验仍只有三枚，保存恢复来自原有真实观测 flags。
- 试光台右侧现场保留主线、连通旁路、隔离旁路图。脉冲末段的光点写向对应铜牌。结果与实时供光分开标识，收光不抹去旧观测。
- 外罩上方并列先前漏光、补片封稳未复测，只有 inward_verified 才显示复测不漏/仍回流。
- 阿灯台词拆短，备用归途标明独立安全灯匣、主线未修；互动后朵朵明确决定留下，灯匣封存继续保留。

RED `n2-four-red.log` 是缺少 trial_records 的1个真实失败。GREEN `n2-four-green.log` 19/0（隔离→主线→连通、缺失事实恢复、重复/收光、真实补罩复测和决定），旧试验 `n2-four-experiment.log`26/0、旧 review `n2-four-review.log`13/0。全章正常输入乱序单/双回归已通关149/0，日志 `n2-four-input.log`，专用 tests/m27_four_memory_playthrough_test.gd，实际 namespace DuoduoCatsCourtyard-qa-m27-four-n2。

Native fixture 提供但本代理未打开 GUI：`tests/m27_four_memory_preview.gd`。运行在任意新 QA source 后生成 res://n2-four-unseen.png、isolated-only、three-compared、light-off-memory、patched-before-retest、retested、safe-home-offer、choose-to-stay。这是配置图，不是自然通关证据；请 root/视觉作者检查铜牌字号、遮挡与灯匣说明。

C4 SHA256 `665bb1701e15b7077abe3a9ee87b27ff700268b65779460ee56a52767e67b62d`。

本轮没有儿童/真人理解验收，不将观测断言替代玩家是否能解释光路和修罩作用。

全章 input 与旧 pad 测试退出均有同样2 ObjectDB实例warning，无脚本错误/功能断言失败；未声称资源零泄漏。
