extends CanvasLayer
## Critical dialogue uses explicit confirmation, at the player's reading speed.
var active:=false
var card:=Panel.new()
var body:=Label.new()
var footer:=Label.new()
var font:Font
func _init(value:Font)->void:font=value
func _ready()->void:
    layer=38
    card.position=Vector2(214,564);card.size=Vector2(852,190)
    var style:=StyleBoxFlat.new();style.bg_color=Color("f5ead0");style.border_color=Color("a78b64");style.set_border_width_all(2);style.set_corner_radius_all(14)
    card.add_theme_stylebox_override("panel",style);add_child(card)
    body.position=Vector2(26,20);body.size=Vector2(800,112);body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.add_theme_font_override("font",font);body.add_theme_font_size_override("font_size",23);body.add_theme_color_override("font_color",Color("344d3c"));card.add_child(body)
    footer.position=Vector2(26,144);footer.size=Vector2(800,26);footer.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;footer.add_theme_font_override("font",font);footer.add_theme_font_size_override("font_size",17);footer.add_theme_color_override("font_color",Color("6b705b"));card.add_child(footer)
    visible=false
func present(state,keyboard:bool)->void:
    active=state.has_method("dialogue_active") and state.dialogue_active()
    visible=active
    if not active:return
    body.text=state.dialogue[state.dialogue_index]
    footer.text=("E / 空格 · 继续" if keyboard else "下面键 · 继续")+"    %d / %d"%[state.dialogue_index+1,state.dialogue.size()]
