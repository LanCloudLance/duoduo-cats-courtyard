extends "res://tests/m21_chime_scene_test.gd"
var prefix := ""
func drive(slot: int,vector: Vector2) -> void:
    axes(9 if slot == 0 else 18,vector)
func capture(suffix: String) -> void:
    await frames(3)
    await RenderingServer.frame_post_draw
    check(root.get_texture().get_image().save_png(prefix+suffix+".png") == OK,"capture "+suffix)
func walk(role: int,target: Vector2) -> bool:
    if lobby.stage != "combat": return await super.walk(role,target)
    for i in range(1000):
        var actor: int = 0 if role == 0 else lobby.arena.battle.current_cat
        var offset: Vector2 = target-lobby.arena.battle.positions[actor]
        if offset.length() < 7:
            axes(9 if role == 0 else 18,Vector2.ZERO)
            return true
        axes(9 if role == 0 else 18,Vector2(0 if absf(offset.x)<3 else signf(offset.x),0 if absf(offset.y)<3 else signf(offset.y)))
        await frames(1)
    return false
func run() -> void:
    if OS.get_cmdline_user_args().is_empty() or DisplayServer.get_name() == "headless": quit(1); return
    prefix = OS.get_cmdline_user_args()[0]
    lobby = load("res://main.tscn").instantiate()
    root.add_child(lobby)
    await frames(2)
    lobby.session.set_focus(true)
    lobby.start_trial("combat",false)
    check(await walk(0,Vector2(-90,195)),"girl reaches expanded top left")
    check(await walk(1,Vector2(1000,740)) and await walk(1,Vector2(1350,790)),"cats reach expanded bottom right")
    await capture("-space")
    check(await walk(0,Vector2(570,460)),"girl approaches actual seed")
    axes(9,Vector2.RIGHT); await frames(1); axes(9,Vector2.ZERO)
    tap_key(KEY_F)
    await frames(30)
    tap_key(KEY_F)
    await frames(12)
    check(lobby.arena.battle.seeds[0].mode == "rolling","practice seed really moves before fight")
    await capture("-seed")
    tap_key(KEY_E); tap_key(KEY_SPACE)
    var driver = load("res://tests/battle_driver.gd").new(self,lobby.arena.battle)
    for i in range(180):
        driver.step_slot(0); driver.step_slot(1)
        await frames(1)
    axes(9,Vector2.ZERO); axes(18,Vector2.ZERO)
    await capture("-battle")
    tap_key(KEY_ESCAPE)
    lobby.start_trial("gate",false)
    await frames(3)
    await capture("-gate-start")
    check(await walk(0,lobby.chime_gate.Chime.MIRRORS[0]+Vector2(0,45)),"girl reaches first mirror")
    tap_key(KEY_E); await frames(105)
    check(await walk(0,lobby.chime_gate.puzzle.mirror_points()[0]+Vector2(0,45)),"girl tests shared mirror")
    tap_key(KEY_E)
    check(await walk(0,lobby.chime_gate.puzzle.mirror_points()[2]+Vector2(0,45)),"girl tests branch mirror")
    tap_key(KEY_E)
    check(await walk(0,lobby.chime_gate.puzzle.source_point()+Vector2(0,45)),"girl tests emitter height")
    tap_key(KEY_E)
    tap_key(KEY_TAB)
    check(await walk(1,lobby.chime_gate.puzzle.socket_points()[1]+Vector2(0,40)),"white tests lower crystal")
    tap_key(KEY_R); await frames(10)
    check(lobby.chime_gate.puzzle.receivers == [false,true],"lower route gives one real bell")
    await capture("-gate-wrong")
    tap_key(KEY_R)
    check(await walk(0,lobby.chime_gate.puzzle.source_point()+Vector2(0,45)),"girl compares upper height")
    tap_key(KEY_E)
    check(await walk(1,lobby.chime_gate.puzzle.socket_points()[0]+Vector2(0,40)),"white compares upper crystal")
    tap_key(KEY_R); await frames(60)
    check(lobby.chime_gate.puzzle.finished,"rendered normal actions open coupled bell gate")
    await capture("-gate-open")
    root.size = Vector2i(1280,720)
    await capture("-gate-16x9")
    lobby.queue_free()
    await frames(2)
    await create_timer(0.12).timeout
    print("M21_RENDER_AUDIT: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
