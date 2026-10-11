extends SceneTree
var checks:=0
var failed:=0
func reject(s,data:Dictionary,label:String)->void:
    var before:Dictionary=s.checkpoint()
    checks+=1
    if s.restore_checkpoint(data) or s.checkpoint()!=before:
        failed+=1;print("FAIL ",label)
func _init()->void:
    if not OS.get_user_data_dir().ends_with("DuoduoCatsCourtyard-qa-m29-puzzle"):quit(2);return
    for name in ["prologue","chapter_one","chapter_two","chapter_three","chapter_four","chapter_five"]:
        var s=load("res://game/"+name+"_state.gd").new()
        for solo in [true,false]:
            s.single=solo
            var valid:Dictionary=s.checkpoint()
            var d:Dictionary=valid.duplicate(true);d.mode="dual" if solo else "solo";reject(s,d,name+" cross mode")
            d=valid.duplicate(true);d.phase="invented";reject(s,d,name+" unknown phase")
            d=valid.duplicate(true);d.completed=true;reject(s,d,name+" fake complete")
            d=valid.duplicate(true);d.positions[0][0]=INF;reject(s,d,name+" infinite coordinate")
            d=valid.duplicate(true);d.positions[0][0]=-10000;reject(s,d,name+" out of world")
            d=valid.duplicate(true);d.history=[42];reject(s,d,name+" invalid history")
            d=valid.duplicate(true);d.facts="corrupt";reject(s,d,name+" corrupt fact shape")
            d=valid.duplicate(true);d.puzzle_revision=999;reject(s,d,name+" future revision")
            var extension:String="puzzle_facts" if name in ["prologue","chapter_one"] else "facts"
            for key in valid[extension]:
                d=valid.duplicate(true);d[extension].erase(key);reject(s,d,name+" missing "+key)
                d=valid.duplicate(true);d[extension][key]=["invalid"];reject(s,d,name+" invalid "+key)
            if name=="chapter_one":
                d=valid.duplicate(true);d.puzzle_facts.nightlight_taken=true;reject(s,d,"ungifted nightlight")
                d=valid.duplicate(true);d.puzzle_facts.cloth_found=true;reject(s,d,"unexplored cloth")
            elif name=="chapter_two":
                d=valid.duplicate(true);d.facts.outer_locked=true;reject(s,d,"far platform before front bridge")
            elif name=="chapter_three":
                d=valid.duplicate(true);d.facts.map_discovered=true;reject(s,d,"map before optical alcove")
            elif name=="chapter_four":
                d=valid.duplicate(true);d.facts.stall_seen=true;reject(s,d,"merchant benefit without independent light")
            elif name=="chapter_five":
                for key in ["far_walkway","isolation_open","pilot_open","left_released","cat_one_clean"]:
                    d=valid.duplicate(true);d.facts[key]=true;reject(s,d,"impossible "+key)
    print("M29_PUZZLE_INVALID ",checks," checks / ",failed," failures; all validation before live mutation")
    quit(1 if failed else 0)
