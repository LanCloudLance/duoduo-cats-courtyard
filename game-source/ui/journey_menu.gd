extends Control
## The shipped menu contains journeys and preferences, never test entry points.
signal continue_requested
signal resume_requested(single:bool)
signal new_requested(single:bool)
signal settings_changed
signal controllers_requested
signal quit_requested
signal chapter_requested(chapter:int,single:bool)
var buttons:Array[Button]=[]
var settings
var settings_panel:=Panel.new()
var continue_button:Button
var solo_button:Button
var dual_button:Button
var subtitle:Label
var status:Label
var help:Label
var music_button:Button
var effects_button:Button
var shake_button:Button
var rumble_button:Button
var has_active:=false
var chapters_panel:=Panel.new()
var chapter_buttons:Array[Button]=[]
var visit_mode:=true
var visit_mode_button:Button
var unlocked:={"solo":[],"dual":[]}
func _init(value)->void:settings=value
func _ready()->void:
    size=Vector2(1280,800);mouse_filter=Control.MOUSE_FILTER_STOP
    var backdrop:=ColorRect.new();backdrop.color=Color("f6eedc");backdrop.size=size;backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(backdrop)
    var strip:=ColorRect.new();strip.color=Color("28463b");strip.position=Vector2(0,694);strip.size=Vector2(1280,106);strip.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(strip)
    _label("朵朵与猫猫",Rect2(82,72,700,74),44,Color("28463b"))
    subtitle=_label("一起把回家的路点亮",Rect2(85,145,660,40),24,Color("63776b"))
    var team:=TextureRect.new();team.texture=preload("res://assets/team.png");team.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;team.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;team.position=Vector2(554,185);team.size=Vector2(674,431);team.modulate=Color("f6eedc");team.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(team)
    continue_button=_button("回到冒险",Rect2(86,224,400,56),func():continue_requested.emit())
    solo_button=_button("继续单人旅程",Rect2(86,292,400,52),func():resume_requested.emit(true))
    dual_button=_button("继续双人旅程",Rect2(86,356,400,52),func():resume_requested.emit(false))
    _button("新旅程 · 一个人",Rect2(86,420,400,52),func():new_requested.emit(true))
    _button("新旅程 · 两个人",Rect2(86,484,400,52),func():new_requested.emit(false))
    _button("设置与操作",Rect2(86,548,156,48),func():settings_panel.visible=true;_refresh_settings();music_button.grab_focus())
    _button("旅程回访",Rect2(254,548,126,48),func():chapters_panel.visible=true;_refresh_chapters();visit_mode_button.grab_focus())
    _button("返回" if OS.has_feature("web") else "退出",Rect2(392,548,94,48),func():quit_requested.emit())
    help=_label("单人手动切换伙伴 · 双人同屏合作",Rect2(86,637,1120,35),18,Color("63776b"))
    status=_label("选择一段旅程出发",Rect2(86,719,1100,30),20,Color("f6eedc"))
    _label("WASD / 方向键选择 · Enter 确认 · 手柄十字键 / 下面键确认",Rect2(86,758,1110,26),15,Color("c8d4c6"))
    _build_settings();_build_chapters()
    update_state(false,false,false,"",false)
func _label(value:String,rect:Rect2,font_size:int,tint:Color,parent:Node=self)->Label:
    var label:=Label.new();label.text=value;label.position=rect.position;label.size=rect.size;label.add_theme_font_size_override("font_size",font_size);label.add_theme_color_override("font_color",tint);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(label);return label
func _button(value:String,rect:Rect2,action:Callable,parent:Node=self)->Button:
    var b:=Button.new();b.text=value;b.position=rect.position;b.size=rect.size;b.add_theme_font_size_override("font_size",21)
    var style:=StyleBoxFlat.new();style.bg_color=Color("365a47");style.set_corner_radius_all(12);style.content_margin_left=18;style.content_margin_right=18;b.add_theme_stylebox_override("normal",style)
    var focus:=style.duplicate();focus.bg_color=Color("51735d");focus.border_color=Color("d5b56c");focus.set_border_width_all(3);b.add_theme_stylebox_override("focus",focus);b.add_theme_stylebox_override("hover",focus);b.add_theme_stylebox_override("pressed",focus)
    b.pressed.connect(action);parent.add_child(b);buttons.append(b);return b
