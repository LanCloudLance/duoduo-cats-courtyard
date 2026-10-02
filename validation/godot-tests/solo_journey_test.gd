extends "res://tests/keyboard_scene_test.gd"
# Real one-player keyboard events throughout. No position, health, progress or
# enemy writes. Save paths alone are isolated; combat uses production companion AI.
const Map = preload("res://game/light_layout.gd")
const Store = preload("res://game/checkpoint.gd")
const Driver = preload("res://tests/battle_driver.gd")
const SAVE := "user://test-m11-solo-journey.json"
const DUAL_SAVE := "user://test-m11-dual-isolated.json"
var s
var b
var started := 0
var single_pad := false
func selected():
    match lobby.stage:
        "bridge": return lobby.courtyard.selection
        "light": return lobby.light_corridor.selection
        "rest": return lobby.rest_area.selection
    return null
func state():
    match lobby.stage:
        "bridge": return lobby.courtyard.party
        "light": return lobby.light_corridor.puzzle
        "rest": return lobby.rest_area.state
    return null
func pick(actor: int) -> void:
    if selected().actor == actor: return
    if selected().previous == actor: tap_key(KEY_Q)
    else:
        for i in range(3):
            if selected().actor == actor: break
            tap_key(KEY_TAB)
func drive(_slot: int, vector: Vector2) -> void:
    if not single_pad:
        axes(9,vector)
        return
    for axis in range(2):
        var event := InputEventJoypadMotion.new()
        event.device = 9
        event.axis = axis as JoyAxis
        event.axis_value = vector[axis]
        Input.parse_input_event(event)
    Input.flush_buffered_events()
func tap_key(code: int) -> void:
    if single_pad:
        if code in [KEY_ENTER,KEY_ESCAPE]:
            button(9,JOY_BUTTON_START)
            return
        var buttons := {KEY_E:JOY_BUTTON_A,KEY_SPACE:JOY_BUTTON_A,KEY_F:JOY_BUTTON_X,KEY_J:JOY_BUTTON_X,KEY_Q:JOY_BUTTON_B,KEY_K:JOY_BUTTON_B,KEY_TAB:JOY_BUTTON_Y,KEY_R:JOY_BUTTON_RIGHT_SHOULDER,KEY_G:JOY_BUTTON_LEFT_SHOULDER}
        if buttons.has(code): button(9,buttons[code])
        return
    var mapped: int = {KEY_J:KEY_F,KEY_K:KEY_Q,KEY_SPACE:KEY_E}.get(code,code)
    key_event(mapped,true)
    key_event(mapped,false)
func key_event(code: int, down: bool) -> void:
    if single_pad:
        var buttons := {KEY_G:JOY_BUTTON_LEFT_SHOULDER,KEY_F:JOY_BUTTON_X,KEY_J:JOY_BUTTON_X}
        if buttons.has(code):
            var event := InputEventJoypadButton.new()
            event.device = 9
            event.button_index = buttons[code] as JoyButton
            event.pressed = down
            Input.parse_input_event(event)
            Input.flush_buffered_events()
        return
    super.key_event(code,down)
func direction(offset: Vector2) -> Vector2:
    return Vector2(0 if absf(offset.x)<3 else signf(offset.x),0 if absf(offset.y)<3 else signf(offset.y))
func walk(actor: int, target: Vector2) -> bool:
    pick(actor)
    for i in range(700):
        var offset: Vector2 = target-state().positions[actor]
        if offset.length()<7:
            drive(0,Vector2.ZERO)
            return true
        drive(0,direction(offset))
        await frames(1)
    drive(0,Vector2.ZERO)
    print("SOLO WALK STUCK stage=",lobby.stage," role=",actor," target=",target," pos=",state().positions)
    return false
func aim(actor: int, target: Vector2) -> bool:
    pick(actor)
    for i in range(300):
        var offset: Vector2 = target-s.beam
        if offset.length()<6:
            drive(0,Vector2.ZERO)
            return true
        drive(0,direction(offset))
        await frames(1)
    drive(0,Vector2.ZERO)
    return false
func crossing(actor: int, points: Array) -> bool:
    var operator: int = 1 if actor == 0 else 0
    for goal in points:
        # Illuminate only a short next step, then manually switch and walk it.
        for j in range(25):
            var point: Vector2 = s.positions[actor]
            if point.distance_to(goal)<7: break
            var next: Vector2 = point.move_toward(goal,32)
            if not await aim(operator,next): return false
            if not await walk(actor,next): return false
        if s.positions[actor].distance_to(goal)>=7: return false
    return true
