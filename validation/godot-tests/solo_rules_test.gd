extends SceneTree
const Session = preload("res://input/session_state.gd")
const Battle = preload("res://game/battle_state.gd")
var checks := 0
var failed := 0
func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failed += 1
        push_error("FAIL: "+label)
func _initialize() -> void:
    var s = Session.new()
    check(s.get("single_player") != null,"session supports explicit single player mode")
    if failed: finish(); return
    s.single_player = true
    s.menu(9)
    check(not s.running(),"one pad claims before it readies")
    s.menu(9)
    check(s.running() and s.devices[1] == -1 and not s.ready_flags[1],"one real controller readies without fake second player")
    s.menu(18)
    check(s.devices[1] == -1 and s.running(),"second controller cannot join an active solo battle")
    s.disconnect_device(9)
    check(not s.running(),"single controller disconnect pauses")
    s.menu(9)
    s.menu(9)
    check(s.running(),"one controller can reconnect and resume")
    s.set_focus(false)
    check(not s.running(),"solo also freezes on focus loss")
    s = Session.new()
    s.single_player = true
    s.keyboard_mode = true
    s.ready_flags[0] = true
    check(s.running() and not s.ready_flags[1],"one keyboard readiness suffices in solo")
    var b = Battle.new()
    check(b.get("solo_mode") != null,"battle has solo-specific readiness and pacing")
    if failed: finish(); return
    b.solo_mode = true
    b.interact(0)
    check(b.wave == 1 and b.phase == "combat","one confirmation starts solo combat")
    for enemy in b.enemies: enemy.hp = 0
    for i in range(200): b.step(1.0/60,Vector2.ZERO,Vector2.ZERO,true)
    check(b.phase == "combat" and b.wave == 2,"solo pacing advances without fake AI confirmations")
    b.interact(1)
    check(b.wave == 2,"cat interaction cannot skip active encounter")
    var e: Dictionary = b.enemies[0]
    b._expose(e,"shield")
    check(e.timer > 2.4,"solo widens the same shield opportunity")
    b._start_wave(3)
    e = b.enemies[0]
    e.mode = "exposed"
    e.timer = 2
    b.enemies[1].pos = b.positions[0]+Vector2(100,0)
    b.enemies[1].timer = 0
    b.step(0.05,Vector2.ZERO,Vector2.ZERO,true)
    check(b.enemies[1].mode == "approach","solo does not overlap new charge with armored opening")
    b.phase = "clear"
    b.positions[0] = b.EXIT
    b.interact(0)
    check(b.phase == "clear","solo completion still requires companion to arrive")
    b.positions[b.current_cat] = b.EXIT+Vector2(50,0)
    b.interact(0)
    check(b.phase == "complete","one player completes after both battle actors arrive")
    finish()
func finish() -> void:
    print("SOLO_RULES: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
