# M27 native labels and active-render acceptance

## Approved scope

Product edits are limited to new `game/story_labels.gd`, `game/actor_view.gd` caption presentation and `game/arena.gd` label layout. Root connected the shared solver to chapter one/story views and owns those files. No character-size, enemy-count, HP, collision, attack-rule, encounter or save-contract changes were made for this task.

This work preserves the separate 647-check continuous-mainline and fresh-process resume evidence in `mainline-results.md`.

## Reproduction and design

The original C4 nameplate was 132×26 at a fixed offset. With Duoduo at ARROWS (778,405), it occupied approximately (712,240)–(844,266), crossing Tuantuan's upper body beside BRANCH (715,290). `labels-baseline-c4-before.png` shows the problem in the native renderer. Actual input acceptance was checked first: session.focused=true, D produced movement=(1,0), and Duoduo moved 49.9997 px over eight input frames.

The shared solver keeps labels away from conservative visible actor silhouettes and scene-supplied mechanism rectangles. It uses stable placement candidates with a small hysteresis cost to prevent stationary jitter. Only if ordinary candidates have no safe location does it search a wider ring. This is presentation layout; it never moves a character or modifies simulation rules. Names remove redundant control prose already represented by the selected ring and HUD, while retaining meaningful held-light/holding status.

Arena uses the same solver for names and short enemy status badges. A badge and its HP bar move together. Enemy bodies, stumps, hazards, charge lanes and casting/melee warning regions are protected. Direction arrows, warning rings, guard arcs, rear opening and attack/contact effects remain present.

A second native observation found the pre-existing downed actor scale also compressed its nameplate height. The caption now cancels the body's pose squash for text/plate drawing, keeping its 26px world-space height while leaving the downed body pose unchanged.

## TDD and bounded fixtures

- `labels-red.log`: layout API missing before implementation.
- `labels-green.log`: 12 / 0, including the actual C4 positions, protected mechanisms, unchanged scale, dynamic motion, absent actor and 90 stable refreshes.
- `labels-downed-red.log`: downed actor nameplate compressed by pose scale.
- `labels-downed-green.log`: 13 / 0 after fixing caption drawing only.

`tests/m27_labels_native_test.gd` deliberately seeds a **bounded C4 visual fixture** to reproduce the label conflict; this is not a chapter completion claim. After that setup, walking uses actual production InputEvent routing. The subsequent reserve battle uses the normal practice entry, real attack/guard/dodge/switch/readiness/rescue inputs and actual enemy behavior. Completed encounters can be restarted using the normal pause/replay UI. It does not inflate HP or change enemies to keep a dummy target alive. This performance loop is not another full-story acceptance run.

`tests/m27_frame_meter.gd` records RenderingServer.frame_post_draw wall-clock intervals, process/physics delta and Godot process/physics cost monitors. Godot monitor readings are engine instrumentation sampled per rendered frame, not a claim that every internal operation has a separate profiler span.

## Isolation and boundaries

Official Godot 4.7.2, compatibility renderer on the native Mac. Runner: `python3 work/m27/labels-run.py <label>`. QA namespace is exactly `DuoduoCatsCourtyard-qa-m27-labels`, asserted before use. QA copies exclude addons and are not release packaging. Production saves are not accessed.

Native input evidence uses programmatic InputEvents delivered through the actual application's routing, with focus and movement acceptance asserted. It does **not** establish OS/CUA input, physical controller behavior or Web performance. Root owns those validations. Performance runs use real time, Engine.max_fps=60, no fixed-fps and no accelerated simulation.

## Initial measurement, not exclusive

`labels-current-native-timeline.json`: 61.008 seconds / 3661 rendered samples; interval median16.672ms, p95 17.865ms, p99 18.574ms, max29.094ms; 1 sample >25ms, none >33.333 or >50ms. Physics monitor p95 3.180ms/max7.216ms. It includes movement, attack, shield and 11 role switches. Two isolated right-edge crowded label samples remained, leading to the bounded wider fallback. Other authors may have run short headless checks concurrently, so this is retained as an initial, non-exclusive measurement.

## Final exclusive fresh measurement

Root paused the other authors’ Godot/build processes for the bounded native capture and performance window. `labels-final-exclusive.log` exited 0 without script errors or ObjectDB warnings. `labels-final-exclusive-native-timeline.json` retains raw timings, inputs, feedback, actor/label rectangles and enemy warnings.

- Wall-clock measurement: **61.009156 seconds / 3661 rendered samples**.
- Render interval median **16.680 ms**, p95 **17.859 ms**, p99 **18.694 ms**, maximum **28.703 ms**. One interval exceeded 25 ms; none exceeded 33.333 or 50 ms.
- Physics cost monitor median 2.192 ms, p95 2.732 ms, p99/max 5.820 ms. Process cost monitor median 3.854 ms, p95 5.782 ms, p99/max 12.471 ms.
- Physics dt: 3660 samples at 16.666667 ms. Engine process dt remains about 16.666667 ms; this supplied dt is separate from measured render intervals.
- Movement accepted in **3338 samples**, real attacks and shields, **11 cat switches**. Hit, heavy, interrupt, guard, hurt, defeat, dodge and charge feedback occurred.
- **Zero label/protected-region intersections** across the complete capture and measurement timeline. This does not mean characters never overlap one another.

Current-source continuous image sequences are `labels-final-exclusive-c4-moving-04/05/06.png`, and `labels-final-exclusive-combat-live-015/016/017.png`, `160/161/162.png`, `330/331/332.png`. `labels-final-exclusive-c4-before.png` is the fixed source before movement, not the old-product baseline. Frame 330 shows the corrected downed nameplate, the charge lane and shield in a crowded live battle. The old reproduction is separately retained as `labels-baseline-c4-before.png`.

Small regression (`labels-regression.json`): labels 13/0, battle scene 26/0, animation 87/0, encounter InputEvent 32/0, **158 checks / 0 failures**. Two older harnesses still emit their pre-existing ObjectDB shutdown warnings (21 and 26); their complete logs remain and are not hidden. The new native harness drains audio before exit and has no such warning.

`labels-source-sha256.json` hashes the actual QA snapshot used in the final native run, including the parent’s shared-view/ALIGHT protection wiring. This establishes the tested source boundary even if later N4 or chapter edits change source. It is native Mac renderer evidence only; it does not establish Web performance, physical controller behavior, OS/CUA input, child comprehension or subjective acceptance.
