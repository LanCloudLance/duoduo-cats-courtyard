extends SceneTree
var checks := 0
var failed := 0
func check(value: bool,label: String) -> void:
    checks += 1
    if not value: failed += 1; push_error("FAIL: "+label)
func _initialize() -> void:
    check(ResourceLoader.exists("res://game/chime_state.gd"),"bell gate has a manipulable light rule")
    if failed: finish(); return
    var state = load("res://game/chime_state.gd").new()
    state.trace()
    check(not state.receivers[0],"wrong mirror initially sends light away from bell")
    state.positions[0] = state.MIRRORS[0]
    state.interact(0)
    state.step(0.1,Vector2.ZERO,Vector2.ZERO,true)
    check(state.receivers[0] and state.stage == 1,"mirror rotates immediately and light reveals its result")
    for i in range(16): state.step(0.1,Vector2.ZERO,Vector2.ZERO,true)
    check(state.stage == 2 and not state.finished,"one bell reveals a second rule instead of ending the puzzle")
    state.positions[0] = state.mirror_points()[0]
    state.interact(0)
    state.positions[1] = state.mirror_points()[1]
    state.interact(1)
    check(state.mirrors[1] == 1,"Tuantuan must use claw tool rather than girl's lever")
    state.tool(1)
    state.tool(1)
    state.positions[0] = state.mirror_points()[2]
    state.interact(0)
    state.trace()
    check(state.receivers == [true,false],"correct mirrors alone cannot split the beam")
    state.switch_cat()
    state.positions[2] = state.socket_points()[0]
    state.tool(1)
    for i in range(3): state.step(0.1,Vector2.ZERO,Vector2.ZERO,true)
    check(state.receivers == [true,true] and not state.finished,"two bells actually light before completion threshold")
    state.step(0.1,Vector2.ZERO,Vector2.DOWN,true)
    check(state.lens_site == -1 and state.lit_time == 0,"moving Yuanyuan releases lens and clears partial progress")
    state.positions[2] = state.socket_points()[0]
    state.tool(1)
    state.switch_cat()
    check(state.lens_site == 0,"switching away keeps stable Yuanyuan on the lens")
    for i in range(7): state.step(0.1,Vector2.ZERO,Vector2.ZERO,true)
    check(state.finished,"continuous real two-bell light unlatches exit")
    check(state.has_method("party_ready"),"bell exit checks the entire party")
    if state.has_method("party_ready"):
        state.positions[0] = state.EXIT
        state.positions[state.current_cat] = state.EXIT
        state.positions[3-state.current_cat] = Vector2(180,250)
        check(not state.party_ready(),"exit cannot leave inactive cat behind")
    state.switch_cat()
    state.step(0.1,Vector2.ZERO,Vector2.DOWN,true)
    check(state.finished,"opened latch lets cats reunite without relocking")
    var solutions := 0
    for a in range(2):
        for b in range(2):
            for c in range(2):
                for site in range(2):
                    var candidate = load("res://game/chime_state.gd").new()
                    candidate.stage = 2
                    candidate.mirrors = [a,b,c]
                    candidate.lens_site = site
                    candidate.positions[2] = candidate.socket_points()[site]
                    candidate.trace()
                    if candidate.receivers.all(func(v): return v): solutions += 1
                    check(candidate.rays.size() <= 80,"every finite configuration terminates its ray trace")
    check(solutions == 1,"rule composition has one physical solution among 16 configurations")
    finish()
func finish() -> void:
    print("M21_CHIME: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
