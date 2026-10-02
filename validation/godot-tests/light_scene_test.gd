extends "res://tests/keyboard_scene_test.gd"
const Map = preload("res://game/light_layout.gd")
var s
var pad_mode := false
func drive(slot: int, vector: Vector2) -> void:
    if not pad_mode:
        axes(9 if slot == 0 else 18,vector)
        return
    for dimension in range(2):
        var event := InputEventJoypadMotion.new()
        event.device = 9 if slot == 0 else 18
        event.axis = dimension as JoyAxis
        event.axis_value = vector[dimension]
        Input.parse_input_event(event)
    Input.flush_buffered_events()
func direction(offset: Vector2) -> Vector2:
    return Vector2(0 if absf(offset.x)<4 else signf(offset.x),0 if absf(offset.y)<4 else signf(offset.y))
func walk(slot: int, target: Vector2) -> bool:
    for i in range(800):
        var offset: Vector2 = target-s.positions[s.actor(slot)]
        if offset.length()<8:
            drive(slot,Vector2.ZERO)
            return true
        drive(slot,direction(offset))
        await frames(1)
    drive(slot,Vector2.ZERO)
    push_error("M7 walk timeout: %s -> %s phase=%s operator=%s" % [s.positions,target,s.phase,s.operator_slot])
    return false
func aim(target: Vector2) -> bool:
    var slot: int = s.operator_slot
    for i in range(500):
        var offset: Vector2 = target-s.beam
        if offset.length()<8:
            drive(slot,Vector2.ZERO)
            return true
        drive(slot,direction(offset))
        await frames(1)
    drive(slot,Vector2.ZERO)
    return false
func guide_walk(slot: int, target: Vector2) -> bool:
    var operator_id := 1-slot
    for i in range(900):
        var point: Vector2 = s.positions[s.actor(slot)]
        var offset := target-point
        if offset.length()<8:
            drive(slot,Vector2.ZERO)
            drive(operator_id,Vector2.ZERO)
            return true
        drive(operator_id,direction(point+offset.normalized()*22-s.beam))
        drive(slot,direction(offset))
        await frames(1)
    drive(slot,Vector2.ZERO)
    drive(operator_id,Vector2.ZERO)
    push_error("M7 guide timeout: %s -> %s phase=%s beam=%s recoveries=%s" % [s.positions,target,s.phase,s.beam,s.recoveries])
    return false
func crossing(slot: int, points: Array) -> bool:
    for point in points:
        if not await guide_walk(slot,point): return false
    return true
func launch() -> void:
    lobby = load("res://main.tscn").instantiate()
    root.add_child(lobby)
    await frames(2)
    lobby.session.set_focus(true)
    lobby.get_node("LightPreview").pressed.emit()
    await frames(2)
    world = lobby.light_corridor
    s = world.puzzle
func first_half() -> bool:
    if s.current_cat != 2: tap_key(KEY_TAB)
    if not await walk(1,Vector2(140,550)): return false
    tap_key(KEY_R)
    tap_key(KEY_TAB)
    if not await walk(0,Vector2(210,350)): return false
    tap_key(KEY_E)
    if not await walk(1,Vector2(260,440)): return false
    if not await crossing(1,[Vector2(330,440),Vector2(410,355),Vector2(475,430),Vector2(600,430)]): return false
    if not await walk(1,Vector2(645,340)): return false
    tap_key(KEY_R)
    check(s.phase == "girl" and s.operator_slot == -1,"black opens wide girl crossing and hands over control")
    tap_key(KEY_R)
    if not await walk(0,Vector2(260,520)): return false
    if not await crossing(0,[Vector2(340,540),Vector2(440,540),Vector2(540,480),Vector2(605,480)]): return false
    if not await walk(0,Vector2(625,505)): return false
    tap_key(KEY_E)
    tap_key(KEY_E)
    check(s.front_fixed and s.phase == "route","girl fixes front bridge after actual assisted crossing")
    return true
func select_route(route: String) -> bool:
    if s.current_cat != 2: tap_key(KEY_TAB)
    if not await walk(1,Vector2(250,480)): return false
    if not await walk(1,Vector2(605,480)): return false
    if not await walk(1,Vector2(610,585) if route == "safe" else Vector2(710,585)): return false
    tap_key(KEY_R)
    tap_key(KEY_TAB)
    check(s.lit and s.route == route and s.current_cat == 1,"white relocation chooses branch through actual controls")
    if not await walk(0,Map.FRONT_LOCK): return false
    tap_key(KEY_E)
    if not await walk(0,Vector2(710,420)): return false
    tap_key(KEY_E)
    if not await walk(1,Vector2(740,380) if route == "safe" else Vector2(740,530)): return false
    return true
