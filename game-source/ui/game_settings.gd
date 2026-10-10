extends RefCounted
## Player preferences only; never mutates a journey or a battle result.
var music_level:=1
var effects:=true
var camera_shake:=true
var rumble:=true
var last_error:=""
var path:="user://player-settings-v1.cfg"
func read()->void:
    var config:=ConfigFile.new()
    if config.load(path)!=OK:return
    var level=config.get_value("audio","music",1)
    if typeof(level)==TYPE_INT and level in [0,1,2]:music_level=level
    for key in ["effects","camera_shake","rumble"]:
        var value=config.get_value("play",key,true)
        if typeof(value)==TYPE_BOOL:set(key,value)
func save()->bool:
    var config:=ConfigFile.new()
    config.set_value("audio","music",music_level)
    for key in ["effects","camera_shake","rumble"]:config.set_value("play",key,get(key))
    var result:=config.save(path+".tmp")
    if result==OK:result=DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))
    last_error="" if result==OK else "设置已应用，本次未能保存。"
    return result==OK
