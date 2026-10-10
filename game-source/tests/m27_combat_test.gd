extends SceneTree
const B = preload("res://game/battle_state.gd")
const Solo = preload("res://game/solo_battle.gd")
const Session = preload("res://input/session_state.gd")
const Router = preload("res://input/event_router.gd")
const Visual = preload("res://game/enemy_visual.gd")
var checks := 0
var failed := 0
func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failed += 1
        push_error("FAIL: "+label)
func fixture(cat := 1):
    var b = B.new()
    b.current_cat = cat
    b.positions[0] = Vector2(350,440)
    b.positions[1] = Vector2(350,540)
    b.positions[2] = Vector2(285,595)
    b._spawn("sprout",Vector2(420,440))
    b.enemies[0].hp = 100
    b.enemies[0].mode = "rest"
    b.enemies[0].timer = 99
    return b
func tick(b, seconds: float, hz := 120) -> void:
    for i in range(ceili(seconds*hz)): b.step(1.0/hz,Vector2.ZERO,Vector2.ZERO,true)
func key(r, code: int, down := true) -> void:
    var e := InputEventKey.new()
    e.physical_keycode = code
    e.pressed = down
    r.handle(e)
func _initialize() -> void:
    print("M27_COMBAT_USERDIR ",OS.get_user_data_dir())
    var s = Session.new()
    s.single_player = true
    s.keyboard_mode = true
    s.ready_flags[0] = true
    var r = Router.new(s)
    key(r,KEY_D)
    for i in range(3):
        key(r,KEY_TAB)
        key(r,KEY_TAB,false)
        check(s.movement(0).x > 0.9,"held D survives switch %d" % i)
    key(r,KEY_ESCAPE)
    check(s.movement(0) == Vector2.ZERO,"pause still clears movement")
    s = Session.new()
    s.single_player = true
    s.menu(9)
    s.menu(9)
    r = Router.new(s)
    s.set_axis(9,JOY_AXIS_LEFT_X,0.8)
    var pad := InputEventJoypadButton.new()
    pad.device = 9
    pad.button_index = JOY_BUTTON_Y
    pad.pressed = true
    r.handle(pad)
    check(s.movement(0).x > 0.7,"fixed joystick axis survives Y without another motion")
    s.disconnect_device(9)
    check(s.movement(0) == Vector2.ZERO,"disconnect clears axis")
    var b = fixture()
    var solo = Solo.new()
    b.attack(0)
    solo.engagement = 3.5
    solo.switch_role(b)
    check(b.attacks.pending[0] > 0 and solo.engagement == 3.5,"control handoff preserves sword and engagement")
    tick(b,0.1)
    check(b.enemies[0].hp == 99,"departing sword completes committed hit")
    b = fixture()
    solo = Solo.new()
    b.hold_guard(true)
    solo.switch_role(b)
    solo.step(b,0.016,Vector2.ZERO)
    check(b.guarding,"departing shield keeps a readable committed window")
    b = fixture(2)
    solo = Solo.new()
    b.attack(1)
    tick(b,0.56)
    solo.switch_role(b)
    check(solo.human_slot == 1 and b.current_cat == 2 and b.attacks.charging,"take over currently active charged cat")
    solo.release(b,JOY_BUTTON_X)
    check(b.attacks.kinds[1] == "heavy" and b.attacks.pending[1] > 0,"takeover release commits exactly one heavy")
    b = fixture(2)
    solo = Solo.new()
    solo.switch_role(b)
    check(b.current_cat == 1 and solo.human_slot == 1,"uncharged control rotation still starts with Tuantuan")
    for hz in [60,120]:
        b = fixture()
        b.attack(0)
        tick(b,0.075,hz)
        var pos: Vector2 = b.positions[0]
        var partner: Vector2 = b.positions[1]
        var cooldown: float = b.attack_cooldown[0]
        var flash: float = b.attack_flash[0]
        b.step(1.0/hz,Vector2.RIGHT,Vector2.RIGHT,true)
        check(b.positions[0] == pos and b.attack_cooldown[0] == cooldown and b.attack_flash[0] == flash,"local hitstop freezes motion and action at %d Hz" % hz)
        check(b.positions[1].x > partner.x,"partner moves through local hitstop at %d Hz" % hz)
        b.attack(0)
        check(b.attacks.buffered[0] > 0,"input buffers during contact hold")
        b.dodge(0,Vector2.DOWN)
        check(b.contact_hold[0] == 0 and b.dodge_time[0] > 0,"dodge immediately cancels contact hold")
    for timing in [0.05,0.1,0.18,0.25]:
        b = fixture()
        b.attack(0)
        tick(b,timing)
        for i in range(10): b.attack(0)
        tick(b,0.7)
        check(b.enemies[0].hp == (99 if timing < 0.065 else 98),"one followup after active frame at %.2f seconds" % timing)
    b = fixture()
    b.phase = "combat"
    b.attacks.combo = 2
    b.attacks.combo_window = 0.8
    b.hurt(0,b.positions[0]-Vector2(20,0),false)
    b.attack(0)
    check(b.attacks.pending[0] < 0 and b.attack_flash[0] == 0,"hurt cannot immediately overlap an active attack")
    tick(b,0.09)
    check(b.attacks.pending[0] > 0 and b.attacks.current_combo == 0,"hurt buffers once then starts fresh combo after short stun")
    b = fixture()
    b.phase = "combat"
    b.hurt(0,b.positions[0]-Vector2(20,0),false)
    b.dodge(0,Vector2.DOWN)
    check(b.hurt_time[0] == 0 and b.dodge_time[0] > 0,"dodge cancels hurt pose immediately")
    b = fixture()
    b.attacks.combo = 2
    b.attacks.combo_window = 0.8
    b.enemies[0].mark_time = 1.8
    var before: Vector2 = b.enemies[0].pos
    b.attack(0)
    tick(b,0.13)
    check(b.enemies[0].mark_time > 1.5,"third sword leaves Tuantuan mark for Yuanyuan")
    check(b.enemies[0].pos.x > before.x and not b.message.contains("圆圆把"),"sword finisher has own knockback and correct attribution")
    b = fixture()
    b.enemies[0].kind = "armored"
    b.enemies[0].mode = "exposed"
    b.enemies[0].direction = Vector2.RIGHT
    b.attacks.combo = 2
    b.attacks.combo_window = 0.8
    before = b.enemies[0].pos
    b.attack(0)
    tick(b,0.13)
    check(b.enemies[0].hp == 98 and b.enemies[0].pos == before,"sword finisher damages rear knot without moving anchored armor")
    b = fixture()
    b.phase = "combat"
    b.hold_guard(true)
    b.hurt(0,b.positions[0]-Vector2(30,0))
    check(not b.guarding and b.hurt_time[0] > 0,"rear hurt immediately replaces the shield pose")
    for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
        b = fixture()
        var enemy: Dictionary = b.enemies[0]
        b.contact(enemy,0,direction,false,false)
        var view = Visual.new()
        view.sync(enemy)
        check((view.body.position-view.action_pose.offset).dot(direction) > 0,"visual recoil follows actual force %s" % direction)
        view.free()
    b = fixture()
    b.phase = "combat"
    b.positions[1] = Vector2(376,440)
    b.positions[2] = Vector2(220,560)
    b.enemies[0].mark_time = 1.8
    var handoff: Vector2 = b.positions[1]
    b.switch_cat()
    check(b.positions[2] == handoff,"cat relay retains reachable combat point")
    b.attack(1)
    tick(b,0.5)
    b.release_attack(1)
    tick(b,0.13)
    check(b.enemies[0].hp == 96 and b.enemies[0].mark_time == 0 and b.enemies[0].control_time > 0.6,"relay heavy owns three damage and marked control")
    b = fixture()
    b.positions[1] = b.enemies[0].pos-Vector2(44,0)
    for i in range(30): b.step(1.0/120,Vector2.ZERO,Vector2.RIGHT,true)
    check(b.positions[1].distance_to(b.enemies[0].pos) >= 43.9,"normal movement cannot walk through pounce contact")
    print("M27_COMBAT: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
