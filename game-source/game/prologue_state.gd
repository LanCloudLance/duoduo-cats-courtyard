extends RefCounted
## Story opening only: Yuanyuan is an NPC until the third chapter.
const FLOOR := Rect2(90,390,1090,285)
const HALL := Rect2(1040,270,145,180)
const DESK := Vector2(160,415)
const SOFA := Vector2(400,415)
const TOY := Vector2(695,455)
const CUSHION := Vector2(900,400)
const DOOR := Vector2(1120,300)
var positions: Array[Vector2] = [Vector2(360,475),Vector2(475,510),Vector2(900,365)]
var phase := "chores"
var single := false
var controlled := 0
var notebook := false
var toy := false
var confirmed: Array[bool] = [false,false]
var timer := 0.0
var clock := 0.0
var resting := false
var affection := 0.0
var white_visible := true
var extras := {}
var cue := 0
var event_id := 0
var message := "朵朵：把本子收好，就可以认真休息了。团团，帮我把小玩具找回来吧。"
var idle := 0.0
var finished := false

func valid(point: Vector2) -> bool:
    return FLOOR.has_point(point) or HALL.has_point(point)

func move(point: Vector2, offset: Vector2) -> Vector2:
    var result := point
    var steps := maxi(1,ceili(offset.length()/6))
    for i in range(steps):
        var part := offset/steps
        if valid(result+Vector2(part.x,0)): result.x += part.x
        if valid(result+Vector2(0,part.y)): result.y += part.y
    return result

func say(text: String, sound := 0) -> void:
    message = text
    cue = sound
    event_id += 1
    idle = 0

func switch_actor() -> void:
    if not single or finished: return
    controlled = 1-controlled
    say("现在操作"+("朵朵" if controlled == 0 else "团团")+"。"+("圆圆还在家里自在活动。" if phase in ["chores","rest","leisure"] else "留意伙伴，一起去接圆圆。"))

func objective() -> String:
    match phase:
        "chores": return "收好本子，找回玩具" + (" · 本子 ✓" if notebook else "") + (" · 玩具 ✓" if toy else "")
        "rest": return "正事做完了 · 朵朵去沙发边休息"
        "leisure": return "享受这个下午 · 可以摸猫、玩玩具，或什么都不做"
        "strange": return "走廊传来铃声 · 团团去小门边看看"
        "noticed": return "团团看见了圆圆的尾巴 · 回到朵朵身边，呼唤她"
        "called": return "朵朵去门口看一看 · 团团一起跟上"
        "crossing": return "圆圆，等一下 · 朵朵和团团一起到门口确认出发"
        "complete": return "序章完成 · 我们去接圆圆回家"
    return ""

func hint(slot: int) -> String:
    if finished: return "下一关：点亮第一盏灯"
    var point: Vector2 = positions[slot]
    if phase == "noticed" and slot == 1 and point.distance_to(positions[0]) < 80: return "勾袖口，呼唤朵朵"
    if point.distance_to(DOOR) < 85:
        if phase == "strange" and slot == 1: return "查看门里的白尾巴"
        if phase == "called" and slot == 0: return "查看石板路"
        if phase == "crossing": return "确认出发" if not confirmed[slot] else "等伙伴靠近"
        return "看看小门"
    if point.distance_to(positions[1-slot]) < 80:
        if phase == "noticed" and slot == 1: return "勾袖口，呼唤朵朵"
        if phase not in ["chores","rest"]: return "摸摸团团" if slot == 0 else "蹭一蹭朵朵"
    if slot == 0 and point.distance_to(DESK) < 80: return "收好本子" if not notebook else "看看今天的成果"
    if slot == 1 and point.distance_to(TOY) < 85: return "找回小玩具" if not toy else "拨一拨毛线球"
    if slot == 0 and point.distance_to(SOFA) < 90: return "坐下来休息" if phase == "rest" else "看看最舒服的位置"
    if white_visible and point.distance_to(CUSHION) < 85: return "揉揉圆圆" if slot == 0 else "看看弟弟"
    return "靠近本子、玩具、猫咪或门口互动"

