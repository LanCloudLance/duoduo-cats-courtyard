# N4: spatial choice and visible combat handoff

## Bounded change

This follows `review-next-round.md` N4. It changes only the existing shell/reserve encounters' spatial organization and presentation. No new level, collision wall, enemy count, HP, forced combo, command-hold semantics or saved progression is introduced. The earlier mainline evidence and labels/performance evidence remain separate with their actual source hashes.

The runtime has two real solid circular stumps at (560,320)/(760,555), not a separate root-wall collision system. The design uses those real obstructions, rather than drawing an unimplemented wall.

| Encounter | First wave | Second wave | HP budget |
|---|---|---|---|
| shell | Thorn (870,360) in upper open approach; weaver (960,650) below/right of lower stump | Weaver switches to (670,250), sprout approaches from (1050,610) | 11 + 10 = 21, unchanged |
| reserve | Existing armored (1000,460), weaver (1100,520) | Weaver (950,290), thorn (1020,500), sprout (860,640) | 11 + 15 = 26, unchanged |

Spawn arrival protection still relocates an unsafe spawn if players choose to stand near it between waves. The layout assertions use ordinary initial positions; subsequent input tests retain the relocation rule. The upper/lower paths provide different approaches around a real stump, not rigid lanes or target locks. The next wave changes ranged pressure direction without adding an enemy.

The spare cat prefers legal side/rear points that avoid other silhouettes and warning regions. Movement still uses ordinary stump-aware movement at the previous follower speed. During an unavoidable crossing, the spare silhouette becomes 48% opaque so warnings remain visible. This is **not** a guarantee that the spare body never crosses a warning. It has always been untargeted: switching still brings the incoming cat to the original active slot position, with the same shared HP/cooldowns, so the candidate position cannot become a safe teleport or new rescue exploit. First encounter and general practice retain their previous follower behavior.

A white paw and draining arc now occupy the enemy's safely placed badge for the actual 1.8-second Tuantuan mark. “圆圆可接” appears only when there is no more urgent attack/exposed cue; the first encounter does not show unavailable Yuanyuan. The pre-existing nearby cyan ring remains. Duoduo does not consume the mark. The paw/arc live above/outside body and warning protection regions rather than over a foot-level attack area.

## RED → GREEN and regression

`n4-red-m27_battle_space_test.log`: 11 checks, 3 intended failures (first layout, reversed second-wave pressure, missing spare placement policy). Earlier harness parse/typed-array setup errors were corrected before the behavioral RED; no product behavior was changed to pass those setup errors.

`n4-regression-m27_battle_space_test.log`: 16/0. Checks include both sides actually reaching beyond a stump with legal positions, sword and pounce at real range failing to pass/damage through the stump, unchanged counts/HP, actual mark consumption identity, safe spare candidate, and no HP/cooldown/position exploit when switching. The existing combat suite (38/0) continues to cover hitstop/input buffers and attack identity.

`n4-regression-m27_encounter_input_test.log`: 32/0, solo+dual shell+reserve using normal attacks/held heavy attacks, intermission readiness, low-health rescue, pause and stale confirmation rejection. Generic driver retries were dual shell/reserve 0/0, solo shell/reserve 1/1. These are known-solution technical paths, not blind playtime or subjective difficulty acceptance.

Additional passed checks: labels 13, encounter pace 61, attack identity 34, attack input 12, input feel 3, feedback 10, companion 17, solo rules 17, solo input 18. Pre-existing old harness shutdown ObjectDB warnings are retained in their logs. An initial invocation named two nonexistent split combat suites; those tool errors are retained in `n4-regression.json` and excluded from any passing count. Actual buffer/hitstop coverage is in `m27_combat_test.gd`.

The fixed-fps run exposed one stale guard-input expectation: it required guarding=false immediately after role switching, while the existing solo controller deliberately retains a 0.35-second shield handoff but clears guard_held. The original failure is retained in `n4-combat-regression-m19_guard_input_test.log`; resolution is recorded below.

## Two normal-input choices

`tests/m27_battle_choices_test.gd` uses a real menu mouse event, actual movement/attack/guard/dodge/interact keys and pause/resume. It never edits phase/facts/positions/health to win. Only the permitted encounter configuration is selected before readiness. `n4-choices-m27_battle_choices_test.log`: 16/0, data in `n4-choice-records.json`.

| Mode | Choice | Observed result | Retries |
|---|---|---|---|
| Dual | Defend front approach first | 195 shield samples; first defeated thorn; both waves clear | 1 |
| Dual | Take lower flank first | 118 lower-lane samples; marks caster; both waves clear | 0 |
| Solo | Defend front approach first | 179 shield samples; first defeated thorn; both waves clear | 1 |
| Solo | Take lower flank first | 118 lower-lane samples; marks caster; first defeated weaver; both waves clear | 0 |

The strategy driver chooses a known path and then uses the existing battle driver after the opening. Its retries and inputs are evidence of reachable alternatives, not a balanced player study. No inference of “fun accepted,” child understanding or unknown-solution duration is made.

## Native active readback

