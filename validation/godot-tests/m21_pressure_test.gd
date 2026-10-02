extends SceneTree
const Battle = preload("res://game/battle_state.gd")
var checks := 0
var failed := 0
func check(value: bool,label: String) -> void:
    checks += 1
    if not value: failed += 1; push_error("FAIL: "+label)
func _initialize() -> void:
    var b = Battle.new()
    b.positions[0] = Vector2(930,420)
    b.positions[1] = Vector2(1250,700)
    b.positions[2] = Vector2(1200,730)
    b._start_wave(2)
    check(b.enemies.all(func(e): return b.positions.all(func(p): return p.distance_to(e.pos) >= 200)),"automatic wave cannot appear on any party member")
    var rng := RandomNumberGenerator.new()
    rng.seed = 21
    var distinct := true
    for trial in range(250):
        var sample = Battle.new()
        for role in range(3): sample.positions[role] = Vector2(rng.randf_range(-90,1370),rng.randf_range(200,790))
        sample._start_wave(3)
        for i in range(sample.enemies.size()):
            for j in range(i):
                if sample.enemies[i].pos.distance_to(sample.enemies[j].pos) < 52: distinct = false
    check(distinct,"relocated enemies never appear overlapping another enemy")
    for wave in range(1,4):
        b = Battle.new()
        b.positions[0] = Vector2(0,220); b.positions[1] = Vector2(20,235)
        b._start_wave(wave)
        var route := [Vector2(1300,220),Vector2(1300,750),Vector2(0,750),Vector2(0,220)]
        var next := 0
        var hurt := false
        for frame in range(7200):
            var delta: Vector2 = route[next]-b.positions[0]
            if delta.length() < 10: next = (next+1)%route.size()
            var heading: Vector2 = b.positions[0].direction_to(route[next])
            b.step(1.0/60,heading,heading,true)
            if b.hp != [3,3]: hurt = true; break
        check(hurt,"wave %d creates pressure against blind fixed-circle running" % wave)
    b = Battle.new()
    b._start_wave(2)
    b.enemies.clear()
    b._spawn("weaver",Vector2(750,220))
    var caster: Dictionary = b.enemies[0]
    caster.timer = 0
    b.positions[0] = Vector2(200,220); b.positions[1] = Vector2(1300,750)
    b.step(1.0/60,Vector2.RIGHT,Vector2.ZERO,true)
    check(caster.mode == "cast" and caster.target == 0 and caster.aim.x > b.positions[0].x+100,"distant caster locks moving player zero's future landing point")
    if caster.mode == "cast":
        var warning: float = caster.timer
        check(warning >= 0.85,"prediction still provides a readable warning")
        for i in range(66): b.step(1.0/60,Vector2.DOWN,Vector2.ZERO,true)
        check(b.hp == [3,3],"changing route safely evades the currently locked landing")
    print("M21_PRESSURE: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
