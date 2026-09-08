extends SceneTree
const Store = preload("res://game/checkpoint.gd")
var checks := 0
var failed := 0
func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok: failed += 1; print("FAIL: ",label)
func _initialize() -> void:
    var target := "user://test-upgrade-target.json"
    var old := "user://test-upgrade-old.json"
    var bad := "user://test-upgrade-bad.json"
    var store = Store.new(target)
    if not store.has_method("import_legacy"):
        check(false,"version-independent save migration exists")
    else:
        for path in [target,old,bad]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
        var data := {"version":1,"safe_point":"rest","rested":true,"current_cat":2,"completed":{"bridge":true,"combat":true,"light":true}}
        Store.new(old).save_checkpoint(data)
        var file := FileAccess.open(bad,FileAccess.WRITE)
        file.store_string("broken")
        file.close()
        check(store.import_legacy([bad,old]),"skip malformed legacy and import valid record")
        check(store.read_checkpoint().current_cat == 2 and Store.new(old).read_checkpoint().current_cat == 2,"copy preserves old file and current cat")
        data.current_cat = 1
        store.save_checkpoint(data)
        check(not store.import_legacy([old]) and store.read_checkpoint().current_cat == 1,"existing new record never overwritten by old")
        file = FileAccess.open(target,FileAccess.WRITE)
        file.store_string("unknown")
        file.close()
        check(not store.import_legacy([old]) and store.read_checkpoint().is_empty(),"existing unknown record preserved for manual recovery")
        for path in [target,old,bad]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    print("SAVE_UPGRADE: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
