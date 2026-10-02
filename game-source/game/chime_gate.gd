extends Node2D
signal next_level_requested
const Chime = preload("res://game/chime_state.gd")
const Selection = preload("res://game/solo_selection.gd")
const Actor = preload("res://game/actor_view.gd")
const BACKDROP = preload("res://assets/visual-m14/arena-painted.png")
const PROPS = preload("res://assets/visual-m22/chime-props.png")
# Source regions exclude neighboring sprites and preserve the generated alpha.
const PROP_REGIONS := [Rect2(90,16,280,422),Rect2(497,16,344,422),
    Rect2(946,16,334,427),Rect2(1388,16,336,427),
    Rect2(94,452,296,414),Rect2(539,448,278,420),
    Rect2(925,447,384,421),Rect2(1430,447,238,421)]
const BELL_CUES := [preload("res://assets/music/chime-0.wav"),preload("res://assets/music/chime-1.wav")]
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
var mirror_blends: Array[float] = [1.0,0.0,0.0]
var bell_glows: Array[float] = [0.0,0.0]
var bell_last: Array[bool] = [false,false]
var bell_voices: Array[AudioStreamPlayer] = []

func _init(state) -> void:
    session = state

func _ready() -> void:
    font = get_parent().theme.default_font
    camera.position = Vector2(640,400)
    camera.enabled = false
    add_child(camera)
    add_child(audio)
    for stream in BELL_CUES:
        var voice := AudioStreamPlayer.new()
        voice.stream = stream
        voice.volume_db = -14
        add_child(voice)
        bell_voices.append(voice)
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
    if not value:
        audio.silence()
        for voice in bell_voices: voice.stop()

func restart() -> void:
    var health: Array[int] = puzzle.hp.duplicate()
    puzzle = Chime.new()
    puzzle.hp = health
    puzzle.solo_mode = session.single_player
    selection = Selection.new()
    opening = 0
    reveal = 0
    heard_revision = 0
    mirror_blends = [1.0,0.0,0.0]
    bell_glows = [0.0,0.0]
    bell_last = [false,false]
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
        if puzzle.last_event != "bell": audio.play(1)
        heard_revision = puzzle.revision
    for i in range(3):
        mirror_blends[i] = move_toward(mirror_blends[i],float(puzzle.mirrors[i]),dt*4.5)
    for i in range(2):
        bell_glows[i] = move_toward(bell_glows[i],1.0 if puzzle.receivers[i] else 0.0,dt*4)
        if puzzle.receivers[i] and not bell_last[i] and not audio.muted:
            bell_voices[i].play()
        bell_last[i] = puzzle.receivers[i]
    for i in range(3):
        var selected: bool = i == selection.actor if session.single_player else i == 0 or i == puzzle.current_cat
        actors[i].caption_visible = selected and not (i == 2 and puzzle.lens_site >= 0)
        actors[i].caption_override = ["朵朵","团团","圆圆"][i]+(" · 你控制" if selected and session.single_player else "")
        actors[i].presentation_clock = clock
        actors[i].social_kind = "rest" if i == 2 and puzzle.lens_site >= 0 else ""
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
    draw_string_outline(font,point,text,HORIZONTAL_ALIGNMENT_CENTER,width,size,3,Color("263d30"))
    draw_string(font,point,text,HORIZONTAL_ALIGNMENT_CENTER,width,size,Color("fff0ce"))

func _prop(index: int, foot: Vector2, size: Vector2, opacity: float = 1.0) -> void:
    if opacity <= 0: return
    draw_texture_rect_region(PROPS,Rect2(foot-Vector2(size.x*0.5,size.y),size),PROP_REGIONS[index],Color(1,1,1,opacity))

func _near_operator(point: Vector2, role: int, candidates: Array) -> bool:
    var controlled: bool = selection.actor == role if session.single_player else role == 0 or puzzle.current_cat == role
    if not controlled: return false
    var distance: float = puzzle.positions[role].distance_to(point)
    if distance >= 78: return false
    for other in candidates:
        if puzzle.positions[role].distance_to(other) < distance-0.1: return false
    return true

func _foot_shadow(point: Vector2, width: float) -> void:
    draw_set_transform(point,0,Vector2(1,0.25))
    draw_circle(Vector2.ZERO,width*0.5,Color(0.12,0.19,0.10,0.24))
    draw_set_transform(Vector2.ZERO)

