extends RefCounted
## Two-person story scene. Puzzle actors stay where the player leaves them.
const FLOOR := Rect2(90,210,1100,450)
const Checkpoint = preload("res://game/chapter_one_checkpoint.gd")
const TRUNK := Rect2(600,210,65,450)
const TAG := Vector2(155,400)
const GRANNY := Vector2(330,350)
const LIFT := Vector2(550,440)
const FORK := Vector2(390,570)
const SOCKET := Vector2(585,570)
const KNOT := Vector2(695,550)
const ROAD_EXIT := Vector2(1080,570)
const BENCH := Vector2(650,350)
const LAMP := Vector2(850,400)
const HOOD := Vector2(930,455)
const VENT := Vector2(805,490)
const PILLOW := Vector2(1080,375)
const SEAT := Vector2(960,560)
var positions: Array[Vector2] = [Vector2(210,435),Vector2(265,475)]
var facing: Array[Vector2] = [Vector2.RIGHT,Vector2.RIGHT]
var single := true
var controlled := 0
var phase := "arrival"
var clock := 0.0
var bracing := false
var supported := false
var branch_clear := false
var branch_raise := 0.0
var carrier := -1
var fork_pos := FORK
var rope_flash := 0.0
var battle_requested := false
var equipment := false
var core_found := false
var core_ready := false
var core_installed := false
var hood := 3
var vent := 0
var flame := 0.0
var steady := 0.0
var lit := false
var light_reveal := 0.0
var clue_seen := false
var resting := 0.0
var finished := false
var extras := {}
var message := "朵朵：门里还是我们的家……可是，手碰不到。团团，先找圆圆。"
var message_time := 8.0
var history:Array[String]=[]
var event_id := 0
var cue := 0
var hint_context := ""
var hint_level := 0
var actions: Array[String] = ["",""]
var action_time: Array[float] = [0.0,0.0]

func say(text: String, sound := 0) -> void:
    message = text;message_time = 6.5;cue = sound;event_id += 1
    if history.is_empty() or history.back()!=text:
        history.append(text.left(280))
        if history.size()>32:history.pop_front()
func act(slot: int, kind: String, seconds := 0.55) -> void:
    actions[slot] = kind;action_time[slot] = seconds
func switch_actor() -> void:
    if single and not finished: controlled = 1-controlled
func raised() -> bool: return bracing or supported or branch_clear
func walkable(p: Vector2, role: int) -> bool:
    if not p.is_finite() or not FLOOR.grow(-16).has_point(p): return false
    if phase in ["station","rest","complete"] or branch_clear: return true
    if TRUNK.grow(16).has_point(p): return role == 1 and raised() and p.y >= 544 and p.y <= 603
    return true
func move(role: int, offset: Vector2) -> void:
    var steps := maxi(1,ceili(offset.length()/5))
    for i in range(steps):
        for part in [Vector2(offset.x/steps,0),Vector2(0,offset.y/steps)]:
            if walkable(positions[role]+part,role): positions[role] += part
func near(role: int, p: Vector2, reach := 62.0) -> bool: return positions[role].distance_to(p) < reach
func target(role: int) -> String:
    if finished: return ""
    if phase == "arrival":
        if near(role,GRANNY,85): return "栗婆婆"
        if near(role,TAG): return "空路牌"
        return ""
    if phase == "road":
        if role == 0 and bracing: return "放下枝架"
        if role == 0 and near(role,LIFT) and not branch_clear: return "枝架抬手"
        if role == 1 and near(role,KNOT) and not branch_clear: return "受力绳扣"
        if carrier == role:
            if absf(positions[role].x-585)<68: return "安放木撑"
            return "放下木撑"
        if carrier < 0 and not supported and near(role,fork_pos): return "木撑"
        if branch_clear and near(role,ROAD_EXIT,85): return "林间小道"
    if phase in ["station","rest"]:
        if not core_found and near(role,BENCH): return "矮柜底" if role == 1 else "矮柜"
        if near(role,LAMP): return "灯座"
        if not lit and role == 0 and near(role,HOOD,58): return "遮风罩"
        if not lit and role == 1 and near(role,VENT,58): return "进气片"
        if near(role,PILLOW): return "白毛与脚印"
        if near(role,GRANNY,85): return "栗婆婆"
        if lit and near(role,SEAT,80): return "坐一会儿"
    return ""
func objective() -> String:
    if phase == "arrival": return "第一章 · 点亮第一盏灯"
    if phase == "road": return "去驿站找圆圆的去向"
    if phase == "station": return "让驿站重新亮起来"
    if phase == "rest": return "圆圆来过这里。一起歇一会儿"
    return "第一章完成 · 下一站，山坡钟楼"
