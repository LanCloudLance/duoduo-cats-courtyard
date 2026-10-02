extends SceneTree
const Light = preload("res://game/light_state.gd")
const Map = preload("res://game/light_layout.gd")
var checks := 0
var failed := 0
func check(value: bool, label: String) -> void:
    checks += 1
    if not value:
        failed += 1
        push_error("FAIL: "+label)
func ready_room():
    var s = Light.new()
    s.phase = "girl"
    s.positions[0] = Map.FRONT_LOCK
    s.positions[1] = Map.RELAY
    return s
func _initialize() -> void:
    var s = ready_room()
    check(s.get("pin_site") != null,"one reusable bridge pin exists")
    if failed:
        finish()
        return
    s.interact(0)
    check(s.pin_site == "carried" and not s.front_fixed,"taking loose pin does not solve bridge")
    s.interact(0)
    check(s.pin_site == "front" and s.front_fixed,"same physical pin supports front bridge")
    s.positions[2] = Vector2(410,480)
    s.interact(0)
    check(s.pin_site == "front" and s.front_fixed,"loaded bridge rejects removal atomically")
    s.positions[2] = Map.LAMP_NEAR
    s.interact(0)
    check(s.pin_site == "carried" and not s.front_fixed,"recovering pin really withdraws first crossing")
    s.solo_mode = true
    s.tool(0)
    s.step(0.05,Vector2.ZERO,Vector2.ZERO,true)
    check(s.front_fixed and s.bracing,"manual support persists while solo switches actors")
    s.step(0.05,Vector2.UP,Vector2.ZERO,true)
    check(not s.front_fixed and not s.bracing,"moving away releases manual support")
    s.positions[2] = Map.LAMP_SAFE
    s.current_cat = 2
    s.tool(1)
    s.current_cat = 1
    s.positions[1] = Map.FAR_LOCK
    s.tool(1)
    s.positions[0] = Map.FAR_WINCH
    s.interact(0)
    check(s.permanent and s.pin_site == "far","reused pin and far latch together secure exit bridge")
    s = ready_room()
    s.positions[2] = Map.LAMP_SAFE
    s.current_cat = 2
    s.tool(1)
    s.current_cat = 1
    s.positions[1] = Map.FAR_LOCK
    s.tool(1)
    s.positions[0] = Map.FAR_WINCH
    s.interact(0)
    check(not s.permanent,"far winch cannot invent a second pin")
    s.positions[1] += Vector2(0,70)
    s.step(0.02,Vector2.ZERO,Vector2.ZERO,true)
    check(not s.latched,"spring latch releases if black cat leaves before securing bridge")
    s = ready_room()
    s.solo_mode = true
    s.interact(0)
    s.tool(0)
    s.current_cat = 2
    s.positions[2] = Vector2(270,480)
    for i in range(160): s.step(0.01,Vector2.ZERO,Vector2.RIGHT,true)
    check(s.positions[2].x > 580 and s.pin_site == "carried" and s.bracing,"alternate manual support route brings white across without installing pin")
    s.step(0.01,Vector2.UP,Vector2.ZERO,true)
    check(not s.front_fixed and s.positions[2].x > 580,"support can be recovered after last partner crosses")
    s = Light.new()
    check(not s.objective().contains("①") and not s.objective().contains("先"),"goal does not reveal solution order")
    var before: Array = s.positions.duplicate()
    s.request_hint()
    s.request_hint()
    s.request_hint()
    check(s.hint_level == 3 and s.positions == before and not s.front_fixed,"requested hints explain without auto-solving")
    finish()
func finish() -> void:
    print("M19_PUZZLE: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
