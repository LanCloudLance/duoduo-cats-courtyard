extends "res://tests/render_battle_preview.gd"
# Frozen scene fixtures for legibility, menu navigation and viewport QA only.
func run() -> void:
    var args := OS.get_cmdline_user_args()
    if args.is_empty() or DisplayServer.get_name() == "headless": quit(1); return
    var lobby = load("res://main.tscn").instantiate()
    root.add_child(lobby)
    await process_frame
    lobby.session.set_focus(true)
    lobby._process(0)
    await capture(args[0],"-menu")
    lobby.start_courtyard(true)
    lobby._process(0)
    lobby.set_process(false)
    lobby.courtyard.set_physics_process(false)
    lobby.courtyard._physics_process(0)
    await capture(args[0],"-bridge")
    lobby.enter_light()
    lobby._process(0)
    var light = lobby.light_corridor
    light.set_physics_process(false)
    light.puzzle.lit = true
    light.puzzle.source = "near"
    light.puzzle.positions[2] = light.Map.LAMP_NEAR
    light.puzzle.positions[0] = light.Map.GUIDE_NEAR
    light.puzzle.positions[1] = Vector2(330,440)
    light.puzzle.operator_slot = 0
    light.puzzle.beam = Vector2(330,440)
    light.puzzle.park_traveler(1)
    light.puzzle.beam = Vector2(380,390)
    light._physics_process(0)
    await capture(args[0],"-light")
    root.size = Vector2i(1280,720)
    await capture(args[0],"-light-16x9")
    root.size = Vector2i(1280,800)
    lobby.enter_rest()
    lobby._process(0)
    lobby.rest_area.set_physics_process(false)
    lobby.rest_area._physics_process(0)
    await capture(args[0],"-rest")
    lobby.session.pause_all()
    lobby._process(0)
    await capture(args[0],"-solo-menu")
    print("JOURNEY_RENDER: 6 captures, %d failures" % failures)
    quit(1 if failures else 0)
