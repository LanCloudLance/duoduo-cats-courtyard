extends RefCounted
# Simulation owns two player health pools. The inactive cat is a visual follower.
const Encounter = preload("res://game/battle_encounter.gd")
const Attacks = preload("res://game/battle_attacks.gd")
var attacks = Attacks.new()
const Space = preload("res://game/battle_space.gd")
const FIELD := Space.FIELD
const Garden = preload("res://game/battle_garden.gd")
var garden = Garden.new()
var seeds: Array[Dictionary] = []
var hazards: Array[Dictionary] = []
const EXIT := Vector2(1050, 570)
const RESCUE_SECONDS := 1.2
var positions: Array[Vector2] = [Vector2(350, 440), Vector2(440, 520), Vector2(350, 570)]
var current_cat := 1
var solo_mode := false
var story_first := false
# Empty selects the original three-wave practice encounter.
var story_encounter := "":
    set(value):
        story_encounter = value if value in ["first","shell","reserve"] else ""
        story_first = story_encounter == "first"
        wave_total = 2 if not story_encounter.is_empty() else 3
var wave_total := 3
func available_roles() -> Array: return [0,1] if story_first else [0,1,2]
var hp: Array[int] = [3, 3]
var facing: Array[Vector2] = [Vector2.RIGHT, Vector2.RIGHT]
var velocity: Array[Vector2] = [Vector2.ZERO,Vector2.ZERO]
var attack_cooldown: Array[float] = [0.0, 0.0]
var attack_flash: Array[float] = [0.0, 0.0]
var attack_direction: Array[Vector2] = [Vector2.RIGHT, Vector2.RIGHT]
var dodge_time: Array[float] = [0.0, 0.0]
var dodge_cooldown: Array[float] = [0.0, 0.0]
var dodge_direction: Array[Vector2] = [Vector2.RIGHT, Vector2.RIGHT]
var invulnerable: Array[float] = [0.0, 0.0]
var guarding := false
var guard_held := false
var guard_age := 0.0
var fx: Array[Dictionary] = []
var feedback_id := 0
var last_feedback := ""
var action_dt: Array[float] = [0.0,0.0]
var contact_hold: Array[float] = [0.0,0.0]
var contact_progress: Array[float] = [0.0,0.0]
var hurt_time: Array[float] = [0.0,0.0]
var fallen: Array[Dictionary] = []
var assist_cooldown := 0.0
var assist_role := 1
var assist_time := 0.0
var assist_point := Vector2.ZERO
var enemies: Array[Dictionary] = []
var wave := 0
var phase := "briefing"
var confirmed: Array[bool] = [false, false]
var intermission := 0.0
var retry_time := 0.0
var retries := 0
var rescuer := -1
var rescue_progress := 0.0
var message := "先练 F 横扫、J 猫咪攻击、Tab 切猫；两位按互动键再开战。"
var plant_noticed := false

func _init() -> void:
    garden.setup(self)

func feedback(kind: String, point: Vector2, slot: int, detail: Dictionary = {}) -> void:
    feedback_id += 1
    last_feedback = kind
    var event := {"id":feedback_id,"kind":kind,"pos":point,"slot":slot,"role":actor(slot) if slot >= 0 else -1,"life":0.26}
    event.merge(detail,true)
    fx.append(event)
    if fx.size() > 48: fx.pop_front()

func feedback_since(cursor: int) -> Array[Dictionary]:
    return fx.filter(func(event): return event.id > cursor)

func contact(enemy: Dictionary, slot: int, direction: Vector2, heavy: bool, blocked: bool) -> void:
    contact_hold[slot] = 0.032 if blocked else 0.070 if heavy else 0.042
    contact_progress[slot] = 1.0-attack_flash[slot]/attacks.durations[slot]
    enemy.impact_pause = maxf(enemy.get("impact_pause",0.0),contact_hold[slot])
    enemy.simulation_dt = 0.0
    enemy.impact_age = 0.0
    enemy.impact_direction = direction
    enemy.impact_power = 4.0 if blocked else 26.0 if heavy else 11.0

