extends SceneTree
var checks:=0
var failed:=0
func check(value:bool,label:String)->void:
    checks+=1
    if not value:failed+=1;push_error("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
    if not ResourceLoader.exists("res://game/journey_score.gd"):
        check(false,"journey responds to real chapter progress rather than one puzzle loop")
        finish();return
    var score=load("res://game/journey_score.gd").new()
    var two=load("res://game/chapter_two_state.gd").new()
    var three=load("res://game/chapter_three_state.gd").new()
    var four=load("res://game/chapter_four_state.gd").new()
    var five=load("res://game/chapter_five_state.gd").new()
    var b=load("res://game/battle_state.gd").new()
    var a:Dictionary=score.sample("story-chapter",two,"run-a")
    var c:Dictionary=score.sample("story-chapter",three,"run-a")
    var d:Dictionary=score.sample("story-chapter",four,"run-a")
    check(a.profile=="chapter2" and c.profile=="chapter3" and d.profile=="chapter4","later chapters have separate score identities")
    check(a.accent.is_empty() and c.accent.is_empty(),"entering a chapter does not invent a discovery")
    two.locked_a=true
    check(score.sample("story-chapter",two,"run-a").accent=="resolved","actual first permanent bridge lock gives one musical answer")
    for i in range(30):check(score.sample("story-chapter",two,"run-a").accent.is_empty(),"refresh cannot repeat the bridge resolution")
    two.actions[0]="hold"
    check(score.sample("story-chapter",two,"run-a").accent.is_empty(),"holding an input is not a completion")
    three.joined=true
    check(score.sample("story-chapter",three,"run-a").accent=="reunion","actual reunion receives its own phrase")
    three.start_dialogue(["一起回家。"])
    check(score.sample("story-chapter",three,"run-a").mood=="reflect","dialogue leaves space in the arrangement")
    var restored=load("res://game/chapter_two_state.gd").new();restored.locked_a=true
    check(score.sample("story-chapter",restored,"run-a").accent.is_empty(),"restored facts do not replay a reward")
    b.story_encounter="reserve";b.phase="briefing"
    check(score.sample("story-combat",four,"run-a",b).mood=="reflect","briefing has breathing space")
    b.phase="combat"
    check(score.sample("story-combat",four,"run-a",b).profile=="boss","reserve encounter has its own developing theme")
    b.phase="clear"
    var clear:Dictionary=score.sample("story-combat",four,"run-a",b)
    check(clear.profile=="rest" and clear.accent=="resolved","clearing a battle resolves once")
    b.phase="complete"
    var complete:Dictionary=score.sample("story-combat",four,"run-a",b)
    check(complete.profile=="rest" and complete.accent.is_empty(),"exit confirmation never restarts battle music or repeats victory")
    b.phase="failed"
    check(score.sample("story-combat",four,"run-a",b).mood=="reflect","failure is not ongoing combat intensity")
    four.reserve_available=true
    check(score.sample("story-chapter",four,"run-a").accent.is_empty(),"temporary lamp charge is not a permanent discovery")
    four.reserve_hold_seen=true
    check(score.sample("story-chapter",four,"run-a").accent=="resolved","first retained-light observation receives an answer")
    four.reserve_available=false;score.sample("story-chapter",four,"run-a")
    four.reserve_available=true
    check(score.sample("story-chapter",four,"run-a").accent.is_empty(),"repeated identical experiment cannot farm resolution phrases")
    five.phase="shield"
    check(score.sample("story-chapter",five,"run-a").mood=="pressure","moving-arm repair has an intentional pressure section")
    five.phase="unjam"
    check(score.sample("story-chapter",five,"run-a").mood=="reflect","stopped-arm reasoning releases the pressure arrangement")
    five.machine_stopped=true
    check(score.sample("story-chapter",five,"run-a").accent=="resolved","actual extraction has a resolving musical answer")
    five.phase="test"
    check(score.sample("story-chapter",five,"run-a").mood=="reflect","far-lamp experiment provides listening and thinking space")
    five.phase="home"
    check(score.sample("story-chapter",five,"run-a").profile=="home","home returns to family theme")
    check(score.sample("menu",null,"run-a").profile=="home","menu is independent of stale battle state")
    finish()
func finish()->void:
    print("M29_JOURNEY_SCORE: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
