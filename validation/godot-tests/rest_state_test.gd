extends SceneTree
var checks := 0
var failed := 0
func check(value: bool, label: String) -> void:
    checks += 1
    if not value:
        failed += 1
        push_error("FAIL: " + label)
func _initialize() -> void:
    if not ResourceLoader.exists("res://game/rest_state.gd"):
        check(false, "rest area must provide cooperative rest and exit")
        print("REST_STATE: %d checks, %d failed" % [checks, failed])
        quit(1)
        return
    var S = load("res://game/rest_state.gd")
    var s = S.new()
    s.hp[0] = 1
    s.hp[1] = 2
    s.interact(0)
    s.interact(1)
    check(not s.rested, "distant players cannot trigger rest")
    s.positions[0] = Vector2(610, 460)
    s.positions[1] = Vector2(690, 460)
    s.positions[2] = Vector2(350, 550)
    s.interact(0)
    s.interact(1)
    check(not s.rested, "bench waits for inactive cat too")
    s.positions[2] = Vector2(600, 520)
    s.step(0.01, Vector2.ZERO, Vector2.ZERO, true)
    check(s.rested and s.hp == [3, 3], "whole party rest restores both health pools")
    check(s.sitting[0] and s.sitting[1], "both players sit at cooperative rest")
    var saved: Array = s.positions.duplicate()
    s.step(0.1, Vector2.RIGHT, Vector2.UP, false)
    check(s.positions == saved and s.sitting[0], "pause freezes seated state")
    s.step(0.1, Vector2.RIGHT, Vector2.ZERO, true)
    check(s.rested and not s.sitting[0], "movement stands girl up without losing rest checkpoint")
    s.positions[0] = Vector2(820, 440)
    s.positions[1] = Vector2(860, 440)
    s.positions[2] = Vector2(835, 470)
    s.interact(0)
    check(s.pets[0] == 1 and s.hp == [3, 3], "petting prioritizes nearby player-controlled cat even if follower is closer")
    var first: String = s.message
    s.step(1.0, Vector2.ZERO, Vector2.ZERO, true)
    s.interact(0)
    check(s.pets[0] == 1, "pet input cannot spam through cooldown")
    for i in range(15): s.step(0.1, Vector2.ZERO, Vector2.ZERO, true)
    s.interact(0)
    check(s.pets[0] == 2 and s.message != first, "black cat has a second distinct gentle reaction")
    s.current_cat = 2
    s.positions[2] = Vector2(850, 440)
    s.positions[1] = Vector2(700, 540)
    for i in range(15): s.step(0.1, Vector2.ZERO, Vector2.ZERO, true)
    s.interact(0)
    check(s.pets[1] == 1, "white cat has its own calm pet interaction")
    s.interact(1)
    check(s.greetings[1] == 1, "cat player can initiate contact with girl")
    s.positions[0] = Vector2(1090, 460)
    s.positions[2] = Vector2(1120, 470)
    s.positions[1] = Vector2(700, 540)
    s.interact(0)
    s.interact(1)
    check(not s.finished, "exit waits for inactive cat")
    s.positions[1] = Vector2(1060, 480)
    s.step(0.01, Vector2.ZERO, Vector2.ZERO, true)
    check(s.finished, "both confirmations and all three finish rest exit")
    s = S.new()
    s.positions[0] = Vector2(1090, 460)
    s.positions[1] = Vector2(1120, 470)
    s.positions[2] = Vector2(1060, 480)
    s.interact(0)
    s.interact(1)
    check(not s.finished, "cannot skip cooperative rest by going straight to exit")
    s.progress = {"bridge":true,"combat":false,"light":true}
    check(not s.full_run(), "shortcut visit does not claim skipped combat completed")
    s.progress.combat = true
    check(s.full_run(), "completion summary recognizes all three cleared stages")
    print("REST_STATE: %d checks, %d failed" % [checks, failed])
    quit(1 if failed else 0)
