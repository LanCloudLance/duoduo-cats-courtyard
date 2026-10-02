extends SceneTree
# Frozen rendering fixtures. The behavioral scene test separately walks both routes.
const Session = preload("res://input/session_state.gd")
const Corridor = preload("res://game/light_corridor.gd")
const Map = preload("res://game/light_layout.gd")
var failed := 0
var captures := 0
func _initialize() -> void:
    call_deferred("run")
func capture(path: String) -> void:
    for i in range(15): await process_frame
    await RenderingServer.frame_post_draw
    if root.get_texture().get_image().save_png(path) != OK: failed += 1
    captures += 1
func run() -> void:
    var args := OS.get_cmdline_user_args()
    if args.is_empty() or DisplayServer.get_name() == "headless":
        quit(1)
        return
    var host := Control.new()
    var font = load("res://assets/fonts/CourtyardSans.ttf")
    host.theme = Theme.new()
    host.theme.default_font = font
    root.add_child(host)
    var session = Session.new()
    session.keyboard_mode = true
    session.ready_flags[0] = true
    session.ready_flags[1] = true
    var corridor = Corridor.new(session)
    host.add_child(corridor)
    corridor.set_active(true)
    corridor.set_physics_process(false)
    var s = corridor.puzzle
    s.current_cat = 1
    s.lit = true
    s.source = "near"
    s.operator_slot = 0
    s.positions[2] = Map.LAMP_NEAR
    s.positions[0] = Map.GUIDE_NEAR
    s.positions[1] = Vector2(345,424)
    s.beam = Vector2(355,414)
    corridor._physics_process(0)
    await capture(args[0]+"-guiding.png")
    s.phase = "girl"
    s.operator_slot = 1
    s.positions[0] = Vector2(440,540)
    s.positions[1] = Map.RELAY
    s.beam = Vector2(452,533)
    s.message = "团团拉开反光片，下方的宽石板接到光。"
    corridor._physics_process(0)
    await capture(args[0]+"-handoff.png")
    s.front_fixed = true
    s.pin_site = "front"
    corridor.front_mix = 1.0
    s.phase = "route"
    s.source = "safe"
    s.operator_slot = 0
    s.positions[0] = Map.GUIDE_MID
    s.positions[2] = Map.LAMP_SAFE
    s.positions[1] = Vector2(820,320)
    s.beam = Vector2(845,320)
    s.message = "稳妥线有安全岛可以停下来商量；捷径则需要连续配合。"
    corridor._physics_process(0)
    await capture(args[0]+"-routes.png")
    root.size = Vector2i(1280,720)
    await capture(args[0]+"-16x9.png")
    root.size = Vector2i(1280,800)
    s.permanent = true
    s.pin_site = "far"
    s.front_fixed = false
    corridor.front_mix = 0
    corridor.far_mix = 1.0
    s.latched = true
    s.operator_slot = -1
    s.lit = false
    s.positions[0] = Vector2(1115,510)
    s.positions[1] = Vector2(1090,555)
    s.positions[2] = Vector2(1160,535)
    s.interact(0)
    s.interact(1)
    corridor._physics_process(0)
    await capture(args[0]+"-complete.png")
    print("LIGHT_RENDER: %d captures, %d failures" % [captures,failed])
    quit(1 if failed else 0)