func _build_settings()->void:
    settings_panel.position=Vector2(220,80);settings_panel.size=Vector2(840,640);settings_panel.z_index=5
    var style:=StyleBoxFlat.new();style.bg_color=Color("f0e5cd");style.border_color=Color("365a47");style.set_border_width_all(3);style.set_corner_radius_all(18);settings_panel.add_theme_stylebox_override("panel",style);add_child(settings_panel)
    _label("设置与操作",Rect2(32,23,700,45),28,Color("28463b"),settings_panel)
    music_button=_button("",Rect2(32,88,370,45),func():settings.music_level=(settings.music_level+1)%3;_change(),settings_panel)
    effects_button=_button("",Rect2(420,88,370,45),func():settings.effects=not settings.effects;_change(),settings_panel)
    shake_button=_button("",Rect2(32,145,370,45),func():settings.camera_shake=not settings.camera_shake;_change(),settings_panel)
    rumble_button=_button("",Rect2(420,145,370,45),func():settings.rumble=not settings.rumble;_change(),settings_panel)
    var instructions:=_label("探索：移动 · 下面键互动 · 上面键换角色 / 换猫\n工具与保持：右肩；举盾 / 定光：左肩。\n\n战斗：左面键普攻 · 右面键闪避 · 左肩角色技\n上面键换人；双人只有猫玩家换猫。\n朵朵接招、团团打断、圆圆拍开近敌，各自都能独立应对。\n\n键盘 P1：WASD / E · 战斗 F / Q / G\n键盘 P2：方向键 / 空格 · 战斗 J / K / U\nTab 换角色；G 想一想（第五章举盾）\nH 旅途记事，记事中 V 提示；Esc 暂停。",Rect2(35,214,760,326),18,Color("28463b"),settings_panel);instructions.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    _button("使用手柄",Rect2(32,564,370,45),func():controllers_requested.emit(),settings_panel)
    _button("返回菜单",Rect2(420,564,370,45),close_settings,settings_panel)
    settings_panel.visible=false;_refresh_settings()
func _change()->void:
    settings.save();_refresh_settings();settings_changed.emit()
func _refresh_settings()->void:
    music_button.text="音乐："+["轻声","标准","关闭"][settings.music_level]
    effects_button.text="音效："+("开" if settings.effects else "关")
    shake_button.text="镜头震动："+("开" if settings.camera_shake else "关")
    rumble_button.text="手柄震动："+("开" if settings.rumble else "关")
func close_settings()->void:
    settings_panel.visible=false;chapters_panel.visible=false
    for b in buttons:
        if b.visible and b.get_parent()==self and not b.disabled:b.grab_focus();break
func available_buttons()->Array[Button]:
    var result:Array[Button]=[]
    var parent:Node=chapters_panel if chapters_panel.visible else settings_panel if settings_panel.visible else self
    for b in buttons:
        if b.is_visible_in_tree() and not b.disabled and b.get_parent()==parent:result.append(b)
    return result
func _build_chapters()->void:
    chapters_panel.position=Vector2(220,80);chapters_panel.size=Vector2(840,640);chapters_panel.z_index=6;chapters_panel.add_theme_stylebox_override("panel",settings_panel.get_theme_stylebox("panel"));add_child(chapters_panel)
    _label("旅程回访 · 已走过的路",Rect2(32,23,760,45),28,Color("28463b"),chapters_panel)
    visit_mode_button=_button("",Rect2(32,80,776,43),func():visit_mode=not visit_mode;_refresh_chapters(),chapters_panel)
    var titles:=["序章 · 家中的下午","第一章 · 点亮第一盏灯","第二章 · 团团，去那边等我","第三章 · 这次一起走","第四章 · 灯光躲起来了","第五章 · 把回家的路点亮"]
    for chapter in range(6):
        chapter_buttons.append(_button(titles[chapter],Rect2(32,140+chapter*59,776,45),func():chapter_requested.emit(chapter,visit_mode);close_settings(),chapters_panel))
    _label("回访从本章开始，不覆盖当前旅程的继续位置。",Rect2(35,506,750,32),17,Color("63776b"),chapters_panel)
    _button("返回菜单",Rect2(32,554,776,45),close_settings,chapters_panel)
    chapters_panel.visible=false;_refresh_chapters()
func update_chapters(value:Dictionary)->void:
    unlocked=value.duplicate(true);_refresh_chapters()
func _refresh_chapters()->void:
    if visit_mode_button==null:return
    visit_mode_button.text="人数："+("单人" if visit_mode else "同屏双人")+" · 选择切换"
    var chapters:Array=unlocked.get("solo" if visit_mode else "dual",[])
    for i in range(chapter_buttons.size()):chapter_buttons[i].disabled=i not in chapters
func update_state(in_progress:bool,solo_saved:bool,dual_saved:bool,reason:String,keyboard:bool)->void:
    has_active=in_progress;continue_button.visible=in_progress
    solo_button.disabled=not solo_saved;dual_button.disabled=not dual_saved
    solo_button.text="继续单人旅程" if solo_saved else "单人旅程 · 暂无记录"
    dual_button.text="继续双人旅程" if dual_saved else "双人旅程 · 暂无记录"
    subtitle.text="歇一歇，再继续" if in_progress else "一起把回家的路点亮"
    status.text=reason if in_progress and not reason.is_empty() else "选择一段旅程出发"
    if not settings.last_error.is_empty():status.text=settings.last_error
    help.text="单人手动切换伙伴 · 双人同屏合作"+(" · 键盘已接入" if keyboard else " · 手柄菜单键加入")
