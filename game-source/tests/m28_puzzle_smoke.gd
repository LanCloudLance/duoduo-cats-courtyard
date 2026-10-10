extends SceneTree
func _init()->void:
    var dir:=OS.get_user_data_dir()
    print("USERDIR ",dir)
    if not dir.ends_with("DuoduoCatsCourtyard-qa-m28-puzzle"):
        push_error("unsafe QA namespace");quit(2);return
    for path in ["prologue_state","chapter_one_state","chapter_two_state","chapter_three_state","chapter_four_state","chapter_five_state"]:
        var script=load("res://game/"+path+".gd")
        if script==null:quit(3);return
        var state=script.new()
        var data:Dictionary=state.checkpoint()
        if not state.restore_checkpoint(data):push_error("roundtrip "+path);quit(4);return
        print("ROUNDTRIP ",path)
    quit(0)
