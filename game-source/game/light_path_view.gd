extends Node2D
const Light = preload("res://game/light_state.gd")
const Map = preload("res://game/light_layout.gd")
const TERRAIN = preload("res://assets/visual-m15/terrain-atlas.png")
var bounds := Rect2()
var kind := "cat"
func configure(points: Array, width: float, name_of_route: String) -> void:
    kind = name_of_route
    bounds = Rect2(points[0],Vector2.ZERO)
    for point in points: bounds = bounds.expand(point)
    bounds = bounds.grow(width)
    var mat := ShaderMaterial.new()
    mat.shader = preload("res://assets/visual-m15/light_path.gdshader")
    mat.set_shader_parameter("points",PackedVector2Array(points))
    mat.set_shader_parameter("banks",[Vector4(Map.NEAR.position.x,Map.NEAR.position.y,Map.NEAR.size.x,Map.NEAR.size.y),Vector4(Map.MID.position.x,Map.MID.position.y,Map.MID.size.x,Map.MID.size.y),Vector4(Map.FAR.position.x,Map.FAR.position.y,Map.FAR.size.x,Map.FAR.size.y)])
    var islands: Array[Vector4] = []
    for island in [Map.ISLAND_ONE.grow(-5),Map.ISLAND_SAFE.grow(-5)]:
        islands.append(Vector4(island.position.x,island.position.y,island.size.x,island.size.y))
    mat.set_shader_parameter("islands",islands)
    mat.set_shader_parameter("half_width",width)
    mat.set_shader_parameter("support_radius",Light.SUPPORT_RADIUS)
    mat.set_shader_parameter("memory_radius",Light.MEMORY_RADIUS)
    mat.set_shader_parameter("terrain",TERRAIN)
    mat.set_shader_parameter("route_color",Color("c6ae76") if kind == "fast" else Color("8db5ac"))
    material = mat
func update_state(state) -> void:
    visible = (not state.front_fixed and (kind == "cat" or state.phase != "cat")) if kind in ["cat","girl"] else not state.permanent
    var chosen: bool = state.phase == kind or (state.phase == "route" and state.route == kind)
    if chosen: material.set_shader_parameter("half_width",state.path_width())
    material.set_shader_parameter("lit",chosen and state._source_ready())
    material.set_shader_parameter("beam",state.beam)
    var centers: PackedVector2Array = state.charge_points.duplicate()
    var count := centers.size()
    centers.resize(32)
    material.set_shader_parameter("charge_centers",centers)
    var strengths: PackedFloat32Array = state.charge_strengths()
    if not chosen: strengths.fill(0)
    material.set_shader_parameter("charge_strength",strengths)
    material.set_shader_parameter("charge_count",count if chosen and state._source_ready() else 0)
func _draw() -> void:
    draw_rect(bounds,Color.WHITE)
