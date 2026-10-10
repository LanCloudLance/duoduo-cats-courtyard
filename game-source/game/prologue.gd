extends Node2D
signal next_chapter_requested
const StageArt = preload("res://game/story_stage_art.gd")
const Dialogue = preload("res://game/story_dialogue.gd")
var dialogue_view:CanvasLayer
var feedback_panel:Panel
var presentation_clock:=0.0
const Story = preload("res://game/prologue_state.gd")
const HomeSprite = preload("res://game/home_sprite.gd")
const BACKDROP = preload("res://assets/story-prologue/home-room-play.png")
const OPEN_BACKDROP = preload("res://assets/story-prologue/home-room-open.png")
const PROPS = preload("res://assets/story-prologue/home-props.png")
var props: Array[Sprite2D] = []
var state = Story.new()
var session
var active := false
var camera := Camera2D.new()
var hud := CanvasLayer.new()
var font: Font
var sprites: Array[Node2D] = []
var walk_phase: Array[float] = [0.0,0.0,0.0]
var faces: Array[float] = [1.0,-1.0,-1.0]
var goal_label: Label
var line_label: Label
var controls: Label
var complete_panel: Panel
var completed_text: Label
var audio := preload("res://game/story_audio.gd").new()
var heard := -1
var recorded := false
var save_status := ""
var completion_attempted := false
var saved_signature := ""
var observed_signature := ""
var save_delay := 0.0
var record_prefix := "story-prologue-v2"

func _init(value) -> void: session = value
func _ready() -> void:
    font = get_parent().theme.default_font
    camera.position = Vector2(640,400)
    camera.enabled = false
    add_child(camera)
    add_child(audio)
    for role in range(3):
        var sprite = HomeSprite.new()
        sprite.role = role
        sprite.position = state.positions[role]
        add_child(sprite)
        sprites.append(sprite)
    for index in range(4):
        var prop := Sprite2D.new()
        var atlas := AtlasTexture.new()
        atlas.atlas = PROPS
        # The generated rug extends a few pixels below the half-height seam.
        atlas.region = Rect2((index%2)*627,0 if index < 2 else 650,627,645 if index < 2 else 604)
        atlas.filter_clip = true
        prop.texture = atlas
        var mat := ShaderMaterial.new()
        mat.shader = preload("res://assets/visual-m13/chroma.gdshader")
        prop.material = mat
        prop.scale = Vector2(0.235,0.235) if index < 2 else Vector2(0.12,0.12)
        prop.z_index = 1
        add_child(prop)
        props.append(prop)
    hud.layer = 14
    add_child(hud)
    dialogue_view=Dialogue.new(font);add_child(dialogue_view)
    _panel(Rect2(24,18,590,83))
    _label("序章 · 今天明明准备什么都不干",Rect2(44,25,550,32),23)
    goal_label = _label("",Rect2(44,61,550,27),17)
    feedback_panel=_panel(Rect2(24,700,1026,78))
    line_label = _label("",Rect2(42,710,990,42),18)
    line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    controls = _label("",Rect2(42,752,990,22),13)
    complete_panel = _panel(Rect2(300,165,680,455))
    complete_panel.visible = false
    completed_text = _label("",Rect2(332,189,610,410),23,complete_panel)
    # Children of the completion card use positions local to it.
    completed_text.position = Vector2(32,24)
    completed_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    set_active(false)

func reset(single: bool, resume := false) -> void:
    state = Story.new()
    state.single = single
    recorded = false
    completion_attempted = false
    save_status = ""
    heard = -1
    if resume:
        var data := read_record()
        if not data.is_empty():
            var restored: bool = state.restore_checkpoint(data) if int(data.get("version",0)) >= 2 else preload("res://game/prologue_checkpoint.gd").restore_legacy(state,data)
            if restored:
                recorded = state.finished
                completion_attempted = recorded
                save_status = "已恢复序章通关记录" if recorded else "已恢复序章途中进度"
    saved_signature = ""
    observed_signature = ""
    save_delay = 0
    if complete_panel: complete_panel.visible = state.finished

func record_path() -> String:
    return "user://"+record_prefix+("-solo-v1.json" if state.single else "-dual-v1.json")
func checkpoint_path() -> String:
    return "user://"+record_prefix+("-solo-v2.json" if state.single else "-dual-v2.json")
func _read_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path): return {}
    var file := FileAccess.open(path,FileAccess.READ)
    if not file or file.get_length() > 65536: return {}
    var parser := JSON.new()
    if parser.parse(file.get_as_text()) != OK: return {}
    return parser.data if parser.data is Dictionary else {}
