extends "res://tests/keyboard_scene_test.gd"
const Driver = preload("res://tests/battle_driver.gd")
var b
var single := false
var heavy_inputs := false
func drive(slot: int, vector: Vector2) -> void:
    axes(9 if single or slot == 0 else 18,vector)
func tap_key(code: int) -> void:
    var mapped: int = {KEY_J:KEY_F,KEY_K:KEY_Q,KEY_SPACE:KEY_E}.get(code,code) if single else code
    if heavy_inputs and code == KEY_J and b != null and b.current_cat == 2:
        key_event(mapped,true)
        return
    key_event(mapped,true)
    key_event(mapped,false)
func run() -> void:
    lobby = load("res://main.tscn").instantiate()
    root.add_child(lobby)
    await frames(2)
    lobby.session.set_focus(true)
    for solo_mode in [false,true]:
        for encounter in ["shell","reserve"]:
            if OS.get_cmdline_user_args().has("solo-shell") and not (solo_mode and encounter == "shell"): continue
            single = solo_mode
            heavy_inputs = encounter == "reserve"
            lobby.get_node("SoloCombatPreview" if single else "CombatPreview").pressed.emit()
            await frames(2)
            b = lobby.arena.battle
            b.story_encounter = encounter
            check(b.phase == "briefing" and b.wave == 0 and b.confirmed == [false,false],"fresh entry has no previous readiness "+encounter)
            if single and heavy_inputs:
                tap_key(KEY_TAB)
                tap_key(KEY_TAB)
            tap_key(KEY_E)
            if not single: tap_key(KEY_SPACE)
            await frames(2)
            check(lobby.arena.status_label.text.contains("1 / 2"),"named encounter HUD shows its actual two-wave budget")
            var driver = Driver.new(self,b)
            var cursor := 0
            var heavy_hits := 0
            var interrupted := 0
            var wave_waits := 0
            var paused_combat := false
            for frame in range(15000):
                if b.phase == "clear": break
                if frame in [600,1200,1800] and OS.get_cmdline_user_args().has("solo-shell"):
                    print("SHELL_DEBUG ",frame," wave=",b.wave," positions=",b.positions," enemies=",b.enemies," ai=",lobby.arena.solo.companion.status," engagement=",lobby.arena.solo.engagement," guarding=",b.guarding)
                if not paused_combat and frame >= 90:
                    drive(0,Vector2.ZERO)
                    if not single: drive(1,Vector2.ZERO)
                    tap_key(KEY_ESCAPE)
                    var paused: Array = b.positions.duplicate()
                    var phase: String = b.phase
                    await frames(8)
                    check(b.positions == paused and b.phase == phase,"actual Escape freezes live encounter")
                    tap_key(KEY_ENTER)
                    paused_combat = true
                if b.phase == "intermission":
                    wave_waits += 1
                    drive(0,Vector2.ZERO)
                    if not single: drive(1,Vector2.ZERO)
                    key_event(KEY_F,false)
                    key_event(KEY_J,false)
                    key_event(KEY_G,false)
                    var completed_wave: int = b.wave
                    var health: Array = b.hp.duplicate()
                    await frames(110)
                    check(b.wave == completed_wave and b.phase == "intermission" and (b.hp[0] == health[0] or health[0] == 0) and (b.hp[1] == health[1] or health[1] == 0),"live cleared wave stays put and preserves health until choice")
                    if b.hp[0] <= 0 or b.hp[1] <= 0:
                        for rescue_frame in range(1500):
                            if single: driver.step_slot(lobby.arena.solo.human_slot)
                            else: driver.step_slot(0)
                            if not single: driver.step_slot(1)
                            await frames(1)
                            if b.hp[0] > 0 and b.hp[1] > 0: break
                    if not single:
                        tap_key(KEY_E)
                        check(b.wave == completed_wave and b.confirmed[0],"first real key only readies one slot")
                        tap_key(KEY_ESCAPE)
                        await frames(3)
                        check(b.confirmed == [false,false] and b.wave == completed_wave,"pause clears pending dual ready without advancing wave")
                        tap_key(KEY_ENTER)
                        tap_key(KEY_SPACE)
                        check(b.wave == completed_wave,"resuming does not reuse stale first-player ready")
                    tap_key(KEY_E)
                    check(b.wave == completed_wave+1,"deliberate real-key readiness opens exactly one next wave")
                    continue
                if single:
                    driver.step_slot(lobby.arena.solo.human_slot)
                else:
                    driver.step_slot(0)
                    driver.step_slot(1)
                    if heavy_inputs and b.current_cat == 1 and b.enemies.any(func(e): return e.get("mark_time",0.0)>0): tap_key(KEY_TAB)
                if b.current_cat == 2:
                    if b.attacks.charging and b.attacks.charge_time >= b.attacks.CHARGE_SECONDS-0.00001:
                        key_event(KEY_F if single else KEY_J,false)
                    elif not b.attacks.charging:
                        key_event(KEY_F if single else KEY_J,false)
                for event in b.feedback_since(cursor):
                    if event.kind == "heavy" and event.role == 2: heavy_hits += 1
                    if event.kind == "interrupt": interrupted += 1
                cursor = b.feedback_id
                await frames(1)
            drive(0,Vector2.ZERO)
            if not single: drive(1,Vector2.ZERO)
            key_event(KEY_F,false)
            key_event(KEY_J,false)
            key_event(KEY_G,false)
            check(b.phase == "clear" and b.wave == 2 and wave_waits == 1,"ordinary inputs clear both configured waves %s solo=%s" % [encounter,single])
            if heavy_inputs: check(heavy_hits > 0,"reserve route executes real held-and-released heavy attacks")
            print("M27_ENCOUNTER_INPUT_RESULT ",JSON.stringify({"encounter":encounter,"solo":single,"hp":b.hp,"retries":b.retries,"heavy_hits":heavy_hits,"interrupts":interrupted,"shield_openings":driver.shield_openings,"stump_openings":driver.stump_openings,"phase":b.phase}))
            tap_key(KEY_ESCAPE)
            await frames(2)
    lobby.queue_free()
    await frames(2)
    print("M27_ENCOUNTER_INPUT: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
