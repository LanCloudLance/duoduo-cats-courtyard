extends "res://tests/render_battle_preview.gd"
# Frozen fixtures show real production poses and hit feedback, not human play.
func run() -> void:
    var args := OS.get_cmdline_user_args()
    if args.is_empty() or DisplayServer.get_name() == "headless":
        quit(1)
        return
    var host := Control.new()
    var font := SystemFont.new()
    font.font_names = PackedStringArray(["Microsoft YaHei","PingFang SC","Noto Sans CJK SC"])
    host.theme = Theme.new()
    host.theme.default_font = font
    root.add_child(host)
    var session = Session.new()
    session.keyboard_mode = true
    session.ready_flags[0] = true
    session.ready_flags[1] = true
    var arena = Arena.new(session)
    host.add_child(arena)
    arena.set_active(true)
    arena.set_physics_process(false)
    var b = arena.battle
    b.positions[0] = Vector2(410,450)
    b.positions[1] = Vector2(910,470)
    b.positions[2] = Vector2(850,585)
    b._spawn("thorn",Vector2(490,425))
    b._spawn("thorn",Vector2(490,485))
    b.attack(0)
    b.step(0.08,Vector2.ZERO,Vector2.ZERO,true)
    b.message = "朵朵 · 面向目标挥剑，横扫前方多个枝团。"
    arena._physics_process(0)
    await capture(args[0],"-sword")
    for i in range(3): b.step(0.1,Vector2.ZERO,Vector2.ZERO,true)
    b.enemies.clear()
    b.positions[1] = Vector2(625,445)
    b._spawn("thorn",Vector2(712,445))
    b.attack(1)
    b.step(0.08,Vector2.ZERO,Vector2.ZERO,true)
    b.message = "团团 · 贴地短扑，伸爪快抓；扑击也会被树桩和硬壳挡住。"
    arena._physics_process(0)
    await capture(args[0],"-pounce")
    b.switch_cat()
    b.positions[2] = Vector2(625,445)
    b.enemies[0].pos = Vector2(695,445)
    b.enemies[0].hp = 5
    b.enemies[0].max_hp = 5
    for i in range(10): b.step(0.1,Vector2.ZERO,Vector2.ZERO,true)
    b.attack(1)
    for i in range(7): b.step(0.1,Vector2.ZERO,Vector2.ZERO,true)
    b.message = "圆圆 · 轻按松开是轻拍，蓄满后松开是双爪重拍。"
    arena._physics_process(0)
    await capture(args[0],"-charge")
    b.release_attack(1)
    b.step(0.06,Vector2.ZERO,Vector2.ZERO,true)
    b.message = "圆圆 · 重拍推开普通敌人，为伙伴争取一点空间。"
    arena._physics_process(0)
    await capture(args[0],"-heavy")
    root.size = Vector2i(1280,720)
    await capture(args[0],"-16x9")
    print("ATTACK_RENDER: 5 captures, %d failures" % failures)
    quit(1 if failures else 0)
