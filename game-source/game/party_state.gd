extends RefCounted

const BOUNDS := Rect2(80, 100, 1760, 960)
const RADIUS := 16.0
const SPEED := 220.0
const OBSTACLES: Array[Rect2] = [Rect2(720, 320, 160, 240), Rect2(1200, 760, 240, 80)]
var positions: Array[Vector2] = [Vector2(400, 600), Vector2(510, 640), Vector2(450, 700)]
var current_cat: int = 1
var holding: Array[bool] = [false, false, false]
var pads: Array[Vector2] = [Vector2(540, 700), Vector2(1060, 460)]
var message: String = "一起走走，再试试切换猫咪"
var edge_limited: bool = false
var grid := AStarGrid2D.new()
var path := PackedVector2Array()
var path_target := Vector2i(-1, -1)
var path_timer: float = 0.0
var bridge
var navigation_revision: int = -1
var recovery_delay: float = 0.0

func _init(bridge_state = null) -> void:
    bridge = bridge_state
    grid.region = Rect2i(0, 0, 44, 24)
    grid.cell_size = Vector2(40, 40)
    grid.offset = BOUNDS.position + Vector2(20, 20)
    grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
    grid.update()
    if bridge:
        pads[1] = Vector2(1700, 850)
    _refresh_navigation()

func _refresh_navigation() -> void:
    for x in range(44):
        for y in range(24):
            var cell := Vector2i(x, y)
            grid.set_point_solid(cell, not _walkable(grid.get_point_position(cell)))
    navigation_revision = bridge.revision if bridge else -1
    path.clear()

func step(delta: float, p1: Vector2, p2: Vector2, enabled: bool) -> void:
    if not enabled or not is_finite(delta) or delta <= 0:
        return
    var dt := minf(delta, 0.1)
    if bridge and navigation_revision != bridge.revision:
        _refresh_navigation()
    recovery_delay = maxf(0, recovery_delay - dt)
    edge_limited = false
    _move(0, p1.limit_length() * SPEED * dt)
    if p2.length_squared() > 0.001:
        holding[current_cat] = false
    if current_cat != 1 or recovery_delay <= 0:
        _move(current_cat, p2.limit_length() * SPEED * dt)
    _follow(dt)

func _walkable(point: Vector2, actor: int = -1) -> bool:
    if not point.is_finite() or not BOUNDS.grow(-RADIUS).has_point(point):
        return false
    for obstacle in OBSTACLES:
        if obstacle.grow(RADIUS).has_point(point):
            return false
    if bridge and not bridge.allows(actor, point):
        return false
    return true

func _fits_team(index: int, point: Vector2) -> bool:
    for other in range(3):
        if other == index:
            continue
        var offset := point - positions[other]
        if absf(offset.x) > 880.0 or absf(offset.y) > 440.0:
            return false
    return true

func _move(index: int, displacement: Vector2) -> void:
    if not displacement.is_finite():
        return
    # Small steps prevent a low frame rate from tunnelling through a flowerbed.
    var steps := maxi(1, ceili(displacement.length() / 8.0))
    var amount := displacement / float(steps)
    for i in range(steps):
        for axis in [Vector2(amount.x, 0), Vector2(0, amount.y)]:
            var target: Vector2 = positions[index] + axis
            if bridge and bridge.would_fall(index, positions[index], target):
                positions[index] = bridge.recover()
                recovery_delay = 0.4
                holding[index] = false
                path.clear()
                return
            if not _fits_team(index, target):
                edge_limited = true
            elif _walkable(target, index):
                positions[index] = target

func _cell(point: Vector2) -> Vector2i:
    var cell := Vector2i(((point - grid.offset) / grid.cell_size).round())
    cell.x = clampi(cell.x, 0, 43)
    cell.y = clampi(cell.y, 0, 23)
    if not grid.is_point_solid(cell):
        return cell
    for radius in range(1, 4):
        for dx in range(-radius, radius + 1):
            for dy in range(-radius, radius + 1):
                var candidate := cell + Vector2i(dx, dy)
                if grid.is_in_boundsv(candidate) and not grid.is_point_solid(candidate):
                    return candidate
    return cell

func _follow(delta: float) -> void:
    var follower := 3 - current_cat
    if holding[follower]:
        return
    var goal: Vector2 = positions[current_cat]
    if bridge and bridge.unlocked < 3:
        if follower == 1 and bridge.RIVER.has_point(positions[1]):
            return
        if follower == 2 and positions[1].x >= 1000:
            goal = Vector2(980, 720)
    if positions[follower].distance_to(goal) <= 64.0:
        path.clear()
        return
    path_timer -= delta
    var target_cell := _cell(goal)
    if path.is_empty() or (target_cell != path_target and path_timer <= 0):
        path_target = target_cell
        path_timer = 0.3
        var origin_cell := _cell(positions[follower])
        if grid.is_point_solid(origin_cell) or grid.is_point_solid(target_cell):
            return
        path = grid.get_point_path(origin_cell, target_cell)
        if path.size() > 1 and positions[follower].distance_to(path[0]) < 28:
            path.remove_at(0)
    while not path.is_empty() and positions[follower].distance_to(path[0]) < 5:
        path.remove_at(0)
    if not path.is_empty():
        var toward := path[0] - positions[follower]
        _move(follower, toward.limit_length(275.0 * delta))

func switch_cat() -> void:
    current_cat = 3 - current_cat
    path.clear()
    path_timer = 0
    message = "现在控制%s" % ("团团" if current_cat == 1 else "圆圆")

func toggle_hold() -> bool:
    if holding[current_cat]:
        holding[current_cat] = false
        message = "一起继续走吧"
        return true
    for pad in pads:
        if positions[current_cat].distance_to(pad) <= 48:
            holding[current_cat] = true
            message = "已经留下等候 · 可以切换另一只猫"
            return true
    message = "先走到发光脚印旁，再按右肩键"
    return false

func camera_center() -> Vector2:
    var bounds := Rect2(positions[0], Vector2.ZERO)
    for point in positions:
        bounds = bounds.expand(point)
    return bounds.get_center() + Vector2(0, -20)

func camera_zoom() -> float:
    var bounds := Rect2(positions[0], Vector2.ZERO)
    for point in positions:
        bounds = bounds.expand(point)
    return clampf(minf(1200.0 / (bounds.size.x + 280.0), 600.0 / (bounds.size.y + 230.0)), 0.88, 1.18)
