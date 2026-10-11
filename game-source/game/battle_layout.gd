extends RefCounted
const Geometry = preload("res://game/battle_space.gd")
const ACTOR_RADIUS := 18.0
const ENEMY_RADIUS := 26.0
const STUMP_RADIUS := 34.0
var FIELD := Rect2(90,230,1100,510)
var STUMPS: Array[Vector2] = [Vector2(595,435)]
var STARTS: Array[Vector2] = [Vector2(295,470),Vector2(335,570)]
var EXIT := Vector2(1080,635)
var id := "first"
const ROUTE_RADIUS := 23.0
const ROUTE_GAP := 96.0
var GATE := Vector2(1008,625)
var route_enabled := false
var route_closed := true
func configure_route(enabled:bool,opened:bool)->void:
    route_enabled=enabled;route_closed=not opened
    GATE=Vector2(1008,625)
func route_points()->Array[Vector2]:
    var result:Array[Vector2]=[]
    if not route_enabled:return result
    for i in range(15):
        var point:=Vector2(GATE.x,FIELD.position.y+i*38)
        if point.y>FIELD.end.y+10:break
        if not route_closed and absf(point.y-GATE.y)<ROUTE_GAP:continue
        result.append(point)
    return result
func configure(name: String) -> void:
    id = name
    if name == "shell":
        FIELD = Rect2(70,210,1140,530)
        STUMPS = [Vector2(530,345),Vector2(780,570)]
        STARTS = [Vector2(290,465),Vector2(330,565)]
        EXIT = Vector2(1110,635)
    elif name == "reserve":
        FIELD = Rect2(90,220,1100,520)
        STUMPS = [Vector2(620,500),Vector2(925,340)]
        STARTS = [Vector2(335,435),Vector2(335,580)]
        EXIT = Vector2(1085,625)
    elif name == "practice":
        FIELD = Rect2(70,220,1140,520)
        STUMPS = [Vector2(560,340),Vector2(780,570)]
func reserve_point(index: int) -> Vector2:
    # Safe left apron: full-height silhouettes remain below the fixed top HUD.
    # Kept outside FIELD; deployed STARTS and all collision geometry are untouched.
    return Vector2(FIELD.position.x-78,FIELD.position.y+180+index*195)
static func contact(from: Vector2,to: Vector2,center: Vector2,radius: float) -> float:
    return Geometry.contact(from,to,center,radius)
func valid(point: Vector2,radius: float) -> bool:
    if not FIELD.grow(-radius).has_point(point): return false
    for stump in STUMPS:
        if point.distance_to(stump) < STUMP_RADIUS+radius: return false
    for gate_point in route_points():
        if point.distance_to(gate_point)<ROUTE_RADIUS+radius:return false
    return true
func move(from: Vector2,offset: Vector2,radius: float) -> Vector2:
    var point := from
    var count := maxi(1,ceili(offset.length()/5.0))
    for index in range(count):
        var delta := offset/float(count)
        for axis in [Vector2(delta.x,0),Vector2(0,delta.y)]:
            var target: Vector2 = (point+axis).clamp(FIELD.position+Vector2.ONE*radius,FIELD.end-Vector2.ONE*(radius+0.001))
            if valid(target,radius): point = target
    return point
func clear_line(from: Vector2,to: Vector2,radius: float) -> bool:
    for stump in STUMPS:
        if contact(from,to,stump,STUMP_RADIUS+radius) != INF: return false
    for gate_point in route_points():
        if contact(from,to,gate_point,ROUTE_RADIUS+radius)!=INF:return false
    return true
func direction(from: Vector2,to: Vector2,radius: float) -> Vector2:
    # A player can fit near a hedge/stump where an enemy center cannot. Choose
    # the nearest valid center on the same side, and prove a path before using it.
    if route_enabled and radius>ACTOR_RADIUS and not valid(to,radius):
        for ring in range(1,33):
            var candidates:Array[Vector2]=[]
            for i in range(32):
                var goal:Vector2=to+Vector2.from_angle(i*TAU/32)*ring*4
                if not valid(goal,radius):continue
                if route_closed and (goal.x<GATE.x)!=(to.x<GATE.x):continue
                candidates.append(goal)
            candidates.sort_custom(func(a,b):return from.distance_squared_to(a)<from.distance_squared_to(b))
            for goal in candidates:
                var route:Vector2=_direction_to_valid(from,goal,radius)
                if not route.is_zero_approx():return route
        return Vector2.ZERO
    return _direction_to_valid(from,to,radius)
func _direction_to_valid(from:Vector2,to:Vector2,radius:float)->Vector2:
    if clear_line(from,to,radius): return from.direction_to(to)
    var graph := AStar2D.new()
    graph.add_point(0,from);graph.add_point(1,to)
    var index := 2
    if route_enabled and not route_closed:
        for point in [GATE-Vector2(70,0),GATE,GATE+Vector2(70,0)]:
            if valid(point,radius):graph.add_point(index,point);index+=1
    for stump in STUMPS:
        for i in range(8):
            var point: Vector2 = stump+Vector2.from_angle(i*TAU/8)*(STUMP_RADIUS+radius+17)
            if valid(point,radius): graph.add_point(index,point);index+=1
    for a in range(index):
        for b in range(a+1,index):
            if clear_line(graph.get_point_position(a),graph.get_point_position(b),radius): graph.connect_points(a,b)
    var path := graph.get_point_path(0,1)
    return from.direction_to(path[1]) if path.size()>1 else Vector2.ZERO
