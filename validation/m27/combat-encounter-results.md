# M27 Battle integration follow-up: encounters and player readiness

2026-10-10. This supersedes the first combat handoff's open items for audit #10/#11. Scope remains authoritative outputs/duoduo-game; no lobby/shared/story source, Git, deployment or GUI changes in this follow-up.

## Configuration contract for root

After `arena.configure_solo(session.single_player)`, assign:

```gdscript
arena.battle.story_encounter = "first" # or "shell", "reserve"
```

The setter validates the identifier, sets story_first only for first, and sets wave_total=2. Empty/unknown identifiers use the original 3-wave practice configuration. Existing legacy direct story_first/wave_total assignments still work. Root supplies chapter-facing story_title/story_destination; the encounter HUD now reads wave_total and uses encounter-specific observable objectives even without a title override.

## Different decisions, same existing mechanics

| ID | Wave 1 | Wave 2 | Total HP | Player judgment |
|---|---|---|---:|---|
| first | sprout 4 + thorn 5 | armored 5 + weaver 6 | 20 | Existing two-role introduction preserved; no Yuanyuan before reunion. |
| shell | thorn 5 at (930,310), weaver 6 at (920,620) | sprout 4 at (1050,250), weaver 6 at (1070,670) | 21 | Upper/lower flanks separate pursuit from predicted ground pressure. Move between readable gaps, interrupt the caster or use side cover. |
| reserve | armored 5 at (1000,460), weaver 6 at (1100,520) | thorn 5 at (990,450), weaver 6 at (1160,510), sprout 4 at (1060,600) | 26 | Close formation makes shield opening, caster interruption, broad heavy attacks, and rolling-leaf group control useful together. |

Actual protected arrivals can relocate an enemy to maintain >200px player clearance and non-overlap. Those safeguards are unchanged. The original first-two-practice-wave budget was 30HP / three enemies each wave; neither story encounter exceeds it. Solo and dual share formations, with existing solo single-major-threat cap and longer warnings; dual retains separate-target threat cap.

Shell leaf positions: (920,710), (1160,330). Reserve leaves: (930,500), (1110,700). Tree-stump collision locations remain unchanged. Reserve's first seed lane is behavior-tested: a normally struck rolling leaf bursts near both armored and weaver and damages at least two targets. No new instant damage, health inflation, or additional enemy type was added.

## Pacing and recovery

- Clearing a non-final wave enters intermission, minimum breath 1.25sec. Elapsed time never starts another wave.
- Before the minimum expires, ready presses do not queue a future automatic launch.
- Afterwards, solo needs one real human interaction; dual needs both slots' separate ready events. UI shows who is ready.
- Downed partner rescue takes priority. Rescue restores the existing 2HP only to that partner and is not a ready vote. Standing low-health characters retain current health.
- Pause/focus/exit cancellation clears partial battle ready votes; resume cannot reuse a stale first player's readiness. A new encounter resets all readiness.
- Both downed still retry the current wave using existing retry restoration; no previous wave or chapter is replayed, and no wave is skipped.
- The shared test-only battle_driver owns both simulated human streams: after its downed/rescue branches, dual mode emits E and Space separately. Solo emits only the controlled human's interaction. Production AI never supplies a human ready vote.

## Actual failure → revision loop

1. `combat-pace-red.log`: 18 reached checks, 11 failures before configuration/manual readiness. New configuration branches were guarded until the field existed; final expanded pace suite has 61 checks.
2. Old auto-wave expectations failed in six named suites; preserved as combat-pace-legacy-*-red.log. Existing assertions remain, now checking waiting/partial readiness and explicit starts. m16/solo_rules each gained a start-confirmation assertion.
3. First live InputEvent pass uncovered an external typed Array assignment in arena readiness clearing; changed to indexed writes. Pause/readiness cases now pass without SCRIPT ERROR.
4. Reserve first draft clustered armored+weaver+sprout in the first wave: dual input driver retried 16 times without clearing. Removed that first-wave sprout, moved the caster into a useful two-target leaf lane, and reduced budget 30→26HP. No driver cheats or health changes were used to make it pass.
5. Shell first draft put weaver at (1240,720): solo state-aware driver retried 21 times, repeatedly losing progress during long pursuit under predicted casts. Moved only the caster to the nearer lower flank, with second-wave (1070,670). Same input strategy then cleared without retry. Logs: combat-encounter-input-red.log, combat-shell-debug.log, combat-shell-debug-green.log.
6. Configuration-only HUD still claimed three waves. `combat-encounter-hud-red.log` reproduces it; UI now reads actual wave_total.

## Verification boundary

`m27_encounter_input_test.gd` uses actual InputEventKey press/release via Input.parse_input_event, session/router/arena, production AI and existing battle_driver. At encounter entry it sets only the intended story configuration and chooses the controlled role by Tab. It does not write battle HP, positions, enemy modes, progress, or victory; pauses and all next-wave confirmations are actual input events. Reserve additionally holds/releases the normal attack key until the real charge threshold. Shell/reserve run in both modes, with pauses during battle and between waves, partial-ready invalidation and fresh-entry checks. `m27_encounter_pace_test.gd` separately uses explicit low-health/downed fixtures for repeatable recovery edge cases.

Use final combat-regression.json and combat-m27_encounter_input.log for current totals and outcomes. Fixed-fps headless runs are accelerated simulation checks, not performance measurements or human playtest evidence. This follow-up intentionally starts no GUI while root's MCP probes are serialized. The earlier native rendering/performance evidence predates these encounter layouts and is not a fresh claim about their readability. Existing scene-test exit ObjectDB leak warnings remain disclosed; they are separate from failed assertions or script errors.

Final verified run: **25 suites / 525 checks / 0 failures**. New state suite61/61, actual-input suite32/32. Earlier four-case pass had zero retries; adding a two-frame HUD check changed input timing, and the final solo reserve run retried once before finishing HP[2,3]. Report the final table rather than treating zero-retry behavior as guaranteed.

| Encounter | Mode | Final HP | Retries | Heavy hits | Interrupts | Shield openings |
|---|---|---|---:|---:|---:|---:|
| shell | dual | [1, 1] | 0 | 0 | 3 | 0 |
| reserve | dual | [1, 2] | 0 | 3 | 0 | 0 |
| shell | solo | [2, 3] | 0 | 0 | 2 | 0 |
| reserve | solo | [2, 3] | 1 | 5 | 0 | 2 |
