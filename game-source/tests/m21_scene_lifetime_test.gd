extends SceneTree
var checks := 0
var failed := 0
func _initialize() -> void: run.call_deferred()
func run() -> void:
    var before := Node.get_orphan_node_ids()
    var lobby = load("res://main.tscn").instantiate()
    root.add_child(lobby)
    await process_frame
    lobby.queue_free()
    await process_frame
    await process_frame
    var leaked := Node.get_orphan_node_ids().filter(func(id): return id not in before)
    checks += 1
    if not leaked.is_empty():
        failed += 1
        push_error("FAIL: unopened scenes must release their lazy action sprites; remaining "+str(leaked))
    print("M21_SCENE_LIFETIME: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
