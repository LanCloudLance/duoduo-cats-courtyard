extends RefCounted
# Local game AI: reacts to visible telegraphs and uses normal character actions.
const Space = preload("res://game/battle_space.gd")
var decision_time := 0.22
var attack_wait := 0.0
var movement := Vector2.ZERO
var status := "跟随你"

func reset() -> void:
    movement = Vector2.ZERO
    decision_time = 0.22
    attack_wait = 0.25
    status = "等待接应"

func path(point: Vector2, goal: Vector2, enemies: Array) -> Vector2:
    if point.distance_to(goal) < 9: return Vector2.ZERO
    var heading := Space.direction(point,goal,Space.ACTOR_RADIUS)
    # Walk around bodies instead of taking a straight shortcut through armor.
    for enemy in enemies:
        if enemy.hp <= 0: continue
        var radial: Vector2 = enemy.pos.direction_to(point)
        if point.distance_to(enemy.pos) < 55:
            return radial if radial.length() > 0.1 else Vector2.DOWN
        if Space.contact(point,point+heading*20,enemy.pos,50) != INF:
            var side: Vector2 = radial.orthogonal()
            if side.dot(point.direction_to(goal)) < 0: side = -side
            if not Space.valid(point+side*55,Space.ACTOR_RADIUS): side = -side
            return (side+radial*0.2).normalized()
    return heading

func safe_movement(b, slot: int, dt: float, heading: Vector2) -> Vector2:
    var point: Vector2 = b.positions[b.actor(slot)]
    var end: Vector2 = point+heading*215*dt
    var fraction := 1.0
    for enemy in b.enemies:
        if enemy.hp <= 0: continue
        if point.distance_to(enemy.pos) < 44 and end.distance_to(enemy.pos) > point.distance_to(enemy.pos): continue
        var t := Space.contact(point,end,enemy.pos,44)
        if t != INF: fraction = minf(fraction,maxf(0,t-0.001))
    return heading*fraction

func step(b, slot: int, human: int, dt: float, engaged: bool) -> Vector2:
    decision_time -= dt
    attack_wait = maxf(0,attack_wait-dt)
    if b.hp[slot] <= 0 or b.phase == "complete":
        movement = Vector2.ZERO
        status = "等待救援" if b.hp[slot] <= 0 else "一起休息"
        return movement
    if decision_time > 0: return movement
    decision_time = 0.18
    movement = Vector2.ZERO
    if slot == 0: b.guarding = false
    var point: Vector2 = b.positions[b.actor(slot)]
    var partner: Vector2 = b.positions[b.actor(human)]
    if b.phase == "combat":
        for threat in b.enemies:
            if threat.hp <= 0 or threat.mode not in ["windup","rush"]: continue
            var end: Vector2 = threat.pos+threat.direction*(364 if threat.kind == "roller" else 230)
            var closest := Geometry2D.get_closest_point_to_segment(point,threat.pos,end)
            if point.distance_to(closest) > 72: continue
            if slot == 0 and b.facing[0].dot(-threat.direction) >= 0.5 and b.facing[0].dot(point.direction_to(threat.pos)) >= 0.25:
                b.guarding = b.dodge_time[0] <= 0
                status = "正面举盾"
            else:
                var side: Vector2 = threat.direction.orthogonal()
                if not Space.valid(point+side*100,Space.ACTOR_RADIUS): side = -side
                movement = side
                if threat.mode == "rush" or threat.timer < 0.45:
                    b.dodge(slot,side)
                status = "躲开冲锋"
            if b.rescuer == slot: b._cancel_rescue()
            if slot == 1 and b.attacks.charging: b.attacks.cancel(b,1)
            return movement
    if b.hp[human] <= 0:
        status = "赶来救援"
        if point.distance_to(partner) < 72:
            if b.rescuer != slot: b.interact(slot)
            status = "正在扶起你"
        else:
            movement = path(point,partner,b.enemies)
        return movement
    if b.phase != "combat" or not engaged:
        if slot == 1 and b.attacks.charging: b.attacks.cancel(b,1)
        status = "跟随你" if b.phase != "combat" else "等你创造机会"
        var goal: Vector2 = partner+Vector2(-65,55)
        if b.phase == "clear" and partner.distance_to(b.EXIT) < 100: goal = b.EXIT+Vector2(-20,25)
        goal = goal.clamp(b.FIELD.position+Vector2(25,25),b.FIELD.end-Vector2(25,25))
        if point.distance_to(goal) > 45: movement = path(point,goal,b.enemies)
        return movement
    var target: Dictionary = {}
    var distance := INF
    for enemy in b.enemies:
        if enemy.hp <= 0: continue
        var candidate: float = point.distance_to(enemy.pos)
        if candidate < distance:
            target = enemy
            distance = candidate
    if target.is_empty(): return movement
    if target.kind == "armored":
        if target.mode != "exposed":
            if slot == 0:
                status = "正面接应"
                if b.facing[0].dot(point.direction_to(target.pos)) < 0.9:
                    movement = point.direction_to(target.pos)
                else:
                    b.guarding = b.dodge_time[0] <= 0
                    if distance > 145: movement = path(point,target.pos,b.enemies)
            else:
                status = "绕后等待机会"
                movement = path(point,target.pos-target.direction*115,b.enemies)
            return movement
        if target.direction.dot(target.pos.direction_to(point)) > -0.32:
            status = "绕到展开的结点"
            movement = path(point,target.pos-target.direction*70,b.enemies)
            return movement
    var reach := 100.0 if slot == 0 else (88.0 if b.current_cat == 1 else 75.0)
    var aim: Vector2 = point.direction_to(target.pos)
    if distance > reach:
        movement = path(point,target.pos,b.enemies)
        status = "靠近接应"
    elif b.facing[slot].dot(aim) < 0.94:
        movement = aim*0.2
        status = "对准目标"
    elif b.attack_cooldown[slot] <= 0 and b.dodge_time[slot] <= 0 and attack_wait <= 0:
        if slot == 1 and b.current_cat == 2:
            if b.attacks.charging:
                if b.attacks.charge_time >= 0.599:
                    b.release_attack(1)
                    attack_wait = 0.4
                    status = "双爪重拍"
            else:
                b.attack(1)
                status = "准备重拍"
        else:
            b.attack(slot)
            attack_wait = 0.55
            status = "挥剑接应" if slot == 0 else "短扑快抓"
    return movement
