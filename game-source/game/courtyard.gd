extends Node2D
signal next_level_requested
const Selection = preload("res://game/solo_selection.gd")
var selection = Selection.new()

const Party = preload("res://game/party_state.gd")
const Actor = preload("res://game/actor_view.gd")
const Bridge = preload("res://game/bridge_state.gd")
const BridgeView = preload("res://game/bridge_view.gd")
var bridge = Bridge.new()
var party = Party.new(bridge)
var bridge_view: Node2D
var session
var camera := Camera2D.new()
var hud := CanvasLayer.new()
var girl_label: Label
var cat_label: Label
var hint_label: Label
var objective_label: Label
var progress_label: Label
var p1_help: Label
var p2_help: Label
var pause_help: Label
var actors: Array[Node2D] = []
var font: Font
var active: bool = false

func _init(state) -> void:
    session = state

func _ready() -> void:
    font = get_parent().theme.default_font
    bridge_view = BridgeView.new(bridge)
    bridge_view.font = font
    add_child(bridge_view)
    camera.enabled = false
    camera.position = party.camera_center()
    camera.zoom = Vector2.ONE * party.camera_zoom()
    add_child(camera)
    for index in range(3):
        var actor := Actor.new()
        actor.role = index
        actor.font = font
        actor.position = party.positions[index]
        add_child(actor)
        actors.append(actor)
    add_child(hud)
    hud.layer = 10
    _build_hud()
    set_active(false)

func set_active(value: bool) -> void:
    if value and not active:
        camera.position = party.camera_center()
        camera.zoom = Vector2.ONE * party.camera_zoom()
    active = value
    visible = value
    hud.visible = value
    camera.enabled = value

func handle_action(slot: int, button: int) -> void:
    if not session.running():
        return
    if session.single_player:
        if slot != 0: return
        if button in [JOY_BUTTON_Y,JOY_BUTTON_B]:
            get_parent().router.clear_keyboard()
            session.axes[0] = Vector2.ZERO
            selection.select_next(party,button == JOY_BUTTON_B)
            return
        slot = selection.slot()
    if button == JOY_BUTTON_A:
        if bridge.finished and party.positions[0 if slot == 0 else party.current_cat].distance_to(Bridge.EXIT) <= 120:
            next_level_requested.emit()
        else:
            bridge.interact(slot, party.current_cat, party.positions)
    elif slot == 1 and button == JOY_BUTTON_Y:
        party.switch_cat()
        bridge.message = party.message
    elif slot == 1 and button == JOY_BUTTON_RIGHT_SHOULDER:
        party.toggle_hold()
        bridge.message = party.message

func restart() -> void:
    if session.running():
        return
    bridge = Bridge.new()
    bridge.solo_mode = session.single_player
    selection = Selection.new()
    party = Party.new(bridge)
    bridge_view.state = bridge
    bridge_view.queue_redraw()
    for i in range(3):
        actors[i].position = party.positions[i]
    session.pause_all("庭院已重置 · 请双方重新准备")

