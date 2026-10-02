extends Node2D
signal next_level_requested
const Chime = preload("res://game/chime_state.gd")
const Selection = preload("res://game/solo_selection.gd")
const Actor = preload("res://game/actor_view.gd")
const BACKDROP = preload("res://assets/visual-m14/arena-painted.png")
var puzzle = Chime.new()
var selection = Selection.new()
var session
var active := false
var camera := Camera2D.new()
var hud := CanvasLayer.new()
var actors: Array[Node2D] = []
var font: Font
var title_label: Label
var help_label: Label
var objective_label: Label
var hint_label: Label
var audio := preload("res://game/garden_audio.gd").new()
var heard_revision := 0
var clock := 0.0
var opening := 0.0
var reveal := 0.0

func _init(state) -> void:
    session = state

func _ready() -> void:
    font = get_parent().theme.default_font
    camera.position = Vector2(640,400)
    camera.enabled = false
    add_child(camera)
    add_child(audio)
    for i in range(3):
        var actor = Actor.new()
        actor.role = i
        actor.font = font
        actor.storybook = true
        actor.social_visual = true
        add_child(actor)
        actors.append(actor)
    hud.layer = 12
    add_child(hud)
    _panel(Rect2(24,16,1232,68))
    title_label = _label("风铃门",Rect2(42,23,280,30),25)
    help_label = _label("",Rect2(330,26,870,36),17)
    _panel(Rect2(24,698,1232,78))
    objective_label = _label("",Rect2(42,706,1200,27),20)
    hint_label = _label("",Rect2(42,744,1200,24),16)
    var hint := Button.new()
    hint.text = "需要一点提示"
    hint.position = Vector2(1040,650)
    hint.add_theme_font_override("font",font)
    hint.pressed.connect(func(): puzzle.request_hint(); _refresh())
    hud.add_child(hint)
    set_active(false)
    _refresh()

func set_active(value: bool) -> void:
    active = value
    visible = value
    hud.visible = value
    camera.enabled = value
    if not value: audio.silence()

func restart() -> void:
    var health: Array[int] = puzzle.hp.duplicate()
    puzzle = Chime.new()
    puzzle.hp = health
    puzzle.solo_mode = session.single_player
    selection = Selection.new()
    opening = 0
    reveal = 0
    heard_revision = 0
    _refresh()

func handle_action(slot: int, button: int) -> void:
    if not session.running(): return
    if session.single_player:
        if slot != 0: return
        if button in [JOY_BUTTON_Y,JOY_BUTTON_B]:
            get_parent().router.clear_keyboard()
            session.axes[0] = Vector2.ZERO
            selection.select_next(puzzle,button == JOY_BUTTON_B)
            return
        slot = selection.slot()
    elif slot == 1 and button == JOY_BUTTON_Y:
        puzzle.switch_cat()
        return
    if button == JOY_BUTTON_LEFT_SHOULDER:
        puzzle.request_hint()
    elif button == JOY_BUTTON_RIGHT_SHOULDER:
        puzzle.tool(slot)
    elif button == JOY_BUTTON_A:
        if puzzle.finished:
            if puzzle.party_ready():
                next_level_requested.emit()
            else:
                var missing: Array[String] = []
                for i in range(3):
                    if puzzle.positions[i].distance_to(Chime.EXIT) >= 120: missing.append(["朵朵","团团","圆圆"][i])
                puzzle.message = "门口还少了"+"、".join(missing)+"。一起走吧。"
        else: puzzle.interact(slot)
    _refresh()

func _physics_process(dt: float) -> void:
    if not active or not session.running(): return
    clock += dt
    opening = move_toward(opening,1 if puzzle.finished else 0,dt*1.5)
    reveal = move_toward(reveal,1 if puzzle.stage == 2 else 0,dt*1.5)
    puzzle.step(dt,selection.movement(session.movement(0),0) if session.single_player else session.movement(0),selection.movement(session.movement(0),1) if session.single_player else session.movement(1),true)
    if heard_revision != puzzle.revision:
        audio.play(2 if puzzle.last_event == "bell" else 1)
        heard_revision = puzzle.revision
    for i in range(3):
        var selected: bool = i == selection.actor if session.single_player else i == 0 or i == puzzle.current_cat
        actors[i].caption_visible = selected
        actors[i].caption_override = ["朵朵","团团","圆圆"][i]+(" · 你控制" if selected and session.single_player else "")
        actors[i].presentation_clock = clock
        actors[i].social_kind = "lamp" if i == 2 and puzzle.lens_site >= 0 else ""
        actors[i].update_pose(puzzle.positions[i],selected,i == 2 and puzzle.lens_site >= 0,dt)
    _refresh()

func _refresh() -> void:
    if not is_instance_valid(title_label): return
    title_label.text = "风铃门 · "+("已开门" if puzzle.finished else "寻光")
    help_label.text = "E 转手柄 · R 猫咪工具 · Tab 切猫 · G 提示" if session.keyboard_mode else "下互动 · 右肩工具 · 上切猫 · 左肩提示"
    if session.single_player: help_label.text = selection.title()+" · "+("E 互动 · R 工具 · Tab / Q 换角色 · G 提示" if session.keyboard_mode else "下互动 · 右肩工具 · 上 / 右换角色 · 左肩提示")
    objective_label.text = puzzle.objective()
    hint_label.text = puzzle.message
    queue_redraw()

func _panel(rect: Rect2) -> void:
    var panel := Panel.new()
    panel.position = rect.position
    panel.size = rect.size
    var style := StyleBoxFlat.new()
    style.bg_color = Color("f4e9cf")
    style.set_corner_radius_all(14)
    panel.add_theme_stylebox_override("panel",style)
    hud.add_child(panel)

