extends SceneTree
const Session = preload("res://input/session_state.gd")
const Arena = preload("res://game/arena.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
    # Equal sampling cadence across snapshots; occluded windows can ignore VSync.
    Engine.max_fps = 60
    DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
    var host := Control.new()
    host.theme = Theme.new()
    host.theme.default_font = load("res://assets/fonts/CourtyardSans.ttf")
    root.add_child(host)
    var s = Session.new()
    s.keyboard_mode = true
    s.ready_flags[0] = true
    s.ready_flags[1] = true
    var arena = Arena.new(s)
    host.add_child(arena)
    arena.set_active(true)
    if ResourceLoader.exists("res://game/music_director.gd"):
        var music = load("res://game/music_director.gd").new()
        host.add_child(music)
        music.set_context("boss")
    arena.battle._start_wave(3)
    # Stress fixture: keep four enemies and both players present for all samples.
    for enemy in arena.battle.enemies:
        enemy.hp = 999
        enemy.max_hp = 999
    arena.battle.positions[0] = Vector2(850,430)
    arena.battle.positions[1] = Vector2(930,580)
    var samples: Array[float] = []
    var updates: Array[float] = []
    var physics: Array[float] = []
    var before := Time.get_ticks_usec()
    var started := before
    var i := 0
    while Time.get_ticks_usec()-started < 8000000:
        i += 1
        await process_frame
        var now := Time.get_ticks_usec()
        arena.battle.invulnerable[0] = 10
        arena.battle.invulnerable[1] = 10
        if now-started >= 2000000:
            samples.append((now-before)/1000.0)
            updates.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
            physics.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000)
        before = now
        if i%35 == 0: arena.battle.attack(0)
        if i%55 == 0: arena.battle.attack(1)
        if i%80 == 0: arena.battle.release_attack(1)
        if i%120 == 0: arena.battle.switch_cat()
    samples.sort()
    print("COMBAT_FRAME_MS samples=",samples.size()," median=",samples[int(samples.size()*0.5)]," p95=",samples[int(samples.size()*0.95)]," p99=",samples[int(samples.size()*0.99)]," max=",samples[-1])
    updates.sort()
    physics.sort()
    print("COMBAT_CPU_MS process_p95=",updates[int(updates.size()*0.95)]," physics_p95=",physics[int(physics.size()*0.95)]," enemies=",arena.battle.enemies.size())
    host.queue_free()
    await process_frame
    await process_frame
    await create_timer(0.3).timeout
    quit()