Official native Godot 4.7.2 on Apple M5, max_fps60, time_scale1, no fixed-fps. QA namespace `DuoduoCatsCourtyard-qa-m27-n4-native`; headless checks use `DuoduoCatsCourtyard-qa-m27-n4`. Runner copies exclude addons and production saves. The native script opens ordinary practice via a real mouse event then sends real game InputEvents; it is not OS/CUA/physical-controller input. No seeded battle state is used.

Initial capture `n4-native-active.log`: 19/0, 1320 timeline samples. `n4-active-native-front_guard-040/041/042.png` shows the upper charge lane and spare white cat behind the active pair; `n4-active-native-lower_flank-156/157/158.png` shows the side attack and readable white-paw mark. Actual accepted movement is checked before each start. Label/protected-region overlap = 0 over the 1320 samples; the spare passed warning regions in 58 samples, which is why the transient transparency exists.

Detailed timeline review found an important **negative** case: the capture driver released a heavy attack but dodged on the next frame, cancelling it before impact. This initial recording proves mark→switch→charge/release and cancellation, **not** successful combo contact. The original timeline remains unchanged. Only the test driver is adjusted to commit until the heavy contact before resuming evasive inputs; product cancellation rules remain intact. The fresh contact capture is recorded below when completed.

This is bounded active visual evidence, not a new 60-second performance certification. The prior exclusive 61-second measured source is recorded in `labels-results.md` and `labels-source-sha256.json`; N4 changed source after that measurement. Web/OS input and fresh independent review are root-owned.

## Guard regression resolution

The exact same legacy 6/1 failure reproduced against the preserved **pre-N4** `labels-qa` snapshot at fixed FPS 60: `n4-prechange-m19_guard_input_test.log`. Its solo controller is byte-identical to current source. Thus N4 did not introduce the handoff behavior. The test now asserts human guard_held clears on switching, the separate AI guard handoff is positive but ≤0.35 seconds, and after releasing the original key and allowing that bounded interval the shield is down and remains down. No solo/controller product code was changed.

The native-driver headless smoke also retains its failure (`n4-handoff-smoke-...log`): a fresh heavy press during the departing pounce's cooldown can be correctly rejected. The corrected known-solution driver waits until the original cooldown permits the press. `n4-handoff-smoke2-m27_battle_choices_native_test.log`: **9/0**, including actual combo contact. This is not yet counted as a native renderer capture.

## Fresh native contact and final closure

`n4-native-final.log`: **22 checks / 0 failures**, with a real completion marker and freshly written **1320-frame** timeline. `n4-native-receipt.json` records the fresh files' timestamps/hashes and the battle source used. Only those 14 fresh files (13 PNGs plus timeline) establish this run; the reusable QA directory also contains older capture filenames, which are not silently treated as fresh evidence.

In `n4-final-native-timeline.json`, lower-flank frame **195** has an actual `combo` event. `n4-final-native-lower_flank-195/196/197.png` visibly show Yuanyuan's contact, marked target knocked away, “接力掀翻,” and Tuantuan behind the active pair with the ground warning still visible. The complete timeline records 30 ordinary hits, 5 heavy events, 2 interrupts, 2 guards, 1 earned departure assist and 1 combo. Label/protected overlap is zero throughout. The spare crosses warning regions in 47 samples; transient transparency is a mitigation, not a false zero-overlap claim for bodies.

The intermediate `n4-native-contact.log` process exited 0 **without** a completion marker or fresh finished timeline, so it is excluded from acceptance. The initial released-but-cancelled attack remains the negative case. The runner now requires a completion marker and copies only files written during its own run.

The guard migration's stricter **9/1** result (`n4-guard-green-m19_guard_input_test.log`, retained despite its optimistic filename) exposed a real small boundary: the 0.35-second handoff timer expired but the shield remained until the next 0.18-second companion decision. Root authorized the product fix. On the first transition from positive handoff to zero, the solo controller now makes the companion reevaluate current threats that frame. It does not forcibly disable a legitimate AI frontal defense.

`m27_battle_handoff_test.gd` RED **5/3** → GREEN **5/0** checks no-threat immediate expiry and the counterexample of a real frontal windup earning fresh AI guard. The migrated normal-input guard suite is **9/0**, including original human key intent clearing, bounded handoff, key release and no permanent shield.

Final affected regression: `n4-final-regression.json`, **9 suites / 168 checks / 0 failures** (handoff 5, guard input 9, space 16, choices 16, combat 38, companion 17, solo rules 17, solo input 18, encounter input 32). Earlier unchanged relevant labels/pace/identity/input/feedback coverage is separately listed above; do not silently count nonexistent suite names or failed runs as passed. The native final capture predates only the subsequent solo handoff expiry fix; its dual input route is unaffected, and the current solo source is independently covered by the final headless regression.

`n4-source-sha256.json` identifies final owned code and tests. The product diff comprises encounter positions/objectives, battle-state spare placement, arena badge/transparency presentation and the isolated solo handoff expiry correction. No attack timing/damage, collision geometry, readiness/retry/save rule, input router or chapter rule was changed. Root owns fresh integrated mainline, Web/OS input and independent review. This evidence does not declare subjective fun or original duration budget accepted.
