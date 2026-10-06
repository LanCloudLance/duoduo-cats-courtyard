extends Node2D
signal battle_requested
signal next_chapter_requested(chapter:int)
const Base = preload("res://game/story_chapter_base.gd")
const Actor = preload("res://game/actor_view.gd")
const Home = preload("res://game/home_sprite.gd")
const FOREST = preload("res://assets/story-chapter-one/waystation.png")
const RIVER = preload("res://assets/visual-m13/courtyard-painted.png")
const GROVE = preload("res://assets/visual-m14/arena-painted.png")
const HOME = preload("res://assets/story-prologue/home-room-play.png")
const TERRAIN = preload("res://assets/visual-m15/terrain-atlas.png")
const PROPS = preload("res://assets/story-chapter-one/props.png")
const CHAPTER_ART = [preload("res://assets/visual-m26/chapter-two.png"),preload("res://assets/visual-m26/chapter-three.png"),preload("res://assets/visual-m26/chapter-four.png"),preload("res://assets/visual-m26/chapter-five.png")]
const MECHANISMS = preload("res://assets/visual-m26/mechanisms.png")
const SUPPORT_ART = preload("res://assets/visual-m26/support.png")
const FLOOR_ART = preload("res://assets/visual-m26/floor-pieces.png")
var prop_regions:Dictionary={}
var foreground:=Node2D.new()
var refresh_delta:=0.0
var state = Base.new()
var session
var active := false
var camera := Camera2D.new()
var hud := CanvasLayer.new()
var font:Font
var actors:Array[Node2D]=[]
var homes:Array[Node2D]=[]
var title:Label
var line:Label
var controls:Label
var completion:Panel
var completed_text:Label
var recorded:=false
var record_prefix:="story"
var save_status:=""
var heard:=-1
var last_role:=0
var audio:=preload("res://game/garden_audio.gd").new()
var white_npc:Node2D
var npc_at:=Vector2(-5000,-5000)
func _init(value)->void:session=value
func _ready()->void:
    font=get_parent().theme.default_font
    prop_regions=JSON.parse_string(FileAccess.get_file_as_string("res://assets/visual-m26/props-regions.json"))
    foreground.z_index=950;add_child(foreground);foreground.draw.connect(_draw_foreground)
    camera.position=Vector2(640,400);camera.enabled=false;add_child(camera)
    add_child(audio)
    for role in range(3):
        var a=Actor.new();a.role=role;a.font=font;a.storybook=true;a.caption_visible=true;add_child(a);actors.append(a)
        var h=Home.new();h.role=role;add_child(h);homes.append(h)
    white_npc=Home.new();white_npc.role=2;add_child(white_npc);white_npc.visible=false
    hud.layer=14;add_child(hud)
    _panel(Rect2(24,18,1010,53));title=_label(Rect2(44,28,970,38),23)
    _panel(Rect2(24,676,1232,103));line=_label(Rect2(44,686,1190,51),18);line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    controls=_label(Rect2(44,748,1190,25),14)
    completion=_panel(Rect2(230,110,820,540));completed_text=_label(Rect2(30,25,760,490),21,completion);completed_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    set_active(false)
func reset(chapter:int,single:bool,resume:=true)->void:
    var names:={2:"two",3:"three",4:"four",5:"five"}
    state=load("res://game/chapter_"+names[chapter]+"_state.gd").new();state.single=single
    heard=-1;last_role=0;recorded=false;save_status=""
    if resume:
        var data:=read_record()
        if not data.is_empty():state.restore(data);recorded=true;save_status="已恢复本章通关记录"
func record_path()->String:return "user://"+record_prefix+"-"+state.chapter_key+("-solo-v1.json" if state.single else "-dual-v1.json")
func read_record()->Dictionary:
    if not FileAccess.file_exists(record_path()):return {}
    var f:=FileAccess.open(record_path(),FileAccess.READ)
    if not f or f.get_length()>65536:return {}
    var value=JSON.parse_string(f.get_as_text());f.close()
    if not value is Dictionary or value.get("version")!=1 or value.get("chapter")!=state.chapter_key or typeof(value.get("completed"))!=TYPE_BOOL or not value.completed or not value.get("extras",{}) is Dictionary:return {}
    return value
func save_record()->void:
    var path:=record_path();var f:=FileAccess.open(path+".tmp",FileAccess.WRITE)
    if not f:save_status="通关已完成，记录未写入 · 按互动键重试";return
    f.store_string(JSON.stringify(state.record()));f.flush();var error:=f.get_error();f.close()
    if error==OK and DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))==OK:
        recorded=true;save_status="本章通关已记录"
    else:save_status="通关已完成，记录未写入 · 按互动键重试"
