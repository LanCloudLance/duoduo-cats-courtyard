extends SceneTree
const Session=preload("res://input/session_state.gd")
const Router=preload("res://input/event_router.gd")
const Arena=preload("res://game/arena.gd")
const Pilot=preload("res://tests/m30_combat_driver.gd")
const Store=preload("res://game/battle_journey.gd")
var checks:=0
var failed:=0
func check(value:bool,label:String)->void:
    checks+=1
    if not value:failed+=1;print("FAIL ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
    check(OS.get_user_data_dir().get_file()=="DuoduoCatsCourtyard-qa-m30-combat","actual isolated QA namespace")
    if failed:quit(2);return
    var s=Session.new();s.devices.assign([10,11]);s.ready_flags.assign([true,true])
    var router=Router.new(s);var host=Control.new();host.theme=Theme.new();host.theme.default_font=ThemeDB.fallback_font;root.add_child(host)
    var arena=Arena.new(s);host.add_child(arena);arena.set_physics_process(false)
    var pilot=Pilot.new();pilot.router=router;pilot.arena=arena;root.add_child(pilot)
    router.action_pressed.connect(arena.handle_action);router.action_released.connect(arena.release_action);router.actions_cancelled.connect(arena.cancel_inputs)
    var store=Store.new()
    for single in [true,false]:
        for id in ["shell","reserve"]:
            s.single_player=single;pilot.reset()
            var context={"id":id,"encounter_revision":2,"mode":"solo" if single else "dual","available_role_ids":[0,1,2],"selected_role_id":0,"current_cat":2,"story_run_id":"story-run-300-1","return_chapter":4,"return_phase":"battle_one" if id=="shell" else "battle_two"}
            check(arena.configure(context),"new encounter configured")
            check(store.save(arena.result()),"unopened new goal saves")
            var pending=store.read(context)
            check(pending.get("encounter_revision")==2 and pending.get("route_open")==false,"unopened read does not become an old wave")
            arena.set_active(true)
            for i in range(7200):
                pilot.frame()
                if arena.battle.route_open:break
            check(arena.battle.route_open and arena.battle.enemies.any(func(e):return e.hp>0),"ordinary inputs earn actual route with enemy surviving")
            check(store.save(arena.result()),"actual clear is atomically saved before exit")
            var before:String=FileAccess.get_file_as_string(store.path(context))
            var corrupt=arena.result();corrupt.route_open=false
            check(not store.save(corrupt) and FileAccess.get_file_as_string(store.path(context))==before,"contradictory save cannot overwrite real opened route")
    # Simulate an existing M28 record lacking both extension keys.
    var legacy={"encounter_id":"shell","mode":"solo","story_run_id":"story-run-300-2","return_chapter":4,"return_phase":"battle_one","completed_segments":1,"selected_role_id":2,"current_cat":2}
    check(store.save(legacy),"legacy record shape retained")
    pilot.queue_free();host.queue_free();await process_frame;await process_frame
    print("M30_BATTLE_RESUME_WRITER: ",checks," checks, ",failed," failed");quit(1 if failed else 0)
