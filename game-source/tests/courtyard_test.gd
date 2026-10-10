extends SceneTree
var checked: int = 0
var failed: int = 0

func check(value: bool, label: String) -> void:
    checked += 1
    if not value:
        failed += 1
        push_error("FAIL: " + label)

func button(device: int, code: int) -> void:
    var event := InputEventJoypadButton.new()
    event.device = device
    event.button_index = code as JoyButton
    event.pressed = true
    Input.parse_input_event(event)
    event = event.duplicate()
    event.pressed = false
    Input.parse_input_event(event)
    Input.flush_buffered_events()

func axis(device: int, value: float) -> void:
    var event := InputEventJoypadMotion.new()
    event.device = device
    event.axis = JOY_AXIS_LEFT_X
    event.axis_value = value
    Input.parse_input_event(event)
    Input.flush_buffered_events()

func frames(count: int) -> void:
    for i in range(count):
        await physics_frame
        await process_frame

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var lobby = load("res://main.tscn").instantiate()
    root.add_child(lobby)
    await frames(2)
    var world = lobby.get_node_or_null("Courtyard")
    check(world != null, "lobby owns persistent courtyard")
    if world == null:
        print("COURTYARD: %d checks, %d failed" % [checked, failed])
        quit(1)
        return
    check(not world.visible, "courtyard waits for both players")
    lobby.session.set_focus(true)
    for device in [9, 18, 9, 18]:
        button(device, JOY_BUTTON_START)
    await frames(3)
    check(world.visible and world.camera.enabled and not lobby.top_status.visible, "ready enters courtyard and switches camera")
    var girl_before: Vector2 = world.party.positions[0]
    axis(9, 1.0)
    await frames(25)
    axis(9, 0.0)
    check(world.party.positions[0].x > girl_before.x + 40, "engine events move P1 in live scene")
    button(9, JOY_BUTTON_Y)
    check(world.party.current_cat == 1, "P1 cannot switch P2 cat")
    var cat_before: Vector2 = world.party.positions[2]
    button(18, JOY_BUTTON_Y)
    check(world.party.current_cat == 2 and world.party.positions[2] == cat_before, "P2 button switches without teleport")
    await frames(3)
    check(world.cat_label.text.contains("圆圆"), "HUD identifies controlled white cat")
    world.party.positions[2] = Vector2(540, 700)
    button(18, JOY_BUTTON_RIGHT_SHOULDER)
    button(18, JOY_BUTTON_Y)
    await frames(10)
    check(world.party.holding[2] and world.party.positions[2] == Vector2(540, 700), "shoulder hold survives switching")
    var snapshot: Array = world.party.positions.duplicate()
    button(9, JOY_BUTTON_START)
    await frames(5)
    check(not world.visible and not world.camera.enabled and lobby.top_status.visible, "pause restores preparation interface")
    check(world.party.positions == snapshot, "pause freezes all party positions")
    button(9, JOY_BUTTON_START)
    button(18, JOY_BUTTON_START)
    await frames(3)
    check(world.visible and world.party.positions == snapshot, "both ready resume same held party")
    lobby._connection_changed(18, false)
    await frames(3)
    check(not world.visible and not lobby.session.running(), "disconnect freezes courtyard")
    button(21, JOY_BUTTON_START)
    button(9, JOY_BUTTON_START)
    button(21, JOY_BUTTON_START)
    await frames(3)
    check(world.visible and lobby.session.slot_of(21) == 1, "replacement controller resumes P2")
    lobby.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
    await frames(3)
    snapshot = world.party.positions.duplicate()
    axis(9, 1.0)
    button(21, JOY_BUTTON_Y)
    await frames(3)
    check(world.party.positions == snapshot and not world.visible, "focus loss blocks movement and switches")
    lobby.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN)
    button(9, JOY_BUTTON_START)
    button(21, JOY_BUTTON_START)
    await frames(15)
    axis(9, -1.0)
    axis(21, 1.0)
    await frames(35)
    axis(9, 0.0)
    axis(21, 0.0)
    await frames(25)
    var on_screen := true
    for actor in world.actors:
        var point: Vector2 = actor.get_global_transform_with_canvas().origin
        on_screen = on_screen and Rect2(64, 224, 1152, 450).has_point(point)
    check(on_screen, "rendered camera keeps all actors between HUD panels")
    var args := OS.get_cmdline_user_args()
    if args.size() > 0 and DisplayServer.get_name() != "headless":
        await RenderingServer.frame_post_draw
        check(root.get_texture().get_image().save_png(args[0]) == OK, "live courtyard screenshot saved")
    print("COURTYARD: %d checks, %d failed" % [checked, failed])
    quit(1 if failed else 0)
