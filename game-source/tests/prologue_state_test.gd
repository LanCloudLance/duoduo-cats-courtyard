extends SceneTree
const S = preload("res://game/prologue_state.gd")
var checks := 0
var failed := 0
func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failed += 1
        push_error("FAIL: "+label)
func advance(s, seconds: float, a := Vector2.ZERO, b := Vector2.ZERO) -> void:
    for i in range(ceili(seconds*60)): s.step(1.0/60,a,b,true)
func _initialize() -> void:
    var s = S.new()
    advance(s,30)
    check(s.phase == "home" and s.white_visible,"idle alone never makes white cat disappear")
    check(s.actions[2] == "listen","distant chime has a visible listening response")
    s.positions[0] = S.CUSHION
    s.interact(0)
    check(s.actions[0] == "pet" and s.white_wait > 0,"pet creates actor pose and white cat pause")
    s.step(0.05,Vector2.ZERO,Vector2.ZERO,true)
    check(s.phase == "listen","proximity starts curiosity without chore checklist")
    var clock: float = s.clock
    s.step(1,Vector2.ONE,Vector2.ONE,false)
    check(s.clock == clock,"pause freezes entire room and story")
    s.positions[0] = Vector2(380,495)
    advance(s,15)
    check(s.phase == "peek" and s.white_visible,"cat waits at door when players cannot witness departure")
    s.positions[0] = S.DOOR+Vector2(-45,30)
    advance(s,6)
    check(s.phase == "jam" and not s.white_visible,"observed departure finishes with jammed door")
    s.positions[1] = s.rug_position()+Vector2(0,20)
    s.interact(1)
    advance(s,0.5)
    check(not s.rug_grab and s.rug_pull == 0 and s.rug_shake > 0,"pulling loaded rug fails with physical reaction")
    for i in range(5): s.interact(1)
    check(s.rug_pull == 0,"button spam never substitutes for dragging")
    s.interact(0)
    advance(s,0.5)
    check(s.brace and s.door_open > 0.2,"girl braces door and opens a visible gap")
    s.interact(1)
    advance(s,0.5)
    check(s.rug_grab,"cat can grab freed carpet edge")
    advance(s,0.2,Vector2.ZERO,Vector2.UP)
    check(s.rug_pull == 0,"wrong drag direction does not solve rug")
    advance(s,0.8,Vector2.ZERO,Vector2.DOWN)
    check(s.rug_pull > 20 and s.rug_pull < 105,"rug moves continuously with actor, before solution")
    s.interact(0)
    advance(s,0.2)
    check(not s.rug_grab and s.phase == "jam","releasing support stops loaded rug movement")
    # A portable wedge is a valid alternative to leaving girl holding the handle.
    s.positions[0] = S.DESK
    s.interact(0)
    advance(s,0.7)
    check(s.carrier == 0,"doorstop can be picked up freely")
    s.positions[0] = S.DOOR+Vector2(-45,30)
    s.interact(0)
    check(s.wedged and s.carrier == -1,"carried wedge props door independently")
    advance(s,0.1,Vector2.DOWN)
    check(not s.brace and s.wedged,"girl can leave wedge-supported door")
    s.positions[1] = s.rug_position()+Vector2(0,15)
    s.interact(1)
    advance(s,0.5)
    advance(s,1.8,Vector2.ZERO,Vector2.DOWN)
    check(s.phase == "open" and s.rug_pull >= 105,"physical drag clears rug while wedge supports door")
    s.positions[0] = S.DOOR
    advance(s,1)
    check(not s.finished,"cannot exit without both actors present")
    s.positions[1] = S.DOOR+Vector2(35,35)
    advance(s,3)
    check(s.finished,"walking together triggers visible exit, no confirmation checklist")
    s = S.new()
    s.single = true
    for i in range(7): s.switch_actor()
    check(s.controlled == 1,"solo only selects girl and black cat")
    s.positions[1] = s.ball-Vector2(40,0)
    s.interact(1)
    var ball: Vector2 = s.ball
    advance(s,0.6)
    check(s.ball.x > ball.x+30 and s.actions[1] != "pull","paw input moves ball through room")
    check(s.move(Vector2(300,400),Vector2(0,-200)).y >= 390,"furniture blocks movement")
    check(s.move(Vector2(1120,440),Vector2(0,-130)).y < 390,"hallway stays traversable")
    s.phase = "jam"
    s.request_hint()
    check(s.hint_level == 1 and not s.message.contains("朵朵可以撑门"),"first requested hint describes observation rather than full solution")
    print("PROLOGUE_STATE: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
