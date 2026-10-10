extends RefCounted
const Space = preload("res://game/battle_space.gd")
const CHARGE_SECONDS := 0.48
const BUFFER_SECONDS := 0.18
const HURT_LOCK := 0.08
var charging := false
var charge_time := 0.0
var pounce_left := 0.0
var pounce_hit := false
var kinds: Array[String] = ["sword", "pounce"]
var durations: Array[float] = [0.30,0.28]
var pending: Array[float] = [-1.0,-1.0]
var buffered: Array[float] = [0.0,0.0]
var buffered_release := false
var combo := 0
var combo_window := 0.0
var current_combo := 0
var impact_times: Array[float] = [0.065,0.0]

func available(b, slot: int) -> bool:
    return slot >= 0 and slot <= 1 and b.hp[slot] > 0 and b.attack_cooldown[slot] <= 0 and b.dodge_time[slot] <= 0 and b.contact_hold[slot] <= 0 and b.hurt_time[slot] <= 0.22-HURT_LOCK+0.00001 and b.phase != "complete" and not (slot == 0 and b.guarding)

func aim(b, slot: int) -> Vector2:
    var direction: Vector2 = b.facing[slot]
    var nearest := INF
    for enemy in b.enemies:
        if enemy.hp <= 0: continue
        var offset: Vector2 = enemy.pos-b.positions[b.actor(slot)]
        if offset.length() < nearest and offset.length() < 155 and offset.length() > 0.1 and b.facing[slot].dot(offset.normalized()) >= cos(deg_to_rad(14)) and Space.clear_line(b.positions[b.actor(slot)],enemy.pos,0):
            direction = offset.normalized()
            nearest = offset.length()
    return direction

func press(b, slot: int) -> void:
    if slot < 0 or slot > 1 or b.hp[slot] <= 0 or b.phase == "complete": return
    if not available(b,slot):
        var remaining := maxf(b.attack_cooldown[slot],maxf(b.dodge_time[slot],b.hurt_time[slot]-(0.22-HURT_LOCK)))
        var after_contact: bool = pending[slot] < 0 and b.attack_flash[slot] > 0
        if not (slot == 0 and b.guarding) and (after_contact or remaining <= BUFFER_SECONDS):
            buffered[slot] = remaining+BUFFER_SECONDS
        return
    if slot == 1 and charging: return
    buffered[slot] = 0
    b.hurt_time[slot] = 0
    if b.rescuer == slot: b._cancel_rescue()
    b.attack_direction[slot] = aim(b,slot)
    if slot == 0:
        current_combo = combo if combo_window > 0 else 0
        combo = (current_combo+1)%3
        combo_window = 0.85
        kinds[0] = "sword"
        _begin(b,0,0.38 if current_combo == 2 else 0.30,0.11 if current_combo == 2 else 0.065)
    elif b.current_cat == 1:
        kinds[1] = "pounce"
        pounce_left = 72
        pounce_hit = false
        _begin(b,1,0.28,-1)
    else:
        charging = true
        charge_time = 0
        kinds[1] = "charge"
        b.feedback("charge",b.positions[2],1)

func _begin(b, slot: int, duration: float, impact: float) -> void:
    durations[slot] = duration
    b.attack_cooldown[slot] = duration
    b.attack_flash[slot] = duration
    pending[slot] = impact
    impact_times[slot] = maxf(0,impact)
    b.feedback("swing",b.positions[b.actor(slot)],slot,{"attack":kinds[slot],"direction":b.attack_direction[slot],"combo":current_combo if slot == 0 else 0})

func release(b, slot: int) -> void:
    if slot != 1: return
    if buffered[1] > 0 and not charging:
        buffered_release = true
        return
    if not charging: return
    var heavy := charge_time >= CHARGE_SECONDS-0.00001
    charging = false
    charge_time = 0
    if b.current_cat != 2 or not available(b,1): return
    b.attack_direction[1] = aim(b,1)
    kinds[1] = "heavy" if heavy else "slap"
    _begin(b,1,0.44 if heavy else 0.28,0.105 if heavy else 0.05)

func cancel(b, slot := -1) -> void:
    if slot != 0:
        charging = false
        charge_time = 0
        pounce_left = 0
        pounce_hit = false
        buffered_release = false
    if slot != 1:
        combo = 0
        combo_window = 0
    for index in range(2):
        if slot == -1 or slot == index:
            b.contact_hold[index] = 0
            b.attack_flash[index] = 0
            pending[index] = -1
            buffered[index] = 0

