extends SceneTree
# Continuously running contact fixture with production keyboard routing.
# High-health stationary target isolates feedback; it is not encounter acceptance.
const Session = preload("res://input/session_state.gd")
const Router = preload("res://input/event_router.gd")
const Arena = preload("res://game/arena.gd")
var router
func key(code: int, down: bool) -> void:
    var event := InputEventKey.new()
    event.physical_keycode = code
    event.pressed = down
    router.handle(event)
func _initialize() -> void: run.call_deferred()
func run() -> void:
    if DisplayServer.get_name() == "headless": quit(1); return
    Engine.max_fps = 60
    var prefix: String = OS.get_cmdline_user_args()[0]
    var host := Control.new()
    host.theme = Theme.new()
    host.theme.default_font = load("res://assets/fonts/CourtyardSans.ttf")
    root.add_child(host)
    var s = Session.new()
    s.keyboard_mode = true
    s.ready_flags[0] = true
    s.ready_flags[1] = true
    var arena = Arena.new(s)
    host.add_child(arena)
    arena.set_active(true)
    router = Router.new(s)
    router.action_pressed.connect(arena.handle_action)
    router.action_released.connect(arena.release_action)
    router.actions_cancelled.connect(arena.cancel_inputs)
    var b = arena.battle
    b.positions[0] = Vector2(440,430)
    b.positions[1] = Vector2(450,510)
    b.positions[2] = Vector2(385,565)
    b._spawn("sprout",Vector2(510,450))
    b.enemies[0].hp = 100
    b.enemies[0].max_hp = 100
    b.enemies[0].mode = "rest"
    b.enemies[0].timer = 99
    var trace: Array = []
    var captures := 0
    for frame in range(160):
        if frame == 1: key(KEY_D,true); key(KEY_F,true)
        if frame == 2: key(KEY_F,false)
        if frame == 8: key(KEY_F,true)
        if frame == 9: key(KEY_F,false)
        if frame == 30: key(KEY_D,false)
        if frame == 34: key(KEY_UP,true)
        if frame == 48: key(KEY_UP,false); key(KEY_RIGHT,true)
        if frame == 49: key(KEY_RIGHT,false); key(KEY_J,true)
        if frame == 50: key(KEY_J,false)
        if frame == 65: key(KEY_TAB,true)
        if frame == 66: key(KEY_TAB,false)
        if frame == 75: key(KEY_J,true)
        if frame == 108: key(KEY_J,false)
        await physics_frame
        await process_frame
        trace.append({"frame":frame,"girl":str(b.positions[0]),"cat":str(b.positions[b.current_cat]),"hold":b.contact_hold.duplicate(),"flash":b.attack_flash.duplicate(),"target_hp":b.enemies[0].hp,"kind":b.attacks.kinds[1]})
        if frame in [4,6,10,50,80,114]:
            await RenderingServer.frame_post_draw
            if root.get_texture().get_image().save_png(prefix+"-%03d.png" % frame) == OK: captures += 1
    var output := FileAccess.open(prefix+"-trace.json",FileAccess.WRITE)
    output.store_string(JSON.stringify(trace,"  "))
    print("M27_COMBAT_RENDER: 160 continuous render samples, ",captures," captures, final hp=",b.enemies[0].hp," userdir=",OS.get_user_data_dir())
    quit(0 if captures == 6 else 1)
