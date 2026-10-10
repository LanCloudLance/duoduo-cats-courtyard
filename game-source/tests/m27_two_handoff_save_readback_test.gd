extends SceneTree
const Two=preload("res://game/chapter_two_state.gd")
func _initialize()->void:
    print("M27_TWO_HANDOFF_QA_USERDIR ",OS.get_user_data_dir())
    var latest:={}
    for name in DirAccess.get_files_at("user://"):
        if not name.begins_with("qa-m27-two-handoff-") or not name.ends_with(".json"):continue
        var data=JSON.parse_string(FileAccess.get_file_as_string("user://"+name))
        if not data is Dictionary or not data.get("completed",false):continue
        var key:=("dual" if name.contains("-dual-") else "solo")+":"+str(int(data.get("version",0)))
        var modified:=FileAccess.get_modified_time("user://"+name)
        if latest.has(key) and latest[key].modified>modified:continue
        latest[key]={"file":name,"modified":modified,"data":data}
    var ok:=OS.get_user_data_dir().ends_with("DuoduoCatsCourtyard-qa-m27-two-handoff")
    for mode in ["solo","dual"]:
        for version in [1,2]:
            var key:String=mode+":"+str(version)
            if not latest.has(key):ok=false;continue
            var s=Two.new();s.single=mode=="solo"
            if version==2:
                if not s.restore_checkpoint(latest[key].data):ok=false
            else:s.restore(latest[key].data)
            if not (s.finished and s.locked_b and s.support_site=="far" and s.rear_loaded_seen and not s.rear_braced()):ok=false
            print("M27_TWO_HANDOFF_SAVE_RECEIPT ",JSON.stringify({"file":latest[key].file,"mode":mode,"version":version,"support_site":s.support_site,"rear_loaded_seen":s.rear_loaded_seen,"phase":s.phase,"braced":s.rear_braced()}))
    print("M27_TWO_HANDOFF_SAVED_READBACK ","PASS" if ok else "FAIL");quit(0 if ok else 1)
