extends Node2D
signal checkpoint_requested
const Selection = preload("res://game/solo_selection.gd")
var selection = Selection.new()
const Rest = preload("res://game/rest_state.gd")
const Actor = preload("res://game/actor_view.gd")
var state = Rest.new()
var session
var active := false
var can_save := false
var reported := false
var save_status := "单独试玩 · 不覆盖上次旅程"
var font: Font
var camera := Camera2D.new()
var hud := CanvasLayer.new()
var actors: Array[Node2D] = []
const Prop = preload("res://game/storybook_prop.gd")
const BACKDROP = preload("res://assets/visual-m14/arena-painted.png")
var presentation_clock := 0.0
var ending_card: Panel
var ending_title: Label
var ending_body: Label
var ending_hint: Label
var journey_board: Node2D
var status_label: Label
var p1_label: Label
var p2_label: Label
var p1_help: Label
var p2_help: Label
var objective_label: Label
var dialogue_label: Label
func _init(value) -> void:
    session = value
func _ready() -> void:
    font = get_parent().theme.default_font
    camera.enabled = false
    camera.position = Vector2(640, 400)
    add_child(camera)
    for i in range(3):
        var view := Actor.new()
        view.role = i
        view.storybook = true
        view.social_visual = true
        view.font = font
        view.position = state.positions[i]
        add_child(view)
        actors.append(view)
    _build_art()
    hud.layer = 13
    add_child(hud)
    _panel(Rect2(24, 20, 1232, 124))
    _label("林边休息处", Rect2(48, 34, 268, 38), 28)
    status_label = _label("", Rect2(48, 83, 278, 48), 16)
    p1_label = _label("", Rect2(360, 34, 380, 38), 23, Color("346857"))
    p2_label = _label("", Rect2(784, 34, 440, 38), 23)
    p1_help = _label("", Rect2(360, 83, 400, 48), 17)
    p2_help = _label("", Rect2(784, 83, 435, 48), 17)
    _panel(Rect2(24, 685, 1232, 91))
    objective_label = _label("", Rect2(48, 697, 1170, 32), 21)
    dialogue_label = _label("", Rect2(48, 738, 1170, 27), 16, Color("647253"))
    _build_ending()
    set_active(false)
    _refresh()
func set_active(value: bool) -> void:
    active = value
    visible = value
    hud.visible = value
    camera.enabled = value
func restore(data: Dictionary) -> void:
    state = Rest.new()
    state.solo_mode = session.single_player
    selection = Selection.new()
    state.restore(data)
    can_save = true
    reported = true
    save_status = "已回到记录的休息点"
    _refresh()
func handle_action(slot: int, button: int) -> void:
    if not session.running(): return
    if session.single_player:
        if slot != 0: return
        if button in [JOY_BUTTON_Y,JOY_BUTTON_B]:
            get_parent().router.clear_keyboard()
            session.axes[0] = Vector2.ZERO
            selection.select_next(state,button == JOY_BUTTON_B)
            return
        slot = selection.slot()
    if button == JOY_BUTTON_A and state.finished:
        session.pause_all("试玩完成 · 可以重玩庭院或返回入口")
        return
    if button == JOY_BUTTON_A:
        state.interact(slot)
    elif slot == 1 and button == JOY_BUTTON_Y:
        state.switch_cat()
    _report_rest()
func _report_rest() -> void:
    if state.rested and not reported:
        reported = true
        if can_save:
            checkpoint_requested.emit()
