extends RefCounted
# Test-only controller: observes game state and sends normal keyboard events.
var host
var b
var shield_openings := 0
var stump_openings := 0
var collision_openings := 0
var tracked: Array = []
func _init(owner, battle) -> void:
    host = owner
    b = battle
func drive(slot: int, direction: Vector2) -> void:
    host.drive(slot,direction)
func tap(code: int) -> void:
    host.tap_key(code)
func shield(value: bool) -> void:
    if b.guarding != value: host.key_event(KEY_G,value)
func toward(point: Vector2,goal: Vector2) -> Vector2:
    return b.Space.direction(point,goal,b.Space.ACTOR_RADIUS)
func observe() -> void:
    for enemy in b.enemies:
        if enemy.kind == "armored" and enemy.mode == "exposed" and not tracked.any(func(e): return is_same(e,enemy)):
            tracked.append(enemy)
            if enemy.opening == "shield": shield_openings += 1
            if enemy.opening == "stump": stump_openings += 1
            if enemy.opening == "collision": collision_openings += 1
func step_slot(slot: int) -> void:
    observe()
    if b.hp[slot] <= 0:
        drive(slot,Vector2.ZERO)
        return
    var point: Vector2 = b.positions[b.actor(slot)]
    if b.hp[1-slot] <= 0:
        if slot == 0: shield(false)
        var partner: Vector2 = b.positions[b.actor(1-slot)]
        if point.distance_to(partner) <= 70:
            drive(slot,Vector2.ZERO)
            if b.rescuer < 0: tap(KEY_E if slot == 0 else KEY_SPACE)
        else: drive(slot,toward(point,partner))
        return
    if b.phase == "intermission":
        if slot == 0: shield(false)
        drive(slot,Vector2.ZERO)
        if b.intermission <= 0: tap(KEY_E if slot == 0 else KEY_SPACE)
        return
    if b.phase != "combat":
        if slot == 0: shield(false)
        drive(slot,Vector2.ZERO)
        return
    var target: Dictionary = {}
    var nearest := INF
    for enemy in b.enemies:
        if enemy.hp <= 0: continue
        var distance: float = point.distance_to(enemy.pos)
        if distance < nearest:
            target = enemy
            nearest = distance
    if target.is_empty():
        drive(slot,Vector2.ZERO)
        return
    var movement := Vector2.ZERO
    var can_attack := true
    var defending := false
    if target.kind == "armored":
        var aim: Vector2 = target.direction if target.mode != "approach" else target.pos.direction_to(b.positions[0])
        if slot == 0 and target.mode != "exposed":
            defending = true
            can_attack = false
            # Face the threat using a brief normal movement input, then hold shield.
            if b.facing[0].dot(point.direction_to(target.pos)) < 0.9:
                movement = point.direction_to(target.pos)
            elif point.distance_to(target.pos) > 130:
                movement = toward(point,target.pos)
        else:
            var rear: Vector2 = target.pos-aim*(72 if target.mode == "exposed" else (92 if target.mode in ["windup","rush"] else 170))
            rear = rear.clamp(b.FIELD.position+Vector2(10,10),b.FIELD.end-Vector2(10,10))
            movement = toward(point,rear) if point.distance_to(rear) > 13 else Vector2.ZERO
            can_attack = target.mode == "exposed" and aim.dot(target.pos.direction_to(point)) <= -0.3
    elif nearest > (85 if slot == 0 else 70):
        movement = toward(point,target.pos)
    # Avoid another charging lane; shield may handle a frontal threat.
    for threat in b.enemies:
        if threat.mode in ["cast","burst","slam_windup","slam","melee_windup","melee"] and b.Encounter.danger(threat,point,24):
            var origin: Vector2 = threat.get("aim",threat.pos) if threat.mode in ["cast","burst"] else threat.pos
            movement = origin.direction_to(point)
            if movement.length() < 0.1: movement = Vector2.UP
            if not b.Space.valid(point+movement*100,b.Space.ACTOR_RADIUS): movement = -movement
            drive(slot,movement)
            if slot == 0: shield(false)
            if threat.timer < 0.3: tap(KEY_Q if slot == 0 else KEY_K)
            return
        if threat.mode not in ["windup","rush"]: continue
        var end: Vector2 = threat.pos+threat.direction*(364 if threat.kind == "roller" else 230)
        var closest := Geometry2D.get_closest_point_to_segment(point,threat.pos,end)
        if point.distance_to(closest) >= 65: continue
        if slot == 0 and b.facing[0].dot(-threat.direction) >= 0.25:
            defending = true
            can_attack = false
            movement = Vector2.ZERO
        else:
            var side: Vector2 = threat.direction.orthogonal()
            if not b.Space.valid(point+side*100,b.Space.ACTOR_RADIUS): side = -side
            movement = side
            if (threat.mode == "rush" or threat.timer < 0.25) and b.dodge_cooldown[slot] <= 0:
                drive(slot,movement)
                tap(KEY_Q if slot == 0 else KEY_K)
                if slot == 0: defending = false
    var attack_reach := 106.0 if slot == 0 else (91.0 if b.current_cat == 1 else 77.0)
    if can_attack and nearest < attack_reach and not defending and b.dodge_time[slot] <= 0:
        var aim_to_target: Vector2 = point.direction_to(target.pos)
        # M9 attacks face the last movement; the driver must aim with real input.
        movement = aim_to_target if b.facing[slot].dot(aim_to_target) < 0.94 else Vector2.ZERO
    if slot == 0: shield(defending)
    drive(slot,movement)
    if can_attack and nearest < attack_reach and b.facing[slot].dot(point.direction_to(target.pos)) >= 0.94 and b.attack_cooldown[slot] <= 0 and b.dodge_time[slot] <= 0:
        tap(KEY_F if slot == 0 else KEY_J)
