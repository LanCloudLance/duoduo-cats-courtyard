extends RefCounted
## A small observable room system; chores are optional, never progression gates.
const FLOOR := Rect2(90,390,1090,285)
const HALL := Rect2(1040,270,145,180)
const DESK := Vector2(160,415)
const SOFA := Vector2(400,415)
const TOY := Vector2(680,500)
const CUSHION := Vector2(900,400)
const DOOR := Vector2(1120,300)
var positions: Array[Vector2] = [Vector2(380,495),Vector2(505,520),Vector2(900,365)]
var facing: Array[Vector2] = [Vector2.RIGHT,Vector2.RIGHT,Vector2.RIGHT]
var actions: Array[String] = ["","","sleep"]
var action_time: Array[float] = [0.0,0.0,0.0]
var single := false
var controlled := 0
var phase := "home"
var timer := 0.0
var clock := 0.0
var finished := false
var white_visible := true
var white_alpha := 1.0
var white_wait := 0.0
var resting := false
var affection := 0.0
var extras := {}
var cue := 0
var event_id := 0
var message := "朵朵：今天的正事做完了。接下来，什么都不干也可以。"
var message_time := 6.0
var history:Array[String]=[]
var door_open := 0.0
var brace := false
var wedged := false
var rug_pull := 0.0
var rug_grab := false
var rug_anchor := Vector2.ZERO
var rug_start := 0.0
var rug_shake := 0.0
var ball := TOY
var ball_velocity := Vector2.ZERO
var ball_spin := 0.0
var wedge := DESK
var carrier := -1
var hint_level := 0
var exit_time := 0.0

func checkpoint() -> Dictionary:
    return preload("res://game/prologue_checkpoint.gd").capture(self)
func restore_checkpoint(data: Dictionary) -> bool:
    return preload("res://game/prologue_checkpoint.gd").restore(self,data)
func cancel_inputs() -> void:
    brace = false
    rug_grab = false
    resting = false
    actions[0] = ""
    actions[1] = ""
    action_time = [0.0,0.0,0.0]
func tool(slot: int) -> void:
    if slot < 0 or slot > 1 or finished or phase == "leaving": return
    var item := target(slot)
    if item in ["松手","松开","门挡","放下门挡","地毯边缘"] or (phase == "jam" and item in ["门把手","门缝"]):
        interact(slot)
    else:
        say("朵朵：我的手空着，可以拿门挡，或在门边撑住门。" if slot == 0 else "团团伸了伸爪：靠近物件，才能叼门挡或抓住卷边。")

func valid(p: Vector2) -> bool: return FLOOR.has_point(p) or HALL.has_point(p)
func move(p: Vector2, offset: Vector2) -> Vector2:
    var result := p
    var count := maxi(1,ceili(offset.length()/6))
    for i in range(count):
        var part := offset/count
        if valid(result+Vector2(part.x,0)): result.x += part.x
        if valid(result+Vector2(0,part.y)): result.y += part.y
    return result
func say(text: String, sound := 0) -> void:
    message = text
    message_time = 5.0
    cue = sound
    event_id += 1
    if history.is_empty() or history.back()!=text:
        history.append(text.left(280))
        if history.size()>32:history.pop_front()
func act(slot: int, kind: String, duration := 0.6) -> void:
    actions[slot] = kind
    action_time[slot] = duration
func switch_actor() -> void:
    if single and not finished: controlled = 1-controlled
func objective() -> String:
    if phase == "jam": return "圆圆在门那边……"
    if phase in ["open","leaving","complete"]: return "一起去接圆圆回家"
    return "一个不用赶时间的下午"
func rug_position() -> Vector2: return Vector2(1120,352+rug_pull)
func near_door(slot: int) -> bool: return positions[slot].distance_to(DOOR) < 78
func target(slot: int) -> String:
    if finished or phase == "leaving": return ""
    if slot == 0 and brace: return "松手"
    if slot == 1 and rug_grab: return "松开"
    if white_visible and positions[slot].distance_to(positions[2]) < 74: return "圆圆"
    # The handle and carpet occupy different heights, so one cannot eat the other's input.
    if slot == 1 and positions[slot].distance_to(rug_position()) < 65 and phase == "jam": return "地毯边缘"
    if near_door(slot): return "门把手" if slot == 0 else "门缝"
    if carrier < 0 and not wedged and positions[slot].distance_to(wedge) < 62: return "门挡"
    if positions[slot].distance_to(ball) < 67: return "毛线球"
    if positions[slot].distance_to(positions[1-slot]) < 72: return "团团" if slot == 0 else "朵朵"
    if slot == 0 and positions[0].distance_to(SOFA) < 65: return "坐一会儿"
    if carrier == slot: return "放下门挡"
    return ""
