extends SceneTree
const B = preload("res://game/battle_state.gd")
const Solo = preload("res://game/solo_battle.gd")
var failed := 0
var checks := 0
func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failed += 1
        push_error("FAIL: "+label)
func fixture():
    var b = B.new()
    b.positions[0] = Vector2(350,440)
    b.positions[1] = Vector2(350,540)
    b.positions[2] = Vector2(350,540)
    b._spawn("thorn",Vector2(415,440))
    b.enemies[0].hp = 1000
    b.enemies[0].mode = "rest"
    b.enemies[0].timer = 99
    return b
func budget(kind: String, two: bool) -> Dictionary:
    var b = fixture()
    b.current_cat = 2
    b.positions[2] = b.positions[0]
    if two:
        b._spawn("thorn",b.positions[0]+Vector2.from_angle(deg_to_rad(75))*70)
        b.enemies[1].hp = 1000
    var starts := 0
    var distance_cost := 0.0
    var slot := 0 if kind == "sword" else 1
    var anchors: Array[Vector2] = []
    for e in b.enemies: anchors.append(e.pos)
    for frame in range(1440):
        if b.attacks.available(b,slot) and not b.attacks.charging:
            b.attack(slot)
            starts += 1
            if kind == "slap": b.release_attack(slot)
        elif b.attacks.charging and b.attacks.charge_time >= b.attacks.CHARGE_SECONDS-0.00001:
            b.release_attack(slot)
        b.step(1.0/120,Vector2.ZERO,Vector2.ZERO,true)
        # Fixed contact DPS bench; separately report displaced distance, not real-play DPS.
        for i in range(b.enemies.size()):
            distance_cost += b.enemies[i].pos.distance_to(anchors[i])
            b.enemies[i].pos = anchors[i]
    var damage := 0.0
    for e in b.enemies: damage += 1000-e.hp
    return {"kind":kind,"targets":2 if two else 1,"seconds":12,"damage":damage,"dps":damage/12,"starts":starts,"target_displacement":distance_cost}
func _initialize() -> void:
    for hz in [60,120]:
        var b = fixture()
        b.phase = "combat"
        var e: Dictionary = b.enemies[0]
        e.mode = "rush"
        e.direction = Vector2.RIGHT
        e.timer = 0.4
        e.control_immune = 0.9
        e.mark_time = 1.8
        b.attack_cooldown[0] = 0.3
        b.dodge_cooldown[0] = 0.6
        b.invulnerable[0] = 0.4
        b.contact(e,0,Vector2.RIGHT,true,false)
        var timer: float = e.timer
        var pos: Vector2 = e.pos
        var mark: float = e.mark_time
        for frame in range(int(0.06*hz)):
            b.step(1.0/hz,Vector2.RIGHT,Vector2.ZERO,true)
        check(e.pos == pos and e.timer == timer and e.mark_time == mark and e.control_immune == 0.9,"target rush and all target timers freeze at %d Hz" % hz)
        check(b.attack_cooldown[0] == 0.3 and b.dodge_cooldown[0] == 0.6 and b.invulnerable[0] == 0.4,"all source combat clocks freeze at %d Hz" % hz)
        for frame in range(12): b.step(1.0/hz,Vector2.ZERO,Vector2.ZERO,true)
        check(e.pos.x > pos.x and e.timer < timer,"target resumes after bounded local pause")
    var b = fixture()
    var solo = Solo.new()
    b.solo_mode = true
    b.phase = "combat"
    solo.engagement = 3.5
    for frame in range(480):
        var movement := Vector2.UP if frame%120 < 60 else Vector2.DOWN
        solo.step(b,1.0/120,movement)
    check(solo.engagement > 0,"nearby active footwork keeps AI support after 4 seconds")
    b.positions[0] = Vector2(1200,750)
    for frame in range(480): solo.step(b,1.0/120,Vector2.ZERO)
    check(solo.engagement == 0,"retreat and inactivity expire AI engagement")
    var one: Array = []
    var two: Array = []
    for kind in ["sword","slap","heavy"]:
        one.append(budget(kind,false))
        two.append(budget(kind,true))
    print("COMBAT_BUDGET ",JSON.stringify({"single":one,"spread_pair":two}))
    check(one[0].damage > one[2].damage,"sword sustained single-target pressure exceeds heavy")
    check(two[2].damage > two[0].damage and two[2].damage > two[1].damage,"heavy wins broad-angle pair fixture")
    check(one[2].target_displacement > one[1].target_displacement,"heavy offers measurable positional control")
    print("M27_COMBAT_BUDGET: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
