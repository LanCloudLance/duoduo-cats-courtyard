extends SceneTree
const Arena=preload("res://game/arena.gd")
const Session=preload("res://input/session_state.gd")
const Router=preload("res://input/event_router.gd")
const Pilot=preload("res://tests/m28_combat_driver.gd")
var failed:=0
func _initialize() -> void:call_deferred("run")
func run() -> void:
    print("QA_USER_DIR ",OS.get_user_data_dir())
    if not OS.get_user_data_dir().ends_with("DuoduoCatsCourtyard-qa-m28-combat"):quit(2);return
    var s=Session.new();s.single_player=true;s.devices.assign([10,-1]);s.ready_flags.assign([true,false])
    var router=Router.new(s)
    var host=Control.new();host.theme=Theme.new();host.theme.default_font=ThemeDB.fallback_font;root.add_child(host)
    var arena=Arena.new(s);host.add_child(arena);arena.set_physics_process(false)
    var pilot=Pilot.new();pilot.router=router;pilot.arena=arena;root.add_child(pilot)
    router.action_pressed.connect(arena.handle_action);router.action_released.connect(arena.release_action);router.actions_cancelled.connect(arena.cancel_inputs)
    var results=[]
    for role in [0,1,2]:
        for priority in ["nearest","backline"]:
            pilot.reset();pilot.target_order=priority;pilot.basic_only=true
            arena.configure({"id":"shell","mode":"solo","available_role_ids":[0,1,2],"selected_role_id":role,"current_cat":1});arena.set_active(true)
            var blocked:=0;var damage:=0;var previous_hp:=3;var peak_hazards:=0;var cursor:=0
            for frame in range(7200):
                pilot.frame()
                peak_hazards=maxi(peak_hazards,arena.battle.hazards.size())
                damage+=maxi(0,previous_hp-arena.battle.hp[0]);previous_hp=arena.battle.hp[0]
                for f in arena.battle.feedback_since(cursor):
                    if f.kind=="blocked":blocked+=1
                cursor=arena.battle.feedback_id
                if arena.battle.phase=="complete" or arena.battle.retries>1:break
            var row={"role":role,"priority":priority,"complete":arena.battle.phase=="complete","seconds":snappedf(pilot.elapsed,0.1),"damage":damage,"blocked":blocked,"peak_hazards":peak_hazards,"retries":arena.battle.retries}
            results.append(row);print("STRATEGY ",JSON.stringify(row))
            if not row.complete or (priority=="backline" and row.retries>0):failed+=1
    if results[0].blocked<=results[1].blocked:failed+=1;print("FAIL target priority did not change blocked work")
    print("M28_COMBAT_STRATEGY: 6 full input paths and priority comparison, ",failed," failed")
    quit(1 if failed else 0)
