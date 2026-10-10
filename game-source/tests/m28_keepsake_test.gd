extends SceneTree
const State=preload("res://game/chapter_five_state.gd")
var checks:=0
var failed:=0
func check(value:bool,label:String)->void:
    checks+=1
    if not value:failed+=1;printerr("FAIL: "+label)
func _init()->void:call_deferred("run")
func run()->void:
    check(OS.get_user_data_dir().get_file()=="DuoduoCatsCourtyard-qa-m28-root","actual isolated namespace")
    if failed:quit(1);return
    var s=State.new();s.phase="home";s.positions[0]=s.HOME_TABLE
    s.interact(0)
    check(s.dialogue.is_empty() and s.message.contains("空出"),"unearned table gives no invented memory")
    s.journey_discoveries.assign(["four_stall","four_view"])
    s.interact(0)
    check(s.dialogue.size()==2 and s.dialogue[0].contains("摊主") and not s.dialogue[0].contains("钟楼"),"stall memory recalls only actual help")
    while s.dialogue_active():s.advance_dialogue()
    s.interact(0)
    check(s.dialogue[0].contains("钟楼") and not s.dialogue[0].contains("摊主"),"next earned keepsake recalls different place")
    while s.dialogue_active():s.advance_dialogue()
    s.interact(0)
    check(s.dialogue[0].contains("摊主"),"browsing cycles actual finds without replaying an unearned place")
    print("M28_KEEPSAKE: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
