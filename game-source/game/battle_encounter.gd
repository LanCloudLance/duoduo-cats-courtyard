extends RefCounted
static func seed_points(id: String) -> Array[Vector2]:
    if id=="shell":return [Vector2(715,665),Vector2(1060,335)]
    if id=="reserve":return [Vector2(795,585),Vector2(1080,425)]
    return [Vector2(740,655)]
static func start(b,number: int) -> void:
    match b.story_encounter:
        "first":
            b._spawn("sprout" if number==1 else "weaver",Vector2(760,400) if number==1 else Vector2(1000,370))
            b._spawn("thorn",Vector2(955,610) if number==1 else Vector2(795,625))
        "shell":
            b._spawn("thorn" if number==1 else "sprout",Vector2(785,410) if number==1 else Vector2(1000,650))
            b._spawn("weaver",Vector2(1065,625) if number==1 else Vector2(710,285))
        "reserve":
            b._spawn("armored",Vector2(950,520) if number==1 else Vector2(950,625))
            b._spawn("sprout" if number==1 else "weaver",Vector2(760,650) if number==1 else Vector2(1080,350))
            if number==2:b._spawn("sprout",Vector2(720,285))
        _:
            b._spawn("thorn" if number==1 else "armored",Vector2(875,410))
            b._spawn("weaver",Vector2(1040,625))
static func objective(b,number: int) -> String:
    match b.story_encounter:
        "first":return "把通往驿站的小路清出来。"
        "shell":return "让维修外罩的小路重新通畅。"
        "reserve":return "清开树梯旁的荆棘，归途灯匣留在安全处。"
    return "练练不同战法，准备好再继续。"

static func danger(enemy: Dictionary, point: Vector2, margin := 0.0) -> bool:
    if enemy.hp <= 0: return false
    if enemy.mode in ["cast","burst"]:
        return point.distance_to(enemy.get("aim",enemy.pos)) <= 58+margin
    if enemy.mode in ["slam_windup","slam"]:
        return point.distance_to(enemy.pos) <= 112+margin
    if enemy.mode in ["melee_windup","melee"]:
        var offset: Vector2 = point-enemy.pos
        return offset.length() <= 82+margin and (offset.length() < 1 or enemy.direction.dot(offset.normalized()) >= 0.25)
    if enemy.mode in ["windup","rush"]:
        var end: Vector2 = enemy.pos+enemy.direction*(364 if enemy.kind == "roller" else 230)
        return point.distance_to(Geometry2D.get_closest_point_to_segment(point,enemy.pos,end)) < 44+margin
    return false

static func step(b, enemy: Dictionary, dt: float) -> bool:
    if enemy.kind not in ["sprout","weaver","elder"]: return false
    var target: int = b.nearest_slot(enemy.pos)
    if target<0:return true
    if enemy.mode == "approach":
        enemy.target = target
        var goal: Vector2 = b.positions[b.actor(target)]
        var offset: Vector2 = goal-enemy.pos
        if enemy.kind == "elder":
            if enemy.hp <= enemy.max_hp*0.5 and offset.length() < 155 and enemy.timer <= 0 and not b._busy(enemy):
                enemy.mode = "slam_windup"
                enemy.timer = 0.82+(0.18 if b.solo_mode else 0.0)
                enemy.hit.clear()
                return true
            return false
        var reach := 78.0 if enemy.kind == "sprout" else 1500.0
        if offset.length() > reach or not b.Space.clear_line(enemy.pos,goal,0):
            enemy.pos = b.Space.move(enemy.pos,b.Space.direction(enemy.pos,goal,b.Space.ENEMY_RADIUS)*(125 if enemy.kind == "sprout" else 85)*dt,b.Space.ENEMY_RADIUS)
        elif enemy.timer <= 0 and not b._busy(enemy):
            enemy.direction = offset.normalized() if offset.length() > 1 else Vector2.LEFT
            enemy.mode = "melee_windup" if enemy.kind == "sprout" else "cast"
            enemy.timer = (0.5 if enemy.kind == "sprout" else 0.85)+(0.15 if b.solo_mode else 0.0)
            enemy.aim = goal if enemy.kind == "sprout" else (goal+b.velocity[target].limit_length(215)*enemy.timer).clamp(b.FIELD.position+Vector2(40,40),b.FIELD.end-Vector2(40,40))
            enemy.hit.clear()
        elif enemy.kind == "weaver" and offset.length() < 150:
            enemy.pos = b.Space.move(enemy.pos,-offset.normalized()*55*dt,b.Space.ENEMY_RADIUS)
        return true
    if enemy.mode in ["cast","melee_windup","slam_windup"]:
        if enemy.timer <= 0:
            if enemy.mode == "cast": b.garden.cast(b,enemy.aim)
            enemy.mode = {"cast":"burst","melee_windup":"melee","slam_windup":"slam"}[enemy.mode]
            enemy.timer = 0.22
            b.feedback("danger",enemy.get("aim",enemy.pos) if enemy.mode == "burst" else enemy.pos,-1)
        return true
    if enemy.mode in ["burst","melee","slam"]:
        for slot in b.deployed_slots():
            if not enemy.hit.has(slot) and danger(enemy,b.positions[b.actor(slot)]) and b.Space.clear_line(enemy.pos,b.positions[b.actor(slot)],0):
                b.hurt(slot,enemy.pos,enemy.mode == "melee")
                enemy.hit[slot] = true
        if enemy.timer <= 0:
            enemy.mode = "rest"
            enemy.timer = 0.65 if enemy.kind == "sprout" else (1.15 if enemy.kind == "elder" else 0.85)
        return true
    return false
