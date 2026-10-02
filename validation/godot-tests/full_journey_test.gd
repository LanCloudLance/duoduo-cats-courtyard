extends "res://tests/light_scene_test.gd"
# Continuous production-input journey: no shortcuts, teleports, health writes,
# enemy fixtures or direct completion flags. Only save destination is isolated.
const Store = preload("res://game/checkpoint.gd")
const SAVE := "user://test-full-journey-v1.json"
var b
var started := 0
func drive(slot: int, vector: Vector2) -> void:
    axes(9 if slot == 0 else 18,vector)
func movement_state():
    match lobby.stage:
        "bridge": return lobby.courtyard.party
        "combat": return lobby.arena.battle
        "light": return lobby.light_corridor.puzzle
        "gate": return lobby.chime_gate.puzzle
        "rest": return lobby.rest_area.state
    return null
func walk(slot: int, target: Vector2) -> bool:
    for i in range(800):
        var state = movement_state()
        var index: int = 0 if slot == 0 else state.current_cat
        var offset: Vector2 = target-state.positions[index]
        if offset.length()<7:
            drive(slot,Vector2.ZERO)
            return true
        drive(slot,Vector2(0 if absf(offset.x)<4 else signf(offset.x),0 if absf(offset.y)<4 else signf(offset.y)))
        await frames(1)
    drive(slot,Vector2.ZERO)
    push_error("Full journey walk timeout in "+lobby.stage+" toward "+str(target))
    return false
func milestone(label: String) -> void:
    print("JOURNEY ",label," elapsed=",snappedf((Time.get_ticks_msec()-started)/1000.0,0.1),"s")
func gate(condition: bool, label: String) -> bool:
    check(condition,label)
    if not condition:
        print("FULL_JOURNEY: stopped at ",label,"; ",checks," checks, ",failed," failed")
        quit(1)
    return condition
var combat_driver
func bot(slot: int) -> void:
    if combat_driver == null:
        combat_driver = load("res://tests/battle_driver.gd").new(self,b)
    combat_driver.step_slot(slot)