func hint(slot: int) -> String: return target(slot)
func request_hint() -> void:
    if phase != "jam":
        say("朵朵：圆圆的耳朵一直朝着走廊。它在听什么？")
        return
    hint_level = mini(hint_level+1,3)
    say(["朵朵：门每次弹回来，下面那块地毯都会跟着动。","朵朵：门压着卷边。先让门别往下压，再试试地毯。","朵朵可以撑门，或带上木门挡；团团够得到卷边。抓住后，往房间里退。"][hint_level-1])
func interact(slot: int) -> void:
    if slot < 0 or slot > 1 or finished or phase == "leaving": return
    if action_time[slot] > 0.1: return
    var item := target(slot)
    if item == "松手":
        brace = false
        actions[0] = ""
        return
    if item == "松开":
        rug_grab = false
        actions[1] = ""
        return
    if item == "圆圆":
        act(slot,"pet",1.0)
        act(2,"listen",1.2)
        affection = 1
        white_wait = 2.5
        extras["yuanyuan"] = true
        say("圆圆停下来，回头蹭了蹭伸来的手。",3)
    elif item in ["门把手","门缝"]:
        if phase == "jam":
            if slot == 0:
                brace = true
                actions[0] = "brace"
                if carrier == 0:
                    carrier = -1
                    wedged = true
                    wedge = DOOR+Vector2(-35,20)
                    say("门挡卡住了门。松手之后，门也没有弹回来。",0)
                else: say("门抬起了一点，卷边松了。朵朵的手还撑着门。",0)
            elif carrier == 1 and (brace or door_open > 0.2):
                carrier = -1
                wedged = true
                wedge = DOOR+Vector2(-35,20)
                act(1,"paw")
                say("团团把木门挡塞到门底。",0)
            else:
                act(1,"sniff")
                rug_shake = 0.7
                say("团团够不到门把手。门底压着的东西轻轻颤了一下。",0)
        elif phase == "open": say("朵朵：团团，走吧。圆圆就在前面。")
        else:
            act(slot,"pet" if slot == 0 else "sniff")
            say("门后传来很轻的铃声。圆圆也听见了。",1)
            if phase == "home": _phase("listen")
    elif item == "地毯边缘":
        act(1,"paw",0.35)
        if brace or wedged:
            rug_grab = true
            rug_anchor = positions[1]
            rug_start = rug_pull
            say("团团钩住卷边，前爪抓稳了。",3)
        else:
            rug_shake = 0.9
            say("卷边被压得紧紧的。团团一用力，门也跟着晃。",0)
    elif item == "门挡":
        carrier = slot
        act(slot,"pet" if slot == 0 else "paw")
        extras["wedge"] = true
        say("朵朵拿起小木门挡。" if slot == 0 else "团团叼起小木门挡。",3)
    elif item == "放下门挡":
        carrier = -1
        wedge = move(positions[slot],facing[slot]*40)
        act(slot,"pet" if slot == 0 else "paw")
    elif item == "毛线球":
        var direction := (ball-positions[slot]).normalized()
        if direction.length() < 0.1: direction = facing[slot]
        ball_velocity = direction*(330 if slot == 1 else 230)
        act(slot,"paw" if slot == 1 else "pet",0.45)
        extras["toy"] = true
        cue = 3
        event_id += 1
    elif item in ["团团","朵朵"]:
        act(0,"pet",1.1)
        act(1,"sniff",1.1)
        affection = 1
        extras["tuantuan"] = true
        say("团团伸长脖子舔舔手，又用爪子抱住了手指。",3)
    elif item == "坐一会儿":
        resting = true
        actions[0] = "sit"
        say("朵朵：嗯……今天就坐在这里了。",2)