func set_active(value:bool)->void:
    active=value;visible=value;hud.visible=value;camera.enabled=value
    if not value:audio.silence();state.guard(0,false)
func handle_action(slot:int,button:int)->void:
    if not session.running() or (state.single and slot!=0):return
    var role:int=state.actor_for_slot(slot)
    if button==JOY_BUTTON_Y:
        if state.single:last_role=state.controlled;get_parent().router.clear_keyboard();state.switch_actor()
        elif slot==1:get_parent().router.clear_keyboard();state.switch_cat()
        return
    if button==JOY_BUTTON_B and state.single:
        var old:int=state.controlled;get_parent().router.clear_keyboard();state.controlled=last_role if last_role in state.available_roles() else 0;last_role=old;return
    if state.finished:
        if button==JOY_BUTTON_A:
            if not recorded:save_record()
            elif state.chapter<5:next_chapter_requested.emit(state.chapter+1)
            else:state.interact(role)
        return
    match button:
        JOY_BUTTON_A:state.interact(role)
        JOY_BUTTON_RIGHT_SHOULDER:state.tool(role)
        JOY_BUTTON_LEFT_SHOULDER:
            if state.chapter==5:state.guard(role,true)
            else:state.request_hint()
        JOY_BUTTON_X:state.attack(role)
func release_action(slot:int,button:int)->void:
    if button==JOY_BUTTON_LEFT_SHOULDER:state.guard(state.actor_for_slot(slot),false)
func cancel_inputs()->void:state.guard(0,false)
func _physics_process(dt:float)->void:
    if not active or not session.running():return
    state.step(dt,session.movement(0),session.movement(1),true)
    if state.battle_requested:battle_requested.emit();return
    if state.finished and not recorded and save_status.is_empty():save_record()
    if heard!=state.event_id:heard=state.event_id;audio.play(state.cue)
    _refresh(dt)
func _refresh(dt:float)->void:
    refresh_delta=dt
    var home:bool=state.chapter==5 and state.phase in ["home","complete"]
    for role in range(3):
        var present:bool=role in state.available_roles()
        var selected:bool=state.controlled==role if state.single else role==0 or role==state.current_cat
        actors[role].visible=present and not home;homes[role].visible=present and home
        actors[role].caption_override=["朵朵","团团","圆圆"][role]+(" · 你控制" if state.single and selected else " · 等你" if state.single else "")
        var kind:String=state.actions[role]
        var pose_kind:String={"light":"reach","touch":"reach","hook":"pull","paw":"inspect","pet":"reach","sniff":"inspect"}.get(kind,kind)
        if kind=="hold" and ((state.chapter==5 and role==1 and state.hook_held) or (state.chapter==2 and role==0)):pose_kind="pull"
        actors[role].motion_kind=pose_kind if state.action_time[role]>0 or kind in ["hold","brace","light"] else ""
        actors[role].update_pose(state.positions[role],selected,kind in ["hold","brace"],dt)
        actors[role].rotation=0.0
        var direction:float=1 if state.facing[role].x>=0 else -1
        homes[role].update_motion(state.positions[role],dt)
        homes[role].show_action(state.actions[role],state.clock,direction);homes[role].position=state.positions[role];homes[role].z_index=int(state.positions[role].y)
    title.text=state.objective()
    line.text=state.message if state.message_time>0 else ""
    var party:="朵朵 / 团团 / 圆圆" if state.joined else "朵朵 / 团团"
    controls.text=("WASD · E 互动 · Tab 换角色 · Q 切回 · R 工具" if state.single else "朵朵 WASD / E / T · 猫咪 方向键 / 空格 / R · Tab 切猫") if session.keyboard_mode else "左摇杆 · 下互动 · 右肩工具 · 上换角色"
    controls.text+=" · G 举盾" if state.chapter==5 and session.keyboard_mode else " · G 想一想" if session.keyboard_mode else " · 左肩举盾" if state.chapter==5 else " · 左肩想一想"
    controls.text+=" · 当前："+["朵朵","团团","圆圆"][state.controlled] if state.single else " · "+party
    controls.text+=" · Esc 暂停"
    completion.visible=state.finished and state.chapter<5
    if state.finished and state.chapter==5:
        title.text="故事试玩完成 · 都在就好"
        line.text=state.message if state.message_time>0 else save_status+" · 可在家中继续摸猫，Esc 回访章节。"
    if state.finished:completed_text.text=state.completion_text()+"\n\n"+save_status+("\n\n按互动键继续下一章 · Esc 可重玩 / 选关。" if state.chapter<5 else "\n\n故事试玩完成 · Esc 可回访任意章节。")
    npc_at=Vector2(-5000,-5000);queue_redraw();foreground.queue_redraw()
