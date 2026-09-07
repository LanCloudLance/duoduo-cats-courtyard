extends Control

const Session = preload("res://input/session_state.gd")
const Router = preload("res://input/event_router.gd")
const Stick = preload("res://ui/stick_indicator.gd")
const Courtyard = preload("res://game/courtyard.gd")
const Arena = preload("res://game/arena.gd")
const LightCorridor = preload("res://game/light_corridor.gd")
const RestArea = preload("res://game/rest_area.gd")
const Checkpoint = preload("res://game/checkpoint.gd")
const TEAM = preload("res://assets/team.png")
const CREAM := Color("f6eedc")
const MUTE := Color("a8b9ad")
const GOLD := Color("e9c981")
var session = Session.new()
var router = Router.new(session)
var devices_text: Array[Label] = []
var ready_text: Array[Label] = []
var action_text: Array[Label] = []
var vector_text: Array[Label] = []
var sticks: Array[Control] = []
var top_status: Label
var footer_status: Label
var last_buttons: Array[int] = [-1, -1]
var courtyard: Node2D
var arena: Node2D
var light_corridor: Node2D
var rest_area: Node2D
var checkpoint = Checkpoint.new()
var solo_checkpoint = Checkpoint.new("user://courtyard-solo-safe-v1.json")
var solo_resume_button: Button
var resume_button: Button
var stage := "bridge"
var preview_run := false
var web_pause_callback: JavaScriptObject
var web_probe_clock := 0.0
var menu_index := -1
var menu_controls: Array[Button] = []
var mode_help: Label
var claim_buttons: Array[Button] = []
var slot_titles: Array[Label] = []
var slot_badges: Array[Label] = []
var slot_details: Array[Label] = []

func _ready() -> void:
    Input.ignore_joypad_on_unfocused_application = true
    var system_font := SystemFont.new()
    system_font.font_names = PackedStringArray(["Microsoft YaHei", "PingFang SC", "Noto Sans CJK SC"])
    var theme_value := Theme.new()
    theme_value.default_font = load("res://assets/fonts/CourtyardSans.ttf") if OS.has_feature("web") else system_font
    theme_value.default_font_size = 20
    theme = theme_value
    _build()
    courtyard = Courtyard.new(session)
    courtyard.name = "Courtyard"
    add_child(courtyard)
    arena = Arena.new(session)
    arena.name = "Arena"
    add_child(arena)
    light_corridor = LightCorridor.new(session)
    light_corridor.name = "LightCorridor"
    add_child(light_corridor)
    rest_area = RestArea.new(session)
    rest_area.name = "RestArea"
    add_child(rest_area)
    courtyard.next_level_requested.connect(enter_combat)
    arena.next_level_requested.connect(enter_light)
    light_corridor.next_level_requested.connect(enter_rest)
    rest_area.checkpoint_requested.connect(_save_checkpoint)
    router.action_pressed.connect(_action)
    router.action_released.connect(func(slot, button):
        if stage == "combat": arena.release_action(slot, button)
    )
    router.actions_cancelled.connect(func(): arena.cancel_inputs())
    Input.joy_connection_changed.connect(_connection_changed)
    if not OS.has_feature("web") and checkpoint.path == "user://courtyard-safe-v1.json":
        var legacy: Array = []
        for version in ["M10","M9","M8","M7","M6"]:
            legacy.append(OS.get_data_dir().path_join("Godot/app_userdata/朵朵与猫猫 · 庭院试玩 "+version+"/courtyard-safe-v1.json"))
        checkpoint.import_legacy(legacy)
    _refresh_checkpoint_button()
    print("CONNECTED GAMEPADS: ", Input.get_connected_joypads())
    var web_solo := false
    if OS.has_feature("web"):
        web_solo = str(JavaScriptBridge.eval("window.location.search",true)).contains("mode=solo")
        web_pause_callback = JavaScriptBridge.create_callback(func(_args):
            router.clear_keyboard()
            session.pause_all("已暂停 · 点回游戏后按 Enter 或菜单键继续")
        )
        JavaScriptBridge.get_interface("window").duoduoPause = web_pause_callback
        print("WEB_READY solo=",web_solo," persistent=",OS.is_userfs_persistent()," userdir=",OS.get_user_data_dir())
    if web_solo or "--solo-journey" in OS.get_cmdline_user_args():
        start_journey(true)
    elif "--solo-combat-preview" in OS.get_cmdline_user_args():
        start_solo_combat()
    elif "--combat-preview" in OS.get_cmdline_user_args():
        leave_solo()
        preview_run = true
        enter_combat()
        router.start_keyboard()
    elif "--light-preview" in OS.get_cmdline_user_args():
        leave_solo()
        preview_run = true
        enter_light()
        router.start_keyboard()
    elif "--rest-preview" in OS.get_cmdline_user_args():
        leave_solo()
        preview_run = true
        enter_rest()
        router.start_keyboard()

