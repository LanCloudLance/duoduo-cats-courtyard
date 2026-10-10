extends Node2D
## Artwork follows the state; a separate bud always marks the real rear side.
const SHEET = preload("res://assets/visual-m14/enemy-atlas.png")
const KEY = preload("res://assets/visual-m13/chroma.gdshader")
const Pose = preload("res://game/enemy_pose.gd")
const REGIONS = [Rect2(0,180,410,430),Rect2(440,180,420,430),Rect2(868,200,386,410),Rect2(0,710,410,410),Rect2(420,710,430,410),Rect2(870,730,384,420)]
var body: Sprite2D
var bud: Sprite2D
var kind := ""
var state: Dictionary
var action_pose: Dictionary

static func prop(index: int, width: float) -> Sprite2D:
    var result := Sprite2D.new()
    var atlas := AtlasTexture.new()
    atlas.atlas = SHEET
    atlas.region = REGIONS[index]
    atlas.filter_clip = true
    result.texture = atlas
    var mat := ShaderMaterial.new()
    mat.shader = KEY
    result.material = mat
    result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    result.scale = Vector2.ONE*width/REGIONS[index].size.x
    result.offset.y = -REGIONS[index].size.y*0.35
    return result

func sync(enemy: Dictionary) -> void:
    state = enemy
    if kind != enemy.kind:
        kind = enemy.kind
        if body: body.queue_free()
        body = prop(0 if kind in ["thorn","sprout"] else 1 if kind in ["armored","elder"] else 2,132 if kind == "elder" else 65 if kind == "sprout" else 80 if kind == "weaver" else 94)
        add_child(body)
        if bud: bud.queue_free()
        bud = prop(4,37)
        bud.offset = Vector2.ZERO
        add_child(bud)
    position = enemy.pos
    z_index = int(position.y)
    body.flip_h = enemy.direction.x < 0
    body.modulate = Color(1.45,1.35,1.10) if enemy.flash > 0 else (Color("dcc6f7") if kind == "weaver" else Color("bce7a5") if kind == "sprout" else Color.WHITE)
    action_pose = Pose.sample(enemy)
    body.position = action_pose.offset
    body.rotation = action_pose.lean
    var age: float = enemy.get("impact_age",1.0)
    var impact: Vector2 = enemy.get("impact_direction",Vector2.ZERO)
    var power: float = enemy.get("impact_power",0.0)
    var recoil: float = clampf(1-(age-0.04)/0.16,0,1)
    body.position.x += impact.x*power*recoil
    body.position.y += impact.y*power*recoil
    body.rotation += -impact.x*recoil*0.14
    var factor: float = (132.0 if kind == "elder" else 65.0 if kind == "sprout" else 80.0 if kind == "weaver" else 94.0)/REGIONS[0 if kind in ["thorn","sprout"] else 1 if kind in ["armored","elder"] else 2].size.x
    body.scale = action_pose.stretch*Vector2(factor*(1.0+recoil*0.11),factor*(1.0-recoil*0.10))
    body.material.set_shader_parameter("hit_flash",0.84 if enemy.flash > 0.075 else 0.0)
    bud.visible = (kind in ["armored","elder"] and enemy.mode == "exposed") or kind == "weaver"
    bud.position = body.position+Vector2(0,-65) if kind == "weaver" else -enemy.direction*29
    modulate.a = 1.0
    if enemy.has("death_age"):
        var death: float = enemy.death_age/0.38
        body.rotation = lerpf(body.rotation,0.65*signf(impact.x if impact.x != 0 else 1.0),smoothstep(0.08,0.75,death))
        body.position.y += death*17
        body.scale.y *= 1-death*0.32
        modulate.a = 1.0-smoothstep(0.48,1.0,death)
        bud.visible = false
    queue_redraw()

func _draw() -> void:
    if state.is_empty(): return
    draw_set_transform(Vector2(0,4),0,Vector2(1,0.4))
    draw_circle(Vector2.ZERO,32,Color(0.13,0.20,0.10,0.23))
    draw_set_transform(Vector2.ZERO)
    if not state.has("death_age"):
        _limbs()
    if kind == "elder":
        var canopy: Vector2 = body.position+Vector2(0,-80)*action_pose.stretch
        draw_line(canopy+Vector2(12,0),canopy+Vector2(25,-20),Color("765332"),5,true)
        draw_circle(canopy+Vector2(25,-6),11,Color("ffe59b"))
        draw_arc(canopy+Vector2(25,-6),15,0,TAU,24,Color(1,0.83,0.42,0.4),4,true)
    if state.get("control_time",0.0) > 0:
        draw_arc(Vector2(0,0),38,0,TAU,32,Color("e5cca0"),3,true)
    if kind == "armored":
        var angle: float = state.direction.angle()
        draw_arc(Vector2.ZERO,32,angle-1.4,angle+1.4,28,Color("84613d"),9,true)
        draw_arc(Vector2.ZERO,32,angle-1.4,angle+1.4,28,Color("fff2bf") if state.bounce > 0 else Color("c59b68"),4,true)
        if state.mode != "exposed":
            draw_circle(-state.direction*29,9,Color("6e6442"))
    if state.flash > 0:
        for i in range(5):
            var direction := Vector2.from_angle(i*TAU/5)
            draw_line(Vector2(0,-25)+direction*39,Vector2(0,-25)+direction*49,Color("fff0b7"),3,true)

func _limbs() -> void:
    var direction: Vector2 = state.direction.normalized()
    var side := direction.orthogonal()
    var origin := body.position+Vector2(0,-26 if kind != "elder" else -44)
    var width := 23.0 if kind == "sprout" else 42.0 if kind == "elder" else 32.0
    var color := Color("60824f") if kind in ["sprout","thorn"] else Color("77603f") if kind in ["elder","armored","roller"] else Color("89639e")
    for sign_value in [-1.0,1.0]:
        var shoulder: Vector2 = origin+side*width*0.68*sign_value
        var tip: Vector2 = origin+side*width*sign_value+direction*(17+action_pose.reach)+Vector2(0,action_pose.lift)
        var elbow := shoulder.lerp(tip,0.5)-direction*7
        var vine := PackedVector2Array()
        for i in range(9):
            var t := float(i)/8
            vine.append(shoulder.lerp(elbow,t).lerp(elbow.lerp(tip,t),t))
        draw_polyline(vine,color.darkened(0.30),7,true)
        draw_polyline(vine,color,4,true)
        var leaf := PackedVector2Array([tip-direction*3,tip+side*5,tip+direction*11,tip-side*5])
        draw_colored_polygon(leaf,Color("b8bb72") if kind != "weaver" else Color("c1a4d1"))
        draw_line(tip-direction*2,tip+direction*8,color.darkened(0.10),1,true)
