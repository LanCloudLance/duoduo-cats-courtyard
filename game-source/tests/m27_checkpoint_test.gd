extends SceneTree
var checks:=0
var failed:=0
func check(value:bool,label:String)->void:
    checks+=1
    if not value:failed+=1;print("FAIL: ",label)
func run()->void:
    var Two=load("res://game/chapter_two_state.gd")
    var s=Two.new()
    check(s.has_method("checkpoint"),"unfinished chapters expose checkpoint contract")
    if not s.has_method("checkpoint"):
        print("M27_CHECKPOINT: %d checks, %d failed"%[checks,failed]);quit(1);return
    s.locked_a=true;s.lifted_a=true;s.lamp_a=1;s.positions[1]=Vector2(590,560)
    var data:Dictionary=s.checkpoint()
    var restored=Two.new()
    check(restored.restore_checkpoint(JSON.parse_string(JSON.stringify(data))),"JSON numeric roundtrip restores safe progress")
    check(restored.locked_a and not restored.locked_b and not restored.finished,"first bridge lock survives without forging completion")
    check(restored.walkable(restored.positions[1],1),"temporary crawlway actor returns to permanent safe footing")
    var rejected=Two.new();var wrong:Dictionary=data.duplicate(true);wrong.mode="dual"
    check(not rejected.restore_checkpoint(wrong) and not rejected.locked_a,"mode mismatch rejected atomically")
    wrong=data.duplicate(true);wrong.facts.hook_practiced=true
    check(not rejected.restore_checkpoint(wrong),"invalid dependent progress cannot open a later bridge")
    wrong=data.duplicate(true);wrong.phase="complete"
    check(not rejected.restore_checkpoint(wrong),"incomplete record cannot claim completion phase")
    wrong=data.duplicate(true);wrong.positions[0]=[1e30,0]
    check(not rejected.restore_checkpoint(wrong),"out of bounds data rejected before applying facts")
    var Three=load("res://game/chapter_three_state.gd");var t=Three.new()
    t.wick_found=true;t.wick_ready=true;t.wick_fitted=true;t.door_angle=1;t.npc_called=true;t.door_open=true;t.joined=true;t.light_equipped=true
    t.phase="walkway";t.beam_held=true;t.actions[2]="light";t.positions[2]=t.LIGHT_STAND
    var tr=Three.new()
    check(tr.restore_checkpoint(t.checkpoint()) and tr.joined and tr.light_equipped,"reunion and equipment persist")
    check(not tr.beam_held and tr.actions[2]=="","held puzzle commands do not resume without player intent")
    var Four=load("res://game/chapter_four_state.gd");var f=Four.new()
    f.cover_hooked=true;f.cloth=true;f.main_return_seen=true;f.shell_leak_seen=true;f.reserve_hold_seen=true;f.branch_seen=true;f.duct_seen=true
    f.connected_split_seen=true;f.phase="battle_one";f.battle_requested=true;f.route_split=true;f.pulse_active=true
    var fr=Four.new()
    check(fr.restore_checkpoint(f.checkpoint()) and fr.battle_requested,"pending encounter resumes instead of skipping or erasing evidence")
    check(fr.main_return_seen and fr.reserve_hold_seen and not fr.pulse_active and not fr.route_split,"optical evidence persists, live experiment resets")
    var Five=load("res://game/chapter_five_state.gd");var v=Five.new()
    v.route_lock=true;v.route_supported=true;v.route_lit=true;v.bridge_locked=true;v.arm_locked=true;v.lid_pins=2;v.lid_open=true;v.cleared_segments=1;v.stage_checkpoint=2;v.phase="unjam"
    v.fixed_light=true;v.hook_held=true;v.wheel_ready=true
    var vr=Five.new()
    check(vr.restore_checkpoint(v.checkpoint()) and vr.phase=="unjam" and vr.cleared_segments==1,"partial branch extraction survives restart")
    check(not vr.fixed_light and not vr.hook_held and not vr.wheel_ready,"restored machine requires fresh safe light and unloading command")
    var stale:Dictionary=v.checkpoint();stale.phase="lure"
    check(not Five.new().restore_checkpoint(stale),"later repair facts cannot regress into nonexistent third pin")
    for role in vr.available_roles():check(vr.walkable(vr.positions[role],role),"machine restore place is safe for role "+str(role))
    s.locked_b=true;s.support_site="far";s.rear_loaded_seen=true;s.hook_owned=true;s.hook_practiced=true;s.shortcut_open=true;s.finished=true;s.phase="complete"
    var finished=Two.new();check(finished.restore_checkpoint(s.checkpoint()) and finished.finished,"valid completed checkpoint restores")
    var legacy=Two.new();legacy.restore(s.record());check(legacy.finished,"legacy completed v1 remains readable")
    var follower=Two.new();follower.locked_a=true;follower.locked_b=true;follower.positions[0]=Vector2(880,420);follower.positions[1]=Vector2(410,420);follower.controlled=0
    for i in range(240):follower.step(.05,Vector2.ZERO,Vector2.ZERO,true)
    print("FOLLOW_FIXTURE: ",follower.positions)
    check(follower.positions[1].x>760,"single party follows across permanently locked transport bridge")
    var blocked=Two.new();blocked.positions[0]=Vector2(850,420);blocked.positions[1]=Vector2(410,420)
    for i in range(200):blocked.step(.05,Vector2.ZERO,Vector2.ZERO,true)
    check(blocked.positions[1].x<460 and not blocked.locked_a,"following neither crosses a locked gap nor actuates a puzzle")
    follower.positions[1]=Vector2(420,420);follower.actions[1]="hold"
    for i in range(120):follower.step(.05,Vector2.ZERO,Vector2.ZERO,true)
    check(follower.positions[1]==Vector2(420,420),"explicitly posted partner stays at their mechanism")
    print("M27_CHECKPOINT: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
func _initialize()->void:call_deferred("run")
