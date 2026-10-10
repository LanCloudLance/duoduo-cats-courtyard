extends SceneTree
var failed := 0
var checks := 0
func check(value: bool,label: String) -> void:
    checks += 1
    if not value: failed += 1; push_error("FAIL: "+label)
func _initialize() -> void:
    var store = load("res://game/checkpoint.gd").new()
    var rest = load("res://game/rest_state.gd").new()
    var legacy := {"version":1,"safe_point":"rest","rested":true,"current_cat":1,"completed":{"bridge":true,"combat":true,"light":true}}
    var old: Dictionary = store._canonical(legacy)
    check(not old.is_empty() and not old.completed.has("gate"),"legacy checkpoint remains valid without claiming new gate completed")
    rest.restore(old)
    check(rest.full_run(),"legacy journey keeps its historical completion status")
    legacy.completed["gate"] = true
    var current: Dictionary = store._canonical(legacy)
    check(current.completed.get("gate",false),"new safe point preserves completed bell gate")
    legacy.completed["gate"] = false
    rest.restore(store._canonical(legacy))
    check(not rest.full_run(),"new journey cannot claim full run without bell gate")
    legacy.completed["gate"] = "yes"
    check(store._canonical(legacy).is_empty(),"malformed optional gate status never overwrites saved progress")
    print("M21_CHECKPOINT: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
