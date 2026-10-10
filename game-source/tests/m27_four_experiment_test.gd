extends SceneTree
const Four = preload("res://game/chapter_four_state.gd")
var checks := 0
var failed := 0

func _initialize()->void:
    run()
    print("M27_FOUR_EXPERIMENT: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)

func check(ok:bool,label:String)->void:
    checks+=1
    if not ok:failed+=1;print("FAIL: ",label)

func advance(s,seconds:=1.8)->void:
    for i in range(ceili(seconds/0.05)):s.step(0.05,Vector2.ZERO,Vector2.ZERO,true)

func touch(s,role:int,point:Vector2)->void:
    advance(s,0.6);s.positions[role]=point;s.interact(role)

func lit_trial():
    var s=Four.new();s.phase="investigate";s.cloth=true
    s.positions[2]=s.DUCT_LIGHT;s.facing[2]=Vector2.UP;s.interact(2)
    advance(s,0.6);s.positions[0]=s.ARROWS
    return s

func send(s)->void:
    advance(s,0.6);s.positions[0]=s.ARROWS;s.tool(0);advance(s)

func run()->void:
    # Deleting the experiments and restoring three click-flags must fail this.
    var old=lit_trial()
    touch(old,1,old.BRANCH);touch(old,0,old.ARROWS)
    check(not old.battle_requested,"looking at three objects does not prove two faults")
    check(old.get("route_split")!=null,"trial has a reversible route control")
    if old.get("route_split")==null:return
    var s=lit_trial()
    send(s)
    check(s.main_return_seen and s.return_charge>0,"main-line pulse visibly returns through the jam")
    check(s.shell_leak_seen and s.leak_charge>0,"unrepaired shell loses a distinct share to wind")
    check(s.reserve_charge==0 and not s.reserve_hold_seen,"main route does not light the separate reserve")
    touch(s,0,s.ALIGHT)
    check(not s.battle_requested,"one observation cannot stand in for the comparison")
    touch(s,0,s.ARROWS);send(s)
    check(s.route_split and s.reserve_charge==0,"connected split branch is also sucked empty")
    check(not s.reserve_hold_seen,"failed split is not accepted as retained light")
    touch(s,1,s.BRANCH)
    check(s.branch_seen and s.bypass_isolated,"fine latch reveals trapped branch and isolates the reserve")
    send(s)
    check(s.reserve_charge>0 and s.reserve_hold_seen,"isolated split branch actually retains the pulse")
    var retained:float=s.reserve_charge
    advance(s,4)
    check(is_equal_approx(s.reserve_charge,retained),"retained reserve remains lit after the pulse")
    touch(s,1,s.BRANCH);advance(s)
    check(s.reserve_charge==0,"reconnecting stored light makes it flow back, reversibly")
    touch(s,1,s.BRANCH);send(s)
    touch(s,0,s.ALIGHT)
    check(s.battle_requested and s.phase=="battle_one","Alight and party diagnose only after the real comparison")
    var canceled=lit_trial()
    canceled.tool(0);advance(canceled,0.2)
    canceled.action_time[2]=0;canceled.tool(2);advance(canceled)
    check(not canceled.pulse_active and not canceled.main_return_seen,"withdraw light during a trial cancels without fabricated evidence")
    check(canceled.actions[2]=="","tool releases the light stand")
    touch(canceled,2,canceled.DUCT_LIGHT);send(canceled)
    check(canceled.main_return_seen,"canceled experiment can be retried")
    var fixed=lit_trial();fixed.shell_fixed=true;fixed.phase="test"
    send(fixed)
    check(fixed.inward_verified and fixed.phase=="offer","post-repair pulse proves the machine still returns light")
    check(fixed.leak_charge==0 and fixed.return_charge>0,"shell repair removes leakage but cannot fix the recovery mechanism")
    var dark=Four.new();dark.phase="investigate";dark.positions[0]=dark.ARROWS;dark.tool(0);advance(dark)
    check(dark.trial_count==0 and not dark.main_return_seen,"unlit trial cannot collect evidence")
    var stale=lit_trial();stale.tool(0);advance(stale,0.2)
    stale.action_time[0]=0;stale.interact(0);advance(stale)
    check(not stale.pulse_active and not stale.main_return_seen,"changing the optical route cancels the old sample")
    send(stale)
    check(stale.trial_count==1,"route changes recover with a fresh complete experiment")

    var paused=lit_trial();paused.tool(0);advance(paused,0.2)
    var elapsed:float=paused.pulse_elapsed
    for i in range(80):paused.step(0.05,Vector2.ZERO,Vector2.ZERO,false)
    check(paused.pulse_active and paused.pulse_elapsed==elapsed and paused.trial_count==0,"pause cannot finish a pulse or manufacture observations")
    advance(paused)
    check(paused.main_return_seen and paused.trial_count==1,"resuming finishes the same valid sample once")
    var moved=lit_trial();moved.tool(0);advance(moved,0.2)
    moved.controlled=2;moved.step(0.05,Vector2.DOWN,Vector2.ZERO,true);advance(moved)
    check(not moved.pulse_active and not moved.main_return_seen,"moving white cat safely cancels current experiment")
    var latch=lit_trial();latch.tool(0);advance(latch,0.2)
    latch.positions[1]=latch.BRANCH;latch.action_time[1]=0;latch.interact(1);advance(latch)
    check(not latch.pulse_active and latch.trial_count==0,"changing latch cancels an in-flight sample")
    var e_release=lit_trial();e_release.positions[2]=e_release.DUCT_LIGHT;e_release.interact(2)
    check(e_release.actions[2]=="","interact also explicitly releases stable trial light")
