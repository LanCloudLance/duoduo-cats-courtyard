extends RefCounted
const Space = preload("res://game/battle_space.gd")

static func start(b, number: int) -> void:
    if b.story_encounter == "shell":
        # Open flanks separate pursuit from a remote caster; lower than practice HP budget.
        b._spawn("thorn" if number == 1 else "sprout",Vector2(870,360) if number == 1 else Vector2(1050,610),true)
        b._spawn("weaver",Vector2(960,650) if number == 1 else Vector2(670,250),true)
        b.seeds[0].pos = Vector2(920,710)
        b.seeds[1].pos = Vector2(1160,330)
        return
    if b.story_encounter == "reserve":
        # Same three-body limit as practice; clustering makes shield/interrupt/area control useful.
        b._spawn("armored" if number == 1 else "thorn",Vector2(1000,460) if number == 1 else Vector2(1020,500),true)
        b._spawn("weaver",Vector2(1100,520) if number == 1 else Vector2(950,290),true)
        if number == 2: b._spawn("sprout",Vector2(860,640),true)
        b.seeds[0].pos = Vector2(930,500)
        b.seeds[1].pos = Vector2(1110,700)
        return
    if number == 1:
        b._spawn("thorn",Vector2(920,390),true)
        b._spawn("sprout",Vector2(1040,730),true)
        b._spawn("weaver",Vector2(1200,220),true)
    elif number == 2:
        b._spawn("armored",Vector2(930,420),true)
        b._spawn("weaver",Vector2(1250,700),true)
        b._spawn("sprout",Vector2(1060,220),true)
    else:
        b._spawn("elder",Vector2(950,430),true)
        b._spawn("weaver",Vector2(1260,730),true)
        b._spawn("roller",Vector2(1200,220),true)
        if not b.solo_mode: b._spawn("sprout",Vector2(1000,740),true)

static func objective(b, number: int) -> String:
    if b.story_encounter == "shell":
        return "破罩外圈 · 上侧挡追击，或绕下方树桩打断织藤花；中间留路接应。" if number == 1 else "破罩外圈 · 织藤花换到上桩旁，嫩芽从右下靠近；重新选先处理哪边。"
    if b.story_encounter == "reserve":
        return "护住归途 · 硬壳与织藤花挤在树桩另一侧，卷叶就在它们前方。" if number == 1 else "护住归途 · 织藤花退到上侧，两只枝团从中下靠近；挡住或绕侧，留意接应。"
    if b.story_first:
        return "前方枝团拦住小路；留意冲锋，试着从侧面接应。" if number == 1 else "织藤花守着硬壳的背后，留意落点与展开的结点。"
    return ["近身小怪会追上来：边移动边连击，留意荆棘冲锋。", "藤蔓会预判去路：看到预警换方向，或打断后排；硬壳要分工拆。", "树怪守着灯芯：挡冲锋、绕侧追击；半血后注意震地。"][clampi(number-1,0,2)]

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
    var target: int = enemy.target if b.hp[enemy.target] > 0 else 1-enemy.target
    if b.hp[1-target] > 0 and enemy.pos.distance_to(b.positions[b.actor(1-target)])+30 < enemy.pos.distance_to(b.positions[b.actor(target)]): target = 1-target
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
        if offset.length() > reach or not Space.clear_line(enemy.pos,goal,0):
            enemy.pos = Space.move(enemy.pos,Space.direction(enemy.pos,goal,Space.ENEMY_RADIUS)*(125 if enemy.kind == "sprout" else 85)*dt,Space.ENEMY_RADIUS)
        elif enemy.timer <= 0 and not b._busy(enemy):
            enemy.direction = offset.normalized() if offset.length() > 1 else Vector2.LEFT
            enemy.mode = "melee_windup" if enemy.kind == "sprout" else "cast"
            enemy.timer = (0.5 if enemy.kind == "sprout" else 0.85)+(0.15 if b.solo_mode else 0.0)
            enemy.aim = goal if enemy.kind == "sprout" else (goal+b.velocity[target].limit_length(215)*enemy.timer).clamp(b.FIELD.position+Vector2(40,40),b.FIELD.end-Vector2(40,40))
            enemy.hit.clear()
        elif enemy.kind == "weaver" and offset.length() < 150:
            enemy.pos = Space.move(enemy.pos,-offset.normalized()*55*dt,Space.ENEMY_RADIUS)
        return true
    if enemy.mode in ["cast","melee_windup","slam_windup"]:
        if enemy.timer <= 0:
            if enemy.mode == "cast": b.garden.cast(b,enemy.aim)
            enemy.mode = {"cast":"burst","melee_windup":"melee","slam_windup":"slam"}[enemy.mode]
            enemy.timer = 0.22
            b.feedback("danger",enemy.get("aim",enemy.pos) if enemy.mode == "burst" else enemy.pos,-1)
        return true
    if enemy.mode in ["burst","melee","slam"]:
        for slot in range(2):
            if not enemy.hit.has(slot) and danger(enemy,b.positions[b.actor(slot)]) and Space.clear_line(enemy.pos,b.positions[b.actor(slot)],0):
                b.hurt(slot,enemy.pos,enemy.mode == "melee")
                enemy.hit[slot] = true
        if enemy.timer <= 0:
            enemy.mode = "rest"
            enemy.timer = 0.65 if enemy.kind == "sprout" else (1.15 if enemy.kind == "elder" else 0.85)
        return true
    return false
