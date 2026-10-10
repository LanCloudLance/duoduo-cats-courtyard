extends SceneTree
const Three=preload("res://game/chapter_three_state.gd")
func _initialize()->void:
    print("M27_THREE_TRANSFER_QA_USERDIR ",OS.get_user_data_dir())
    var latest:={}
    for name in DirAccess.get_files_at("user://"):
        if not name.begins_with("qa-m27-three-transfer-") or not name.ends_with(".json"):continue
        var data=JSON.parse_string(FileAccess.get_file_as_string("user://"+name))
        if not data is Dictionary or not data.get("completed",false):continue
        var key:=("dual" if name.contains("-dual-") else "solo")+":"+str(int(data.get("version",0)))
        var modified:=FileAccess.get_modified_time("user://"+name)
        if latest.has(key) and latest[key].modified>modified:continue
        latest[key]={"file":name,"modified":modified,"data":data}
    var ok:=OS.get_user_data_dir().ends_with("DuoduoCatsCourtyard-qa-m27-three-transfer")
    for mode in ["solo","dual"]:
        for version in [1,2]:
            var key:String=mode+":"+str(version)
            if not latest.has(key):ok=false;continue
            var s=Three.new();s.single=mode=="solo"
            if version==2:
                if not s.restore_checkpoint(latest[key].data):ok=false
            else:s.restore(latest[key].data)
            if not (s.finished and s.exit_low_latched and s.exit_high_latched and s.exit_revealed and not s.beam_held):ok=false
            print("M27_THREE_TRANSFER_SAVE_RECEIPT ",JSON.stringify({"file":latest[key].file,"mode":mode,"version":version,"low_lock":s.exit_low_latched,"high_lock":s.exit_high_latched,"phase":s.phase,"beam_held":s.beam_held}))
    print("M27_THREE_TRANSFER_SAVED_READBACK ","PASS" if ok else "FAIL");quit(0 if ok else 1)
