extends SceneTree
func _initialize()->void:
    print("M27_FOUR_QA_USERDIR ",OS.get_user_data_dir())
    var latest:Dictionary={}
    for name in DirAccess.get_files_at("user://"):
        if not name.begins_with("qa-m27-four-") or not name.ends_with(".json"):continue
        var value=JSON.parse_string(FileAccess.get_file_as_string("user://"+name))
        if not value is Dictionary or not value.get("completed",false):continue
        var key:String=str(value.get("chapter"))+":"+("dual" if name.contains("-dual-") else "solo")+":"+str(int(value.get("version")))
        var modified:int=FileAccess.get_modified_time("user://"+name)
        if latest.has(key) and latest[key].modified>modified:continue
        latest[key]={"file":name,"modified":modified,"chapter":value.get("chapter"),"completed":value.get("completed"),"phase":value.get("phase","legacy-complete"),"version":value.get("version"),"mode":"dual" if name.contains("-dual-") else "solo","connected_split_seen":value.get("facts",{}).get("connected_split_seen",false)}
    for key in latest:print("M27_FOUR_SAVE_RECEIPT ",JSON.stringify(latest[key]))
    var ok:=OS.get_user_data_dir().ends_with("DuoduoCatsCourtyard-qa-m27-four")
    for chapter in ["chapter-four"]:
        for mode in ["solo","dual"]:
            if not latest.has(chapter+":"+mode+":1") or not latest.has(chapter+":"+mode+":2"):ok=false
    for key in latest:
        if key.ends_with(":2") and not latest[key].connected_split_seen:ok=false
    print("M27_FOUR_SAVED_READBACK ","PASS" if ok else "FAIL");quit(0 if ok else 1)
