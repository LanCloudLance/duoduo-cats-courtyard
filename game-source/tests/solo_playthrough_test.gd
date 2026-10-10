extends "res://tests/keyboard_scene_test.gd"
const Driver = preload("res://tests/battle_driver.gd")
var b
func drive(_slot: int, direction: Vector2) -> void:
    axes(9,direction)
func tap_key(code: int) -> void:
    var mapped: int = {KEY_J:KEY_F,KEY_K:KEY_Q,KEY_SPACE:KEY_E}.get(code,code)
    key_event(mapped,true)
    key_event(mapped,false)
func run() -> void:
    lobby = load("res://main.tscn").instantiate()
    root.add_child(lobby)
    await frames(2)
    lobby.session.set_focus(true)
    for role in [0,2]:
        lobby.get_node("SoloCombatPreview").pressed.emit()
        await frames(2)
        b = lobby.arena.battle
        for i in range(role): tap_key(KEY_TAB)
        tap_key(KEY_E)
        var driver = Driver.new(self,b)
        var old_wave := 0
        for i in range(7000):
            if b.phase == "clear": break
            driver.step_slot(lobby.arena.solo.human_slot)
            if old_wave != b.wave:
                old_wave = b.wave
                print("SOLO_LIVE role=",role," wave=",b.wave," hp=",b.hp)
            await frames(1)
        drive(0,Vector2.ZERO)
        key_event(KEY_G,false)
        check(b.phase == "clear" and b.wave == 3,"one input stream plus production AI clears all rounds as role %d" % role)
        if b.phase != "clear":
            print("SOLO_STUCK ",b.phase," hp=",b.hp," pos=",b.positions," enemies=",b.enemies," ai=",lobby.arena.solo.companion.status)
            finish()
            return
        for i in range(900):
            if b.hp[0] > 0 and b.hp[1] > 0: break
            driver.step_slot(lobby.arena.solo.human_slot)
            await frames(1)
        check(b.hp[0] > 0 and b.hp[1] > 0,"both actors remain available for solo exit")
        for i in range(700):
            var point: Vector2 = b.positions[b.actor(lobby.arena.solo.human_slot)]
            drive(0,b.Space.direction(point,b.EXIT,b.Space.ACTOR_RADIUS) if point.distance_to(b.EXIT)>15 else Vector2.ZERO)
            if b.positions[0].distance_to(b.EXIT)<90 and b.positions[b.current_cat].distance_to(b.EXIT)<90: break
            await frames(1)
        drive(0,Vector2.ZERO)
        tap_key(KEY_E)
        check(b.phase == "complete","human confirms solo finish after companion physically arrives")
        check(lobby.stage == "combat" and not lobby.rest_area.can_save,"solo trial does not enter puzzle or save journey")
        tap_key(KEY_ESCAPE)
        await frames(2)
    finish()
func finish() -> void:
    print("SOLO_PLAYTHROUGH: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
