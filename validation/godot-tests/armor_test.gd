extends SceneTree
const B = preload("res://game/battle_state.gd")
var checks := 0
var failed := 0
func check(value: bool, label: String) -> void:
    checks += 1
    if not value:
        failed += 1
        push_error("FAIL: "+label)
func advance(b, seconds: float, p1 := Vector2.ZERO, p2 := Vector2.ZERO) -> void:
    for i in range(ceili(seconds*60)): b.step(1.0/60,p1,p2,true)
func fixture():
    var b = B.new()
    b._start_wave(2)
    b.positions[0] = Vector2(400,440)
    b.positions[1] = Vector2(950,610)
    b.enemies[0].pos = Vector2(580,440)
    b.enemies[0].direction = Vector2.LEFT
    b.enemies[0].mode = "windup"
    b.enemies[0].timer = 0.1
    return b
func _initialize() -> void:
    var b = fixture()
    check(b.enemies.size() == 1 and b.enemies[0].kind == "armored","second round teaches one armored opponent")
    if failed:
        finish()
        return
    var enemy = b.enemies[0]
    b.positions[0] = Vector2(510,440)
    b.attack(0)
    check(enemy.hp == 3,"armor blocks front attacks")
    b.positions[1] = Vector2(650,440)
    b.attack(1)
    check(enemy.hp == 3,"closed rear knot also resists attacks")
    b = fixture()
    b.facing[0] = Vector2.RIGHT
    b.guarding = true
    advance(b,0.6)
    enemy = b.enemies[0]
    check(enemy.mode == "exposed" and enemy.timer > 2 and b.hp[0] == 3,"real frontal shield contact stops charge and exposes knot")
    check(enemy.pos.x > b.positions[0].x+40,"shield stops enemy outside girl body")
    var timer: float = enemy.timer
    advance(b,0.2)
    check(enemy.timer < timer,"contact cannot repeatedly refresh exposure")
    b.positions[1] = enemy.pos+Vector2(65,0)
    b.facing[1] = Vector2.LEFT
    b.attack(1)
    advance(b,0.15)
    check(enemy.hp == 2,"cat damages exposed rear knot")
    b.guarding = false
    b.positions[0] = enemy.pos+Vector2(65,0)
    b.facing[0] = Vector2.LEFT
    b.attack(0)
    check(enemy.hp == 1,"girl can also damage exposed rear knot")
    b.attack_cooldown[0] = 0
    b.positions[0] = enemy.pos-Vector2(65,0)
    b.facing[0] = Vector2.RIGHT
    b.attack(0)
    check(enemy.hp == 1,"exposure does not remove front armor")
    var angle: Vector2 = enemy.direction
    advance(b,0.1,Vector2.DOWN)
    check(enemy.direction == angle,"exposed enemy cannot turn weak point away mid-window")
    timer = enemy.timer
    var point: Vector2 = enemy.pos
    b.step(0.1,Vector2.RIGHT,Vector2.LEFT,false)
    check(enemy.timer == timer and enemy.pos == point,"pause freezes exposure")
    b = fixture()
    b.facing[0] = Vector2.LEFT
    b.guarding = true
    advance(b,0.7)
    check(b.enemies[0].mode != "exposed" and b.hp[0] == 2,"wrong-facing shield does not create opening")
    b = fixture()
    b.enemies[0].pos = Vector2(370,440)
    b.enemies[0].mode = "rush"
    b.enemies[0].timer = 0.4
    b.facing[0] = Vector2.RIGHT
    b.guarding = true
    advance(b,0.05)
    check(b.enemies[0].mode != "exposed", "shield cannot catch an enemy already behind the body")
    b = fixture()
    b.invulnerable[0] = 3
    advance(b,0.7)
    check(b.enemies[0].mode != "exposed" and b.hp[0] == 3,"invulnerability alone is not a shield block")
    b = fixture()
    b.dodge_time[0] = 0.7
    b.dodge_direction[0] = Vector2.DOWN
    advance(b,0.5)
    check(b.enemies[0].mode != "exposed","dodge alone never exposes armor")
    # Incoming charge meets a stump before the player standing behind it.
    b = fixture()
    enemy = b.enemies[0]
    enemy.pos = Vector2(720,320)
    enemy.direction = Vector2.LEFT
    b.positions[0] = Vector2(450,320)
    advance(b,0.65)
    check(enemy.mode == "exposed" and enemy.pos.x > 615 and b.hp[0] == 3,"first stump collision stops swept charge before protected player")
    check(enemy.timer <= 2.0,"stump opening uses its own duration")
    b = fixture()
    enemy = b.enemies[0]
    enemy.pos = Vector2(850,320)
    enemy.direction = Vector2.LEFT
    b.positions[0] = Vector2(750,320)
    b.guarding = true
    b.facing[0] = Vector2.RIGHT
    advance(b,0.4)
    check(enemy.mode == "exposed" and enemy.pos.x > 800,"shield before stump wins collision ordering")
    b = fixture()
    enemy = b.enemies[0]
    enemy.pos = Vector2(160,440)
    enemy.direction = Vector2.LEFT
    b.positions[0] = Vector2(700,440)
    advance(b,0.7)
    check(enemy.mode == "rest","field edge is not an exposure shortcut")
    b = B.new()
    b.positions[0] = Vector2(490,320)
    b.dodge(0,Vector2.RIGHT)
    advance(b,0.25,Vector2.RIGHT)
    check(b.positions[0].x <= 510,"dodge cannot tunnel through stump")
    b = B.new()
    b._start_wave(3)
    b.positions[0] = Vector2(850,430)
    b.positions[1] = Vector2(900,590)
    b.enemies[0].timer = 0
    b.enemies[1].timer = 0
    advance(b,0.02)
    var busy := 0
    for e in b.enemies:
        if e.mode in ["windup","rush"]: busy += 1
    check(busy == 1,"mixed round staggers charge telegraphs")
    enemy = b.enemies[0]
    angle = enemy.direction
    b.switch_cat()
    advance(b,0.1)
    check(enemy.direction == angle,"switching cats does not retarget locked telegraph")
    b = B.new()
    b._start_wave(1)
    b.enemies[0].hp = 0
    b.hp[1] = 0
    advance(b,4)
    b.interact(0)
    check(b.wave == 1 and b.enemies.is_empty(),"cleared wave waits for downed partner")
    b.positions[1] = b.positions[0]+Vector2(40,0)
    b.interact(0)
    advance(b,1.3)
    b.interact(0)
    check(b.wave == 1,"one confirmation cannot start next round")
    b.interact(1)
    check(b.wave == 2 and b.enemies[0].kind == "armored","both ready after rescue starts tutorial round")
    b.hp[0] = 0
    b.hp[1] = 0
    advance(b,2.1)
    check(b.wave == 2 and b.hp == [3,3] and b.enemies[0].mode != "exposed","wipe retries only current round without stale opening")
    finish()
func finish() -> void:
    print("ARMOR: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
