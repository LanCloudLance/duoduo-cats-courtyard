extends SceneTree
# Rendering-only fixture. Full input, focus and traversal behavior is covered
# by bridge_scene_test.gd; this host does not consume physical input or focus.
const Session = preload("res://input/session_state.gd")
const Courtyard = preload("res://game/courtyard.gd")
var failures := 0

func _initialize() -> void:
    call_deferred("run")

func capture(prefix: String, suffix: String) -> void:
    for i in range(45):
        await process_frame
    await RenderingServer.frame_post_draw
    if root.get_texture().get_image().save_png(prefix + suffix + ".png") != OK:
        failures += 1

func run() -> void:
    var args := OS.get_cmdline_user_args()
    if args.is_empty() or DisplayServer.get_name() == "headless":
        push_error("Rendering fixture needs a graphical renderer and an output prefix")
        quit(1)
        return
    var host := Control.new()
    var font := SystemFont.new()
    font.font_names = PackedStringArray(["Microsoft YaHei", "PingFang SC", "Noto Sans CJK SC"])
    var palette := Theme.new()
    palette.default_font = font
    host.theme = palette
    root.add_child(host)
    var session = Session.new()
    for device in [9, 18, 9, 18]:
        session.menu(device)
    var world = Courtyard.new(session)
    host.add_child(world)
    var p = world.party
    p.positions[0] = Vector2(960, 620)
    p.positions[1] = Vector2(1132, 640)
    p.positions[2] = Vector2(980, 700)
    world.bridge.interact(0, 1, p.positions)
    world.bridge.interact(1, 1, p.positions)
    world.bridge.interact(0, 1, p.positions)
    p.positions[1] = Vector2(1252, 640)
    world.set_active(true)
    await capture(args[0], "-working")
    world.bridge.interact(1, 1, p.positions)
    world.bridge.interact(0, 1, p.positions)
    p.positions[1] = Vector2(1372, 640)
    world.bridge.interact(1, 1, p.positions)
    p.positions[0] = Vector2(1480, 640)
    p.positions[1] = Vector2(1560, 640)
    p.positions[2] = Vector2(1500, 640)
    world.bridge.interact(0, 1, p.positions)
    world.bridge.interact(1, 1, p.positions)
    await capture(args[0], "-complete")
    print("RENDER_FIXTURE: 2 captures, %d failures" % failures)
    quit(1 if failures else 0)