func _panel(rect:Rect2)->Panel:
    var p:=Panel.new();p.position=rect.position;p.size=rect.size
    var s:=StyleBoxFlat.new();s.bg_color=Color("f5ead0");s.border_color=Color("a78b64");s.set_border_width_all(2);s.set_corner_radius_all(15);p.add_theme_stylebox_override("panel",s);hud.add_child(p);return p
func _label(rect:Rect2,size:int,parent:Node=null)->Label:
    var l:=Label.new();l.position=rect.position;l.size=rect.size;l.add_theme_font_override("font",font);l.add_theme_font_size_override("font_size",size);l.add_theme_color_override("font_color",Color("344d3c"));(hud if parent==null else parent).add_child(l);return l
func _draw()->void:
    var home:bool=state.chapter==5 and state.phase in ["home","complete"]
    var backdrop:Texture2D=HOME if home else CHAPTER_ART[2] if state.chapter==5 and state.phase=="farewell" else CHAPTER_ART[clampi(state.chapter-2,0,3)]
    var night:bool=state.chapter==4 and not state.shell_fixed
    if state.chapter==3:
        # Align the painted cutaway's partition and service pit with real walls.
        var source_cuts:=[0,455,875,1090,1586]
        var world_cuts:=[0,450,700,855,1280]
        for i in range(4):
            draw_texture_rect_region(backdrop,Rect2(world_cuts[i],0,world_cuts[i+1]-world_cuts[i],800),Rect2(source_cuts[i],0,source_cuts[i+1]-source_cuts[i],992))
    else:draw_texture_rect(backdrop,Rect2(0,0,1280,800),false,Color("929db5") if night else Color.WHITE)
    if not active:return
    state.draw_world(self)
    white_npc.visible=npc_at.x>0 and not state.joined
    if white_npc.visible:
        var walking:bool=state.chapter==3 and state.npc_called and not state.door_open
        white_npc.update_motion(npc_at,refresh_delta)
        white_npc.show_action("walk" if walking else "sleep" if state.chapter==2 else "",state.clock,1)
        white_npc.position=npc_at;white_npc.z_index=int(npc_at.y)
    for role in state.available_roles():
        if state.single and state.controlled!=role:continue
        if home:ink(state.positions[role]+Vector2(-80,-125 if role==0 else -94),["朵朵","团团","圆圆"][role],160)
        var item:String=state.target(role)
        if not item.is_empty() and not state.finished:
            var key:String=("E" if state.single or role==0 else "空格") if session.keyboard_mode else "面键下"
            ink(state.positions[role]+Vector2(-125,33),key+" · "+display_name(item),250,16)
func ink(p:Vector2,text:String,width:=160.0,size:=17)->void:
    draw_string_outline(font,p,text,HORIZONTAL_ALIGNMENT_CENTER,width,size,4,Color("fff3d8"));draw_string(font,p,text,HORIZONTAL_ALIGNMENT_CENTER,width,size,Color("304a3a"))
func wood(rect:Rect2,color:=Color("a68453"))->void:
    draw_texture_rect_region(FLOOR_ART,rect,Rect2(1090,559,371,371),Color.WHITE.lerp(color,0.25))
func lamp(p:Vector2,lit:bool)->void:
    prop(2,Rect2(p+Vector2(-25,-78),Vector2(50,84)),0,Color.WHITE if lit else Color("8c9d9a"))
    if lit:
        var flame:=p+Vector2(11,-38)
        for i in range(4):draw_circle(flame,29-i*6,Color(1,.76,.34,.025+i*.035))
        draw_colored_polygon(PackedVector2Array([flame+Vector2(-4,6),flame+Vector2(-5,-1),flame+Vector2(1,-10),flame+Vector2(5,3),flame+Vector2(3,7)]),Color("ffe3a1"))
func gear(p:Vector2,angle:float,radius:=25.0)->void:
    support_prop(5,Rect2(p-Vector2.ONE*radius,Vector2.ONE*radius*2),angle)
func arrow(p:Vector2,direction:Vector2,color:=Color("efe0a1"))->void:
    var d:=direction.normalized();draw_line(p-d*15,p+d*15,color,4,true);draw_line(p+d*15,p+d*5+d.orthogonal()*9,color,4,true);draw_line(p+d*15,p+d*5-d.orthogonal()*9,color,4,true)
