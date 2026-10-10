extends SceneTree
const Session=preload("res://input/session_state.gd")
const Router=preload("res://input/event_router.gd")
const Arena=preload("res://game/arena.gd")
const Pilot=preload("res://tests/m28_combat_driver.gd")
const Store=preload("res://game/battle_journey.gd")
var checks:=0
var failed:=0
func check(value:bool,label:String)->void:
    checks+=1
    if not value:failed+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
    check(OS.get_user_data_dir().get_file()=="DuoduoCatsCourtyard-qa-m28-root","actual isolated QA namespace")
    if failed:quit(1);return
    var session=Session.new();session.devices.assign([10,11]);session.ready_flags.assign([true,true]);session.single_player=true
    var router=Router.new(session)
    var host=Control.new();host.theme=Theme.new();host.theme.default_font=ThemeDB.fallback_font;root.add_child(host)
    var arena=Arena.new(session);host.add_child(arena);arena.set_physics_process(false)
    var pilot=Pilot.new();pilot.router=router;pilot.arena=arena;root.add_child(pilot)
    router.action_pressed.connect(arena.handle_action);router.action_released.connect(arena.release_action);router.actions_cancelled.connect(arena.cancel_inputs)
    var context:Dictionary={"id":"first","mode":"solo","available_role_ids":[0,1],"selected_role_id":0,"current_cat":1,"story_run_id":"story-run-280-1","return_chapter":1,"return_phase":"battle"}
    check(arena.configure(context),"ordinary encounter configuration accepted");arena.set_active(true)
    for i in range(6000):
        pilot.frame()
        if arena.battle.cleared_segments==1:break
    check(arena.battle.cleared_segments==1,"normal InputEvents actually clear first segment")
    var store=Store.new()
    check(store.save(arena.result()),"safe segment writes atomically")
    var durable:Dictionary=store.read(context)
    check(durable.get("cleared_segments")==1,"durable segment reads back")
    var before:String=FileAccess.get_file_as_string(store.path(context))
    var invalid:Dictionary=arena.result();invalid.completed_segments=3
    check(not store.save(invalid) and FileAccess.get_file_as_string(store.path(context))==before,"invalid segment cannot mutate prior save")
    var other:Dictionary=context.duplicate();other.mode="dual"
    check(store.read(other).is_empty(),"different player mode never imports solo segment")
    pilot.queue_free();host.queue_free();await process_frame;await process_frame
    print("M28_BATTLE_RESUME_WRITER: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