func _panel(rect: Rect2, color: Color, line: Color, radius: int = 20) -> Panel:
    var panel := Panel.new()
    panel.position = rect.position
    panel.size = rect.size
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = line
    style.set_border_width_all(1)
    style.set_corner_radius_all(radius)
    panel.add_theme_stylebox_override("panel", style)
    add_child(panel)
    return panel

func _label(text_value: String, rect: Rect2, font_size: int, color: Color = CREAM) -> Label:
    var label := Label.new()
    label.text = text_value
    label.position = rect.position
    label.size = rect.size
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    add_child(label)
    return label

func _button(text_value: String, rect: Rect2, action: Callable) -> Button:
    var button := Button.new()
    button.text = text_value
    button.position = rect.position
    button.size = rect.size
    button.focus_mode = Control.FOCUS_ALL
    var style := StyleBoxFlat.new()
    style.bg_color = Color("25483f")
    style.border_color = Color("527568")
    style.set_border_width_all(1)
    style.set_corner_radius_all(10)
    button.add_theme_stylebox_override("normal", style)
    var hover := style.duplicate()
    hover.bg_color = Color("386456")
    button.add_theme_stylebox_override("hover", hover)
    button.add_theme_stylebox_override("pressed", hover)
    var focus := style.duplicate()
    focus.bg_color = Color(0,0,0,0)
    focus.border_color = GOLD
    focus.set_border_width_all(3)
    button.add_theme_stylebox_override("focus",focus)
    button.add_theme_color_override("font_color", CREAM)
    button.pressed.connect(action)
    add_child(button)
    return button

func _build() -> void:
    _label("朵朵与猫猫", Rect2(38, 23, 320, 50), 30)
    _label("准备 / 暂停", Rect2(354, 31, 260, 40), 18, MUTE)
    top_status = _label("", Rect2(762, 29, 480, 44), 18, GOLD)
    top_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _panel(Rect2(34, 97, 563, 552), Color("16392e"), Color("426052"), 24)
    _label("一起把回家的路点亮", Rect2(63, 119, 510, 54), 33, CREAM)
    _label("一位朵朵，两只猫咪。", Rect2(65, 177, 220, 40), 18, MUTE)
    resume_button = _button("继续休息点", Rect2(431, 181, 130, 35), resume_checkpoint)
    resume_button.name = "ResumeCheckpoint"
    solo_resume_button = _button("继续单人", Rect2(292,181,130,35),func(): resume_journey(true))
    solo_resume_button.name = "ResumeSolo"
    _panel(Rect2(59, 234, 513, 231), Color.WHITE, Color("eadfc5"), 16)
    var team := TextureRect.new()
    team.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    team.texture = TEAM
    team.position = Vector2(65, 240)
    team.size = Vector2(501, 219)
    team.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    add_child(team)
    _button("双人战斗",Rect2(68,482,114,38),func(): start_preview("combat")).name = "CombatPreview"
    _button("双猫灯廊",Rect2(194,482,114,38),func(): start_preview("light")).name = "LightPreview"
    _button("林边休息",Rect2(320,482,114,38),func(): start_preview("rest")).name = "RestPreview"
    _button("单人战斗",Rect2(446,482,114,38),start_solo_combat).name = "SoloCombatPreview"
    _button("从头开始 · 单人",Rect2(68,530,240,43),func(): start_journey(true)).name = "SingleJourney"
    _button("从头开始 · 双人",Rect2(320,530,240,43),func(): start_journey(false)).name = "DualJourney"
    var keyboard_button := _button("键盘试玩 · Enter", Rect2(68, 586, 253, 43), func(): router.start_keyboard())
    keyboard_button.name = "KeyboardPlay"
    var pads := _button("切回双手柄", Rect2(340, 586, 220, 43), func(): router.use_gamepads())
    pads.name = "GamepadMode"
    _build_slot(0, 97, "朵朵", "认真冒险，也认真休息。", Color("79c4b0"))
    _build_slot(1, 383, "猫咪伙伴", "团团与圆圆，共用一个玩家位置。", GOLD)
    _panel(Rect2(34, 671, 1212, 95), Color("1a342b"), Color("456153"), 16)
    footer_status = _label("", Rect2(58, 684, 900, 35), 23, GOLD)
    mode_help = _label("", Rect2(59, 724, 900, 28), 16, MUTE)
    var replay := _button("重玩庭院", Rect2(979, 692, 141, 46), func():
        router.clear_keyboard()
        if stage == "rest":
            restart_journey()
        elif stage == "light":
            light_corridor.restart()
            session.pause_all("双猫灯廊已重置 · Enter 或双手柄准备")
        elif stage == "combat":
            arena.restart()
            arena.allow_next_level = not preview_run or not session.single_player
            session.pause_all("林间空地已重置 · Enter 或双手柄准备")
        else:
            courtyard.restart()
    )
    replay.name = "ReplayCourtyard"
    _button("返回" if OS.has_feature("web") else "退出", Rect2(1135, 692, 82, 46), exit_game).name = "ExitGame"
    for id in ["SingleJourney","DualJourney","ResumeSolo","ResumeCheckpoint","SoloCombatPreview","CombatPreview","LightPreview","RestPreview","ReplayCourtyard","KeyboardPlay","GamepadMode","ExitGame"]:
        menu_controls.append(get_node(id))