func step(b, dt: float) -> bool:
    combo_window = maxf(0,combo_window-b.action_dt[0])
    for enemy in b.enemies:
        var pause: float = enemy.get("impact_pause",0.0)
        var local_dt := maxf(0,dt-pause)
        enemy.impact_pause = maxf(0,pause-dt)
        enemy.simulation_dt = local_dt
        enemy.impact_age = enemy.get("impact_age",1.0)+local_dt
        enemy.control_immune = maxf(0,enemy.get("control_immune",0.0)-local_dt)
        enemy.control_time = maxf(0,enemy.get("control_time",0.0)-local_dt)
        enemy.mark_time = maxf(0,enemy.get("mark_time",0.0)-local_dt)
    for slot in range(2):
        var local_dt: float = b.action_dt[slot]
        if pending[slot] >= 0:
            pending[slot] -= local_dt
            if pending[slot] <= 0:
                pending[slot] = -1
                if slot == 0: strike(b,0,112,PI/3,2 if current_combo == 2 else 1,false,current_combo == 2)
                else: strike(b,1,105 if kinds[1] == "heavy" else 82,PI/2 if kinds[1] == "heavy" else PI/3,3 if kinds[1] == "heavy" else 1,false,kinds[1] == "heavy")
        if buffered[slot] > 0:
            if available(b,slot):
                var quick_release := slot == 1 and buffered_release
                buffered_release = false if slot == 1 else buffered_release
                press(b,slot)
                if quick_release: release(b,slot)
            else:
                buffered[slot] = maxf(0,buffered[slot]-local_dt)
                if slot == 1 and buffered[slot] <= 0: buffered_release = false
    if charging:
        var before := charge_time
        charge_time = minf(CHARGE_SECONDS,charge_time+b.action_dt[1])
        if before < CHARGE_SECONDS and charge_time >= CHARGE_SECONDS: b.feedback("ready",b.positions[2],1)
    var was_pouncing := pounce_left > 0
    if was_pouncing and b.action_dt[1] > 0 and b.contact_hold[1] <= 0:
        var origin: Vector2 = b.positions[1]
        var amount := minf(pounce_left,520*b.action_dt[1])
        var end: Vector2 = Space.move(origin,b.attack_direction[1]*amount,Space.ACTOR_RADIUS)
        var contact := 1.0
        for enemy in b.enemies:
            if enemy.hp <= 0: continue
            var t := Space.contact(origin,end,enemy.pos,Space.ACTOR_RADIUS+Space.ENEMY_RADIUS)
            if t != INF: contact = minf(contact,maxf(0,t-0.001))
        b.positions[1] = origin.lerp(end,contact)
        pounce_left = maxf(0,pounce_left-amount)
        if contact < 1 or origin.distance_to(end) < amount*0.5: pounce_left = 0
        if not pounce_hit: pounce_hit = strike(b,1,67,PI/5,1,true,false)
    return was_pouncing

func strike(b, slot: int, reach: float, half_angle: float, damage: int, single: bool, heavy: bool) -> bool:
    var origin: Vector2 = b.positions[b.actor(slot)]
    var direction: Vector2 = b.attack_direction[slot]
    var seed_hit: bool = b.garden.strike(b,origin,direction,reach,half_angle,heavy)
    var targets: Array[Dictionary] = []
    for enemy in b.enemies:
        if enemy.hp <= 0: continue
        var offset: Vector2 = enemy.pos-origin
        if offset.length() <= reach and (offset.length() < 0.01 or direction.dot(offset.normalized()) >= cos(half_angle)) and Space.clear_line(origin,enemy.pos,0): targets.append(enemy)
    targets.sort_custom(func(a,c): return origin.distance_squared_to(a.pos) < origin.distance_squared_to(c.pos))
    for enemy in targets:
        var blocked: bool = enemy.kind == "armored" and (enemy.mode != "exposed" or enemy.direction.dot(enemy.pos.direction_to(origin)) > -0.258819)
        if blocked:
            enemy.bounce = 0.2
            b.feedback("blocked",enemy.pos,slot,{"direction":direction,"attack":kinds[slot]})
            if b.hp[0] > 0 and b.hp[1] > 0: b.message = "树皮挡住了！盾挡或引它撞树桩，再绕到背后。"
        else:
            var amount := float(damage)
            if enemy.kind == "elder":
                if enemy.mode == "exposed": amount *= 1.5
                elif enemy.direction.dot(enemy.pos.direction_to(origin)) > 0.2: amount *= 0.4
            enemy.hp = maxf(0,enemy.hp-amount)
            enemy.flash = 0.13
            b.feedback("heavy" if heavy else "hit",enemy.pos,slot,{"direction":direction,"attack":kinds[slot]})
            if slot == 1 and b.current_cat == 1:
                enemy.mark_time = 1.8
                enemy.assist_used = false
                if enemy.mode in ["cast","melee_windup"] and enemy.get("control_immune",0.0) <= 0:
                    enemy.mode = "rest"
                    enemy.timer = 0.7
                    enemy.control_immune = 2.2
                    b.feedback("interrupt",enemy.pos,slot)
                    b.message = "团团打断了！朵朵接上连击，或团团继续追击。" if b.story_first else "团团打断了！换圆圆，接重拍或继续追击。"
            var yuanyuan_heavy: bool = heavy and slot == 1 and b.current_cat == 2
            if yuanyuan_heavy and enemy.hp > 0:
                if enemy.kind == "armored":
                    if not enemy.get("heavy_extended",false):
                        enemy.timer += 0.5
                        enemy.heavy_extended = true
                elif enemy.mode != "rush" and (enemy.get("control_immune",0.0) <= 0 or enemy.get("mark_time",0.0) > 0):
                    var combo_hit: bool = enemy.get("mark_time",0.0) > 0
                    enemy.pos = Space.move(enemy.pos,direction*(54 if combo_hit else 32),Space.ENEMY_RADIUS)
                    enemy.mode = "rest"
                    enemy.timer = 0.0
                    enemy.control_time = 0.8 if combo_hit else 0.28
                    enemy.control_immune = 2.2
                    if combo_hit:
                        enemy.mark_time = 0
                        b.feedback("combo",enemy.pos,slot)
                        b.message = "接住机会！圆圆把它掀翻了。"
            elif heavy and slot == 0 and enemy.hp > 0 and enemy.kind != "armored" and enemy.mode != "rush":
                enemy.pos = Space.move(enemy.pos,direction*22,Space.ENEMY_RADIUS)
            elif enemy.kind in ["sprout","weaver"] and enemy.mode not in ["rush","cast","melee_windup"]:
                enemy.pos = Space.move(enemy.pos,direction*12,Space.ENEMY_RADIUS)
        b.contact(enemy,slot,direction,heavy,blocked)
        if single: break
    return not targets.is_empty() or seed_hit
