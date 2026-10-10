# Latest frozen-candidate result (2026-10-10)

Writer **641/0** and separate-process reader **52/0**, in `mainline-final-mainline.log` and `mainline-final-mainline-readback.log`. Both complete prologue → five chapters → home in one lobby, with ordinary InputEvents and no product-state or HP mutation. Actual run IDs are `story-run-1791644601082-3908237` (solo) and `story-run-1791644622585-25411352` (dual); all 12 chapter records were read back.

Latest combat outcomes: solo first 0 retries/[2,2], shell 0/[1,1], reserve 0/[3,2]; dual first 0/[3,2], shell 0/[3,3], reserve 0/[2,1]. These deterministic known-solution outcomes do not establish difficulty or first-play duration. The latest driver walks the expanded C3 map after companions; the legacy rescue driver now approaches downed actors from safe sides rather than standing inside continuous thorn damage. No combat product rules were weakened for those driver corrections.

The following report preserves earlier passes, failure history and limits. Its earlier HP outcomes, counts and source snapshot belong to their stated runs. `mainline-receipt.json` now contains the latest writer receipt.

---

# M27 continuous mainline InputEvent acceptance

**Earlier integrated result: writer 595 / 0 + separate-process reader 52 / 0 = 647 checks / 0 failed**, `mainline-writer-cleanup.log` and `mainline-reader-green.log`, official Godot 4.7.2. Both modes traverse the full story in one lobby instance. This is a known-solution routing test, not blind play, child usability acceptance, or a frame-time measurement.

## Scope and route

This task changed only new `tests/m27_mainline_playthrough_test.gd`, `tests/m27_mainline_resume_test.gd` and runner/report/evidence files. No product edits, chapter direct starts, live checkpoint restoration, phase/fact/position/HP mutation, GUI launches, Git, or deployment. Product entry changes were made by the parent.

The script clicks the normal SingleJourney/DualJourney button with actual mouse InputEvents, verifies exactly one pressed signal, then uses production key InputEvents for all walking, role selection, tools, combat and chapter transitions. Mouse coordinates use the root final transform; headless Godot uses a 64×64 output viewport with letterboxing rather than the logical 1280×800 scene size.

It reuses known-solution paths from prologue_scene, m24, m27_two_three, m27_four and m27_five tests plus battle_driver. Original tests remain untouched. Their completion-time reset/restore calls were intentionally excluded. Record checks only read saved data and do not replace live state.

Both modes complete:

- Prologue, including actual door brace and carpet drag.
- Chapter one, first battle, station repair and rest.
- Chapter two, support reuse and actual low-window approach.
- Chapter three, real door/reunion, third role unlock, both reflection rules.
- Chapter four, market route, main/isolated/connected optical observations, shell battle, outside repair, reserve choice, reserve battle and rest.
- Chapter five, arm arrest, two manual lid pins, three manual unload/hook segments, outgoing test and explicit receiver confirmation, farewell, portal, equipment storage, paws and voluntary family home completion.

Tests verify chapter titles in state, current HUD objectives, chronology-dependent roster, exact chapter order, actual encounter configuration, one unchanged lobby instance, different legitimate run IDs for the two modes, each completed chapter pointer chapter/runID, and each journey resume pointer at chapter five. Normal Escape/Enter pauses, H journal observation/pause/resume and C5 focus pause preserve earned state.

## Final observed combat outcomes

| Mode | first retries / final HP | shell retries / final HP | reserve retries / final HP |
|---|---|---|---|
| Solo | 0 / [2,2] | 0 / [3,3] | 0 / [2,2] |
| Dual | 0 / [3,2] | **1 / [3,3]** | 0 / [2,1] |

These are this deterministic known-solution run's outcomes, not an ease or no-retry guarantee. The dual shell battle legitimately wiped and retried; test code never injected healing, skipped waves or removed enemies. All waves use production readiness and combat driver rescue priorities.

## Isolation and retained evidence

`python3 work/m27/mainline-run.py <log-label>` makes an independent QA copy, explicitly sets `override.cfg` to `DuoduoCatsCourtyard-qa-m27-mainline`, and runs official Godot headlessly with `--fixed-fps 60`, Engine.time_scale=3 and a 180 second hard timeout. This simulation acceleration is not performance evidence. The full-suite runner needs this namespace and fixed-fps for this long integration suite.

Actual OS namespace is printed and asserted before any QA cleanup/write. Fixed `qa-m27-mainline` names identify the test receipt only; the new product journey entry legitimately allocates independent `story-run-*` names and those are preserved. No product default save files outside this QA namespace are accessed. The initial helper prefix overrides were removed because the product now owns its run identifiers.

The final run preserves 12 chapter completion records and reads every one again after both journeys. `mainline-receipt.json` copies the final QA receipt into the workspace; it lists actual paths, modes, routes and saved histories. `mainline-source-sha256.json` identifies the tested helper and relevant product sources.

## Failure history and limits

- `mainline-red.log`: 2 checks / 1 failed, stage remained bridge. Static inspection independently confirmed the old start_journey called restart_journey and selected bridge. **This first run did not prove delivery of its mouse click**, because its coordinates had not been transformed for the headless window. Earlier wording saying it proved a successful click was corrected to parent immediately after discovering this test defect.
- `mainline-after-entry.log`: still failed before correcting the mouse transform. This is a test-harness failure, not evidence that the parent's entry repair failed.
- `mainline-click-debug.log`: first complete continuous pass, 566 / 0.
- `mainline-green.log`: final stricter assertions, **583 / 0**, exit 0. No script, parse or assertion errors. Godot reports **13 ObjectDB instances leaked at exit**, a separate teardown warning; it is retained, not hidden or counted as a gameplay assertion pass.

No native GUI screenshot or subjective usability acceptance is claimed by this headless integration task.

## Fresh-process Continue acceptance

After writer exit 0, run `python3 work/m27/mainline-run.py reader --resume --verbose` in a separate Godot process using the same QA namespace. Do not parallelize the reader ahead of the writer or include it in an unordered suite glob.

The reader sends actual mouse InputEvents to Continue Solo and Continue Dual; no chapter start or checkpoint restore method is called by test code. Both land in chapter five's completed playable home with matching independent runID/manifest. It checks every durable machine/home fact, repaired tools and network, three-role roster and selected actors, safe actor floors, retained observation history (allowing exactly the new restore notice under the 32-line bound), journal and pause controls, plus all 12 earlier completed files. It passes **52 / 0**.

`mainline-reader-red.log` and `mainline-reader-facts.log` retain the initial comparator failure: actual integer facts and JSON float facts had identical numerical values but Godot dictionary equality treated their types differently. Canonicalizing only the read-only live fact comparison through JSON resolved this test issue; no product restore behavior was changed.

## Audio teardown diagnosis and resolution

The earlier final-stage warning is resolved for these new tests. `mainline-writer-verbose.log` recorded **14 leaked instances: 4 AudioStreamWAV and 10 AudioStreamPlaybackWAV**, no leaked scene Nodes or battle RefCounted models. Clearing test c/s/b references alone did not fix it. With fixed-fps simulation racing real audio mixing, the test exited before pending audio-thread deletions drained.

The only cleanup change is in the new test: clear its references, queue_free the lobby, await four frames, then continue processing frames for **100 milliseconds of real wall time** before quitting. No product audio code, playback behavior or gameplay is changed. Fresh writer **595 / 0** and reader **52 / 0** detailed logs contain no WARNING, leaked instance, script error or assertion failure. This evidence supports a fast-test teardown timing cause; it does not make broader claims about every production lifecycle.