func _build_slot(slot: int, y: float, title: String, detail: String, tint: Color) -> void:
    _panel(Rect2(621, y, 625, 266), Color("152c25"), Color("476052"), 20)
    slot_badges.append(_label("P%d" % [slot + 1], Rect2(645, y + 18, 70, 40), 26, tint))
    slot_titles.append(_label(title, Rect2(712, y + 16, 330, 44), 28))
    slot_details.append(_label(detail, Rect2(647, y + 61, 560, 28), 17, MUTE))
    devices_text.append(_label("", Rect2(647, y + 98, 557, 28), 17, MUTE))
    ready_text.append(_label("", Rect2(647, y + 129, 470, 34), 22, tint))
    action_text.append(_label("", Rect2(647, y + 176, 410, 31), 18, CREAM))
    vector_text.append(_label("", Rect2(647, y + 211, 415, 28), 16, MUTE))
    var stick := Stick.new()
    stick.position = Vector2(1146, y + 153)
    stick.size = Vector2(78, 78)
    stick.tint = tint
    add_child(stick)
    sticks.append(stick)
    claim_buttons.append(_button("重新认领", Rect2(1111, y + 24, 112, 38), func():
        session.release_slot(slot)
        last_buttons[slot] = -1
    ))

func _input(event: InputEvent) -> void:
    if _menu_input(event):
        get_viewport().set_input_as_handled()
        return
    router.handle(event)
    if not session.running() and is_instance_valid(arena):
        arena.cancel_inputs()
    if event is InputEventKey and session.keyboard_mode:
        get_viewport().set_input_as_handled()

func _action(slot: int, button: int) -> void:
    last_buttons[slot] = button
    if stage == "rest":
        rest_area.handle_action(slot, button)
    elif stage == "light":
        light_corridor.handle_action(slot, button)
    elif stage == "combat":
        arena.handle_action(slot, button)
    else:
        courtyard.handle_action(slot, button)

func enter_combat() -> void:
    if arena.battle.solo_mode != session.single_player: arena.configure_solo(session.single_player)
    arena.allow_next_level = not preview_run or not session.single_player
    router.clear_keyboard()
    if stage == "bridge":
        arena.battle.current_cat = courtyard.party.current_cat
    stage = "combat"
    courtyard.set_active(false)
    light_corridor.set_active(false)
    rest_area.set_active(false)
    arena.set_active(session.running())

func enter_light() -> void:
    light_corridor.puzzle.solo_mode = session.single_player
    router.clear_keyboard()
    if stage != "light":
        light_corridor.puzzle.current_cat = arena.battle.current_cat if stage == "combat" else courtyard.party.current_cat
        light_corridor.puzzle.hp = arena.battle.hp.duplicate()
    stage = "light"
    courtyard.set_active(false)
    arena.set_active(false)
    rest_area.set_active(false)
    light_corridor.set_active(session.running())

func _show_rest() -> void:
    router.clear_keyboard()
    stage = "rest"
    courtyard.set_active(false)
    arena.set_active(false)
    light_corridor.set_active(false)
    rest_area.set_active(session.running())