func actor(slot: int) -> int:
    return 0 if slot == 0 else current_cat

func _bounded(point: Vector2) -> Vector2:
    return point.clamp(FIELD.position, FIELD.end)

func interact(slot: int) -> void:
    if slot < 0 or slot > 1 or hp[slot] <= 0 or phase == "complete":
        return
    if hp[1 - slot] <= 0:
        if positions[actor(slot)].distance_to(positions[actor(1 - slot)]) <= 85:
            attacks.cancel(self,slot)
            if rescuer != slot:
                rescuer = slot
                rescue_progress = 0
            message = "正在扶起伙伴……停留片刻；移动或受击会中断。"
        else:
            message = "靠近坐下的伙伴，再按互动键扶起。"
        return
    if solo_mode and phase in ["briefing","intermission"]:
        if phase == "intermission" and intermission > 0: return
        _start_wave(1 if phase == "briefing" else wave+1)
        return
    if solo_mode and phase == "clear":
        if positions[0].distance_to(EXIT) <= 95 and positions[current_cat].distance_to(EXIT) <= 95:
            phase = "complete"
            cancel_attacks()
            message = "单人战斗试玩完成！可以在暂停菜单重玩，或选择双人关卡。"
        else:
            message = "带上伙伴一起到右边营火，再按互动键。"
        return
    if phase == "briefing":
        confirmed[slot] = true
        message = "一位已准备，等另一位按互动键。"
        if confirmed[0] and confirmed[1]:
            _start_wave(1)
    elif phase == "intermission":
        if intermission > 0:
            message = "先整理一下；稍后两位各按互动键，再开始下一段。"
            return
        confirmed[slot] = true
        message = "一位已准备；另一位也按互动键，再开始下一段。"
        if confirmed[0] and confirmed[1]: _start_wave(wave+1)
    elif phase == "clear" and positions[actor(slot)].distance_to(EXIT) <= 95:
        confirmed[slot] = true
        message = "在营火旁等一等，另一位也按互动键。"
        if confirmed[0] and confirmed[1] and positions[0].distance_to(EXIT) <= 95 and positions[current_cat].distance_to(EXIT) <= 95:
            phase = "complete"
            message = "朵朵：好，正事做完！先和猫猫歇一会儿。"

# The spare cat has no combat slot or targetability. These are presentation
# positions only: switching still puts the incoming cat at the active slot point.
func spare_obstructs_warning(point: Vector2) -> bool:
    var body := Rect2(point-Vector2(43,102),Vector2(86,112))
    for enemy in enemies:
        if enemy.hp <= 0: continue
        var warning := Rect2()
        if enemy.mode in ["windup","rush"]:
            var end: Vector2 = enemy.pos+enemy.direction*(364 if enemy.kind == "roller" else 230)
            warning = Rect2(enemy.pos.min(end),enemy.pos.max(end)-enemy.pos.min(end)).grow(44)
        elif enemy.mode in ["cast","burst","slam_windup","slam"]:
            var center: Vector2 = enemy.get("aim",enemy.pos) if enemy.mode in ["cast","burst"] else enemy.pos
            var radius := 58.0 if enemy.mode in ["cast","burst"] else 112.0
            warning = Rect2(center-Vector2.ONE*radius,Vector2.ONE*radius*2)
        elif enemy.mode in ["melee_windup","melee"]:
            warning = Rect2(enemy.pos-Vector2.ONE*82,Vector2.ONE*164)
        if warning.has_area() and body.intersects(warning): return true
    for hazard in hazards:
        if body.intersects(Rect2(hazard.pos-Vector2.ONE*hazard.radius,Vector2.ONE*hazard.radius*2)): return true
    return false

