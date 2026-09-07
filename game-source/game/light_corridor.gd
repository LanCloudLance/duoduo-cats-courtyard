extends Node2D
signal next_level_requested
const Selection = preload("res://game/solo_selection.gd")
var selection = Selection.new()
const Light = preload("res://game/light_state.gd")
const Map = preload("res://game/light_layout.gd")
const Actor = preload("res://game/actor_view.gd")
var puzzle = Light.new()
var session
var active := false
var font: Font
var camera := Camera2D.new()
var hud := CanvasLayer.new()
var actors: Array[Node2D] = []
var girl_label: Label
var cat_label: Label
var status_label: Label
var p1_help: Label
var p2_help: Label
var objective_label: Label
var hint_label: Label
func _init(state) -> void:
    session = state
func _ready() -> void:
    font = get_parent().theme.default_font
    camera.enabled = false
    camera.position = Vector2(640, 400)
    add_child(camera)
    for i in range(3):
        var actor_view := Actor.new()
        actor_view.role = i
        actor_view.font = font
        actor_view.scale = Vector2(0.82,0.82)
        actor_view.position = puzzle.positions[i]
        add_child(actor_view)
        actors.append(actor_view)
    hud.layer = 12
    add_child(hud)
    _panel(Rect2(24, 20, 1232, 124))
    _label("你照着我", Rect2(48, 34, 250, 38), 28)
    status_label = _label("", Rect2(48, 80, 250, 50), 16)
    girl_label = _label("P1 朵朵 · 照路 / 过桥", Rect2(330, 34, 420, 38), 22, Color("9cdcca"))
    cat_label = _label("", Rect2(754, 34, 470, 38), 22)
    p1_help = _label("", Rect2(330, 81, 405, 50), 17)
    p2_help = _label("", Rect2(754, 81, 470, 50), 17)
    _panel(Rect2(24, 685, 1232, 91))
    objective_label = _label("", Rect2(48, 697, 1170, 32), 21)
    hint_label = _label("", Rect2(48, 738, 1170, 27), 16, Color("bdd6c7"))
    set_active(false)
    _refresh()
func set_active(value: bool) -> void:
    active = value
    visible = value
    hud.visible = value
    camera.enabled = value
func restart() -> void:
    var health: Array[int] = puzzle.hp.duplicate()
    puzzle = Light.new()
    puzzle.solo_mode = session.single_player
    selection = Selection.new()
    puzzle.hp = health
    _refresh()
func handle_action(slot: int, button: int) -> void:
    if not session.running():
        return
    if session.single_player:
        if slot != 0: return
        if button in [JOY_BUTTON_Y,JOY_BUTTON_B]:
            get_parent().router.clear_keyboard()
            session.axes[0] = Vector2.ZERO
            selection.select_next(puzzle,button == JOY_BUTTON_B)
            return
        slot = selection.slot()
    if button == JOY_BUTTON_A and puzzle.finished:
        next_level_requested.emit()
        return
    if button == JOY_BUTTON_A:
        puzzle.interact(slot)
    elif button == JOY_BUTTON_RIGHT_SHOULDER:
        if slot == 0:
            puzzle.interact(slot)
        else:
            puzzle.tool(slot)
    elif slot == 1 and button == JOY_BUTTON_Y:
        puzzle.switch_cat()
func _physics_process(delta: float) -> void:
    if not active or not session.running():
        return
    if session.single_player:
        puzzle.step(delta, selection.movement(session.movement(0),0), selection.movement(session.movement(0),1), true)
    else:
        puzzle.step(delta, session.movement(0), session.movement(1), true)
    for i in range(3):
        actors[i].caption_visible = true
        if i > 0:
            for j in range(3):
                if j != i and puzzle.positions[j].distance_to(puzzle.positions[i]) < 110:
                    actors[i].caption_visible = i == puzzle.current_cat or (i == 2 and puzzle.lit)
        if i == 2 and puzzle.lit:
            actors[i].caption_visible = false
        var selected: bool = i == selection.actor if session.single_player else i == 0 or i == puzzle.current_cat
        actors[i].caption_override = ["朵朵","团团","圆圆"][i]+(" · 你控制" if selected else "") if session.single_player else ""
        actors[i].caption_visible = selected or actors[i].caption_visible
        actors[i].update_pose(puzzle.positions[i], selected, i == 2 and puzzle.lit, delta)
    _refresh()
