extends SceneTree
const Session = preload("res://input/session_state.gd")
const Arena = preload("res://game/arena.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
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
    arena.battle._start_wave(3)
    var samples: Array[float] = []
    var before := Time.get_ticks_usec()
    for i in range(420):
        await process_frame
        var now := Time.get_ticks_usec()
        if i >= 60: samples.append((now-before)/1000.0)
        before = now
        if i%35 == 0: arena.battle.attack(0)
        if i%55 == 0: arena.battle.attack(1)
        if i%80 == 0: arena.battle.release_attack(1)
        if i%120 == 0: arena.battle.switch_cat()
    samples.sort()
    print("COMBAT_FRAME_MS samples=",samples.size()," median=",samples[180]," p95=",samples[342]," p99=",samples[356]," max=",samples[-1])
    quit()