func spare_goal() -> Vector2:
    var origin: Vector2 = positions[current_cat]
    var forward: Vector2 = facing[1].normalized()
    var side := forward.orthogonal()
    var best := positions[3-current_cat]
    var lowest := INF
    for offset in [Vector2(-100,112),Vector2(-100,-112),Vector2(-145,125),Vector2(-145,-125),Vector2(-90,180),Vector2(-90,-180),Vector2(-200,100),Vector2(-200,-100),Vector2(0,170),Vector2(0,-170)]:
        var point: Vector2 = origin+forward*offset.x+side*offset.y
        if not Space.valid(point,Space.ACTOR_RADIUS) or not Rect2(70,205,1130,570).has_point(point): continue
        var body := Rect2(point-Vector2(43,102),Vector2(86,112))
        var score: float = offset.length()*0.1+point.distance_to(positions[3-current_cat])*0.05
        if spare_obstructs_warning(point): score += 10000
        for role in [0,current_cat]:
            var height := 136.0 if role == 0 else 102.0
            if body.intersects(Rect2(positions[role]-Vector2(43,height),Vector2(86,height+10))): score += 5000
        for enemy in enemies:
            if enemy.hp > 0 and body.intersects(Rect2(enemy.pos-Vector2(53,102),Vector2(106,120))): score += 5000
        for stump in Space.STUMPS:
            if body.intersects(Rect2(stump-Vector2(43,78),Vector2(86,95))): score += 5000
        if score < lowest: lowest=score;best=point
    return best

func switch_cat() -> void:
    if story_first or hp[1] <= 0 or phase == "complete":
        return
    # An earned departure assist cannot be farmed by switching repeatedly.
    if phase == "combat" and assist_cooldown <= 0:
        for enemy in enemies:
            if enemy.hp > 0 and enemy.get("mark_time",0.0) > 0 and not enemy.get("assist_used",false) and positions[current_cat].distance_to(enemy.pos) < 130 and Space.clear_line(positions[current_cat],enemy.pos,0):
                enemy.assist_used = true
                enemy.hp = maxf(0,enemy.hp-1)
                enemy.flash = 0.15
                assist_cooldown = 3.0
                assist_role = current_cat
                assist_time = 0.22
                assist_point = enemy.pos
                feedback("assist",enemy.pos,1)
                break
    attacks.cancel(self,1)
    # Both cats share one combat slot: the incoming cat takes its safe ground point.
    # The departing cat moves to the former follower point; HP/timers never reset.
    var departure: Vector2 = positions[current_cat]
    var incoming: int = 3-current_cat
    positions[current_cat] = positions[incoming]
    positions[incoming] = departure
    current_cat = incoming
    confirmed[1] = false
    if rescuer == 1:
        _cancel_rescue()
    message = "团团接棒，猫咪共用体力。" if current_cat == 1 else "圆圆接棒，猫咪共用体力。"

func attack(slot: int) -> void:
    attacks.press(self,slot)

func release_attack(slot: int) -> void:
    attacks.release(self,slot)

func cancel_attacks() -> void:
    attacks.cancel(self)

func hold_guard(value: bool) -> void:
    guard_held = value
    guarding = value and hp[0] > 0 and dodge_time[0] <= 0 and hurt_time[0] <= 0.14

func dodge(slot: int, direction: Vector2) -> void:
    if slot < 0 or slot > 1 or hp[slot] <= 0 or dodge_cooldown[slot] > 0 or phase == "complete":
        return
    if rescuer == slot:
        _cancel_rescue()
    attacks.cancel(self,slot)
    attack_cooldown[slot] = minf(attack_cooldown[slot],0.08)
    hurt_time[slot] = 0
    dodge_direction[slot] = direction.normalized() if direction.length() > 0.1 else facing[slot]
    dodge_time[slot] = 0.22
    dodge_cooldown[slot] = 0.72
    feedback("dodge",positions[actor(slot)],slot,{"direction":dodge_direction[slot]})
    if slot == 0:
        guarding = false

