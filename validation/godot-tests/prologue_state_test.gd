extends SceneTree
const S = preload("res://game/prologue_state.gd")
var checks := 0
var failed := 0
func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failed += 1
        push_error("FAIL: "+label)
func advance(s, seconds: float) -> void:
    for i in range(ceili(seconds*60)): s.step(1.0/60,Vector2.ZERO,Vector2.ZERO,true)
func _initialize() -> void:
    var s = S.new()
    s.positions[1] = S.DESK
    s.interact(1)
    check(not s.notebook,"cat cannot complete girl's notebook task")
    s.positions[0] = S.DESK
    s.interact(0)
    check(s.notebook and s.phase == "chores","girl contribution alone does not finish shared opening")
    s.positions[1] = S.TOY
    s.interact(1)
    check(s.phase == "rest","both contributions unlock rest")
    s.positions[0] = S.SOFA
    s.interact(0)
    check(s.resting and s.phase == "leisure","rest follows completed chores")
    var timer: float = s.timer
    s.step(1,Vector2.RIGHT,Vector2.RIGHT,false)
    check(s.timer == timer and s.positions[0] == S.SOFA,"pause freezes movement and scripted events")
    advance(s,4.1)
    check(s.phase == "strange","door event follows short rest without manual skip")
    s.positions[0] = S.DOOR
    s.interact(0)
    check(s.phase == "strange","girl cannot bypass black cat discovery")
    s.positions[1] = S.DOOR
    s.interact(1)
    check(s.phase == "noticed","black cat discovers white tail")
    s.positions[0] = S.SOFA
    s.interact(1)
    check(s.phase == "noticed","calling from far away cannot advance reunion")
    s.positions[1] = s.positions[0]+Vector2(35,0)
    s.interact(1)
    check(s.phase == "called","cat returns and calls girl")
    s.positions[0] = S.DOOR
    s.interact(0)
    check(s.phase == "crossing","girl chooses to follow after seeing path")
    s.interact(0)
    check(not s.finished,"one player cannot exit without partner")
    s.step(0.05,Vector2.DOWN,Vector2.ZERO,true)
    s.positions[0] = Vector2(1120,430)
    s.step(0.01,Vector2.ZERO,Vector2.ZERO,true)
    check(not s.confirmed[0],"leaving door clears stale readiness")
    s.positions[0] = S.DOOR
    s.positions[1] = S.DOOR+Vector2(30,30)
    s.interact(0)
    s.interact(1)
    check(s.finished and s.phase == "complete","both players finish at door")
    s = S.new()
    s.single = true
    for i in range(7): s.switch_actor()
    check(s.controlled == 1,"solo only alternates girl and black cat")
    s.step(0.05,Vector2.UP*100,Vector2.ZERO,true)
    check(s.valid(s.positions[0]),"large input cannot escape room")
    check(s.move(Vector2(300,400),Vector2(0,-200)).y >= 390,"furniture wall blocks walking")
    check(s.move(Vector2(1120,440),Vector2(0,-130)).y < 390,"hallway provides door access")
    s.phase = "crossing"
    s.positions[0] = S.DOOR
    s.positions[1] = S.DOOR+Vector2(25,25)
    s.interact(1)
    check(s.finished,"solo exit needs both manually positioned actors but only one confirmation")
    s = S.new()
    s.phase = "noticed"
    s.positions[0] = S.DOOR
    s.positions[1] = S.DOOR+Vector2(20,20)
    check(s.hint(1).contains("呼唤"),"door overlap shows story-critical partner hint")
    s.interact(1)
    check(s.phase == "called","girl waiting at doorway cannot block cat call")
    print("PROLOGUE_STATE: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