func _refresh() -> void:
    if not is_instance_valid(cat_label):
        return
    cat_label.text = "P2 " + ("团团 · 爪钩" if puzzle.current_cat == 1 else "圆圆 · 定光扣")
    status_label.text = "双人灯廊 / M11 · %s\nEsc / 菜单键暂停" % ({"cat":"① 探路","girl":"② 接应","route":"③ 选路"}[puzzle.phase])
    if session.keyboard_mode:
        p1_help.text = "WASD 移动光斑 · E 离开操作台" if puzzle.operator_slot == 0 else "WASD 走路 · E 操台 / 固桥 / 集合"
        p2_help.text = "方向键移动光斑 · R 离台" if puzzle.operator_slot == 1 else "方向键走路 · R 工具 · Tab 切猫"
        p2_help.text += "\n空格：集合 / 安全岛返回中岛"
    else:
        p1_help.text = "左摇杆移光 · 面键下离台" if puzzle.operator_slot == 0 else "左摇杆走路 · 面键下操台 / 固桥"
        p2_help.text = "左摇杆移光 · 右肩离台" if puzzle.operator_slot == 1 else "左摇杆走路 · 右肩工具 · 面键上切猫"
        p2_help.text += "\n面键下：集合 / 安全岛返回中岛"
    p1_help.text += "\n" + ("正在导光 · 看伙伴脚下" if puzzle.operator_slot == 0 else ("走近岸下方宽桥，伙伴接应你" if puzzle.phase == "girl" else "与伙伴一起观察下一块踏石"))
    objective_label.text = puzzle.objective()
    hint_label.text = puzzle.message
    if puzzle.finished:
        hint_label.text = "再按互动键，带猫猫去林边长椅休息。"
    girl_label.text = selection.title() if session.single_player else "P1 朵朵 · 照路 / 过桥"
    if session.single_player:
        status_label.text = "单人灯廊 · 手动解谜\nEsc / 菜单键暂停"
        cat_label.text = "切换时保留脚下已照亮的落脚点"
        p1_help.text = ("WASD 移光 · E / R 离台" if puzzle.is_operator(selection.actor) else "WASD 移动 · E 互动 · R 工具") if session.keyboard_mode else ("摇杆移光 · 下 / 右肩离台" if puzzle.is_operator(selection.actor) else "摇杆移动 · 面键下互动 · 右肩工具")
        p1_help.text += "\n" + selection.help(session.keyboard_mode)
        p2_help.text = "先照亮下一小段，再切回伙伴前进\n圆圆持续定光；收光会撤掉临时落脚点"
        objective_label.text = objective_label.text.replace("朵朵与猫咪分别确认","按互动键确认")
    queue_redraw()
func _panel(rect: Rect2) -> void:
    var panel := Panel.new()
    panel.position = rect.position
    panel.size = rect.size
    var style := StyleBoxFlat.new()
    style.bg_color = Color("163930")
    style.border_color = Color("608775")
    style.set_border_width_all(1)
    style.set_corner_radius_all(16)
    panel.add_theme_stylebox_override("panel", style)
    hud.add_child(panel)
func _label(value: String, rect: Rect2, size: int, color := Color("fff0d0")) -> Label:
    var label := Label.new()
    label.text = value
    label.position = rect.position
    label.size = rect.size
    label.add_theme_font_override("font", font)
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", color)
    hud.add_child(label)
    return label
func _text(point: Vector2, value: String, width: float, size := 17, color := Color("fff0d0")) -> void:
    if font:
        draw_string(font, point, value, HORIZONTAL_ALIGNMENT_CENTER, width, size, color)
