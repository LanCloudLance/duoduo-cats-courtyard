extends SceneTree
const Bridge = preload("res://game/bridge_state.gd")
var checks := 0
var failed := 0

func check(value: bool, label: String) -> void:
    checks += 1
    if not value:
        failed += 1
        push_error("FAIL: " + label)

func _initialize() -> void:
    var b = Bridge.new()
    var p: Array[Vector2] = [Vector2(500, 620), Vector2(1000, 640), Vector2(980, 720)]
    check(not b.interact(0, 1, p) and b.deployed == 0, "distant player cannot turn winch")
    p[0] = Vector2(960, 620)
    check(not b.interact(1, 1, p) and b.deployed == 0, "cat cannot operate winch")
    check(b.interact(0, 1, p) and b.deployed == 1, "girl unfolds first platform")
    check(not b.interact(0, 1, p) and b.deployed == 1, "repeated turn cannot skip locked latch")
    check(b.allows(1, Vector2(1100, 640)), "black cat can enter deployed passage")
    check(not b.allows(0, Vector2(1100, 640)), "girl cannot bypass cat passage")
    check(not b.allows(2, Vector2(1100, 640)), "white cat waits until permanent bridge")
    check(not b.allows(1, Vector2(1220, 640)), "unopened next platform blocks progress")
    check(not b.allows(1, Vector2(1100, 400)), "water outside passage blocks crossing")
    check(not b.interact(1, 1, p) and b.unlocked == 0, "cat cannot unlock at a distance")
    p[1] = Vector2(1132, 640)
    p[2] = Vector2(1132, 640)
    check(not b.interact(1, 2, p) and b.unlocked == 0, "white cat cannot impersonate black cat latch action")
    check(b.interact(1, 1, p) and b.unlocked == 1, "black cat secures first latch")
    check(b.would_fall(1, Vector2(1120, 662), Vector2(1120, 669)), "stepping off narrow side detects fall")
    var safe: Vector2 = b.recover()
    check(safe == Vector2(1132, 640) and b.unlocked == 1 and b.falls == 1, "fall restores checkpoint without losing latch")
    check(not b.would_fall(2, Vector2(1120, 662), Vector2(1120, 669)), "white cat does not use scaffold fall rule")
    for i in [1, 2]:
        check(b.interact(0, 1, p), "girl unfolds next platform after latch")
        p[1] = Vector2(1132 + 120 * i, 640)
        check(b.interact(1, 1, p), "black cat secures next latch")
    check(b.unlocked == 3 and b.deployed == 3, "three alternating rounds complete bridge")
    check(b.allows(0, Vector2(1200, 680)) and b.allows(2, Vector2(1300, 600)), "permanent bridge admits girl and white cat")
    check(not b.allows(0, Vector2(1200, 900)), "completed bridge does not make whole river walkable")
    check(not b.would_fall(1, Vector2(1120, 662), Vector2(1120, 669)), "permanent bridge removes narrow scaffold fall rule")
    p[0] = Vector2(1540, 640)
    p[1] = Vector2(1540, 640)
    p[2] = Vector2(980, 720)
    b.interact(0, 1, p)
    b.interact(1, 1, p)
    check(not b.finished, "two confirmations cannot leave white cat behind")
    p[0] = Vector2(1300, 640)
    b.tick(p, 1)
    check(not b.confirmed[0], "leaving exit cancels player confirmation")
    p[0] = Vector2(1540, 640)
    p[2] = Vector2(1530, 700)
    b.tick(p, 2)
    check(not b.confirmed[1], "switching cats invalidates earlier P2 confirmation")
    b.interact(0, 2, p)
    b.interact(1, 2, p)
    check(b.finished, "all three together and both players confirm completion")
    print("BRIDGE: %d checks, %d failed" % [checks, failed])
    quit(1 if failed else 0)