func _physics_process(delta: float) -> void:
    if not active or not session.running(): return
    presentation_clock += maxf(0,delta)
    if session.single_player:
        state.step(delta, selection.movement(session.movement(0),0), selection.movement(session.movement(0),1), true)
    else:
        state.step(delta, session.movement(0), session.movement(1), true)
    _report_rest()
    for i in range(3):
        var selected: bool = i == selection.actor if session.single_player else i == 0 or i == state.current_cat
        actors[i].caption_override = ["朵朵","团团","圆圆"][i]+(" · 你控制" if selected else "") if session.single_player else ""
        actors[i].caption_visible = selected
        var moving: bool = actors[i].position.distance_to(state.positions[i]) > 0.1
        var sitting: bool = state.sitting[0 if i == 0 else 1] and not moving
        var petting: bool = (state.pet_cooldown > 0 and (i == 0 or i == state.reaction_cat)) or (state.greet_cooldown > 0 and i == state.reaction_cat)
        actors[i].social_kind = "pet" if petting and not moving else "rest" if sitting else ""
        actors[i].presentation_clock = presentation_clock
        if petting and i == 0: actors[i].facing = 1 if state.positions[state.reaction_cat].x >= state.positions[0].x else -1
        actors[i].update_pose(state.positions[i], selected, false, delta)
    _refresh()
func _refresh() -> void:
    if not is_instance_valid(status_label): return
    status_label.text = save_status + "\nEsc / 菜单键暂停"
    p1_label.text = "P1 朵朵   " + "●".repeat(state.hp[0]) + "○".repeat(3-state.hp[0])
    p2_label.text = "P2 " + ("团团" if state.current_cat == 1 else "圆圆") + "   " + "●".repeat(state.hp[1]) + "○".repeat(3-state.hp[1])
    p1_help.text = "WASD 移动 · E 坐下 / 摸猫\n出口 E 确认离开" if session.keyboard_mode else "左摇杆移动 · 面键下坐下 / 摸猫\n出口面键下确认离开"
    p2_help.text = "方向键移动 · 空格坐下 / 碰爪\nTab 切猫 · 出口空格确认" if session.keyboard_mode else "左摇杆移动 · 面键下坐下 / 碰爪\n面键上切猫 · 出口面键下确认"
    if state.finished:
        objective_label.text = "庭院试玩完成 ✓ 三位一起走到了最后。" if state.full_run() else "休息点体验完成 ✓ 可以回准备室体验其他关卡。"
    elif state.rested:
        objective_label.text = "体力恢复了。可以摸摸猫；三位到右侧出口，双方确认结束试玩。"
    else:
        objective_label.text = "到长椅边集合，两位分别互动坐下：%s / %s" % ["朵朵已准备" if state.ready[0] else "朵朵待准备", "猫咪已准备" if state.ready[1] else "猫咪待准备"]
    if session.single_player:
        p1_label.text = selection.title()
        p2_label.text = "朵朵与双猫 · 一起休息"
        p1_help.text = "WASD 移动 · E 坐下 / 摸猫" if session.keyboard_mode else "摇杆移动 · 面键下坐下 / 摸猫"
        p2_help.text = selection.help(session.keyboard_mode)+"\n三位到齐后，互动一次即可"
        if not state.rested: objective_label.text = "三位到长椅边集合，再按互动键一起休息" + ("并保存。" if can_save else "。")
        elif not state.finished: objective_label.text = "体力恢复了。可以摸摸猫；三位到右侧出口，互动一次结束试玩。"
    ending_card.visible = state.finished
    if state.finished:
        ending_title.text = "一起把这段路点亮了" if state.full_run() else "歇好脚，再一起出发"
        ending_body.text = ("合作调桥  ✓  林间战斗  ✓  双猫灯廊  ✓\n"+("风铃门 ✓" if state.progress.has("gate") else "旧版旅程 · 风铃门未记录")+"\n\n朵朵、团团、圆圆，一个也没落下。") if state.full_run() else "休息点体验完成。\n\n回到准备室，可以从庭院入口开始完整旅程。"
        ending_hint.text = ("E / 空格：回到菜单" if session.keyboard_mode else "面键下：回到菜单") + "   ·   Esc / 菜单键：暂停"
    dialogue_label.text = state.message
    journey_board.progress = state.progress
    journey_board.queue_redraw()
    queue_redraw()
func _panel(rect: Rect2) -> void:
    var panel := Panel.new()
    panel.position = rect.position
    panel.size = rect.size
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.98,0.94,0.80,0.98)
    style.border_color = Color("bca876")
    style.set_border_width_all(1)
    style.set_corner_radius_all(16)
    panel.add_theme_stylebox_override("panel", style)
    hud.add_child(panel)
