extends SceneTree
## State fixtures: direct placements isolate physical constraints, not a keyboard playthrough.
var checks:=0
var failed:=0
func check(v:bool,label:String)->void:
    checks+=1
    if not v:failed+=1;push_error("FAIL: "+label)
func ticks(s,n:=40)->void:
    for i in range(n):s.step(1.0/60,Vector2.ZERO,Vector2.ZERO,true)
func touch(s,role:int,p:Vector2)->void:
    s.positions[role]=p;s.interact(role);ticks(s)
func _initialize()->void:call_deferred("run")
func run()->void:
    var script=load("res://game/chapter_two_state.gd")
    var s=script.new()
    check(s.available_roles()==[0,1],"white cat stays NPC in chapter two")
    check(not s.walkable(Vector2(500,420),0) and not s.walkable(Vector2(500,560),1),"raised gap blocks real walking")
    touch(s,1,s.WINCH_A);check(not s.lifted_a,"wrong role cannot lift bridge")
    touch(s,0,s.WINCH_A)
    check(not s.walkable(Vector2(500,560),1),"lift without lamp alignment still unsafe")
    touch(s,0,s.LAMP_A)
    check(s.walkable(Vector2(500,560),1) and not s.walkable(Vector2(500,560),0),"aligned low path is cat sized")
    s.positions[1]=Vector2(500,560);touch(s,0,s.WINCH_A)
    check(s.positions[1].x<460 and not s.locked_a,"lowering loaded segment returns cat safely")
    touch(s,0,s.WINCH_A);touch(s,1,s.LATCH_A)
    check(s.locked_a and s.reverse_seen and s.walkable(Vector2(570,420),0),"first latch permanently locks and reveals reversing light")
    touch(s,0,s.WINCH_B);touch(s,0,s.LAMP_B)
    check(not s.segment_ready(1),"second segment needs a different orientation")
    touch(s,0,s.LAMP_B);touch(s,1,s.LATCH_B)
    check(s.locked_b and s.walkable(Vector2(720,420),0),"second bridge lock is a permanent checkpoint")
    touch(s,0,s.BOX);check(not s.hook_owned,"girl cannot acquire cat equipment")
    touch(s,1,s.BOX);touch(s,1,s.SHORTCUT)
    check(s.hook_owned and not s.shortcut_open,"hook must first be practiced safely")
    touch(s,1,s.LOOP);touch(s,1,s.SHORTCUT)
    check(s.shortcut_open and s.walkable(Vector2(970,420),0),"practiced hook physically lowers the shortcut")
    check(not s.walkable(Vector2(1145,380),1),"barred low window cannot be crossed by cat")
    s.positions[1]=Vector2(850,420);touch(s,0,s.WINDOW)
    check(not s.finished,"both must approach window")
    s.positions[1]=Vector2(990,420);touch(s,0,s.WINDOW)
    check(not s.finished,"proximity cannot complete while companion is still on shortcut gap")
    touch(s,1,s.WINDOW);touch(s,0,s.WINDOW)
    check(s.finished and not s.joined and s.record().get("chapter")=="chapter-two","chapter completion never unlocks white cat")
    var r=script.new();r.restore(s.record())
    check(r.finished and r.locked_b and r.hook_owned and r.shortcut_open,"save restores completed physical world")
    var bad=script.new();bad.restore({"version":1,"chapter":"chapter-three","completed":true})
    check(not bad.finished,"other chapter save rejected")
    var before:float=bad.clock;bad.step(0.05,Vector2.RIGHT,Vector2.RIGHT,false)
    check(before==bad.clock,"disabled state does not move")
    print("M25_TWO_STATE: %d checks, %d failed (state fixtures)"%[checks,failed]);quit(1 if failed else 0)
