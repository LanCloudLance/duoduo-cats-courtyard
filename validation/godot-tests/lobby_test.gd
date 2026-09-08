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
    var release := event.duplicate()
    release.pressed = false
    Input.parse_input_event(release)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var scene = load("res://main.tscn").instantiate()
    root.add_child(scene)
    await process_frame
    await process_frame
    scene.session.set_focus(true)
    check(scene.ready_text[0].text == "等待加入", "empty slot visible")
    var art: TextureRect
    for child in scene.get_children():
        if child is TextureRect:
            art = child
    check(art != null and Rect2(59,234,513,231).encloses(art.get_rect()), "team art stays inside left panel")
    button(9, JOY_BUTTON_START)
    button(18, JOY_BUTTON_START)
    button(9, JOY_BUTTON_START)
    button(18, JOY_BUTTON_START)
    await process_frame
    await process_frame
    check(scene.session.running(), "engine input reaches lobby session")
    check(scene.ready_text[0].text.begins_with("已准备") and scene.ready_text[1].text.begins_with("已准备"), "both ready states rendered")
    button(18, JOY_BUTTON_Y)
    var motion := InputEventJoypadMotion.new()
    motion.device = 9
    motion.axis = JOY_AXIS_LEFT_X
    motion.axis_value = 1.0
    Input.parse_input_event(motion)
    await process_frame
    await process_frame
    check(scene.last_buttons == [-1, JOY_BUTTON_Y], "action display isolated")
    check(scene.sticks[0].value == Vector2.RIGHT and scene.sticks[1].value == Vector2.ZERO, "stick displays isolated")
    scene._connection_changed(9, false)
    await process_frame
    await process_frame
    check(scene.ready_text[0].text == "等待加入", "disconnect releases visible slot")
    check(scene.footer_status.text.contains("手柄断开"), "disconnect reason visible")
    check(scene.sticks[0].value == Vector2.ZERO, "disconnect clears visible input")
    # Leave screenshot in the actual initial state, without simulated devices.
    scene.session.release_slot(1)
    scene.session.pause_all("等待两位加入")
    scene.last_buttons[0] = -1
    scene.last_buttons[1] = -1
    await process_frame
    await process_frame
    var args := OS.get_cmdline_user_args()
    if args.size() > 0 and DisplayServer.get_name() != "headless":
        await RenderingServer.frame_post_draw
        var error := root.get_texture().get_image().save_png(args[0])
        check(error == OK, "actual viewport capture saved")
    print("LOBBY: %d checks, %d failed" % [checked, failed])
    quit(1 if failed else 0)
