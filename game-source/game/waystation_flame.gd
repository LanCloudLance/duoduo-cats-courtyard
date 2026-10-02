extends Node2D
## Separate draw layer lets the flame show inside the illustrated glass, not behind it.
var state
func _draw()->void:
    if not state or not state.core_installed:return
    var p:=Vector2(16,-96)
    var strength:float=1.0 if state.lit else state.flame
    var flicker:float=1+sin(state.clock*26)*(0.04 if state.lit else 0.12)
    var height:float=28*strength*flicker
    var sway:float=0 if state.hood==1 or state.lit else sin(state.clock*18)*9+7
    draw_circle(p,17*strength,Color(1,0.76,0.3,0.28))
    draw_colored_polygon(PackedVector2Array([p+Vector2(-5,4),p+Vector2(sway,-height),p+Vector2(5,4)]),Color("ecc06b"))
    draw_circle(p,2.5,Color("fff1bc"))
