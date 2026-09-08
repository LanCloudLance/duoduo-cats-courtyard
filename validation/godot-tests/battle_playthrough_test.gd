extends "res://tests/keyboard_scene_test.gd"
const Driver = preload("res://tests/battle_driver.gd")
var b
func drive(slot: int, vector: Vector2) -> void:
    # Real analog input is simulated with keyboard direction signs.
    axes(9 if slot == 0 else 18,vector)
func run() -> void:
    lobby = load("res://main.tscn").instantiate()
    root.add_child(lobby)
    await frames(2)
    lobby.session.set_focus(true)
    lobby.get_node("CombatPreview").pressed.emit()
    await frames(2)
    b = lobby.arena.battle
    tap_key(KEY_E)
    tap_key(KEY_SPACE)
    var bot = Driver.new(self,b)
    var started := Time.get_ticks_msec()
    var old_wave := 1
    for i in range(16000):
        if b.phase == "clear": break
        bot.step_slot(0)
        bot.step_slot(1)
        if b.wave != old_wave:
            old_wave = b.wave
            print("BATTLE_LIVE round=",b.wave," hp=",b.hp)
        await frames(1)
    drive(0,Vector2.ZERO)
    drive(1,Vector2.ZERO)
    key_event(KEY_G,false)
    check(b.phase == "clear" and b.wave == 3,"normal inputs defeat all three live rounds")
    check(bot.shield_openings > 0,"live tactics create shield openings before rear attacks")
    check(b.hp[0] > 0 and b.hp[1] > 0,"both players remain available after combat")
    print("BATTLE_LIVE hp=",b.hp," retries=",b.retries," shield_openings=",bot.shield_openings," stump_openings=",bot.stump_openings," seconds=",(Time.get_ticks_msec()-started)/1000.0)
    print("BATTLE_PLAYTHROUGH: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
