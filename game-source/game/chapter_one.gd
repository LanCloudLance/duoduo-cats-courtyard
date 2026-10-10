extends Node2D
const StoryLabels=preload("res://game/story_labels.gd")
var labels=StoryLabels.new()
signal next_chapter_requested
signal battle_requested
const Story = preload("res://game/chapter_one_state.gd")
const Actor = preload("res://game/actor_view.gd")
const Home = preload("res://game/home_sprite.gd")
const LAMP_ART = preload("res://assets/visual-m22/chime-props.png")
const PROPS = preload("res://assets/story-chapter-one/props.png")
const BACKDROP = preload("res://assets/story-chapter-one/waystation.png")
var state = Story.new()
var session
var active := false
var camera := Camera2D.new()
var hud := CanvasLayer.new()
var font: Font
var home_views: Array[Node2D] = []
var actors: Array[Node2D] = []
var lamp: Sprite2D
var flame_view: Node2D
var title: Label
var line: Label
var controls: Label
var complete_panel: Panel
var completed_text: Label
var recorded := false
var completion_attempted:=false
var checkpoint_signature:=""
var checkpoint_pending:=0.0
var save_status := ""
var record_prefix := "story-chapter-one"
var heard := -1
var audio := preload("res://game/garden_audio.gd").new()
var prop_views: Array[Sprite2D] = []

func _init(value) -> void:session = value
func _ready() -> void:
    font = get_parent().theme.default_font
    camera.position = Vector2(640,400);camera.enabled = false;add_child(camera)
    add_child(audio)
    for role in range(2):
        var home = Home.new();home.role = role;add_child(home);home_views.append(home)
        var actor = Actor.new();actor.role = role;actor.font = font;actor.storybook = true;actor.caption_visible = true;add_child(actor);actors.append(actor)
    lamp = make_prop(LAMP_ART,Rect2(94,452,296,414),Vector2(98,142));add_child(lamp)
    lamp.position = Story.LAMP;lamp.z_index = int(Story.LAMP.y)
    flame_view = preload("res://game/waystation_flame.gd").new()
    flame_view.state = state
    flame_view.position = Story.LAMP
    flame_view.z_index = int(Story.LAMP.y)+1
    add_child(flame_view)
    for data in [[Rect2(80,50,500,620),Vector2(112,145)],[Rect2(800,0,380,750),Vector2(190,438)],[Rect2(120,732,400,515),Vector2(68,88)],[Rect2(648,766,600,452),Vector2(122,91)]]:
        var prop := make_prop(PROPS,data[0],data[1]);add_child(prop);prop_views.append(prop)
    hud.layer = 14;add_child(hud)
    _panel(Rect2(24,18,850,53))
    title = _label("",Rect2(44,29,820,36),23)
    _panel(Rect2(24,690,1232,90))
    line = _label("",Rect2(44,700,1190,42),18);line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    controls = _label("",Rect2(44,751,1190,24),15)
    complete_panel = _panel(Rect2(275,130,730,505))
    completed_text = _label("",Rect2(30,28,670,450),22,complete_panel);completed_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    complete_panel.visible = false
    set_active(false)

func reset(single: bool, resume := true) -> void:
    state = Story.new();state.single = single;recorded = false;completion_attempted=false;save_status = "";heard = -1;checkpoint_signature="";checkpoint_pending=0
    if resume:
        var data := read_record()
        if not data.is_empty():
            if data.get("version")==2:state.restore_checkpoint(data)
            else:state.restore(data)
            recorded=state.finished;save_status="已恢复第一章通关记录" if recorded else "已恢复第一章安全进度"
            checkpoint_signature=progress_signature()
func record_path() -> String:return "user://"+record_prefix+("-solo-v1.json" if state.single else "-dual-v1.json")
func checkpoint_path()->String:return "user://"+record_prefix+("-solo-v2.json" if state.single else "-dual-v2.json")
func progress_signature()->String:
    var value:Dictionary=state.checkpoint();value.erase("positions");value.erase("controlled")
    return JSON.stringify(value)