func _draw() -> void:
    draw_rect(Rect2(-800,-800,3000,2500),Color("172f31"))
    draw_rect(Map.FIELD.grow(18),Color("314d50"))
    draw_rect(Map.FIELD,Color("233f50"))
    for x in range(295,1060,42):
        for y in range(270,640,46):
            draw_line(Vector2(x,y),Vector2(x+16,y-3),Color("355463"),2,true)
    for land in [Map.NEAR,Map.MID,Map.FAR]:
        draw_rect(land.grow(4),Color("849775"))
        draw_rect(land,Color("607c62"))
    _text(Vector2(85,218),"近岸 · 出发",190,21)
    _text(Vector2(580,218),"中岛 · 交换职责",180,21)
    _text(Vector2(1055,218),"远岸 · 团聚",150,21)
    if not puzzle.front_fixed:
        _path(Map.CAT_PATH, "cat", Color("8dd7cf"))
        if puzzle.phase != "cat": _path(Map.GIRL_PATH,"girl",Color("dbc294"))
    else: _bridge(270,590)
    if not puzzle.permanent:
        _path(Map.SAFE_PATH,"safe",Color("8dd7cf"))
        _path(Map.FAST_PATH,"fast",Color("f0c480"))
    else: _bridge(750,1070)
    for island in [Map.ISLAND_ONE,Map.ISLAND_SAFE]:
        draw_rect(island.grow(4),Color("b4b79c"))
        draw_rect(island,Color("789077"))
        draw_arc(island.get_center(),15,0,TAU,24,Color("e5ecd2"),2,true)
    _text(Vector2(364,313),"安全点",90,15)
    _text(Vector2(866,275),"安全岛",90,15)
    if not puzzle.permanent:
        _text(Vector2(820,247),"稳妥线 · 有休息岛",210,16,Color("afe4d8"))
        _text(Vector2(810,621),"捷径 · 连续弯道",240,16,Color("eed49e"))
    if puzzle.lit:
        var source: Vector2 = Map.LAMP_NEAR if puzzle.source == "near" else (Map.LAMP_SAFE if puzzle.source == "safe" else Map.LAMP_FAST)
        var desk: Vector2 = Map.GUIDE_NEAR if puzzle.phase == "cat" else (Map.RELAY if puzzle.phase == "girl" else Map.GUIDE_MID)
        draw_line(source,desk,Color(0.6,0.91,0.85,0.35),3,true)
        if puzzle._source_ready() and not puzzle.permanent:
            draw_line(desk,puzzle.beam,Color(0.8,0.96,0.8,0.18),6,true)
            draw_circle(puzzle.beam,Light.BEAM_RADIUS,Color(0.9,1,0.78,0.1))
            draw_arc(puzzle.beam,Light.SUPPORT_RADIUS,0,TAU,60,Color("f6efad"),2,true)
            draw_line(puzzle.beam-Vector2(7,0),puzzle.beam+Vector2(7,0),Color("fff5c7"),2)
            draw_line(puzzle.beam-Vector2(0,7),puzzle.beam+Vector2(0,7),Color("fff5c7"),2)
            _text(puzzle.beam+Vector2(-40,83),("团团光斑" if puzzle.phase == "girl" else "朵朵光斑") if session.single_player else "P%d 光斑" % (2 if puzzle.phase == "girl" else 1),80,14)
    if puzzle.held_actor >= 0 and puzzle._held(puzzle.held_actor):
        draw_arc(puzzle.held_point,10,0,TAU,24,Color("fff0aa"),3,true)
    _lamp(Map.LAMP_NEAR,"圆圆 · 定光",not puzzle.front_fixed,puzzle.source == "near")
    _lamp(Map.LAMP_SAFE,"圆圆 · 稳妥",puzzle.front_fixed,puzzle.source == "safe")
    _lamp(Map.LAMP_FAST,"圆圆 · 捷径",puzzle.front_fixed,puzzle.source == "fast")
    _desk(Map.GUIDE_NEAR,"朵朵导光",puzzle.phase == "cat",puzzle.operator_slot == 0 and puzzle.phase == "cat")
    _desk(Map.RELAY,"团团反光",puzzle.phase in ["cat","girl"],puzzle.operator_slot == 1)
    _desk(Map.GUIDE_MID,"朵朵导光",puzzle.phase == "route" and not puzzle.latched,puzzle.operator_slot == 0 and puzzle.phase == "route")
    _lock(Map.FRONT_LOCK,"固定前桥",puzzle.front_fixed,puzzle.phase == "girl")
    _lock(Map.FAR_WINCH,"放下后桥",puzzle.permanent,puzzle.latched and not puzzle.permanent)
    _lock(Map.FAR_LOCK,"远岸桥锁",puzzle.latched,puzzle.phase == "route")
    draw_arc(Map.EXIT,57,0,TAU,40,Color("edda9c") if puzzle.permanent else Color("86947a"),3,true)
    _text(Map.EXIT+Vector2(-55,84),"集合出口",110,18)
    if puzzle.permanent:
        _text(Map.EXIT+Vector2(-65,106),"%s / %s" % ["朵朵 ✓" if puzzle.confirmed[0] else "朵朵", "猫咪 ✓" if puzzle.confirmed[1] else "猫咪"],130,14)
    for i in range(3):
        if puzzle.slipping[i] > 0:
            draw_arc(puzzle.positions[i],29,0,TAU,32,Color("ffcb82"),4,true)
            _text(puzzle.positions[i]+Vector2(-80,-100),"抓稳了！把光照回来",160,16,Color("ffe3aa"))