func hurt(slot: int, source: Vector2, blockable := true) -> bool:
    if hp[slot] <= 0 or invulnerable[slot] > 0 or dodge_time[slot] > 0 or phase != "combat":
        return false
    if blockable and slot == 0 and guarding and facing[0].dot(positions[0].direction_to(source)) >= 0.25:
        feedback("guard",positions[0],0,{"direction":facing[0]})
        message = "挡住了！朵朵正面举盾，猫咪可以绕到侧面抓击。"
        return false
    attacks.cancel(self,slot)
    feedback("hurt",positions[actor(slot)],slot)
    attack_cooldown[slot] = 0
    hurt_time[slot] = 0.22
    if slot == 0: guarding = false
    var away := source.direction_to(positions[actor(slot)])
    positions[actor(slot)] = Space.move(positions[actor(slot)],away*18,Space.ACTOR_RADIUS)
    hp[slot] -= 1
    invulnerable[slot] = 1.2
    if rescuer == slot:
        _cancel_rescue()
    if hp[slot] == 0:
        if slot == 0:
            guarding = false
        message = "伙伴坐下了！靠近后按互动键，停留片刻扶起。"
    return true

func _cancel_rescue() -> void:
    rescuer = -1
    rescue_progress = 0

func _start_wave(number: int) -> void:
    cancel_attacks()
    wave = number
    phase = "combat"
    confirmed[0] = false
    confirmed[1] = false
    enemies.clear()
    fallen.clear()
    garden.setup(self)
    if story_first:
        _spawn("sprout" if number == 1 else "armored",Vector2(960,400),true)
        _spawn("thorn" if number == 1 else "weaver",Vector2(1200,680),true)
    else: Encounter.start(self,number)
    message = Encounter.objective(self,number)

func _spawn(kind: String, point: Vector2, protect_arrival := false) -> void:
    if protect_arrival and (positions.any(func(p): return p.distance_to(point) < 220) or enemies.any(func(e): return e.pos.distance_to(point) < 100) or not Space.valid(point,Space.ENEMY_RADIUS)):
        var candidates: Array[Vector2] = []
        for x in range(6):
            for y in range(4):
                var candidate: Vector2 = FIELD.position+Vector2(90+x*(FIELD.size.x-180)/5,80+y*(FIELD.size.y-160)/3)
                if Space.valid(candidate,Space.ENEMY_RADIUS) and positions.all(func(p): return p.distance_to(candidate) >= 220) and enemies.all(func(e): return e.pos.distance_to(candidate) > 100): candidates.append(candidate)
        candidates.sort_custom(func(a,c): return a.distance_squared_to(point) < c.distance_squared_to(point))
        if not candidates.is_empty(): point = candidates[0]
    var health: float = {"sprout":4.0,"weaver":6.0,"elder":22.0,"roller":5.0,"armored":5.0}.get(kind,5.0)
    enemies.append({"kind": kind, "pos": point, "hp": health,
        "max_hp": health, "mode": "approach", "timer": 0.8,
        "direction": Vector2.LEFT, "hit": {}, "flash": 0.0, "bounce": 0.0, "target": 0, "opening": ""})

func _retry_wave() -> void:
    retries += 1
    positions[0] = Vector2(350, 440)
    positions[1] = Vector2(440, 520)
    positions[2] = Vector2(-4000,-4000) if story_first else Vector2(350, 570)
    for slot in range(2):
        hp[slot] = 3
        invulnerable[slot] = 2.0
        attack_cooldown[slot] = 0
        dodge_cooldown[slot] = 0
        dodge_time[slot] = 0
    guarding = false
    _cancel_rescue()
    retry_time = 0
    _start_wave(wave)
    message = "一起重新站起来。只重试当前一波，之前的桥和进度都保留。"

