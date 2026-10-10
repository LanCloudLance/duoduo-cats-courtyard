extends Node2D
signal battle_requested
signal next_chapter_requested(chapter:int)
const Base = preload("res://game/story_chapter_base.gd")
const Actor = preload("res://game/actor_view.gd")
const StoryLabels = preload("res://game/story_labels.gd")
const StageArt = preload("res://game/story_stage_art.gd")
const Dialogue = preload("res://game/story_dialogue.gd")
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
var labels=StoryLabels.new()
var homes:Array[Node2D]=[]
var title:Label
var line:Label
var controls:Label
var completion:Panel
var completed_text:Label
var recorded:=false
var completion_attempted:=false
var record_prefix:="story"
var save_status:=""
var checkpoint_signature:=""
var checkpoint_pending:=0.0
var heard:=-1
var last_role:=0
var guard_owners:Array[int]=[-1,-1]
var audio:=preload("res://game/story_audio.gd").new()
var scene_transition:CanvasLayer
var memory_scene:CanvasLayer
var dialogue_view:CanvasLayer
var title_panel:Panel
var feedback_panel:Panel
var presentation_data:Dictionary={}
var presentation_clock:=0.0
var social_signature:=""
var social_elapsed:=0.0
var home_ball:=Sprite2D.new()
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
        var a=Actor.new();a.role=role;a.font=font;a.storybook=true;a.social_visual=true;a.caption_visible=true;add_child(a);actors.append(a)
        var h=Home.new();h.role=role;add_child(h);homes.append(h)
    var ball_atlas:=AtlasTexture.new();ball_atlas.atlas=preload("res://assets/story-prologue/home-props.png");ball_atlas.region=Rect2(164,817,355,291);ball_atlas.filter_clip=true
    home_ball.texture=ball_atlas;home_ball.position=Vector2(113,203);home_ball.scale=Vector2(.078,.078);home_ball.z_index=246
    var ball_material:=ShaderMaterial.new();ball_material.shader=preload("res://assets/visual-m13/chroma.gdshader");home_ball.material=ball_material;add_child(home_ball);home_ball.visible=false
    white_npc=Home.new();white_npc.role=2;add_child(white_npc);white_npc.visible=false
    hud.layer=14;add_child(hud)
    dialogue_view=Dialogue.new(font);add_child(dialogue_view)
    memory_scene=preload("res://game/story_memory_scene.gd").new(font);add_child(memory_scene)
    scene_transition=preload("res://game/story_scene_transition.gd").new(font);add_child(scene_transition)
    title_panel=_panel(Rect2(24,18,860,48));title=_label(Rect2(42,27,824,32),21)
    feedback_panel=_panel(Rect2(24,693,1026,83));line=_label(Rect2(42,704,990,43),18);line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    controls=_label(Rect2(42,751,990,21),13)
    completion=_panel(Rect2(230,110,820,540));completed_text=_label(Rect2(30,25,760,490),21,completion);completed_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    set_active(false)
func reset(chapter:int,single:bool,resume:=true)->void:
    var names:={2:"two",3:"three",4:"four",5:"five"}
    state=load("res://game/chapter_"+names[chapter]+"_state.gd").new();state.single=single
    scene_transition.clear()
    heard=-1;last_role=0;guard_owners.assign([-1,-1]);recorded=false;completion_attempted=false;save_status=""
    checkpoint_signature="";checkpoint_pending=0.0
    if resume:
        var data:=read_record()
        if not data.is_empty():
            if int(data.get("version",0))>=2:state.restore_checkpoint(data)
            else:state.restore(data)
            recorded=state.finished;save_status="已恢复本章通关记录" if recorded else "已恢复本章安全进度"
            checkpoint_signature=progress_signature()
func record_path()->String:return "user://"+record_prefix+"-"+state.chapter_key+("-solo-v1.json" if state.single else "-dual-v1.json")
func checkpoint_path()->String:return "user://"+record_prefix+"-"+state.chapter_key+("-solo-v2.json" if state.single else "-dual-v2.json")
func progress_signature()->String:
    var value:Dictionary=state.checkpoint()
    value.erase("positions");value.erase("controlled");value.erase("current_cat")
    return JSON.stringify(value)
