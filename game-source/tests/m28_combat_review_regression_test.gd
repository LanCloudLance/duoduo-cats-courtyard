extends SceneTree
const Battle=preload("res://game/battle_state.gd")
const Arena=preload("res://game/arena.gd")
const Session=preload("res://input/session_state.gd")
var checks:=0
var failed:=0
func expect(ok: bool,label: String) -> void:
    checks+=1
    if not ok:failed+=1;print("FAIL ",label)
func context(id: String="reserve",role: int=0) -> Dictionary:
    return {"id":id,"mode":"solo","available_role_ids":[0,1] if id=="first" else [0,1,2],"selected_role_id":role,"current_cat":1}
func tick(b,seconds: float,p1:=Vector2.ZERO) -> void:
    for i in range(ceili(seconds*60)):b.step(1.0/60,p1,Vector2.ZERO,true)
func fixture(role: int=0):
    var b=Battle.new();b.configure(context("reserve",role));b.phase="combat";b.positions[role]=Vector2(400,620)
    b._spawn("weaver",Vector2(460,620),false);b.enemies[0].mode="rest";b.enemies[0].timer=99
    return b
func _initialize() -> void:call_deferred("run")
func run() -> void:
    print("QA_USER_DIR ",OS.get_user_data_dir())
    if not OS.get_user_data_dir().ends_with("DuoduoCatsCourtyard-qa-m28-combat"):quit(2);return
    var openings=[];var followup=[]
    for age in [0.05,1.0]:
        var b=Battle.new();b.configure(context());b.phase="combat";b.positions[0]=Vector2(400,620)
        b._spawn("armored",Vector2(480,620),false)
        var e=b.enemies[0];e.mode="rest";e.timer=99;b.facing[0]=Vector2.RIGHT;b.signature(0);tick(b,age)
        e.mode="rush";e.timer=0.48;e.direction=Vector2.LEFT;tick(b,0.05);openings.append(e.timer)
        b.release_signature(0);b.dodge(0,Vector2.RIGHT);tick(b,0.22);tick(b,3.05)
        b.facing[0]=Vector2.LEFT;b.attack(0);tick(b,0.12);followup.append(e.hp)
    expect(openings[0]>openings[1]+0.59,"precise guard grants real 0.6s opening")
    expect(followup[0]<followup[1],"same late rear swing lands only after precise guard")
    print("PARRY openings=",openings," identical_late_attack_hp=",followup)
    var b=fixture(1);b.attack(0);tick(b,0.18);b.signature(0);b.release_signature(0);tick(b,0.30)
    expect(b.attacks.kinds[0]=="pounce" and b.signature_cooldown[0]>0,"black tapped skill buffers through basic recovery")
    b=fixture(2);b.attack(0);tick(b,0.20);b.signature(0);tick(b,0.18)
    expect(b.attacks.charging and b.attacks.charge_time<0.15,"white charge starts at recovery end, not retroactively")
    b=fixture(2);b.attack(0);tick(b,0.20);b.signature(0);b.release_signature(0);tick(b,0.5)
    expect(not b.attacks.charging and b.enemies[0].hp==4,"early release cancels queued white charge")
    b=fixture(1);b.attack(0);tick(b,0.18);b.signature(0);b.request_switch(0);tick(b,0.35)
    expect(b.actor(0)==2 and b.signature_cooldown[0]==0 and not b.attacks.charging,"role switch clears old skill intent")
    b=fixture(1);b.attack(0);tick(b,0.18);b.signature(0);b.cancel_attacks();tick(b,0.4)
    expect(b.signature_cooldown[0]==0 and b.attacks.skill_buffer[0]==0,"pause cancellation clears skill intent")
    b=fixture(1);b.attack(0);b.signature(0);tick(b,0.4)
    expect(b.signature_cooldown[0]==0,"skill outside180ms window never queues")
    # Link can be solved with any role and ordinary position; no role key.
    for role in [0,1,2]:
        b=Battle.new();b.configure(context("shell",role));b.phase="combat"
        b.positions[role]=Vector2(400,650);b._spawn("thorn",Vector2(460,650),false);b._spawn("weaver",Vector2(900,650),false)
        var front=b.enemies[0];front.mode="rest";front.timer=99;front.direction=Vector2.LEFT;b.enemies[1].mode="rest";b.enemies[1].timer=99
        b.facing[0]=Vector2.RIGHT;b.attack(0);tick(b,0.12)
        expect(front.hp==5,"linked front blocks role %d"%role)
        tick(b,0.4);b.positions[role]=Vector2(520,650);b.facing[0]=Vector2.LEFT;b.attack(0);tick(b,0.12)
        expect(front.hp<5,"side/rear basic works role %d"%role)
        b.enemies[1].hp=0
        expect(b.linked_source(front).is_empty(),"defeating source releases front role %d"%role)
    b=Battle.new();b.configure(context("shell",1));b.phase="combat";b.positions[1]=Vector2(850,650)
    b._spawn("thorn",Vector2(460,650),false);b._spawn("weaver",Vector2(900,650),false)
    b.enemies[0].mode="rest";b.enemies[0].timer=99;var caster=b.enemies[1];caster.mode="cast";caster.timer=0.4;caster.aim=b.positions[1]
    b.signature(0);tick(b,0.18)
    expect(caster.get("weave_break",0)>2 and b.linked_source(b.enemies[0]).is_empty(),"actual interruption severs link as well as cast")
    b.enemies[0].pos=Vector2(720,570);caster.pos=Vector2(840,570);caster.weave_break=0
    expect(b.linked_source(b.enemies[0]).is_empty(),"solid stump physically occludes link")
    var s=Session.new();s.single_player=true;s.keyboard_mode=true;s.ready_flags.assign([true,false])
    var host=Control.new();host.theme=Theme.new();host.theme.default_font=ThemeDB.fallback_font;root.add_child(host)
    var a=Arena.new(s);host.add_child(a);a.set_physics_process(false);a.configure(context());a.battle.phase="clear";a.battle.cleared_segments=2;a.battle.positions[0]=a.battle.EXIT
    a.handle_action(0,JOY_BUTTON_A);a._refresh()
    expect(a.result().outcome=="complete" and a.hint_label.text.contains("E 继续返回"),"completion makes next input explicit")
    s.single_player=false;var dual=context();dual.mode="dual";a.configure(dual);a.battle.phase="complete";a._refresh()
    expect(a.hint_label.text.contains("任一位 E / 空格"),"dual continuation says either player")
    # Exact rejected policy from independent review, retained unchanged.
    for id in ["first","shell","reserve"]:
        for role in ([0,1] if id=="first" else [0,1,2]):
            b=Battle.new();b.configure(context(id,role));b.interact(0)
            var elapsed:=0.0;var blocked:=0;var cursor:=0
            for frame in range(3600):
                var move:=Vector2.ZERO
                if b.phase=="intermission":b.interact(0)
                if b.phase in ["failed","clear"]:break
                if b.phase=="combat" and not b.enemies.is_empty():
                    var e=b.enemies[0]
                    for candidate in b.enemies:
                        if candidate.pos.distance_squared_to(b.positions[role])<e.pos.distance_squared_to(b.positions[role]):e=candidate
                    var point: Vector2=b.positions[role];var gap: float=point.distance_to(e.pos)
                    move=b.Space.direction(point,e.pos,18) if gap>55 else Vector2.ZERO
                    if gap<=100 if role==0 else gap<=72:
                        b.facing[0]=point.direction_to(e.pos)
                        if frame%12==0:b.attack(0)
                b.step(1.0/60,move,Vector2.ZERO,true);elapsed+=1.0/60
                for f in b.feedback_since(cursor):
                    if f.kind=="blocked":blocked+=1
                cursor=b.feedback_id
            print("NAIVE id=",id," role=",role," phase=",b.phase," wave=",b.wave," seconds=",snappedf(elapsed,0.1)," hp=",b.hp[0]," blocked=",blocked)
            if id=="shell" and role==0:expect(b.phase!="clear","old nearest-tap shell policy no longer bypasses its readable relation")
    print("M28_COMBAT_REVIEW_REGRESSION: ",checks," checks, ",failed," failed")
    quit(1 if failed else 0)
