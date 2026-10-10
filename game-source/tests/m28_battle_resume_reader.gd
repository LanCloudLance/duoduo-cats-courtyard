extends SceneTree
const Store=preload("res://game/battle_journey.gd")
const Battle=preload("res://game/battle_state.gd")
var checks:=0
var failed:=0
func check(value:bool,label:String)->void:
    checks+=1
    if not value:failed+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
    check(OS.get_user_data_dir().get_file()=="DuoduoCatsCourtyard-qa-m28-root","fresh process actual isolated QA namespace")
    if failed:quit(1);return
    var context:Dictionary={"id":"first","mode":"solo","available_role_ids":[0,1],"selected_role_id":0,"current_cat":1,"story_run_id":"story-run-280-1","return_chapter":1,"return_phase":"battle"}
    var store=Store.new();var durable:Dictionary=store.read(context)
    check(durable.get("cleared_segments")==1,"new process reads actual earlier victory")
    context.merge(durable,true)
    var battle=Battle.new()
    check(battle.configure(context) and battle.phase=="intermission" and battle.cleared_segments==1,"new encounter restores completed segment without fake current victory")
    battle.intermission=0;battle.interact(0)
    check(battle.phase=="combat" and battle.wave==2,"continuation starts only uncleared segment")
    var different:Dictionary=context.duplicate();different.story_run_id="story-run-280-2"
    check(store.read(different).is_empty(),"new journey cannot inherit previous run's combat victory")
    print("M28_BATTLE_RESUME_READER: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