func read_record() -> Dictionary:
    var data := _read_json(checkpoint_path())
    var probe = Story.new()
    probe.single = state.single
    if probe.restore_checkpoint(data): return data
    data = _read_json(record_path())
    if preload("res://game/prologue_checkpoint.gd").restore_legacy(probe,data): return data
    return {}
func _signature() -> String:
    var data: Dictionary = state.checkpoint()
    # Movement is flushed on pause; permanent changes are debounced while playing.
    data.erase("positions")
    data.erase("controlled")
    data.facts.erase("ball")
    data.facts.erase("wedge")
    return JSON.stringify(data)
func save_checkpoint() -> bool:
    var data: Dictionary = state.checkpoint()
    var probe = Story.new()
    probe.single = state.single
    if not probe.restore_checkpoint(data):
        save_status = "进度暂未写入 · 可稍后重试"
        return false
    var path := checkpoint_path()
    var temp := path+".tmp"
    var file := FileAccess.open(temp,FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(data))
        file.flush()
        var error := file.get_error()
        file.close()
        if error == OK and DirAccess.rename_absolute(temp,path) == OK:
            saved_signature = _signature()
            observed_signature = saved_signature
            save_delay = 0
            save_status = "序章通关已记录" if state.finished else "序章途中进度已记录"
            if state.finished: recorded = true
            return true
    save_status = "进度暂未写入 · 可稍后重试"
    return false
func save_record() -> void:
    completion_attempted = true
    save_checkpoint()
func cancel_inputs() -> void:
    state.cancel_inputs()
func set_active(value: bool) -> void:
    if active and not value:
        save_checkpoint()
        cancel_inputs()
    active = value
    visible = value
    hud.visible = value
    camera.enabled = value
    if not value:
        audio.silence()
        dialogue_view.visible=false

func handle_action(slot: int, button: int) -> void:
    if not active or not session.running() or slot<0 or slot>1:return
    if StageArt.social_transition_active(state):return
    if StageArt.dialog_active(state):
        if button==JOY_BUTTON_A:state.advance_dialogue()
        return
    if not session.running() or slot < 0 or slot > 1: return
    if state.single:
        if slot != 0: return
        if button in [JOY_BUTTON_Y,JOY_BUTTON_B]:
            state.switch_actor()
            return
        slot = state.controlled
    if button == JOY_BUTTON_RIGHT_SHOULDER:
        state.tool(slot)
        return
    if button == JOY_BUTTON_LEFT_SHOULDER:
        state.request_hint()
        return
    if button == JOY_BUTTON_A:
        if state.finished:
            if not recorded: save_record()
            else: next_chapter_requested.emit()
        else: state.interact(slot)

