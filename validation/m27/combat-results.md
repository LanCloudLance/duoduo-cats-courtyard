> Update: the later encounter/manual-readiness implementation supersedes the earlier audit #10/#11 open items and source/test totals below. See [combat-encounter-results.md](combat-encounter-results.md) and the current combat-regression.json.

# M27 Combat delivery to integration

Authoritative source changed: game/battle_state.gd, game/battle_attacks.gd, game/solo_battle.gd, game/enemy_visual.gd, input/event_router.gd under outputs/duoduo-game. arena, companion_ai, session_state, lobby, chapters, Git and deployment unchanged.

New tests: m27_combat_test.gd (38 assertions), m27_combat_budget_test.gd (11), m27_combat_render.gd (continuous render capture tool). Existing expectations minimally updated in m16_combat_test, solo_input_test, attack_identity_test and attack_input_test; every assertion retained. Full decision/test/isolation history: combat-progress.md.

Implemented: continued movement through control switch; committed other-slot attacks and bounded shield handoff; AI charge takeover/release; engagement preserved while actively moving near combat; local actor+target simulation clocks and cancellable contact freeze; one-slot post-active buffer; 80ms hurt lock with immediate dodge cancel/fresh combo; forward recoil; exclusive Yuanyuan marked knockdown; reachable safe-position cat handoff; walking contact radius consistent with pounce.

| 12sec fixed-contact strategy fixture | Single target | 75-degree spread pair |
|---|---:|---:|
| Duoduo sword combo | 42 damage / 3.50 DPS | 42 / 3.50 |
| Yuanyuan light slap | 37 / 3.08 | 37 / 3.08 |
| Yuanyuan heavy | 36 / 3.00 | 72 / 6.00 |

Heavy: 3 damage, .48sec charge + .44sec recovery, .07sec contact freeze; 105px range / 90-degree half-angle. Duoduo third hit: 2 damage and ordinary22px knockback except anchored armor/rush; no mark consumption or Yuanyuan text. Heavy marks grant54px/0.8sec control, unmarked heavy32px/0.28sec with control immunity. Real movement costs are excluded from the DPS denominator; the fixture separately tracks displacement. Enemy health/count never raised.

Verified: final combat-regression.json = 23 suites, 430 checks, 0 failed; both solo roles and dual 3-wave ordinary-input paths complete. New tests exercise 60/120Hz actor/target clocks. Native six-PNG continuous trace and separate real rendering pressure metrics are in combat-render.log / combat-live-*.png / combat-live-trace.json / combat-perf.log. Final userdir is qa-m27-combat. Initial inherited override issue and legacy scene-harness exit leaks are disclosed in progress, not silently ignored.

Open acceptance items: unmodified low-health wave rhythm; C4 encounter differentiation from the other author; long-duration overlap/readability; actual player ease, Windows/physical gamepad and Web release checks. This is the completed bounded combat implementation, not whole-game acceptance.
