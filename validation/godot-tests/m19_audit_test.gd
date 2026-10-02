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
func supported_bridge():
    var s = Light.new()
    s.phase = "girl"
    s.positions[0] = Map.FRONT_LOCK
    s.interact(0)
    s.interact(0)
    s.tool(0)
    return s
func _initialize() -> void:
    # Break caught: feedback assumes removing one support removes both supports.
    var s = supported_bridge()
    s.interact(0)
    check(s.pin_site == "carried" and s.pin_actor == 0 and s.bracing and s.front_fixed,
        "taking pin leaves the manually held bridge walkable")
    check(s.message.contains("撑") and not s.message.contains("收了回去"),
        "pin retrieval feedback explains the remaining manual support")
    # Break caught: leaving the handle reports withdrawal despite an installed pin.
    s = supported_bridge()
    s.step(0.05,Vector2.UP,Vector2.ZERO,true)
    check(not s.bracing and s.pin_site == "front" and s.front_fixed,
        "moving away leaves the pinned bridge walkable")
    check(s.message.contains("桥扣") and not s.message.contains("收回去了"),
        "handle release feedback explains the remaining pin support")
    # Break caught: reinspection of a completed winch incorrectly reports missing pin.
    s = supported_bridge()
    s.interact(0)
    s.positions[2] = Map.LAMP_SAFE
    s.current_cat = 2
    s.tool(1)
    s.current_cat = 1
    s.positions[1] = Map.FAR_LOCK
    s.tool(1)
    s.positions[0] = Map.FAR_WINCH
    s.interact(0)
    check(s.permanent and s.pin_site == "far","single recovered pin secures the far bridge")
    s.interact(0)
    check(s.permanent and s.pin_site == "far" and s.message.contains("锁") and not s.message.contains("少"),
        "secured winch reinspection reports its actual completed state")
    print("M19_AUDIT: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
