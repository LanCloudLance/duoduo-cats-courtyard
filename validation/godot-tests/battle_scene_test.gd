extends "res://tests/keyboard_scene_test.gd"
# Integration fixtures position actors/enemies to isolate inputs, health, rescue
# and stage transitions. They are not a measurement of human combat difficulty.
func run() -> void:
    Engine.time_scale = 4
    lobby = load("res://main.tscn").instantiate()
    root.add_child(lobby)
    await frames(2)
    lobby.session.set_focus(true)
    tap_key(KEY_ENTER)
    await frames(2)
    world = lobby.courtyard
    world.bridge.unlocked = 3
    world.bridge.finished = true
    world.party.positions[0] = world.Bridge.EXIT
    tap_key(KEY_E)
    await frames(2)
    var arena = lobby.arena
    var b = arena.battle
    check(lobby.stage == "combat" and arena.visible and not world.visible, "finished bridge enters arena through interaction")
    check(b.phase == "briefing" and not b.confirmed[0], "transition input is not reused as combat confirmation")
    tap_key(KEY_E)
    tap_key(KEY_SPACE)
    check(b.wave == 1, "keyboard confirmations start first combat wave")
    key_event(KEY_G, true)
    check(b.guarding, "holding G raises shield")
    key_event(KEY_G, false)
    check(not b.guarding, "releasing G lowers shield")
    for enemy in b.enemies:
        enemy.mode = "rest"
        enemy.timer = 100.0
    b.enemies[0].mode = "rest"
    b.enemies[0].timer = 100.0
    b.positions[0] = b.enemies[0].pos + Vector2(-70, 0)
    tap_key(KEY_F)
    await frames(2)
    check(b.enemies[0].hp == 4, "F attacks through production keyboard router")
    b.positions[b.current_cat] = b.enemies[0].pos + Vector2(0, 70)
    key_event(KEY_UP,true)
    await frames(1)
    key_event(KEY_UP,false)
    tap_key(KEY_J)
    await frames(2)
    check(b.enemies[0].hp == 3, "J independently scratches as P2")
    tap_key(KEY_Q)
    tap_key(KEY_K)
    check(b.dodge_time[0] > 0 and b.dodge_time[1] > 0, "both keyboard dodge bindings work")
    await frames(6)
    key_event(KEY_G, true)
    tap_key(KEY_ESCAPE)
    var saved: Array = b.positions.duplicate()
    var timer: float = b.enemies[0].timer
    await frames(3)
    check(not arena.visible and not b.guarding and b.positions == saved and b.enemies[0].timer == timer, "pause clears shield and freezes combat")
    tap_key(KEY_ENTER)
    await frames(2)
    check(arena.visible and not b.guarding, "resume cannot leave shield stuck on")
    b.hp[1] = 1
    tap_key(KEY_TAB)
    check(b.current_cat == 2 and b.hp[1] == 1, "Tab switches white cat without refreshing health")
    b.hp[0] = 0
    b.positions[0] = Vector2(400, 450)
    b.positions[b.current_cat] = Vector2(450, 450)
    tap_key(KEY_SPACE)
    await frames(22)
    check(b.hp[0] == 2, "cat rescues girl through real interaction and elapsed simulation")
    b.hp[1] = 0
    tap_key(KEY_E)
    await frames(22)
    check(b.hp[1] == 2, "girl can rescue either active cat")
    # Finish enemies using real attack events, with stationary test opponents.
    for wave_number in [1, 2, 3]:
        var opponents: Array = b.enemies.duplicate()
        for enemy in opponents:
            enemy.mode = "exposed" if enemy.kind == "armored" else "rest"
            enemy.timer = 100.0
        for enemy in opponents:
            b.positions[0] = enemy.pos + Vector2(70 if enemy.kind == "armored" else -70, 0)
            var face_key := KEY_A if enemy.kind == "armored" else KEY_D
            key_event(face_key,true)
            await frames(1)
            key_event(face_key,false)
            for hit in range(80):
                if enemy.hp <= 0: break
                for frozen in opponents:
                    frozen.mode = "exposed" if frozen.kind == "armored" else "rest"
                    frozen.timer = 100.0
                b.positions[0] = enemy.pos + Vector2(70 if enemy.kind == "armored" else -70,0)
                await frames(9)
                tap_key(KEY_F)
                await frames(3)
        if wave_number < 3:
            for wait_frame in range(80):
                if b.wave == wave_number+1: break
                await frames(1)
            check(b.wave == wave_number+1 and b.phase == "combat", "cleared round automatically begins the next encounter")
            tap_key(KEY_E)
            tap_key(KEY_SPACE)
            check(b.wave == wave_number+1, "extra confirmations cannot skip a combat wave")
    await frames(2)
    check(b.phase == "clear", "attacks can defeat all three rounds and unlock camp")
    b.positions[0] = b.EXIT + Vector2(-35, 0)
    b.positions[b.current_cat] = b.EXIT + Vector2(35, 0)
    tap_key(KEY_E)
    tap_key(KEY_SPACE)
    await frames(2)
    check(b.phase == "complete" and arena.objective_label.text.contains("完成"), "both players confirm complete state at camp")
    check(world.bridge.unlocked == 3 and world.bridge.finished, "combat leaves solved bridge intact")
    tap_key(KEY_ESCAPE)
    await frames(2)
    lobby.get_node("ReplayCourtyard").pressed.emit()
    check(arena.battle.phase == "briefing" and arena.battle.hp == [3, 3] and world.bridge.finished, "replay resets only current combat level")
    # Same production path with synthetic controllers, including button release.
    lobby.router.use_gamepads()
    for device in [9, 18, 9, 18]:
        button(device, JOY_BUTTON_START)
    await frames(2)
    b = arena.battle
    button(9, JOY_BUTTON_A)
    button(18, JOY_BUTTON_A)
    check(b.wave == 1 and not lobby.session.keyboard_mode, "dual controller inputs start arena independently")
    var shield := InputEventJoypadButton.new()
    shield.device = 9
    shield.button_index = JOY_BUTTON_LEFT_SHOULDER
    shield.pressed = true
    Input.parse_input_event(shield)
    Input.flush_buffered_events()
    check(b.guarding, "controller left shoulder holds shield")
    shield = shield.duplicate()
    shield.pressed = false
    Input.parse_input_event(shield)
    Input.flush_buffered_events()
    check(not b.guarding, "controller release lowers shield")
    shield = shield.duplicate()
    shield.pressed = true
    Input.parse_input_event(shield)
    Input.flush_buffered_events()
    lobby.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
    await frames(2)
    check(not b.guarding and not lobby.session.running() and not arena.visible, "focus loss pauses controller combat and clears shield")
    lobby.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN)
    lobby.session.release_slot(0)
    lobby.session.release_slot(1)
    lobby.get_node("CombatPreview").pressed.emit()
    await frames(2)
    check(lobby.stage == "combat" and arena.visible and lobby.session.keyboard_mode and lobby.session.running(), "no-controller menu shortcut opens playable combat")
    print("BATTLE_SCENE: %d checks, %d failed" % [checks, failed])
    quit(1 if failed else 0)
