extends SceneTree
const Two=preload("res://game/chapter_two_state.gd")
const Three=preload("res://game/chapter_three_state.gd")
var checks:=0
var failed:=0
func check(ok:bool,label:String)->void:
    checks+=1
    if not ok:failed+=1;print("FAIL: ",label)
func _initialize()->void:
    for mode in [true,false]:
        var t=Two.new();t.single=mode;t.locked_a=true;t.reverse_seen=true;t.support_site="carried"
        var restored=Two.new();restored.single=mode
        check(restored.restore_checkpoint(t.checkpoint()),"carried support checkpoint accepts legal state")
        check(restored.support_site=="carried" and restored.locked_a,"same support and fixed first leaf survive restart")
        t.support_site="b";t.lifted_b=true;t.rear_loaded_seen=true;t.actions[0]="brace"
        restored=Two.new();restored.single=mode
        check(restored.restore_checkpoint(t.checkpoint()),"installed rear support checkpoint restores")
        check(restored.support_site=="b" and restored.rear_loaded_seen and not restored.lifted_b and restored.actions[0]=="","mid-operation load resets but physical support stays installed")
        var bad=t.checkpoint();bad.facts.locked_a=false
        var safe=Two.new();safe.single=mode
        check(not safe.restore_checkpoint(bad) and safe.support_site=="a","impossible support transfer rejected before mutation")
        var s=Three.new();s.single=mode;s.wick_found=true;s.wick_ready=true;s.wick_fitted=true;s.door_angle=1;s.npc_called=true;s.door_open=true;s.joined=true;s.light_equipped=true;s.cat_lock=true;s.phase="walkway";s.board_angle=1
        s.beam_held=true;s.actions[2]="light";s.positions[1]=s.LOCK;s.positions[2]=s.LIGHT_STAND;s.beam_direction=Vector2.UP
        var three=Three.new();three.single=mode
        check(three.restore_checkpoint(s.checkpoint()),"opened mechanical lock is a valid intermediate checkpoint")
        check(three.cat_lock and not three.beam_held and three.actions[2]=="" and three.positions[1].x<700,"restoring in-flight light keeps mechanism and returns cat to real floor")
        s.bridge_locked=true;s.light_released=true;s.narrow_open=true;s.rig_ready=true;s.rig_angle=1;s.source_level=1;s.high_mirror_angle=0;s.exit_low_latched=true;s.phase="exit"
        three=Three.new();three.single=mode
        check(three.restore_checkpoint(s.checkpoint()) and three.rig_angle==1 and three.source_level==1 and three.high_mirror_angle==0 and three.exit_low_latched,"chosen height and mirrors plus witnessed low lock survive restart")
        check(not three.beam_held and not three.exit_revealed,"restoring configured mirror cannot fabricate light or solved exit")
    print("M27_TWO_THREE_CHECKPOINT: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