func _physics_process(delta: float) -> void:
    if not active or not session.running():
        return
    if session.single_player:
        party.step(delta, selection.movement(session.movement(0),0), selection.movement(session.movement(0),1), true)
    else:
        party.step(delta, session.movement(0), session.movement(1), true)
    bridge.tick(party.positions, party.current_cat)
    for i in range(3):
        actors[i].caption_visible = true
        if i > 0:
            for other in range(3):
                if other != i and party.positions[i].distance_to(party.positions[other]) < 110:
                    actors[i].caption_visible = false
        var selected: bool = i == selection.actor if session.single_player else i == 0 or i == party.current_cat
        actors[i].caption_override = ["朵朵","团团","圆圆"][i]+(" · 你控制" if selected else "") if session.single_player else ""
        actors[i].update_pose(party.positions[i], selected, party.holding[i], delta)
    var weight := 1.0 - exp(-7.0 * delta)
    camera.position = camera.position.lerp(party.camera_center(), weight)
    camera.zoom = camera.zoom.lerp(Vector2.ONE * party.camera_zoom(), weight)
    var current: String = "团团 · 黑猫哥哥" if party.current_cat == 1 else "圆圆 · 白猫弟弟"
    var follower: String = "圆圆" if party.current_cat == 1 else "团团"
    var following_status := "正在驻守" if party.holding[3 - party.current_cat] else "正在跟随"
    if bridge.unlocked < 3 and party.positions[1].x >= 1000:
        following_status = "近岸待命" if party.current_cat == 1 else "原地等候"
    cat_label.text = "P2  " + current + "    |    " + follower + following_status
    objective_label.text = "等一等伙伴，靠近后继续走" if party.edge_limited else bridge.objective()
    if bridge.finished:
        objective_label.text = "调桥完成 ✓  在出口再按互动键，前往林间空地。"
    hint_label.text = bridge.message
    if session.keyboard_mode:
        objective_label.text = objective_label.text.replace("双方按面键下方确认", "朵朵按 E、猫咪按空格确认")
        objective_label.text = objective_label.text.replace("互动键", "E / 空格")
        hint_label.text = hint_label.text.replace("按面键上方切猫", "按 Tab 切猫").replace("互动键", "空格").replace("右肩键", "R 键")
    p1_help.text = "WASD 移动 · E 互动" if session.keyboard_mode else "移动 · 面键下方互动"
    p2_help.text = "方向键移动 · 空格互动 · Tab 切猫 · R 驻守" if session.keyboard_mode else "面键下方互动 · 上方切猫 · 右肩驻守"
    pause_help.text = "Esc 暂停" if session.keyboard_mode else "菜单键暂停"
    progress_label.text = "合作调桥 / M11   卡扣 %d / 3" % bridge.unlocked
    girl_label.text = selection.title() if session.single_player else "P1  朵朵"
    if session.single_player:
        cat_label.text = "切换角色，亲自调桥与开锁"
        p1_help.text = "WASD · E 互动 · R 工具" if session.keyboard_mode else "摇杆 · 下互动 · 右肩工具"
        p2_help.text = selection.help(session.keyboard_mode)
        objective_label.text = objective_label.text.replace("双方按面键下方确认","按互动键确认").replace("朵朵按 E、猫咪按空格确认","按 E 确认").replace("E / 空格","E")
    bridge_view.highlight = -1
    if bridge.unlocked < 3:
        if party.positions[0].distance_to(Bridge.WINCH) <= 56 and bridge.deployed == bridge.unlocked:
            bridge_view.highlight = 0
        elif party.current_cat == 1 and bridge.deployed > bridge.unlocked and party.positions[1].distance_to(Bridge.LOCKS[bridge.unlocked]) <= 42:
            bridge_view.highlight = bridge.unlocked + 1
    bridge_view.queue_redraw()

func _hud_label(text: String, rect: Rect2, size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = text
    label.position = rect.position
    label.size = rect.size
    label.add_theme_font_override("font", font)
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", color)
    hud.add_child(label)
    return label

func _hud_panel(rect: Rect2) -> void:
    var panel := Panel.new()
    panel.position = rect.position
    panel.size = rect.size
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.06, 0.17, 0.13, 0.95)
    style.border_color = Color("658b70")
    style.set_border_width_all(1)
    style.set_corner_radius_all(16)
    panel.add_theme_stylebox_override("panel", style)
    hud.add_child(panel)

func _build_hud() -> void:
    var cream := Color("fff0d0")
    var mute := Color("bad2b7")
    _hud_panel(Rect2(24, 20, 1232, 104))
    _hud_label("试灯庭院", Rect2(48, 32, 210, 42), 29, cream)
    progress_label = _hud_label("", Rect2(48, 78, 270, 26), 16, mute)
    girl_label = _hud_label("P1  朵朵", Rect2(330, 38, 230, 31), 22, Color("99dbc6"))
    cat_label = _hud_label("", Rect2(588, 38, 640, 32), 21, cream)
    p1_help = _hud_label("", Rect2(330, 79, 240, 25), 16, mute)
    p2_help = _hud_label("", Rect2(588, 79, 638, 25), 16, mute)
    _hud_panel(Rect2(24, 699, 1232, 77))
    objective_label = _hud_label("", Rect2(48, 708, 940, 31), 21, cream)
    hint_label = _hud_label("", Rect2(49, 745, 990, 22), 15, mute)
    pause_help = _hud_label("", Rect2(1066, 722, 171, 30), 19, Color("efd193"))

