extends SceneTree
const Battle=preload("res://game/battle_state.gd")
const Pose=preload("res://game/enemy_pose.gd")
var checks:=0
var failed:=0
func expect(ok: bool,label: String) -> void:
    checks+=1
    if not ok:failed+=1;print("FAIL ",label)
func fixture(role: int=0,dual: bool=false):
    var b=Battle.new();b.configure({"id":"shell","mode":"dual" if dual else "solo","available_role_ids":[0,1,2],"selected_role_id":role,"current_cat":1})
    b.positions[b.actor(0)]=Vector2(360,460);b.facing[0]=Vector2.RIGHT
    b._spawn("sprout",Vector2(425,460),false);b.enemies[0].mode="rest";b.enemies[0].timer=99
    return b
func budget(role: int,heavy: bool,two: bool) -> Dictionary:
    var b=fixture(role);b.enemies[0].hp=1000
    if two:b._spawn("sprout",b.positions[role]+Vector2.from_angle(deg_to_rad(75))*70,false);b.enemies[1].hp=1000
    var anchors=[]
    for e in b.enemies:anchors.append(e.pos)
    var displaced:=0.0
    for frame in range(1440):
        if heavy:
            if b.attacks.charging and b.attacks.charge_time>=b.attacks.CHARGE_SECONDS:b.release_signature(0)
            elif not b.attacks.charging and b.attacks.available(b,0) and b.signature_cooldown[0]<=0:b.signature(0)
        elif b.attacks.available(b,0):b.attack(0)
        b.step(1.0/120,Vector2.ZERO,Vector2.ZERO,true)
        for i in range(b.enemies.size()):
            displaced+=b.enemies[i].pos.distance_to(anchors[i]);b.enemies[i].pos=anchors[i]
    var damage:=0.0
    for e in b.enemies:damage+=1000-e.hp
    return {"role":role,"heavy":heavy,"targets":2 if two else 1,"seconds":12,"damage":damage,"dps":damage/12,"displaced":displaced}
func _initialize() -> void:call_deferred("run")
func run() -> void:
    print("QA_USER_DIR ",OS.get_user_data_dir())
    expect(OS.get_user_data_dir().ends_with("DuoduoCatsCourtyard-qa-m28-combat"),"actual isolated namespace")
    for hz in [60,120]:
        var b=fixture(0,true);b.phase="combat"
        var e=b.enemies[0];e.mode="rush";e.direction=Vector2.RIGHT;e.timer=0.4;e.control_immune=0.9
        b.attack_cooldown[0]=0.3;b.signature_cooldown[0]=0.5;b.invulnerable[0]=0.4;b.dodge_cooldown[0]=0.6
        b.contact(e,0,Vector2.RIGHT,true,false)
        var p: Vector2=e.pos;var partner: Vector2=b.positions[1]
        for frame in range(int(hz*0.06)):b.step(1.0/hz,Vector2.RIGHT,Vector2.DOWN,true)
        expect(e.pos==p and e.timer==0.4 and e.control_immune==0.9,"target clocks frozen %d"%hz)
        expect(b.attack_cooldown[0]==0.3 and b.signature_cooldown[0]==0.5 and b.invulnerable[0]==0.4 and b.dodge_cooldown[0]==0.6,"all owner timers frozen %d"%hz)
        expect(b.positions[1].distance_to(partner)>5,"uninvolved partner still moves %d"%hz)
        for frame in range(12):b.step(1.0/hz,Vector2.ZERO,Vector2.ZERO,true)
        expect(e.timer<0.4 and e.pos.x>p.x,"target resumes %d"%hz)
    var b=fixture();b.phase="combat";b.enemies[0].mode="approach";b.enemies[0].timer=0
    b.step(1.0/60,Vector2.ZERO,Vector2.ZERO,true)
    var e=b.enemies[0]
    expect(e.mode=="melee_windup" and e.pose_elapsed==0,"motion follows true preparation phase")
    for i in range(20):b.step(1.0/60,Vector2.ZERO,Vector2.ZERO,true)
    var preparation=Pose.sample(e)
    while e.mode=="melee_windup":b.step(1.0/60,Vector2.ZERO,Vector2.ZERO,true)
    var strike=Pose.sample(e)
    expect(e.mode=="melee" and preparation.offset.distance_to(strike.offset)>8,"body releases from prepared crouch")
    var locked: Vector2=e.direction
    b.request_switch(0)
    expect(e.direction==locked,"role swap preserves enemy locked direction")
    b=fixture(1);b.positions[1]=Vector2(470,345);b.enemies[0].pos=Vector2(590,345)
    b.signature(0)
    for i in range(30):b.step(1.0/60,Vector2.RIGHT,Vector2.ZERO,true)
    expect(b.positions[1].x<=478.01 and b.enemies[0].hp==4,"pounce cannot cross/damage through stump")
    b=fixture(2);e=b.enemies[0];e.kind="armored";e.mode="approach";e.direction=Vector2.LEFT
    b.signature(0)
    for i in range(26):b.step(1.0/60,Vector2.ZERO,Vector2.ZERO,true)
    b.release_signature(0)
    for i in range(10):b.step(1.0/60,Vector2.ZERO,Vector2.ZERO,true)
    expect(e.hp==4 and b.feedback_since(0).any(func(f):return f.kind=="blocked"),"heavy cannot bypass closed shell")
    var single=[];var pair=[]
    for role in [0,1,2]:single.append(budget(role,false,false));pair.append(budget(role,false,true))
    single.append(budget(2,true,false));pair.append(budget(2,true,true))
    print("M28_COMBAT_BUDGET ",JSON.stringify({"single":single,"spread_pair":pair}))
    expect(single[0].damage>single[3].damage,"sword sustained pressure exceeds heavy single target")
    expect(pair[3].damage>pair[0].damage and pair[3].damage>pair[1].damage,"white heavy wins broad pair")
    expect(single[3].displaced/(single[3].damage/3)>single[2].displaced/single[2].damage,"heavy buys more displacement per committed strike")
    print("M28_COMBAT_FEEDBACK: ",checks," checks, ",failed," failed")
    quit(1 if failed else 0)
