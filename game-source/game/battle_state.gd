extends RefCounted
# Simulation owns two player health pools. The inactive cat is a visual follower.
const Encounter = preload("res://game/battle_encounter.gd")
const Attacks = preload("res://game/battle_attacks.gd")
var attacks = Attacks.new()
const Space = preload("res://game/battle_space.gd")
const FIELD := Rect2(120, 240, 1040, 410)
const EXIT := Vector2(1050, 570)
const RESCUE_SECONDS := 1.2
var positions: Array[Vector2] = [Vector2(350, 440), Vector2(440, 520), Vector2(350, 570)]
var current_cat := 1
var solo_mode := false
var hp: Array[int] = [3, 3]
var facing: Array[Vector2] = [Vector2.RIGHT, Vector2.RIGHT]
var attack_cooldown: Array[float] = [0.0, 0.0]
var attack_flash: Array[float] = [0.0, 0.0]
var attack_direction: Array[Vector2] = [Vector2.RIGHT, Vector2.RIGHT]
var dodge_time: Array[float] = [0.0, 0.0]
var dodge_cooldown: Array[float] = [0.0, 0.0]
var dodge_direction: Array[Vector2] = [Vector2.RIGHT, Vector2.RIGHT]
var invulnerable: Array[float] = [0.0, 0.0]
var guarding := false
var guard_age := 0.0
var fx: Array[Dictionary] = []
var feedback_id := 0
var last_feedback := ""
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

func feedback(kind: String, point: Vector2, slot: int) -> void:
    feedback_id += 1
    last_feedback = kind
    fx.append({"kind":kind,"pos":point,"slot":slot,"life":0.26})
    if fx.size() > 24: fx.pop_front()

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
        if confirmed[0] and confirmed[1]: _start_wave(wave+1)
    elif phase == "clear" and positions[actor(slot)].distance_to(EXIT) <= 95:
        confirmed[slot] = true
        message = "在营火旁等一等，另一位也按互动键。"
        if confirmed[0] and confirmed[1] and positions[0].distance_to(EXIT) <= 95 and positions[current_cat].distance_to(EXIT) <= 95:
            phase = "complete"
            message = "朵朵：好，正事做完！先和猫猫歇一会儿。"

func switch_cat() -> void:
    if hp[1] <= 0 or phase == "complete":
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
    current_cat = 3 - current_cat
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

func dodge(slot: int, direction: Vector2) -> void:
    if slot < 0 or slot > 1 or hp[slot] <= 0 or dodge_cooldown[slot] > 0 or phase == "complete":
        return
    if rescuer == slot:
        _cancel_rescue()
    attacks.cancel(self,slot)
    dodge_direction[slot] = direction.normalized() if direction.length() > 0.1 else facing[slot]
    dodge_time[slot] = 0.22
    dodge_cooldown[slot] = 0.72
    if slot == 0:
        guarding = false

func hurt(slot: int, source: Vector2, blockable := true) -> bool:
    if hp[slot] <= 0 or invulnerable[slot] > 0 or dodge_time[slot] > 0 or phase != "combat":
        return false
    if blockable and slot == 0 and guarding and facing[0].dot(positions[0].direction_to(source)) >= 0.25:
        message = "挡住了！朵朵正面举盾，猫咪可以绕到侧面抓击。"
        return false
    attacks.cancel(self,slot)
    feedback("hurt",positions[actor(slot)],slot)
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
    Encounter.start(self,number)
    message = ["近身小怪会追上来：边移动边连击，留意荆棘冲锋。", "藤蔓会锁定脚下：先打断后排，或分工拆掉硬壳。", "树怪守着灯芯：挡冲锋、绕侧追击；半血后注意震地。"][number-1]

func _spawn(kind: String, point: Vector2) -> void:
    var health: float = {"sprout":4.0,"weaver":6.0,"elder":22.0,"roller":5.0,"armored":5.0}.get(kind,5.0)
    enemies.append({"kind": kind, "pos": point, "hp": health,
        "max_hp": health, "mode": "approach", "timer": 0.8,
        "direction": Vector2.LEFT, "hit": {}, "flash": 0.0, "bounce": 0.0, "target": 0, "opening": ""})

func _retry_wave() -> void:
    retries += 1
    positions[0] = Vector2(350, 440)
    positions[1] = Vector2(440, 520)
    positions[2] = Vector2(350, 570)
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
        attack_cooldown[slot] = maxf(0, attack_cooldown[slot] - dt)
        attack_flash[slot] = maxf(0, attack_flash[slot] - dt)
        dodge_cooldown[slot] = maxf(0, dodge_cooldown[slot] - dt)
        invulnerable[slot] = maxf(0, invulnerable[slot] - dt)
    if guarding: attacks.cancel(self,0)
    var pouncing: bool = attacks.step(self,dt)
    var inputs := [p1.limit_length(), p2.limit_length()]
    for slot in range(2):
        if hp[slot] <= 0 or phase == "complete":
            continue
        var velocity: Vector2 = inputs[slot] * (90.0 if slot == 0 and guarding else 215.0)
        if slot == 1 and attacks.charging: velocity *= 0.4
        if slot == 1 and pouncing: velocity = Vector2.ZERO
        if inputs[slot].length() > 0.1 and not (slot == 1 and pouncing):
            facing[slot] = inputs[slot].normalized()
        if dodge_time[slot] > 0:
            velocity = dodge_direction[slot] * 550.0
            dodge_time[slot] = maxf(0, dodge_time[slot] - dt)
        positions[actor(slot)] = Space.move(positions[actor(slot)], velocity*dt, Space.ACTOR_RADIUS)
        if phase == "clear" and positions[actor(slot)].distance_to(EXIT) > 95:
            confirmed[slot] = false
    # The spare cat follows the active cat and is never an enemy target.
    var follower := 3 - current_cat
    var goal := _bounded(positions[current_cat] + Vector2(-65, 55))
    positions[follower] = Space.move(positions[follower], Space.direction(positions[follower],goal,Space.ACTOR_RADIUS)*minf(260*dt,positions[follower].distance_to(goal)), Space.ACTOR_RADIUS)
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
    if phase == "intermission":
        intermission -= dt
        intermission = maxf(0,intermission)
        if intermission <= 0 and hp[0] > 0 and hp[1] > 0: _start_wave(wave+1)
    elif phase == "combat":
        for enemy in enemies:
            if enemy.hp > 0:
                _enemy_step(enemy, dt)
        enemies = enemies.filter(func(e): return e.hp > 0)
        if enemies.is_empty() and (hp[0] > 0 or hp[1] > 0):
            phase = "intermission" if wave < 3 else "clear"
            intermission = 1.25
            confirmed = [false,false]
            message = "喘口气，下一段马上开始；伙伴坐下时先扶起来。" if wave < 3 else "空地安全了！扶起伙伴，再到右边营火集合。"

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
