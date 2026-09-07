extends RefCounted
# Attack lifecycle and hit resolution; no ownership reference back to Battle.
const Space = preload("res://game/battle_space.gd")
const CHARGE_SECONDS := 0.6
var charging := false
var charge_time := 0.0
var pounce_left := 0.0
var pounce_hit := false
var kinds: Array[String] = ["sword", "pounce"]

func available(b, slot: int) -> bool:
    return slot >= 0 and slot <= 1 and b.hp[slot] > 0 and b.attack_cooldown[slot] <= 0 and b.dodge_time[slot] <= 0 and b.phase != "complete" and not (slot == 0 and b.guarding)

func press(b, slot: int) -> void:
    if not available(b,slot) or (slot == 1 and charging): return
    if b.rescuer == slot: b._cancel_rescue()
    b.attack_direction[slot] = b.facing[slot]
    if slot == 0:
        kinds[0] = "sword"
        b.attack_cooldown[0] = 0.5
        b.attack_flash[0] = 0.24
        strike(b,0,110,PI/3,1,false,false)
    elif b.current_cat == 1:
        kinds[1] = "pounce"
        b.attack_cooldown[1] = 0.35
        b.attack_flash[1] = 0.22
        pounce_left = 45
        pounce_hit = false
    else:
        charging = true
        charge_time = 0
        kinds[1] = "charge"

func release(b, slot: int) -> void:
    if slot != 1 or not charging: return
    var heavy := charge_time >= CHARGE_SECONDS-0.00001
    charging = false
    charge_time = 0
    if b.current_cat != 2 or not available(b,1): return
    b.attack_direction[1] = b.facing[1]
    kinds[1] = "heavy" if heavy else "slap"
    b.attack_cooldown[1] = 0.9 if heavy else 0.7
    b.attack_flash[1] = 0.3 if heavy else 0.22
    strike(b,1,80,PI/4,2 if heavy else 1,false,heavy)

func cancel(b, slot := -1) -> void:
    if slot != 0:
        charging = false
        charge_time = 0
        pounce_left = 0
        pounce_hit = false
    for index in range(2):
        if slot == -1 or slot == index: b.attack_flash[index] = 0

func step(b, dt: float) -> bool:
    for enemy in b.enemies:
        enemy.control_immune = maxf(0,enemy.get("control_immune",0.0)-dt)
        enemy.control_time = maxf(0,enemy.get("control_time",0.0)-dt)
    if charging:
        charge_time = minf(CHARGE_SECONDS,charge_time+dt)
    var was_pouncing := pounce_left > 0
    if was_pouncing:
        var origin: Vector2 = b.positions[1]
        var amount := minf(pounce_left,375*dt)
        var end: Vector2 = Space.move(origin,b.attack_direction[1]*amount,Space.ACTOR_RADIUS)
        var contact := 1.0
        for enemy in b.enemies:
            if enemy.hp <= 0: continue
            var t := Space.contact(origin,end,enemy.pos,Space.ACTOR_RADIUS+Space.ENEMY_RADIUS)
            if t != INF: contact = minf(contact,maxf(0,t-0.001))
        b.positions[1] = origin.lerp(end,contact)
        pounce_left = maxf(0,pounce_left-amount)
        if contact < 1 or origin.distance_to(end) < amount*0.5: pounce_left = 0
        if not pounce_hit:
            pounce_hit = strike(b,1,65,PI/6,1,true,false)
    return was_pouncing

func strike(b, slot: int, reach: float, half_angle: float, damage: int, single: bool, heavy: bool) -> bool:
    var origin: Vector2 = b.positions[b.actor(slot)]
    var direction: Vector2 = b.attack_direction[slot]
    var targets: Array[Dictionary] = []
    for enemy in b.enemies:
        if enemy.hp <= 0: continue
        var offset: Vector2 = enemy.pos-origin
        if offset.length() <= reach and (offset.length() < 0.01 or direction.dot(offset.normalized()) >= cos(half_angle)) and Space.clear_line(origin,enemy.pos,0):
            targets.append(enemy)
    targets.sort_custom(func(a,c): return origin.distance_squared_to(a.pos) < origin.distance_squared_to(c.pos))
    for enemy in targets:
        if enemy.kind == "armored" and (enemy.mode != "exposed" or enemy.direction.dot(enemy.pos.direction_to(origin)) > -0.258819):
            enemy.bounce = 0.2
            if b.hp[0] > 0 and b.hp[1] > 0:
                b.message = "树皮挡住了！用盾或树桩让它撞停，再打背后展开的结点。"
        else:
            enemy.hp = maxi(0,enemy.hp-damage)
            enemy.flash = 0.16
            if heavy and enemy.hp > 0:
                if enemy.kind == "armored":
                    if not enemy.get("heavy_extended",false):
                        enemy.timer += 0.5
                        enemy.heavy_extended = true
                elif enemy.mode != "rush" and enemy.get("control_immune",0.0) <= 0:
                    enemy.pos = Space.move(enemy.pos,direction*35,Space.ENEMY_RADIUS)
                    enemy.mode = "rest"
                    enemy.timer = 0.0
                    enemy.control_time = 0.4
                    enemy.control_immune = 2.5
        if single: break
    return not targets.is_empty()