func _physics_process(dt: float) -> void:
    if not active or not session.running(): return
    presentation_clock+=dt
    var old: Array[Vector2] = state.positions.duplicate()
    var a: Vector2 = session.movement(0)
    var b: Vector2 = session.movement(1)
    if state.single:
        b = a if state.controlled == 1 else Vector2.ZERO
        a = a if state.controlled == 0 else Vector2.ZERO
    state.step(dt,a,b,true)
    if state.finished and not recorded and not completion_attempted: save_record()
    var signature := _signature()
    if signature != observed_signature:
        observed_signature = signature
        save_delay = 0
    elif signature != saved_signature:
        save_delay += dt
        if save_delay >= 0.4:
            save_delay = 0
            save_checkpoint()
    if heard != state.event_id:
        heard = state.event_id
        audio.play_story(state)
    for role in range(3):
        var change: Vector2 = state.positions[role]-old[role]
        if absf(change.x) > 0.01: faces[role] = signf(change.x)
        walk_phase[role] += change.length()*0.09
        sprites[role].update_motion(state.positions[role],dt,state.affection if role < 2 else 0)
        var face: float = faces[role]
        if role < 2 and absf(state.facing[role].x) > 0.1: face = signf(state.facing[role].x)
        if state.actions[role] == "brace": face = 1
        if role == 2 and (state.white_wait > 0 or (state.phase == "peek" and state.timer < 1.2)): face = -1
        var action:String=state.actions[role]
        var social:String=StageArt.social_kind(state,role)
        if not social.is_empty():action="sit" if social=="rest" else "pet" if role==0 else "paw" if role==1 else "sleep"
        sprites[role].show_action(action,presentation_clock,face)
        sprites[role].place_home(state.positions[role],action,dt)
        sprites[role].z_index = int(state.positions[role].y)
        sprites[role].visible = role < 2 or state.white_visible
        sprites[role].modulate.a = state.white_alpha if role == 2 else 1.0
    props[0].position = state.rug_position()+Vector2(sin(state.clock*40)*state.rug_shake*5,-84)
    props[1].position = props[0].position
    props[0].visible = state.rug_pull < 105
    props[1].visible = state.rug_pull >= 105
    props[2].position = state.ball
    props[2].rotation = state.ball_spin
    props[3].position = Story.DOOR+Vector2(37,-73) if state.wedged else state.wedge
    props[3].z_index = 700 if state.carrier >= 0 else 2
    dialogue_view.present(state,session.keyboard_mode)
    goal_label.text = state.objective()
    line_label.text = state.message if state.message_time > 0 or state.finished else ""
    controls.text = ("WASD 移动 · E 互动 · Tab/Q 换角色 · R 工具" if state.single else "朵朵 WASD / E / T 工具 · 团团 方向键 / 空格 / R 工具")+" · G 想一想 · Esc 暂停" if session.keyboard_mode else "左摇杆移动 · 面键下互动"+(" · 面键上换朵朵 / 团团" if state.single else " · 两位分别操作")+" · 右肩工具 · 左肩想一想 · 菜单键暂停"
    complete_panel.visible = state.finished
    if state.finished:
        completed_text.text = "原本准备休息的下午，\n变成了一起出发的下午。\n\n序章完成 ✓\n"+save_status+"\n\n下一关：点亮第一盏灯\n前往森林，寻找圆圆的方向。\n\n按互动键进入第一章。Esc 返回选关，可重玩序章。"
    controls.text="E 互动 · R 工具 · Tab 换角色 · H 记事 · Esc 暂停" if session.keyboard_mode else "下面键互动 · 右肩工具 · 左肩想一想"
    feedback_panel.visible=not dialogue_view.active and not line_label.text.is_empty()
    line_label.visible=feedback_panel.visible;controls.visible=feedback_panel.visible
    queue_redraw()

func _panel(rect: Rect2) -> Panel:
    var panel := Panel.new()
    panel.position = rect.position
    panel.size = rect.size
    var style := StyleBoxFlat.new()
    style.bg_color = Color("f5ead0")
    style.border_color = Color("a78b64")
    style.set_border_width_all(2)
    style.set_corner_radius_all(16)
    panel.add_theme_stylebox_override("panel",style)
    hud.add_child(panel)
    return panel
func _label(text: String, rect: Rect2, size: int, parent: Node = null) -> Label:
    var label := Label.new()
    label.text = text
    label.position = rect.position
    label.size = rect.size
    label.add_theme_font_override("font",font)
    label.add_theme_font_size_override("font_size",size)
    label.add_theme_color_override("font_color",Color("3b4e3c"))
    (parent if parent != null else hud).add_child(label)
    return label
func _text(point: Vector2, value: String, width := 160.0) -> void:
    draw_string_outline(font,point,value,HORIZONTAL_ALIGNMENT_CENTER,width,16,5,Color("f9edcf"))
    draw_string(font,point,value,HORIZONTAL_ALIGNMENT_CENTER,width,16,Color("344b3b"))
func _draw() -> void:
    draw_texture_rect(BACKDROP,Rect2(0,0,1280,800),false)
    StageArt.draw_mechanisms(self,StageArt.data(state))
    # Reveal only the actual doorway, keeping the room and its movable props stable.
    var opening: float = state.door_open
    if opening > 0:
        var dest := Rect2(1104,22,104*opening,204)
        var ratio := OPEN_BACKDROP.get_size()/Vector2(1280,800)
        draw_texture_rect_region(OPEN_BACKDROP,dest,Rect2(dest.position*ratio,dest.size*ratio))
    for slot in range(2):
        var p: Vector2 = state.positions[slot]
        var selected: bool = not state.single or state.controlled == slot
        if selected:
            # Small control indicator, never a world-object waypoint.
            draw_line(p+Vector2(-9,5),p+Vector2(9,5),Color("f8e3b4"),3,true)
        if selected and not state.finished:
            var item: String = state.target(slot)
            if not item.is_empty():
                var key := ("E" if state.single or slot == 0 else "空格") if session.keyboard_mode else "面键下"
                _text(p+Vector2(-100,29),key+" · "+item,200)
    if state.affection > 0:
        var center: Vector2 = state.positions[2] if state.actions[2] == "listen" and state.white_wait > 0 else state.positions[1]
        _text(center+Vector2(-60,-112-(1-state.affection)*20),"♡",120)
