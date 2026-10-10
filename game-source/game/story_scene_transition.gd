extends CanvasLayer
var shade:=ColorRect.new()
var label:=Label.new()
var previous:=""
var opacity:=0.0
var blocking:=false
func _init(font:Font)->void:
    label.add_theme_font_override("font",font)
func _ready()->void:
    layer=36;shade.size=Vector2(1280,800);shade.color=Color("14241e");shade.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(shade)
    label.position=Vector2(290,370);label.size=Vector2(700,45);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.add_theme_font_size_override("font_size",27);label.add_theme_color_override("font_color",Color("f8e8bc"));add_child(label);visible=false
func present(room:String,approaching:bool,delta:float)->void:
    if previous.is_empty():previous=room
    elif room!=previous:previous=room;opacity=1.0
    elif approaching:opacity=move_toward(opacity,1.0,delta*3.8)
    else:opacity=move_toward(opacity,0.0,delta*2.6)
    label.text={"4-market":"回到集市","4-interior":"阿灯的小屋","4-exterior":"灯树外廊","5-home":"回到同一个下午","5-farewell":"修好的路，亮着灯"}.get(room,"")
    shade.modulate.a=opacity;label.modulate.a=opacity;visible=opacity>0.01;blocking=visible and not approaching
func clear()->void:previous="";opacity=0.0;visible=false;blocking=false