func enter_rest() -> void:
    if stage != "rest":
        rest_area.state = rest_area.Rest.new()
        rest_area.state.solo_mode = session.single_player
        rest_area.selection = rest_area.Selection.new()
        rest_area.state.progress = {"bridge":courtyard.bridge.finished,"combat":arena.battle.phase == "complete","light":light_corridor.puzzle.finished}
        rest_area.state.current_cat = light_corridor.puzzle.current_cat if stage == "light" else arena.battle.current_cat
        rest_area.state.hp = light_corridor.puzzle.hp.duplicate() if stage == "light" else arena.battle.hp.duplicate()
        rest_area.reported = false
        rest_area.can_save = stage == "light" and light_corridor.puzzle.finished and not preview_run
        rest_area.save_status = "坐下休息后记录安全点" if rest_area.can_save else "单独试玩 · 不覆盖上次旅程"
    if preview_run:
        rest_area.can_save = false
        rest_area.save_status = "单独试玩 · 不覆盖上次旅程"
    _show_rest()

func _save_checkpoint() -> void:
    var store = solo_checkpoint if session.single_player else checkpoint
    if store.save_checkpoint(rest_area.state.record()):
        rest_area.save_status = "安全点已保存 · 下次可继续"
    else:
        rest_area.save_status = "安全点未保存 · 本次可继续"
        rest_area.state.message = store.last_error
    _refresh_checkpoint_button()

func _refresh_checkpoint_button() -> void:
    var data: Dictionary = checkpoint.read_checkpoint()
    resume_button.disabled = data.is_empty()
    resume_button.text = "暂无双人记录" if data.is_empty() else "继续双人"
    var solo_data: Dictionary = solo_checkpoint.read_checkpoint()
    solo_resume_button.disabled = solo_data.is_empty()
    solo_resume_button.text = "暂无单人记录" if solo_data.is_empty() else "继续单人"
    solo_resume_button.tooltip_text = solo_checkpoint.last_error
    resume_button.tooltip_text = checkpoint.last_error

func resume_checkpoint() -> void:
    resume_journey(false)

func resume_journey(single: bool) -> void:
    var store = solo_checkpoint if single else checkpoint
    var data: Dictionary = store.read_checkpoint()
    if data.is_empty():
        _refresh_checkpoint_button()
        return
    router.clear_keyboard()
    session.pause_all("正在恢复休息点")
    session.single_player = single
    if single: session.devices[1] = -1
    rest_area.restore(data)
    preview_run = false
    _show_rest()
    if session.keyboard_mode or session.devices == [-1,-1]:
        router.start_keyboard()
    else:
        session.pause_all("已回到休息点 · 两位准备后继续")

func restart_journey() -> void:
    router.clear_keyboard()
    session.pause_all("重新开始庭院")
    preview_run = false
    courtyard.restart()
    arena.restart()
    arena.allow_next_level = true
    light_corridor.restart()
    light_corridor.puzzle.hp[0] = 3
    light_corridor.puzzle.hp[1] = 3
    rest_area.state = rest_area.Rest.new()
    rest_area.state.solo_mode = session.single_player
    rest_area.selection = rest_area.Selection.new()
    rest_area.reported = false
    rest_area.can_save = false
    rest_area.set_active(false)
    stage = "bridge"
    session.pause_all("已回到庭院入口 · Enter 或双方准备开始")

func _connection_changed(device: int, connected: bool) -> void:
    if not connected:
        var slot: int = session.slot_of(device)
        session.disconnect_device(device)
        arena.cancel_inputs()
        if slot >= 0:
            last_buttons[slot] = -1

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        router.clear_keyboard()
        session.set_focus(false)
    elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
        session.set_focus(true)

