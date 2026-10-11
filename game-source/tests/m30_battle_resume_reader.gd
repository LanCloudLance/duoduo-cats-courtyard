extends SceneTree
const Store=preload("res://game/battle_journey.gd")
const Battle=preload("res://game/battle_state.gd")
var checks:=0
var failed:=0
func check(value:bool,label:String)->void:
    checks+=1
    if not value:failed+=1;print("FAIL ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
    check(OS.get_user_data_dir().get_file()=="DuoduoCatsCourtyard-qa-m30-combat","fresh process actual isolated QA namespace")
    if failed:quit(2);return
    var store=Store.new()
    for single in [true,false]:
        for id in ["shell","reserve"]:
            var context={"id":id,"encounter_revision":2,"mode":"solo" if single else "dual","available_role_ids":[0,1,2],"selected_role_id":0,"current_cat":2,"story_run_id":"story-run-300-1","return_chapter":4,"return_phase":"battle_one" if id=="shell" else "battle_two"}
            var result=store.read(context)
            check(result.get("encounter_revision")==2 and result.get("route_open")==true,"fresh process reads witnessed route")
            context.merge(result,true);var b=Battle.new()
            check(b.configure(context) and b.phase=="clear" and b.Space.valid(b.Space.GATE,18),"opened route restores actual passable gate and safe phase")
            check(b.enemies.is_empty() and b.hazards.is_empty(),"restored durable goal adds no repeat threat")
            var other=context.duplicate();other.story_run_id="story-run-300-99"
            check(store.read(other).is_empty(),"other run cannot inherit opened gate")
    var old_context={"id":"shell","encounter_revision":2,"mode":"solo","available_role_ids":[0,1,2],"selected_role_id":0,"current_cat":1,"story_run_id":"story-run-300-2","return_chapter":4,"return_phase":"battle_one"}
    var old=store.read(old_context)
    check(old.get("encounter_revision")==1 and old.get("cleared_segments")==1,"old missing revision explicitly overrides requested new rule")
    old_context.merge(old,true);var b=Battle.new()
    check(b.configure(old_context) and b.phase=="intermission" and not b.Space.route_enabled,"old actual safe segment retains original rules")
    b.interact(0);check(b.phase=="combat" and b.wave==2,"old remaining wave really resumes")
    print("M30_BATTLE_RESUME_READER: ",checks," checks, ",failed," failed");quit(1 if failed else 0)
