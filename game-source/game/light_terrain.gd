extends Node2D
const Map = preload("res://game/light_layout.gd")
const TERRAIN = preload("res://assets/visual-m15/terrain-atlas.png")
func _draw() -> void:
    draw_rect(Rect2(-800,-800,3000,2500),Color("1c3433"))
    draw_texture_rect_region(TERRAIN,Rect2(0,145,1280,545),Rect2(627,627,627,627),Color("8d9e82"))
    draw_rect(Map.FIELD.grow(10),Color("354c41"))
    draw_texture_rect_region(TERRAIN,Map.FIELD,Rect2(0,0,627,627),Color("b4c9bd"))
    for land in [Map.NEAR,Map.MID,Map.FAR]:
        draw_texture_rect_region(TERRAIN,Rect2(land.position+Vector2(0,17),land.size),Rect2(0,627,627,627),Color("819081"))
        draw_texture_rect_region(TERRAIN,land,Rect2(627,0,627,627),Color("c4c4a0"))
        draw_rect(land,Color("b8b78d"),false,2)
        for y in range(275,640,54): draw_line(Vector2(land.position.x+6,y),Vector2(land.end.x-6,y-2),Color(0.34,0.37,0.27,0.16),2,true)
    for island in [Map.ISLAND_ONE,Map.ISLAND_SAFE]:
        var top: Rect2 = island.grow(-5)
        draw_texture_rect_region(TERRAIN,Rect2(top.position+Vector2(0,10),top.size),Rect2(0,627,627,627))
        draw_texture_rect_region(TERRAIN,top,Rect2(627,0,627,627))
        draw_rect(top,Color("e1d8a0"),false,2)
        draw_arc(top.get_center(),10,0,TAU,28,Color("9d9c69"),2,true)
