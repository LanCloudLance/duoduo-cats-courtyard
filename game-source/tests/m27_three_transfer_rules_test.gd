extends SceneTree
const Three=preload("res://game/chapter_three_state.gd")
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
    var s=Three.new();s.restore_complete();s.finished=false;s.phase="exit";s.exit_revealed=false
    return s
func light(s)->void:
    s.facing[2]=Vector2.RIGHT;use(s,2,s.SEARCH_STAND)
func _initialize()->void:
    var s=fixture()
    check(s.get("source_level")!=null,"exit has two source heights")
    check(s.get("exit_low_latched")!=null,"two differently faced receivers have durable locks")
    if s.get("source_level")==null:quit(1);return
    s.source_level=0;s.rig_angle=1;s.high_mirror_angle=0;s.exit_low_latched=false;s.exit_high_latched=false
    light(s)
    check(not s.exit_revealed and not s.exit_low_latched,"wrong low mirror does not light receiver")
    check(s.transfer_trace().misses.size()>0,"wrong low mirror has visible ray endpoint")
    use(s,0,s.RIG)
    check(s.exit_low_latched and not s.exit_high_latched and not s.exit_revealed,"low geometry latches only first receiver")
    use(s,0,s.SEARCH_STAND)
    check(s.source_level==1 and not s.beam_held and s.actions[2]=="","height change visibly clears held source")
    check(s.exit_low_latched and not s.exit_high_latched,"height change retains first lock without second fact")
    light(s)
    check(not s.exit_high_latched and not s.exit_revealed,"same low mirror cannot solve raised geometry")
    check(s.transfer_trace().backfaces.size()>0,"raised source visibly strikes low receiver back")
    use(s,0,s.RIG)
    check(not s.exit_high_latched and s.transfer_trace().misses.size()>0,"correct low mirror with wrong high mirror still misses")
    use(s,1,s.HIGH_RING)
    check(s.exit_high_latched and s.exit_revealed and s.phase=="map","high mirror routes light into second receiver front")
    use(s,2,s.SEARCH_STAND,true)
    check(not s.beam_held and s.exit_revealed,"both permanent locks survive explicit light release")
    var copy=Three.new()
    check(copy.restore_checkpoint(s.checkpoint()) and copy.exit_revealed and not copy.beam_held,"completed optical locks resume without live source")
    var partial=fixture();partial.exit_low_latched=false;partial.exit_high_latched=false;partial.source_level=1;partial.rig_angle=0;partial.high_mirror_angle=0
    light(partial)
    check(not partial.exit_low_latched and not partial.exit_high_latched,"back face never grants missing low evidence")
    var safe=Three.new()
    check(safe.restore_checkpoint(partial.checkpoint()) and not safe.exit_low_latched and not safe.exit_high_latched,"resume cannot manufacture unseen receiver locks")
    var configured=fixture();configured.exit_low_latched=false;configured.exit_high_latched=false;configured.source_level=1;configured.rig_angle=1;configured.high_mirror_angle=1
    var unlit=Three.new()
    check(unlit.restore_checkpoint(configured.checkpoint()) and not unlit.exit_high_latched and not unlit.beam_held,"correct mirror configuration alone does not invent receiver evidence on load")
    partial.request_hint();check(partial.message.contains("1 / 3"),"transfer starts with observation hint")
    partial.request_hint();partial.request_hint();check(partial.message.contains("3 / 3"),"local transfer guidance has three capped levels")
    use(partial,0,partial.RIG);partial.request_hint();check(partial.message.contains("1 / 3"),"changed ray endpoint resets local hint")
    print("M27_THREE_TRANSFER_RULES: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
