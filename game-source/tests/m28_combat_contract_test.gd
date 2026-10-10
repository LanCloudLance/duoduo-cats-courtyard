extends SceneTree
const Battle=preload("res://game/battle_state.gd")
const Arena=preload("res://game/arena.gd")
const Session=preload("res://input/session_state.gd")
const Router=preload("res://input/event_router.gd")
var checks:=0
var failed:=0
var arena
var router
var session
func expect(value: bool,label: String) -> void:
    checks+=1
    if not value:failed+=1;print("FAIL ",label)
func context(id: String="shell",role: int=0,mode: String="solo") -> Dictionary:
    return {"id":id,"mode":mode,"available_role_ids":[0,1] if id=="first" else [0,1,2],"selected_role_id":role,"current_cat":1,"story_run_id":"qa-only","return_chapter":4,"return_phase":"battle"}
func tick(b,seconds: float,p1:=Vector2.ZERO,p2:=Vector2.ZERO) -> void:
    for _i in range(ceili(seconds*60)):b.step(1.0/60.0,p1,p2,true)
func fixture(role: int=0,mode: String="solo"):
    var b=Battle.new();b.configure(context("shell",role,mode));b.phase="combat";b.positions[b.actor(0)]=Vector2(400,470)
    b._spawn("weaver",Vector2(455,470),false)
    b.enemies[0].mode="rest";b.enemies[0].timer=9
    return b
func key(code: int,pressed: bool=true) -> void:
    var e=InputEventKey.new();e.physical_keycode=code;e.pressed=pressed;router.handle(e)
