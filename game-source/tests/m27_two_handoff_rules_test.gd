extends SceneTree
const Two=preload("res://game/chapter_two_state.gd")
var checks:=0
var failed:=0
func check(ok:bool,label:String)->void:
    checks+=1
    if not ok:failed+=1;print("FAIL: ",label)
func use(s,r:int,p:Vector2,tool:=false)->void:
    s.positions[r]=p;s.action_time[r]=0
    if tool:s.tool(r)
    else:s.interact(r)
func fixture():
    var s=Two.new();s.locked_a=true;s.reverse_seen=true;s.lifted_a=true;s.support_site="b";s.lifted_b=true;s.lamp_b=2;s.rear_loaded_seen=true
    return s
func _initialize()->void:
    var old=fixture();use(old,1,old.LATCH_B)
    check(not old.locked_b,"rear latch cannot lock without carrying unique support to far socket")
    check(old.has_method("rear_braced"),"girl can explicitly take rear bridge weight")
    if not old.has_method("rear_braced"):quit(1);return
    for mode in [true,false]:
        var s=fixture();s.single=mode
        s.positions[0]=s.WINCH_B;check(s.target(0)=="winch_b","girl at winch center cannot accidentally select lower brace handle")
        s.positions[0]=s.BRACE_B;check(s.target(0)=="brace_b","girl at lower handhold selects explicit brace rather than overlapping winch")
        use(s,1,s.WINCH_B)
        check(s.support_site=="b","cat cannot remove weight-loaded support")
        use(s,0,s.BRACE_B)
        check(s.rear_braced() and s.actions[0]=="brace","girl holds bridge with explicit persistent action")
        s.switch_actor()
        check(s.rear_braced(),"ordinary single-player role switch preserves explicit brace")
        use(s,1,s.WINCH_B)
        check(s.support_site=="cat_carried" and s.segment_ready(1),"cat takes same unloaded support while girl bears weight")
        use(s,1,s.LATCH_B)
        check(s.locked_b and s.support_site=="far" and not s.rear_braced(),"far socket takes weight permanently and ends brace")
        s.actions[0]="";s.lamp_b=0;s.lifted_b=false;s.guard(0,false)
        check(s.walkable(Vector2(720,420),0) and s.walkable(Vector2(720,555),1),"permanent bridge survives all temporary support removal")
        use(s,1,s.LATCH_B,true)
        check(s.locked_b and s.support_site=="far","installed far support cannot be removed or cloned")
        var canceled=fixture();canceled.single=mode;use(canceled,0,canceled.BRACE_B);use(canceled,1,canceled.WINCH_B)
        canceled.positions[1]=Vector2(700,555);canceled.guard(0,false)
        check(not canceled.rear_braced() and not canceled.lifted_b and canceled.positions[1].x<615 and canceled.support_site=="cat_carried","session cancellation returns carrier to fixed platform and keeps unique prop")
        var loaded=Two.new();loaded.single=mode
        check(loaded.restore_checkpoint(canceled.checkpoint()) and loaded.support_site=="cat_carried" and not loaded.rear_braced(),"mid-carry checkpoint restores safe carrier without body support")
        use(loaded,0,loaded.BRACE_B)
        check(loaded.rear_braced() and loaded.segment_ready(1),"safe carrier can resume by bracing without forced prop return trip")
        loaded.positions[1]=Vector2(700,555);loaded.controlled=0
        loaded.step(.05,Vector2.LEFT,Vector2.ZERO,true)
        check(not loaded.rear_braced() and loaded.positions[1].x<615,"moving girl releases support and safely returns traveler")
        var dark=fixture();dark.single=mode;use(dark,0,dark.BRACE_B);use(dark,1,dark.WINCH_B);dark.positions[1]=Vector2(700,555)
        dark.lamp_b=0;dark.step(.05,Vector2.ZERO,Vector2.ZERO,true)
        check(dark.positions[1].x<615 and dark.support_site=="cat_carried" and not dark.locked_b,"loss of aligned light returns carried prop safely without progress")
        var lesson=Two.new();lesson.single=mode;lesson.locked_a=true;lesson.support_site="carried";lesson.positions[0]=lesson.WINCH_B
        use(lesson,1,lesson.WINCH_B)
        check(lesson.support_site=="cat_carried" and not lesson.lifted_b,"safe fixed-platform handoff visibly teaches cat pickup")
        use(lesson,1,lesson.WINCH_B)
        check(lesson.support_site=="b" and not lesson.lifted_b,"cat safely fits the same prop into empty rear socket")
    print("M27_TWO_HANDOFF_RULES: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
