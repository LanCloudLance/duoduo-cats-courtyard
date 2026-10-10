extends RefCounted


func setup(b) -> void:
    b.hazards.clear()
    b.seeds.clear()
    for point in b.Encounter.seed_points(b.story_encounter):
        b.seeds.append({"pos":point,"mode":"rooted","velocity":Vector2.ZERO,"age":0.0})

func strike(b, origin: Vector2, direction: Vector2, reach: float, half_angle: float, heavy: bool) -> bool:
    var hit := false
    for seed in b.seeds:
        if seed.mode not in ["rooted","loose"]: continue
        var offset: Vector2 = seed.pos-origin
        if offset.length() > reach or (offset.length() > 0.01 and direction.dot(offset.normalized()) < cos(half_angle)) or not b.Space.clear_line(origin,seed.pos,0): continue
        hit = true
        if heavy or seed.mode == "loose":
            seed.mode = "rolling"
            seed.velocity = direction.normalized()*430
            seed.age = 0.0
            b.feedback("heavy",seed.pos,-1,{"direction":direction,"plant":true})
        else:
            seed.mode = "loose"
            b.message = "卷叶松开，开始晃动。"
            b.feedback("hit",seed.pos,-1,{"direction":direction,"plant":true})
    return hit

func cast(b, point: Vector2) -> void:
    if b.hazards.size() >= 3: b.hazards.pop_front()
    b.hazards.append({"pos":point,"age":0.0,"radius":72.0})

func burst(b, seed: Dictionary) -> void:
    seed.mode = "spent"
    seed.age = 0.0
    for enemy in b.enemies:
        if enemy.hp <= 0 or enemy.pos.distance_to(seed.pos) > 125 or not b.Space.clear_line(seed.pos,enemy.pos,0): continue
        enemy.hp = maxf(0,enemy.hp-3.0)
        enemy.flash = 0.2
        if enemy.hp > 0 and enemy.get("control_immune",0.0) <= 0:
            enemy.mode = "rest"
            enemy.timer = 0.9
            enemy.control_immune = 2.2
            enemy.weave_break = 2.2
        b.feedback("heavy",enemy.pos,-1,{"direction":seed.velocity.normalized(),"plant":true})
    b.feedback("plant_burst",seed.pos,-1,{"life":0.55})

func step(b, dt: float) -> void:
    for seed in b.seeds:
        if seed.mode not in ["rolling","spent"]: continue
        seed.age += dt
        if seed.mode == "spent": continue
        var next: Vector2 = seed.pos+seed.velocity*dt
        var fraction := 1.0
        var collided := false
        for stump in b.Space.STUMPS:
            var t: float = b.Space.contact(seed.pos,next,stump,b.Space.STUMP_RADIUS+18)
            if t != INF: fraction = minf(fraction,t); collided = true
        for enemy in b.enemies:
            if enemy.hp <= 0: continue
            var t: float = b.Space.contact(seed.pos,next,enemy.pos,b.Space.ENEMY_RADIUS+18)
            if t != INF: fraction = minf(fraction,t); collided = true
        seed.pos = seed.pos.lerp(next,fraction).clamp(b.Space.FIELD.position,b.Space.FIELD.end)
        if collided or seed.age >= 2.0 or not b.Space.FIELD.has_point(next): burst(b,seed)
    for hazard in b.hazards:
        hazard.age += dt
        if hazard.age < 0.65 or b.phase != "combat": continue
        for slot in b.deployed_slots():
            if b.positions[b.actor(slot)].distance_to(hazard.pos) < hazard.radius:
                b.hurt(slot,hazard.pos,false)
    b.hazards = b.hazards.filter(func(h): return h.age < 3.1)

func danger(b, point: Vector2, margin: float = 0.0) -> Vector2:
    for hazard in b.hazards:
        if point.distance_to(hazard.pos) < hazard.radius+margin: return hazard.pos
    return Vector2(INF,INF)