func _path(points: Array, kind: String, color: Color) -> void:
    var chosen: bool = (puzzle.phase == kind) or (puzzle.phase == "route" and puzzle.route == kind)
    draw_polyline(PackedVector2Array(points),Color(color,0.25),2,true)
    for point in Map.samples(points):
        if Map.bank(point) >= 0: continue
        var bright: bool = chosen and puzzle._source_ready() and point.distance_to(puzzle.beam) <= Light.SUPPORT_RADIUS
        draw_circle(point,13 if kind in ["girl","safe"] else 10,Color("dcf1bf") if bright else Color("48616a"))
        draw_arc(point,13 if kind in ["girl","safe"] else 10,0,TAU,16,color if chosen else Color(color,0.35),1.4,true)
func _bridge(start: float, end: float) -> void:
    draw_rect(Rect2(start,441,end-start,78),Color("45483c"))
    for x in range(int(start),int(end),21): draw_rect(Rect2(x,447,18,66),Color("bea271"))
    for y in [444,516]: draw_line(Vector2(start,y),Vector2(end,y),Color("e5c68e"),4,true)
func _lamp(point: Vector2,title: String,available: bool,selected: bool) -> void:
    var color := Color("b1ebdf") if available else Color("839083")
    draw_arc(point,25,0,TAU,32,color,3,true)
    draw_circle(point,10,color)
    if selected and puzzle.lit: draw_arc(point,31,0,TAU,32,Color("fff0a8"),3,true)
    _text(point+Vector2(-48,44),title,96,14,color)
func _desk(point: Vector2,title: String,available: bool,selected: bool) -> void:
    var color := Color("e8d7a2") if available else Color("8a9783")
    draw_rect(Rect2(point-Vector2(22,13),Vector2(44,27)),Color("3a5649"))
    draw_line(point-Vector2(21,8),point+Vector2(21,8),color,8,true)
    if available: draw_arc(point,30,0,TAU,28,color,2,true)
    _text(point+Vector2(-55,49),"导光中" if selected else title,110,15,color)
func _lock(point: Vector2,title: String,done: bool,available: bool) -> void:
    var color := Color("c0eab1") if done else (Color("f1cd8b") if available else Color("879581"))
    draw_arc(point,19,0,TAU,24,color,5,true)
    draw_line(point-Vector2(12,12),point+Vector2(12,12),color,3,true)
    if not done:
        _text(point+Vector2(-48,38),title,96,14,color)