func read_json(path:String)->Dictionary:
    if not FileAccess.file_exists(path):return {}
    var f:=FileAccess.open(path,FileAccess.READ)
    if not f or f.get_length()>65536:return {}
    var value=JSON.parse_string(f.get_as_text());f.close()
    return value if value is Dictionary else {}
func read_record()->Dictionary:
    var value:=read_json(checkpoint_path())
    if not value.is_empty():
        var probe=state.get_script().new();probe.single=state.single
        if probe.restore_checkpoint(value):return value
    value=read_json(record_path())
    if not value is Dictionary or value.get("version")!=1 or value.get("chapter")!=state.chapter_key or typeof(value.get("completed"))!=TYPE_BOOL or not value.completed or not value.get("extras",{}) is Dictionary:return {}
    return value
func save_checkpoint()->bool:
    var value:Dictionary=state.checkpoint()
    var probe=state.get_script().new();probe.single=state.single
    if value.is_empty() or not probe.restore_checkpoint(value):return false
    var path:=checkpoint_path();var f:=FileAccess.open(path+".tmp",FileAccess.WRITE)
    if not f:return false
    f.store_string(JSON.stringify(value));f.flush();var error:=f.get_error();f.close()
    if error!=OK or DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))!=OK:return false
    checkpoint_signature=progress_signature();checkpoint_pending=0.0
    if not state.finished:save_status="安全进度已记录"
    return true
func save_record()->void:
    completion_attempted=true
    var path:=record_path();var f:=FileAccess.open(path+".tmp",FileAccess.WRITE)
    if not f:save_status="通关已完成，记录未写入 · 按互动键重试";return
    f.store_string(JSON.stringify(state.record()));f.flush();var error:=f.get_error();f.close()
    if error==OK and DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))==OK:
        if save_checkpoint():
            recorded=true;save_status="本章通关已记录"
        else:save_status="通关已完成，安全记录未写入 · 按互动键重试"
    else:save_status="通关已完成，记录未写入 · 按互动键重试"
func set_active(value:bool)->void:
    if active and not value:save_checkpoint()
    active=value;visible=value;hud.visible=value;camera.enabled=value
    if not value:audio.silence();cancel_inputs();dialogue_view.visible=false;memory_scene.visible=false;scene_transition.visible=false
func handle_action(slot:int,button:int)->void:
    if not session.running() or (state.single and slot!=0):return
    if StageArt.social_transition_active(state):return
    if StageArt.dialog_active(state):
        cancel_inputs()
        if button==JOY_BUTTON_A:state.advance_dialogue()
        _refresh(0);return
    if scene_transition.blocking:return
    var role:int=state.actor_for_slot(slot)
    if button==JOY_BUTTON_Y:
        if state.single:last_role=state.controlled;state.switch_actor()
        elif slot==1:state.switch_cat()
        return
    if button==JOY_BUTTON_B and state.single:
        var old:int=state.controlled;state.controlled=last_role if last_role in state.available_roles() else 0;last_role=old;return
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
            if state.chapter==5:
                guard_owners[slot]=role if role==0 else -1
                state.guard(role,true)
            else:state.request_hint()
        JOY_BUTTON_X:state.attack(role)
func release_action(slot:int,button:int)->void:
    if button==JOY_BUTTON_LEFT_SHOULDER and guard_owners[slot]>=0:
        state.guard(guard_owners[slot],false);guard_owners[slot]=-1
func cancel_inputs()->void:
    state.guard(0,false);guard_owners.assign([-1,-1])
func _physics_process(dt:float)->void:
    if not active or not session.running():return
    if StageArt.dialog_active(state):
        cancel_inputs();_refresh(dt);return
    if scene_transition.blocking and not StageArt.social_transition_active(state):_refresh(dt);return
    state.step(dt,session.movement(0),session.movement(1),true)
    if progress_signature()!=checkpoint_signature:
        checkpoint_pending+=dt
        if checkpoint_pending>=0.6:save_checkpoint()
    if state.battle_requested:battle_requested.emit();return
    if state.finished and not recorded and not completion_attempted:save_record()
    if heard!=state.event_id:heard=state.event_id;audio.play_story(state)
    _refresh(dt)
