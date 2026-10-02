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
var message := "风把桥板掀起来了。灯架、反光台和桥绳都还完好。"
var pin_site := "loose"
var pin_actor := -1
var pin_pos := Map.FRONT_LOCK+Vector2(24,15)
var bracing := false
var hint_level := 0
var hint_context := ""

func _front_support() -> void:
    front_fixed = pin_site == "front" or bracing

func _bridge_loaded() -> bool:
    for point in positions:
        if point.x > 280 and point.x < 580 and absf(point.y-480) < 36: return true
    return false

func _take_pin(index: int) -> bool:
    if pin_site == "front":
        if _bridge_loaded():
            message = "桥绳还承着重量，金属扣被压紧了。"
            return false
        pin_site = "carried"
        pin_actor = index
        _front_support()
        message = "桥扣拔出来了，前桥板顺着绳索收了回去。"
        return true
    if pin_site == "loose":
        pin_site = "carried"
        pin_actor = index
        message = "一枚沉甸甸的桥扣，侧面有两道凹槽。"
        return true
    return false

func request_hint() -> void:
    var context := "exit" if permanent else "reuse" if phase == "route" else "cross" if phase == "girl" else "light"
    if context != hint_context:
        hint_context = context
        hint_level = 0
    hint_level = mini(3,hint_level+1)
    var hints := {
        "light":["观察：圆圆坐稳灯架后，石板会在光下显出边缘。","规则：团团的体重能走窄路；移动光斑会改变落脚的位置。","试试：圆圆稳住近岸灯架，朵朵操作反光台，照着团团的下一步。"],
        "cross":["观察：中岛反光台旁还有一组更宽的石板。","规则：团团能展开反光台；朵朵需要宽一些的落脚面。","试试：团团接手照光，让朵朵走下方宽路；检查前桥的金属扣槽。"],
        "reuse":["观察：两座桥的扣槽形状一样；前桥扣可以取出。","规则：桥扣只有一枚。撤去支撑会收桥，朵朵也能暂时撑住前桥。","试试：接圆圆到中岛后回收前桥扣。团团牵住远岸桥绳，朵朵带扣到中岛绞盘。"],
        "exit":["观察：远岸木桥已稳住。","规则：圆圆收光后也能走固定木桥。","试试：带三位到远岸出口，再确认出发。"]}
    message = "提示 %d / 3 · %s" % [hint_level,hints[context][hint_level-1]]
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
        message = "反光台没有接到光，石板还是暗的。"
        return
    operator_slot = slot
    message = "反光片转起来了，方向控制光；再按互动键松手。"
func interact(slot: int) -> void:
    if slot < 0 or slot > 1 or finished: return
    if slot == 0 and operator_slot == 0:
        operator_slot = -1
        message = "朵朵离开导光台，光斑停在原处。"
        return
    var point := positions[actor(slot)]
    if slot == 0 and pin_site == "loose" and point.distance_to(pin_pos) <= 44:
        _take_pin(0)
        return
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
    elif phase in ["girl","route"] and point.distance_to(Map.FRONT_LOCK) <= 38:
        if pin_site == "carried" and pin_actor == 0:
            pin_site = "front"
            pin_actor = -1
            bracing = false
            _front_support()
            phase = "route"
            operator_slot = -1
            beam = Vector2(740,380)
            checkpoints[0] = Map.FRONT_LOCK
            message = "桥扣落进槽里，前桥板放平了。"
        elif pin_site == "front": _take_pin(0)
        else: message = "扣槽是空的，桥绳一松就缩回去。朵朵能用工具键撑住绞柄。"
    elif point.distance_to(Map.FAR_WINCH) <= 34:
        if not latched: message = "绞盘空转，远岸的桥绳还没有绷住。"
        elif pin_site != "carried" or pin_actor != 0: message = "绞盘拉得动了，扣槽里却少一枚金属扣。"
        else:
            pin_site = "far"
            pin_actor = -1
            permanent = true
            operator_slot = -1
            message = "同一枚桥扣扣紧后桥，木板稳稳放下了。"
    elif phase == "route" and not latched and point.distance_to(Map.GUIDE_MID) <= 40:
        _start_aim(0)
    else: message = "这里没有够得着的机关。观察绳索和石板的变化；左肩可请求提示。"
