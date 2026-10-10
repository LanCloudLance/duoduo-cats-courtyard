extends SceneTree
const Party = preload("res://game/party_state.gd")
var checked: int = 0
var failed: int = 0

func check(value: bool, label: String) -> void:
    checked += 1
    if not value:
        failed += 1
        push_error("FAIL: " + label)

func advance(party, frames: int, p1: Vector2 = Vector2.ZERO, p2: Vector2 = Vector2.ZERO, enabled: bool = true) -> void:
    for frame in range(frames):
        party.step(1.0 / 60.0, p1, p2, enabled)

func _initialize() -> void:
    var s = Party.new()
    var cat_start: Vector2 = s.positions[1]
    advance(s, 60, Vector2.RIGHT)
    check(s.positions[0].is_equal_approx(Vector2(620, 600)), "P1 moves 220 units in one second")
    check(s.positions[1] == cat_start, "P1 does not move the active cat")
    s = Party.new()
    advance(s, 60, Vector2.ONE)
    check(is_equal_approx(s.positions[0].distance_to(Vector2(400, 600)), 220.0), "diagonal speed equals straight speed")
    s = Party.new()
    advance(s, 30, Vector2.ZERO, Vector2.RIGHT)
    check(s.positions[1].x > 600 and s.positions[0] == Vector2(400, 600), "P2 moves own cat only")
    var before: Array = s.positions.duplicate()
    advance(s, 120, Vector2.ONE, Vector2.ONE, false)
    check(s.positions == before, "pause freezes active and following characters")
    s = Party.new()
    s.positions[0] = Vector2(680, 440)
    advance(s, 180, Vector2.RIGHT)
    check(s.positions[0].x <= 704.0, "flowerbed blocks direct movement")
    s.positions[0] = Vector2(100, 600)
    advance(s, 120, Vector2.LEFT)
    check(s.positions[0].x >= 96.0, "outer wall blocks movement")
    s = Party.new()
    before = s.positions.duplicate()
    s.switch_cat()
    check(s.current_cat == 2 and s.positions == before, "switch changes control without teleporting")
    advance(s, 20, Vector2.ZERO, Vector2.DOWN)
    check(s.positions[2].y > 720, "new active cat consumes P2 movement")
    s.switch_cat()
    check(s.current_cat == 1, "second switch returns to black cat")
    s = Party.new()
    check(not s.toggle_hold() and not s.holding[1], "cannot hold outside a marked pad")
    s.positions[1] = Vector2(540, 700)
    check(s.toggle_hold() and s.holding[1], "cat can hold at a marked pad")
    s.switch_cat()
    advance(s, 90, Vector2.ZERO, Vector2.RIGHT)
    check(s.positions[1] == Vector2(540, 700), "inactive held cat stays at pad")
    s.switch_cat()
    advance(s, 10, Vector2.ZERO, Vector2.LEFT)
    check(not s.holding[1] and s.positions[1].x < 540, "moving selected cat releases hold")
    s = Party.new()
    s.positions[1] = Vector2(620, 440)
    s.positions[2] = Vector2(940, 440)
    var crossed_obstacle := false
    for frame in range(600):
        s.step(1.0 / 60.0, Vector2.ZERO, Vector2.ZERO, true)
        if Rect2(704, 304, 192, 272).has_point(s.positions[2]):
            crossed_obstacle = true
    check(not crossed_obstacle, "following cat never crosses expanded flowerbed")
    check(s.positions[2].distance_to(s.positions[1]) < 85, "following cat routes around flowerbed and rejoins")
    s = Party.new()
    advance(s, 400, Vector2.LEFT, Vector2.RIGHT)
    check(absf(s.positions[0].x - s.positions[1].x) <= 880.01, "shared view limits horizontal separation")
    var old_gap: float = s.positions[0].distance_to(s.positions[1])
    advance(s, 30, Vector2.RIGHT, Vector2.LEFT)
    check(s.positions[0].distance_to(s.positions[1]) < old_gap, "range limit still allows moving toward partner")
    var center: Vector2 = s.camera_center()
    var zoom: float = s.camera_zoom()
    var all_visible := true
    for point in s.positions:
        var screen: Vector2 = (point - center) * zoom + Vector2(640, 400)
        all_visible = all_visible and Rect2(64, 140, 1152, 536).has_point(screen)
    check(all_visible, "shared camera fits all three beneath HUD")
    s = Party.new()
    s.positions[2] = Vector2(540, 700)
    s.holding[2] = true
    advance(s, 360, Vector2.UP, Vector2.UP)
    check(s.positions[0].y >= 260 and s.positions[1].y >= 260, "held inactive cat also limits vertical separation")
    check(s.positions[2] == Vector2(540, 700), "range constraint never drags the held cat")
    center = s.camera_center()
    zoom = s.camera_zoom()
    all_visible = true
    for point in s.positions:
        var screen: Vector2 = (point - center) * zoom + Vector2(640, 400)
        all_visible = all_visible and Rect2(64, 140, 1152, 536).has_point(screen)
    check(all_visible, "vertical limit keeps held and active cats visible")
    print("PARTY: %d checks, %d failed" % [checked, failed])
    quit(1 if failed else 0)
