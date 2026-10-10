extends SceneTree
const Two=preload("res://game/chapter_two_state.gd")
var checks:=0
var failed:=0
func check(ok:bool,label:String)->void:
    checks+=1
    if not ok:failed+=1;print("FAIL: ",label)
func use(s,r:int,p:Vector2)->void:s.positions[r]=p;s.action_time[r]=0;s.interact(r)
func _initialize()->void:
    var s=Two.new();s.locked_a=true;s.support_site="carried";s.positions[0]=s.WINCH_B
    use(s,1,s.WINCH_B);use(s,0,s.BRACE_B)
    check(not s.rear_braced() and not s.lifted_b,"first safe handoff cannot skip loading the rear support")
    check(s.get("rear_loaded_seen")!=null,"actual rear loading has durable evidence for safe restart")
    if s.get("rear_loaded_seen")==null:quit(1);return
    use(s,1,s.WINCH_B);use(s,0,s.WINCH_B)
    check(s.rear_loaded_seen and s.lifted_b,"installed rear prop is actually loaded before body handoff")
    use(s,0,s.BRACE_B);use(s,1,s.WINCH_B)
    s.guard(0,false);use(s,0,s.BRACE_B)
    check(s.rear_braced() and s.support_site=="cat_carried","witnessed rear loading permits local recovery without returning prop")
    print("M27_TWO_HANDOFF_BYPASS: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
