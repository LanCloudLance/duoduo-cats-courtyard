extends SceneTree
const Session = preload("res://input/session_state.gd")
const Router = preload("res://input/event_router.gd")
var checks := 0
var failed := 0
var actions: Array = []

func check(value: bool, label: String) -> void:
    checks += 1
    if not value:
        failed += 1
        push_error("FAIL: " + label)

func key(router, code: int, down: bool = true, echo: bool = false) -> void:
    var event := InputEventKey.new()
    event.physical_keycode = code as Key
    event.pressed = down
    event.echo = echo
    router.handle(event)

func tap(router, code: int) -> void:
    key(router, code)
    key(router, code, false)

func _initialize() -> void:
    var s = Session.new()
    var r = Router.new(s)
    r.action_pressed.connect(func(slot, code): actions.append([slot, code]))
    tap(r, KEY_E)
    check(actions.is_empty(), "keyboard actions ignored before explicit opt-in")
    tap(r, KEY_ENTER)
    check(s.keyboard_mode and s.running() and s.devices == [-1, -1], "Enter starts keyboard without fake controllers")
    key(r, KEY_D)
    key(r, KEY_UP)
    check(s.movement(0) == Vector2.RIGHT and s.movement(1) == Vector2.UP, "two key groups independently move players")
    key(r, KEY_W)
    check(is_equal_approx(s.movement(0).length(), 1.0), "keyboard diagonal does not increase speed")
    key(r, KEY_W, false)
    key(r, KEY_D, false)
    check(s.movement(0) == Vector2.ZERO and s.movement(1) == Vector2.UP, "releasing P1 movement leaves P2 intact")
    tap(r, KEY_E)
    tap(r, KEY_SPACE)
    check(actions == [[0, JOY_BUTTON_A], [1, JOY_BUTTON_A]], "both keyboard interactions reach correct players")
    key(r, KEY_TAB)
    key(r, KEY_TAB, true, true)
    key(r, KEY_TAB)
    key(r, KEY_TAB, false)
    check(actions.size() == 3 and actions[2] == [1, JOY_BUTTON_Y], "held Tab switches only once")
    tap(r, KEY_R)
    check(not actions.is_empty() and actions.back() == [1, JOY_BUTTON_RIGHT_SHOULDER], "R uses existing cat hold action")
    tap(r, KEY_ESCAPE)
    check(not s.running() and s.movement(1) == Vector2.ZERO, "Escape pauses and clears movement")
    tap(r, KEY_ENTER)
    check(s.running() and s.movement(1) == Vector2.ZERO, "resume does not reuse held arrow")
    var joy := InputEventJoypadButton.new()
    joy.device = 9
    joy.button_index = JOY_BUTTON_START
    joy.pressed = true
    r.handle(joy)
    check(s.running() and s.devices == [-1, -1], "gamepad cannot hijack keyboard session")
    key(r, KEY_D)
    s.set_focus(false)
    tap(r, KEY_E)
    tap(r, KEY_ENTER)
    check(not s.running(), "unfocused keyboard cannot resume or interact")
    s.set_focus(true)
    tap(r, KEY_ENTER)
    check(s.running() and s.movement(0) == Vector2.ZERO, "focus recovery has no stuck key movement")
    print("KEYBOARD: %d checks, %d failed" % [checks, failed])
    quit(1 if failed else 0)