func tool(slot: int) -> void:
    if finished: return
    if slot == 0:
        if phase in ["girl","route"] and positions[0].distance_to(Map.FRONT_LOCK) <= 42:
            bracing = not bracing
            _front_support()
            if bracing:
                phase = "route"
                operator_slot = -1
            message = "朵朵撑住绞柄，前桥板放下了；走开就会松手。" if bracing else "朵朵松开了绞柄。"
        elif operator_slot == 0: interact(0)
        else: message = "朵朵伸手够了够，附近没有可用的绞柄。"
        return
    if slot != 1: return
    if current_cat == 1:
        if pin_site == "loose" and positions[1].distance_to(pin_pos) <= 44:
            _take_pin(1)
            return
        if positions[1].distance_to(Map.FRONT_LOCK) <= 38:
            if pin_site == "front":
                _take_pin(1)
                return
            if pin_site == "carried" and pin_actor == 1:
                pin_site = "loose"
                pin_actor = -1
                pin_pos = Map.FRONT_LOCK+Vector2(24,15)
                message = "团团把桥扣放到绞柄旁，朵朵可以拿到。"
                return
    if current_cat == 2:
        if lit:
            _release_light()
            return
        var point := positions[2]
        if point.distance_to(Map.LAMP_NEAR) <= 34:
            source = "near"
            phase = "girl" if phase != "cat" else "cat"
        elif point.distance_to(Map.LAMP_SAFE) <= 34:
            source = "safe"
            phase = "route"
        elif point.distance_to(Map.LAMP_FAST) <= 34:
            source = "fast"
            phase = "route"
        else:
            message = "圆圆坐下了，附近没有与反光台相连的灯架。"
            return
        lit = true
        if source != "near":
            held_actor = -1
            route = source
            # Old-route temporary positions are never carried into another branch.
            if not is_safe(positions[1]): _recover(1)
            beam = Vector2(740,380 if route == "safe" else 530)
            checkpoints[1] = beam
        message = "灯架不晃了，反光台接到光，水上的石板显出轮廓。"
        return
    if operator_slot == 1:
        operator_slot = -1
        message = "团团松开反光台，光斑停在原处。"
    elif phase == "cat" and positions[1].distance_to(Map.RELAY) <= 40 and _source_ready():
        phase = "girl"
        operator_slot = -1
        beam = Vector2(260,520)
        message = "团团拉出另一块反光片，下方更宽的石板亮出了边缘。"
    elif phase == "girl" and positions[1].distance_to(Map.RELAY) <= 40:
        _start_aim(1)
    elif phase == "route" and _source_ready() and positions[1].distance_to(Map.FAR_LOCK) <= 40:
        latched = not latched
        operator_slot = -1
        message = "团团牵住桥绳，另一端的绞盘绳索绷直了；走开会松爪。" if latched else "团团松开桥绳，弹簧把它拉回去了。"
    else: message = "团团用爪子碰了碰，附近没有能拉动的反光片或桥绳。"
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
    if bracing and p1.length() > 0.01:
        bracing = false
        _front_support()
        message = "朵朵松开绞柄，前桥板收回去了。"
    if latched and not permanent and positions[1].distance_to(Map.FAR_LOCK) > 44:
        latched = false
        message = "团团离开后桥绳缩回，绞盘失去拉力。"
    if pin_site == "carried": pin_pos = positions[pin_actor]+Vector2(24,-18)
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
    return "带朵朵、团团、圆圆一起到远岸 · 桥扣只有一枚，走之前也要接回伙伴。"
