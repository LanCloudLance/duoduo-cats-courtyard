extends "res://tests/prologue_state_test.gd"
func _initialize() -> void:
    var s = S.new()
    check(s.has_method("checkpoint") and s.has_method("restore_checkpoint"),"prologue exposes explicit mid-progress checkpoint contract")
    check(s.has_method("tool"),"prologue has a real contextual role tool")
    if failed:
        print("M27_PROLOGUE_CHECKPOINT: %d checks, %d failed" % [checks,failed])
        quit(1)
        return
    for single in [false,true]:
        s = S.new()
        s.single = single
        for phase in ["home","listen","sniff","peek","slip","jam","open","leaving","complete"]:
            s.phase = phase
            s.finished = phase == "complete"
            s.rug_pull = 115 if phase in ["open","leaving","complete"] else 0
            var data: Dictionary = s.checkpoint()
            var target = S.new()
            target.single = single
            check(target.restore_checkpoint(data),"restore reachable phase "+phase)
            check(target.phase == ("open" if phase == "leaving" else phase),"safe phase "+phase)
            check(not target.brace and not target.rug_grab,"held commands cleared "+phase)
            if phase in ["home","listen","sniff","peek","slip"]:
                target.positions[0] = Vector2(1080,320)
                advance(target,20)
                check(target.phase == "jam","restored white departure remains continuable "+phase)
        s = S.new()
        s.single = single
        s.phase = "jam"
        s.wedged = true
        s.rug_pull = 48
        s.brace = true
        s.rug_grab = true
        s.ball_velocity = Vector2(90,20)
        s.say("门挡已经撑住了门。")
        var data: Dictionary = s.checkpoint()
        var target = S.new()
        target.single = single
        check(target.restore_checkpoint(data),"partial rug restores")
        check(target.wedged and target.rug_pull == 48 and target.history.has("门挡已经撑住了门。"),"permanent work and history survive")
        check(not target.brace and not target.rug_grab and target.ball_velocity == Vector2.ZERO,"restoration releases commands and momentum")
        for bad in ["phase","mode","history","facts","positions","completed"]:
            var corrupt: Dictionary = data.duplicate(true)
            if bad == "phase": corrupt.phase = "mystery"
            if bad == "mode": corrupt.mode = "wrong"
            if bad == "history": corrupt.history = [3]
            if bad == "facts": corrupt.facts.rug_pull = 115
            if bad == "positions": corrupt.positions[0] = [-400,7]
            if bad == "completed": corrupt.completed = true
            var before: Dictionary = target.checkpoint()
            check(not target.restore_checkpoint(corrupt),"reject corrupt "+bad)
            check(target.checkpoint() == before,"reject atomically "+bad)
        s.carrier = 0
        s.wedged = false
        s.wedge = s.positions[0]+Vector2(28,-36)
        check(target.restore_checkpoint(s.checkpoint()),"carried prop safely restores")
        check(target.carrier == -1 and target.wedge == target.positions[0],"carried wedge is reachable at owner's feet")
    s = S.new()
    var hints: int = s.hint_level
    s.tool(0)
    check(s.hint_level == hints and s.message.contains("门挡"),"no-target tool explains ability without hint escalation")
    s.positions[0] = s.DESK
    s.action_time[0] = 0
    s.tool(0)
    check(s.carrier == 0,"context tool picks up doorstop")
    s.phase = "jam"
    s.positions[0] = Vector2(1080,320)
    s.action_time[0] = 0
    s.tool(0)
    check(s.wedged,"context tool props door")
    print("M27_PROLOGUE_CHECKPOINT: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
