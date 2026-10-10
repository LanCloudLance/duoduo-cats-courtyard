extends CanvasLayer
signal close_requested
signal hint_requested
var active:=false
var panel:=PanelContainer.new()
var lines:=Label.new()
var scroll:=ScrollContainer.new()
var scroll_axis:=0.0
func _init(font:Font)->void:
    layer=45
    var shade:=ColorRect.new();shade.color=Color(0.05,0.10,0.08,.86);shade.size=Vector2(1280,800);add_child(shade)
    panel.position=Vector2(150,85);panel.size=Vector2(980,630);add_child(panel)
    var style:=StyleBoxFlat.new();style.bg_color=Color("f5ead0");style.set_corner_radius_all(16);style.content_margin_left=28;style.content_margin_right=28;style.content_margin_top=24;style.content_margin_bottom=24;panel.add_theme_stylebox_override("panel",style)
    var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",18);panel.add_child(stack)
    var heading:=Label.new();heading.text="旅途记事 · 已发生的对话与观察";heading.add_theme_font_override("font",font);heading.add_theme_font_size_override("font_size",25);heading.add_theme_color_override("font_color",Color("344d3c"));stack.add_child(heading)
    scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;stack.add_child(scroll)
    lines.custom_minimum_size.x=860;lines.size_flags_horizontal=Control.SIZE_EXPAND_FILL;lines.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;lines.add_theme_font_override("font",font);lines.add_theme_font_size_override("font_size",20);lines.add_theme_color_override("font_color",Color("344d3c"));scroll.add_child(lines)
    var help:=Label.new();help.text="上下 / 摇杆翻阅 · 翻页键 / 肩键快速翻页";help.add_theme_font_override("font",font);help.add_theme_font_size_override("font_size",16);help.add_theme_color_override("font_color",Color("344d3c"));stack.add_child(help)
    var hint:=Button.new();hint.name="ThinkHint";hint.text="想一想 · V / 手柄上面键";hint.add_theme_font_override("font",font);hint.add_theme_font_size_override("font_size",20);hint.pressed.connect(func():hint_requested.emit());stack.add_child(hint)
    var close:=Button.new();close.text="返回 · H / Esc / 手柄返回";close.add_theme_font_override("font",font);close.add_theme_font_size_override("font_size",20);close.pressed.connect(func():close_requested.emit());stack.add_child(close)
    visible=false
func open(history:Array,fallback:String)->void:
    var text_lines:PackedStringArray=[]
    for entry in history:text_lines.append(String(entry))
    if text_lines.is_empty():text_lines.append(fallback)
    lines.text="\n\n".join(text_lines);active=true;visible=true;scroll.set_deferred("scroll_vertical",999999)
func close()->void:active=false;visible=false;scroll_axis=0
func handle_input(event:InputEvent)->void:
    if event is InputEventKey and event.pressed and not event.echo:
        var code:int=event.physical_keycode if event.physical_keycode else event.keycode
        if code==KEY_V:hint_requested.emit()
        elif code in [KEY_UP,KEY_W,KEY_PAGEUP]:scroll.scroll_vertical-=360 if code==KEY_PAGEUP else 72
        elif code in [KEY_DOWN,KEY_S,KEY_PAGEDOWN]:scroll.scroll_vertical+=360 if code==KEY_PAGEDOWN else 72
    elif event is InputEventJoypadButton and event.pressed:
        if event.button_index==JOY_BUTTON_Y:hint_requested.emit()
        elif event.button_index in [JOY_BUTTON_DPAD_UP,JOY_BUTTON_LEFT_SHOULDER]:scroll.scroll_vertical-=360 if event.button_index==JOY_BUTTON_LEFT_SHOULDER else 72
        elif event.button_index in [JOY_BUTTON_DPAD_DOWN,JOY_BUTTON_RIGHT_SHOULDER]:scroll.scroll_vertical+=360 if event.button_index==JOY_BUTTON_RIGHT_SHOULDER else 72
    elif event is InputEventJoypadMotion and event.axis==JOY_AXIS_LEFT_Y:scroll_axis=event.axis_value if absf(event.axis_value)>.2 else 0
func _process(dt:float)->void:
    if not active or not get_parent().session.focused:scroll_axis=0;return
    scroll.scroll_vertical+=roundi(scroll_axis*360*dt)
