extends "res://tests/bridge_scene_test.gd"

func key_event(code: int, down: bool) -> void:
    var event := InputEventKey.new()
    event.physical_keycode = code as Key
    event.pressed = down
    Input.parse_input_event(event)
    Input.flush_buffered_events()

func tap_key(code: int) -> void:
    key_event(code, true)
    key_event(code, false)

func axes(device: int, vector: Vector2) -> void:
    var codes: Array = [KEY_A, KEY_D, KEY_W, KEY_S] if device == 9 else [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]
    var states := [vector.x < -0.1, vector.x > 0.1, vector.y < -0.1, vector.y > 0.1]
    for i in range(4):
        key_event(codes[i], states[i])

func walk(slot: int, target: Vector2) -> bool:
    var device := 9 if slot == 0 else 18
    for frame in range(600):
        var actor: int = 0 if slot == 0 else world.party.current_cat
        var offset: Vector2 = target - world.party.positions[actor]
        if offset.length() < 6:
            axes(device, Vector2.ZERO)
            return true
        axes(device, offset)
        await frames(1)
    axes(device, Vector2.ZERO)
    return false

func run() -> void:
    lobby = load("res://main.tscn").instantiate()
    root.add_child(lobby)
    await frames(2)
    world = lobby.get_node("Courtyard")
    lobby.session.set_focus(true)
    tap_key(KEY_ENTER)
    await frames(3)
    check(world.visible and lobby.session.keyboard_mode, "Enter enters real courtyard without controllers")
    check(world.get("p1_help") != null, "courtyard exposes mode-aware keyboard help")
    if world.get("p1_help") != null:
        check(world.p1_help.text.contains("WASD"), "HUD shows keyboard movement")
    check(await walk(0, Vector2(960, 620)), "WASD reaches winch")
    tap_key(KEY_E)
    check(world.bridge.deployed == 1, "E operates girl winch")
    for stage in range(3):
        if stage > 0:
            tap_key(KEY_E)
        check(await walk(1, Vector2(1132 + 120 * stage, 640)), "arrow keys traverse platform")
        tap_key(KEY_SPACE)
        check(world.bridge.unlocked == stage + 1, "Space opens cat latch")
    check(await walk(0, Vector2(1480, 640)), "girl crosses bridge on keyboard")
    check(await walk(1, Vector2(1560, 640)), "cat reaches exit on keyboard")
    await frames(100)
    tap_key(KEY_E)
    tap_key(KEY_SPACE)
    check(world.bridge.finished, "keyboard alone can complete cooperative stage")
    key_event(KEY_D, true)
    lobby.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
    var saved: Array = world.party.positions.duplicate()
    await frames(4)
    check(world.party.positions == saved and not world.visible, "focus loss freezes keyboard scene")
    lobby.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN)
    tap_key(KEY_ENTER)
    await frames(4)
    check(world.party.positions[0] == saved[0], "focus resume clears held movement key")
    tap_key(KEY_ESCAPE)
    await frames(3)
    check(not world.visible, "Escape returns to preparation screen")
    lobby.router.use_gamepads()
    await frames(2)
    check(not lobby.session.keyboard_mode and not lobby.session.running(), "can return to controller mode safely")
    print("KEYBOARD_SCENE: %d checks, %d failed" % [checks, failed])
    quit(1 if failed else 0)