func step(delta: float, p1: Vector2, p2: Vector2, enabled: bool) -> void:
    if not enabled or not is_finite(delta) or delta <= 0 or not p1.is_finite() or not p2.is_finite():
        return
    var dt := minf(delta, 0.1)
    if guard_held: guarding = hp[0] > 0 and dodge_time[0] <= 0 and hurt_time[0] <= 0.14
    for body in fallen:
        body.death_age += dt
        body.flash = maxf(0,body.flash-dt)
    fallen = fallen.filter(func(body): return body.death_age < 0.38)
    if hp[0] <= 0 and hp[1] <= 0:
        retry_time += dt
        if retry_time >= 2.0:
            _retry_wave()
        return
    guard_age = guard_age+dt if guarding else 0.0
    assist_cooldown = maxf(0,assist_cooldown-dt)
    assist_time = maxf(0,assist_time-dt)
    for effect in fx: effect.life -= dt
    fx = fx.filter(func(effect): return effect.life > 0)
    for slot in range(2):
        # Local simulation clock freezes every timer and displacement for this slot.
        action_dt[slot] = maxf(0,dt-contact_hold[slot])
        contact_hold[slot] = maxf(0,contact_hold[slot]-dt)
        var local_dt: float = action_dt[slot]
        hurt_time[slot] = maxf(0,hurt_time[slot]-local_dt)
        attack_cooldown[slot] = maxf(0, attack_cooldown[slot] - local_dt)
        attack_flash[slot] = maxf(0, attack_flash[slot] - local_dt)
        dodge_cooldown[slot] = maxf(0, dodge_cooldown[slot] - local_dt)
        invulnerable[slot] = maxf(0, invulnerable[slot] - local_dt)
    if guarding: attacks.cancel(self,0)
    var pouncing: bool = attacks.step(self,dt)
    var inputs := [p1.limit_length(), p2.limit_length()]
    for slot in range(2):
        if hp[slot] <= 0 or phase == "complete":
            continue
        var local_dt: float = 0.0 if contact_hold[slot] > 0 or hurt_time[slot] > 0.14 else action_dt[slot]
        var motion: Vector2 = inputs[slot] * (90.0 if slot == 0 and guarding else 215.0)
        if slot == 1 and attacks.charging: motion *= 0.4
        if slot == 1 and pouncing: motion = Vector2.ZERO
        if inputs[slot].length() > 0.1 and not (slot == 1 and pouncing):
            facing[slot] = inputs[slot].normalized()
        if dodge_time[slot] > 0:
            motion = dodge_direction[slot] * 550.0
            dodge_time[slot] = maxf(0, dodge_time[slot] - local_dt)
        var before: Vector2 = positions[actor(slot)]
        positions[actor(slot)] = _move_actor(before,motion*local_dt,dodge_time[slot] > 0)
        velocity[slot] = (positions[actor(slot)]-before)/dt
        if phase == "clear" and positions[actor(slot)].distance_to(EXIT) > 95:
            confirmed[slot] = false
    # The spare cat follows the active cat and is never an enemy target.
    var follower := 3 - current_cat
    var goal := spare_goal() if story_encounter in ["shell","reserve"] else _bounded(positions[current_cat]-facing[1]*65+facing[1].orthogonal()*55)
    if not story_first: positions[follower] = Space.move(positions[follower], Space.direction(positions[follower],goal,Space.ACTOR_RADIUS)*minf(260*dt,positions[follower].distance_to(goal)), Space.ACTOR_RADIUS)
    if not plant_noticed:
        for seed in seeds:
            if positions.any(func(p): return p.distance_to(seed.pos) < 145):
                plant_noticed = true
                message = "朵朵：这团卷叶摇摇晃晃的，敲一下会怎样？"
                break
    if rescuer >= 0:
        if inputs[rescuer].length() > 0.1 or hp[rescuer] <= 0 or positions[actor(rescuer)].distance_to(positions[actor(1 - rescuer)]) > 85:
            _cancel_rescue()
        else:
            rescue_progress += dt
            if rescue_progress >= RESCUE_SECONDS:
                hp[1 - rescuer] = 2
                invulnerable[1 - rescuer] = 2.0
                _cancel_rescue()
                message = "扶起来了！继续一起走。"
    if phase != "complete": garden.step(self,dt)
    if phase == "intermission":
        intermission -= dt
        intermission = maxf(0,intermission)
        # Time is the minimum breathing room, never the next-wave trigger.
    elif phase == "combat":
        for enemy in enemies:
            if enemy.hp > 0:
                _enemy_step(enemy, dt)
            else:
                var body: Dictionary = enemy.duplicate(true)
                body.death_age = 0.0
                fallen.append(body)
                feedback("defeat",enemy.pos,-1,{"direction":enemy.get("impact_direction",-enemy.direction)})
        enemies = enemies.filter(func(e): return e.hp > 0)
        if enemies.is_empty() and (hp[0] > 0 or hp[1] > 0):
            phase = "intermission" if wave < wave_total else "clear"
            intermission = 1.25
            confirmed = [false,false]
            message = "喘口气；准备好后按互动键开始下一段，伙伴坐下时先扶起来。" if wave < wave_total else "空地安全了！扶起伙伴，再到右边营火集合。"

