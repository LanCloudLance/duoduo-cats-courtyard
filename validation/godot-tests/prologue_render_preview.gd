extends SceneTree
const S = preload("res://input/session_state.gd")
const H = preload("res://game/prologue.gd")
func _initialize() -> void: call_deferred("run")
func capture(prefix: String, name: String) -> void:
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(prefix+name+".png")
func run() -> void:
    var args := OS.get_cmdline_user_args()
    if args.is_empty(): quit(1); return
    var host := Control.new()
    host.theme = Theme.new()
    host.theme.default_font = load("res://assets/fonts/CourtyardSans.ttf")
    root.add_child(host)
    var session = S.new()
    session.keyboard_mode = true
    session.ready_flags[0] = true
    session.ready_flags[1] = true
    var home = H.new(session)
    host.add_child(home)
    home.set_active(true)
    home.set_physics_process(false)
    home._physics_process(0)
    await capture(args[0],"-home")
    home.state.phase = "strange"
    home.state.positions[0] = Vector2(420,415)
    home.state.positions[1] = Vector2(1070,410)
    home.state.positions[2] = Vector2(1120,320)
    home.state.message = "走廊的小门轻轻响了。圆圆抬头看了一会儿，走向铃声。"
    home._physics_process(0)
    await capture(args[0],"-door")
    root.size = Vector2i(1280,720)
    home._physics_process(0)
    await capture(args[0],"-16x9")
    home.state.white_visible = false
    home.state.message = "朵朵：圆圆，等一下。团团，我们去接它。"
    home.state.finished = true
    home.state.phase = "complete"
    home.recorded = true
    home.save_status = "序章进度已记录"
    home._physics_process(0)
    await capture(args[0],"-complete")
    print("PROLOGUE_RENDER: 4 captures")
    quit()