func _label(text: String, rect: Rect2, size: int, color := Color("3c4938")) -> Label:
    var label := Label.new()
    label.text = text
    label.position = rect.position
    label.size = rect.size
    label.add_theme_font_override("font", font)
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", color)
    hud.add_child(label)
    return label
func _text(point: Vector2, text: String, width: float, size := 18) -> void:
    if font: draw_string(font, point, text, HORIZONTAL_ALIGNMENT_CENTER, width, size, Color("fff0d0"))
func _draw() -> void:
    draw_rect(Rect2(-800,-800,3000,2500),Color("294938"))
    draw_texture_rect(BACKDROP,Rect2(0,0,1280,800),false)
    # Wide bench and picnic mat provide a clear shared gathering place.
    draw_circle(Rest.BENCH, 102, Color(0.96, 0.87, 0.62, 0.1))
    draw_arc(Rest.BENCH, 102, 0, TAU, 64, Color("e0d3a0"), 2, true)
    draw_rect(Rect2(545, 498, 215, 57), Color("cfb88c"))
    for x in range(551, 759, 23): draw_line(Vector2(x, 500), Vector2(x, 553), Color("ad9877"), 2)
    _text(Vector2(490, 233), "正事做完，认真休息", 320, 23)
    draw_arc(Rest.EXIT, 73, 0, TAU, 48, Color("e9d598") if state.rested else Color("87a17a"), 3, true)
    _text(Vector2(1025, 322), "出口 →", 150, 21)
    _text(Vector2(1015, 571), "三位一起离开", 170, 18)
    if state.rested:
        _text(Vector2(1015, 602), "%s / %s" % ["朵朵 ✓" if state.confirmed[0] else "朵朵", "猫咪 ✓" if state.confirmed[1] else "猫咪"], 170, 16)
    if state.pet_cooldown > 0 or state.greet_cooldown > 0:
        var p: Vector2 = state.positions[state.reaction_cat] + Vector2(0,-110)
        draw_circle(p + Vector2(-5,0), 6, Color("e8baab"))
        draw_circle(p + Vector2(5,0), 6, Color("e8baab"))
        draw_colored_polygon(PackedVector2Array([p+Vector2(-10,2),p+Vector2(10,2),p+Vector2(0,14)]), Color("e8baab"))

func _build_art() -> void:
    journey_board = preload("res://game/rest_journey_board.gd").new()
    journey_board.font = font
    journey_board.position = Vector2(260,460)
    journey_board.z_index = 239
    add_child(journey_board)
    var bench := Prop.make(3,Vector2(284,168))
    bench.position = Vector2(650,425)
    bench.z_index = 239
    add_child(bench)
    var post := Prop.make(5,Vector2(42,102))
    post.position = Vector2(1140,385)
    post.z_index = 239
    add_child(post)
func _build_ending() -> void:
    ending_card = Panel.new()
    ending_card.position = Vector2(372,237)
    ending_card.size = Vector2(536,368)
    var paper := StyleBoxFlat.new()
    paper.bg_color = Color("f5e6bd")
    paper.border_color = Color("b3965b")
    paper.set_border_width_all(3)
    paper.set_corner_radius_all(20)
    paper.shadow_color = Color(0.08,0.14,0.10,0.4)
    paper.shadow_size = 16
    ending_card.add_theme_stylebox_override("panel",paper)
    hud.add_child(ending_card)
    ending_title = _ending_label(Rect2(20,30,496,40),29,Color("375543"))
    var line := _ending_label(Rect2(20,91,496,35),21,Color("82653c"))
    line.text = "朵朵  ·  团团  ·  圆圆"
    ending_body = _ending_label(Rect2(24,150,488,103),18,Color("576348"))
    ending_hint = _ending_label(Rect2(15,304,506,40),16,Color("796441"))
    ending_card.visible = false
func _ending_label(rect: Rect2, size: int, color: Color) -> Label:
    var label := Label.new()
    label.position = rect.position
    label.size = rect.size
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_override("font",font)
    label.add_theme_font_size_override("font_size",size)
    label.add_theme_color_override("font_color",color)
    ending_card.add_child(label)
    return label
