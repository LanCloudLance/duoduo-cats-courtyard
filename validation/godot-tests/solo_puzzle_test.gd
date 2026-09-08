extends SceneTree
const Bridge = preload("res://game/bridge_state.gd")
const Light = preload("res://game/light_state.gd")
const Rest = preload("res://game/rest_state.gd")
var checks := 0
var failed := 0
func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failed += 1
        print("FAIL: ",message)
func _initialize() -> void:
    var bridge = Bridge.new()
    if bridge.get("solo_mode") == null:
        check(false,"single puzzle mode exists")
    else:
        bridge.solo_mode = true
        bridge.unlocked = 3
        var points: Array[Vector2] = [Bridge.EXIT,Bridge.EXIT,Vector2(400,640)]
        bridge.interact(0,1,points)
        check(not bridge.finished,"single confirmation cannot abandon white cat")
        points[2] = Bridge.EXIT
        bridge.tick(points,1)
        check(bridge.finished and not bridge.confirmed[1],"actual whole party, one confirmation")
        var rest = Rest.new()
        rest.solo_mode = true
        for i in range(3): rest.positions[i] = Rest.BENCH
        rest.interact(0)
        check(rest.rested and not rest.ready[1],"solo bench does not fake player two")
        for i in range(3): rest.positions[i] = Rest.EXIT
        rest.interact(0)
        check(rest.finished,"single exit after actual gathering")
        var light = Light.new()
        light.solo_mode = true
        light.lit = true
        light.source = "near"
        light.positions[1] = Vector2(330,440)
        light.beam = light.positions[1]
        light.park_traveler(1)
        light.beam = Vector2(580,440)
        for i in range(150): light.step(0.02,Vector2.ZERO,Vector2.ZERO,true)
        check(light.recoveries == 0,"parked illuminated foothold survives operator adjustment")
        var before: Vector2 = light.positions[1]
        light.step(0.1,Vector2.ZERO,Vector2.RIGHT,true)
        check(light.positions[1] == before,"foothold cannot pave dark path")
        light.park_traveler(1)
        check(light.held_actor == 1,"cycling on old hold does not extend it")
        light._release_light()
        check(light.recoveries == 1 and light.held_actor == -1,"release light clears hold and recovers")
        light.lit = true
        light.positions[1] = Vector2(330,440)
        light.beam = light.positions[1]
        light.slipping[1] = 0.4
        light.park_traveler(1)
        check(light.held_actor == -1,"cannot cancel a fall by switching")
        light.slipping[1] = 0
        light = Light.new()
        light.solo_mode = true
        light.phase = "girl"
        light.solo_actor = 2
        light.operator_slot = 1
        light.current_cat = 2
        var beam_before: Vector2 = light.beam
        light.positions[2] = Vector2(180,400)
        light.step(0.05,Vector2.ZERO,Vector2.RIGHT,true)
        check(light.beam == beam_before,"white cat input cannot operate black cat desk")
    print("SOLO PUZZLE: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