func read_json(path:String)->Dictionary:
    if not FileAccess.file_exists(path):return {}
    var file:=FileAccess.open(path,FileAccess.READ)
    if not file or file.get_length()>65536:return {}
    var value=JSON.parse_string(file.get_as_text());file.close()
    return value if value is Dictionary else {}
func read_record() -> Dictionary:
    var value:=read_json(checkpoint_path());var probe=Story.new();probe.single=state.single
    if probe.restore_checkpoint(value):return value
    value=read_json(record_path())
    if not value is Dictionary or value.get("version")!=1 or value.get("chapter")!="chapter-one" or typeof(value.get("completed"))!=TYPE_BOOL or value.get("completed")!=true or not value.get("extras",{}) is Dictionary:return {}
    return value
func save_checkpoint()->bool:
    var value:Dictionary=state.checkpoint();var probe=Story.new();probe.single=state.single
    if not probe.restore_checkpoint(value):return false
    var path:=checkpoint_path();var file:=FileAccess.open(path+".tmp",FileAccess.WRITE)
    if not file:return false
    file.store_string(JSON.stringify(value));file.flush();var error:=file.get_error();file.close()
    if error!=OK or DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))!=OK:return false
    checkpoint_signature=progress_signature();checkpoint_pending=0
    if not state.finished:save_status="安全进度已记录"
    return true
func save_record() -> void:
    completion_attempted=true
    var temporary := record_path()+".tmp"
    var file := FileAccess.open(temporary,FileAccess.WRITE)
    if not file:save_status = "通关完成，记录暂未写入 · 按互动键重试";return
    file.store_string(JSON.stringify(state.record()));file.flush()
    var error := file.get_error();file.close()
    if error==OK and DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary),ProjectSettings.globalize_path(record_path()))==OK:
        recorded = true;save_status = "第一章通关已记录"
    else:save_status = "通关完成，记录暂未写入 · 按互动键重试"
func set_active(value: bool) -> void:
    if active and not value:save_checkpoint()
    active = value;visible = value;hud.visible = value;camera.enabled = value
    if not value:audio.silence()
func start_battle() -> void:
    state.phase = "battle";state.battle_requested = false;battle_requested.emit()
func finish_battle() -> void:state.enter_station()
func handle_action(slot: int, button: int) -> void:
    if not session.running() or (state.single and slot!=0):return
    if button==JOY_BUTTON_LEFT_SHOULDER:state.request_hint();return
    if button==JOY_BUTTON_RIGHT_SHOULDER:
        state.tool(state.controlled if state.single else slot);return
    if state.single:
        if slot!=0:return
        if button in [JOY_BUTTON_Y,JOY_BUTTON_B]:state.switch_actor();return
        slot = state.controlled
    if button==JOY_BUTTON_A:
        if state.finished:
            if not recorded:save_record()
            else:next_chapter_requested.emit()
        else:state.interact(slot)
func _physics_process(dt: float) -> void:
    if not active or not session.running():return
    var a:Vector2=session.movement(0);var b:Vector2=session.movement(1)
    if state.single:b = a if state.controlled==1 else Vector2.ZERO;a = a if state.controlled==0 else Vector2.ZERO
    state.step(dt,a,b,true)
    if progress_signature()!=checkpoint_signature:
        checkpoint_pending+=dt
        if checkpoint_pending>=0.6:save_checkpoint()
    if state.battle_requested:start_battle();return
    if state.finished and not recorded and not completion_attempted:save_record()
    if heard!=state.event_id:heard = state.event_id;audio.play(state.cue)
    _refresh(dt)
