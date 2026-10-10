# Continuous legacy journey: rescue driver correction

## Finding

The full-suite failure was **not** an unaccepted interact event, frozen rescue timer, or impossible revival. The existing test driver walked to the first point within 70 px and then blindly repeated stationary rescue, ignoring the caster's lasting thorns and attack warnings at that point. With real body obstruction and live enemy pressure, this is no longer a reliable operation sequence.

No product change is needed or made for this correction. The same battle configuration and initial positions succeed with ordinary movement/dodge/interaction when the rescuer chooses another side of the downed partner and commits during a safe gap. This is an automated known-solution route, not evidence of first-time player understanding.

## Preserved RED

Root failure: `regression/runs/20261010-225006-185000/full_journey_test.log`: **16 checks / 1 failure** at “cat walks over and revives girl in continuous run.” The original test source is retained as `rescue-original-full_journey_test.gd`.

Independent instrumented reproduction: `n4-full-journey-probe-m27_full_journey_probe.log`, same **16/1**, QA namespace `DuoduoCatsCourtyard-qa-m27-n4`. The girl was downed naturally by live enemies while the cat remained at 3 HP. The cat travelled from (164.5,616.3) to about (601.1,419.1), 67.9 px from the downed girl at (668.8,424.7). Its movement input was zero, rescuer=1, and rescue_progress reached **0.633 seconds**. After damage cancelled that rescue, it tried again from (602.0,424.8), reaching **0.65 seconds** before another cancellation. The cat then fell and both retried. Thus input and rescue progress were functioning; the unsafe stationary choice failed as the rules specify.

## Correction limited to tests

`tests/m27_rescue_driver.gd` is a test-only helper. It reads existing attack telegraphs, hazard age/radius, enemy positions and the actual rescue radius. It selects a legal approach point around the downed partner, sends normal direction/dodge events to get there and interacts only when the remaining stationary rescue can fit in the observed gap. All movement goes through production input and collision. It neither edits health/positions/phase nor grants invulnerability or clears enemies.

Only the deliberately staged live rescue section of `tests/full_journey_test.gd` uses this helper. The general battle driver, natural downing setup, original rescue assertion (`hp[0] > 0 && retries == 0`), every later combat/health-transfer/puzzle/save/restore assertion and the complete journey remain intact. The new helper's host/battle references are cleared after use.

The original failing path is not deleted or declared successful: its complete trace remains. Existing `battle_state_test` explicitly checks that both movement and damage interrupt rescue; the migrated journey does not change those semantics.

## Pilot and fresh acceptance

Pilot: `n4-full-journey-pilot-m27_full_journey_probe.log`: rescue succeeds at girl HP 2 / cat HP 3, **zero retries**, ending to the girl's upper right at (707.0,384.7). The unchanged remaining legacy bridge→combat→light→bell→rest→resume route then completes **42 checks / 0 failures**. This pilot used fixed FPS 60 as a technical runner, not a performance measurement.

The final independent run uses `rescue-run.py`, official Godot 4.7.2, **headless without fixed FPS**, matching the root suite's timing mode, with namespace **DuoduoCatsCourtyard-qa-m27-rescue**. It runs the full original journey plus rescue-state and wave-readiness regressions. No GUI or production saves are used. Results follow below.

`rescue-product-unchanged.json` compares six relevant combat product files against the prior completed N4 source hashes: battle state, attacks, space, encounter, arena and solo controller are byte-identical. This diagnosis introduces no product fix.

## Final result

Fresh ordinary-time run: `rescue-fresh-full_journey_test.log`, **42 checks / 0 failures**, including the earned checkpoint's fresh-scene resume. Bridge completed at 14.8 s, combat at 106.3 s (remaining HP [1,2]), light at 124.4 s, bell at 141.9 s and the complete journey at **151.5 s**. This is automation wall time, **not** a player-duration claim. The rescue itself again ended with HP [2,3] / zero retries, without moving the initial setup or changing any combat state by assignment.

The original 42 assertions are preserved. Original full-suite RED, independently instrumented RED and fixed-FPS pilot are all retained separately from this final no-fixed-FPS acceptance. `rescue-receipt.json` identifies the exact helper/test hashes and individual regression results. The final complete route has no script error, test failure or ObjectDB shutdown warning.

Final related regression total: **135 checks / 0 failures** (full journey 42, battle state 32, encounter pace 61), with no logged script errors or shutdown warnings. The instrumented one-off probe source is retained in `rescue-probe.gd` under work rather than added to the normal suite.
