extends SceneTree
const Arena=preload("res://game/arena.gd")
const Session=preload("res://input/session_state.gd")
const Router=preload("res://input/event_router.gd")
class KeyboardPilot extends "res://tests/m30_combat_driver.gd":
    func key(code:int,pressed:bool)->void:
        var e=InputEventKey.new();e.physical_keycode=code;e.pressed=pressed;send(e)
    func axis(slot:int,vector:Vector2)->void:
        var keys=[KEY_A,KEY_D,KEY_W,KEY_S] if slot==0 else [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]
        var down=[vector.x< -0.1,vector.x>0.1,vector.y< -0.1,vector.y>0.1]
        for i in range(4):key(keys[i],down[i])
    func button(slot:int,id:int,pressed:bool)->void:
        var keys={JOY_BUTTON_A:KEY_E,JOY_BUTTON_X:KEY_F,JOY_BUTTON_B:KEY_Q,JOY_BUTTON_Y:KEY_TAB,JOY_BUTTON_LEFT_SHOULDER:KEY_G} if slot==0 else {JOY_BUTTON_A:KEY_SPACE,JOY_BUTTON_X:KEY_J,JOY_BUTTON_B:KEY_K,JOY_BUTTON_Y:KEY_TAB,JOY_BUTTON_LEFT_SHOULDER:KEY_U}
        key(keys[id],pressed)
var failed:=0
func _initialize()->void:call_deferred("run")
func run()->void:
    if OS.get_user_data_dir().get_file()!="DuoduoCatsCourtyard-qa-m30-combat":quit(2);return
    var session=Session.new();session.keyboard_mode=true;session.ready_flags.assign([true,true]);var router=Router.new(session)
    var host=Control.new();host.theme=Theme.new();host.theme.default_font=ThemeDB.fallback_font;root.add_child(host)
    var arena=Arena.new(session);host.add_child(arena);arena.set_physics_process(false)
    var pilot=KeyboardPilot.new();pilot.router=router;pilot.arena=arena;root.add_child(pilot)
    router.action_pressed.connect(arena.handle_action);router.action_released.connect(arena.release_action);router.actions_cancelled.connect(arena.cancel_inputs)
    var paths:=0
    for delta in [1.0/60,0.05]:
        for c in [{"role":0,"solo":true},{"role":1,"solo":true},{"role":2,"solo":true},{"role":1,"solo":false},{"role":2,"solo":false}]:
            var role:int=c.role
            paths+=1;session.single_player=c.solo;session.ready_flags.assign([true,true]);pilot.reset();router.clear_keyboard()
            arena.configure({"id":"reserve","encounter_revision":2,"mode":"solo" if c.solo else "dual","available_role_ids":[0,1,2],"selected_role_id":role,"current_cat":role if role>0 else 1});arena.set_active(true)
            var trace=[];var old_mode:=""
            for i in range(1800):
                pilot.tick_index+=1;pilot.elapsed+=delta
                for slot in arena.battle.deployed_slots():pilot.pilot(slot)
                arena.battle.step(delta,session.movement(0),session.movement(1),true)
                for e in arena.battle.enemies:
                    if e.kind=="armored" and e.mode!=old_mode:
                        if e.mode in ["windup","rush","exposed"]:trace.append({"t":pilot.elapsed,"mode":e.mode,"enemy":str(e.pos),"player":str(arena.battle.positions[arena.battle.actor(0)]),"direction":str(e.direction),"cause":e.get("opening","")})
                        old_mode=e.mode
                if arena.battle.phase=="complete" or arena.battle.retries>2:break
            var ok:bool=arena.battle.phase=="complete"
            if not ok:failed+=1
            print("KEYPATH delta=",delta," role=",role," solo=",c.solo," success=",ok," retries=",arena.battle.retries," phase=",arena.battle.phase," route=",arena.battle.route_cause," time=",pilot.elapsed)
            print("KEYTRACE ",JSON.stringify(trace))
            if not ok:print("KEYSTATE positions=",arena.battle.positions," enemies=",arena.battle.enemies," axes=",session.axes)
    print("M30_KEYBOARD_COMBAT: ",paths," paths, ",failed," failed");quit(1 if failed else 0)