func _refresh(dt: float) -> void:
    for role in range(2):
        var selected:bool=not state.single or state.controlled==role
        actors[role].visible = state.equipment
        home_views[role].visible = not state.equipment
        var direction:float=1.0 if state.facing[role].x>=0 else -1.0
        home_views[role].update_motion(state.positions[role],dt)
        home_views[role].show_action(state.actions[role],state.clock,direction)
        home_views[role].position = state.positions[role];home_views[role].z_index = int(state.positions[role].y)
        var kind:String=state.actions[role]
        actors[role].motion_kind={"pet":"reach","paw":"inspect","sniff":"inspect"}.get(kind,kind) if state.action_time[role]>0 or kind=="brace" else ""
        actors[role].update_pose(state.positions[role],selected,state.bracing if role==0 else false,dt)
        actors[role].caption_override = ["朵朵","团团"][role]+(" · 你控制" if state.single and selected else " · 保持中" if state.single and role==0 and state.bracing else " · 伙伴" if state.single else "")
        if state.actions[role] in ["pet","paw","sniff"]:actors[role].rotation = sin(state.action_time[role]*16)*0.04
        else:actors[role].rotation = 0
        if state.resting>0:actors[role].scale = Vector2(1,0.85)
        else:actors[role].scale = Vector2.ONE
    var station:bool = state.phase in ["station","rest","complete"]
    var protected:Array[Rect2]=[]
    if station:
        protected.assign([Rect2(Story.HOOD-Vector2(38,43),Vector2(76,66)),Rect2(Story.VENT-Vector2(40,30),Vector2(80,60)),Rect2(Story.LAMP-Vector2(40,130),Vector2(80,135))])
    else:
        protected.assign([Rect2(Story.SOCKET-Vector2(35,40),Vector2(70,80)),Rect2(Story.KNOT-Vector2(35,40),Vector2(70,80))])
    labels.update(actors,protected)
    prop_views[0].position = Story.GRANNY
    prop_views[0].z_index = int(Story.GRANNY.y)
    prop_views[1].visible = not station
    prop_views[1].position = Vector2(627,650)-Vector2(0,state.branch_raise*26)+(Vector2(132,-35) if state.branch_clear else Vector2.ZERO)
    prop_views[1].rotation = 0.35 if state.branch_clear else 0.0
    prop_views[1].z_index = 208
    prop_views[2].visible = not station
    prop_views[2].position = state.fork_pos if state.carrier<0 else state.positions[state.carrier]+Vector2(26,-21)
    prop_views[2].z_index = int(prop_views[2].position.y)
    prop_views[3].visible = station
    prop_views[3].position = Story.BENCH
    prop_views[3].z_index = int(Story.BENCH.y)
    lamp.modulate = Color.WHITE if state.lit else Color(0.65,0.68,0.65)
    title.text = state.objective()
    line.text = state.message if state.message_time>0 or state.finished else ""
    controls.text = ("WASD · E 互动 · Tab 换角色 · R 工具" if state.single else "朵朵 WASD / E / T · 团团 方向键 / 空格 / R")+" · G 想一想 · Esc 暂停" if session.keyboard_mode else "左摇杆移动 · 面键下互动"+(" · 面键上换角色" if state.single else " · 两位分别操作")+" · 右肩工具 / 左肩想一想 · 菜单暂停"
    if state.single: controls.text += " · 当前："+["朵朵","团团"][state.controlled]
    lamp.visible = state.phase in ["station","rest","complete"]
    flame_view.state = state;flame_view.visible = lamp.visible;flame_view.queue_redraw()
    complete_panel.visible = state.finished
    if state.finished:
        completed_text.text = "点亮第一盏灯 ✓\n\n驿站重新亮起来了。圆圆留下的白毛和脚印，\n把路指向了山坡上的旧钟楼。\n\n朵朵：五分钟以后，我还是很勇敢。\n\n"+save_status+"\n\n下一章：团团，去那边等我\n运输桥、桥架内外的分工，还有钟楼的低窗。\n\n按互动键进入第二章。Esc 可选关、重玩第一章。"
    queue_redraw()