func run() -> void:
    started = Time.get_ticks_msec()
    DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
    lobby = load("res://main.tscn").instantiate()
    lobby.checkpoint = Store.new(SAVE)
    root.add_child(lobby)
    await frames(2)
    lobby.session.set_focus(true)
    tap_key(KEY_ENTER)
    await frames(2)
    if not gate(lobby.stage=="bridge" and not lobby.preview_run,"normal Enter starts complete journey"): return
    check(await walk(0,Vector2(960,620)),"girl reaches first winch")
    for stage_number in range(3):
        tap_key(KEY_E)
        check(await walk(1,Vector2(1132+120*stage_number,640)),"black walks next bridge platform")
        tap_key(KEY_SPACE)
        if not gate(lobby.courtyard.bridge.unlocked==stage_number+1,"bridge latch needs both roles"): return
    check(await walk(0,Vector2(1480,640)),"girl crosses completed bridge")
    check(await walk(1,Vector2(1560,640)),"black walks to first gathering point")
    await frames(100)
    tap_key(KEY_E)
    tap_key(KEY_SPACE)
    if not gate(lobby.courtyard.bridge.finished,"all three complete bridge through inputs"): return
    milestone("bridge complete")
    tap_key(KEY_E)
    await frames(2)
    if not gate(lobby.stage=="combat","bridge exit enters combat normally"): return
    b=lobby.arena.battle
    check(await walk(1,Vector2(160,620)),"cat walks clear of charge exercise")
    check(await walk(0,Vector2(690,420)),"girl walks into charge lane")
    tap_key(KEY_E)
    tap_key(KEY_SPACE)
    for i in range(1000):
        if b.hp[0]==0: break
        await frames(1)
    if not gate(b.hp[0]==0 and b.hp[1]==3,"live enemy attacks down girl naturally"): return
    for i in range(1800):
        if b.hp[0]>0 or b.retries>0: break
        bot(1)
        await frames(1)
    drive(1,Vector2.ZERO)
    if not gate(b.hp[0]>0 and b.retries==0,"cat walks over and revives girl in continuous run"): return
    for i in range(9000):
        if b.phase=="clear": break
        bot(0)
        bot(1)
        await frames(1)
    drive(0,Vector2.ZERO)
    drive(1,Vector2.ZERO)
    if not gate(b.phase=="clear","all three live combat rounds defeated"): return
    for i in range(1800):
        if b.hp[0]>0 and b.hp[1]>0: break
        bot(0)
        bot(1)
        await frames(1)
    check(await walk(0,Vector2(1015,570)),"girl reaches combat camp")
    check(await walk(1,Vector2(1085,570)),"cat reaches combat camp")
    tap_key(KEY_E)
    tap_key(KEY_SPACE)
    if not gate(b.phase=="complete","both confirm combat complete"): return
    var health: Array = b.hp.duplicate()
    milestone("combat complete hp="+str(health))
    tap_key(KEY_E)
    await frames(2)
    if not gate(lobby.stage=="light" and lobby.light_corridor.puzzle.hp==health,"combat health carries into light corridor"): return
    s = lobby.light_corridor.puzzle
    if not gate(await first_half(),"continuous swapped-role light crossings"): return
    if not gate(await select_route("safe"),"continuous source relocation and branch choice"): return
    if not gate(await finish_route("safe"),"continuous M7 light completion"): return
    milestone("light complete")
    tap_key(KEY_E)
    await frames(2)
    if not gate(lobby.stage == "gate","completed light corridor reaches bell gate"): return
    if not gate(await load("res://tests/chime_driver.gd").solve(self,false),"physical bell rules finish continuous dual journey"): return
    milestone("bell gate complete")
    if not gate(lobby.stage=="rest" and lobby.rest_area.can_save,"normal route reaches save-enabled rest area"): return
    var rest = lobby.rest_area.state
    check(rest.full_run() and rest.hp==health,"rest board and health reflect actual completed journey")
    check(await walk(0,Vector2(610,460)),"girl walks to bench")
    check(await walk(1,Vector2(690,460)),"white walks to bench")
    await frames(50)
    tap_key(KEY_E)
    tap_key(KEY_SPACE)
    if not gate(rest.rested and rest.hp==[3,3],"shared rest restores health"): return
    var saved: Dictionary = Store.new(SAVE).read_checkpoint()
    if not gate(not saved.is_empty() and saved.completed.bridge and saved.completed.combat and saved.completed.light,"actual full journey produces complete checkpoint"): return
    tap_key(KEY_E)
    tap_key(KEY_SPACE)
    check(rest.pets[1]>0 and rest.greetings[1]>0,"both players interact with white cat after journey")
    check(await walk(0,Vector2(1070,460)),"girl walks to final exit")
    check(await walk(1,Vector2(1130,460)),"cat walks to final exit")
    await frames(50)
    tap_key(KEY_E)
    tap_key(KEY_SPACE)
    if not gate(rest.finished,"all four areas completed continuously"): return
    milestone("full journey complete")
    var duration := (Time.get_ticks_msec()-started)/1000.0
    lobby.free()
    await frames(2)
    lobby=load("res://main.tscn").instantiate()
    lobby.checkpoint=Store.new(SAVE)
    root.add_child(lobby)
    await frames(2)
    lobby.session.set_focus(true)
    lobby.resume_button.pressed.emit()
    await frames(2)
    check(lobby.stage=="rest" and lobby.rest_area.state.full_run() and lobby.rest_area.state.hp==[3,3],"fresh scene resumes checkpoint earned by actual full journey")
    DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
    print("FULL_JOURNEY: %d checks, %d failed; automation_wall_seconds=%.1f" % [checks,failed,duration])
    quit(1 if failed else 0)
