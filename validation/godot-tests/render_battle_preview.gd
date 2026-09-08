extends SceneTree
# Synthetic rendering fixture only; battle_scene_test covers production routing.
const Session = preload("res://input/session_state.gd")
const Arena = preload("res://game/arena.gd")
var failures := 0
func _initialize() -> void:
    call_deferred("run")
func capture(prefix: String, suffix: String) -> void:
    for i in range(15):
        # Advance only presentation smoothing while the fixture state stays frozen.
        for host in root.get_children():
            for child in host.get_children():
                if child is Arena:
                    for actor in child.actors:
                        if actor.painted:
                            actor.painted.pose_delta = 1.0/60.0
                            actor.painted.pose(actor.phase,actor.stride,actor.facing,actor.reaction)
        await process_frame
    await RenderingServer.frame_post_draw
    if root.get_texture().get_image().save_png(prefix + suffix + ".png") != OK:
        failures += 1
func run() -> void:
    var args := OS.get_cmdline_user_args()
    if args.is_empty() or DisplayServer.get_name() == "headless":
        quit(1)
        return
    var host := Control.new()
    var font := SystemFont.new()
    font.font_names = PackedStringArray(["Microsoft YaHei", "PingFang SC", "Noto Sans CJK SC"])
    host.theme = Theme.new()
    host.theme.default_font = font
    root.add_child(host)
    var session = Session.new()
    session.keyboard_mode = true
    session.ready_flags[0] = true
    session.ready_flags[1] = true
    var arena = Arena.new(session)
    host.add_child(arena)
    arena.set_active(true)
    arena.set_physics_process(false)
    var b = arena.battle
    b._start_wave(3)
    b.positions[0] = Vector2(585,440)
    b.positions[1] = Vector2(915,470)
    b.positions[2] = Vector2(440,590)
    b.enemies[0].pos = Vector2(760,440)
    b.enemies[0].mode = "windup"
    b.enemies[0].direction = Vector2.LEFT
    b.enemies[0].timer = 0.6
    b.enemies[1].pos = Vector2(1010,560)
    b.enemies[1].mode = "approach"
    b.guarding = true
    arena._physics_process(0)
    await capture(args[0],"-combat")
    b.enemies[0].pos = Vector2(690,440)
    b.enemies[0].mode = "exposed"
    b.enemies[0].opening = "shield"
    b.enemies[0].timer = 2.0
    b.positions[0] = Vector2(626,440)
    b.positions[1] = Vector2(785,480)
    b.message = "挡住了！猫咪绕到展开的结点一侧，朵朵也可以放盾接应。"
    arena._physics_process(0)
    await capture(args[0],"-opening")
    root.size = Vector2i(1280,720)
    await capture(args[0],"-16x9")
    root.size = Vector2i(1280,800)
    b.hp[0] = 0
    b.guarding = false
    b.positions[0] = Vector2(400,440)
    b.positions[1] = Vector2(465,440)
    for enemy in b.enemies: enemy.mode = "rest"
    b.interact(1)
    b.rescue_progress = 0.7
    arena._physics_process(0)
    await capture(args[0],"-rescue")
    print("BATTLE_RENDER: 4 captures, %d failures" % failures)
    quit(1 if failures else 0)