func _panel(rect: Rect2) -> Panel:
    var p := Panel.new();p.position = rect.position;p.size = rect.size
    var style := StyleBoxFlat.new();style.bg_color = Color("f5ead0");style.border_color = Color("a78b64");style.set_border_width_all(2);style.set_corner_radius_all(15)
    p.add_theme_stylebox_override("panel",style);hud.add_child(p);return p
func _label(text:String,rect:Rect2,size:int,parent:Node=null)->Label:
    var l := Label.new();l.text = text;l.position = rect.position;l.size = rect.size
    l.add_theme_font_override("font",font);l.add_theme_font_size_override("font_size",size);l.add_theme_color_override("font_color",Color("344d3c"))
    (hud if parent==null else parent).add_child(l);return l
func _text(p:Vector2,text:String,width:=150.0,size:=16)->void:
    draw_string_outline(font,p,text,HORIZONTAL_ALIGNMENT_CENTER,width,size,5,Color("f9edcf"));draw_string(font,p,text,HORIZONTAL_ALIGNMENT_CENTER,width,size,Color("344b3b"))
func _draw()->void:
    draw_texture_rect(BACKDROP,Rect2(0,0,1280,800),false)
    if not active:return
    var station:bool=state.phase in ["station","rest","complete"]
    if not station:
        _text(Story.TAG+Vector2(-55,-70),"归途门",110)
        draw_style_box(_wood(),Rect2(Story.TAG-Vector2(21,55),Vector2(42,40)))
        if state.extras.get("tag",false):
            draw_polyline(PackedVector2Array([Story.TAG+Vector2(-10,-35),Story.TAG+Vector2(-10,-43),Story.TAG+Vector2(0,-51),Story.TAG+Vector2(10,-43),Story.TAG+Vector2(10,-35),Story.TAG+Vector2(-10,-35)]),Color("ead9a7"),2,true)
        else: draw_line(Story.TAG+Vector2(-8,-40),Story.TAG+Vector2(8,-40),Color("ead9a7"),3,true)
        # Dynamic branch art is attached as a sprite when the atlas is available.
        draw_line(Story.KNOT+Vector2(-34,-28),Story.KNOT+Vector2(-6,-5),Color("d1b475") if state.rope_flash<=0 else Color("d4865c"),5,true)
        if not state.branch_clear:
            draw_line(Story.KNOT+Vector2(-30,-29),Vector2(618,510)-Vector2(0,state.branch_raise*25),Color("d1b475"),3,true)
            draw_arc(Story.SOCKET+Vector2(40,-12),10,0,PI,12,Color("d6b580"),3,true)
        _text(Story.ROAD_EXIT+Vector2(-75,40),"驿站小道",150)
    else:
        _lamp_mechanics()
        _text(Story.BENCH+Vector2(-75,22),"矮柜",150)
        if not state.core_found:
            var core := Story.BENCH+Vector2(0,-8)
            draw_circle(core,5+sin(state.clock*3),Color("d5c786"));draw_circle(core,2,Color("fff1c4"))
        elif state.carrier==1:draw_circle(state.positions[1]+Vector2(23,-36),5,Color("fff1b0"))
        draw_set_transform(Story.PILLOW,0,Vector2(1,0.45));draw_circle(Vector2.ZERO,34,Color("9fbab0"));draw_arc(Vector2.ZERO,27,0,TAU,30,Color("7c978a"),4,true);draw_set_transform(Vector2.ZERO)
        for i in range(3):
            var foot:Vector2=Story.PILLOW+Vector2(35+i*18,-7-i*15)
            draw_circle(foot,2.5,Color("796b56"));draw_circle(foot+Vector2(3,-4),1.5,Color("796b56"))
        draw_line(Story.PILLOW+Vector2(-6,-9),Story.PILLOW+Vector2(3,-4),Color("fff6e4"),3,true)
        draw_texture_rect_region(PROPS,Rect2(Story.SEAT-Vector2(58,28),Vector2(116,27)),Rect2(653,770,590,137))
        for side in [-1,1]:draw_line(Story.SEAT+Vector2(side*45,-3),Story.SEAT+Vector2(side*45,16),Color("715235"),6,true)
        if state.lit:
            for w in [Vector2(906,132),Vector2(1045,173),Vector2(1010,240)]:draw_circle(w,13*state.light_reveal,Color(1,0.78,0.36,0.3*state.light_reveal))
            if state.resting>0:
                var t:=fmod(state.clock*0.5,1)
                draw_circle(Vector2(1140,290).lerp(Vector2(1220,210),t),4,Color(1,0.83,0.45,1-t))
    _text(Story.GRANNY+Vector2(-75,-152),"栗婆婆",150)
    for role in range(2):
        if state.single and state.controlled!=role:continue
        if not state.equipment:
            draw_line(state.positions[role]+Vector2(-9,5),state.positions[role]+Vector2(9,5),Color("fff1c6"),3,true)
            _text(state.positions[role]+Vector2(-80,-150 if role==0 else -103),["朵朵","团团"][role]+(" · 你控制" if state.single else ""),160)
        var item:String=state.target(role)
        if not item.is_empty() and not state.finished:
            var key:String = ("E" if state.single or role==0 else "空格") if session.keyboard_mode else "面键下"
            _text(state.positions[role]+Vector2(-110,36),key+" · "+item,220)
