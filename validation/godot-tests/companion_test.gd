extends "res://tests/solo_rules_test.gd"
func advance(solo, b, seconds: float, movement := Vector2.ZERO) -> void:
    for i in range(ceili(seconds*60)): solo.step(b,1.0/60,movement)
func fixture():
    var b = Battle.new()
    b.solo_mode = true
    b._start_wave(1)
    b.positions[0] = Vector2(350,440)
    b.positions[1] = Vector2(410,440)
    b.positions[2] = Vector2(400,580)
    b.enemies[0].pos = Vector2(475,440)
    b.enemies[0].mode = "rest"
    b.enemies[0].timer = 100
    b.enemies[0].hp = 20
    return b
func _initialize() -> void:
    check(ResourceLoader.exists("res://game/solo_battle.gd"),"production solo controller exists independently of test driver")
    if failed: finish(); return
    var Solo = load("res://game/solo_battle.gd")
    var b = fixture()
    var solo = Solo.new()
    var e: Dictionary = b.enemies[0]
    advance(solo,b,3)
    check(e.hp == 20,"idle human does not trigger autonomous combat clearing")
    solo.press(b,JOY_BUTTON_X,Vector2.ZERO)
    advance(solo,b,2)
    check(e.hp < 20,"cat contributes real attacks after human starts engaging")
    var hp: int = e.hp
    advance(solo,b,6)
    hp = e.hp
    advance(solo,b,2)
    check(e.hp == hp,"AI returns to support after human stops acting")
    b = fixture()
    solo = Solo.new()
    solo.switch_role(b)
    check(solo.human_slot == 1 and b.current_cat == 1,"first switch controls black cat")
    b.attack_cooldown[1] = 0.4
    solo.switch_role(b)
    check(b.current_cat == 2 and is_equal_approx(b.attack_cooldown[1],0.4),"switching to white keeps shared recovery")
    b.attack_cooldown[1] = 0
    solo.press(b,JOY_BUTTON_X,Vector2.ZERO)
    advance(solo,b,0.7)
    solo.switch_role(b)
    solo.release(b,JOY_BUTTON_X)
    check(solo.human_slot == 0 and not b.attacks.charging,"switching clears held white attack")
    b.hp[0] = 0
    solo.switch_role(b)
    check(solo.human_slot == 1,"downed girl can hand control to living cat")
    b.hp[1] = 0
    var cat: int = b.current_cat
    solo.switch_role(b)
    check(b.hp == [0,0] and b.current_cat == cat,"switch cannot revive shared downed cats")
    b = fixture()
    solo = Solo.new()
    b.hp[0] = 0
    b.positions[0] = b.positions[1]-Vector2(50,0)
    advance(solo,b,2)
    check(b.hp[0] == 2,"AI performs timed rescue when lane is safe")
    b = fixture()
    solo = Solo.new()
    solo.switch_role(b)
    b.enemies[0].pos = Vector2(550,440)
    b.enemies[0].kind = "armored"
    b.enemies[0].mode = "windup"
    b.enemies[0].direction = Vector2.LEFT
    b.enemies[0].timer = 1.4
    b.positions[1] = Vector2(850,440)
    solo.press(b,JOY_BUTTON_B,Vector2.DOWN)
    advance(solo,b,1.8)
    check(b.enemies[0].mode == "exposed" and b.hp[0] == 3,"AI girl faces and shields real telegraphed rush")
    b = fixture()
    solo = Solo.new()
    b.current_cat = 2
    b.positions[2] = Vector2(410,440)
    e = b.enemies[0]
    solo.press(b,JOY_BUTTON_X,Vector2.ZERO)
    advance(solo,b,2)
    check(e.hp <= 18,"white companion can release its own charged attack")
    var snapshot: Array = b.positions.duplicate()
    solo.cancel(b)
    check(not b.guarding and not b.attacks.charging,"cancel clears AI-held shield and charge")
    check(snapshot == b.positions,"cancel never teleports party")
    b = fixture()
    solo = Solo.new()
    e = b.enemies[0]
    e.kind = "armored"
    e.direction = Vector2.LEFT
    solo.press(b,JOY_BUTTON_X,Vector2.ZERO)
    var clear_body := true
    for i in range(180):
        solo.step(b,1.0/60,Vector2.ZERO)
        if b.positions[1].distance_to(e.pos) < 43.9: clear_body = false
    check(clear_body and b.positions[1].x > e.pos.x,"AI walks around closed armor to rear without crossing body")
    b = fixture()
    solo = Solo.new()
    b.hp[0] = 0
    e = b.enemies[0]
    e.pos = Vector2(600,440)
    e.mode = "windup"
    e.direction = Vector2.LEFT
    e.timer = 1.1
    advance(solo,b,0.4)
    check(b.rescuer == -1 and b.hp[0] == 0,"AI does not begin rescue while standing in a visible charge lane")
    b = fixture()
    solo = Solo.new()
    e = b.enemies[0]
    solo.press(b,JOY_BUTTON_B,Vector2.DOWN)
    advance(solo,b,0.1)
    check(e.hp == 20,"AI decisions have reaction delay instead of instant perfect response")
    finish()
func finish() -> void:
    print("COMPANION: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
