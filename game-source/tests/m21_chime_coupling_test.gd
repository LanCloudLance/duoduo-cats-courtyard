extends SceneTree
var checks := 0
var failed := 0
func check(value: bool,label: String) -> void:
    checks += 1
    if not value: failed += 1; push_error("FAIL: "+label)
func _initialize() -> void:
    var state = load("res://game/chime_state.gd").new()
    check(state.has_method("mirror_points") and state.has_method("source_point"),"main board exposes real coupled optical geometry")
    if failed: finish(); return
    state.stage = 2
    state.mirrors = [0,1,1]
    state.lens_site = 0
    state.trace()
    check(state.receivers == [true,true],"both branches traverse the shared mirror and enter the bell windows")
    state.mirrors[0] = 1
    state.trace()
    check(state.receivers == [false,false],"turning shared mirror changes both bell routes, not only one next step")
    state.mirrors = [0,1,1]
    state.lens_site = -1
    state.trace()
    check(state.receivers == [true,false],"unsplit beam gives visible partial success")
    state.source_level = 1
    state.lens_site = 1
    state.trace()
    check(state.receivers == [false,true],"lower lens has a useful distinct outcome rather than decorative complexity")
    state.positions[0] = state.source_point()
    state.interact(0)
    check(state.source_level == 0,"girl can change emitter rail height through normal interaction")
    var solutions := 0
    var lower_partial := 0
    for a in range(2):
        for b in range(2):
            for c in range(2):
                for lens in range(2):
                    for source in range(2):
                        state.mirrors = [a,b,c]
                        state.lens_site = lens
                        state.source_level = source
                        state.trace()
                        if state.receivers == [true,true]: solutions += 1
                        if lens == 1 and state.receivers == [false,true]: lower_partial += 1
                        check(state.rays.size() <= 80,"ray graph terminates in every configuration")
    check(solutions == 1 and lower_partial > 0,"32 combinations contain one full solution and meaningful lower-lens experiments")
    finish()
func finish() -> void:
    print("M21_CHIME_COUPLING: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
