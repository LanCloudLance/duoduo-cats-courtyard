extends SceneTree
var checks := 0
var failed := 0
func check(value: bool, label: String) -> void:
    checks += 1
    if not value:
        failed += 1
        push_error("FAIL: " + label)
func _initialize() -> void:
    if not ResourceLoader.exists("res://game/checkpoint.gd"):
        check(false, "safe point must survive a fresh reader")
        print("CHECKPOINT: %d checks, %d failed" % [checks, failed])
        quit(1)
        return
    var Store = load("res://game/checkpoint.gd")
    var path := "user://test-m6-checkpoint.json"
    DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    var store = Store.new(path)
    check(store.read_checkpoint().is_empty(), "missing save safely returns no checkpoint")
    var data := {"version":1,"safe_point":"rest","rested":true,"current_cat":2,"completed":{"bridge":true,"combat":false,"light":true}}
    check(store.save_checkpoint(data), "valid rest checkpoint writes successfully")
    var fresh = Store.new(path)
    var loaded: Dictionary = fresh.read_checkpoint()
    check(not loaded.is_empty() and loaded.current_cat == 2 and loaded.completed.combat == false, "fresh reader keeps selected cat and honest partial progress")
    var invalid := data.duplicate(true)
    invalid.current_cat = 9
    check(not store.save_checkpoint(invalid), "invalid cat index is rejected before overwriting")
    check(fresh.read_checkpoint().get("current_cat") == 2, "rejected write preserves previous checkpoint")
    invalid.current_cat = 1.5
    check(not store.save_checkpoint(invalid), "fractional cat identifiers cannot be truncated into valid saves")
    data.current_cat = 1
    data.completed.combat = true
    check(store.save_checkpoint(data) and fresh.read_checkpoint().get("completed", {}).get("combat", false), "atomic replacement updates an existing checkpoint")
    var file := FileAccess.open(path, FileAccess.WRITE)
    file.store_string("{broken")
    file.close()
    check(fresh.read_checkpoint().is_empty() and not fresh.last_error.is_empty(), "corrupt JSON returns an error without crashing")
    file = FileAccess.open(path, FileAccess.WRITE)
    file.store_string('{"version":2,"safe_point":"rest"}')
    file.close()
    check(fresh.read_checkpoint().is_empty(), "unsupported save version is not silently accepted")
    var blocked = Store.new("user://missing-m6-folder/no-save.json")
    check(not blocked.save_checkpoint(data) and not blocked.last_error.is_empty(), "failed file write is reported rather than claiming saved")
    DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    DirAccess.remove_absolute(ProjectSettings.globalize_path(path + ".tmp"))
    print("CHECKPOINT: %d checks, %d failed" % [checks, failed])
    quit(1 if failed else 0)
