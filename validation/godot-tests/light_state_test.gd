extends SceneTree
var checks := 0
var failed := 0
func check(value: bool, label: String) -> void:
    checks += 1
    if not value:
        failed += 1
        push_error("FAIL: " + label)
func _initialize() -> void:
    var s = load("res://game/light_state.gd").new()
    # A single interaction must enter continuous aiming, not permanently light a segment.
    check(s.get("operator_slot") != null, "light requires an independent continuous operator")
    if failed:
        print("LIGHT_STATE: %d checks, %d failed" % [checks,failed])
        quit(1)
        return
    run_rules(s)
    print("LIGHT_STATE: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
func run_rules(s) -> void:
    var L = load("res://game/light_layout.gd")
    s.positions[0] = L.GUIDE_NEAR
    s.interact(0)
    check(s.operator_slot == -1, "no beam operation without a light source")
    s.current_cat = 2
    s.positions[2] = L.LAMP_NEAR
    s.tool(1)
    s.switch_cat()
    s.interact(0)
    check(s.operator_slot == 0 and s.lit, "girl enters beam control while white maintains source")
    var girl: Vector2 = s.positions[0]
    var beam: Vector2 = s.beam
    s.step(0.1, Vector2.RIGHT, Vector2.ZERO, true)
    check(s.positions[0] == girl and s.beam.x > beam.x, "aim input moves beam but not operator body")
    s.positions[1] = Vector2(300,440)
    s.beam = Vector2(300,440)
    for i in range(30): s.step(0.05,Vector2.ZERO,Vector2.RIGHT,true)
    check(s.positions[1].x < 365, "stationary beam cannot pre-light whole crossing")
    # Off-light actor is caught in place; recentering rescues before timeout.
    s.positions[1] = Vector2(330,440)
    s.beam = Vector2(480,430)
    var cat: Vector2 = s.positions[1]
    s.step(0.1,Vector2.ZERO,Vector2.RIGHT,true)
    check(s.positions[1] == cat and s.slipping[1] > 0, "off-light grace freezes forward movement")
    var grace: float = s.slipping[1]
    s.step(0.1,Vector2.RIGHT,Vector2.RIGHT,false)
    check(s.slipping[1] == grace and s.positions[1] == cat, "pause freezes grace and coordinates")
    s.beam = cat
    s.step(0.1,Vector2.ZERO,Vector2.ZERO,true)
    check(s.slipping[1] == 0, "partner can rescue slipping cat with light")
    s.beam = Vector2(550,430)
    for i in range(25): s.step(0.1,Vector2.ZERO,Vector2.ZERO,true)
    check(s.positions[1].x < 280 and s.recoveries == 1, "timeout returns to earned safe bank")
    s.positions[1] = L.ISLAND_ONE.get_center()
    s.step(0.01,Vector2.ZERO,Vector2.ZERO,true)
    s.positions[1] = Vector2(465,419)
    s.switch_cat()
    s.tool(1)
    check(not s.lit and s.positions[1].distance_to(L.ISLAND_ONE.get_center()) < 1, "release recovers inactive cat to reached island")
    check(s.operator_slot == -1, "light release ends operator mode")
    s.tool(1)
    s.switch_cat()
    s.positions[1] = L.RELAY
    s.tool(1)
    check(s.phase == "girl" and not s.front_fixed, "black relay opens girl crossing but not permanent bridge")
    s.tool(1)
    check(s.operator_slot == 1, "black operates reflector without girl holding near desk")
    s.positions[0] = Vector2(330,536)
    s.beam = s.positions[0]
    girl = s.positions[0]
    cat = s.positions[1]
    s.step(0.05,Vector2.RIGHT,Vector2.RIGHT,true)
    check(s.positions[0].x > girl.x and s.positions[1] == cat, "roles reverse with independently moving girl and beam")
    s.switch_cat()
    check(s.operator_slot == -1 and s.lit, "switching operator cat exits desk without releasing white source")
    s.current_cat = 1
    s.positions[0] = L.FRONT_LOCK
    s.interact(0)
    s.interact(0)
    check(s.front_fixed and s.phase == "route", "girl secures front bridge before source relocation")
    s.current_cat = 2
    var black_wait: Vector2 = s.positions[1]
    for i in range(10): s.step(0.05,Vector2.ZERO,Vector2.ZERO,true)
    check(s.positions[1] == black_wait, "black waits on middle island while player retrieves white")
    s.positions[2] = L.LAMP_SAFE
    # Moving source is normally done via step; this fixture tests socket selection independently.
    if s.lit: s.tool(1)
    s.tool(1)
    check(s.route == "safe" and s.lit, "middle safe socket selects wide route")
    s.current_cat = 1
    s.positions[0] = L.GUIDE_MID
    s.interact(0)
    check(s.operator_slot == 0, "girl guides far route using relocated white source")
    s.positions[1] = L.ISLAND_SAFE.get_center()
    s.step(0.01,Vector2.ZERO,Vector2.ZERO,true)
    s.interact(1)
    check(s.positions[1].x < 760 and s.front_fixed, "safe island return allows reselecting route without resetting front bridge")
    s.current_cat = 2
    s.tool(1)
    s.positions[2] = L.LAMP_FAST
    s.tool(1)
    check(s.route == "fast" and s.lit, "shortcut socket changes active route")
    check(not s.allows(1,Vector2(820,320)), "unselected safe branch is not traversable")
    s.current_cat = 1
    s.positions[1] = L.FAR_LOCK
    s.tool(1)
    check(s.latched and not s.permanent, "black unlocks far latch but girl must fix bridge")
    s.positions[0] = L.GUIDE_MID
    if s.operator_slot == 0: s.interact(0)
    s.positions[0] = L.FRONT_LOCK
    s.interact(0)
    s.positions[0] = L.FAR_WINCH
    s.interact(0)
    check(s.permanent and s.allows(2,Vector2(900,480)), "permanent far bridge supports white without beam")
    s.current_cat = 2
    if s.lit: s.tool(1)
    s.positions[0] = Vector2(1130,470)
    s.positions[2] = Vector2(1150,490)
    s.positions[1] = Vector2(690,480)
    s.interact(0)
    s.interact(1)
    check(not s.finished, "exit waits for inactive cat")
    for i in range(160): s.step(0.05,Vector2.ZERO,Vector2.ZERO,true)
    check(s.finished, "inactive cat follows permanent bridges to complete gathering")
    s = load("res://game/light_state.gd").new()
    s.positions[0] = L.FRONT_LOCK
    s.interact(0)
    check(not s.front_fixed, "girl cannot skip relay to fix front bridge")
    s.positions[1] = L.FAR_LOCK
    s.tool(1)
    check(not s.latched, "black cannot unlock far bridge before middle source")
    s.step(0.1,Vector2(INF,0),Vector2.ZERO,true)
    check(s.positions[0].is_finite(), "invalid axis input cannot corrupt state")
