extends "res://tests/keyboard_scene_test.gd"
const Driver = preload("res://tests/chime_driver.gd")
func pick(actor: int) -> void:
    for i in range(3):
        if lobby.chime_gate.selection.actor == actor: return
        tap_key(KEY_TAB)
func walk(role: int, target: Vector2) -> bool:
    if lobby.session.single_player: pick(role)
    var slot := 0 if lobby.session.single_player or role == 0 else 1
    for i in range(800):
        var actor: int = role if lobby.session.single_player else 0 if slot == 0 else lobby.chime_gate.puzzle.current_cat
        var offset: Vector2 = target-lobby.chime_gate.puzzle.positions[actor]
        if offset.length() < 7:
            axes(9 if slot == 0 else 18,Vector2.ZERO)
            return true
        axes(9 if slot == 0 else 18,Vector2(0 if absf(offset.x)<3 else signf(offset.x),0 if absf(offset.y)<3 else signf(offset.y)))
        await frames(1)
    return false
func run() -> void:
    for single in [false,true]:
        lobby = load("res://main.tscn").instantiate()
        root.add_child(lobby)
        await frames(2)
        lobby.session.set_focus(true)
        lobby.start_trial("gate",single)
        await frames(2)
        check(lobby.stage == "gate" and lobby.chime_gate.active,"direct entry uses live puzzle scene")
        var state = lobby.chime_gate.puzzle
        var before: Array = state.positions.duplicate()
        tap_key(KEY_ESCAPE)
        axes(9,Vector2.RIGHT)
        await frames(10)
        check(state.positions == before,"pause prevents puzzle movement")
        tap_key(KEY_ENTER)
        check(await Driver.solve(self,single),"normal routed %s input completes both bell rules and exits" % ("solo" if single else "dual"))
        check(not lobby.rest_area.can_save,"direct preview never overwrites journey checkpoint")
        lobby.queue_free()
        await frames(2)
        lobby=null
    var mixer_deadline:int=Time.get_ticks_msec()+100
    while Time.get_ticks_msec()<mixer_deadline:await process_frame
    print("M21_CHIME_SCENE: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
