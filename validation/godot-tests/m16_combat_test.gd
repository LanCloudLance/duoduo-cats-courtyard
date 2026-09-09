extends SceneTree
const B = preload("res://game/battle_state.gd")
var checks := 0
var failed := 0
func check(value: bool, label: String) -> void:
    checks += 1
    if not value:
        failed += 1
        push_error("FAIL: "+label)
func tick(b, seconds: float, a := Vector2.ZERO, c := Vector2.ZERO) -> void:
    for i in range(ceili(seconds*120)): b.step(1.0/120,a,c,true)
func fixture(cat := 1):
    var b = B.new()
    b.current_cat = cat
    for i in range(3): b.positions[i] = Vector2(350,440)
    b._spawn("sprout",Vector2(420,440))
    b.enemies[0].hp = 100
    b.enemies[0].max_hp = 100
    b.enemies[0].mode = "rest"
    b.enemies[0].timer = 99
    return b
func _initialize() -> void:
    var b = fixture()
    var e: Dictionary = b.enemies[0]
    b.attack(0)
    check(e.hp == 100 and b.attack_flash[0] > 0,"press starts visual before hit")
    tick(b,0.075)
    check(e.hp == 99,"damage arrives during early swing")
    tick(b,0.13)
    b.attack(0)
    b.attack(0)
    tick(b,0.18)
    check(e.hp == 98,"one early buffered followup executes once")
    tick(b,0.6)
    check(e.hp == 98,"no held queue continues attacking by itself")
    b = fixture()
    b.attack(0)
    tick(b,0.21)
    b.attack(0)
    b.cancel_attacks()
    tick(b,0.5)
    check(b.enemies[0].hp == 99,"pause cancellation clears buffered attack")
    b = fixture(2)
    b.attack(1)
    tick(b,0.56)
    check(b.attacks.charging and b.last_feedback == "ready","full charge has explicit ready feedback")
    b.dodge(1,Vector2.DOWN)
    b.release_attack(1)
    tick(b,0.3)
    check(b.enemies[0].hp == 100 and not b.attacks.charging,"dodge cancels full charge without stray hit")
    b = fixture(2)
    b.attack(1)
    b.release_attack(1)
    tick(b,0.19)
    b.attack(1)
    b.release_attack(1)
    tick(b,0.18)
    check(b.enemies[0].hp == 98 and not b.attacks.charging,"buffered white tap preserves its release")
    b = fixture()
    b.enemies[0].mode = "cast"
    b.attack(1)
    tick(b,0.1)
    e = b.enemies[0]
    check(e.mode == "rest" and e.mark_time > 0,"pounce interrupts casting and marks an opening")
    b.phase = "combat"
    var before: float = e.hp
    b.switch_cat()
    b.switch_cat()
    b.switch_cat()
    check(e.hp == before-1,"switch assist triggers once and cannot be spammed")
    tick(b,0.3)
    b.positions[2] = e.pos-Vector2(55,0)
    b.attack(1)
    tick(b,0.56)
    b.release_attack(1)
    tick(b,0.12)
    check(e.control_time > 0.6 and e.mark_time == 0,"white heavy can consume black interrupt despite control immunity")
    b = fixture()
    b._spawn("thorn",Vector2(300,440))
    b.attack(0)
    tick(b,0.08)
    check(b.attack_direction[0].x > 0.99 and b.enemies[1].hp == 5,"aim assistance never snaps to closer target behind")
    b = B.new()
    b._start_wave(3)
    check(b.enemies.size() == 4 and b.enemies.any(func(v): return v.kind == "weaver"),"dual final encounter has distinct simultaneous roles")
    b.solo_mode = true
    b._start_wave(3)
    check(b.enemies.size() == 3,"solo removes one flanking enemy")
    e = b.enemies[0]
    e.hp = e.max_hp*0.5
    e.pos = Vector2(430,440)
    e.timer = 0
    b.positions[0] = Vector2(350,440)
    tick(b,0.02)
    check(e.mode == "slam_windup" and e.timer > 0.7,"wounded elder introduces independently telegraphed slam")
    b = B.new()
    b._spawn("weaver",Vector2(430,440))
    b.phase = "combat"
    b.enemies[0].timer = 0
    tick(b,0.02)
    e = b.enemies[0]
    var aim: Vector2 = e.aim
    tick(b,0.25,Vector2.DOWN)
    check(e.aim == aim,"caster locks visible ground target instead of tracking input")
    b = B.new()
    b._start_wave(1)
    for v in b.enemies: v.hp = 0
    b.hp[1] = 0
    tick(b,2)
    check(b.phase == "intermission" and b.wave == 1,"automatic pacing still waits for downed partner")
    b.positions[1] = b.positions[0]+Vector2(40,0)
    b.interact(0)
    tick(b,1.3)
    check(b.wave == 2 and b.hp[1] > 0,"successful rescue resumes pacing automatically")
    b = B.new()
    b._start_wave(1)
    for i in range(60*60):
        b.attack(0)
        b.attack(1)
        b.step(1.0/60,Vector2.ZERO,Vector2.ZERO,true)
    print("SPAM_RESULT phase=",b.phase," wave=",b.wave," hp=",b.hp," retries=",b.retries)
    check(b.phase != "clear" and (b.retries > 0 or b.hp[0] == 0 or b.hp[1] == 0),"stationary attack spam cannot clear encounter and leaves a downed partner or retries")
    b = B.new()
    b._start_wave(3)
    b.enemies[0].mode = "windup"
    b.enemies[0].target = 0
    b.enemies[1].target = 1
    check(not b._busy(b.enemies[1]),"dual permits a separate threat aimed at the other player")
    b.enemies[1].target = 0
    check(b._busy(b.enemies[1]),"major threats cannot stack on the same player")
    b.enemies[1].target = 1
    b.solo_mode = true
    check(b._busy(b.enemies[1]),"solo caps concurrent major attacks at one")
    b = B.new()
    b.phase = "combat"
    b.guarding = true
    b.facing[0] = Vector2.RIGHT
    check(b.hurt(0,b.positions[0]+Vector2(80,0),false) and b.hp[0] == 2,"ground hazards require moving or dodging even with frontal shield")
    b = B.new()
    b._spawn("elder",Vector2(500,440))
    e = b.enemies[0]
    b.guard_age = 0.1
    b._expose(e,"shield")
    var perfect: float = e.timer
    b.guard_age = 1.0
    b._expose(e,"shield")
    check(perfect > e.timer,"timed guard opens a longer elder counterattack")
    b = B.new()
    b.phase = "combat"
    b.positions[0] = Vector2(150,600)
    b.positions[1] = Vector2(200,600)
    b._spawn("thorn",Vector2(400,440))
    b._spawn("weaver",Vector2(500,440))
    e = b.enemies[0]
    e.mode = "rush"
    e.direction = Vector2.RIGHT
    e.timer = 1
    b.enemies[1].mode = "cast"
    b.enemies[1].aim = b.positions[0]
    b._rush(e,0.15)
    check(b.enemies[1].hp == 5 and b.enemies[1].mode == "rest" and e.opening == "collision","lured rush damages and interrupts backline caster")
    print("M16_COMBAT: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