func gate(ok: bool, label: String) -> bool:
    check(ok,label)
    if not ok:
        if s != null: print("LIGHT STATE phase=",s.phase," light=",s.lit," op=",s.operator_slot," beam=",s.beam," held=",s.held_actor," recovery=",s.recoveries)
        finish()
    return ok
func milestone(label: String) -> void:
    print("SOLO JOURNEY ",label," elapsed=",snappedf((Time.get_ticks_msec()-started)/1000.0,0.1))
func first_half() -> bool:
    if not await walk(2,Map.LAMP_NEAR): return false
    tap_key(KEY_R)
    check(s.lit,"solo R deploys white light")
    if not await walk(0,Map.GUIDE_NEAR): return false
    tap_key(KEY_E)
    if not await walk(1,Vector2(260,440)): return false
    if not await crossing(1,[Vector2(330,440),Vector2(410,355),Vector2(475,430),Vector2(600,430)]): return false
    if not await walk(1,Map.RELAY): return false
    tap_key(KEY_R)
    tap_key(KEY_R)
    check(s.phase == "girl" and s.operator_slot == 1,"manual relay begins girl crossing")
    if not await walk(0,Vector2(260,520)): return false
    if not await crossing(0,[Vector2(340,540),Vector2(440,540),Vector2(540,480),Vector2(605,480)]): return false
    if not await walk(0,Map.FRONT_LOCK): return false
    tap_key(KEY_E)
    tap_key(KEY_E)
    return s.front_fixed
func route_half(route: String) -> bool:
    if not await walk(2,Vector2(250,480)): return false
    if not await walk(2,Vector2(605,480)): return false
    if not await walk(2,Map.LAMP_SAFE if route == "safe" else Map.LAMP_FAST): return false
    tap_key(KEY_R)
    if not await walk(0,Map.FRONT_LOCK): return false
    tap_key(KEY_E)
    if not await walk(0,Map.GUIDE_MID): return false
    tap_key(KEY_E)
    if not await walk(1,Vector2(740,380) if route == "safe" else Vector2(740,530)): return false
    # Pause with the beam held, then ensure stale axes do not leak on resume.
    pick(0)
    drive(0,Vector2.RIGHT)
    tap_key(KEY_ESCAPE)
    var beam: Vector2 = s.beam
    var pos: Array = s.positions.duplicate()
    await frames(8)
    check(s.beam == beam and s.positions == pos,"solo pause freezes beam and all actors")
    tap_key(KEY_ENTER)
    await frames(5)
    check(s.beam == beam and s.positions == pos,"solo resume clears old axes")
    var points: Array = [Vector2(820,320),Vector2(905,320),Vector2(985,355),Vector2(1080,380)] if route == "safe" else [Vector2(825,550),Vector2(900,475),Vector2(990,510),Vector2(1080,480)]
    if not await crossing(1,points): return false
    if not await walk(1,Map.FAR_LOCK): return false
    tap_key(KEY_R)
    if not await walk(0,Map.FAR_WINCH): return false
    tap_key(KEY_E)
    if not s.permanent: return false
    if not await walk(2,Vector2(740,480)): return false
    if not await walk(2,Vector2(1110,480)): return false
    if not await walk(2,Vector2(1150,525)): return false
    if not await walk(0,Vector2(740,480)): return false
    if not await walk(0,Vector2(1100,480)): return false
    if not await walk(0,Vector2(1120,525)): return false
    await frames(60)
    tap_key(KEY_E)
    return s.finished
func launch() -> void:
    lobby = load("res://main.tscn").instantiate()
    lobby.checkpoint = Store.new(DUAL_SAVE)
    lobby.solo_checkpoint = Store.new(SAVE)
    root.add_child(lobby)
    await frames(2)
    lobby.session.set_focus(true)
    if single_pad:
        button(9,JOY_BUTTON_DPAD_DOWN)
        button(9,JOY_BUTTON_A)
        button(9,JOY_BUTTON_START)
    else: lobby.get_node("SingleJourney").pressed.emit()
    await frames(2)
