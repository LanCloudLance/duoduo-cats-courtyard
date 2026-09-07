extends RefCounted
const Map = preload("res://game/light_layout.gd")
const BEAM_RADIUS := 68.0
const SUPPORT_RADIUS := 56.0
const SPEED := 220.0
var positions: Array[Vector2] = [Vector2(165,425),Vector2(220,470),Vector2(130,495)]
var checkpoints: Array[Vector2] = [Vector2(260,520),Vector2(260,440),Vector2(150,540)]
var recovery_delay: Array[float] = [0.0,0.0,0.0]
var slipping: Array[float] = [0.0,0.0,0.0]
var hp: Array[int] = [3,3]
var solo_mode := false
var solo_actor := 0
var held_actor := -1
var held_point := Vector2.ZERO
var current_cat := 1
var phase := "cat"
var lit := false
var source := ""
var route := "safe"
var operator_slot := -1
var beam := Vector2(260,440)
var front_fixed := false
var latched := false
var permanent := false
var finished := false
var recoveries := 0
var confirmed: Array[bool] = [false,false]
var message := "圆圆先在近岸灯位坐稳；朵朵照路，团团去中岛。"
func actor(slot: int) -> int:
    return 0 if slot == 0 else current_cat
func path() -> Array:
    if phase == "cat": return Map.CAT_PATH
    if phase == "girl": return Map.GIRL_PATH
    return Map.SAFE_PATH if route == "safe" else Map.FAST_PATH
func traveler() -> int:
    return 0 if phase == "girl" else 1
func path_width() -> float:
    if phase == "girl": return 30.0
    return 28.0 if phase == "route" and route == "safe" else 23.0
func is_safe(point: Vector2) -> bool:
    if Map.bank(point) >= 0: return true
    if Map.ISLAND_ONE.grow(-5).has_point(point): return true
    if Map.ISLAND_SAFE.grow(-5).has_point(point): return true
    if front_fixed and point.x >= 265 and point.x <= 595 and absf(point.y-480) <= 34: return true
    if permanent and point.x >= 745 and point.x <= 1075 and absf(point.y-480) <= 34: return true
    return false
func _source_ready() -> bool:
    return lit and ((phase in ["cat","girl"] and source == "near") or (phase == "route" and source == route))
func _physical_path(index: int, point: Vector2) -> bool:
    return index == traveler() and _source_ready() and not permanent and Map.distance_to_path(point,path()) <= path_width()
func _supported(point: Vector2) -> bool:
    return point.distance_to(beam) <= SUPPORT_RADIUS
func park_traveler(index: int) -> void:
    if solo_mode and index == traveler() and _physical_path(index,positions[index]) and _supported(positions[index]) and slipping[index] <= 0 and recovery_delay[index] <= 0:
        held_actor = index
        held_point = positions[index]
func _held(index: int) -> bool:
    return solo_mode and held_actor == index and _source_ready() and index == traveler() and positions[index].distance_to(held_point) <= 4
func is_operator(index: int) -> bool:
    return (operator_slot == 0 and index == 0) or (operator_slot == 1 and index == 1)
func allows(index: int, point: Vector2) -> bool:
    if not point.is_finite() or not Map.FIELD.grow(-10).has_point(point): return false
    return is_safe(point) or (_physical_path(index,point) and _supported(point))
func switch_cat() -> void:
    if finished: return
    if operator_slot == 1 and not solo_mode: operator_slot = -1
    current_cat = 3-current_cat
    confirmed[1] = false
    message = "团团接棒，圆圆继续定光。" if current_cat == 1 and lit else "切到%s；非主动猫在安全处等候。" % ("团团" if current_cat == 1 else "圆圆")
func _start_aim(slot: int) -> void:
    if not _source_ready():
        message = "先让圆圆在这一段的灯位展开定光扣。"
        return
    operator_slot = slot
    message = "你照着我，我接住你。方向控制光斑；再按操作键离开台子。"
