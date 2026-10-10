# 序章中途恢复与操作一致性 · 2026-10-10

仅改 prologue.gd、prologue_state.gd、新 prologue_checkpoint.gd、新 m27_prologue tests，以及旧 prologue_gamepad_test 的独立 prefix 与工具键断言。无 GUI/Git/部署。

v2 保存 mode、phase、completed、controlled、两位安全位置、wedged/rug_pull/carrier/wedge/ball、白名单 extras、最多32条历史。恢复先完整验证再修改。白猫 home/listen/sniff 在房间锚点，peek/slip 在门口锚点，既有正常短过程继续；leaving 恢复 open 安全门口，complete 保留完成。携带门挡恢复到原持有者脚边；临时 brace/rug_grab/resting/actions/timers/velocity/charge 不延续。门挡与拉出部分地毯永久事实保留。

View checkpoint_path() 指 v2；record_path() 仍为 v1 兼容读路径。read_record() 优先合法 v2，失败再兼容合法 v1 completed；写入只落 v2。≤64KiB读取，临时文件 flush+rename，写失败保留旧档。0.4秒事实变化 debounce、暂停/失活 flush，通关有独立 completion_attempted。Tab/Q/Y/B 保留移动 axes；pause/focus 清键；R/右肩执行附近门挡/撑门/抓卷边工具，G/LB仍提示。

QA 实际 userdir `/Users/wangyuanlong/Library/Application Support/DuoduoCatsCourtyard-qa-m27-prologue`，独立 project 不继承 override.cfg。官方 Godot headless，素材缓存只读复用。

验证日志：prologue-checkpoint.log 103/0；prologue-input.log 17/0（含真实 temp 写失败保留旧档）；prologue-state.log 25/0；prologue-scene.log 正常 InputEvent 单/双通关43/0；prologue-pad.log 8/0；prologue-writer.log 17/0、独立进程 prologue-reader.log 14/0。writer 正常走位拾门挡/放稳/拉42.5像素后暂停退出；reader 新进程恢复永久事实且无保持命令、重新抓取拉完、正常同行完成并读回完成记录。旧pad退出有2个ObjectDB实例warning，功能断言全通过，未据此声称资源零泄漏。

SHA256:
- prologue.gd ec6da1ce11554b3fabdf061eaa618590aaea361c024d5b3baf8a0dfa9f30d46a
- prologue_state.gd c3c6adc2e2e5c628057cf39136703e77aa40ca191b061c7321f1931fb02818a6
- prologue_checkpoint.gd efd2f3e611d080a5e1f7abe30a58bd7be7bf766291c1f7d35d7b92d193114f32

边界：只证明受控输入可达、损坏档拒绝、进程间事实恢复。未做本轮 GUI/陌生玩家/儿童体验验收。父任务负责 fresh 主线整合、lobby runID 与 chapter entry。
