extends SceneTree
# Frozen presentation fixtures, not a gameplay-completion test.
const Session = preload("res://input/session_state.gd")
const Arena = preload("res://game/arena.gd")
var arena
var captures := 0
var failed := 0
var prefix := ""
func _initialize() -> void: run.call_deferred()
func capture(suffix: String) -> void:
    for i in range(8):
        arena._physics_process(0)
        await process_frame
    await RenderingServer.frame_post_draw
    if root.get_texture().get_image().save_png(prefix+suffix+".png") != OK: failed += 1
    captures += 1
func room(cat := 1):
    arena.configure_solo(false)
    var b = arena.battle
    b.current_cat = cat
    b.positions[0] = Vector2(530,470)
    b.positions[1] = Vector2(810,500)
    b.positions[2] = Vector2(420,560)
    b._spawn("sprout",Vector2(610,470))
    b.enemies[0].hp = 30
    b.enemies[0].mode = "rest"
    b.enemies[0].timer = 99
    return b
func run() -> void:
    if DisplayServer.get_name() == "headless": quit(1); return
    prefix = OS.get_cmdline_user_args()[0]
    var host := Control.new()
    host.theme = Theme.new()
    host.theme.default_font = load("res://assets/fonts/CourtyardSans.ttf")
    root.add_child(host)
    var session = Session.new()
    session.keyboard_mode = true
    session.ready_flags[0] = true
    session.ready_flags[1] = true
    arena = Arena.new(session)
    host.add_child(arena)
    arena.set_active(true)
    arena.set_physics_process(false)
    var b = room()
    for index in range(3):
        b.attack(0)
        b.step(0.07 if index < 2 else 0.12,Vector2.ZERO,Vector2.ZERO,true)
        await capture("-sword%d" % (index+1))
        b.attack_cooldown[0] = 0
    b = room(1)
    b.positions[1] = Vector2(520,470)
    b.attack(1)
    b.step(0.10,Vector2.ZERO,Vector2.ZERO,true)
    await capture("-pounce")
    b = room(2)
    b.positions[2] = Vector2(530,470)
    b.facing[1] = Vector2.RIGHT
    b.attack(1)
    for i in range(6): b.step(0.1,Vector2.ZERO,Vector2.ZERO,true)
    await capture("-charge")
    b.release_attack(1)
    b.step(0.1,Vector2.ZERO,Vector2.ZERO,true)
    b.step(0.01,Vector2.ZERO,Vector2.ZERO,true)
    await capture("-heavy")
    b = room()
    b.phase = "combat"
    b.enemies[0].hp = 1
    b.attack(0)
    b.step(0.07,Vector2.ZERO,Vector2.ZERO,true)
    b.step(0.1,Vector2.ZERO,Vector2.ZERO,true)
    await capture("-defeat")
    print("M19_CONTACT_RENDER: %d captures, %d failures" % [captures,failed])
    quit(1 if failed else 0)
