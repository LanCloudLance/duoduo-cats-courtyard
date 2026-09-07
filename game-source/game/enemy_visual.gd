extends Node2D
## Artwork follows the state; a separate bud always marks the real rear side.
const SHEET = preload("res://assets/visual-m14/enemy-atlas.png")
const KEY = preload("res://assets/visual-m13/chroma.gdshader")
const REGIONS = [Rect2(0,180,410,430),Rect2(440,180,420,430),Rect2(868,200,386,410),Rect2(0,710,410,410),Rect2(420,710,430,410),Rect2(870,730,384,420)]
var body: Sprite2D
var bud: Sprite2D
var kind := ""
var state: Dictionary

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
        body = prop(0 if kind == "thorn" else 1 if kind == "armored" else 2,94)
        add_child(body)
        if bud: bud.queue_free()
        bud = prop(4,37)
        bud.offset = Vector2.ZERO
        add_child(bud)
    position = enemy.pos
    z_index = int(position.y)
    body.flip_h = enemy.direction.x < 0
    body.modulate = Color(1.45,1.35,1.10) if enemy.flash > 0 else Color.WHITE
    body.position.y = -sin(clampf(enemy.timer,0,1)*PI)*3 if enemy.mode == "windup" else 0.0
    bud.visible = kind == "armored" and enemy.mode == "exposed"
    bud.position = -enemy.direction*29
    queue_redraw()

func _draw() -> void:
    if state.is_empty(): return
    draw_set_transform(Vector2(0,4),0,Vector2(1,0.4))
    draw_circle(Vector2.ZERO,32,Color(0.13,0.20,0.10,0.23))
    draw_set_transform(Vector2.ZERO)
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
