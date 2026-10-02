extends SceneTree
## Frozen default and charged-road pictures; not a manual completion claim.
const Session = preload("res://input/session_state.gd")
const Corridor = preload("res://game/light_corridor.gd")
const Map = preload("res://game/light_layout.gd")
var corridor
var prefix: String
func _initialize() -> void:
    run.call_deferred()
func capture(name: String) -> void:
    corridor._physics_process(0)
    for i in range(6): await process_frame
    await RenderingServer.frame_post_draw
    assert(root.get_texture().get_image().save_png(prefix+name+".png") == OK)
func run() -> void:
    if DisplayServer.get_name() == "headless": quit(1); return
    prefix = OS.get_cmdline_user_args()[0]
    var host := Control.new()
    host.theme = Theme.new()
    host.theme.default_font = load("res://assets/fonts/CourtyardSans.ttf")
    root.add_child(host)
    var session = Session.new()
    session.keyboard_mode = true
    session.single_player = true
    session.ready_flags[0] = true
    session.ready_flags[1] = true
    corridor = Corridor.new(session)
    host.add_child(corridor)
    corridor.set_active(true)
    corridor.set_physics_process(false)
    await capture("-default")
    var s = corridor.puzzle
    s.solo_mode = true
    s.solo_actor = 0
    s.positions[0] = Map.GUIDE_NEAR
    s.positions[2] = Map.LAMP_NEAR
    s.lit = true
    s.source = "near"
    for point in Map.samples(Map.CAT_PATH,45):
        s.beam = point
        for i in range(5): s._charge_step(0.1)
    corridor.selection.actor = 1
    s.positions[1] = Vector2(330,440)
    s.message = "光斑已经移开，石板上的余光还在。"
    await capture("-stored")
    s.beam = Vector2(600,430)
    for i in range(110): s.step(0.1,Vector2.ZERO,Vector2.ZERO,true)
    await capture("-expired")
    print("M20_LIGHT_PREVIEW: 3 captures, 0 failures")
    quit()