func _refresh(dt:float)->void:
    refresh_delta=dt
    presentation_clock+=dt
    presentation_data=StageArt.data(state)
    var signature:String=str(presentation_data.get("social",{}))+str(state.dialogue)
    if signature!=social_signature:social_signature=signature;social_elapsed=0.0
    social_elapsed+=dt
    dialogue_view.present(state,session.keyboard_mode)
    memory_scene.present(state,dt)
    var room_key:String=str(state.chapter)+"-"+(presentation_data.get("room","") if state.chapter==4 else state.phase if state.chapter==5 and state.phase in ["home","farewell","complete"] else "world")
    var near_door:=false
    if StageArt.social_transition_active(state) and state.social_gesture.get("kind","")=="travel":
        near_door=true
        for actor in state.social_goals:
            if state.positions[actor].distance_to(state.social_goals[actor])>55:near_door=false
    scene_transition.present(room_key,near_door,dt)
    var home:bool=state.chapter==5 and state.phase in ["home","complete"]
    for role in range(3):
        var present:bool=role in state.available_roles()
        var selected:bool=state.controlled==role if state.single else role==0 or role==state.current_cat
        actors[role].visible=present and not home;homes[role].visible=present and home
        var kind:String=state.actions[role]
        var activity:String="稳光中" if kind=="light" else "保持中" if kind in ["hold","brace"] else "你控制" if selected else "伙伴"
        actors[role].caption_override=["朵朵","团团","圆圆"][role]+(" · "+activity if state.single else "")
        var pose_kind:String={"light":"reach","touch":"reach","hook":"pull","paw":"inspect","pet":"reach","sniff":"inspect"}.get(kind,kind)
        if role==0 and presentation_data.get("pilot_waiting",false):pose_kind="inspect"
        if kind=="hold" and ((state.chapter==5 and role==1 and state.hook_held) or (state.chapter==2 and role==0)):pose_kind="pull"
        actors[role].social_kind=StageArt.social_kind(state,role)
        actors[role].presentation_clock=presentation_clock
        actors[role].motion_kind=pose_kind if state.action_time[role]>0 or kind in ["hold","brace","light"] else ""
        actors[role].update_pose(state.positions[role],selected,kind in ["hold","brace"],dt)
        actors[role].rotation=0.0
        var direction:float=1 if state.facing[role].x>=0 else -1
        homes[role].update_motion(state.positions[role],dt)
        var home_kind:String=state.actions[role]
        var social:String=StageArt.social_kind(state,role)
        if not social.is_empty():home_kind="sit" if social=="rest" else "pet" if role==0 else "paw" if role==1 else "sleep"
        homes[role].show_action(home_kind,presentation_clock,direction);homes[role].place_home(state.positions[role],home_kind,dt);homes[role].z_index=int(state.positions[role].y)
    labels.update(actors,_label_obstacles())
    title.text=state.objective()
    line.text=state.message if state.message_time>0 else ""
    var party:="朵朵 / 团团 / 圆圆" if state.joined else "朵朵 / 团团"
    controls.text=("WASD · E 互动 · Tab 换角色 · Q 切回 · R 工具" if state.single else "朵朵 WASD / E / T · 猫咪 方向键 / 空格 / R · Tab 切猫") if session.keyboard_mode else "左摇杆 · 下互动 · 右肩工具 · 上换角色"
    controls.text+=" · G 举盾" if state.chapter==5 and session.keyboard_mode else " · G 想一想" if session.keyboard_mode else " · 左肩举盾" if state.chapter==5 else " · 左肩想一想"
    controls.text+=" · 当前："+["朵朵","团团","圆圆"][state.controlled] if state.single else " · "+party
    controls.text+=" · 记事中可想一想 · Esc 暂停"
    completion.visible=state.finished and state.chapter<5
    if state.finished and state.chapter==5:
        title.text="都在就好 · 回家的路亮了"
        line.text=state.message if state.message_time>0 else save_status+" · 可在家中继续摸猫，Esc 回访章节。"
    if state.finished:completed_text.text=state.completion_text()+"\n\n"+save_status+("\n\n按互动键继续下一章 · Esc 可重玩 / 选关。" if state.chapter<5 else "\n\n旅程完成 · 可在家中停留，或从菜单回访章节。")
    controls.text=("E 互动 · R 工具 · Tab 换角色 · H 记事 · Esc 暂停" if session.keyboard_mode else "下面键互动 · 右肩工具 · 上面键换猫 · 返回键记事")
    feedback_panel.visible=not dialogue_view.active and (not line.text.is_empty() or state.message_time>0)
    line.visible=feedback_panel.visible;controls.visible=feedback_panel.visible
    title_panel.visible=not dialogue_view.active;title.visible=not dialogue_view.active
    npc_at=Vector2(-5000,-5000);queue_redraw();foreground.queue_redraw()