func tool(role:int)->void:
    if role not in [0,1] or finished or battle_requested:return
    var item:=target(role)
    if item in ["枝架抬手","放下枝架","木撑","安放木撑","放下木撑","受力绳扣","矮柜底","灯座","遮风罩","进气片"]:
        interact(role);return
    act(role,"inspect")
    say("朵朵把木盾收在手边，看看附近有没有需要撑稳、装好或调整的物件。" if role==0 else "团团伸爪试了试。靠近低处的柜缝、木撑或小绳扣，才能用上它的灵巧。")
func request_hint() -> void:
    var context:=str([phase,supported,branch_clear,core_found,core_ready,core_installed,lit,clue_seen])
    if context!=hint_context:hint_context=context;hint_level=0
    hint_level = mini(3,hint_level+1)
    if phase == "road":
        say(["朵朵：绳扣连着枝架，下面却留着一条很矮的缝。","朵朵：抬起一端，绳子就不那么紧了。木撑可以替我承重。","朵朵抬枝架，木撑放在南边的凹槽；团团从低缝过去，松开另一侧绳扣。"][hint_level-1])
    elif phase == "station":
        say(["朵朵：矮柜下有白毛，也有一点灯芯的光。风把门边的布条吹向右边。","朵朵：火苗需要一点空气，也不能迎着风。观察进气片和罩口。","团团找灯芯送到灯座，朵朵装入；遮风罩开向东侧，进气片留小缝。"][hint_level-1])
    else: say("朵朵：路牌记着回家的方向。先问问这里的人，有没有见过一只白猫。")
func interact(role: int) -> void:
    if role not in [0,1] or action_time[role]>0.1 or battle_requested: return
    var item := target(role)
    match item:
        "空路牌":
            extras["tag"] = true;act(role,"pet" if role==0 else "sniff")
            say("路牌浮出家门的轮廓。朵朵：嗯，回家的地址带上了。",1)
        "栗婆婆":
            act(role,"pet" if role==0 else "sniff")
            if phase == "arrival":
                equipment = true;extras["tag"] = true;phase = "road";hint_level = 0
                say("栗婆婆：白猫往山坡去了。先借你木剑和盾。枝架后就是驿站，我们一起把灯修好。",1)
            elif lit: say("栗婆婆：圆圆睡够就往钟楼去了。归途门亮起，会带你回到离开的那个下午。")
            else: say("栗婆婆：备用灯芯掉进柜底了。灯罩被风扭歪，火苗总留不住。")
        "枝架抬手":
            bracing = true;actions[0] = "brace"
            say("枝架抬起，绳子松了一点，下面露出矮缝。",0)
        "放下枝架": bracing = false;actions[0] = ""
        "木撑":
            carrier = role;act(role,"pet" if role==0 else "paw")
            say("木撑有一个分叉，刚好能托住枝架。",3)
        "安放木撑":
            if near(role,SOCKET,58) and raised():
                supported = true;carrier = -1;fork_pos = SOCKET;act(role,"paw" if role==1 else "pet")
                say("木撑稳稳顶住凹槽。朵朵可以松手了。",2)
            else:
                rope_flash = 0.8
                say("这里没有承重的凹槽，木撑歪了，绳子还是紧的。",0)
        "放下木撑":
            carrier = -1;fork_pos = positions[role]+facing[role]*24;act(role,"paw" if role==1 else "pet")
        "受力绳扣":
            act(role,"paw")
            if raised():
                branch_clear = true;bracing = false;actions[0] = "";hint_level = 0
                say("绳扣松开了！枝架沿斜坡滑到一旁，小道让出来了。",2)
            else: rope_flash = 0.8;say("绳扣勒得太紧，团团扯不动。",0)
        "林间小道":
            if positions.all(func(p):return p.distance_to(ROAD_EXIT)<125):
                battle_requested = true
            else: say("朵朵：团团，我们一起过去。")
        "矮柜": act(role,"pet");say("手够不进去。柜底有白毛，还有一点微光。")
        "矮柜底":
            core_found = true;carrier = 1;act(1,"paw",0.8)
            say("团团从柜底叼出了备用灯芯。",3)
        "灯座":
            act(role,"pet" if role==0 else "paw")
            if carrier == 1 and role == 1 and core_found:
                carrier = -1;core_ready = true;say("团团把灯芯放到灯座边。",3)
            elif role == 0 and core_ready and not core_installed:
                core_installed = true;say("灯芯装回去了。小火苗刚冒出，就被风吹歪了。",1)
            elif lit: say("朵朵：这盏灯终于稳稳亮着了。",2)
            elif core_installed: say(flame_reading())
            else: say("灯座空着。柜子下面有一点同样的光。")
        "遮风罩":
            hood = (hood+1)%4;act(0,"pet")
            say("罩口朝%s，火苗跟着变了。"%["北侧","东侧","南侧","西侧"][hood])
        "进气片":
            vent = (vent+1)%3;act(1,"paw")
            say(["进气片合上，灯里几乎没有空气。","进气片留着小缝，气流轻轻进去。","进气片敞开，气流一下子灌进灯座。"][vent])
        "白毛与脚印":
            clue_seen = true;extras["route"] = true;act(role,"pet" if role==0 else "sniff")
            say("软垫睡出一个圆坑，白毛旁的脚印朝山坡。朵朵：至少……它睡得挺舒服。",3)
        "坐一会儿":
            if not clue_seen: say("朵朵：先看看圆圆有没有留下线索。")
            elif not positions.all(func(p):return p.distance_to(SEAT)<125):say("朵朵：团团，来我这边歇一会儿。")
            else:
                resting = 0.01;actions = ["sit","sniff"]
                say("朵朵：休息五分钟。五分钟以后，我还是很勇敢。",2)
