extends SceneTree
func _init()->void:
    var dir:=OS.get_user_data_dir()
    if not dir.ends_with("DuoduoCatsCourtyard-qa-m30-puzzle"):push_error("wrong userdir");quit(2);return
    print("READBACK_USERDIR ",dir)
    var file=FileAccess.open("user://m30-puzzle-shared-records.json",FileAccess.READ)
    if file==null:push_error("writer evidence absent");quit(2);return
    var data=JSON.parse_string(file.get_as_text());file.close()
    if not data is Dictionary:quit(3);return
    var count:=0
    for path in data.initial:
        var s=load(path).new()
        if not s.restore_checkpoint(data.initial[path]):push_error("initial "+path);quit(4);return
        count+=1
    for label in data.cases:
        var item:Dictionary=data.cases[label];var s=load(item.path).new();s.single=item.solo
        if item.path.ends_with("chapter_five_state.gd"):
            s.load_held=true;s.load_return_time=.4;s.load_return_from=-.45;s.actions[0]="hold"
        if not s.restore_checkpoint(item.record):push_error("case "+label);quit(5);return
        if JSON.parse_string(JSON.stringify(s.checkpoint().facts))!=item.record.facts:print(s.checkpoint().facts);print(item.record.facts);push_error("facts changed "+label);quit(6);return
        if s.has_method("social_transition_active") and s.social_transition_active():push_error("transient social resumed unexpectedly");quit(7);return
        if item.path.ends_with("chapter_five_state.gd") and (s.load_held or s.load_return_time!=0 or s.load_return_from!=0):push_error("load transfer transient survived restore "+label);quit(10);return
        if label.begins_with("cart"):
            if s.phase!=item.record.phase or s.finished!=item.record.completed or not s.cart_open or s.shortcut_open or s.hook_practiced:push_error("cart route progress changed "+label);quit(8);return
            for role in [0,1]:
                if s.positions[role]!=Vector2(item.record.positions[role][0],item.record.positions[role][1]) or not s.walkable(s.positions[role],role):push_error("cart route feet relocated "+label);quit(9);return
        count+=1
    print("M30_PUZZLE_SHARED_READBACK ",count," records; exact durable facts preserved")
    quit(0)
