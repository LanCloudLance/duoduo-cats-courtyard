extends SceneTree
const Battle=preload("res://game/battle_state.gd")
const Solo=preload("res://game/solo_battle.gd")
var checks:=0
var failed:=0
func check(ok:bool,label:String)->void:
    checks+=1
    if not ok:failed+=1;push_error("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
    for threat in [false,true]:
        var b=Battle.new();var solo=Solo.new();b.solo_mode=true
        b.guarding=true;b.guard_held=false;solo.human_slot=1;solo.guard_handoff=0.01;solo.companion.decision_time=0.18
        if threat:
            b.phase="combat";b._spawn("thorn",Vector2(500,440));b.enemies[0].mode="windup";b.enemies[0].timer=0.5;b.enemies[0].direction=Vector2.LEFT;b.enemies[0].target=0
        solo.step(b,0.02,Vector2.ZERO)
        check(solo.guard_handoff==0 and not b.guard_held,"handoff expires without restoring human held intent")
        if threat:
            check(b.guarding and solo.companion.status=="正面举盾","real frontal windup earns fresh AI guard at expiry")
        else:
            check(not b.guarding,"no-threat expiry lowers guard in the same simulation step")
            solo.step(b,0.02,Vector2.ZERO)
            check(not b.guarding,"expired handoff never refreshes a permanent shield")
    print("M27_BATTLE_HANDOFF: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
