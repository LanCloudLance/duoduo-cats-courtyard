extends SceneTree
const B = preload("res://game/battle_state.gd")
const Driver = preload("res://tests/battle_driver.gd")
class DriverHost extends RefCounted:
    var battle
    func drive(_slot: int, _direction: Vector2) -> void: pass
    func key_event(_code: int, _pressed: bool) -> void: pass
    func tap_key(code: int) -> void:
        if code == KEY_E: battle.interact(0)
        if code == KEY_SPACE: battle.interact(1)
const Solo = preload("res://game/solo_battle.gd")
var checks := 0
var failed := 0
func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok: failed += 1; push_error("FAIL: "+label)
func tick(b, seconds: float, enabled := true) -> void:
    for i in range(ceili(seconds*120)): b.step(1.0/120,Vector2.ZERO,Vector2.ZERO,enabled)
func cleared(solo := false):
    var b = B.new()
    b.solo_mode = solo
    b._start_wave(1)
    b.hp[0] = 1
    b.hp[1] = 2
    for e in b.enemies: e.hp = 0
    tick(b,0.01)
    return b
func _initialize() -> void:
    for single in [false,true]:
        var b = cleared(single)
        b.interact(0)
        check(b.wave == 1 and b.confirmed == [false,false],"minimum breath rejects early readiness %s" % single)
        tick(b,4)
        check(b.phase == "intermission" and b.wave == 1 and b.hp == [1,2],"low-health wave waits indefinitely without healing %s" % single)
        tick(b,10,false)
        check(b.wave == 1,"disabled simulation never advances waiting wave")
        b.interact(0)
        if single:
            check(b.wave == 2,"one human explicitly starts solo next wave")
        else:
            check(b.wave == 1 and b.confirmed[0] and not b.confirmed[1],"one dual ready cannot start next wave")
            b.interact(1)
            check(b.wave == 2,"both dual humans explicitly start next wave")
        check(b.hp == [1,2],"ready never refills low health")
        b.hp[0] = 0
        b.hp[1] = 0
        tick(b,2.1)
        check(b.wave == 2 and b.phase == "combat" and b.retries == 1,"wipe retries current wave without skipping %s" % single)
    var b = cleared()
    tick(b,2)
    var driver_host = DriverHost.new()
    driver_host.battle = b
    var driver = Driver.new(driver_host,b)
    driver.step_slot(0)
    check(b.wave == 2,"shared dual input driver sends both readiness events")
    b = cleared()
    driver_host.battle = b
    driver = Driver.new(driver_host,b)
    b.hp[1] = 0
    b.positions[1] = b.positions[0]+Vector2(40,0)
    tick(b,2)
    driver.step_slot(0)
    check(b.wave == 1 and b.rescuer == 0 and b.confirmed == [false,false],"driver prioritizes actual rescue before any ready input")
    b = cleared()
    b.hp[1] = 0
    b.positions[1] = b.positions[0]+Vector2(40,0)
    tick(b,2)
    b.interact(0)
    tick(b,1.3)
    check(b.wave == 1 and b.hp == [1,2] and b.confirmed == [false,false],"rescue restores only downed partner and does not count as readiness")
    b.interact(0)
    check(b.wave == 1,"rescuer alone still waits for recovered player's choice")
    b.interact(1)
    check(b.wave == 2,"rescued pair can choose next wave")
    b = cleared(true)
    var ai = Solo.new()
    for frame in range(600): ai.step(b,1.0/120,Vector2.ZERO)
    check(b.wave == 1 and b.phase == "intermission","AI never supplies the human's next-wave confirmation")
    check(b.get("story_encounter") != null,"explicit story encounter configuration exists")
    if b.get("story_encounter") != null:
        for mode in [false,true]:
            var layouts := {}
            for name in ["first","shell","reserve"]:
                var total_health := 0.0
                var rows: Array = []
                b = B.new()
                b.solo_mode = mode
                b.story_encounter = name
                check(b.wave_total == 2 and b.story_first == (name == "first"),"story configuration agrees with cast and two waves "+name)
                for wave in [1,2]:
                    b._start_wave(wave)
                    var row := {"kinds":[],"positions":[],"seeds":[]}
                    for e in b.enemies:
                        row.kinds.append(e.kind)
                        row.positions.append(str(e.pos))
                        total_health += e.max_hp
                    for seed in b.seeds: row.seeds.append(str(seed.pos))
                    rows.append(row)
                    check(b.enemies.size() <= (2 if name in ["first","shell"] else 3),"encounter population stays within original bound "+name)
                    check(b.enemies.all(func(e): return b.positions.all(func(p): return p.distance_to(e.pos) >= 200)),"story spawn does not overlap arrivals "+name)
                check(total_health <= 30,"story encounter never adds HP budget "+name)
                layouts[name] = rows
                print("M27_ENCOUNTER_LAYOUT ",JSON.stringify({"encounter":name,"solo":mode,"total_hp":total_health,"waves":rows}))
            check(layouts.shell[0].kinds != layouts.reserve[0].kinds,"shell and reserve ask different first-wave decisions")
            check(layouts.shell[1].positions != layouts.reserve[1].positions and layouts.shell[1].seeds != layouts.reserve[1].seeds,"reserve combines a different formation and existing plant terrain")
        b = B.new()
        b.story_encounter = "reserve"
        b._start_wave(1)
        var seed: Dictionary = b.seeds[0]
        var health_before := 0.0
        for e in b.enemies: health_before += e.hp
        b.garden.strike(b,seed.pos-Vector2(60,0),Vector2.RIGHT,105,PI/2,true)
        # Stationary fixture isolates the designed seed lane from enemy AI.
        for frame in range(120): b.garden.step(b,1.0/120)
        var damaged := 0
        for e in b.enemies:
            if e.hp < e.max_hp: damaged += 1
        check(damaged >= 2,"reserve rolling plant lane can affect a group, not only decoration")
    print("M27_ENCOUNTER_PACE: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
