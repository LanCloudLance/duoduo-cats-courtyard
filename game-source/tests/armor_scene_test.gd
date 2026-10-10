extends "res://tests/keyboard_scene_test.gd"
# Explicit setup fixtures isolate both openings, then use production input/events
# and enemy simulation. battle_playthrough_test covers the unmodified start.
var b
func run() -> void:
    lobby = load("res://main.tscn").instantiate()
    root.add_child(lobby)
    await frames(2)
    lobby.session.set_focus(true)
    lobby.get_node("CombatPreview").pressed.emit()
    await frames(2)
    b = lobby.arena.battle
    b._start_wave(2)
    b.enemies.resize(1)
    var e = b.enemies[0]
    e.pos = Vector2(720,320)
    e.timer = 0.0
    b.positions[0] = Vector2(800,320)
    b.positions[1] = Vector2(650,320)
    await frames(2)
    check(e.mode == "windup" and e.direction.x < -0.9,"cat position lures real charge toward stump")
    key_event(KEY_DOWN,true)
    tap_key(KEY_K)
    await frames(16)
    key_event(KEY_DOWN,false)
    for i in range(180):
        if e.mode == "exposed": break
        await frames(1)
    check(e.mode == "exposed" and e.opening == "stump" and b.hp[1] == 3,"cat side dodge causes real stump opening")
    key_event(KEY_A,true)
    for i in range(80):
        if b.positions[0].distance_to(e.pos) < 85: break
        await frames(1)
    key_event(KEY_A,false)
    for i in range(180):
        if e.hp <= 0: break
        if b.attack_cooldown[0] <= 0: tap_key(KEY_F)
        await frames(1)
    check(e.hp == 0,"girl defeats stump-exposed knot through normal attack events")
    await frames(4)
    check(b.phase == "intermission" and b.wave == 2,"clearing isolated armor offers brief recovery")
    for i in range(240):
        if b.wave == 3: break
        await frames(1)
    tap_key(KEY_E)
    check(b.wave == 2 and b.confirmed[0],"one ready input after recovery waits for partner")
    tap_key(KEY_SPACE)
    check(b.wave == 3,"partner confirmation starts the next wave exactly once")
    # Actual shield contact followed by event-driven pause and resume.
    b._start_wave(2)
    b.enemies.resize(1)
    e = b.enemies[0]
    e.pos = Vector2(600,440)
    e.timer = 0.0
    b.positions[0] = Vector2(420,440)
    b.positions[1] = Vector2(850,440)
    key_event(KEY_D,true)
    await frames(1)
    key_event(KEY_D,false)
    key_event(KEY_G,true)
    for i in range(180):
        if e.mode == "exposed": break
        await frames(1)
    check(e.mode == "exposed" and e.opening == "shield","G produces physical shield opening")
    tap_key(KEY_ESCAPE)
    var remaining: float = e.timer
    await frames(12)
    check(e.timer == remaining and not b.guarding,"pause freezes opening and clears held shield")
    tap_key(KEY_ENTER)
    await frames(3)
    check(e.timer < remaining and not b.guarding,"resume continues opening without stuck shield")
    print("ARMOR_SCENE: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
