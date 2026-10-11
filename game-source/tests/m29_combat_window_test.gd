extends SceneTree
const Battle=preload("res://game/battle_state.gd")
const Pose=preload("res://game/enemy_pose.gd")
var checks:=0
var failed:=0
func check(value:bool,label:String)->void:
    checks+=1
    if not value:failed+=1;print("FAIL ",label)
func fixture(mode:String="solo",role:int=0):
    var b=Battle.new();b.configure({"id":"reserve","mode":mode,"available_role_ids":[0,1,2],"selected_role_id":role,"current_cat":1});b.phase="combat"
    b.positions[b.actor(0)]=Vector2(300,650);b.positions[1]=Vector2(300,550) if mode=="dual" else b.positions[1]
    b._spawn("armored",Vector2(500,650),false)
    return b
func tick(b,seconds:float,enabled:bool=true)->void:
    for i in range(ceili(seconds*60)):b.step(1.0/60,Vector2.ZERO,Vector2.ZERO,enabled)
func _initialize()->void:call_deferred("run")
func run()->void:
    print("QA_USER_DIR ",OS.get_user_data_dir())
    if OS.get_user_data_dir().get_file()!="DuoduoCatsCourtyard-qa-m29-combat":quit(2);return
    for mode in ["solo","dual"]:
        for cause in ["miss","stump","shield","parry","collision"]:
            var b=fixture(mode);var e=b.enemies[0]
            b.guard_age=0.1 if cause=="parry" else 0.5
            if cause=="miss":
                e.mode="rush";e.direction=Vector2.RIGHT;e.timer=0;b._rush(e,1.0/60)
            else:b._expose(e,"shield" if cause=="parry" else cause)
            var expected:float=(1.15 if mode=="solo" else 0.9) if cause=="miss" else (3.8 if mode=="solo" else 3.0) if cause=="parry" else (3.2 if mode=="solo" else 2.4) if cause=="shield" else (2.8 if mode=="solo" else 2.0)
            check(is_equal_approx(e.timer,expected),mode+" "+cause+" actual duration")
            check(is_equal_approx(e.get("opening_duration",0.0),expected),mode+" "+cause+" authoritative visual duration")
            var events=b.fx.filter(func(f):return f.kind=="opening")
            check(events.size()==1 and events[0].get("cause","")==cause,mode+" "+cause+" one semantic result event")
            if not events.is_empty():check(events[0].get("duration",0)==expected and events[0].get("target_id",-1)==e.id,"event identifies target and actual span")
            var before:float=e.timer;tick(b,0.3,false)
            check(e.timer==before,"disabled simulation preserves opening")
            tick(b,0.10)
            check(e.timer<before and e.timer>before-0.12,"opening follows simulation clock")
    # Same flank position and ordinary movement/attacks: an earned opening gives
    # enough time to reach the rear. Perfect pre-positioning may still win a short one.
    for role in [0,1,2]:
        var outcomes=[]
        for cause in ["miss","stump"]:
            var b=fixture("solo",role);var e=b.enemies[0];e.direction=Vector2.RIGHT
            b.positions[role]=e.pos+Vector2(0,-105);b.facing[0]=Vector2.RIGHT;b._expose(e,cause)
            for i in range(144):
                if e.mode!="exposed" or e.hp<=0:break
                var rear:Vector2=e.pos-Vector2(58,0)
                var movement:Vector2=b.Space.direction(b.positions[role],rear,18) if b.positions[role].distance_to(rear)>5 else Vector2.ZERO
                if movement==Vector2.ZERO:
                    b.facing[0]=Vector2.RIGHT
                    if b.attack_cooldown[0]<=0:b.attack(0)
                b.step(1.0/60,movement,Vector2.ZERO,true)
            outcomes.append(5.0-e.hp)
        print("OPENING_PAYOFF role=",role," miss=",outcomes[0]," stump=",outcomes[1])
        check(outcomes[1]>outcomes[0],"role %d gains actual extra hits by making an opening"%role)
    var b=fixture();var e=b.enemies[0];b._expose(e,"stump");var before:float=e.timer
    b.request_switch(0);check(e.timer==before and e.opening=="stump","handoff cannot reset enemy's opening")
    b.cancel_attacks();check(e.timer==before,"cancel input cannot extend opening")
    e.impact_pause=0.07;tick(b,0.05);check(is_equal_approx(e.timer,before),"contact stop freezes opening clock")
    tick(b,0.1);check(e.timer<before and e.timer>before-0.1,"opening resumes after only remaining contact stop")
    for span in [0.5,0.65,0.85,1.0,1.4]:
        var cue={"kind":"weaver","mode":"cast","timer":span,"pose_mode":"cast","pose_duration":span}
        check(is_zero_approx(Pose.progress(cue)),"new warning starts empty regardless of mode duration")
        cue.timer=span*0.5;check(is_equal_approx(Pose.progress(cue),0.5),"every warning shows the same halfway point")
    e.timer=0.35;check(is_equal_approx(Pose.rear_openness(e),1.0),"bud stays open until closing interval")
    e.timer=0.175;check(is_equal_approx(Pose.rear_openness(e),0.5),"bud visibly folds in final interval")
    e.timer=0.0;check(is_zero_approx(Pose.rear_openness(e)),"bud fully closes at collision boundary")
    print("M29_COMBAT_WINDOW: ",checks," checks, ",failed," failed")
    quit(1 if failed else 0)
