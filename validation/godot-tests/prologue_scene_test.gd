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
        check(await go(0,s.DESK),"girl reaches notebook")
        interact(0)
        check(s.notebook,"normal girl input completes notebook")
        check(await go(1,s.TOY),"cat reaches toy")
        interact(1)
        check(s.phase == "rest","normal cat input completes shared opening")
        check(await go(0,s.CUSHION),"girl can inspect white cat")
        interact(0)
        check(s.extras.has("yuanyuan"),"optional white cat interaction works")
        check(await go(0,s.SOFA),"girl returns to sofa")
        interact(0)
        tap_key(KEY_ESCAPE)
        var timer: float = s.timer
        await frames(12)
        check(s.timer == timer and not home.visible,"pause freezes chapter event clock")
        tap_key(KEY_ENTER)
        for i in range(180):
            if s.phase == "strange": break
            await frames(1)
        check(s.phase == "strange","rest leads to door event")
        await door(1)
        interact(1)
        check(s.phase == "noticed","cat detects tail by normal input")
        check(await go(1,Vector2(1115,440)),"cat leaves hall safely")
        check(await go(1,s.positions[0]+Vector2(40,0)),"cat returns to girl")
        interact(1)
        check(s.phase == "called","cat call advances story")
        await door(0)
        interact(0)
        check(s.phase == "crossing","girl elects to follow")
        interact(0)
        check(not s.finished,"waiting at door alone cannot finish")
        await door(1)
        interact(0)
        interact(1)
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
