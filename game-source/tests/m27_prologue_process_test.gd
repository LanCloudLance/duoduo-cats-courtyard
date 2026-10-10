extends "res://tests/prologue_scene_test.gd"
# Run writer then reader as two separate Godot processes. Gameplay is InputEvent only.
func run() -> void:
    Engine.time_scale = 3
    check(OS.get_user_data_dir().ends_with("DuoduoCatsCourtyard-qa-m27-prologue"),"isolated actual process namespace")
    print("QA_USERDIR: "+OS.get_user_data_dir())
    var reading := OS.get_cmdline_user_args().has("read")
    lobby = load("res://main.tscn").instantiate()
    root.add_child(lobby)
    await frames(3)
    lobby.session.set_focus(true)
    home = lobby.prologue
    home.record_prefix = "qa-prologue-cross-process"
    if not reading:
        home.reset(true,false)
        for path in [home.checkpoint_path(),home.record_path()]:
            if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
    lobby.start_story(true)
    s = home.state
    await frames(2)
    if not reading:
        check(await go(0,s.DESK),"writer approaches doorstop")
        tap_key(KEY_R)
        await frames(20)
        check(s.carrier == 0,"writer lifts doorstop via tool input")
        await door(0)
        var seen := {}
        for i in range(900):
            if not seen.has(s.phase):
                seen[s.phase] = true
                var probe = load("res://game/prologue_state.gd").new()
                probe.single = true
                check(probe.restore_checkpoint(s.checkpoint()),"live departure capture restores "+s.phase)
            if s.phase == "jam": break
            await frames(1)
        check(s.phase == "jam","writer witnesses departure")
        tap_key(KEY_R)
        await frames(20)
        check(s.wedged,"writer fixes door with carried wedge")
        check(await go(1,Vector2(1120,440)),"writer cat enters hall")
        check(await go(1,s.rug_position()+Vector2(0,18)),"writer cat reaches edge")
        tap_key(KEY_R)
        await frames(12)
        check(s.rug_grab,"writer cat grabs via tool")
        check(await go(1,s.positions[1]+Vector2(0,50)),"writer makes partial physical drag")
        check(s.rug_pull > 20 and s.rug_pull < 100,"writer stores partial progress")
        tap_key(KEY_ESCAPE)
        await frames(2)
        var data: Dictionary = home.read_record()
        check(data.get("version") == 2 and data.get("facts",{}).get("rug_pull",0) > 20,"pause writes valid v2")
        print("WRITER_RUG: "+str(s.rug_pull))
    else:
        check(s.phase == "jam" and s.wedged and s.rug_pull > 20 and s.rug_pull < 100,"new process restores permanent intermediate work")
        check(not s.brace and not s.rug_grab and s.carrier == -1,"new process releases all temporary holds")
        check(s.history.size() > 0,"new process retains journal")
        check(await go(1,s.rug_position()+Vector2(0,18)),"reader re-approaches saved edge")
        tap_key(KEY_R)
        await frames(10)
        check(s.rug_grab,"reader reacquires edge")
        check(await go(1,Vector2(1120,530)),"reader pulls remaining rug")
        check(s.phase == "open","reader completes resumed obstacle normally")
        await door(0)
        await door(1)
        await frames(100)
        check(s.finished and home.recorded,"reader finishes and persists completion")
        check(home.read_record().get("completed") == true,"completion readback after intermediate save")
    print("M27_PROLOGUE_PROCESS_%s: %d checks, %d failed" % ["READER" if reading else "WRITER",checks,failed])
    quit(1 if failed else 0)
