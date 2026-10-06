extends Node2D
signal next_chapter_requested
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
var audio := preload("res://game/garden_audio.gd").new()
var heard := -1
var recorded := false
var save_status := ""
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
    _panel(Rect2(24,18,590,83))
    _label("序章 · 今天明明准备什么都不干",Rect2(44,25,550,32),23)
    goal_label = _label("",Rect2(44,61,550,27),17)
    _panel(Rect2(24,692,1232,90))
    line_label = _label("",Rect2(44,700,1180,42),18)
    line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    controls = _label("",Rect2(44,750,1160,26),16)
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
    save_status = ""
    heard = -1
    if resume:
        var record := read_record()
        if record.get("completed",false):
            state.phase = "complete"
            state.finished = true
            state.extras = record.get("extras",{})
            state.door_open = 1
            state.rug_pull = 115
            state.white_visible = false
            recorded = true
            save_status = "已恢复序章通关记录"
    if complete_panel: complete_panel.visible = state.finished

func record_path() -> String:
    return "user://"+record_prefix+("-solo-v1.json" if state.single else "-dual-v1.json")
func read_record() -> Dictionary:
    if not FileAccess.file_exists(record_path()): return {}
    var data = JSON.parse_string(FileAccess.get_file_as_string(record_path()))
    if not data is Dictionary or data.get("version") != 1 or data.get("chapter") != "prologue" or data.get("completed") != true: return {}
    if not data.get("extras",{}) is Dictionary: return {}
    return data
func save_record() -> void:
    var file := FileAccess.open(record_path(),FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify({"version":1,"chapter":"prologue","completed":true,"extras":state.extras}))
        file.close()
        save_status = "序章进度已记录"
        recorded = true
    else: save_status = "本次通关完成，进度暂未写入 · 可稍后重试"

func set_active(value: bool) -> void:
    active = value
    visible = value
    hud.visible = value
    camera.enabled = value
    if not value: audio.silence()

func handle_action(slot: int, button: int) -> void:
    if not session.running(): return
    if button == JOY_BUTTON_RIGHT_SHOULDER:
        state.request_hint()
        return
    if state.single:
        if slot != 0: return
        if button in [JOY_BUTTON_Y,JOY_BUTTON_B]:
            get_parent().router.clear_keyboard()
            state.switch_actor()
            return
        slot = state.controlled
    if button == JOY_BUTTON_A:
        if state.finished:
            if not recorded: save_record()
            else: next_chapter_requested.emit()
        else: state.interact(slot)

func _physics_process(dt: float) -> void:
    if not active or not session.running(): return
    var old: Array[Vector2] = state.positions.duplicate()
    var a: Vector2 = session.movement(0)
    var b: Vector2 = session.movement(1)
    if state.single:
        b = a if state.controlled == 1 else Vector2.ZERO
        a = a if state.controlled == 0 else Vector2.ZERO
    state.step(dt,a,b,true)
    if state.finished and not recorded and save_status.is_empty(): save_record()
    if heard != state.event_id:
        heard = state.event_id
        audio.play(state.cue)
    for role in range(3):
        var change: Vector2 = state.positions[role]-old[role]
        if absf(change.x) > 0.01: faces[role] = signf(change.x)
        walk_phase[role] += change.length()*0.09
        sprites[role].update_motion(state.positions[role],dt,state.affection if role < 2 else 0)
        var face: float = faces[role]
        if role < 2 and absf(state.facing[role].x) > 0.1: face = signf(state.facing[role].x)
        if state.actions[role] == "brace": face = 1
        if role == 2 and (state.white_wait > 0 or (state.phase == "peek" and state.timer < 1.2)): face = -1
        sprites[role].show_action(state.actions[role],state.clock,face)
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
    goal_label.text = state.objective()
    line_label.text = state.message if state.message_time > 0 or state.finished else ""
    controls.text = ("WASD 移动 · E 互动 · Tab 换朵朵 / 团团" if state.single else "朵朵 WASD / E · 团团 方向键 / 空格")+" · R 想一想 · Esc 暂停" if session.keyboard_mode else "左摇杆移动 · 面键下互动"+(" · 面键上换朵朵 / 团团" if state.single else " · 两位分别操作")+" · 右肩想一想 · 菜单键暂停"
    complete_panel.visible = state.finished
    if state.finished:
        completed_text.text = "原本准备休息的下午，\n变成了一起出发的下午。\n\n序章完成 ✓\n"+save_status+"\n\n下一关：点亮第一盏灯\n前往森林，寻找圆圆的方向。\n\n按互动键进入第一章。Esc 返回选关，可重玩序章。"
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
