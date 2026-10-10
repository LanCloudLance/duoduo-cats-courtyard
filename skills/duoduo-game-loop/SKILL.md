---
name: duoduo-game-loop
description: Develop and review this Duoduo Godot game in a continuous design, implementation and playtest loop, preserving its five-chapter scope and private release routing. Use for this project only.
---

# Duoduo game development loop

Authoritative game: `outputs/duoduo-game`. Git/Web snapshot: `work/duoduo-web`. Maintain the active goal and `work/m27/loop-state.json`; do not redefine completion as a tool install, test count or a shorter demo. Read the current spec, ledger and audit before expanding a module. User has authorized autonomous iteration and independent domain agents; ask only for missing decisions that materially block progress.

## What changes decisions

- Puzzles: teach an observable rule, let wrong hypotheses change a visible object, then require reuse/combination. No mandatory light-spot checklist, idle timers as solutions, or HUD giving the complete chain. Use escalating on-demand hints. Wrong attempts preserve permanent repairs and permit retry.
- Co-op: Duoduo handles heavy repair/shield; Tuantuan handles precise hook/interrupt; Yuanyuan supplies stable light/area control. Single-player switches roles manually for puzzles; combat AI may support. Safe follow is limited to permanent travel floor and never actuates a puzzle or abandons an actual hold.
- Feel: distinct hit/block/interrupt/hurt events. Inputs survive role handoff and short contact stops. Freeze relevant target/attacker timers consistently; an uninvolved co-op partner can continue. Test single-target efficiency and multi-target control instead of inflating HP.
- Recovery: explicit persistent fact/configuration whitelists; reject invalid dependency/phase/mode before mutation; clear transient holds/timers; atomic file writes and actual separate-process reads. Keep legacy completed saves readable.
- Presentation: inspect rendered moving frames, physical mechanism geometry, interactions and occlusion. Static scene fixtures prove layout only. Engine InputEvent proves engine input only. Browser/OS/controller acceptance needs its own evidence.

## Tools and evidence

Use the bundled official Godot executable and QA copies. `override.cfg` overrides project userdir: verify the **actual** OS user_data_dir is task-specific before writing saves. Import a fresh copy before scene tests. Never use the production save namespace for QA. Put timeouts on failing/hanging test processes.

Local reference checkout: `work/m27/tools/awesome-gamedev-agent-skills` at pinned SHA in tool-research.md. Read discipline `game-feel`, `level-design`, and Godot/GDScript selectively. They are references, not authorization to migrate engines or install unrelated frameworks.

Optional runtime helper: `work/m27/tools/godot-mcp` and `mcp_stdio_probe.py`, QA-only editor addon, port 6527. MCP initialize/tools/list is not runtime success. Play launches asynchronously: wait for debugger, desired scene node **and initialized dependencies**, then read state after input and view screenshots. Refresh tree/IDs after restart. Use key down/up pairs, not `action_press` for `_input` interactions. Preserve collector traces with clear=false. Keep addon and its autoload out of production exports. Local stdio client use is distinct from a registered native Codex connector.

Repeat: reproduce one player problem → define visible result and counterexample → implement → ordinary-input successful + wrong/recovery paths → rendered review → fresh independent professional/child-perspective agent critique → repair major defects → retest a different path. Tests do not establish subjective fun or real child/controller acceptance.

## Release gate

No unresolved P0/P1; no unexplained suite failures; continuous mainline, failure/recovery/save checks and actual render/Web evidence. Preserve original Site project and private audience. Synchronize exact GitHub SHA, source snapshot, package and private deployment receipt after integration is ready. Report remaining human/hardware checks honestly; do not send a half-integrated build as the final game.

Sources: [game skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills), [Godot MCP](https://github.com/letsagents/godot-mcp). Pinned unmodified upstream checkouts retain their Apache-2.0/MIT notices. This project instruction is original text, not copied upstream code.
