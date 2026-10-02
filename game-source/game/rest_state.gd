extends RefCounted
const FIELD := Rect2(100, 240, 1080, 410)
const BENCH := Vector2(650, 460)
const EXIT := Vector2(1100, 460)
var positions: Array[Vector2] = [Vector2(280, 430), Vector2(360, 470), Vector2(290, 540)]
var solo_mode := false
var current_cat := 1
var hp: Array[int] = [3, 3]
var progress: Dictionary = {"bridge":false,"combat":false,"light":false}
var ready: Array[bool] = [false, false]
var confirmed: Array[bool] = [false, false]
var sitting: Array[bool] = [false, false]
var pets: Array[int] = [0, 0]
var greetings: Array[int] = [0, 0]
var pet_cooldown := 0.0
var greet_cooldown := 0.0
var reaction_cat := 1
var rested := false
var finished := false
var message := "朵朵：该认真的时候认真。现在嘛……先找张椅子！"
func actor(slot: int) -> int:
    return 0 if slot == 0 else current_cat
func full_run() -> bool:
    return progress.get("bridge", false) and progress.get("combat", false) and progress.get("light", false) and (not progress.has("gate") or progress.gate)
func switch_cat() -> void:
    if finished: return
    current_cat = 3 - current_cat
    confirmed[1] = false
    ready[1] = false
    sitting[1] = false
    message = "团团凑过来，抬头等你伸手。" if current_cat == 1 else "圆圆慢悠悠地抬起头：轮到我了吗？"
func interact(slot: int) -> void:
    if slot < 0 or slot > 1 or finished: return
    var point: Vector2 = positions[actor(slot)]
    if point.distance_to(EXIT) <= 85:
        if not rested:
            message = "先到长椅边，带两只猫一起歇歇脚。"
        else:
            confirmed[slot] = true
            message = "等另一位也确认，三位一起离开。"
            _check_exit()
        return
    if not rested and point.distance_to(BENCH) <= 100:
        ready[slot] = true
        message = "一个位置准备好了，等另一位和猫猫一起坐下。"
        _check_rest()
        return
    if slot == 0 and pet_cooldown <= 0:
        var nearest := current_cat
        if point.distance_to(positions[current_cat]) > 85:
            nearest = 3-current_cat
        if point.distance_to(positions[nearest]) <= 85:
            pets[nearest-1] += 1
            reaction_cat = nearest
            pet_cooldown = 1.1
            if nearest == 1:
                message = ["团团舔了舔朵朵的手心，又往前蹭了一小步。", "团团抱住她的手腕，轻轻搭了一下爪子。朵朵：好好好，再摸一下。", "团团把脑袋塞进掌心：还没摸够呢。"][ (pets[0]-1) % 3 ]
            else:
                message = ["圆圆慢半拍地翻出肚皮，任由朵朵揉了揉。", "圆圆眯着眼睛，一动不动。朵朵：你已经进入省电模式了？"][ (pets[1]-1) % 2 ]
    elif slot == 1 and greet_cooldown <= 0 and point.distance_to(positions[0]) <= 85:
        greetings[current_cat-1] += 1
        reaction_cat = current_cat
        greet_cooldown = 1.1
        message = "团团主动蹭蹭朵朵，伸爪和她碰了一下。" if current_cat == 1 else "圆圆靠在朵朵旁边，安安稳稳地坐下来。"
        sitting[1] = true
func _check_rest() -> void:
    if rested: return
    if not (ready[0] or ready[1]) if solo_mode else not (ready[0] and ready[1]): return
    for point in positions:
        if point.distance_to(BENCH) > 145: return
    rested = true
    hp[0] = 3
    hp[1] = 3
    sitting[0] = true
    sitting[1] = true
    message = "朵朵：今天该做的事做完了。接下来，请允许我在椅子上长五分钟。"
func _check_exit() -> void:
    if not rested: return
    if not (confirmed[0] or confirmed[1]) if solo_mode else not (confirmed[0] and confirmed[1]): return
    for point in positions:
        if point.distance_to(EXIT) > 120: return
    finished = true
    message = "三位一起把这段路点亮了。谢谢你们陪朵朵和猫猫走到这里。" if full_run() else "休息点体验结束。还可以回准备室，试试其他合作关卡。"
func step(delta: float, p1: Vector2, p2: Vector2, enabled: bool) -> void:
    if not enabled or finished or not is_finite(delta) or delta <= 0 or not p1.is_finite() or not p2.is_finite(): return
    var dt := minf(delta, 0.1)
    pet_cooldown = maxf(0, pet_cooldown-dt)
    greet_cooldown = maxf(0, greet_cooldown-dt)
    var inputs := [p1, p2]
    for slot in range(2):
        if inputs[slot].length() > 0.01:
            sitting[slot] = false
        positions[actor(slot)] = (positions[actor(slot)] + inputs[slot].limit_length() * 210 * dt).clamp(FIELD.position, FIELD.end)
        if positions[actor(slot)].distance_to(BENCH) > 100:
            ready[slot] = false
        if positions[actor(slot)].distance_to(EXIT) > 85:
            confirmed[slot] = false
    var follower := 3-current_cat
    var goal: Vector2 = (positions[current_cat] + Vector2(-55, 50)).clamp(FIELD.position, FIELD.end)
    positions[follower] = positions[follower].move_toward(goal, 245*dt)
    _check_rest()
    _check_exit()
func record() -> Dictionary:
    if not rested: return {}
    return {"version":1, "safe_point":"rest", "rested":true, "current_cat":current_cat, "completed":progress.duplicate()}
func restore(data: Dictionary) -> void:
    progress = data.completed.duplicate()
    current_cat = int(data.current_cat)
    rested = true
    positions[0] = Vector2(610, 460)
    positions[1] = Vector2(690, 460)
    positions[2] = Vector2(600, 520)
    hp[0] = 3
    hp[1] = 3
    sitting[0] = true
    sitting[1] = true
    message = "回到长椅边了。朵朵和猫猫都在，一起继续吧。"