func _move_actor(origin: Vector2, offset: Vector2, dodging: bool) -> Vector2:
    var end := Space.move(origin,offset,Space.ACTOR_RADIUS)
    if dodging: return end
    # Same contact radius as pounce; tangential input slides, retreat always works.
    for enemy in enemies:
        if enemy.hp <= 0: continue
        var radial: Vector2 = enemy.pos.direction_to(origin)
        var distance: float = origin.distance_to(enemy.pos)
        if distance < 44.01:
            if end.distance_to(enemy.pos) >= distance: continue
            var slide: Vector2 = offset-radial*minf(0,offset.dot(radial))
            end = Space.move(origin,slide,Space.ACTOR_RADIUS)
        else:
            var t := Space.contact(origin,end,enemy.pos,44)
            if t != INF: end = origin.lerp(end,maxf(0,t-0.001))
    return end

func _busy(except_enemy: Dictionary) -> bool:
    var count := 0
    for other in enemies:
        if is_same(other,except_enemy) or other.hp <= 0: continue
        if solo_mode and other.mode == "exposed": return true
        if other.mode in ["windup","rush","cast","burst","slam_windup","slam","melee_windup","melee"]:
            count += 1
            # Never stack melee and a major attack on the same player.
            if other.target == except_enemy.target: return true
    return count >= (1 if solo_mode else 2)
func _expose(enemy: Dictionary, cause: String) -> void:
    enemy.mode = "exposed" if enemy.kind in ["armored","elder"] else "rest"
    enemy.timer = (2.4 if cause == "shield" else 2.0) if enemy.kind == "armored" else 1.25
    if solo_mode and enemy.kind == "armored": enemy.timer += 0.8
    if enemy.kind == "elder": enemy.timer = 2.0 if cause == "stump" or guard_age <= 0.18 else 1.15
    if cause == "shield": feedback("parry" if guard_age <= 0.18 else "guard",enemy.pos,0)
    enemy.opening = cause
    enemy.heavy_extended = false
    if hp[0] > 0 and hp[1] > 0:
        if enemy.kind == "armored":
            message = "挡住了！背后有机会，绕后拆结点！" if cause == "shield" else "撞到树桩了！背后的结点展开了。"
        else:
            message = "撞停了！趁它休息时进攻。"
