extends RefCounted
## A journey owns its chapter saves. Starting over never resumes an older run.
var prefix:="story-journey-v1"
var last_error:=""
func path(single:bool)->String:return "user://"+prefix+("-solo.json" if single else "-dual.json")
func valid(value,single:bool)->bool:
    if not value is Dictionary or value.get("version")!=1 or value.get("mode")!=("solo" if single else "dual"):return false
    var chapter=value.get("chapter");var id=value.get("run_id")
    if not preload("res://game/story_checkpoint.gd").integer(chapter,0,5) or not id is String or not id.begins_with("story-run-") or id.length()>80:return false
    var suffix:String=id.trim_prefix("story-run-")
    if suffix.is_empty():return false
    for character in suffix.to_utf8_buffer():
        if character!=45 and (character<48 or character>57):return false
    return true
func read(single:bool)->Dictionary:
    var file:=FileAccess.open(path(single),FileAccess.READ)
    if not file:return {}
    if file.get_length()>4096:file.close();return {}
    var value=JSON.parse_string(file.get_as_text());file.close()
    return value if valid(value,single) else {}
func save(single:bool,run_id:String,chapter:int)->bool:
    last_error="";var value:={"version":1,"mode":"solo" if single else "dual","run_id":run_id,"chapter":chapter}
    if not valid(value,single):last_error="旅程进度不完整，未覆盖已有记录。";return false
    var name:=path(single);var file:=FileAccess.open(name+".tmp",FileAccess.WRITE)
    if not file:last_error="旅程位置未写入；本次仍可继续。";return false
    file.store_string(JSON.stringify(value));file.flush();var error:=file.get_error();file.close()
    if error!=OK or DirAccess.rename_absolute(ProjectSettings.globalize_path(name+".tmp"),ProjectSettings.globalize_path(name))!=OK:
        last_error="旅程位置未写入；本次仍可继续。";return false
    return true