func _draw() -> void:
    # Procedural prototype scenery; approved concept artwork remains separate.
    draw_rect(Rect2(-2000, -2000, 6000, 5000), Color("284d3a"))
    draw_rect(Party.BOUNDS.grow(28), Color("527255"))
    draw_rect(Party.BOUNDS, Color("6b8b5d"))
    var rng := RandomNumberGenerator.new()
    rng.seed = 7723
    for i in range(190):
        var p := Vector2(rng.randf_range(94, 1822), rng.randf_range(116, 1040))
        draw_line(p, p + Vector2(-4, -7), Color("7f9b68"), 2, true)
        draw_line(p, p + Vector2(3, -9), Color("587c4f"), 2, true)
    draw_line(Vector2(240, 665), Vector2(1660, 665), Color("b4b18a"), 124, true)
    draw_circle(Vector2(240, 665), 62, Color("b4b18a"))
    draw_circle(Vector2(1660, 665), 62, Color("b4b18a"))
    draw_line(Vector2(1020, 665), Vector2(1020, 270), Color("b4b18a"), 114, true)
    for x in range(280, 1660, 80):
        var stone := Rect2(x, 643 + (x % 3) * 7, 50, 29)
        draw_style_box(_stone_style(), stone)
    for y in range(300, 630, 70):
        draw_style_box(_stone_style(), Rect2(991, y, 55, 32))
    # Low fences mark the movement boundary.
    for y in [100, 1060]:
        draw_line(Vector2(80, y), Vector2(1840, y), Color("b1a87b"), 7)
        for x in range(80, 1841, 80):
            draw_line(Vector2(x, y + 7), Vector2(x, y - 29), Color("d5c393"), 10)
    for x in [80, 1840]:
        draw_line(Vector2(x, 100), Vector2(x, 1060), Color("b1a87b"), 7)
        for y in range(140, 1060, 80):
            draw_line(Vector2(x, y + 8), Vector2(x, y - 20), Color("d5c393"), 10)
    for rect in Party.OBSTACLES:
        draw_rect(Rect2(rect.position + Vector2(7, 9), rect.size), Color(0.14, 0.25, 0.15, 0.3))
        draw_style_box(_bed_style(), rect)
        for x in range(int(rect.position.x) + 25, int(rect.end.x) - 12, 38):
            for y in range(int(rect.position.y) + 25, int(rect.end.y) - 12, 38):
                draw_circle(Vector2(x, y), 18, Color("3b7453"))
                draw_circle(Vector2(x - 3, y - 4), 5, Color("e1c57d") if x % 3 == 0 else Color("cfaeae"))
    for pad in party.pads:
        draw_circle(pad, 48, Color(0.95, 0.85, 0.5, 0.12))
        draw_arc(pad, 36, 0, TAU, 48, Color("f0d58c"), 3, true)
        draw_circle(pad + Vector2(0, 5), 10, Color("efdb9e"))
        for offset in [Vector2(-14, -7), Vector2(-5, -14), Vector2(6, -14), Vector2(15, -6)]:
            draw_circle(pad + offset, 4.5, Color("efdb9e"))
        if font:
            draw_string(font, pad + Vector2(-55, 65), "驻守脚印", HORIZONTAL_ALIGNMENT_CENTER, 110, 17, Color("fff0cb"))
    # A sign and lantern give the empty movement yard a clear destination.
    draw_line(Vector2(1150, 306), Vector2(1150, 224), Color("725b3f"), 8)
    draw_rect(Rect2(1095, 219, 110, 42), Color("bead7a"))
    if font:
        draw_string(font, Vector2(1096, 248), "试灯小院", HORIZONTAL_ALIGNMENT_CENTER, 108, 18, Color("385343"))
    for point in [Vector2(250, 585), Vector2(1640, 575)]:
        draw_line(point, point + Vector2(0, -83), Color("6c5a3e"), 7)
        draw_circle(point + Vector2(0, -85), 29, Color(1, 0.86, 0.45, 0.15))
        draw_rect(Rect2(point + Vector2(-11, -102), Vector2(22, 29)), Color("f3d782"))

func _stone_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color("c8c6a5")
    style.border_color = Color("9eaa84")
    style.set_border_width_all(2)
    style.set_corner_radius_all(10)
    return style

func _bed_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color("456c46")
    style.border_color = Color("c2b18b")
    style.set_border_width_all(8)
    style.set_corner_radius_all(18)
    return style