func _process(_delta: float) -> void:
    if not is_instance_valid(top_status):
        return
    if OS.has_feature("web") and OS.is_debug_build():
        web_probe_clock += _delta
        if web_probe_clock >= 0.1:
            web_probe_clock = 0
            var current = courtyard.party if stage == "bridge" else (arena.battle if stage == "combat" else (light_corridor.puzzle if stage == "light" else rest_area.state))
            var points: Array = []
            for point in current.positions: points.append([point.x,point.y])
            var report := {"stage":stage,"running":session.running(),"solo":session.single_player,"positions":points,"cat":current.current_cat,"bridge_locks":courtyard.bridge.unlocked,"bridge_done":courtyard.bridge.finished,"phase":arena.battle.phase,"wave":arena.battle.wave,"hp":arena.battle.hp,"persistent":OS.is_userfs_persistent(),"rested":rest_area.state.rested,"finished":rest_area.state.finished,"can_save":rest_area.can_save,"solo_saved":not solo_checkpoint.read_checkpoint().is_empty(),"dual_saved":not checkpoint.read_checkpoint().is_empty()}
            if stage == "combat":
                report["human"] = arena.solo.human_slot
                report["enemies"] = arena.battle.enemies
            if stage == "light":
                report["light_phase"] = light_corridor.puzzle.phase
                report["beam"] = [light_corridor.puzzle.beam.x,light_corridor.puzzle.beam.y]
                report["operator"] = light_corridor.puzzle.operator_slot
                report["recoveries"] = light_corridor.puzzle.recoveries
            JavaScriptBridge.eval("window.duoduoStatus = " + JSON.stringify(report),true)
    var playing: bool = session.running()
    for child in get_children():
        if child is CanvasItem and child != courtyard and child != arena and child != light_corridor and child != rest_area:
            child.visible = not playing
    if courtyard.active != (playing and stage == "bridge"):
        courtyard.set_active(playing and stage == "bridge")
    if arena.active != (playing and stage == "combat"):
        arena.set_active(playing and stage == "combat")
    if light_corridor.active != (playing and stage == "light"):
        light_corridor.set_active(playing and stage == "light")
    if rest_area.active != (playing and stage == "rest"):
        rest_area.set_active(playing and stage == "rest")
    get_node("ReplayCourtyard").text = "重走庭院" if stage == "rest" else ("重玩庭院" if stage == "bridge" else "重玩本关")
    top_status.text = "键盘试玩  ·  M14.1" if session.keyboard_mode else "检测到 %d 只手柄  ·  M14.1" % Input.get_connected_joypads().size()
    footer_status.text = "双人输入已启用 · 试试两边的摇杆与按钮" if session.running() else session.pause_reason
    mode_help.text = "WASD / E：朵朵  ·  方向键 / 空格：猫咪  ·  Enter 继续" if session.keyboard_mode else "十字键选菜单，面键下选择；菜单键加入 / 准备。无手柄可按 Enter。"
    if not playing and not session.keyboard_mode and session.devices == [-1, -1]:
        footer_status.text = "按 Enter 开始键盘试玩，或接入两只手柄"
    get_node("GamepadMode").text = "切回单手柄" if session.single_player else "切回双手柄"
    for slot in range(2):
        slot_titles[slot].text = (["玩家控制","AI 伙伴"][slot] if session.single_player else ["朵朵","猫咪伙伴"][slot])
        slot_details[slot].text = (["一套按键切换朵朵、团团与圆圆。","协助战斗；机关解谜由玩家操作。"][slot] if session.single_player else ["认真冒险，也认真休息。","团团与圆圆，共用一个玩家位置。"][slot])
        var device: int = session.devices[slot]
        claim_buttons[slot].disabled = session.keyboard_mode
        claim_buttons[slot].text = "键盘模式" if session.keyboard_mode else "重新认领"
        if session.keyboard_mode:
            devices_text[slot].text = "WASD 移动 · E 互动" if slot == 0 else "方向键移动 · 空格互动 · Tab 切猫 · R 驻守"
            ready_text[slot].text = "键盘已就绪" if playing else "按 Enter 继续"
        elif device < 0:
            devices_text[slot].text = "未认领 · 接上手柄后按菜单键"
            ready_text[slot].text = "等待加入"
        else:
            var device_name := Input.get_joy_name(device)
            devices_text[slot].text = "设备 %d · %s" % [device, device_name if not device_name.is_empty() else "已认领设备"]
            ready_text[slot].text = "已准备  ✓" if session.ready_flags[slot] else "已加入 · 按菜单键准备"
        var movement: Vector2 = session.movement(slot)
        sticks[slot].set_value(movement)
        vector_text[slot].text = "摇杆   X %+.2f    Y %+.2f" % [movement.x, movement.y]
        if not session.running():
            action_text[slot].text = "按 Enter 开始／继续" if session.keyboard_mode else ("按菜单键准备后启用输入" if session.single_player else "双方准备后启用输入")
        elif last_buttons[slot] < 0:
            action_text[slot].text = "按下按钮，查看接收结果"
        else:
            action_text[slot].text = "已收到按钮 %d" % last_buttons[slot]
        slot_badges[slot].text = ("AI" if stage == "combat" else "伴") if session.single_player and slot == 1 else "P%d" % (slot+1)
    if session.single_player:
        top_status.text = ("单人战斗试玩" if preview_run else "单人完整庭院") + " · M14.1"
        footer_status.text = "单人键盘 · Enter 开始 / 继续" if session.keyboard_mode else "单手柄 · 十字键选菜单 / 下确认 · 菜单键准备 / 继续"
        if not session.focused: footer_status.text = "返回游戏窗口后继续"
        mode_help.text = "WASD 移动 · E 互动 · Tab 换角色；战斗 F 攻击 / Q 闪避，解谜 R 工具 / Q 切回。"
        devices_text[0].text = "单人键盘 · WASD / F / Q / E / Tab" if session.keyboard_mode else devices_text[0].text
        devices_text[1].text = "无需第二只手柄"
        slot_titles[1].text = "AI 伙伴" if stage == "combat" else "伙伴分工"
        ready_text[1].text = "另一位角色由 AI 协助" if stage == "combat" else "解谜时由你切换三位角色"
        action_text[1].text = "接应、掩护和安全救援" if stage == "combat" else "战斗阶段会有 AI 协助"
        vector_text[1].text = "机关解谜由玩家亲自完成"
        claim_buttons[1].visible = false
        sticks[1].visible = false

