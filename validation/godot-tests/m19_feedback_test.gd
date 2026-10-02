extends SceneTree
const Battle = preload("res://game/battle_state.gd")
var checks := 0
var failed := 0
func check(value: bool, label: String) -> void:
    checks += 1
    if not value:
        failed += 1
        push_error("FAIL: "+label)
func fixture():
    var b = Battle.new()
    b.positions[0] = Vector2(350,440)
    b.positions[1] = Vector2(350,540)
    b._spawn("sprout",Vector2(420,440))
    b.enemies[0].mode = "rest"
    b.enemies[0].timer = 99
    b.enemies[0].hp = 10
    return b
func _initialize() -> void:
    var b = fixture()
    check(b.has_method("feedback_since"),"simultaneous feedback is delivered as distinct events")
    if failed:
        finish()
        return
    b.feedback("hit",Vector2(1,2),0)
    b.feedback("hurt",Vector2(3,4),1)
    var events: Array = b.feedback_since(0)
    check(events.size() == 2 and events[0].kind == "hit" and events[1].kind == "hurt","one player's impact cannot overwrite the other's hurt")
    check(b.feedback_since(b.feedback_id).is_empty(),"consumed feedback is not replayed")
    b = fixture()
    b.attack(0)
    b.step(0.02,Vector2.ZERO,Vector2.ZERO,true)
    check(b.feedback_since(0).all(func(e): return e.kind == "swing"),"startup gives swing feedback without pretending to hit")
    b.step(0.05,Vector2.ZERO,Vector2.ZERO,true)
    check(b.contact_hold[0] > 0 and b.enemies[0].hp == 9,"actual contact triggers local attack pose hold")
    var partner: Vector2 = b.positions[1]
    b.step(0.016,Vector2.ZERO,Vector2.RIGHT,true)
    check(b.positions[1].x > partner.x,"local hit stop does not freeze partner movement")
    b.dodge(0,Vector2.DOWN)
    check(b.contact_hold[0] == 0 and b.dodge_time[0] > 0,"dodge cancels the held attack pose immediately")
    b = fixture()
    b.phase = "combat"
    b.enemies[0].hp = 1
    b.attack(0)
    b.step(0.07,Vector2.ZERO,Vector2.ZERO,true)
    check(b.enemies.is_empty() and b.fallen.size() == 1,"defeated target stops fighting but retains a visible death finish")
    b.step(0.1,Vector2.RIGHT,Vector2.ZERO,false)
    check(b.fallen[0].death_age == 0,"pause freezes death finish")
    for i in range(5): b.step(0.1,Vector2.ZERO,Vector2.ZERO,true)
    check(b.fallen.is_empty(),"death artwork is cleaned up after a short bounded finish")
    finish()
func finish() -> void:
    print("M19_FEEDBACK: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
