extends SceneTree

const Session = preload("res://input/session_state.gd")
var failed: int = 0
var checked: int = 0

func check(condition: bool, label: String) -> void:
    checked += 1
    if not condition:
        failed += 1
        push_error("FAIL: " + label)

func joined():
    var s = Session.new()
    s.menu(12)
    s.menu(34)
    s.menu(12)
    s.menu(34)
    return s

func _initialize() -> void:
    test_join_isolation()
    test_pause_and_disconnect()
    test_focus_gates_all_input()
    test_motion_and_deadzone()
    test_reassignment()
    print("SESSION: %d checks, %d failed" % [checked, failed])
    quit(1 if failed else 0)

func test_join_isolation() -> void:
    var s = Session.new()
    check(s.claim(-1) == -1, "invalid device rejected")
    check(s.claim(12) == 0, "arbitrary first device becomes P1")
    check(s.claim(12) == 0, "same device cannot take P2")
    check(s.claim(34) == 1, "second device becomes P2")
    check(s.claim(56) == -1, "third device rejected")
    check(not s.running(), "joining is not readiness")
    s.menu(12)
    check(not s.running(), "P1 readiness alone cannot run")
    s.menu(34)
    check(s.running(), "two explicit ready confirmations enable session")
    s.menu(56)
    check(s.running(), "third device cannot pause joined session")
    check(s.slot_of(34) == 1, "P2 identity preserved")

func test_pause_and_disconnect() -> void:
    var s = joined()
    s.set_axis(12, 0, 0.8)
    s.menu(12)
    check(not s.running(), "menu pauses")
    check(s.movement(0) == Vector2.ZERO, "pause clears held movement")
    check(not s.ready_flags[0] and not s.ready_flags[1], "pause requires both to reconfirm")
    s.menu(12)
    s.menu(34)
    s.disconnect_device(99)
    check(s.running(), "unbound disconnect cannot interrupt play")
    s.disconnect_device(12)
    check(not s.running(), "bound disconnect pauses immediately")
    check(s.slot_of(34) == 1, "remaining player is not moved into P1")
    check(s.claim(78) == 0, "replacement device claims vacant slot")
    s.menu(78)
    check(not s.running(), "replacement cannot resume alone")
    s.menu(34)
    check(s.running(), "both reconfirm after reconnect")

func test_focus_gates_all_input() -> void:
    var s = joined()
    s.set_focus(false)
    s.menu(12)
    s.menu(34)
    s.set_axis(12, 0, 1.0)
    check(not s.running(), "unfocused menu events cannot resume")
    check(s.movement(0) == Vector2.ZERO, "unfocused motion blocked")
    s.set_focus(true)
    check(not s.running(), "refocus never resumes automatically")
    s.menu(12)
    check(not s.running(), "refocus needs both players")
    s.menu(34)
    check(s.running(), "refocus and both ready resumes")

func test_motion_and_deadzone() -> void:
    var s = joined()
    s.set_axis(12, 0, 0.1)
    check(s.movement(0) == Vector2.ZERO, "small drift ignored")
    s.set_axis(12, 0, 0.6)
    check(s.movement(0).is_equal_approx(Vector2(0.5, 0)), "analog range rescaled after deadzone")
    check(s.movement(1) == Vector2.ZERO, "P1 motion cannot leak into P2")
    s.set_axis(99, 1, 1.0)
    check(s.movement(1) == Vector2.ZERO, "unbound movement ignored")
    s.set_axis(12, 0, 1.0)
    s.set_axis(12, 1, 1.0)
    check(is_equal_approx(s.movement(0).length(), 1.0), "diagonals cannot exceed unit speed")
    s.set_axis(12, 4, 1.0)
    check(is_equal_approx(s.movement(0).length(), 1.0), "trigger axis is not movement")
    s.set_axis(34, 1, -1.0)
    check(s.movement(1).is_equal_approx(Vector2(0, -1)), "P2 uses its own axis")
    check(s.movement(-1) == Vector2.ZERO, "invalid slot safe")
    s.set_axis(12, 0, NAN)
    check(is_finite(s.movement(0).x), "invalid numeric input cannot poison movement")

func test_reassignment() -> void:
    var s = joined()
    s.release_slot(0)
    check(not s.running(), "reassign request pauses")
    check(s.slot_of(12) == -1, "released device can rejoin")
    check(s.slot_of(34) == 1, "other slot is preserved")
    s.release_slot(4)
    check(s.claim(91) == 0, "new device fills explicit vacant slot")