func run() -> void:
    single_pad = "--single-pad" in OS.get_cmdline_user_args()
    started = Time.get_ticks_msec()
    DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
    DirAccess.remove_absolute(ProjectSettings.globalize_path(DUAL_SAVE))
    await launch()
    check(lobby.session.single_player and not lobby.preview_run and not lobby.session.ready_flags[1],"full solo entry uses only player one")
    if not gate(await walk(0,Vector2(960,620)),"girl reaches winch"): return
    for i in range(3):
        pick(0)
        tap_key(KEY_E)
        if not gate(await walk(1,Vector2(1132+120*i,640)),"black walks bridge segment"): return
        tap_key(KEY_E)
        check(lobby.courtyard.bridge.unlocked == i+1,"manual girl and black alternate locks")
    if not gate(await walk(0,Vector2(1480,640)),"girl crosses bridge"): return
    if not gate(await walk(1,Vector2(1560,640)),"black reaches exit"): return
    await frames(100)
    tap_key(KEY_E)
    if not gate(lobby.courtyard.bridge.finished,"single confirmation waits for all three"): return
    tap_key(KEY_E)
    await frames(2)
    if not gate(lobby.stage == "combat" and lobby.arena.battle.solo_mode,"solo bridge enters solo combat"): return
    b = lobby.arena.battle
    check(b.phase == "briefing","transition key did not auto start combat")
    milestone("bridge complete")
    var driver = Driver.new(self,b)
    tap_key(KEY_E)
    for i in range(8500):
        if b.phase == "clear": break
        driver.step_slot(lobby.arena.solo.human_slot)
        await frames(1)
    drive(0,Vector2.ZERO)
    key_event(KEY_G,false)
    if not gate(b.phase == "clear","one input and production AI clear three live rounds"): return
    for i in range(900):
        if b.hp[0]>0 and b.hp[1]>0: break
        driver.step_slot(lobby.arena.solo.human_slot)
        await frames(1)
    for i in range(700):
        var point: Vector2 = b.positions[b.actor(lobby.arena.solo.human_slot)]
        drive(0,b.Space.direction(point,b.EXIT,b.Space.ACTOR_RADIUS) if point.distance_to(b.EXIT)>15 else Vector2.ZERO)
        if b.positions[0].distance_to(b.EXIT)<90 and b.positions[b.current_cat].distance_to(b.EXIT)<90: break
        await frames(1)
    drive(0,Vector2.ZERO)
    tap_key(KEY_E)
    if not gate(b.phase == "complete" and lobby.stage == "combat","combat requires separate transition"): return
    var health: Array = b.hp.duplicate()
    tap_key(KEY_E)
    await frames(2)
    if not gate(lobby.stage == "light" and lobby.session.single_player,"solo combat proceeds to manual puzzle"): return
    s = lobby.light_corridor.puzzle
    check(s.hp == health,"health carries between stages")
    milestone("combat complete")
    if not gate(await first_half(),"single input completes both front crossings"): return
    if not gate(await route_half("safe"),"single input completes safe path and reunion"): return
    milestone("light complete")
    tap_key(KEY_E)
    await frames(2)
    if not gate(lobby.stage == "rest" and lobby.rest_area.can_save,"full solo reaches save-enabled rest"): return
    var rest = lobby.rest_area.state
    check(rest.full_run() and rest.hp == health,"rest reflects all actual stages")
    if not gate(await walk(0,Vector2(610,460)),"girl reaches bench"): return
    if not gate(await walk(2,Vector2(690,460)),"cats reach bench"): return
    await frames(50)
    tap_key(KEY_E)
    if not gate(rest.rested and rest.hp == [3,3],"single bench interaction rests all three"): return
    check(not Store.new(SAVE).read_checkpoint().is_empty() and Store.new(DUAL_SAVE).read_checkpoint().is_empty(),"solo save does not overwrite dual mode")
    if not gate(await walk(0,Vector2(1070,460)),"girl reaches final exit"): return
    if not gate(await walk(2,Vector2(1130,460)),"cats reach final exit"): return
    await frames(50)
    tap_key(KEY_E)
    if not gate(rest.finished,"full single journey completes from normal entry"): return
    milestone("four areas complete")
    lobby.free()
    await frames(2)
    await launch()
    tap_key(KEY_ESCAPE)
    lobby.solo_resume_button.pressed.emit()
    if single_pad: button(9,JOY_BUTTON_START)
    await frames(2)
    check(lobby.stage == "rest" and lobby.session.single_player and lobby.rest_area.state.full_run(),"fresh scene resumes earned solo checkpoint")
    # Replay only the light scene from spawn to test the second route; no state writes.
    tap_key(KEY_ESCAPE)
    lobby.get_node("SingleJourney").pressed.emit()
    if single_pad: button(9,JOY_BUTTON_START)
    lobby.enter_light()
    await frames(2)
    s = lobby.light_corridor.puzzle
    if not gate(await first_half(),"second run repeats manual relay"): return
    if not gate(await route_half("fast"),"solo shortcut also finishes with one input"): return
    DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
    DirAccess.remove_absolute(ProjectSettings.globalize_path(DUAL_SAVE))
    finish()
func finish() -> void:
    print(("SOLO_PAD_JOURNEY:" if single_pad else "SOLO_JOURNEY:")+" %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
