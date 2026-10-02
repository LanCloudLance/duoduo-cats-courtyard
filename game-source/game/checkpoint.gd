extends RefCounted
var path: String
var last_error := ""
func _init(save_path := "user://courtyard-safe-v1.json") -> void:
    path = save_path
func _canonical(value: Variant) -> Dictionary:
    if not value is Dictionary: return {}
    if value.get("version") != 1 or value.get("safe_point") != "rest" or value.get("rested") != true: return {}
    if typeof(value.get("rested")) != TYPE_BOOL: return {}
    # JSON numbers are floats; Array membership compares numeric types strictly.
    var cat: Variant = value.get("current_cat")
    if typeof(cat) != TYPE_INT and typeof(cat) != TYPE_FLOAT: return {}
    if cat != 1 and cat != 2: return {}
    var completed: Variant = value.get("completed")
    if not completed is Dictionary: return {}
    for key in ["bridge", "combat", "light"]:
        if typeof(completed.get(key)) != TYPE_BOOL: return {}
    var progress := {"bridge":completed.bridge,"combat":completed.combat,"light":completed.light}
    if completed.has("gate"):
        if typeof(completed.gate) != TYPE_BOOL: return {}
        progress.gate = completed.gate
    return {"version":1,"safe_point":"rest","rested":true,"current_cat":int(value.current_cat),"completed":progress}
func read_checkpoint() -> Dictionary:
    last_error = ""
    if not FileAccess.file_exists(path): return {}
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        last_error = "无法读取安全点文件。"
        return {}
    if file.get_length() > 65536:
        last_error = "安全点文件格式不正确。"
        file.close()
        return {}
    var source := file.get_as_text()
    file.close()
    var parser := JSON.new()
    if parser.parse(source) != OK:
        last_error = "安全点文件损坏；可以从头开始试玩。"
        return {}
    var result := _canonical(parser.data)
    if result.is_empty(): last_error = "安全点版本或内容不匹配。"
    return result
func save_checkpoint(value: Dictionary) -> bool:
    last_error = ""
    var data := _canonical(value)
    if data.is_empty():
        last_error = "安全点数据不完整，未覆盖已有记录。"
        return false
    var temporary := path + ".tmp"
    var file := FileAccess.open(temporary, FileAccess.WRITE)
    if file == null:
        last_error = "安全点写入失败；本次仍可继续游玩。"
        return false
    file.store_string(JSON.stringify(data))
    file.flush()
    var result := file.get_error()
    file.close()
    if result != OK:
        last_error = "安全点没有写完整，已有记录保留。"
        return false
    result = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path))
    if result != OK:
        last_error = "安全点更新失败，已有记录保留。"
        return false
    return true

func import_legacy(candidates: Array) -> bool:
    # Never replace a present file, even if it is damaged or a newer format.
    if FileAccess.file_exists(path): return false
    for candidate in candidates:
        var reader = get_script().new(candidate)
        var data: Dictionary = reader.read_checkpoint()
        if not data.is_empty(): return save_checkpoint(data)
    return false
