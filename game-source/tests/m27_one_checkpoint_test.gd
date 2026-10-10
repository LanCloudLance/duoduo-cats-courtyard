extends SceneTree
var checks:=0
var failed:=0
func check(ok:bool,label:String)->void:
    checks+=1
    if not ok:failed+=1;print("FAIL: ",label)
func run()->void:
    var Story=load("res://tests/m27_one_baseline_state.gd" if "--baseline" in OS.get_cmdline_user_args() else "res://game/chapter_one_state.gd");var s=Story.new()
    check(s.has_method("checkpoint"),"first chapter exposes midprogress checkpoint")
    if not s.has_method("checkpoint"):print("M27_ONE_CHECKPOINT: %d checks, %d failed"%[checks,failed]);quit(1);return
    s.phase="road";s.equipment=true;s.supported=true;s.bracing=true;s.positions[1]=Vector2(620,570)
    var r=Story.new();check(r.restore_checkpoint(JSON.parse_string(JSON.stringify(s.checkpoint()))),"partial physical support survives JSON roundtrip")
    check(r.supported and not r.bracing and not r.branch_clear,"save preserves support, not a held command or unreached knot")
    s.phase="battle";s.branch_clear=true;s.battle_requested=false
    r=Story.new();check(r.restore_checkpoint(s.checkpoint()) and r.battle_requested,"interrupted first encounter resumes at its entrance")
    s.enter_station();s.positions[0]=s.PILLOW;s.interact(0)
    r=Story.new();check(s.clue_seen and not s.lit and r.restore_checkpoint(s.checkpoint()) and r.clue_seen,"early independent clue survives without lamp precondition")
    s.core_found=true;s.carrier=1
    r=Story.new();check(r.restore_checkpoint(s.checkpoint()) and r.carrier==1 and not r.core_ready,"carried wick is not lost or magically installed")
    s.carrier=-1;s.core_ready=true;s.core_installed=true;s.hood=1;s.vent=1;s.steady=1.3;s.flame=.7
    r=Story.new();check(r.restore_checkpoint(s.checkpoint()) and not r.lit and r.steady==0 and r.flame==0,"in-progress flame restarts observation without fabricated success")
    s.lit=true;s.clue_seen=true;s.phase="rest";s.resting=.4
    r=Story.new();check(r.restore_checkpoint(s.checkpoint()) and r.resting==0 and r.lit and r.clue_seen,"rest resumes only after new player interaction")
    check(r.extras.get("route",false),"route evidence rebuilt from actual durable clue")
    var bad:Dictionary=s.checkpoint();bad.facts.core_found=false
    var fresh=Story.new();check(not fresh.restore_checkpoint(bad) and not fresh.core_ready,"dependent wick corruption rejected atomically")
    bad=s.checkpoint();bad.completed=true;check(not fresh.restore_checkpoint(bad),"unfinished rest cannot become completion")
    bad=s.checkpoint();bad.facts.hood=1.5;check(not fresh.restore_checkpoint(bad),"nonintegral apparatus angle rejected")
    bad=s.checkpoint();bad.positions[0]=[INF,400];check(not fresh.restore_checkpoint(bad),"nonfinite position rejected")
    bad=s.checkpoint();bad.mode="dual";check(not fresh.restore_checkpoint(bad),"mode isolation enforced")
    s.finished=true;s.phase="complete";r=Story.new();check(r.restore_checkpoint(s.checkpoint()) and r.finished,"complete checkpoint validates all durable facts")
    var legacy=Story.new();legacy.restore(s.record());check(legacy.finished,"legacy v1 completion remains supported")
    s=Story.new();s.single=true;s.phase="road";s.equipment=true;s.branch_clear=true;s.positions.assign([Vector2(1000,550),Vector2(300,550)])
    for i in range(200):s.step(.05,Vector2.ZERO,Vector2.ZERO,true)
    check(s.positions[1].distance_to(s.positions[0])<125,"single party walks across repaired permanent path")
    s=Story.new();s.single=true;s.phase="road";s.equipment=true;s.positions.assign([Vector2(1000,550),Vector2(550,570)])
    for i in range(200):s.step(.05,Vector2.ZERO,Vector2.ZERO,true)
    check(s.positions[1].x<600 and not s.branch_clear,"unrepaired trunk cannot be crossed by follow")
    print("M27_ONE_CHECKPOINT: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
func _initialize()->void:call_deferred("run")
