extends Control
## The earned paper can be reread later. It shows connections, never current solutions.
var ink_font:Font
func _init(font:Font)->void:
    ink_font=font;custom_minimum_size=Vector2(860,285);mouse_filter=Control.MOUSE_FILTER_IGNORE
func caption(point:Vector2,value:String,font_size:=18)->void:
    draw_string(ink_font,point,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color("5d513a"))
func route(points:PackedVector2Array)->void:
    draw_polyline(points,Color("817457"),3.0,true)
    var tip:Vector2=points[-1];var direction:Vector2=(tip-points[-2]).normalized()
    draw_polyline(PackedVector2Array([tip-direction.rotated(0.45)*13,tip,tip-direction.rotated(-0.45)*13]),Color("817457"),3.0,true)
func _draw()->void:
    draw_style_box(paper(),Rect2(0,0,850,280))
    caption(Vector2(22,34),"钟楼纸背的旧线路图",23)
    caption(Vector2(22,62),"团团找到的折页。支路的小扣能让小灯与回收口分开。",17)
    var source:=Vector2(85,125);var split:=Vector2(275,125);var machine:=Vector2(705,125)
    route(PackedVector2Array([source+Vector2(24,0),machine-Vector2(47,0)]))
    route(PackedVector2Array([split,Vector2(275,207),Vector2(400,207)]))
    route(PackedVector2Array([Vector2(448,207),Vector2(610,207),Vector2(610,125),machine-Vector2(47,0)]))
    draw_circle(source,22,Color("d5bc72"));draw_arc(source,22,0,TAU,40,Color("817457"),2)
    draw_circle(split,5,Color("817457"))
    draw_style_box(node_style(),Rect2(machine-Vector2(47,29),Vector2(95,58)))
    draw_arc(Vector2(424,207),24,0,TAU,40,Color("817457"),3)
    draw_line(Vector2(411,207),Vector2(437,207),Color("aa9258"),7)
    draw_arc(Vector2(552,207),16,-PI*0.82,PI*0.82,24,Color("817457"),3)
    draw_line(Vector2(541,202),Vector2(565,202),Color("aa9258"),4)
    caption(Vector2(48,168),"试光入口")
    caption(Vector2(300,112),"主线")
    caption(machine-Vector2(37,-6),"回收主机",17)
    caption(Vector2(390,254),"小灯")
    caption(Vector2(514,254),"独立扣")
    caption(Vector2(280,187),"支路",17)
func paper()->StyleBoxFlat:
    var box:=StyleBoxFlat.new();box.bg_color=Color("eee0b7");box.border_color=Color("bbab80");box.set_border_width_all(2);box.set_corner_radius_all(9);return box
func node_style()->StyleBoxFlat:
    var box:=StyleBoxFlat.new();box.bg_color=Color("dcc99b");box.border_color=Color("817457");box.set_border_width_all(2);box.set_corner_radius_all(8);return box
