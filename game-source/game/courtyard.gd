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
var garden := preload("res://game/garden_view.gd").new()
var audio := preload("res://game/garden_audio.gd").new()
var seen_deployed := 0
var seen_unlocked := 0
var seen_finished := false

func _init(state) -> void:
    session = state

func _ready() -> void:
    font = get_parent().theme.default_font
    garden.party = party
    garden.font = font
    add_child(garden)
    add_child(audio)
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
        actor.storybook = true
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
    if not value: audio.silence()

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
            if bridge.interact(slot, party.current_cat, party.positions):
                actors[0 if slot == 0 else party.current_cat].reaction = 1.0
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
    bridge_view.displayed = [0.0,0.0,0.0]
    bridge_view.last_unlocked = 0
    bridge_view.burst = 0.0
    garden.party = party
    seen_deployed = 0
    seen_unlocked = 0
    seen_finished = false
    bridge_view.queue_redraw()
    for i in range(3):
        actors[i].position = party.positions[i]
    session.pause_all("庭院已重置 · 请双方重新准备")

func _physics_process(delta: float) -> void:
    if not active or not session.running():
        audio.silence()
        return
    garden.advance(delta)
    bridge_view.keyboard = session.keyboard_mode
    bridge_view.solo = session.single_player
    bridge_view.advance(delta)
    if bridge.finished and not seen_finished:
        audio.play(2)
    elif bridge.unlocked > seen_unlocked:
        audio.play(1)
    elif bridge.deployed > seen_deployed:
        audio.play(0)
    seen_finished = bridge.finished
    seen_unlocked = bridge.unlocked
    seen_deployed = bridge.deployed
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
        if selected: actors[i].caption_visible = true
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
    progress_label.text = "序章 · 合作调桥    %d / 3" % bridge.unlocked
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
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.98, 0.94, 0.80, 0.97)
    style.border_color = Color("b99a62")
    style.set_border_width_all(2)
    style.set_corner_radius_all(15)
    style.shadow_color = Color(0.05,0.12,0.07,0.25)
    style.shadow_size = 5
    style.shadow_offset = Vector2(0,3)
    panel.add_theme_stylebox_override("panel", style)
    hud.add_child(panel)

func _build_hud() -> void:
    var ink := Color("324d40")
    var mute := Color("6f7458")
    _hud_panel(Rect2(24,20,305,86))
    _hud_label("试灯庭院",Rect2(45,29,255,38),27,ink)
    progress_label = _hud_label("",Rect2(46,72,264,24),16,mute)
    _hud_panel(Rect2(718,20,538,86))
    girl_label = _hud_label("",Rect2(740,29,390,30),20,Color("26736a"))
    cat_label = _hud_label("",Rect2(740,69,496,28),17,ink)
    var sound := Button.new()
    sound.text = "音效 开"
    sound.position = Vector2(1155,34)
    sound.size = Vector2(82,29)
    sound.add_theme_font_size_override("font_size",15)
    sound.add_theme_font_override("font",font)
    var sound_style := StyleBoxFlat.new()
    sound_style.bg_color = Color("355e4e")
    sound_style.set_corner_radius_all(8)
    sound.add_theme_stylebox_override("normal",sound_style)
    sound.add_theme_stylebox_override("hover",sound_style)
    sound.pressed.connect(func():
        audio.muted = not audio.muted
        audio.silence()
        sound.text = "音效 关" if audio.muted else "音效 开"
        sound.release_focus())
    hud.add_child(sound)
    _hud_panel(Rect2(24,674,1232,104))
    objective_label = _hud_label("",Rect2(46,685,1090,31),21,ink)
    hint_label = _hud_label("",Rect2(46,722,1030,23),16,mute)
    p1_help = _hud_label("",Rect2(46,752,312,22),14,Color("35776d"))
    p2_help = _hud_label("",Rect2(382,752,740,22),14,mute)
    pause_help = _hud_label("",Rect2(1130,746,115,23),16,ink)
