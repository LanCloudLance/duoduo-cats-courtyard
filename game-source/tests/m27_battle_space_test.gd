extends SceneTree
const Battle=preload("res://game/battle_state.gd")
var checks:=0
var failed:=0
func check(ok:bool,label:String)->void:
    checks+=1
    if not ok:failed+=1;push_error("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
    var b=Battle.new();b.story_encounter="shell";b._start_wave(1)
    check(b.enemies.size()==2 and b.enemies[0].hp+b.enemies[1].hp==11,"shell first wave retains two bodies / 11 HP")
    check(b.enemies[0].pos==Vector2(870,360) and b.enemies[1].pos==Vector2(960,650),"first shell pressure separated around lower stump")
    b.enemies.clear();b._start_wave(2)
    check(b.enemies.size()==2 and b.enemies[0].hp+b.enemies[1].hp==10,"shell second wave retains two bodies / 10 HP")
    check(b.enemies[1].pos.y<320 and b.enemies[0].pos.y>555,"second shell wave reverses ranged pressure side")
    for side in [-1,1]:
        var point=Vector2(630,555)
        var bend=Vector2(760,555+side*120)
        var round_side:=false
        var legal:=true
        for frame in range(240):
            if point.distance_to(bend)<5:round_side=true
            var target=Vector2(920,555+side*120) if round_side else bend
            point=b.Space.move(point,b.Space.direction(point,target,18)*3,18)
            legal=legal and b.Space.valid(point,18)
            if point.x>860:break
        check(legal and round_side and point.x>860,"both side approaches reach the far side without crossing solid stump")
    var reserve=Battle.new();reserve.story_encounter="reserve";reserve._start_wave(2)
    check(reserve.enemies.size()==3 and reserve.enemies[0].hp+reserve.enemies[1].hp+reserve.enemies[2].hp==15,"reserve still has three bodies and 15 HP in second wave")
    check(reserve.enemies[1].pos.y<reserve.enemies[0].pos.y and reserve.enemies[0].pos.y<reserve.enemies[2].pos.y,"reserve caster / pursuers occupy three distinct vertical approaches")
    b.enemies.clear();b._spawn("weaver",Vector2(613,320));b.positions[0]=Vector2(507,320);b.attack_direction[0]=Vector2.RIGHT
    b.attacks.strike(b,0,112,PI/3,2,false,false)
    check(b.enemies[0].hp==6,"sword cannot damage through stump at actual attack reach")
    b.positions[1]=Vector2(500,320);b.facing[1]=Vector2.RIGHT;b.attack(1)
    for frame in range(24):b.step(1.0/60,Vector2.ZERO,Vector2.ZERO,true)
    check(b.positions[1].x<=508 and b.enemies[0].hp==6,"pounce cannot cross or damage through stump")
    b=Battle.new();b.story_encounter="shell";b.phase="combat";b._spawn("weaver",Vector2(720,420))
    b.positions.assign([Vector2(550,530),Vector2(720,530),Vector2(655,585)])
    b.enemies[0].mode="cast";b.enemies[0].aim=Vector2(655,585);b.enemies[0].timer=1
    check(b.has_method("spare_goal"),"spare cat uses danger-aware side/rear presentation goal")
    if b.has_method("spare_goal"):
        var goal:Vector2=b.spare_goal()
        check(not b.spare_obstructs_warning(goal),"spare goal keeps silhouette away from current warning")
        check(b.Space.valid(goal,18) and goal.distance_to(b.positions[1])>=90,"spare remains on legal visible side/rear ground")
    var departure:Vector2=b.positions[b.current_cat]
    b.hp[1]=1;b.attack_cooldown[1]=0.3;b.dodge_cooldown[1]=0.7
    b.switch_cat()
    check(b.positions[b.current_cat]==departure and b.hp[1]==1 and b.attack_cooldown[1]==0.3 and b.dodge_cooldown[1]==0.7,"spare placement cannot grant a safe teleport or reset shared vulnerability")
    b=Battle.new();b.phase="combat";b._spawn("weaver",Vector2(700,430));b.enemies[0].mark_time=1.8
    b.positions[0]=Vector2(610,430);b.attack_direction[0]=Vector2.RIGHT
    b.attacks.strike(b,0,112,PI/3,2,false,true)
    check(b.enemies[0].mark_time==1.8,"Duoduo third hit never consumes Yuanyuan opportunity")
    b.current_cat=2;b.positions[2]=Vector2(650,430);b.attack_direction[1]=Vector2.RIGHT
    b.attacks.strike(b,1,105,PI/2,3,false,true)
    check(b.enemies[0].mark_time==0 and b.enemies[0].control_time==0.8,"Yuanyuan heavy consumes opportunity with real extra control")
    print("M27_BATTLE_SPACE: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
