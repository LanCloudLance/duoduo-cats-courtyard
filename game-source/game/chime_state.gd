extends RefCounted
const FIELD := Rect2(120,220,1040,490)
const SOURCE := Vector2(180,500)
const MIRRORS := [Vector2(380,500),Vector2(680,400),Vector2(680,600)]
const SOCKETS := [Vector2(380,400),Vector2(380,600)]
const BELLS := [Vector2(380,300),Vector2(880,600)]
const EXIT := Vector2(1070,530)
var positions: Array[Vector2] = [Vector2(240,600),Vector2(290,650),Vector2(210,650)]
var hp: Array[int] = [3,3]
var mirrors: Array = [1,0,0]
var current_cat := 1
var solo_actor := 0
var solo_mode := false
var stage := 1
var source_level := 0
var deploy_time := 0.0
var finished := false
var lens_site := -1
var rays: Array[Dictionary] = []
var receivers: Array = [false,false]
var lit_time := 0.0
var hints := 0
var message := "朵朵：风铃有光才会响吧？先看看灯光往哪儿走。"
var revision := 0
var last_event := ""

func actor(slot: int) -> int:
    return 0 if slot == 0 else current_cat

func mirror_points() -> Array:
    return MIRRORS if stage == 1 else [Vector2(680,600),Vector2(680,400),Vector2(380,600)]

func socket_points() -> Array:
    return SOCKETS if stage == 1 else [Vector2(380,400),Vector2(380,500)]

func bell_points() -> Array:
    return BELLS if stage == 1 else [Vector2(580,600),Vector2(680,500)]

func source_point() -> Vector2:
    return SOURCE if stage == 1 else Vector2(180,400+source_level*100)

func board_blend() -> float:
    return 0.0 if stage == 1 else 1.0-clampf(deploy_time/0.9,0,1)

func party_ready() -> bool:
    return positions.all(func(p): return p.distance_to(EXIT) < 120)

func _near(points: Array, role: int, radius: float = 78) -> int:
    var found := -1
    var distance := radius
    for i in range(points.size()):
        var d: float = positions[role].distance_to(points[i])
        if d < distance: found = i; distance = d
    return found

func interact(slot: int) -> void:
    if slot < 0 or slot > 1 or finished or deploy_time > 0: return
    var role: int = 0 if slot == 0 else current_cat
    if stage == 2 and role == 0 and positions[0].distance_to(source_point()) < 78:
        source_level = 1-source_level
        revision += 1
        last_event = "turn"
        message = "灯沿着立杆滑到了另一层，整条光路都变了。"
        trace()
        return
    var mirror := _near(mirror_points(),role)
    if mirror < 0:
        message = "朵朵：这里没有手柄。到镜子旁看看。" if role == 0 else "猫咪歪头看着镜架上的扣环。"
        return
    if role != 0 or mirror == 1:
        message = "高处的扣环需要团团的爪钩。" if mirror == 1 else "镜架上的手柄适合朵朵来转。"
        return
    _rotate(mirror)

func _rotate(index: int) -> void:
    mirrors[index] = 1-int(mirrors[index])
    message = "镜面转了半圈，光路也随之改变。"
    revision += 1
    last_event = "turn"
    trace()

func tool(slot: int) -> void:
    if slot != 1 or finished or deploy_time > 0: return
    if current_cat == 1:
        if _near([mirror_points()[1]],1) == 0: _rotate(1)
        else: message = "团团的爪钩能碰到镜架高处的扣环。"
    else:
        if lens_site >= 0:
            lens_site = -1
            message = "圆圆挪开了爪子，水晶只留下细细一道光。"
        else:
            lens_site = _near(socket_points(),2,68)
            message = "圆圆趴稳了，水晶把一道光分成了两道。" if lens_site >= 0 else "水晶底座有些松，圆圆可以在旁边稳住它。"
        revision += 1
        last_event = "lens"
        trace()

func switch_cat() -> void:
    current_cat = 3-current_cat

