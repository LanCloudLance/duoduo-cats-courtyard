extends SceneTree
const Light = preload("res://game/light_state.gd")
const Map = preload("res://game/light_layout.gd")
var checks := 0
var failed := 0
func check(value: bool, label: String) -> void:
    checks += 1
    if not value:
        failed += 1
        push_error("FAIL: "+label)
func room(solo: bool):
    var s = Light.new()
    s.solo_mode = solo
    s.lit = true
    s.source = "near"
    s.beam = Vector2(330,440)
    return s
func _initialize() -> void:
    var s = room(false)
    check(s.get("charge_levels") != null,"illuminated stones retain a real support state")
    if failed:
        finish()
        return
    for solo in [false,true]:
        s = room(solo)
        s.step(0.05,Vector2.ZERO,Vector2.ZERO,true)
        s.beam = Vector2(580,440)
        check(not s.allows(1,Vector2(330,440)),"brief sweep does not instantly charge a stone")
        s.beam = Vector2(330,440)
        for i in range(5): s.step(0.1,Vector2.ZERO,Vector2.ZERO,true)
        s.beam = Vector2(580,440)
        check(s.allows(1,Vector2(330,440)),"charged foothold stays usable after the beam moves")
        check(not s.allows(1,Vector2(475,430)),"charging one foothold cannot silently pave the whole path")
        check(not s.allows(0,Vector2(330,440)) and not s.allows(2,Vector2(330,440)),
            "charging cannot bypass the narrow path's role constraints")
        var expiring = room(solo)
        for i in range(5): expiring.step(0.1,Vector2.ZERO,Vector2.ZERO,true)
        expiring.beam = Vector2(580,440)
        for i in range(110): expiring.step(0.1,Vector2.ZERO,Vector2.ZERO,true)
        check(not expiring.allows(1,Vector2(330,440)),"stored light expires without another illumination")
        var levels: PackedFloat32Array = s.charge_levels.duplicate()
        s.beam = Vector2(475,430)
        s.step(0.1,Vector2.ZERO,Vector2.ZERO,false)
        check(s.charge_levels == levels,"paused light neither charges nor erases stones")
        s.positions[1] = Vector2(330,440)
        s._release_light()
        check(not s.allows(1,Vector2(330,440)) and s.positions[1].x < 280,
            "removing white's light extinguishes memory and returns stranded traveler")
        s = room(solo)
        s.phase = "route"
        s.source = "safe"
        s.beam = Vector2(820,320)
        for i in range(5): s.step(0.1,Vector2.ZERO,Vector2.ZERO,true)
        s.beam = Vector2(990,510)
        check(s.allows(1,Vector2(820,320)),"safe route can retain prepared stepping stones")
        s.current_cat = 2
        s._release_light()
        s.positions[2] = Map.LAMP_FAST
        s.tool(1)
        check(not s.allows(1,Vector2(820,320)),"relocating source cannot carry charge into the wrong route")
        for route_kind in ["cat","girl","safe","fast"]:
            check(prepare_then_cross(solo,route_kind),"%s route crosses after one deliberate light sweep, solo=%s" % [route_kind,solo])
    finish()

func prepare_then_cross(solo: bool, route_kind: String) -> bool:
    var s = room(solo)
    s.phase = route_kind if route_kind in ["cat","girl"] else "route"
    s.route = route_kind if s.phase == "route" else "safe"
    s.source = s.route if s.phase == "route" else "near"
    s.positions[2] = Map.LAMP_NEAR if s.source == "near" else Map.LAMP_SAFE if s.source == "safe" else Map.LAMP_FAST
    s.positions[0] = Map.GUIDE_NEAR if s.phase == "cat" else Map.GUIDE_MID
    s.positions[1] = Map.RELAY
    var points: Array = s.path()
    var walker: int = s.traveler()
    var operator: int = 1 if walker == 0 else 0
    s.operator_slot = operator
    s.solo_actor = operator
    s.positions[walker] = points[0]
    s.beam = points[0]
    # Deliberately settle the first foothold before sweeping away from the bank.
    for i in range(4): s.step(0.1,Vector2.ZERO,Vector2.ZERO,true)
    for target in points:
        var attempts := 0
        while s.beam.distance_to(target) > 1 and attempts < 500:
            var input: Vector2 = (target-s.beam)/(280.0*0.025)
            s.step(0.025,input if operator == 0 else Vector2.ZERO,input if operator == 1 else Vector2.ZERO,true)
            attempts += 1
        if attempts >= 500:
            print("PREPARE_TIMEOUT ",route_kind," beam=",s.beam," target=",target)
            return false
    if operator == 0: s.interact(0)
    else: s.tool(1)
    s.solo_actor = walker
    for target in points:
        var attempts := 0
        while s.positions[walker].distance_to(target) > 1 and attempts < 500:
            var input: Vector2 = (target-s.positions[walker])/(220.0*0.025)
            s.step(0.025,input if walker == 0 else Vector2.ZERO,input if walker == 1 else Vector2.ZERO,true)
            attempts += 1
        if attempts >= 500:
            print("CROSS_TIMEOUT ",route_kind," solo=",solo," pos=",s.positions[walker]," target=",target," recoveries=",s.recoveries)
            return false
    return s.positions[walker].distance_to(points[-1]) < 2 and s.recoveries == 0 and s.lit
func finish() -> void:
    print("M20_LIGHT_CHARGE: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