func interact(slot: int) -> void:
    if slot < 0 or slot > 1 or finished: return
    if slot == 0 and operator_slot == 0:
        operator_slot = -1
        message = "朵朵离开导光台，光斑停在原处。"
        return
    var point := positions[actor(slot)]
    if permanent and point.distance_to(Map.EXIT) <= 85:
        confirmed[slot] = true
        _check_finish()
        return
    if slot == 1:
        if phase == "route" and current_cat == 1 and Map.ISLAND_SAFE.grow(-5).has_point(point):
            positions[1] = Vector2(740,380 if route == "safe" else 530)
            checkpoints[1] = positions[1]
            slipping[1] = 0
            beam = positions[1]
            message = "团团回到中岛，可以换灯位再选一条路。"
        else: message = "猫咪用工具键操作灯位、反光台与桥锁。"
        return
    if phase == "cat" and point.distance_to(Map.GUIDE_NEAR) <= 42:
        _start_aim(0)
    elif phase == "girl" and point.distance_to(Map.FRONT_LOCK) <= 38:
        front_fixed = true
        phase = "route"
        operator_slot = -1
        beam = Vector2(740,380)
        checkpoints[0] = Map.FRONT_LOCK
        checkpoints[1] = Vector2(740,380)
        message = "前桥固定！接圆圆到中岛：左灯位稳妥，右灯位走捷径。"
    elif phase == "route" and point.distance_to(Map.FAR_WINCH) <= 34 and latched:
        permanent = true
        operator_slot = -1
        message = "永久桥放稳了！切圆圆收光，三位到出口集合。"
    elif phase == "route" and not latched and point.distance_to(Map.GUIDE_MID) <= 40:
        _start_aim(0)
    else: message = "走近当前发亮的操作台或桥扣，再按互动键。"
func tool(slot: int) -> void:
    if slot != 1 or finished: return
    if current_cat == 2:
        if lit:
            _release_light()
            return
        var point := positions[2]
        if not front_fixed and point.distance_to(Map.LAMP_NEAR) <= 34:
            source = "near"
        elif front_fixed and point.distance_to(Map.LAMP_SAFE) <= 34:
            source = "safe"
        elif front_fixed and point.distance_to(Map.LAMP_FAST) <= 34:
            source = "fast"
        else:
            message = "圆圆要先走到当前可用灯位，再展开定光扣。"
            return
        lit = true
        if front_fixed:
            held_actor = -1
            route = source
            # Old-route temporary positions are never carried into another branch.
            if not is_safe(positions[1]): _recover(1)
            beam = Vector2(740,380 if route == "safe" else 530)
            checkpoints[1] = beam
        message = "圆圆坐稳了，切团团开始配合。" if source == "near" else ("稳妥线：路宽，中途能休息。" if route == "safe" else "捷径：连续弯道，没有中途安全岛。")
        return
    if operator_slot == 1:
        operator_slot = -1
        message = "团团松开反光台，光斑停在原处。"
    elif phase == "cat" and positions[1].distance_to(Map.RELAY) <= 40 and _source_ready():
        phase = "girl"
        operator_slot = -1
        beam = Vector2(260,520)
        message = "团团展开宽桥面！再按工具键接手照光，朵朵从近岸下方过桥。"
    elif phase == "girl" and positions[1].distance_to(Map.RELAY) <= 40:
        _start_aim(1)
    elif phase == "route" and _source_ready() and positions[1].distance_to(Map.FAR_LOCK) <= 40:
        latched = true
        operator_slot = -1
        message = "远岸锁开了！朵朵到中岛绞盘放桥。"
    else: message = "团团到中岛反光台或远岸桥锁旁，使用爪钩。"
func _release_light() -> void:
    held_actor = -1
    lit = false
    operator_slot = -1
    for i in range(3):
        if not is_safe(positions[i]): _recover(i)
    message = "圆圆收光了，临时路上的伙伴已回安全点；桥扣进度保留。"
func _checkpoint(index: int) -> void:
    var point := positions[index]
    if Map.ISLAND_ONE.grow(-10).has_point(point): checkpoints[index] = Map.ISLAND_ONE.get_center()
    elif Map.ISLAND_SAFE.grow(-10).has_point(point): checkpoints[index] = Map.ISLAND_SAFE.get_center()
    elif Map.NEAR.grow(-8).has_point(point): checkpoints[index] = Vector2(260,520 if index == 0 else 440)
    elif Map.MID.grow(-8).has_point(point): checkpoints[index] = Vector2(605,480) if index == 0 else Vector2(740,380 if route == "safe" else 530)
    elif Map.FAR.grow(-8).has_point(point): checkpoints[index] = Vector2(1080,480)
func _recover(index: int) -> void:
    if held_actor == index: held_actor = -1
    positions[index] = checkpoints[index]
    recovery_delay[index] = 0.6
    slipping[index] = 0
    recoveries += 1
    beam = positions[index]
    message = "回到安全点，已经固定的桥还在；等光照好再出发。"