func _draw() -> void:
    draw_texture_rect(BACKDROP,Rect2(0,0,1280,800),false)
    # Props use their real ground anchor; beams pass through glass above it.
    var height := Vector2(0,65)
    var blend: float = puzzle.board_blend()
    for i in [0,2]:
        var start: Vector2 = Chime.MIRRORS[i]
        var end: Vector2 = puzzle.mirror_points()[i]
        if start.distance_to(end) > 1:
            draw_line(start+Vector2(0,4),end+Vector2(0,4),Color(0.32,0.25,0.13,0.4),7,true)
            draw_line(start,end,Color(0.66,0.49,0.27,0.75),3,true)
    if puzzle.stage == 2:
        draw_line(Vector2(180,400),Vector2(180,500),Color(0.42,0.30,0.15,0.65),6,true)
    var source: Vector2 = Chime.SOURCE.lerp(puzzle.source_point(),blend)
    _foot_shadow(source,62)
    _prop(4,source+Vector2(-12,4),Vector2(85,118))
    draw_circle(source-height,7,Color(1,0.90,0.56,0.65+sin(clock*2)*0.1))
    var girl_controls: Array = [puzzle.source_point(),puzzle.mirror_points()[0],puzzle.mirror_points()[2]]
    if puzzle.stage == 2 and _near_operator(puzzle.source_point(),0,girl_controls):
        _text(source+Vector2(-65,25),"调灯高低",130,16)
    for i in range(3):
        var foot: Vector2 = Chime.MIRRORS[i].lerp(puzzle.mirror_points()[i],blend)
        _foot_shadow(foot,69)
        _prop(2,foot+Vector2(0,4),Vector2(104,133),1-mirror_blends[i])
        _prop(3,foot+Vector2(0,4),Vector2(104,133),mirror_blends[i])
        if _near_operator(puzzle.mirror_points()[i],1 if i == 1 else 0,[puzzle.mirror_points()[1]] if i == 1 else girl_controls):
            _text(foot+Vector2(-67,25),"团团 · 爪钩扣环" if i == 1 else "朵朵 · 转手柄",134,15)
    for i in range(2):
        var foot: Vector2 = Chime.SOCKETS[i].lerp(puzzle.socket_points()[i],blend)
        _foot_shadow(foot,57)
        _prop(5,foot+Vector2(0,5),Vector2(66,100))
        if puzzle.lens_site == i:
            draw_arc(foot-height,22,0,TAU,36,Color(1,0.87,0.42,0.5),2,true)
            for k in range(3):
                var sparkle := foot-height+Vector2(sin(clock*2+k*2)*18,-12-k*7+sin(clock*3+k)*4)
                draw_circle(sparkle,1.7,Color("fff0b6"))
        if _near_operator(puzzle.socket_points()[i],2,puzzle.socket_points()):
            _text(foot+Vector2(-66,25),"圆圆 · 稳住水晶",132,15)
    for i in range(2):
        if i == 1 and reveal < 0.03: continue
        var foot: Vector2 = Chime.BELLS[i].lerp(puzzle.bell_points()[i],blend)
        var visibility := 1.0 if i == 0 else reveal
        _foot_shadow(foot,55)
        # Bell body can swing, while the branch stand stays visually grounded.
        var sway := sin(clock*10)*bell_glows[i]*0.025
        draw_set_transform(foot,sway)
        _prop(0,Vector2(-13,3),Vector2(82,124),visibility*(1-bell_glows[i]))
        _prop(1,Vector2(-5,3),Vector2(100,124),visibility*bell_glows[i])
        draw_set_transform(Vector2.ZERO)
        if puzzle.stage == 2:
            # A small receiving port with a moving glint, visibly directed
            # toward its one accepted incoming beam; no floating debug ring.
            var port := foot-height+(Vector2(27,0) if i == 0 else Vector2(0,27))
            var toward := Vector2.LEFT if i == 0 else Vector2.UP
            draw_line(port-toward*7,port+toward*5,Color("76502c"),9,true)
            draw_line(port-toward*6,port+toward*5,Color("e7ba69"),5,true)
            var glint := port-toward*(9-fmod(clock*10,12))
            draw_circle(glint,2.2,Color(1,0.91,0.65,visibility*.8))
        if puzzle.receivers[i]:
            var ring_center: Vector2 = foot-height
            draw_arc(ring_center,38+sin(clock*5)*3,0.15,2.65,28,Color(1,0.91,0.62,0.55),2,true)
    var door: Vector2 = Chime.EXIT
    _foot_shadow(door,126)
    # Hinged leaves narrow while opening; the doorway never slides off its frame.
    var leaf_width := 49*(1-opening)
    if leaf_width > 1:
        _prop(7,door+Vector2(-24-opening*23,-12),Vector2(leaf_width,151))
        _prop(7,door+Vector2(24+opening*23,-12),Vector2(leaf_width,151))
    _prop(6,door+Vector2(0,8),Vector2(170,201))
    # Keep the magical path legible across the illustrated frames. Actors
    # still draw above the world; the resting white-cat pose clears its prism.
    for ray in puzzle.rays:
        draw_line(ray.from-height,ray.to-height,Color(1,0.86,0.43,0.14),12,true)
        draw_line(ray.from-height,ray.to-height,Color(1,0.89,0.62,0.30),5,true)
        draw_line(ray.from-height,ray.to-height,Color("ffe7a0"),2,true)
    if puzzle.finished: _text(door+Vector2(-85,39),"门开了 · 一起走吧",170,17)
