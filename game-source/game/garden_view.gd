extends Node2D
const ART = preload("res://assets/visual-m13/courtyard-painted.png")
const Party = preload("res://game/party_state.gd")
var party
var font: Font
var clock := 0.0
const Prop = preload("res://game/painted_prop.gd")

func _ready() -> void:
    add_child(Prop.make(Rect2(180,38,279,586),Party.OBSTACLES[0]))
    add_child(Prop.make(Rect2(62,814,564,306),Party.OBSTACLES[1]))
    for p in [Vector2(250,585),Vector2(1700,575)]:
        add_child(Prop.make(Rect2(790,660,264,520),Rect2(p-Vector2(26,114),Vector2(60,118))))

func advance(delta: float) -> void:
    clock += delta
    queue_redraw()

func oval(point: Vector2, radius: Vector2, color: Color) -> void:
    draw_set_transform(point, 0, radius)
    draw_circle(Vector2.ZERO, 1, color)
    draw_set_transform(Vector2.ZERO)

func _draw() -> void:
    draw_rect(Rect2(-3000,-3000,8000,8000),Color("172c24"))
    draw_set_transform(Vector2(3840,0),0,Vector2(-1,1))
    draw_texture_rect_region(ART,Rect2(1416,0,504,1200),Rect2(1034,0,552,992))
    draw_set_transform(Vector2.ZERO,0,Vector2(-1,1))
    draw_texture_rect_region(ART,Rect2(0,0,700,1200),Rect2(0,0,511,992))
    draw_set_transform(Vector2.ZERO)
    draw_texture_rect_region(ART,Rect2(-700,-600,3320,600),Rect2(0,0,1586,90))
    draw_texture_rect_region(ART,Rect2(-700,1200,3320,600),Rect2(0,890,1586,102))
    # Three slices align the painted riverbanks to the authoritative collision map.
    draw_texture_rect_region(ART,Rect2(0,0,1024,1200),Rect2(0,0,747,992))
    draw_texture_rect_region(ART,Rect2(1024,0,392,1200),Rect2(747,0,287,992))
    draw_texture_rect_region(ART,Rect2(1416,0,504,1200),Rect2(1034,0,552,992))
    for rect in Party.OBSTACLES:
        draw_rect(Rect2(rect.position+Vector2(5,8),rect.size),Color(0.04,0.08,0.03,0.22))
    for pad in party.pads:
        oval(pad+Vector2(2,5),Vector2(39,22),Color(0.10,0.17,0.10,0.18))
        oval(pad,Vector2(38,22),Color("d5c99e"))
        oval(pad,Vector2(32,18),Color("b6ad80"))
        oval(pad+Vector2(0,3),Vector2(9,6),Color("f5e7bb"))
        for offset in [Vector2(-13,-4),Vector2(-5,-9),Vector2(5,-9),Vector2(13,-4)]:
            draw_circle(pad+offset,3.4,Color("f5e7bb"))
    # Sparse moving pollen and ripples are noninteractive and pause with the game.
    for i in range(15):
        var p := Vector2(160+fmod(i*127.0+clock*7,1630),230+fmod(i*97.0+sin(clock*0.4+i)*20,750))
        if p.x < 1000 or p.x > 1440:
            draw_circle(p,1.5+sin(clock+i)*0.5,Color(1,0.93,0.66,0.35))

func _lantern() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color("ffe7a4")
    style.border_color = Color("8c6b41")
    style.set_border_width_all(3)
    style.set_corner_radius_all(3)
    return style
