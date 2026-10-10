extends SceneTree
const Five=preload("res://game/chapter_five_state.gd")
var checks:=0
var failed:=0
func check(ok:bool,label:String)->void:
    checks+=1
    if not ok:failed+=1;push_error("FAIL: "+label)
func _init()->void:
    if not OS.get_user_data_dir().get_file() in ["DuoduoCatsCourtyard-qa-m28-portable","DuoduoCatsCourtyard-qa-m28-puzzle"]:quit(2);return
    for solo in [true,false]:
        for route in [0,1]:
            var s=Five.new();s.single=solo;s.restore_complete();s.finished=false;s.phase="test";s.tested=false;s.network_lit=false;s.tag_inserted=false;s.gear_stored=false;s.paws_clean=false;s.cat_one_clean=false;s.cat_two_clean=false
            s.pilot_route=route;s.positions[0]=s.selected_test_end();s.positions[2]=s.TEST_SOURCE;s.facing[2]=Vector2.RIGHT;s.actions[2]="light";s.beam_held=true
            s.interact(0);var at:Vector2=s.positions[0]
            check(s.pilot_waiting and s.actions[0]=="hold" and not s.tested,"explicit observation asks girl to wait while portable light remains")
            if solo:s.switch_actor();s.switch_actor()
            else:s.switch_cat()
            for i in range(120):s.step(.05,Vector2.ZERO,Vector2.ZERO,true)
            check(s.positions[0]==at and s.pilot_waiting,"girl does not follow switched cat away from observed endpoint across six seconds")
            s.tool(2)
            for i in range(80):s.step(.05,Vector2.ZERO,Vector2.ZERO,true)
            check(not s.beam_held and s.positions[0]==at and s.pilot_waiting,"withdrawn beam leaves waiting girl at real endpoint for confirmation")
            var probe=Five.new();probe.single=solo;probe.pilot_waiting=true
            check(probe.restore_checkpoint(s.checkpoint()) and not probe.pilot_waiting,"checkpoint never resumes transient observation wait")
            s.controlled=0;s.step(.05,Vector2.DOWN,Vector2.ZERO,true)
            check(not s.pilot_waiting and s.positions[0]!=at,"girl's own movement deliberately releases waiting stance")
            s.positions[0]=at;s.action_time[0]=0;s.interact(0)
            check(s.tested and s.phase=="release" and not s.pilot_waiting,"normal endpoint confirmation ends wait and advances pilot")
    for route in [0,1]:
        var s=Five.new();s.phase="test";s.arm_locked=true;s.arm_route=route;s.positions[0]=s.WHEEL
        for i in range(100):
            var offset:Vector2=s.ALIGHT-s.positions[0]
            if offset.length()<.1:break
            s.move(0,offset.normalized()*minf(5,offset.length()))
        check(s.positions[0].distance_to(s.ALIGHT)<.1,"wheel to Alight eastern entry remains open in both shield plans")
        check(s.walkable(Vector2(900,478),0) and s.walkable(Vector2(1045,478),0),"front eastern decking collision matches permanent presentation")
        check(s.walkable(Vector2(750,478),0)==(route==1),"only western shortcut entrance depends on far shield plan")
    print("M28_PUZZLE_PILOT_WAIT: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
