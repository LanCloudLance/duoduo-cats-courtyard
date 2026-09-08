extends SceneTree
var checks := 0
var failed := 0
var lobby
var world

func check(value: bool, label: String) -> void:
    checks += 1
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

func axes(device: int, vector: Vector2) -> void:
    for dimension in range(2):
        var event := InputEventJoypadMotion.new()
        event.device = device
        event.axis = dimension as JoyAxis
        event.axis_value = vector[dimension]
        Input.parse_input_event(event)
    Input.flush_buffered_events()

func frames(count: int) -> void:
    for i in range(count):
        await physics_frame
        await process_frame

func walk(slot: int, target: Vector2) -> bool:
    var device: int = lobby.session.devices[slot]
    for frame in range(600):
        var actor: int = 0 if slot == 0 else world.party.current_cat
        var offset: Vector2 = target - world.party.positions[actor]
        if offset.length() < 6:
            axes(device, Vector2.ZERO)
            return true
        axes(device, offset.normalized())
        await frames(1)
    axes(device, Vector2.ZERO)
    push_error("Walk timed out at %s toward %s; running=%s, pause=%s" % [str(world.party.positions), str(target), str(lobby.session.running()), lobby.session.pause_reason])
    return false

func snapshot(suffix: String) -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() > 0 and DisplayServer.get_name() != "headless":
        await frames(20)
        await RenderingServer.frame_post_draw
        check(root.get_texture().get_image().save_png(args[0] + suffix + ".png") == OK, "rendered bridge screenshot saved")

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    lobby = load("res://main.tscn").instantiate()
    root.add_child(lobby)
    await frames(2)
    world = lobby.get_node("Courtyard")
    var bridge = world.get("bridge")
    check(bridge != null, "courtyard contains live cooperative bridge")
    if bridge == null:
        quit(1)
        return
    lobby.session.set_focus(true)
    for device in [9, 18, 9, 18]:
        button(device, JOY_BUTTON_START)
    await frames(3)
    check(await walk(0, Vector2(960, 620)), "P1 walks from spawn to winch")
    button(9, JOY_BUTTON_A)
    check(bridge.deployed == 1, "P1 real input deploys first platform")
    if bridge.deployed != 1:
        quit(1)
        return
    button(9, JOY_BUTTON_A)
    check(bridge.deployed == 1, "repeated input cannot skip cooperation")
    check(await walk(1, Vector2(1132, 640)), "P2 physically traverses first narrow platform")
    button(18, JOY_BUTTON_A)
    check(bridge.unlocked == 1, "P2 real input opens first latch")
    # Misstep through the same movement input used in play, then recover.
    axes(18, Vector2.UP)
    await frames(12)
    axes(18, Vector2.ZERO)
    check(bridge.falls == 1 and world.party.positions[1] == Vector2(1132, 640), "misstep returns cat and keeps first latch")
    button(18, JOY_BUTTON_Y)
    await frames(10)
    check(world.party.positions[1] == Vector2(1132, 640), "switching away leaves black cat safely waiting")
    button(18, JOY_BUTTON_Y)
    button(9, JOY_BUTTON_START)
    var saved: Array = world.party.positions.duplicate()
    await frames(5)
    check(not world.visible and bridge.unlocked == 1 and world.party.positions == saved, "pause preserves bridge and party")
    button(9, JOY_BUTTON_START)
    button(18, JOY_BUTTON_START)
    await frames(5)
    check(world.visible and bridge.unlocked == 1, "resume keeps solved latch")
    for i in [1, 2]:
        button(9, JOY_BUTTON_A)
        check(bridge.deployed == i + 1, "next platform needs P1 input")
        check(await walk(1, Vector2(1132 + 120 * i, 640)), "P2 reaches next latch by movement")
        if i == 1:
            await snapshot("-working")
        button(18, JOY_BUTTON_A)
        check(bridge.unlocked == i + 1, "next latch needs P2 input")
    check(await walk(0, Vector2(1480, 640)), "girl can cross permanent bridge")
    check(await walk(1, Vector2(1560, 640)), "black cat reaches gathering circle")
    await frames(100)
    check(world.party.positions[2].x > 1416, "white cat follows over permanent bridge")
    button(9, JOY_BUTTON_A)
    check(not bridge.finished, "one player cannot finish alone")
    button(18, JOY_BUTTON_A)
    await frames(3)
    check(bridge.finished and world.objective_label.text.contains("完成"), "both confirmations and whole party finish stage")
    await snapshot("-complete")
    button(9, JOY_BUTTON_START)
    await frames(3)
    var replay: Button = lobby.get_node_or_null("ReplayCourtyard")
    check(replay != null and replay.visible, "pause exposes replay control")
    if replay:
        replay.pressed.emit()
        check(world.bridge.unlocked == 0 and not world.bridge.finished, "replay resets completed mechanism")
        check(world.party.positions[0] == Vector2(400, 600) and lobby.session.devices == [9, 18], "replay restores spawn and keeps player bindings")
    print("BRIDGE_SCENE: %d checks, %d failed" % [checks, failed])
    quit(1 if failed else 0)