func _label_obstacles()->Array[Rect2]:
    var rects:Array[Rect2]=[]
    if state.chapter==2 and state.locked_a and not state.locked_b:
        rects.assign([Rect2(562,435,68,72),Rect2(609,424,40,55),Rect2(625,358,83,78)])
    if state.chapter==3 and state.bridge_locked:
        rects.assign([Rect2(901,337,34,106),Rect2(state.LOW_MIRROR-Vector2(19,19),Vector2(38,38)),Rect2(state.HIGH_MIRROR-Vector2(19,19),Vector2(38,38)),Rect2(state.HIGH_RING-Vector2(14,-11),Vector2(28,23)),Rect2(state.LOW_RECEIVER-Vector2(17,18),Vector2(34,36)),Rect2(state.HIGH_RECEIVER-Vector2(17,18),Vector2(34,36)),Rect2(state.EXIT_WALL-4,272,22,69)])
    if state.chapter==4 and state.phase in ["meet","investigate","test","offer"]:
        rects.assign([Rect2(state.BRANCH-Vector2(38,48),Vector2(76,96)),Rect2(state.ARROWS-Vector2(35,40),Vector2(70,80)),Rect2(state.DUCT_LIGHT-Vector2(32,45),Vector2(64,90)),Rect2(state.RESERVE-Vector2(25,25),Vector2(50,50)),Rect2(state.ALIGHT-Vector2(35,100),Vector2(70,110))])
    return rects
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
    elif state.chapter==4:
        var room:String=presentation_data.get("room","market" if state.phase=="market" else "exterior" if state.phase=="exterior" else "interior")
        if not StageArt.backdrop_four(self,room):draw_texture_rect(backdrop,Rect2(0,0,1280,800),false,Color("aebbc4") if night else Color.WHITE)
    else:draw_texture_rect(backdrop,Rect2(0,0,1280,800),false,Color("929db5") if night else Color.WHITE)
    if not active:return
    if state.chapter==4:StageArt.draw_four(self,state,presentation_data)
    else:
        state.draw_world(self)
        StageArt.draw_paths(self,presentation_data)
        StageArt.draw_mechanisms(self,presentation_data)
    home_ball.visible=home and "prologue_ball" in presentation_data.get("home_discoveries",[])
    if home:
        var found:Array=presentation_data.get("home_discoveries",[]).duplicate()
        if state.farewell_gift and not "wood_lamp" in found:found.append("wood_lamp")
        StageArt.discoveries(self,found,Vector2(150,267))
    white_npc.visible=npc_at.x>0 and not state.joined
    if white_npc.visible:
        var walking:bool=state.chapter==3 and state.npc_called and not state.door_open
        white_npc.update_motion(npc_at,refresh_delta)
        white_npc.show_action("walk" if walking else "sleep" if state.chapter==2 else "",state.clock,1)
        white_npc.position=npc_at;white_npc.z_index=int(npc_at.y)
    for role in state.available_roles():
        if state.single and state.controlled!=role:continue
        if home and not dialogue_view.active:ink(homes[role].position+Vector2(-80,-125 if role==0 else -94),["朵朵","团团","圆圆"][role],160)
        var item:String=state.target(role)
        if not item.is_empty() and (not state.finished or home) and not dialogue_view.active:
            var key:String=("E" if state.single or role==0 else "空格") if session.keyboard_mode else "面键下"
            ink(state.positions[role]+Vector2(-125,33),key+" · "+display_name(item),250,16)
