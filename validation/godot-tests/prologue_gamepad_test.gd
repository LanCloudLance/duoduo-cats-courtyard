extends "res://tests/bridge_scene_test.gd"
func run() -> void:
    lobby = load("res://main.tscn").instantiate()
    root.add_child(lobby)
    await frames(2)
    lobby.session.set_focus(true)
    # Join by the ordinary controller events, then select the chapter.
    button(9,JOY_BUTTON_START)
    button(18,JOY_BUTTON_START)
    lobby.session.pause_all()
    lobby.start_story(false)
    button(9,JOY_BUTTON_START)
    button(18,JOY_BUTTON_START)
    await frames(2)
    var s = lobby.prologue.state
    check(lobby.session.running() and not lobby.session.keyboard_mode,"two controller slots can enter story")
    var origin: Vector2 = s.positions[1]
    axes(18,Vector2.RIGHT)
    await frames(10)
    axes(18,Vector2.ZERO)
    check(s.positions[1].x > origin.x and s.positions[0] == Vector2(360,475),"second stick moves only Tuantuan")
    s.positions[0] = s.DESK
    button(9,JOY_BUTTON_A)
    check(s.notebook,"first controller interaction reaches notebook")
    s.positions[1] = s.TOY
    button(18,JOY_BUTTON_A)
    check(s.phase == "rest","second controller interaction reaches toy")
    button(9,JOY_BUTTON_START)
    await frames(2)
    check(not lobby.session.running(),"controller menu pauses story")
    lobby.start_story(true)
    button(9,JOY_BUTTON_START)
    await frames(2)
    s = lobby.prologue.state
    check(lobby.session.running(),"one controller can start solo story")
    button(9,JOY_BUTTON_Y)
    check(s.controlled == 1,"solo controller switches to black cat")
    button(9,JOY_BUTTON_Y)
    check(s.controlled == 0,"solo controller switches back without unlocking white cat")
    print("PROLOGUE_GAMEPAD: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
