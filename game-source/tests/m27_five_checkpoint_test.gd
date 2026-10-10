extends SceneTree
const Five=preload("res://game/chapter_five_state.gd")
const Checkpoint=preload("res://game/story_checkpoint.gd")
var failed:=0
var checks:=0
func check(value:bool,label:String)->void:
    checks+=1
    if not value:failed+=1;push_error(label)
func _initialize()->void:
    var s=Five.new();s.restore_complete()
    var value:Dictionary=Checkpoint.capture(s)
    var restored=Five.new()
    check(Checkpoint.restore(restored,value),"capture after legacy completed restore remains valid")
    check(restored.extras.get("wood_lamp")==true and restored.extras.get("outward_verified")==true and restored.extras.get("home_finished")==true,"checkpoint restore rebuilds earned ending evidence metadata")
    for name in ["lure","unjam","shield"]:
        var malformed:Dictionary=value.duplicate(true);malformed.phase=name;malformed.completed=false
        check(not Checkpoint.restore(Five.new(),malformed),"incompatible completed facts cannot restore early phase "+name)
    print("M27_FIVE_CHECKPOINT: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
