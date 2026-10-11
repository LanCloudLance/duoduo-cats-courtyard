extends SceneTree
func _init()->void:
    if OS.get_user_data_dir().get_file()!="DuoduoCatsCourtyard-qa-m30-puzzle":quit(2);return
    var records=JSON.parse_string(FileAccess.get_file_as_string("user://m30-c4-records.json"))
    if not records is Dictionary:quit(3);return
    var count:=0
    for label in records:
        var item:Dictionary=records[label];var s=load("res://game/chapter_four_state.gd").new();s.single=item.solo
        if not s.restore_checkpoint(item.record):push_error("restore "+label);quit(4);return
        if JSON.parse_string(JSON.stringify(s.checkpoint().facts))!=item.record.facts:push_error("durable facts "+label);quit(5);return
        if s.room_name()!=(item.record.facts.visit_room if not item.record.facts.visit_room.is_empty() else "market" if item.record.phase=="market" else "interior"):push_error("physical room "+label);quit(6);return
        count+=1
    print("M30_C4_READBACK: ",count," records, durable facts and physical room preserved");quit(0)
