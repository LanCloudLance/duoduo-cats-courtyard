extends RefCounted
# All coordinates are world-space feet positions; rendering shares this geometry.
const FIELD := Rect2(80,250,1120,390)
const NEAR := Rect2(80,250,200,390)
const MID := Rect2(580,250,180,390)
const FAR := Rect2(1060,250,140,390)
const ISLAND_ONE := Rect2(385,330,50,50)
const ISLAND_SAFE := Rect2(875,295,60,50)
const LAMP_NEAR := Vector2(140,550)
const LAMP_SAFE := Vector2(610,585)
const LAMP_FAST := Vector2(710,585)
const GUIDE_NEAR := Vector2(210,350)
const RELAY := Vector2(645,340)
const FRONT_LOCK := Vector2(625,505)
const GUIDE_MID := Vector2(710,420)
const FAR_WINCH := Vector2(705,500)
const FAR_LOCK := Vector2(1115,380)
const EXIT := Vector2(1140,525)
const CAT_PATH := [Vector2(260,440),Vector2(330,440),Vector2(410,355),Vector2(475,430),Vector2(600,430)]
const GIRL_PATH := [Vector2(260,520),Vector2(340,540),Vector2(440,540),Vector2(540,480),Vector2(605,480)]
const SAFE_PATH := [Vector2(740,380),Vector2(820,320),Vector2(905,320),Vector2(985,355),Vector2(1080,380)]
const FAST_PATH := [Vector2(740,530),Vector2(825,550),Vector2(900,475),Vector2(990,510),Vector2(1080,480)]
static func distance_to_path(point: Vector2, path: Array) -> float:
    var distance := INF
    for i in range(path.size()-1):
        distance = minf(distance,point.distance_to(Geometry2D.get_closest_point_to_segment(point,path[i],path[i+1])))
    return distance
static func samples(path: Array, spacing := 19.0) -> PackedVector2Array:
    var result := PackedVector2Array()
    for i in range(path.size()-1):
        var count := maxi(1,ceili(path[i].distance_to(path[i+1])/spacing))
        for j in range(count): result.append(path[i].lerp(path[i+1],float(j)/count))
    result.append(path[-1])
    return result
static func bank(point: Vector2) -> int:
    if NEAR.has_point(point): return 0
    if MID.has_point(point): return 1
    if FAR.has_point(point): return 2
    return -1
