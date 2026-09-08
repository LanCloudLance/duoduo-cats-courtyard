extends SceneTree
const Session = preload("res://input/session_state.gd")
const Router = preload("res://input/event_router.gd")
var failed: int = 0
var checked: int = 0
var actions: Array = []

func check(value: bool, label: String) -> void:
    checked += 1
    if not value:
        failed += 1
        push_error("FAIL: " + label)

func button(device: int, code: int, pressed: bool = true) -> InputEventJoypadButton:
    var event := InputEventJoypadButton.new()
    event.device = device
    event.button_index = code as JoyButton
    event.pressed = pressed
    return event

func _initialize() -> void:
    var session = Session.new()
    var router = Router.new(session)
    router.action_pressed.connect(func(slot: int, key: int): actions.append([slot, key]))
    router.handle(button(9, JOY_BUTTON_START))
    router.handle(button(18, JOY_BUTTON_START))
    check(session.slot_of(9) == 0 and session.slot_of(18) == 1, "button event device determines slot")
    router.handle(button(9, JOY_BUTTON_X))
    check(actions.is_empty(), "paused attack suppressed")
    router.handle(button(9, JOY_BUTTON_START))
    router.handle(button(18, JOY_BUTTON_START))
    check(session.running(), "real event route readies both")
    router.handle(button(18, JOY_BUTTON_Y))
    check(actions == [[1, JOY_BUTTON_Y]], "P2 switch delivered exactly once")
    router.handle(button(18, JOY_BUTTON_Y, false))
    router.handle(button(99, JOY_BUTTON_X))
    check(actions.size() == 1, "release and unbound device cannot generate actions")
    var axis := InputEventJoypadMotion.new()
    axis.device = 18
    axis.axis = JOY_AXIS_LEFT_Y
    axis.axis_value = -1.0
    router.handle(axis)
    check(session.movement(1).is_equal_approx(Vector2(0, -1)), "motion routed to correct player")
    check(session.movement(0) == Vector2.ZERO, "motion does not cross slots")
    var key := InputEventKey.new()
    key.keycode = KEY_SPACE
    key.pressed = true
    router.handle(key)
    check(actions.size() == 1, "keyboard cannot impersonate joined gamepad")
    router.handle(button(18, JOY_BUTTON_START))
    check(not session.running(), "pause enters through same event route")
    session.set_focus(false)
    router.handle(button(9, JOY_BUTTON_START))
    router.handle(button(18, JOY_BUTTON_START))
    router.handle(button(18, JOY_BUTTON_Y))
    check(not session.running() and actions.size() == 1, "unfocused game receives no ready or action")
    print("ROUTER: %d checks, %d failed" % [checked, failed])
    quit(1 if failed else 0)
