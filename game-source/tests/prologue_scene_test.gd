extends "res://tests/keyboard_scene_test.gd"
var home
var s
func go(slot: int, target: Vector2) -> bool:
    if s.single and s.controlled != slot: tap_key(KEY_TAB)
    var device := 9 if s.single or slot == 0 else 18
    for i in range(900):
        var offset: Vector2 = target-s.positions[slot]
        if offset.length() < 8:
            axes(device,Vector2.ZERO)
            return true
        axes(device,offset)
        await frames(1)
    axes(device,Vector2.ZERO)
    return false
func interact(slot: int) -> void:
    if s.single and s.controlled != slot: tap_key(KEY_TAB)
    tap_key(KEY_E if s.single or slot == 0 else KEY_SPACE)
func door(slot: int) -> void:
    check(await go(slot,Vector2(1115,440)),"walk to hallway")
    check(await go(slot,Vector2(1120,315)),"walk up hallway to door")
func run() -> void:
    Engine.time_scale = 2
    lobby = load("res://main.tscn").instantiate()
    root.add_child(lobby)
    await frames(3)
    lobby.session.set_focus(true)
    home = lobby.prologue
    home.record_prefix = "qa-prologue-"+str(Time.get_ticks_usec())
    for single in [false,true]:
        lobby.session.pause_all()
        lobby.start_story(single)
        s = home.state
        await frames(2)
        check(lobby.stage == "prologue" and home.visible and not lobby.courtyard.visible,"chapter entry isolates story from courtyard")
        check(await go(1,s.ball-Vector2(40,0)),"cat reaches loose ball")
        interact(1)
        await frames(20)
        check(s.extras.has("toy") and s.ball != s.TOY,"paw input visibly moves a real room object")
        check(await go(0,s.DOOR+Vector2(-40,115)),"girl approaches hallway")
        check(await go(0,s.DOOR+Vector2(-40,32)),"girl can watch cat at door")
        for i in range(900):
            if s.phase == "jam": break
            await frames(1)
        check(s.phase == "jam","curiosity and visible departure lead to environmental obstacle")
        tap_key(KEY_ESCAPE)
        var clock: float = s.clock
        await frames(10)
        check(s.clock == clock and not home.visible,"pause freezes props and cat behavior")
        tap_key(KEY_ENTER)
        check(await go(1,Vector2(1120,440)),"cat enters hall")
        check(await go(1,s.rug_position()+Vector2(0,18)),"cat reaches actual carpet edge")
        interact(1)
        await frames(15)
        check(not s.rug_grab,"loaded rug cannot be solved by interaction alone")
        interact(0)
        await frames(20)
        check(s.brace and s.door_open > 0.2,"girl holds door open using normal input")
        interact(1)
        await frames(15)
        check(s.rug_grab,"cat grips freed edge")
        check(await go(1,Vector2(1120,505)),"cat physically walks backward to pull rug")
        check(s.phase == "open","dragging solves the environment, not repeated confirmations")
        await door(0)
        await door(1)
        await frames(90)
        await frames(2)
        check(s.finished and home.recorded,"both reach chapter end and write separate chapter record")
        check(not home.read_record().is_empty(),"chapter record reads back")
        home.reset(single,true)
        check(home.state.finished,"completed chapter can be resumed")
    lobby.session.pause_all()
    lobby.get_node("CombatPreview").pressed.emit()
    await frames(2)
    check(lobby.stage == "combat" and not home.visible and lobby.arena.visible,"sample combat remains accessible")
    print("PROLOGUE_SCENE: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