func finish_route(route: String) -> bool:
    var points: Array = [Vector2(820,320),Vector2(905,320),Vector2(985,355),Vector2(1080,380)] if route == "safe" else [Vector2(825,550),Vector2(900,475),Vector2(990,510),Vector2(1080,480)]
    if not await crossing(1,points): return false
    if not await walk(1,Vector2(1115,380)): return false
    tap_key(KEY_R)
    if not await walk(0,Vector2(705,500)): return false
    tap_key(KEY_E)
    check(s.permanent and s.latched,"cat latch and girl winch establish permanent far bridge")
    tap_key(KEY_TAB)
    if not await walk(1,Vector2(740,480)): return false
    if not await walk(1,Vector2(1110,480)): return false
    if not await walk(1,Vector2(1150,525)): return false
    if not await walk(0,Vector2(740,480)): return false
    if not await walk(0,Vector2(1100,480)): return false
    if not await walk(0,Vector2(1120,525)): return false
    await frames(60)
    tap_key(KEY_E)
    check(not s.finished,"both confirmations still required")
    tap_key(KEY_SPACE)
    await frames(4)
    return s.finished
func run() -> void:
    await launch()
    check(lobby.stage == "light" and lobby.preview_run,"preview opens new cooperative corridor without normal save authority")
    if not check_gate(await first_half(),"complete first two cooperative crossings"): return
    if not check_gate(await select_route("safe"),"select safe branch"): return
    # Pause during beam control while movement is held; clear-on-pause must stop it.
    drive(0,Vector2.RIGHT)
    tap_key(KEY_ESCAPE)
    var positions: Array = s.positions.duplicate()
    var beam: Vector2 = s.beam
    await frames(5)
    check(s.positions == positions and s.beam == beam and not world.visible,"pause freezes bodies and beam")
    tap_key(KEY_ENTER)
    await frames(5)
    check(s.beam == beam and s.positions == positions,"resume clears held aiming input")
    if not check_gate(await finish_route("safe"),"safe route completes from spawn using normal inputs"): return
    tap_key(KEY_E)
    await frames(3)
    check(lobby.stage == "rest" and not lobby.rest_area.can_save,"preview completion hands off to rest without replacing save")
    lobby.free()
    await frames(2)
    await launch()
    if not check_gate(await first_half(),"second run completes swapped roles"): return
    if not check_gate(await select_route("fast"),"select shortcut"): return
    if not check_gate(await finish_route("fast"),"shortcut completes from spawn using normal inputs"): return
    # New scene, real event router with synthetic gamepads. Not hardware validation.
    lobby.free()
    await frames(2)
    await launch()
    lobby.router.use_gamepads()
    pad_mode = true
    for device in [9,18,9,18]: button(device,JOY_BUTTON_START)
    button(18,JOY_BUTTON_Y)
    check(await walk(1,Vector2(140,550)),"gamepad axes move white to lamp")
    button(18,JOY_BUTTON_RIGHT_SHOULDER)
    button(18,JOY_BUTTON_Y)
    check(await walk(0,Vector2(210,350)),"gamepad moves girl to desk")
    button(9,JOY_BUTTON_A)
    positions = s.positions.duplicate()
    beam = s.beam
    drive(0,Vector2.RIGHT)
    await frames(6)
    drive(0,Vector2.ZERO)
    check(s.positions[0] == positions[0] and s.beam.x > beam.x,"controller aiming moves beam without moving girl")
    lobby.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
    beam = s.beam
    await frames(4)
    check(s.beam == beam and s.lit and not lobby.session.running(),"focus loss pauses aim and preserves light")
    lobby.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN)
    button(9,JOY_BUTTON_START)
    button(18,JOY_BUTTON_START)
    lobby._connection_changed(18,false)
    await frames(3)
    check(not lobby.session.running() and s.lit,"disconnect freezes new puzzle")
    print("LIGHT_SCENE: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
func check_gate(value: bool,label: String) -> bool:
    check(value,label)
    if not value:
        print("LIGHT_SCENE: %d checks, %d failed" % [checks,failed])
        quit(1)
    return value