func _phase(value: String) -> void:
    phase = value
    timer = 0
    if value == "listen":
        actions[2] = "listen"
        cue = 1
        event_id += 1
    elif value == "sniff": actions[2] = "walk"
    elif value == "peek": actions[2] = "listen"
    elif value == "slip":
        actions[2] = "walk"
        say("朵朵：圆圆？……你在看什么？")
    elif value == "jam":
        white_visible = false
        white_alpha = 0
        say("门轻轻弹了回来。门那边，传来圆圆的小脚步声。",0)
    elif value == "open":
        rug_grab = false
        brace = false
        actions[0] = ""
        actions[1] = ""
        say("地毯终于滑出来，门慢慢打开了。朵朵：团团，我们去接它。",2)
func step(dt: float, a: Vector2, b: Vector2, enabled: bool) -> void:
    if not enabled or not is_finite(dt) or dt <= 0 or not a.is_finite() or not b.is_finite(): return
    dt = minf(dt,0.05)
    clock += dt
    if finished: return
    timer += dt
    message_time = maxf(0,message_time-dt)
    white_wait = maxf(0,white_wait-dt)
    affection = maxf(0,affection-dt)
    rug_shake = maxf(0,rug_shake-dt)
    for slot in range(2):
        action_time[slot] = maxf(0,action_time[slot]-dt)
        var direction: Vector2 = (a if slot == 0 else b).limit_length()
        if phase == "leaving": direction = Vector2.ZERO
        if direction.length() > 0.1:
            facing[slot] = direction
            if slot == 0:
                resting = false
                brace = false
        if action_time[slot] <= 0:
            if not (slot == 0 and (resting or brace)) and not (slot == 1 and rug_grab): actions[slot] = ""
            positions[slot] = move(positions[slot],direction*(85 if slot == 1 and rug_grab else 190)*dt)
    if brace: positions[0] = positions[0].move_toward(Vector2(1145,280),190*dt)
    if carrier >= 0: wedge = positions[carrier]+Vector2(28,-36)
    var proposed := ball+ball_velocity*dt
    if not valid(proposed): ball_velocity *= -0.62
    else: ball = proposed
    ball_spin += ball_velocity.length()*dt*0.04
    ball_velocity = ball_velocity.move_toward(Vector2.ZERO,110*dt)
    var audience := minf(positions[0].distance_to(DOOR),positions[1].distance_to(DOOR)) < 345
    if phase == "home":
        if minf(positions[0].distance_to(positions[2]),positions[1].distance_to(positions[2])) < 260 or audience: _phase("listen")
        elif timer > 10 and actions[2] == "sleep":
            actions[2] = "listen"
            cue = 1
            event_id += 1
    elif phase == "listen":
        if timer > 2.5 and white_wait <= 0: _phase("sniff")
    elif phase == "sniff":
        if white_wait <= 0:
            actions[2] = "walk"
            positions[2] = positions[2].move_toward(Vector2(1095,362),36*dt)
            if positions[2].distance_to(Vector2(1095,362)) < 3: _phase("peek")
    elif phase == "peek":
        if not audience or white_wait > 0: timer = 0
        if timer > 3: _phase("slip")
    elif phase == "slip":
        if not audience or white_wait > 0: timer = 0
        else:
            actions[2] = "walk"
            positions[2] = positions[2].move_toward(Vector2(1135,267),48*dt)
            white_alpha = clampf((positions[2].y-267)/35,0,1)
            if positions[2].y < 269: _phase("jam")
    elif phase == "jam":
        if rug_grab:
            actions[1] = "pull"
            if not brace and not wedged:
                rug_grab = false
                rug_shake = 0.6
                say("门又压了下来，卷边动不了了。",0)
            else:
                # Only physically dragging away from the door dislodges the runner.
                rug_pull = clampf(rug_start+positions[1].y-rug_anchor.y,0,115)
                if absf(positions[1].x-rug_anchor.x) > 100: rug_grab = false
                if rug_pull >= 105: _phase("open")
    elif phase == "open":
        if near_door(0) and near_door(1):
            exit_time += dt
            if exit_time > 0.6: _phase("leaving")
        else: exit_time = 0
    elif phase == "leaving":
        for slot in range(2): positions[slot] = positions[slot].move_toward(DOOR+Vector2(slot*28-14,-32),50*dt)
        if timer > 1.6:
            phase = "complete"
            finished = true
    var opening := 0.0
    if phase in ["peek","slip"]: opening = 0.20
    elif phase == "jam": opening = 0.40 if brace or wedged else 0.035
    elif phase in ["open","leaving","complete"]: opening = 1.0
    door_open = move_toward(door_open,opening,dt*0.75)
