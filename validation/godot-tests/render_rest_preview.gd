extends SceneTree
# Synthetic rendering fixtures. Input and actual disk saves are tested separately.
const Session = preload("res://input/session_state.gd")
const RestArea = preload("res://game/rest_area.gd")
var failed := 0
func _initialize() -> void: call_deferred("run")
func capture(path: String) -> void:
    for i in range(15): await process_frame
    await RenderingServer.frame_post_draw
    if root.get_texture().get_image().save_png(path) != OK: failed += 1
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
    var area = RestArea.new(session)
    host.add_child(area)
    area.set_active(true)
    area.set_physics_process(false)
    var s = area.state
    s.progress = {"bridge":true,"combat":true,"light":true}
    s.positions[0] = Vector2(610,460)
    s.positions[1] = Vector2(685,480)
    s.positions[2] = Vector2(595,535)
    s.interact(0)
    s.interact(1)
    s.interact(0)
    area._physics_process(0)
    area._physics_process(0)
    await capture(args[0]+"-resting.png")
    s.positions[0] = Vector2(1060,420)
    s.positions[1] = Vector2(1135,460)
    s.positions[2] = Vector2(1060,510)
    s.sitting[0] = false
    s.sitting[1] = false
    s.pet_cooldown = 0
    s.interact(0)
    s.interact(1)
    area._physics_process(0)
    area._physics_process(0)
    await capture(args[0]+"-complete.png")
    print("REST_RENDER: 2 captures, %d failures" % failed)
    quit(1 if failed else 0)
