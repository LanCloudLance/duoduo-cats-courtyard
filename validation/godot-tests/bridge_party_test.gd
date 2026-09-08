extends SceneTree
const Bridge = preload("res://game/bridge_state.gd")
const Party = preload("res://game/party_state.gd")
var checks := 0
var failed := 0

func check(value: bool, label: String) -> void:
    checks += 1
    if not value:
        failed += 1
        push_error("FAIL: " + label)

func advance(p, count: int, girl: Vector2 = Vector2.ZERO, cat: Vector2 = Vector2.ZERO) -> void:
    for i in range(count):
        p.step(1.0 / 60.0, girl, cat, true)

func _initialize() -> void:
    var b = Bridge.new()
    var p = Party.new(b)
    p.positions[0] = Vector2(1000, 640)
    p.positions[1] = Vector2(980, 640)
    p.positions[2] = Vector2(940, 700)
    advance(p, 60, Vector2.RIGHT)
    check(p.positions[0].x <= 1024, "girl cannot walk into closed river")
    p.positions[0] = Vector2(960, 620)
    b.interact(0, 1, p.positions)
    advance(p, 60, Vector2.ZERO, Vector2.RIGHT)
    check(p.positions[1].x > 1120 and p.positions[1].x <= 1144, "cat walks first platform and stops at unopened gap")
    check(p.positions[2].x < 1024, "following white cat does not enter narrow passage")
    b.interact(1, 1, p.positions)
    advance(p, 20, Vector2.ZERO, Vector2.UP)
    check(b.falls == 1 and p.positions[1] == Vector2(1132, 640), "sideways misstep returns actual cat to checkpoint")
    check(b.unlocked == 1, "recovery retains completed first latch")
    p.switch_cat()
    advance(p, 80, Vector2.ZERO, Vector2.LEFT)
    check(p.positions[1] == Vector2(1132, 640), "inactive black cat waits safely in narrow passage")
    p.switch_cat()
    check(p.current_cat == 1 and p.positions[1] == Vector2(1132, 640), "switching back resumes at same platform")
    p.positions[0] = Vector2(960, 620)
    for i in [1, 2]:
        b.interact(0, 1, p.positions)
        p.positions[1] = Vector2(1132 + 120 * i, 640)
        b.interact(1, 1, p.positions)
    p.positions[0] = Vector2(1500, 640)
    p.positions[1] = Vector2(1540, 640)
    p.positions[2] = Vector2(980, 640)
    advance(p, 300)
    check(p.positions[2].x > 1416, "navigation rebuild lets white cat cross completed bridge")
    p.positions[0] = Vector2(1540, 920)
    advance(p, 100, Vector2.LEFT)
    check(p.positions[0].x >= 1416, "cannot bypass bridge by crossing water farther south")
    var before: Array = p.positions.duplicate()
    p.step(1.0, Vector2.RIGHT, Vector2.RIGHT, false)
    check(p.positions == before and b.unlocked == 3, "paused movement preserves party and completed bridge")
    print("BRIDGE_PARTY: %d checks, %d failed" % [checks, failed])
    quit(1 if failed else 0)
