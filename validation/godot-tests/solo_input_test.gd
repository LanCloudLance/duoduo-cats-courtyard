extends "res://tests/keyboard_scene_test.gd"
func run() -> void:
    lobby = load("res://main.tscn").instantiate()
    root.add_child(lobby)
    await frames(2)
    lobby.session.set_focus(true)
    check(lobby.has_node("SoloCombatPreview"),"menu exposes explicitly bounded solo combat preview")
    if failed: finish(); return
    lobby.get_node("SoloCombatPreview").pressed.emit()
    await frames(2)
    var a = lobby.arena
    var b = a.battle
    check(lobby.session.single_player and lobby.session.running() and not lobby.session.ready_flags[1],"solo keyboard starts without fake second readiness")
    var before: Vector2 = b.positions[0]
    key_event(KEY_D,true)
    await frames(3)
    tap_key(KEY_TAB)
    var cat_before: Vector2 = b.positions[1]
    await frames(3)
    check(b.positions[1] == cat_before and a.solo.human_slot == 1,"Tab cancels held movement instead of moving next actor")
    key_event(KEY_D,false)
    key_event(KEY_W,true)
    await frames(3)
    key_event(KEY_W,false)
    check(b.positions[1].y < cat_before.y and before != b.positions[0],"same WASD moves girl then cat")
    tap_key(KEY_TAB)
    check(b.current_cat == 2,"next Tab selects white cat")
    key_event(KEY_F,true)
    await frames(40)
    check(b.attacks.charging,"solo F can hold white charge")
    key_event(KEY_F,false)
    check(not b.attacks.charging and b.attacks.kinds[1] == "heavy","solo F release performs white heavy")
    var cooldown: float = b.attack_cooldown[1]
    tap_key(KEY_TAB)
    check(a.solo.human_slot == 0 and is_equal_approx(cooldown,b.attack_cooldown[1]),"rotation preserves cat recovery")
    tap_key(KEY_E)
    check(b.wave == 1,"one E starts combat")
    tap_key(KEY_ESCAPE)
    await frames(2)
    var paused: Array = b.positions.duplicate()
    var timer: float = b.enemies[0].timer
    await frames(5)
    check(b.positions == paused and b.enemies[0].timer == timer,"pause freezes AI and enemies together")
    tap_key(KEY_ENTER)
    await frames(2)
    check(lobby.session.running() and lobby.session.single_player,"Enter resumes same solo mode")
    # One synthetic controller and normal button release.
    tap_key(KEY_ESCAPE)
    lobby.router.use_gamepads()
    button(9,JOY_BUTTON_START)
    button(9,JOY_BUTTON_START)
    await frames(2)
    check(lobby.session.running() and lobby.session.devices[1] == -1,"one pad resumes solo scene")
    button(9,JOY_BUTTON_Y)
    check(a.solo.human_slot == 1,"single pad Y controls cat")
    button(9,JOY_BUTTON_Y)
    var target: Dictionary = b.enemies[0]
    target.pos = b.positions[2]+Vector2(60,0)
    target.hp = 10
    target.mode = "rest"
    target.timer = 100
    # Release semantics need a quiet contact fixture, rather than a live caster
    # interrupting the charge. Continuous journeys still retain every enemy.
    b.enemies.resize(1)
    b.hazards.clear()
    await frames(60)
    # Isolate controller release damage from the companion's valid attacks.
    b.positions[0] = Vector2(1050,260)
    target.pos = b.positions[2]+b.facing[1]*60
    var attack := InputEventJoypadButton.new()
    attack.device = 9
    attack.button_index = JOY_BUTTON_X
    attack.pressed = true
    Input.parse_input_event(attack)
    Input.flush_buffered_events()
    await frames(40)
    check(b.attacks.charging and target.hp == 10,"single pad holds white charge without premature hit")
    attack = attack.duplicate()
    attack.pressed = false
    Input.parse_input_event(attack)
    Input.flush_buffered_events()
    await frames(9)
    check(target.hp == 8,"single pad release damages target with white heavy")
    lobby._connection_changed(9,false)
    await frames(2)
    check(not lobby.session.running() and not b.attacks.charging,"disconnect pauses solo and clears pending attacks")
    # A solo victory must not flow into unadapted puzzles or create a save.
    tap_key(KEY_ENTER)
    b.phase = "complete"
    tap_key(KEY_E)
    check(lobby.stage == "combat" and lobby.preview_run and not lobby.rest_area.can_save,"solo completion stays in preview and cannot write journey checkpoint")
    tap_key(KEY_ESCAPE)
    lobby.get_node("CombatPreview").pressed.emit()
    await frames(2)
    check(not lobby.session.single_player and not a.battle.solo_mode,"dual combat entry restores dual session and battle rules")
    finish()
func finish() -> void:
    print("SOLO_INPUT: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
