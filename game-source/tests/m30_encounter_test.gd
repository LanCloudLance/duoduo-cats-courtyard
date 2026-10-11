extends SceneTree
const Battle=preload("res://game/battle_state.gd")
const Save=preload("res://game/battle_journey.gd")
var checks:=0
var failed:=0
func check(value:bool,label:String)->void:
    checks+=1
    if not value:failed+=1;print("FAIL ",label)
func fixture(id:String,role:int=0,mode:String="solo"):
    var b=Battle.new()
    check(b.configure({"id":id,"mode":mode,"available_role_ids":[0,1,2],"selected_role_id":role,"current_cat":role if role>0 else 1,"encounter_revision":2,"story_run_id":"story-run-3020261011","return_chapter":4,"return_phase":"battle_one" if id=="shell" else "battle_two"}),"new encounter config")
    return b
func tick(b,amount:int=1)->void:
    for i in range(amount):b.step(1.0/60,Vector2.ZERO,Vector2.ZERO,true)
func _initialize()->void:call_deferred("run")
func run()->void:
    print("QA_USER_DIR ",OS.get_user_data_dir())
    if OS.get_user_data_dir().get_file()!="DuoduoCatsCourtyard-qa-m30-combat":quit(2);return
    for id in ["shell","reserve"]:
        var b=fixture(id)
        check(b.get("encounter_revision")==2,"new revision retained")
        check(not b.configure({"id":id,"mode":"solo","encounter_revision":3}),"unknown rule revision rejected")
        if b.get("encounter_revision")!=2:continue
        var edge:Vector2=b.Space.GATE-Vector2(43,0)
        check(b.Space.valid(edge,18),"player may stand next to closed gate")
        check(not b.Space.direction(b.Space.GATE-Vector2(320,20),edge,26).is_zero_approx(),"larger enemy can approach a player close to the gate")
        var valid_gate:bool=b.Space.valid(b.Space.GATE,18)
        check(not valid_gate,"closed physical gate blocks body")
        b.interact(0)
        check(b.wave_total==1 and b.enemies.size()==2,"one objective encounter keeps first-wave body budget")
        if id=="shell":
            var source=b.enemies.filter(func(e):return e.kind=="weaver")[0]
            var front=b.enemies.filter(func(e):return e.kind!="weaver")[0]
            front.hp=0;tick(b)
            check(b.phase=="combat" and not b.route_open,"frontline defeat cannot open source-held gate")
            var again=fixture("shell");again.interact(0)
            var live_front=again.enemies.filter(func(e):return e.kind!="weaver")[0]
            again.enemies.filter(func(e):return e.kind=="weaver")[0].hp=0;tick(again)
            check(again.route_open and again.phase=="clear","source defeat opens gate")
            check(live_front.hp>0 and live_front.mode=="retreat","surviving frontline genuinely retreats")
            check(again.Space.valid(again.Space.GATE,18),"opened physical gate accepts body")
            var before:Vector2=live_front.pos;tick(again,15)
            check(live_front.pos!=before,"retreat body visibly moves")
            again.positions[again.actor(0)]=live_front.pos-Vector2(50,0)
            var crossed:Vector2=again._move_actor(again.positions[again.actor(0)],Vector2(100,0),false)
            check(crossed.distance_to(again.positions[again.actor(0)])>90,"retreating enemy cannot body-block exit")
            check(again.result().completed_segments==2 and again.result().route_open,"result preserves real opened milestone")
            tick(again,30)
            check(again.feedback_id==2,"opening and original defeat are emitted once")
        else:
            var armor=b.enemies.filter(func(e):return e.kind=="armored")[0]
            b.positions[b.actor(0)]=b.Space.GATE-Vector2(70,0);b.interact(0)
            check(not b.route_open,"live armored cannot be bypassed by interacting")
            armor.pos=b.Space.GATE-Vector2(100,0);armor.direction=Vector2.RIGHT;armor.mode="rush";armor.timer=0.3
            b.positions[b.actor(0)]=Vector2(600,650)
            b._rush(armor,0.2)
            check(b.route_open and armor.hp>0,"collision breaks gate without killing armored")
            check(b.phase=="clear" and b.Space.valid(b.Space.GATE,18),"collision creates traversable safe route")
            check(b.hazards.is_empty(),"opened route clears lingering hazards")
    for role in [0,1,2]:
        var b=fixture("reserve",role)
        if b.get("encounter_revision")!=2:continue
        b.interact(0);var armor=b.enemies.filter(func(e):return e.kind=="armored")[0]
        armor.hp=0;tick(b)
        check(b.phase=="combat" and not b.route_open,"early armored defeat does not pretend collision")
        b.positions[role]=b.Space.GATE-Vector2(70,0);b.interact(0)
        check(b.route_open and b.enemies.any(func(e):return e.hp>0),"every role can release branch with other enemy alive")
    # An empty list alone is not evidence that the actual source was defeated.
    for id in ["shell","reserve"]:
        var b=fixture(id);b.positions[b.actor(0)]=b.Space.GATE-Vector2(70,0)
        b.interact(0)
        check(not b.route_open and b.phase=="combat","briefing input starts encounter without opening")
        b.enemies.clear();tick(b);b.interact(0)
        check(not b.route_open,"missing enemy list is not a witnessed objective defeat")
        b.phase="failed";b.retry_time=1;b.interact(0)
        check(not b.route_open,"failed empty encounter cannot release route")
    # Arrival protection must not relocate the only source behind its closed gate.
    var crowded=fixture("shell",0,"dual")
    crowded.positions[0]=Vector2(880,555);crowded.positions[1]=Vector2(790,300)
    crowded.interact(0);crowded.interact(1)
    var shifted=crowded.enemies.filter(func(e):return e.kind=="weaver")[0]
    check(shifted.pos.x<crowded.Space.GATE.x-crowded.Space.ROUTE_RADIUS-crowded.Space.ENEMY_RADIUS,"protected spawn remains before the closed gate")
    check(not crowded.Space.direction(crowded.positions[0],shifted.pos,18).is_zero_approx(),"relocated source remains reachable from deployed player")
    # Winning the source cannot bypass a downed partner or the physical exit side.
    var dual=fixture("shell",0,"dual");dual.interact(0);dual.interact(1)
    dual.enemies.filter(func(e):return e.kind=="weaver")[0].hp=0;dual.hp[1]=0;tick(dual)
    check(dual.route_open and dual.phase=="clear","living partner can earn route despite other partner down")
    dual.positions[0]=dual.Space.GATE-Vector2(42,0);dual.interact(0)
    check(dual.phase=="clear" and not dual.confirmed[0],"exit circle cannot confirm through closed side of opening")
    dual.positions[0]=dual.positions[dual.actor(1)]+Vector2(40,0);dual.interact(0);tick(dual,75)
    check(dual.hp[1]==2,"clear phase still advances only human-started rescue")
    for slot in dual.deployed_slots():dual.positions[dual.actor(slot)]=dual.EXIT
    dual.interact(0);check(dual.phase=="clear","one partner cannot confirm for the other")
    dual.interact(1);check(dual.phase=="complete","both living partners physically exit")
    var gone=fixture("shell");gone.interact(0);gone.enemies.filter(func(e):return e.kind=="weaver")[0].hp=0;gone.hp[0]=0;tick(gone)
    check(gone.phase=="failed" and not gone.route_open,"same-frame last-player down does not award a route")
    for id in ["shell","reserve"]:
        var geom=fixture(id)
        for y in range(int(geom.FIELD.position.y+20),int(geom.FIELD.end.y-19),11):
            var from:=Vector2(geom.Space.GATE.x-65,y)
            check(geom.Space.move(from,Vector2(130,0),18).x<geom.Space.GATE.x,"no edge path bypasses closed branch wall")
    # Closest wall projection must also clear the stump and preserve reachability.
    var chase=fixture("reserve")
    var observed:=0
    for y in range(240,721,5):
        var player:=Vector2(965,y)
        if not chase.Space.valid(player,18):continue
        var enemy_point:=Vector2(810,625)
        if enemy_point.distance_to(player)<=250:continue
        var moved:=false
        for i in range(300):
            if enemy_point.distance_to(player)<=250:break
            var direction:Vector2=chase.Space.direction(enemy_point,player,26)
            var next:Vector2=chase.Space.move(enemy_point,direction*85/60,26)
            moved=moved or next.distance_to(enemy_point)>0.001
            check(chase.Space.valid(next,26) and next.x<chase.Space.GATE.x,"chasing projected target never clips stump or gate")
            enemy_point=next
        check(moved and enemy_point.distance_to(player)<=250,"gate-side player remains approachable including stump overlap")
        observed+=1
    check(observed>10,"wide actual gate/stump edge sweep exercised")
    var old=Battle.new();check(old.configure({"id":"shell","mode":"solo","cleared_segments":1}),"old partial segment accepted")
    check(old.phase=="intermission" and old.wave_total==2,"legacy resume retains original two-wave meaning")
    var seed={"version":1,"encounter_id":"shell","mode":"solo","story_run_id":"story-run-3020261011","return_chapter":4,"return_phase":"battle_one","completed_segments":0,"selected_role_id":0,"current_cat":1,"encounter_revision":2,"route_open":false}
    var store=Save.new()
    check(store.valid(seed),"new unresolved checkpoint valid")
    check(store.valid(JSON.parse_string(JSON.stringify(seed))),"JSON numeric representation preserves valid new goal")
    for field in ["version","completed_segments","encounter_revision"]:
        for wrong in ["2",false,true,[],{},null]:
            var poison=seed.duplicate(true);poison[field]=wrong;check(not store.valid(poison),"poisoned numeric metadata rejected before comparing")
    for wrong in [false,[],{},1,null]:
        var malformed=seed.duplicate(true);malformed.return_phase=wrong;check(not store.valid(malformed),"malformed return phase rejected without script error")
    var bad=seed.duplicate(true);bad.encounter_revision=3;check(not store.valid(bad),"unknown save revision rejected")
    bad=seed.duplicate(true);bad.route_open=true;check(not store.valid(bad),"contradictory open/zero rejected")
    bad=seed.duplicate(true);bad.completed_segments=1;check(not store.valid(bad),"new half-wave fake progress rejected")
    bad=seed.duplicate(true);bad.route_open="false";check(not store.valid(bad),"nonboolean route proof rejected")
    print("M30_ENCOUNTER: ",checks," checks, ",failed," failed")
    quit(1 if failed else 0)