func _rush(enemy: Dictionary, dt: float) -> void:
    var before: Vector2 = enemy.pos
    var speed := 560.0 if enemy.kind == "roller" else 480.0
    var end := _bounded(before+enemy.direction*speed*dt)
    var hits: Array[Dictionary] = []
    for stump in Space.STUMPS:
        var t := Space.contact(before,end,stump,Space.STUMP_RADIUS+Space.ENEMY_RADIUS)
        if t != INF: hits.append({"t":t,"kind":"stump","slot":-1})
    for slot in range(2):
        if hp[slot] <= 0 or enemy.hit.has(slot): continue
        var shield: bool = slot == 0 and guarding and dodge_time[0] <= 0 and facing[0].dot(-enemy.direction) >= 0.25 and facing[0].dot(positions[0].direction_to(before)) >= 0.25
        var t := Space.contact(before,end,positions[actor(slot)],64.0 if shield else 44.0)
        if t != INF: hits.append({"t":t,"kind":"shield" if shield else "body","slot":slot})
    for other in enemies:
        if is_same(other,enemy) or other.hp <= 0 or other.kind == "armored": continue
        var t := Space.contact(before,end,other.pos,Space.ENEMY_RADIUS*2)
        if t != INF: hits.append({"t":t,"kind":"enemy","slot":-1,"enemy":other})
    hits.sort_custom(func(a,b): return a.t < b.t)
    for hit in hits:
        if hit.kind == "enemy":
            var other: Dictionary = hit.enemy
            other.hp = maxf(0,other.hp-1)
            other.flash = 0.13
            if other.mode != "rush":
                other.mode = "rest"
                other.timer = 0.7
            enemy.pos = before.lerp(end,maxf(0,hit.t-0.001))
            _expose(enemy,"collision")
            feedback("interrupt",other.pos,-1)
            message = "撞到一起了！后排被打断，趁现在追击。"
            return
        if hit.kind == "stump" or hit.kind == "shield":
            enemy.pos = before.lerp(end,maxf(0,hit.t-0.001))
            if hit.slot >= 0: enemy.hit[hit.slot] = true
            _expose(enemy,"shield" if hit.kind == "shield" else "stump")
            return
        hurt(hit.slot,positions[actor(hit.slot)]-enemy.direction*50)
        enemy.hit[hit.slot] = true
    enemy.pos = end
    if enemy.timer <= 0 or enemy.pos == before:
        enemy.mode = "rest"
        enemy.timer = 1.4 if enemy.kind == "armored" else (1.25 if enemy.kind == "thorn" else 1.65)
func _enemy_step(enemy: Dictionary, dt: float) -> void:
    dt = enemy.get("simulation_dt",dt)
    if dt <= 0: return
    if enemy.get("pose_mode","") != enemy.mode:
        enemy.pose_mode = enemy.mode
        enemy.pose_duration = maxf(enemy.timer,0.001)
        enemy.pose_elapsed = 0.0
    var held: bool = enemy.get("impact_pause",0.0) > 0 or enemy.get("control_time",0.0) > 0
    _enemy_ai(enemy,dt)
    if enemy.pose_mode != enemy.mode:
        enemy.pose_mode = enemy.mode
        enemy.pose_duration = maxf(enemy.timer,0.001)
        enemy.pose_elapsed = 0.0
    elif not held:
        enemy.pose_elapsed += dt

func _enemy_ai(enemy: Dictionary, dt: float) -> void:
    enemy.flash = maxf(0,enemy.flash-dt)
    enemy.bounce = maxf(0,enemy.bounce-dt)
    if enemy.get("control_time",0.0) > 0: return
    enemy.timer -= dt
    if Encounter.step(self,enemy,dt): return
    if enemy.mode == "approach":
        var target: int = enemy.target if hp[enemy.target] > 0 else 1-enemy.target
        if hp[1-target] > 0 and positions[actor(1-target)].distance_to(enemy.pos)+0.1 < positions[actor(target)].distance_to(enemy.pos): target = 1-target
        enemy.target = target
        var offset: Vector2 = positions[actor(target)]-enemy.pos
        if offset.length() > 250:
            enemy.pos = Space.move(enemy.pos,Space.direction(enemy.pos,positions[actor(target)],Space.ENEMY_RADIUS)*85*dt,Space.ENEMY_RADIUS)
        elif enemy.timer <= 0 and not _busy(enemy):
            enemy.direction = offset.normalized() if offset.length() > 0.1 else Vector2.LEFT
            enemy.mode = "windup"
            enemy.timer = (0.9 if enemy.kind == "thorn" else 1.2)+(0.2 if solo_mode else 0.0)
    elif enemy.mode == "windup" and enemy.timer <= 0:
        enemy.mode = "rush"
        enemy.timer = 0.65 if enemy.kind == "roller" else 0.48
        enemy.hit.clear()
        enemy.opening = ""
    elif enemy.mode == "rush":
        _rush(enemy,dt)
    elif enemy.mode in ["rest","exposed"] and enemy.timer <= 0:
        enemy.mode = "approach"
        enemy.timer = 0.2
        enemy.opening = ""
