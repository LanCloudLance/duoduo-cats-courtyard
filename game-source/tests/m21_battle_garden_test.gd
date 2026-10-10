extends SceneTree
const Battle = preload("res://game/battle_state.gd")
var checks := 0
var failed := 0
func check(value: bool,label: String) -> void:
    checks += 1
    if not value: failed += 1; push_error("FAIL: "+label)
func _initialize() -> void:
    var b = Battle.new()
    check(b.FIELD.size.x >= 1500 and b.FIELD.size.y >= 640,"combat gains real movement space in both axes")
    check(ResourceLoader.exists("res://game/battle_garden.gd"),"combat scenery has actionable objects")
    if failed: finish(); return
    var practice = Battle.new()
    practice.positions[0] = practice.seeds[0].pos-Vector2(80,0)
    practice.facing[0] = Vector2.RIGHT
    practice.attack(0)
    for i in range(30): practice.step(1.0/60,Vector2.ZERO,Vector2.ZERO,true)
    check(practice.seeds[0].mode == "loose","briefing allows a real practice strike to loosen seed")
    practice.attack(0)
    for i in range(12): practice.step(1.0/60,Vector2.ZERO,Vector2.ZERO,true)
    check(practice.seeds[0].pos.x > 670 and practice.seeds[0].mode == "rolling","briefing practice propels the seed instead of freezing it")
    for i in range(150): practice.step(1.0/60,Vector2.ZERO,Vector2.ZERO,true)
    check(practice.seeds[0].mode == "spent" and practice.hp == [3,3],"briefing seed bursts safely and ends without combat")
    b._start_wave(1)
    b.enemies.clear()
    b._spawn("sprout",Vector2(900,700))
    b.enemies[0].mode = "rest"; b.enemies[0].timer = 999
    for i in range(90): b.step(1.0/60,Vector2.LEFT,Vector2.ZERO,true)
    check(b.positions[0].x < 120,"ordinary movement reaches the expanded area")
    var seed: Dictionary = b.seeds[0]
    check(seed.mode == "rooted" and b.seeds.size() == 2,"encounter offers a finite pair of seeds")
    var origin: Vector2 = seed.pos-Vector2(80,0)
    b.garden.strike(b,origin,Vector2.LEFT,112,PI/3,true)
    check(seed.mode == "rooted","attacking away cannot move scenery")
    b.garden.strike(b,origin,Vector2.RIGHT,112,PI/3,false)
    check(seed.mode == "loose","ordinary strike visibly loosens the seed")
    b.garden.strike(b,origin,Vector2.RIGHT,112,PI/3,true)
    check(seed.mode == "rolling" and seed.velocity.x > 0,"heavy strike propels seed along aim")
    b.enemies[0].pos = seed.pos+Vector2(95,0)
    var health: float = b.enemies[0].hp
    var party: Array = b.hp.duplicate()
    for i in range(30): b.garden.step(b,1.0/60)
    check(b.enemies[0].hp < health and seed.mode == "spent","seed collision bursts and changes combat")
    check(b.hp == party,"plant burst cannot damage party")
    var other: Dictionary = b.seeds[1]
    b.garden.strike(b,other.pos-Vector2(0,80),Vector2.DOWN,112,PI/3,true)
    for i in range(150): b.garden.step(b,1.0/60)
    check(other.mode == "spent","missed rolling seed expires instead of accumulating objects")
    b.garden.cast(b,b.positions[0])
    b.invulnerable[0] = 0
    b.garden.step(b,0.5)
    check(b.hp == party,"ground hazard shows a grace warning")
    b.garden.step(b,0.2)
    check(b.hp[0] < party[0],"lingering thorns punish ignoring the warning")
    b._retry_wave()
    check(b.hazards.is_empty() and b.seeds.all(func(s): return s.mode == "rooted"),"retry restores scenery and clears lingering danger")
    b.enemies.clear(); b._spawn("weaver",b.positions[1]+Vector2(55,0))
    var caster: Dictionary = b.enemies[0]
    caster.mode = "cast"; caster.timer = 0.5; caster.aim = b.positions[0]
    b.attack_direction[1] = Vector2.RIGHT
    b.attacks.strike(b,1,80,PI/3,1,false,true)
    for i in range(60): b.step(1.0/60,Vector2.ZERO,Vector2.ZERO,true)
    check(b.hazards.is_empty(),"Tuantuan interrupt prevents lingering cast")
    finish()
func finish() -> void:
    print("M21_BATTLE_GARDEN: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