func start_solo_combat() -> void:
    if session.running(): return
    router.clear_keyboard()
    session.pause_all("单人战斗 · 一只手柄加入后准备，或按 Enter")
    session.single_player = true
    session.devices[1] = -1
    preview_run = true
    arena.configure_solo(true)
    stage = "combat"
    courtyard.set_active(false)
    light_corridor.set_active(false)
    rest_area.set_active(false)
    if session.keyboard_mode or session.devices[0] < 0: router.start_keyboard()

func leave_solo() -> void:
    if not session.single_player: return
    router.clear_keyboard()
    session.single_player = false
    session.pause_all("已回到双人模式 · Enter 或双方准备")
    arena.configure_solo(false)

func start_journey(single: bool) -> void:
    if session.running(): return
    session.single_player = single
    if single: session.devices[1] = -1
    restart_journey()
    if session.keyboard_mode or session.devices[0] < 0:
        router.start_keyboard()
    else:
        session.pause_all("单人庭院 · 菜单键准备" if single else "双人庭院 · 两位按菜单键准备")

func _menu_input(event: InputEvent) -> bool:
    if session.running() or not session.focused or not event is InputEventJoypadButton: return false
    if event.button_index not in [JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN,JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT,JOY_BUTTON_A]: return false
    if not event.pressed: return true
    if event.button_index == JOY_BUTTON_A:
        if menu_index < 0: menu_index = 0
        else:
            var chosen: Button = menu_controls[menu_index]
            if not chosen.disabled:
                if session.keyboard_mode: router.use_gamepads()
                if session.slot_of(event.device) < 0: session.claim(event.device)
                chosen.pressed.emit()
                if session.running(): chosen.release_focus()
                return true
    else:
        var offset := -1 if event.button_index in [JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_LEFT] else 1
        if menu_index < 0: menu_index = 0
        else:
            for i in range(menu_controls.size()):
                menu_index = posmod(menu_index+offset,menu_controls.size())
                if not menu_controls[menu_index].disabled: break
    menu_controls[menu_index].grab_focus()
    return true

func start_preview(target: String) -> void:
    if session.running(): return
    leave_solo()
    preview_run = true
    match target:
        "combat":
            arena.configure_solo(false)
            enter_combat()
        "light":
            light_corridor.restart()
            light_corridor.puzzle.solo_mode = false
            enter_light()
        "rest":
            rest_area.state = rest_area.Rest.new()
            rest_area.selection = rest_area.Selection.new()
            rest_area.reported = false
            rest_area.can_save = false
            rest_area.save_status = "单独试玩 · 不覆盖上次旅程"
            _show_rest()
    if session.keyboard_mode or session.devices == [-1,-1]: router.start_keyboard()

func exit_game() -> void:
    if OS.has_feature("web"):
        router.clear_keyboard()
        session.pause_all("已回到网页入口")
        JavaScriptBridge.eval("parent.postMessage({type:'duoduo-exit'}, location.origin)")
    else:
        get_tree().quit()
