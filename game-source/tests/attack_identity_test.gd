extends SceneTree
# Catches omnidirectional/nearest-only hits, tunneling pounces, duplicate release
# damage, stale charges, armor bypass and permanent crowd control.
const B = preload("res://game/battle_state.gd")
var checks := 0
var failed := 0
func check(value: bool, label: String) -> void:
    checks += 1
    if not value:
        failed += 1
        push_error("FAIL: "+label)
func fixture(cat := 1):
    var b = B.new()
    b.current_cat = cat
    for i in range(3): b.positions[i] = Vector2(350,440)
    return b
func spawn(b, point: Vector2, kind := "thorn"):
    b._spawn(kind,point)
    var e: Dictionary = b.enemies[-1]
    e.mode = "rest"
    e.timer = 100
    e.hp = 10
    e.max_hp = 10
    return e
func advance(b, seconds: float) -> void:
    for i in range(ceili(seconds*60)): b.step(1.0/60,Vector2.ZERO,Vector2.ZERO,true)
func release(b) -> void:
    b.call("release_attack",1)
    advance(b,0.12)
func _initialize() -> void:
    var b = fixture()
    var a = spawn(b,Vector2(420,415))
    var c = spawn(b,Vector2(425,470))
    var rear = spawn(b,Vector2(300,440))
    b.attack(0)
    advance(b,0.08)
    check(a.hp == 9 and c.hp == 9,"sword sweep hits both forward targets once")
    check(rear.hp == 10,"sword does not automatically turn toward nearer rear target")
    b.attack(0)
    advance(b,0.08)
    check(a.hp == 9,"repeat press cannot bypass recovery")
    b = fixture()
    b.positions[0] = Vector2(510,320)
    a = spawn(b,Vector2(610,320))
    b.attack(0)
    advance(b,0.08)
    check(a.hp == 10,"sweep cannot pass through stump")
    b = fixture()
    b.guarding = true
    a = spawn(b,Vector2(420,440))
    b.attack(0)
    advance(b,0.08)
    check(a.hp == 10,"shield prevents sword attack")
    b = fixture()
    a = spawn(b,Vector2(445,440))
    c = spawn(b,Vector2(445,450))
    b.attack(1)
    advance(b,0.2)
    check(b.positions[1].x > 350 and b.positions[1].x <= 401.01,"black cat stops at enemy body during pounce")
    check(a.hp+c.hp == 19,"pounce reaches target and hits only one once")
    b = fixture()
    b.positions[1] = Vector2(505,320)
    b.attack(1)
    advance(b,0.2)
    check(b.positions[1].x <= 508.01,"pounce cannot tunnel through stump")
    b = fixture()
    a = spawn(b,Vector2(405,440),"armored")
    b.attack(1)
    advance(b,0.2)
    check(b.positions[1].x <= 361.01 and a.hp == 10,"closed armor blocks pounce body and damage")
    b = fixture()
    a = spawn(b,Vector2(420,440),"armored")
    a.mode = "exposed"
    a.direction = Vector2.RIGHT
    b.attack(1)
    advance(b,0.2)
    check(a.hp == 9,"rear pounce damages exposed knot")
    check(b.has_method("release_attack"),"white cat has press and release attack lifecycle")
    if not b.has_method("release_attack"):
        finish()
        return
    b = fixture(2)
    a = spawn(b,Vector2(410,440))
    b.attack(1)
    check(a.hp == 10,"white press prepares without dealing damage")
    release(b)
    check(a.hp == 9,"white short release deals one light hit")
    release(b)
    check(a.hp == 9,"duplicate release does not hit again")
    b = fixture(2)
    a = spawn(b,Vector2(410,440))
    b.attack(1)
    advance(b,0.65)
    check(a.hp == 10,"full charge waits for explicit release")
    release(b)
    check(a.hp == 7 and a.pos.x > 410,"heavy slap deals three damage and physically pushes ordinary enemy")
    var pushed: Vector2 = a.pos
    advance(b,1)
    b.positions[2] = a.pos-Vector2(60,0)
    b.attack(1)
    advance(b,0.65)
    release(b)
    check(a.hp == 4 and a.pos == pushed,"control immunity prevents repeated push while damage remains valid")
    b = fixture(2)
    a = spawn(b,Vector2(410,440))
    a.mode = "rush"
    b.attack(1)
    advance(b,0.65)
    release(b)
    check(a.mode == "rush" and a.pos == Vector2(410,440) and a.hp == 7,"heavy damage does not interrupt an active rush")
    for exposed in [false,true]:
        b = fixture(2)
        a = spawn(b,Vector2(410,440),"armored")
        a.direction = Vector2.RIGHT
        if exposed: a.mode = "exposed"
        b.attack(1)
        advance(b,0.65)
        var before: float = a.timer
        release(b)
        check(a.hp == (7 if exposed else 10),"heavy respects closed armor and exposed rear")
        check(a.pos == Vector2(410,440),"heavy never displaces armored target")
        if exposed:
            check(is_equal_approx(a.timer,before+0.5),"heavy extends exposed window once")
            advance(b,1)
            b.attack(1)
            advance(b,0.65)
            before = a.timer
            release(b)
            check(is_equal_approx(a.timer,before),"same opening cannot be extended repeatedly")
    for action in ["switch","dodge","hurt","cancel"]:
        b = fixture(2)
        a = spawn(b,Vector2(410,440))
        b.attack(1)
        advance(b,0.65)
        match action:
            "switch":
                b.switch_cat()
                b.switch_cat()
            "dodge": b.dodge(1,Vector2.DOWN)
            "hurt":
                b.phase = "combat"
                b.hurt(1,Vector2(300,440))
            "cancel": b.call("cancel_attacks")
        release(b)
        check(a.hp == 10,"%s cancels pending heavy without releasing it" % action)
    b = fixture(2)
    a = spawn(b,Vector2(410,440))
    b.attack(1)
    b.step(0.1,Vector2.ZERO,Vector2.ZERO,false)
    release(b)
    check(a.hp == 9,"disabled simulation cannot accumulate charge")
    b = fixture(2)
    a = spawn(b,Vector2(410,440))
    b.attack(1)
    advance(b,3)
    release(b)
    check(a.hp == 7,"holding beyond full charge cannot increase damage")
    b.switch_cat()
    b.attack(1)
    advance(b,0.2)
    check(a.hp == 7,"switching cat preserves previous heavy recovery")
    b = fixture(2)
    a = spawn(b,Vector2(410,440))
    b.attack(1)
    advance(b,0.65)
    b.phase = "combat"
    release(b)
    advance(b,0.5)
    check(a.mode != "rest","short control does not stack a second recovery delay")
    b = fixture(2)
    a = spawn(b,Vector2(410,440),"armored")
    a.mode = "exposed"
    a.direction = Vector2.LEFT
    b.attack(1)
    advance(b,0.65)
    release(b)
    check(a.hp == 10,"heavy from the front still hits armor during exposure")
    b = fixture(2)
    a = spawn(b,Vector2(410,440))
    b.hp[0] = 0
    b.attack(1)
    advance(b,0.65)
    b.positions[0] = b.positions[2]+Vector2(25,0)
    b.interact(1)
    release(b)
    check(a.hp == 10 and b.rescuer == 1,"starting rescue cancels charge instead of attacking while rescuing")
    finish()
func finish() -> void:
    print("ATTACK_IDENTITY: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
