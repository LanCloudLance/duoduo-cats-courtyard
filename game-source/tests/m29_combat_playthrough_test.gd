extends SceneTree
const Arena=preload("res://game/arena.gd")
const Session=preload("res://input/session_state.gd")
const Router=preload("res://input/event_router.gd")
const Pilot=preload("res://tests/m29_combat_driver.gd")
var failed:=0
func _initialize() -> void:call_deferred("run")
func run() -> void:
    print("QA_USER_DIR ",OS.get_user_data_dir())
    if not OS.get_user_data_dir().ends_with("DuoduoCatsCourtyard-qa-m29-combat"):quit(2);return
    var session=Session.new();session.devices.assign([10,11]);session.ready_flags.assign([true,true])
    var router=Router.new(session)
    var host=Control.new();host.theme=Theme.new();host.theme.default_font=ThemeDB.fallback_font;root.add_child(host)
    var arena=Arena.new(session);host.add_child(arena);arena.set_physics_process(false)
    var pilot=Pilot.new();pilot.router=router;pilot.arena=arena;root.add_child(pilot)
    router.action_pressed.connect(arena.handle_action);router.action_released.connect(arena.release_action);router.actions_cancelled.connect(arena.cancel_inputs)
    var cases=[]
    for basic in [true,false]:
        for id in ["first","shell","reserve"]:
            for role in ([0,1] if id=="first" else [0,1,2]):cases.append({"id":id,"role":role,"solo":true,"basic":basic})
    for id in ["first","shell","reserve"]:
        for cat in ([1] if id=="first" else [1,2]):cases.append({"id":id,"role":cat,"solo":false,"basic":false})
    for c in cases:
        session.single_player=c.solo;session.ready_flags.assign([true,true]);pilot.reset();pilot.basic_only=c.basic
        var ok: bool=arena.configure({"id":c.id,"mode":"solo" if c.solo else "dual","available_role_ids":[0,1] if c.id=="first" else [0,1,2],"selected_role_id":c.role,"current_cat":c.role if c.role>0 else 1})
        arena.set_active(true)
        var damage:=0
        var minimum_hp:=3
        var previous_hp: int=arena.battle.hp[0]+(arena.battle.hp[1] if not c.solo else 0)
        for i in range(7200):
            pilot.frame()
            var now: int=arena.battle.hp[0]+(arena.battle.hp[1] if not c.solo else 0)
            damage+=maxi(0,previous_hp-now);previous_hp=now;minimum_hp=mini(minimum_hp,arena.battle.hp[0])
            if i%300==0:arena._sync_actors(1.0/60);arena._refresh()
            if arena.battle.phase=="complete" or arena.battle.retries>2:break
        var success: bool=ok and arena.result().outcome=="complete"
        if not success:failed+=1
        print("PLAY ",JSON.stringify(c)," success=",success," seconds=",snappedf(pilot.elapsed,0.1)," damage=",damage," retries=",arena.battle.retries," basics=",pilot.attack_events," skills=",pilot.signature_events," dodges=",pilot.dodge_events," phase=",arena.battle.phase," wave=",arena.battle.wave," hp=",arena.battle.hp)
        if not success:
            print("REMAIN ",arena.battle.enemies," position=",arena.battle.positions)
    print("M29_COMBAT_PLAYTHROUGH: ",cases.size()," complete paths, ",failed," failed")
    quit(1 if failed else 0)