func _wood()->StyleBoxFlat:
    var s:=StyleBoxFlat.new();s.bg_color=Color("a37c4b");s.border_color=Color("684b32");s.set_border_width_all(3);s.set_corner_radius_all(7);return s
func _lamp_mechanics()->void:
    # A windsock and travelling air particles show direction without a solution waypoint.
    var pole:=Vector2(745,302)
    draw_line(pole,pole+Vector2(0,-95),Color("796142"),5,true)
    draw_polyline(PackedVector2Array([pole+Vector2(0,-86),pole+Vector2(33,-80+sin(state.clock*4)*4),pole+Vector2(61,-82+sin(state.clock*5)*7)]),Color("d9b67a"),7,true)
    for i in range(8):
        var t:=fmod(state.clock*0.55+i/8.0,1)
        var p:=Vector2(730,355+i%3*19).lerp(Vector2(952,355+i%3*19),t)
        draw_line(p,p+Vector2(9,0),Color(0.95,0.93,0.80,sin(t*PI)*0.3),1.4,true)
    var glass:Vector2 = Story.LAMP+Vector2(16,-96)
    draw_polyline(PackedVector2Array([glass+Vector2(0,24),Vector2(glass.x,433),Story.VENT-Vector2(0,10)]),Color("7e6641"),7,true)
    draw_polyline(PackedVector2Array([glass+Vector2(23,0),Vector2(Story.HOOD.x,glass.y),Story.HOOD-Vector2(0,8)]),Color("92754d"),4,true)
    var direction:Vector2=[Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT][state.hood]
    var origin:=Story.HOOD+Vector2(0,-8)
    draw_circle(origin,23,Color("89744d"));draw_circle(origin,17,Color("cab07a"))
    draw_line(origin+direction*7,origin+direction*19,Color("3e574d"),11,true)
    for i in range(3):
        var p:=Story.VENT+Vector2(-17+i*17,-10)
        draw_line(p+Vector2(0,-12),p+Vector2(0,12),Color("6e583c"),5,true)
        if i<state.vent:draw_line(p+Vector2(-5,0),p+Vector2(5,0),Color("e8daa9"),3,true)
    _text(Story.HOOD+Vector2(-55,-42),["北","东","南","西"][state.hood],110,15)
    _text(Story.VENT+Vector2(-65,38),["合上","小缝","敞开"][state.vent],130,15)

func make_prop(sheet:Texture2D,region:Rect2,size:Vector2)->Sprite2D:
    var sprite := Sprite2D.new();var frame := AtlasTexture.new();frame.atlas = sheet;frame.region = region;frame.filter_clip = true
    sprite.texture = frame;sprite.offset = Vector2(0,-region.size.y/2);sprite.scale = size/region.size
    return sprite
