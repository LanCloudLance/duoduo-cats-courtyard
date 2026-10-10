extends "res://tests/render_battle_preview.gd"
# Explicit frozen fixtures for HUD and pause-page visual inspection only.
func run() -> void:
    var args := OS.get_cmdline_user_args()
    if args.is_empty() or DisplayServer.get_name() == "headless": quit(1); return
    var lobby = load("res://main.tscn").instantiate()
    root.add_child(lobby)
    await process_frame
    lobby.session.set_focus(true)
    lobby.start_solo_combat()
    lobby._process(0)
    lobby.set_process(false)
    var a = lobby.arena
    a.set_physics_process(false)
    var b = a.battle
    b._start_wave(2)
    b.positions[0] = Vector2(450,440)
    b.positions[1] = Vector2(755,465)
    b.positions[2] = Vector2(870,565)
    b.enemies[0].pos = Vector2(610,440)
    b.enemies[0].mode = "windup"
    b.enemies[0].timer = 0.7
    b.enemies[0].direction = Vector2.LEFT
    b.guarding = true
    a.solo.companion.status = "绕后等待机会"
    a._physics_process(0)
    await capture(args[0],"-girl")
    a.solo.human_slot = 1
    a.solo.companion.status = "正面举盾"
    b.enemies[0].mode = "exposed"
    b.enemies[0].pos = Vector2(530,440)
    b.positions[0] = Vector2(465,440)
    b.positions[1] = Vector2(605,470)
    b.facing[1] = Vector2.LEFT
    b.message = "朵朵挡住了，轮到你绕后抓住机会。"
    a._physics_process(0)
    await capture(args[0],"-cat")
    root.size = Vector2i(1280,720)
    await capture(args[0],"-16x9")
    root.size = Vector2i(1280,800)
    b.enemies.clear()
    b.phase = "complete"
    b.wave = 3
    b.message = "单人战斗试玩完成！可以在暂停菜单重玩，或选择双人关卡。"
    a.solo.companion.status = "一起休息"
    b.positions[0] = b.EXIT-Vector2(55,0)
    b.positions[1] = b.EXIT+Vector2(20,20)
    b.guarding = false
    a._physics_process(0)
    await capture(args[0],"-complete")
    lobby.session.pause_all("单人战斗暂停")
    lobby._process(0)
    await capture(args[0],"-pause")
    print("SOLO_RENDER: 5 captures, %d failures" % failures)
    quit(1 if failures else 0)