func _label(text: String, rect: Rect2, size: int) -> Label:
    var label := Label.new()
    label.text = text
    label.position = rect.position
    label.size = rect.size
    label.add_theme_font_override("font",font)
    label.add_theme_font_size_override("font_size",size)
    label.add_theme_color_override("font_color",Color("3a5547"))
    hud.add_child(label)
    return label

func _text(point: Vector2,text: String,width: float,size: int = 16) -> void:
    draw_string(font,point,text,HORIZONTAL_ALIGNMENT_CENTER,width,size,Color("fff0ce"))

func _draw() -> void:
    draw_texture_rect(BACKDROP,Rect2(0,0,1280,800),false)
    draw_rect(Rect2(120,190,860,440),Color(0.23,0.25,0.14,0.35))
    # All optics sit on a raised rail; the walking space below remains clear.
    var height := Vector2(0,65)
    for ray in puzzle.rays:
        draw_line(ray.from-height,ray.to-height,Color(1,0.86,0.43,0.24),10,true)
        draw_line(ray.from-height,ray.to-height,Color("ffe7a0"),3,true)
    var blend: float = puzzle.board_blend()
    for i in [0,2]:
        draw_line(Chime.MIRRORS[i],puzzle.mirror_points()[i],Color("807350"),5,true)
    if puzzle.stage == 2:
        draw_line(Vector2(180,400)-height,Vector2(180,500)-height,Color("8d815e"),8,true)
    var source: Vector2 = Chime.SOURCE.lerp(puzzle.source_point(),blend)-height
    draw_circle(source,18,Color("efd16e"))
    draw_arc(source,26,0,TAU,32,Color("ffedac"),2,true)
    if puzzle.stage == 2:
        draw_line(source+Vector2(-21,0),source+Vector2(-36,12),Color("d7b96f"),5,true)
        if puzzle.positions[0].distance_to(puzzle.source_point()) < 120:
            _text(source+Vector2(-65,45),"调灯高低",130,17)
    for i in range(3):
        var p: Vector2 = Chime.MIRRORS[i].lerp(puzzle.mirror_points()[i],blend)-height
        draw_line(p+height-Vector2(0,6),p,Color("806b4c"),10,true)
        draw_circle(p,30,Color("5c796e"))
        var d := Vector2(20,-20) if int(puzzle.mirrors[i]) == 0 else Vector2(20,20)
        draw_line(p-d,p+d,Color("ccece1"),9,true)
        if i == 1:
            draw_arc(p+Vector2(0,-40),9,0,TAU,20,Color("d7b96f"),3,true)
        else:
            draw_line(p+Vector2(30,0),p+Vector2(47,0),Color("d7b96f"),5,true)
        _text(p+Vector2(-50,46),"扣环" if i == 1 else "手柄",100,16)
    for i in range(2):
        var p: Vector2 = Chime.SOCKETS[i].lerp(puzzle.socket_points()[i],blend)-height
        draw_line(p,p+height-Vector2(0,7),Color("867a55"),7,true)
        draw_arc(p+height-Vector2(0,8),25,0,TAU,32,Color("b5bf98"),3,true)
        draw_circle(p,21,Color("9caa88") if puzzle.lens_site != i else Color("ebd778"))
        draw_polygon(PackedVector2Array([p+Vector2(0,-18),p+Vector2(15,0),p+Vector2(0,18),p+Vector2(-15,0)]),PackedColorArray([Color("ccebd7")]))
        _text(p+Vector2(-58,39),"水晶底座",116,15)
    for i in range(2):
        var p: Vector2 = Chime.BELLS[i].lerp(puzzle.bell_points()[i],blend)-height
        var swinging := sin(clock*14)*0.15 if puzzle.receivers[i] else 0.0
        draw_set_transform(p,swinging)
        draw_line(Vector2(0,-31),Vector2(0,-15),Color("c9bd91"),3,true)
        draw_polygon(PackedVector2Array([Vector2(-19,14),Vector2(-12,-12),Vector2(12,-12),Vector2(19,14)]),PackedColorArray([Color("f3d47d") if puzzle.receivers[i] else Color("a49d7b")]))
        draw_circle(Vector2(0,18),4,Color("d7ad58"))
        if puzzle.stage == 2:
            var window := Vector2(29,0) if i == 0 else Vector2(0,29)
            draw_arc(Vector2.ZERO,26,window.angle()+0.6,window.angle()+TAU-0.6,28,Color("747c6a"),5,true)
            draw_circle(window,8,Color("faedb3"))
            var toward: Vector2 = -window.normalized()
            var tip := window+toward*5
            draw_line(window-toward*18,tip,Color("ffdb70"),3,true)
            draw_line(tip,tip-toward.rotated(0.65)*9,Color("ffdb70"),3,true)
            draw_line(tip,tip-toward.rotated(-0.65)*9,Color("ffdb70"),3,true)
        if puzzle.receivers[i]: draw_arc(Vector2.ZERO,34,0.2,2.8,24,Color("fff0a0"),2,true)
        if i == 1 and reveal < 1: draw_rect(Rect2(-30,-35,60,70*(1-reveal)),Color("6c836e"))
        draw_set_transform(Vector2.ZERO)
    var door := Chime.EXIT-height
    draw_rect(Rect2(door-Vector2(48,85),Vector2(96,150)),Color("685b44"),false,10)
    for side in [-1,1]:
        draw_rect(Rect2(door+Vector2(side*opening*52-44 if side < 0 else side*opening*52, -80),Vector2(44,140)),Color("a29069"))
    if puzzle.finished: _text(Chime.EXIT+Vector2(-85,44),"门开了",170,20)