func rope(a:Vector2,b:Vector2)->void:draw_line(a,b,Color("795f3a"),7,true);draw_line(a,b,Color("c7ad7c"),3,true)
func bridge(rect:Rect2,open:bool)->void:
    if open:
        draw_texture_rect_region(FLOOR_ART,rect,Rect2(96,132,855,302));rope(rect.position,Vector2(rect.end.x,rect.position.y));rope(Vector2(rect.position.x,rect.end.y),rect.end)
    else:
        if state.chapter==2:
            for y in range(int(rect.position.y)+10,int(rect.end.y),30):draw_line(Vector2(rect.position.x+7,y),Vector2(rect.end.x-7,y-5),Color(.72,.91,.85,.28),2,true)
        else:pit(rect)
func pit(rect:Rect2)->void:
    if rect.size.y<=rect.size.x:
        draw_texture_rect_region(FLOOR_ART,rect,Rect2(100,614,855,249));return
    # Preserve masonry/pipe proportions along long narrow cuts in the floor.
    # Two end caps and repeating inner-wall strips keep this a flat service trench.
    var ratio:=rect.size.x/234.0
    var cap:=minf(76.0*ratio,rect.size.y*.2)
    draw_texture_rect_region(FLOOR_ART,Rect2(rect.position,Vector2(rect.size.x,cap)),Rect2(1087,20,234,76))
    var yy:=rect.position.y+cap
    while yy<rect.end.y-cap-.01:
        var h:=minf(342.0*ratio,rect.end.y-cap-yy)
        draw_texture_rect_region(FLOOR_ART,Rect2(rect.position.x,yy,rect.size.x,h),Rect2(1087,96,234,h/ratio))
        yy+=h
    draw_texture_rect_region(FLOOR_ART,Rect2(rect.position.x,rect.end.y-cap,rect.size.x,cap),Rect2(1087,431,234,76))
func prop(index:int,rect:Rect2,angle:=0.0,tint:=Color.WHITE)->void:
    _atlas_prop(MECHANISMS,prop_regions.mechanisms[index],rect,angle,tint)
func support_prop(index:int,rect:Rect2,angle:=0.0,tint:=Color.WHITE)->void:
    _atlas_prop(SUPPORT_ART,prop_regions.support[index],rect,angle,tint)
func _atlas_prop(texture:Texture2D,region:Array,rect:Rect2,angle:float,tint:Color)->void:
    var source:=Rect2(region[0],region[1],region[2],region[3])
    draw_set_transform(rect.get_center(),angle)
    draw_texture_rect_region(texture,Rect2(-rect.size*.5,rect.size),source,tint)
    draw_set_transform(Vector2.ZERO)
func machine_arm(a:Vector2,b:Vector2,width:float)->void:
    support_prop(4,Rect2((a+b)*.5-Vector2(a.distance_to(b)*.5,width*.5),Vector2(a.distance_to(b),width)),a.angle_to_point(b))
    gear(a,0,width*.65);gear(b,0,width*.65)
func merchant(p:Vector2)->void:support_prop(1,Rect2(p-Vector2(40,116),Vector2(80,116)))
func alight(p:Vector2)->void:
    support_prop(0,Rect2(p-Vector2(37,100),Vector2(74,100)))
func _draw_foreground()->void:
    if not active or state.chapter!=2:return
    for x in [1138,1154,1170,1186]:
        foreground.draw_line(Vector2(x,335),Vector2(x,419),Color("625f4a"),4,true)
        foreground.draw_line(Vector2(x-1,335),Vector2(x-1,419),Color("c2b591"),1,true)
func white_cat(p:Vector2)->void:npc_at=p
func granny(p:Vector2)->void:
    draw_texture_rect_region(PROPS,Rect2(p-Vector2(52,142),Vector2(104,142)),Rect2(80,50,500,620))

func display_name(item:String)->String:
    return {"winch_a":"近岸绞盘","winch_b":"后段绞盘","lamp_a":"近岸导向灯","lamp_b":"中段导向灯","latch_a":"前桥扣","latch_b":"后桥扣","box":"检修箱","loop":"试用拉环","shortcut":"短桥拉环","window":"低窗","duct":"外墙检修槽","door_lamp":"门外灯座","reunion":"圆圆","equipment":"工具架","light":"定光灯座","board":"导光板","lock":"桥锁","narrow":"窄道拉环","rig":"灯架","search":"寻路灯座","map":"路线图"}.get(item,item)
