extends "res://tests/keyboard_scene_test.gd"
const Store = preload("res://game/checkpoint.gd")
func run() -> void:
    lobby = load("res://main.tscn").instantiate()
    lobby.checkpoint = Store.new("user://test-m19-entry-dual.json")
    lobby.solo_checkpoint = Store.new("user://test-m19-entry-solo.json")
    root.add_child(lobby)
    await frames(2)
    lobby.session.set_focus(true)
    check(lobby.has_method("start_trial"),"updated rooms can be entered directly in either player mode")
    if failed:
        print("M19_ENTRY: %d checks, %d failed" % [checks,failed])
        quit(1)
        return
    for single in [true,false]:
        for target in ["combat","light"]:
            lobby.session.pause_all()
            lobby.start_trial(target,single)
            await frames(2)
            check(lobby.stage == target and lobby.preview_run,"direct trial enters selected room without journey save authority")
            check(lobby.session.single_player == single,"direct trial respects selected player count")
            if target == "light": check(lobby.light_corridor.puzzle.solo_mode == single,"light direct entry uses correct manual switching rules")
            else: check(lobby.arena.battle.solo_mode == single,"combat direct entry uses correct AI support rules")
    check(lobby.checkpoint.read_checkpoint().is_empty() and lobby.solo_checkpoint.read_checkpoint().is_empty(),"room trials never create or replace journey records")
    lobby.free()
    print("M19_ENTRY: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