func trace() -> void:
    receivers = [false,false]
    rays.clear()
    if deploy_time > 0: return
    var pending: Array = [{"pos":source_point(),"dir":Vector2.RIGHT}]
    var visited := {}
    var iterations := 0
    while not pending.is_empty() and iterations < 80:
        iterations += 1
        var ray: Dictionary = pending.pop_front()
        var next: Vector2 = ray.pos+ray.dir*100
        var key := str(next)+str(ray.dir)
        if visited.has(key): continue
        visited[key] = true
        if next.x < 180 or next.x > 980 or next.y < 200 or next.y > 700: continue
        rays.append({"from":ray.pos,"to":next})
        var receiver := bell_points().find(next)
        if receiver >= 0:
            # The hood has a visible receiving window on one side. A beam
            # passing behind that window continues along the rail.
            var accepted: bool = stage == 1 or ray.dir == (Vector2.LEFT if receiver == 0 else Vector2.UP)
            if accepted:
                if receiver == 0 or stage == 2: receivers[receiver] = true
                continue
        var direction: Vector2 = ray.dir
        var mirror := mirror_points().find(next)
        if mirror >= 0:
            direction = Vector2(-direction.y,-direction.x) if int(mirrors[mirror]) == 0 else Vector2(direction.y,direction.x)
        if lens_site >= 0 and next == socket_points()[lens_site]:
            pending.append({"pos":next,"dir":Vector2(-direction.y,direction.x)})
        pending.append({"pos":next,"dir":direction})

func step(delta: float, p1: Vector2, p2: Vector2, enabled: bool) -> void:
    if not enabled or not is_finite(delta) or delta <= 0 or not p1.is_finite() or not p2.is_finite(): return
    var dt := minf(delta,0.1)
    deploy_time = maxf(0,deploy_time-dt)
    var inputs := [p1.limit_length(),p2.limit_length()]
    if lens_site >= 0 and current_cat == 2 and p2.length() > 0.1:
        lens_site = -1
        lit_time = 0
        message = "圆圆一挪步，分开的光又合成了一束。"
        revision += 1
        last_event = "lens"
    positions[0] = (positions[0]+inputs[0]*210*dt).clamp(FIELD.position,FIELD.end)
    positions[current_cat] = (positions[current_cat]+inputs[1]*210*dt).clamp(FIELD.position,FIELD.end)
    var follower := 3-current_cat
    if (not solo_mode or finished) and not (follower == 2 and lens_site >= 0):
        var goal: Vector2 = (positions[current_cat]+Vector2(-70,45)).clamp(FIELD.position,FIELD.end)
        positions[follower] = positions[follower].move_toward(goal,(260 if finished else 180)*dt)
    trace()
    if finished: return
    var lit: bool = receivers[0] if stage == 1 else receivers[0] and receivers[1]
    lit_time = lit_time+dt if lit else 0.0
    if lit_time >= 0.6:
        revision += 1
        last_event = "bell"
        lit_time = 0
        if stage == 1:
            stage = 2
            deploy_time = 0.9
            mirrors = [1,1,0]
            lens_site = -1
            trace()
            message = "铃声拉开了木架，镜子沿轨道滑开！铃罩的小窗只接迎面来的光。"
        else:
            finished = true
            lens_site = -1
            message = "两声风铃一起响起，门闩扣住了！圆圆也可以离开水晶啦。"

func request_hint() -> void:
    hints = mini(3,hints+1)
    message = ["看光线碰到斜镜时拐向哪里；铃罩的小窗朝着哪边？","两条光路都会碰到右下那面镜子。转它一次，看看两只铃会怎样。","灯有两种高度，水晶也有两个位置。比较只响一只铃时的光路，找能分出另一条路的位置。"][hints-1]

func objective() -> String:
    if finished: return "风铃门开了 · 带猫猫穿过右侧的门。"
    return "风铃门 · 一道光，一个铃声。" if stage == 1 else "风铃门 · 两只风铃要一起响，门闩才肯松开。"