func flame_reading() -> String:
    if vent == 0: return "火苗快憋熄了。底下没有空气流进来。"
    if vent == 2: return "气流太急，小火苗一下子被冲散了。"
    if hood != 1: return "火苗被侧风压倒。布条一直飘向东侧。"
    return "火苗站稳了，灯罩里面慢慢亮起来。"
func enter_station() -> void:
    phase = "station";battle_requested = false;branch_clear = true;equipment = true;hint_level = 0
    positions = [Vector2(390,480),Vector2(450,530)]
    bracing = false;carrier = -1;actions = ["",""];action_time = [0.0,0.0]
    say("栗婆婆：荆棘散开了，谢谢你们。窗台有白毛……先把这盏备用灯修好。",1)
func step(dt: float, a: Vector2, b: Vector2, enabled: bool) -> void:
    if not enabled or not is_finite(dt) or dt<=0 or not a.is_finite() or not b.is_finite():return
    dt = minf(dt,0.05);clock += dt
    message_time = maxf(0,message_time-dt);rope_flash = maxf(0,rope_flash-dt)
    if finished:return
    for role in range(2):
        action_time[role] = maxf(0,action_time[role]-dt)
        var direction:Vector2=(a if role==0 else b).limit_length()
        if resting>0:direction = Vector2.ZERO
        if direction.length()>0.1:
            facing[role] = direction
            if role==0:bracing = false
        if action_time[role]<=0:
            if not (role==0 and bracing):actions[role] = ""
            move(role,direction*(140 if carrier==role else 205)*dt)
    if single and (branch_clear or phase in ["station","rest"]) and resting<=0:
        var follower:=1-controlled
        var goal:=positions[controlled]+Vector2(-42,34)
        if not walkable(goal,follower):goal=positions[controlled]
        if not (follower==0 and bracing) and action_time[follower]<=0 and positions[follower].distance_to(goal)>50:
            var offset:=positions[follower].direction_to(goal)*minf(175*dt,positions[follower].distance_to(goal))
            facing[follower]=offset.normalized();move(follower,offset)
    if bracing: actions[0] = "brace"
    if not raised() and TRUNK.grow(18).has_point(positions[1]):
        positions[1] = Vector2(560,580)
        say("枝架落回去，团团退到安全的这一侧。",0)
    branch_raise = move_toward(branch_raise,1 if raised() else 0,dt*2)
    if phase == "station" and core_installed:
        var correct:=hood==1 and vent==1
        flame = move_toward(flame,1.0 if correct else (0.18 if vent==0 else 0.04),dt*1.5)
        steady = steady+dt if correct else 0.0
        if steady>=2.0:
            lit = true;phase = "rest";hint_level = 0;say("驿站的灯站稳了。窗里、屋檐下，一盏接一盏亮起来。",2)
    if lit:light_reveal = minf(1,light_reveal+dt*0.6)
    if resting>0:
        resting += dt
        if resting>=1.2:
            finished = true;phase = "complete";extras["tag"] = true
            say("团团挨着朵朵坐下。远处的一点灯光，却逆着道路飘向森林深处。",1)
func record() -> Dictionary:
    if not finished:return {}
    return {"version":1,"chapter":"chapter-one","completed":true,"extras":extras.duplicate()}
func checkpoint()->Dictionary:return Checkpoint.capture(self)
func restore_checkpoint(value:Dictionary)->bool:return Checkpoint.restore(self,value)
func restore(value: Dictionary) -> void:
    if value.get("version")!=1 or value.get("chapter")!="chapter-one" or value.get("completed")!=true or not value.get("extras",{}) is Dictionary:return
    extras = value.get("extras",{}).duplicate();enter_station();lit = true;light_reveal = 1;finished = true;phase = "complete";clue_seen = true
