extends RefCounted
const STUMPS := [Vector2(560,320),Vector2(760,555)]
const STUMP_RADIUS := 34.0
const ACTOR_RADIUS := 18.0
const ENEMY_RADIUS := 26.0
const FIELD := Rect2(-120,170,1520,650)
# First time of contact on a segment, INF if there is no contact.
static func contact(from: Vector2, to: Vector2, center: Vector2, radius: float) -> float:
    var offset := from-center
    var delta := to-from
    if offset.length_squared() <= radius*radius: return 0.0
    var a := delta.length_squared()
    if a < 0.000001: return INF
    var b := 2.0*offset.dot(delta)
    var c := offset.length_squared()-radius*radius
    var discriminant := b*b-4*a*c
    if discriminant < 0: return INF
    var t := (-b-sqrt(discriminant))/(2*a)
    return t if t >= 0 and t <= 1 else INF
static func valid(point: Vector2,radius: float) -> bool:
    if not FIELD.has_point(point): return false
    for stump in STUMPS:
        if point.distance_to(stump) < STUMP_RADIUS+radius: return false
    return true
static func move(from: Vector2, offset: Vector2,radius: float) -> Vector2:
    var point := from
    var count := maxi(1,ceili(offset.length()/5.0))
    for i in range(count):
        var delta := offset/float(count)
        for axis in [Vector2(delta.x,0),Vector2(0,delta.y)]:
            var target: Vector2 = (point+axis).clamp(FIELD.position,FIELD.end-Vector2(0.001,0.001))
            if valid(target,radius): point = target
    return point
static func clear_line(from: Vector2,to: Vector2,radius: float) -> bool:
    for stump in STUMPS:
        if contact(from,to,stump,STUMP_RADIUS+radius) != INF: return false
    return true
static func direction(from: Vector2,to: Vector2,radius: float) -> Vector2:
    if clear_line(from,to,radius): return from.direction_to(to)
    # Tiny visibility graph only when obstructed; keeps followers and approach
    # movement from sticking against the two stumps. Player movement stays direct.
    var graph := AStar2D.new()
    graph.add_point(0,from)
    graph.add_point(1,to)
    var id := 2
    for stump in STUMPS:
        for i in range(8):
            var point: Vector2 = stump+Vector2.from_angle(i*TAU/8)*(STUMP_RADIUS+radius+16)
            if valid(point,radius):
                graph.add_point(id,point)
                id += 1
    for a in range(id):
        for b in range(a+1,id):
            if clear_line(graph.get_point_position(a),graph.get_point_position(b),radius): graph.connect_points(a,b)
    var path := graph.get_point_path(0,1)
    return from.direction_to(path[1]) if path.size()>1 else Vector2.ZERO
