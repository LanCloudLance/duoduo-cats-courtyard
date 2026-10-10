extends SceneTree
var checks:=0
var failed:=0
func check(ok:bool,label:String)->void:
    checks+=1
    if not ok:failed+=1;push_error("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
    var s=load("res://game/chapter_three_state.gd").new()
    s.single=false;s.joined=true;s.current_cat=2;s.bridge_locked=true;s.exit_revealed=true;s.phase="map"
    s.positions.assign([s.MAP+Vector2(35,0),Vector2(900,420),s.MAP+Vector2(35,0)])
    for i in range(1200):s.step(1.0/60,Vector2.ZERO,Vector2.ZERO,true)
    check(s.positions[1].x>s.EXIT_WALL and s.walkable(s.positions[1],1) and s.positions[1].distance_to(s.MAP)<130,"dormant cat enters the opened permanent doorway and gathers with party")
    s.positions[1]=Vector2(900,420);s.actions[1]="hold"
    for i in range(120):s.step(1.0/60,Vector2.ZERO,Vector2.ZERO,true)
    check(s.positions[1]==Vector2(900,420),"explicit cat hold survives automatic navigation")
    s.actions[1]="";s.exit_revealed=false;s.narrow_open=false;s.positions[1]=Vector2(900,420)
    for i in range(900):s.step(1.0/60,Vector2.ZERO,Vector2.ZERO,true)
    check(s.positions[1].x<s.EXIT_WALL,"follower cannot solve or pass unopened exit")
    check(not s.finished and not s.exit_revealed,"navigation never solves story puzzle")
    print("M25_FOLLOW: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
