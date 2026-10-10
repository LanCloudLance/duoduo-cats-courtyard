extends SceneTree
const Four=preload("res://game/chapter_four_state.gd")
var checks:=0
var failed:=0
func check(ok:bool,label:String)->void:
    checks+=1
    if not ok:failed+=1;print("FAIL: ",label)
func advance(s,n:=30)->void:
    for i in range(n):s.step(.05,Vector2.ZERO,Vector2.ZERO,true)
func use(s,role:int,p:Vector2,tool:=false)->void:
    s.positions[role]=p;s.action_time[role]=0
    if tool:s.tool(role)
    else:s.interact(role)
func lit():
    var s=Four.new();s.cover_hooked=true;s.cloth=true;s.phase="investigate"
    s.facing[2]=Vector2.UP;use(s,2,s.DUCT_LIGHT);advance(s)
    return s
func send(s)->void:use(s,0,s.ARROWS,true);advance(s)
func _initialize()->void:
    var s=lit();send(s);use(s,1,s.BRANCH);use(s,0,s.ARROWS);send(s);use(s,0,s.ALIGHT)
    check(not s.battle_requested,"main and isolated split cannot fabricate connected split observation")
    check(s.get("connected_split_seen")!=null,"connected split has separate durable observation")
    if s.get("connected_split_seen")!=null:
        check(not s.connected_split_seen,"isolated split does not award connected evidence")
        use(s,1,s.BRANCH);use(s,0,s.ALIGHT)
        check(not s.connected_split_seen and not s.battle_requested,"reconnecting stored light is not a completed connected sample")
        use(s,0,s.ARROWS,true);advance(s,3);use(s,2,s.DUCT_LIGHT,true);advance(s)
        check(not s.connected_split_seen,"canceled connected sample grants no evidence")
        use(s,2,s.DUCT_LIGHT);send(s)
        check(s.connected_split_seen and s.reserve_charge==0,"completed connected split really drains and records evidence")
        var restored=Four.new()
        check(restored.restore_checkpoint(s.checkpoint()) and restored.connected_split_seen and not restored.pulse_active,"connected observation survives checkpoint without active light")
        use(s,0,s.ALIGHT)
        check(s.battle_requested and s.phase=="battle_one","all three optical samples permit truthful diagnosis")
    var hints=lit();hints.request_hint()
    check(hints.message.contains("1 / 3") and hints.message.contains("观察"),"first hint is observation level")
    hints.request_hint();check(hints.message.contains("2 / 3") and hints.message.contains("规则"),"second hint explains local rule")
    hints.request_hint();hints.request_hint();check(hints.message.contains("3 / 3"),"local action hint caps at level three")
    send(hints);hints.request_hint()
    check(hints.message.contains("1 / 3"),"new observed result resets hint level")
    hints.phase="exterior";hints.request_hint();hints.request_hint();hints.latch_fixed=true;hints.request_hint()
    check(hints.message.contains("1 / 3"),"repair milestone resets contextual guidance")
    print("M27_FOUR_REVIEW: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