func _move(index: int, offset: Vector2) -> void:
    if recovery_delay[index] > 0: return
    if offset.is_zero_approx():
        if is_safe(positions[index]): _checkpoint(index)
        return
    var count := maxi(1,ceili(offset.length()/5.0))
    for i in range(count):
        var target := positions[index] + offset/float(count)
        if not Map.FIELD.grow(-10).has_point(target): return
        if is_safe(target):
            positions[index] = target
        elif _physical_path(index,target):
            if not _supported(target):
                if not is_safe(positions[index]) and not _held(index): slipping[index] = maxf(slipping[index],0.001)
                return
            positions[index] = target
        else:
            if not is_safe(positions[index]): _recover(index)
            return
        if held_actor == index and positions[index].distance_to(held_point) > 4: held_actor = -1
        _checkpoint(index)
func _follow(dt: float) -> void:
    var follower := 3-current_cat
    if follower == 2 and lit: return
    var point := positions[follower]
    if follower == 1 and not permanent and point.x >= 580: return
    var target := (positions[current_cat]+Vector2(-42,30)).clamp(Map.FIELD.position+Vector2(15,15),Map.FIELD.end-Vector2(15,15))
    # Nonactive cats never use a temporary crossing, even when it is lit.
    var from_bank := Map.bank(point)
    var to_bank := Map.bank(target)
    if from_bank != to_bank:
        if (point.x < 580 or target.x < 580) and not front_fixed: return
        if (point.x > 760 or target.x > 760) and not permanent: return
    if not is_safe(point): return
    var goal := target
    if (point.x < 580 and target.x >= 280) or (point.x > 580 and target.x < 580) or (point.x > 760 and target.x < 1060) or (point.x < 1060 and target.x >= 1060):
        goal = Vector2(point.x,480) if absf(point.y-480) > 3 else Vector2(target.x,480)
    elif from_bank == -1: goal = Vector2(target.x,480)
    if point.distance_to(goal) <= 5: return
    var next := point + (goal-point).limit_length(245*dt)
    if is_safe(next): positions[follower] = next
func _check_finish() -> void:
    if not permanent or lit: return
    if not (confirmed[0] or confirmed[1]) if solo_mode else not (confirmed[0] and confirmed[1]): return
    for point in positions:
        if point.distance_to(Map.EXIT) > 105: return
    finished = true
    message = "朵朵：这次是我们一起走过来的。现在申请休息！"
func step(delta: float, p1: Vector2, p2: Vector2, enabled: bool) -> void:
    if not enabled or finished or not is_finite(delta) or delta <= 0 or not p1.is_finite() or not p2.is_finite(): return
    var dt := minf(delta,0.1)
    var inputs := [p1.limit_length(),p2.limit_length()]
    if current_cat == 2 and lit and p2.length_squared() > 0.001: _release_light()
    if operator_slot >= 0 and (not solo_mode or is_operator(solo_actor)):
        beam += inputs[operator_slot]*280.0*dt
        var bounds := Rect2(250,305,360,270) if phase != "route" else Rect2(730,280,365,310)
        beam = beam.clamp(bounds.position,bounds.end)
    for index in range(3):
        recovery_delay[index] = maxf(0,recovery_delay[index]-dt)
        if not is_safe(positions[index]) and not _held(index) and (not _source_ready() or not _supported(positions[index]) or slipping[index] > 0):
            if _source_ready() and _supported(positions[index]):
                slipping[index] = 0
            else:
                slipping[index] += dt
                if slipping[index] >= (1.8 if phase == "cat" else 1.2): _recover(index)
        elif is_safe(positions[index]): slipping[index] = 0
    for slot in range(2):
        var index := actor(slot)
        var operating: bool = is_operator(index) if solo_mode else slot == operator_slot
        if not operating and slipping[index] <= 0:
            _move(index,inputs[slot]*SPEED*dt)
        if positions[index].distance_to(Map.EXIT) > 85: confirmed[slot] = false
    _follow(dt)
    _check_finish()
func objective() -> String:
    if finished: return "灯廊完成 · 再按互动键去林边休息。"
    if permanent: return "切圆圆收光，三位到远岸出口；朵朵与猫咪分别确认。"
    if latched: return "远岸锁已开 · 朵朵到中岛下方绞盘放下永久桥。"
    if phase == "cat": return "① 朵朵照路，团团去中岛 · 光斑只照亮一小段。" if lit else "① 圆圆到近岸灯位定光，切团团；朵朵到导光台。"
    if phase == "girl": return "② 交换职责 · 团团在中岛导光，朵朵从近岸下方走宽桥。"
    if not _source_ready(): return "③ 前桥已固定 · 接圆圆到中岛，选稳妥线或捷径灯位。"
    return "③ %s · 朵朵在中岛导光，团团去远岸开锁。" % ("稳妥线" if route == "safe" else "捷径")
