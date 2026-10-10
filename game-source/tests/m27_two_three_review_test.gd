extends SceneTree
const Two=preload("res://game/chapter_two_state.gd")
const Three=preload("res://game/chapter_three_state.gd")
var checks:=0
var failed:=0
func check(ok:bool,label:String)->void:
    checks+=1
    if not ok:failed+=1;print("FAIL: ",label)
func use(s,role:int,p:Vector2)->void:
    s.positions[role]=p;s.action_time[role]=0;s.interact(role)
func _initialize()->void:
    for mode in [true,false]:
        var two=Two.new();two.single=mode;two.restore_complete();two.finished=false;two.phase="window"
        use(two,1,two.LATCH_B)
        check(two.phase=="window","revisiting completed rear latch preserves window phase")
        var restored_two=Two.new();restored_two.single=mode
        check(restored_two.restore_checkpoint(two.checkpoint()) and restored_two.phase=="window","rear latch revisit saves and resumes the same milestone")
        use(two,1,two.LATCH_A)
        check(two.phase=="window" and two.shortcut_open,"revisiting front latch cannot undo later route")
        var three=Three.new();three.single=mode;three.restore_complete();three.finished=false;three.phase="map"
        use(three,0,three.EQUIPMENT)
        check(three.phase=="map","revisiting equipped rack preserves map phase")
        var restored_three=Three.new();restored_three.single=mode
        check(restored_three.restore_checkpoint(three.checkpoint()) and restored_three.phase=="map","rack revisit saves and resumes latest physical milestone")
        three.phase="exit";three.exit_revealed=false;three.exit_high_latched=false
        use(three,0,three.EQUIPMENT)
        check(three.phase=="exit","equipped rack cannot regress fixed bridge stage")
    print("M27_TWO_THREE_REVIEW: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
