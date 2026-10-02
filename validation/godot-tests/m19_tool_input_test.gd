extends "res://tests/keyboard_scene_test.gd"
const Map = preload("res://game/light_layout.gd")
func run() -> void:
    lobby = load("res://main.tscn").instantiate()
    root.add_child(lobby)
    await frames(2)
    lobby.session.set_focus(true)
    lobby.start_trial("light",false)
    await frames(2)
    var light = lobby.light_corridor
    var p = light.puzzle
    p.phase = "girl"
    p.positions[0] = Map.FRONT_LOCK
    p.positions[1] = Map.RELAY
    tap_key(KEY_T)
    check(p.bracing and p.front_fixed,"P1 can brace with T on co-op keyboard")
    check(p.pin_site == "loose","manual support does not silently install the pin")
    tap_key(KEY_T)
    check(not p.bracing,"T releases P1 manual support")
    p.positions[1] = Map.FRONT_LOCK
    tap_key(KEY_R)
    check(p.pin_site == "carried" and p.pin_actor == 1,"R remains the co-op cat tool")
    light._refresh()
    check(light.p1_help.text.contains("T 工具"),"co-op HUD displays the actual P1 tool key")
    lobby.session.pause_all()
    lobby.start_trial("light",true)
    await frames(2)
    p = lobby.light_corridor.puzzle
    p.phase = "girl"
    p.positions[0] = Map.FRONT_LOCK
    tap_key(KEY_R)
    check(p.bracing,"solo R remains the controlled actor tool")
    lobby.free()
    print("M19_TOOL_INPUT: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