func interact(slot: int) -> void:
    if slot < 0 or slot > 1 or finished: return
    var p: Vector2 = positions[slot]
    if phase == "noticed" and slot == 1 and p.distance_to(positions[0]) < 80:
        phase = "called"
        resting = false
        affection = 1
        say("团团轻轻勾住袖口。朵朵：怎么啦？你弟又躲哪里睡觉了？",1)
        return
    if p.distance_to(DOOR) < 85:
        if phase == "strange" and slot == 1:
            phase = "noticed"
            say("门缝里闪过一截白尾巴。团团竖起耳朵，回头看向朵朵。",1)
        elif phase == "called" and slot == 0:
            phase = "crossing"
            resting = false
            say("朵朵：圆圆，等一下。团团，我们去接它。",1)
        elif phase == "crossing":
            confirmed[slot] = true
            if single and positions[1-slot].distance_to(DOOR) < 85: confirmed[1-slot] = true
            if confirmed[0] and confirmed[1] and positions[0].distance_to(DOOR) < 85 and positions[1].distance_to(DOOR) < 85:
                finished = true
                phase = "complete"
                say("朵朵握好门边的扶手，团团贴着她的脚边。两位一起踏进亮着小灯的石板路。",2)
            else: say("等一等伙伴。两位都到门边，再一起出发。")
        else: say("门那边像是有一条路……先留意一下圆圆。" if phase != "chores" else "这扇门平时一直关着。先把手里的事情做完吧。")
        return
    if slot == 0 and p.distance_to(DESK) < 80:
        notebook = true
        say("朵朵把本子合好，摆齐铅笔：今天的事情，完成！",1)
    elif slot == 1 and p.distance_to(TOY) < 85:
        toy = true
        extras["toy"] = true
        say("团团从毛线球旁拨出小老鼠玩具，抬头看了一眼朵朵。",3)
    elif slot == 0 and p.distance_to(SOFA) < 90 and phase == "rest":
        phase = "leisure"
        timer = 0
        resting = true
        say("朵朵：好了，剩下的时间我要认真休息。",2)
    elif p.distance_to(positions[1-slot]) < 80:
        affection = 1
        extras["tuantuan"] = true
        say("团团舔了舔她的手，又抱住手指玩。朵朵：好好好，先松爪。",3)
    elif white_visible and p.distance_to(CUSHION) < 85:
        extras["yuanyuan"] = true
        say("圆圆被揉得软软的，慢悠悠动了动尾巴，继续靠着垫子。",3)
    else:
        say(hint(slot))
    if phase == "chores" and notebook and toy:
        phase = "rest"
        say("朵朵：正事做完！接下来，是沙发时间。",1)

func step(dt: float, a: Vector2, b: Vector2, enabled: bool) -> void:
    if not enabled or not is_finite(dt) or dt <= 0 or not a.is_finite() or not b.is_finite(): return
    dt = minf(dt,0.05)
    clock += dt
    if finished: return
    idle += dt
    affection = maxf(0,affection-dt)
    for slot in range(2):
        var direction: Vector2 = a if slot == 0 else b
        if direction.length() > 0.1:
            idle = 0
            if slot == 0: resting = false
        positions[slot] = move(positions[slot],direction.limit_length()*190*dt)
        if positions[slot].distance_to(DOOR) >= 85: confirmed[slot] = false
    if phase == "leisure":
        timer += dt
        if timer >= 4:
            phase = "strange"
            timer = 0
            say("一阵风吹来，走廊的小门轻轻响了。圆圆抬头看了一会儿，走向铃声。",1)
    if phase in ["strange","noticed","called","crossing"]:
        positions[2] = positions[2].move_toward(DOOR,95*dt)
        if positions[2].distance_to(DOOR) < 5 and phase != "strange": white_visible = false
    if idle > 18:
        say(objective()+"。靠近提示的地方，按互动键试一试。")
