extends SceneTree
const Five=preload("res://game/chapter_five_state.gd")
func _init()->void:
    if OS.get_user_data_dir().get_file()!="DuoduoCatsCourtyard-qa-m31-puzzle":quit(2);return
    var data=JSON.parse_string(FileAccess.get_file_as_string("user://m31-c5-records.json"))
    if not data is Dictionary or data.is_empty():push_error("writer evidence missing");quit(3);return
    var checks:=0
    for label in data:
        var value:Dictionary=data[label];var s=Five.new();s.single=value.solo
        if not s.restore_checkpoint(value.record):push_error("readback rejected "+label);quit(4);return
        if JSON.parse_string(JSON.stringify(s.checkpoint().facts))!=value.record.facts:push_error("durable facts changed "+label);quit(5);return
        if s.load_held or s.fixed_light or s.beam_held or s.cat_in_service():push_error("unsafe transient replay "+label);quit(6);return
        checks+=3
    var mainline=JSON.parse_string(FileAccess.get_file_as_string("user://qa-m31-mainline-receipt.json"))
    if not mainline is Dictionary or mainline.records.size()!=12:push_error("ordinary mainline writer missing");quit(7);return
    for record in mainline.records:
        if record.route.back()!="five":continue
        var s=Five.new();s.single=record.single
        var actual=JSON.parse_string(FileAccess.get_file_as_string(record.path))
        if not s.restore_checkpoint(actual) or not s.finished:push_error("ordinary full journey does not restore at completed home");quit(8);return
        if s.extraction_method!=("held" if record.single else "support"):push_error("ordinary saved method changed");quit(9);return
        checks+=2
    print("M31_C5_READBACK: %d checks, 0 failures"%checks);quit(0)
