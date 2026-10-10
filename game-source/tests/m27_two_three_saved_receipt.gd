extends SceneTree
func _initialize()->void:
    print("M27_TWO_THREE_QA_USERDIR ",OS.get_user_data_dir())
    var latest:Dictionary={}
    for name in DirAccess.get_files_at("user://"):
        if not name.begins_with("qa-m27-two-three-") or not name.ends_with(".json"):continue
        var value=JSON.parse_string(FileAccess.get_file_as_string("user://"+name))
        if not value is Dictionary or not value.get("completed",false):continue
        var key:String=str(value.get("chapter"))+":"+("dual" if name.contains("-dual-") else "solo")+":"+str(int(value.get("version")))
        var modified:int=FileAccess.get_modified_time("user://"+name)
        if latest.has(key) and latest[key].modified>modified:continue
        latest[key]={"file":name,"modified":modified,"chapter":value.get("chapter"),"completed":value.get("completed"),"phase":value.get("phase","legacy-complete"),"version":value.get("version"),"mode":"dual" if name.contains("-dual-") else "solo"}
    for key in latest:print("M27_TWO_THREE_SAVE_RECEIPT ",JSON.stringify(latest[key]))
    var ok:=OS.get_user_data_dir().ends_with("DuoduoCatsCourtyard-qa-m27-two-three")
    for chapter in ["chapter-two","chapter-three"]:
        for mode in ["solo","dual"]:
            if not latest.has(chapter+":"+mode+":1") or not latest.has(chapter+":"+mode+":2"):ok=false
    print("M27_TWO_THREE_SAVED_READBACK ","PASS" if ok else "FAIL");quit(0 if ok else 1)