func tap(code: int) -> void:key(code);key(code,false)
func _initialize() -> void:call_deferred("run")
func run() -> void:
    print("QA_USER_DIR ",OS.get_user_data_dir())
    expect(OS.get_user_data_dir().ends_with("DuoduoCatsCourtyard-qa-m28-combat"),"isolated actual OS namespace")
    var b=Battle.new();expect(b.configure(context()),"configure")
    expect(b.deployed_slots()==[0] and b.actor(1)==-1,"one entity")
    expect(b.nearest_slot(b.positions[1])==0,"reserve excluded from targets")
    var saved=b.result();expect(not b.configure(context("first",2)),"unjoined role rejected")
    expect(b.result()==saved,"invalid configure atomic")
    b.hp[0]=2;b.attack_cooldown[0]=0.22;b.signature_cooldown[0]=0.7;b.dodge_cooldown[0]=0.5;b.invulnerable[0]=0.6;b.facing[0]=Vector2.UP;b.velocity[0]=Vector2(12,8);var point: Vector2=b.positions[0]
    expect(b.request_switch(0),"manual swap accepted")
    expect(b.actor(0)==1 and b.positions[1]==point and b.hp[0]==2,"swap preserves position and shared HP")
    expect(b.attack_cooldown[0]==0.22 and b.signature_cooldown[0]==0.7 and b.dodge_cooldown[0]==0.5 and b.invulnerable[0]==0.6,"swap preserves resource timers")
    expect(b.facing[0]==Vector2.UP and b.velocity[0]==Vector2(12,8),"swap preserves facing/motion")
    expect(not b.request_switch(0),"swap cooldown rejects repeat")
    for role in [0,1,2]:
        b=fixture(role);var enemy=b.enemies[0];b.attack(0);tick(b,0.12)
        expect(enemy.hp<5,"role %d basic damages"%role)
        expect(b.attacks.kinds[0]==["sword","claw","slap"][role],"distinct basic identity %d"%role)
    b=fixture(1);var e=b.enemies[0];e.mode="cast";e.timer=0.3;e.aim=b.positions[1]
    b.signature(0);tick(b,0.2)
    expect(e.mode=="rest" and not e.has("aim"),"pounce cancels casting instance")
    tick(b,0.3);expect(b.hazards.is_empty(),"cancelled cast cannot create hazard")
    b=fixture(2);b.signature(0);tick(b,0.20);b.release_signature(0);tick(b,0.2)
    expect(b.enemies[0].hp==5 and b.attacks.pending[0]<0,"early release no donated slap")
    b.signature(0);tick(b,0.45);b.release_signature(0);tick(b,0.11)
    expect(b.enemies[0].hp==2 and b.enemies[0].get("control_time",0)>0,"charged heavy distinct 3 damage/control")
    b=fixture(0);b.attack(0);b.request_switch(0)
    expect(b.actor(0)==0,"swap not erase startup")
    tick(b,0.16)
    expect(b.enemies[0].hp==4 and b.actor(0)==1,"queued swap after one completed basic")
    expect(b.attack_cooldown[0]>0,"queued swap retains recovery")
    b=fixture(0);b.attack(0);b.signature(0)
    expect(b.guard_held and not b.guarding,"held shield waits through sword startup")
    tick(b,0.20);expect(b.guarding,"held shield raises after active contact")
    b=fixture(0);b.signature(0);expect(b.guarding,"girl shield")
    b.request_switch(0);expect(not b.guarding and not b.guard_held,"reserve cannot keep shield")
    b=fixture();b.hp[0]=0;tick(b,0.8)
    expect(b.phase=="failed" and b.hp[1]==3 and b.retries==0,"no AI/downed dummy rescue")
    expect(b.request_switch(0) and b.actor(0)==1,"failed choice remains manual")
    b.interact(0);expect(b.phase=="combat" and b.retries==1 and b.hp[0]==3,"explicit local retry")
    b=fixture(0,"dual");expect(b.deployed_slots()==[0,1] and b.roster.reserves()==[2],"dual real pair plus one reserve")
    expect(not b.request_switch(0) and b.request_switch(1) and b.actor(1)==2,"dual only P2 selects cat")
    b.hp[1]=0;b.positions[2]=b.positions[0]+Vector2(0,50);b.interact(0);tick(b,1.25)
    expect(b.hp[1]==2,"dual manual rescue")
    var layouts=[]
    for id in ["first","shell","reserve"]:
        b=Battle.new();b.configure(context(id));layouts.append(b.Space.STUMPS.duplicate());b.interact(0)
        expect(b.enemies.size()>=2 and b.enemies.size()<=3,"bounded bodies "+id)
        expect(b.enemies.all(func(enemy):return enemy.pos.distance_to(b.positions[b.actor(0)])>=190),"arrival distance "+id)
    expect(layouts[0]!=layouts[1] and layouts[1]!=layouts[2],"three distinct layouts")
    for role in [0,1,2]:
        b=Battle.new();b.configure(context("reserve",role));b.phase="combat"
        var obstacle: Vector2=b.Space.STUMPS[0]
        b.positions[role]=obstacle-Vector2(120,0);b._spawn("armored",obstacle+Vector2(190,0),false)
        tick(b,3.0)
        expect(b.enemies[0].mode=="exposed" and b.enemies[0].opening=="stump" and b.hp[0]==3,"role %d can bait stump without shield"%role)
    b=fixture();b.cleared_segments=1;b.wave=2;b.hp[0]=0;b.hurt_time[0]=0.22;tick(b,0.8)
    expect(b.request_switch(0) and b.actor(0)==1,"failed hurt lock cannot prevent role choice")
    b.interact(0)
    expect(b.wave==2 and b.cleared_segments==1 and b.result().completed_segments==1,"retry preserves completed segment")
    var resumed=Battle.new();var resume_context=context();resume_context.cleared_segments=1
    expect(resumed.configure(resume_context) and resumed.phase=="intermission","resume returns between verified segments")
    resumed.interact(0);expect(resumed.wave==2,"resume only remaining segment")
    # Paired counterfactual: same cat input with or without a human-raised shield.
    var partnership=[]
    for shield in [false,true]:
        b=Battle.new();b.configure(context("reserve",0,"dual"));b.phase="combat"
        b.positions[0]=Vector2(400,630);b.positions[1]=Vector2(560,630)
        b._spawn("armored",Vector2(500,630),false)
        var shell=b.enemies[0];shell.mode="rush";shell.direction=Vector2.LEFT;shell.timer=0.48
        b.facing[0]=Vector2.RIGHT;b.facing[1]=Vector2.LEFT
        if shield:b.signature(0)
        tick(b,0.133,Vector2.ZERO,Vector2.LEFT)
        b.attack(1);tick(b,0.06)
        partnership.append({"hp":shell.hp,"girl_hp":b.hp[0],"opening":shell.opening})
    expect(partnership[1].hp<partnership[0].hp and partnership[1].opening=="shield","human shield creates cat rear opening")
    expect(partnership[1].girl_hp==3,"cooperation does not trade free HP")
    b=fixture(0,"dual");b.request_switch(1);b.signature(1);b.attack(0);tick(b,0.2);b.attack(0)
    expect(b.attacks.charging and b.attacks.buffered[0]>0,"P2 charge does not block P1 buffer")
    session=Session.new();session.single_player=true;session.keyboard_mode=true;session.ready_flags.assign([true,false])
    router=Router.new(session);arena=Arena.new(session);arena.configure(context("shell",2))
    var host=Control.new();host.theme=Theme.new();host.theme.default_font=ThemeDB.fallback_font;root.add_child(host);host.add_child(arena);arena.set_active(true);arena.set_physics_process(false)
    router.action_pressed.connect(arena.handle_action);router.action_released.connect(arena.release_action);router.actions_cancelled.connect(arena.cancel_inputs)
    key(KEY_D);tap(KEY_TAB)
    expect(session.movement(0).x>0.9 and arena.battle.actor(0)==0,"ordinary swap keeps held move")
    key(KEY_D,false);tick(arena.battle,0.7)
    tap(KEY_TAB);tick(arena.battle,0.7);tap(KEY_TAB);tick(arena.battle,0.7)
    key(KEY_G);tick(arena.battle,0.46);tap(KEY_TAB);key(KEY_G,false)
    expect(arena.battle.actor(0)==0 and not arena.battle.attacks.charging and arena.battle.attacks.pending[0]<0,"stale heavy release cannot belong to new actor")
    tick(arena.battle,0.7);tap(KEY_TAB);tick(arena.battle,0.7);tap(KEY_TAB);key(KEY_G);tick(arena.battle,0.46);tap(KEY_ESCAPE);key(KEY_G,false)
    expect(not arena.battle.attacks.charging and arena.held_actions.is_empty() and session.axes[0]==Vector2.ZERO,"pause clears ownership and queue")
    session.keyboard_mode=false;session.devices.assign([5,-1]);session.ready_flags.assign([true,false])
    var pad=InputEventJoypadButton.new();pad.device=5;pad.button_index=JOY_BUTTON_DPAD_RIGHT;pad.pressed=true;router.handle(pad)
    expect(session.movement(0).x>0.9,"Dpad ordinary event moves")
    pad.pressed=false;router.handle(pad);expect(session.movement(0)==Vector2.ZERO,"Dpad release stops")
    pad.pressed=true;router.handle(pad)
    var menu=InputEventJoypadButton.new();menu.device=5;menu.button_index=JOY_BUTTON_START;menu.pressed=true;router.handle(menu)
    pad.pressed=false;router.handle(pad);router.handle(menu)
    expect(session.running() and router.dpad.is_empty() and session.movement(0)==Vector2.ZERO,"menu pause/resume cannot resurrect held Dpad")
    arena.shake_enabled=false;arena.rumble_enabled=true;arena.impact_shake=0.1;arena._physics_process(1.0/60.0)
    expect(arena.camera.offset==Vector2.ZERO and arena.rumble_enabled,"shake/rumble independent")
    print("M28_COMBAT_CONTRACT: ",checks," checks, ",failed," failed")
    quit(1 if failed else 0)
