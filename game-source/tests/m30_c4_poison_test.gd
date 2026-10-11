extends SceneTree
const Four=preload("res://game/chapter_four_state.gd")
var checks:=0
var failed:=0
func _init()->void:
    if OS.get_user_data_dir().get_file()!="DuoduoCatsCourtyard-qa-m30-puzzle":quit(2);return
    var s=Four.new();var base:Dictionary=s.checkpoint()
    for key in ["puzzle_revision","version","chapter","mode"]:
        for wrong in [null,true,"bad",[],{},1.5]:
            var bad:Dictionary=base.duplicate(true);bad[key]=wrong
            checks+=1
            if s.restore_checkpoint(bad) or s.checkpoint()!=base:failed+=1;print("FAIL reject poison metadata ",key," type=",typeof(wrong))
    print("M30_C4_POISON: %d checks, %d failures; any SCRIPT ERROR also fails QA"%[checks,failed]);quit(1 if failed else 0)