func ink(p:Vector2,text:String,width:=160.0,size:=17)->void:
    if state.chapter==5 and state.phase in ["home","complete"] and (text.begins_with("装备") or text in ["水盆和软布","干净的猫爪"]):return
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
func conduit(points:PackedVector2Array,lit:=false)->void:
    draw_polyline(points,Color("473820"),11,true)
    draw_polyline(points,Color("a27942"),8,true)
    var highlights:=PackedVector2Array()
    for p in points:highlights.append(p+Vector2(-1,-2))
    draw_polyline(highlights,Color("e4bc75"),2,true)
    for p in points:
        draw_circle(p,6,Color("674825"));draw_circle(p,4,Color("c7a466"));draw_circle(p,2,Color("fae4ae") if lit else Color("80613b"))
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
    if index==14 and state.chapter==5 and state.phase in ["home","complete"]:return
    if index==9 and state.chapter==5 and state.phase in ["home","complete"]:
        StageArt.tool_rack(self,rect,state.gear_stored);return
    if index==9 and state.chapter==3 and rect.position.x<900:
        StageArt.tool_rack(self,rect,not state.light_equipped,true);return
    if index==4 and state.chapter==2:
        StageArt.toolbox(self,rect,state.hook_owned,state.hook_owned);return
    if index==11 and state.chapter==3:
        StageArt.hatch(self,rect,true);return
    if index in [11,12] and state.chapter==5:
        if index==11 or not state.lid_open:StageArt.hatch(self,rect,state.lid_open)
        return
    if index==8:
        if state.chapter==3 and rect.get_center().distance_to(state.INDOOR_PLATE)<40:
            StageArt.pressure_plate(self,rect,state.door_open or (state.wick_fitted and state.door_angle==1))
        elif rect.size.x>rect.size.y*1.6:
            StageArt.handle(self,rect,state.actions[0] in ["hold","brace"])
        elif rect.size.x<40 or state.chapter==5:
            StageArt.receiver(self,rect,tint.r>0.9 and tint.g>0.75,angle)
        else:
            _atlas_prop(MECHANISMS,prop_regions.mechanisms[index],rect,angle,tint)
        return
    if index==3:
        var locked:bool=tint!=Color.WHITE and tint.r>0.9 and tint.g>0.75
        if state.chapter==5 and state.phase=="approach":locked=state.route_lock if rect.get_center().distance_to(state.LOW_LOCK)<45 else state.route_supported
        elif state.chapter==5 and rect.get_center().distance_to(state.ARM_LOCK)<45:locked=state.arm_locked
        StageArt.latch(self,rect,locked,angle);return
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
func merchant(p:Vector2)->void:StageArt.npc(self,1,2 if state.chapter==5 else 0,p,120,state.clock)
func alight(p:Vector2)->void:
    StageArt.npc(self,0,2 if state.chapter==5 and state.network_lit else 1 if state.chapter==5 and state.machine_stopped else 0,p,112,state.clock)
func _draw_foreground()->void:
    StageArt.social_items(foreground,state,social_elapsed)
    if state.chapter==5 and presentation_data.get("support_site","")=="carried":StageArt.support_pin(foreground,state.positions[1]+Vector2(22,-33))
    if not active or state.chapter!=2:return
    for x in [1138,1154,1170,1186]:
        foreground.draw_line(Vector2(x,335),Vector2(x,419),Color("625f4a"),4,true)
        foreground.draw_line(Vector2(x-1,335),Vector2(x-1,419),Color("c2b591"),1,true)
func white_cat(p:Vector2)->void:npc_at=p
func granny(p:Vector2)->void:
    StageArt.npc(self,2,2 if state.chapter==5 and state.farewell_gift else 1,p,140,state.clock)

func display_name(item:String)->String:
    return {"outer_bench":"旧作业台","outer_ratchet":"外路棘轮","cart_hook":"货运钩","map_back":"旧图背面","winch_a":"近岸绞盘","winch_b":"后段绞盘","brace_b":"后桥受力柄","lamp_a":"近岸导向灯","lamp_b":"中段导向灯","latch_a":"前桥扣","latch_b":"后桥扣","box":"检修箱","loop":"试用拉环","shortcut":"短桥拉环","window":"低窗","duct":"外墙检修槽","door_lamp":"门外灯座","reunion":"圆圆","equipment":"工具架","light":"定光灯座","board":"导光板","lock":"桥锁","narrow":"窄道拉环","rig":"低镜调整柄","high_mirror":"高镜拉环","search":"升降灯座","map":"路线图"}.get(item,item)
