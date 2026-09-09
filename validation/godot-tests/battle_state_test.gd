extends SceneTree
const Battle = preload("res://game/battle_state.gd")
var checks := 0
var failed := 0
func check(value: bool, label: String) -> void:
    checks += 1
    if not value:
        failed += 1
        push_error("FAIL: " + label)
func advance(b, seconds: float, a := Vector2.ZERO, c := Vector2.ZERO) -> void:
    for i in range(ceili(seconds * 60)):
        b.step(1.0 / 60.0, a, c, true)
func start(b) -> void:
    b.interact(0)
    b.interact(1)
func _initialize() -> void:
    var b = Battle.new()
    check(b.hp == [3, 3] and b.phase == "briefing", "safe briefing starts with two health pools")
    b.interact(0)
    check(b.enemies.is_empty(), "both players must confirm combat start")
    b.interact(1)
    check(b.wave == 1 and b.enemies.size() == 3, "first wave starts after both confirmations")
    var snapshot: Array = b.positions.duplicate()
    var timer: float = b.enemies[0].timer
    b.step(0.1, Vector2.RIGHT, Vector2.LEFT, false)
    check(b.positions == snapshot and b.enemies[0].timer == timer, "pause freezes movement and enemy clocks")
    b.positions[0] = Vector2(700, 440)
    b.enemies[0].pos = Vector2(780, 440)
    b.attack(0)
    advance(b,0.08)
    check(b.enemies[0].hp == 4, "wood sword damages nearby enemy")
    b.attack(0)
    advance(b,0.08)
    check(b.enemies[0].hp == 4, "attack cannot bypass cooldown by button spam")
    b.positions[0] = Vector2(300, 450)
    b.facing[0] = Vector2.RIGHT
    b.guarding = true
    check(not b.hurt(0, Vector2(400, 450)) and b.hp[0] == 3, "held shield blocks attacks from front")
    check(b.hurt(0, Vector2(200, 450)) and b.hp[0] == 2, "shield does not block attacks from behind")
    check(not b.hurt(0, Vector2(200, 450)), "post-hit invulnerability prevents stacked hits")
    b.invulnerable[0] = 0
    b.guarding = false
    b.dodge(0, Vector2.DOWN)
    check(not b.hurt(0, Vector2(300, 350)), "dodge provides brief invulnerability")
    var before: Vector2 = b.positions[0]
    advance(b, 0.2)
    check(b.positions[0].distance_to(before) > 60, "dodge actually moves the character")
    b.hp[1] = 0
    var cat: int = b.current_cat
    b.switch_cat()
    check(b.current_cat == cat and b.hp[1] == 0, "cannot switch cats to escape downed state")
    b.positions[0] = Vector2(300, 450)
    b.positions[cat] = Vector2(350, 450)
    b.dodge_time[0] = 0
    b.interact(0)
    advance(b, 0.4, Vector2.LEFT)
    check(b.rescuer == -1 and b.hp[1] == 0, "moving cancels rescue without reviving")
    b.positions[0] = Vector2(300, 450)
    b.interact(0)
    advance(b, 1.3)
    check(b.hp[1] == 2 and b.invulnerable[1] > 0, "stationary rescue restores health and grace period")
    b.hp[1] = 1
    b.invulnerable[1] = 0.7
    b.attack_cooldown[1] = 0.3
    b.switch_cat()
    check(b.hp[1] == 1 and is_equal_approx(b.invulnerable[1], 0.7) and is_equal_approx(b.attack_cooldown[1], 0.3), "switch preserves cat health and recovery timers")
    b = Battle.new()
    start(b)
    for enemy in b.enemies: enemy.hp = 0
    advance(b, 0.1)
    check(b.phase == "intermission", "cleared first wave offers breathing room")
    advance(b, 3.2)
    check(b.wave == 2 and b.enemies.size() == 3, "intermission automatically starts next wave without repeated confirmation")
    start(b)
    check(b.wave == 2 and b.enemies.size() == 3, "second wave combines armor, caster and melee")
    b.hp[0] = 0
    b.hp[1] = 0
    advance(b, 2.2)
    check(b.wave == 2 and b.hp == [3, 3] and b.enemies.size() == 3, "team wipe retries current wave without replaying previous wave")
    for enemy in b.enemies: enemy.hp = 0
    advance(b,3.2)
    start(b)
    for enemy in b.enemies: enemy.hp = 0
    advance(b, 0.1)
    check(b.phase == "clear", "all waves unlock camp exit")
    b.positions[0] = Battle.EXIT
    b.positions[b.current_cat] = Battle.EXIT + Vector2(-40, 0)
    b.interact(0)
    check(b.phase == "clear", "one player cannot finish alone")
    b.positions[0] = Vector2(300, 450)
    b.step(0.01, Vector2.ZERO, Vector2.ZERO, true)
    b.positions[0] = Battle.EXIT
    b.interact(1)
    check(b.phase == "clear", "leaving camp clears stale confirmation")
    b.interact(0)
    check(b.phase == "complete", "both players at camp complete combat stage")
    b = Battle.new()
    start(b)
    b.enemies.resize(1)
    b.positions[0] = Vector2(600, 440)
    b.positions[1] = Vector2(200, 600)
    b.enemies[0].pos = Vector2(820, 440)
    b.enemies[0].timer = 0
    advance(b, 0.02)
    check(b.enemies[0].mode == "windup", "enemy telegraphs before charging")
    var aim: Vector2 = b.enemies[0].direction
    advance(b, 0.3, Vector2.DOWN)
    check(b.enemies[0].direction == aim, "telegraphed aim stays locked so dodge is readable")
    advance(b, 1.5)
    check(b.hp[0] == 3, "moving out of warning lane avoids charge")
    b = Battle.new()
    start(b)
    b.enemies.resize(1)
    b.positions[0] = Vector2(600, 440)
    b.positions[1] = Vector2(200, 620)
    b.enemies[0].pos = Vector2(780, 440)
    b.enemies[0].timer = 0
    advance(b, 1.5)
    check(b.hp[0] == 2, "standing in telegraphed lane takes exactly one hit per charge")
    b = Battle.new()
    start(b)
    b.enemies.resize(1)
    b.positions[0] = Vector2(600, 440)
    b.positions[1] = Vector2(200, 620)
    b.enemies[0].pos = Vector2(780, 440)
    b.enemies[0].timer = 0
    b.guarding = true
    advance(b, 1.5)
    check(b.hp[0] == 3, "front shield blocks actual swept enemy charge")
    b.hp[1] = 0
    b.positions[1] = b.positions[0] + Vector2(50, 0)
    b.interact(0)
    advance(b, 0.2)
    b.guarding = false
    b.hurt(0, b.positions[0] + Vector2.RIGHT * 50)
    check(b.rescuer == -1 and b.hp[1] == 0, "damage interrupts an in-progress rescue")
    b.hp[0] = 0
    b.attack_cooldown[0] = 0
    b.attack(0)
    advance(b,0.08)
    check(b.attack_cooldown[0] == 0, "downed player cannot attack")
    b = Battle.new()
    b._start_wave(3)
    b.positions[0] = Vector2(820, 570)
    b.positions[1] = Vector2(200, 620)
    var rolling: Dictionary = b.enemies[2]
    b.enemies.clear()
    b.enemies.append(rolling)
    b.enemies[0].pos = Vector2(1010,570)
    b.enemies[0].timer = 0
    advance(b, 0.9)
    check(b.enemies[0].kind == "roller" and b.enemies[0].mode == "windup" and b.hp[0] == 3, "rolling enemy has longer safe telegraph")
    advance(b, 1.0)
    check(b.hp[0] == 2 and b.enemies[0].mode == "rest", "rolling charge hits once then exposes recovery window")
    print("BATTLE_STATE: %d checks, %d failed" % [checks, failed])
    quit(1 if failed else 0)
