extends "res://tests/keyboard_scene_test.gd"
const Store = preload("res://game/checkpoint.gd")
const SAVE := "user://test-m6-rest-scene.json"
var s
func pad_walk(slot: int, target: Vector2) -> bool:
    for i in range(600):
        var offset: Vector2 = target-s.positions[s.actor(slot)]
        var vector := Vector2.ZERO if offset.length()<6 else offset.normalized()
        for dimension in range(2):
            var event := InputEventJoypadMotion.new()
            event.device = 9 if slot == 0 else 18
            event.axis = dimension as JoyAxis
            event.axis_value = vector[dimension]
            Input.parse_input_event(event)
        Input.flush_buffered_events()
        if vector == Vector2.ZERO: return true
        await frames(1)
    return false
func walk(slot: int, target: Vector2) -> bool:
    for i in range(700):
        var current = lobby.chime_gate.puzzle if lobby.stage == "gate" else s
        var offset: Vector2 = target - current.positions[current.actor(slot)]
        if offset.length() < 7:
            axes(9 if slot == 0 else 18, Vector2.ZERO)
            return true
        axes(9 if slot == 0 else 18, Vector2(0 if absf(offset.x)<4 else signf(offset.x),0 if absf(offset.y)<4 else signf(offset.y)))
        await frames(1)
    return false
func new_lobby() -> void:
    lobby = load("res://main.tscn").instantiate()
    lobby.checkpoint = Store.new(SAVE)
    root.add_child(lobby)
    await frames(2)
    lobby.session.set_focus(true)
func run() -> void:
    DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
    await new_lobby()
    check(lobby.resume_button.disabled, "fresh installation does not offer nonexistent checkpoint")
    tap_key(KEY_ENTER)
    # Upstream completed-stage fixture isolates the light -> rest handoff. Rest
    # movement, interactions, save and resume all use the production input path.
    lobby.courtyard.bridge.finished = true
    lobby.arena.battle.phase = "complete"
    lobby.arena.battle.hp[0] = 1
    lobby.arena.battle.hp[1] = 2
    lobby.enter_light()
    lobby.light_corridor.puzzle.finished = true
    tap_key(KEY_E)
    await frames(2)
    check(await load("res://tests/chime_driver.gd").solve(self,false),"upstream fixture still needs actual bell gate inputs")
    world = lobby.rest_area
    s = world.state
    check(lobby.stage == "rest" and world.can_save and not s.rested, "gate completion enters rest without reusing interaction")
    check(s.hp == [1,2] and s.full_run(), "normal route brings health and completed-stage facts")
    check(await walk(0, Vector2(610,460)), "girl walks from entry to bench")
    check(await walk(1, Vector2(690,460)), "cat walks from entry to bench")
    await frames(50)
    tap_key(KEY_E)
    check(not s.rested, "girl cannot start shared rest alone")
    tap_key(KEY_SPACE)
    await frames(2)
    check(s.rested and s.hp == [3,3] and FileAccess.file_exists(SAVE), "both sit, restore health and persist checkpoint")
    check(not lobby.resume_button.disabled, "successful save enables continue button")
    if s.current_cat != 1: tap_key(KEY_TAB)
    await frames(75)
    tap_key(KEY_E)
    tap_key(KEY_SPACE)
    check(s.pets[0] == 1 and s.greetings[0] == 1, "both players can initiate black cat contact")
    if s.current_cat != 2: tap_key(KEY_TAB)
    check(await walk(1,Vector2(690,460)),"white cat approaches before contact")
    await frames(75)
    tap_key(KEY_E)
    check(s.pets[1] == 1, "white cat has a separately recorded interaction")
    key_event(KEY_D, true)
    lobby.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
    var saved: Array = s.positions.duplicate()
    await frames(4)
    check(not world.visible and s.positions == saved, "focus loss freezes rest movement")
    lobby.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN)
    tap_key(KEY_ENTER)
    await frames(2)
    check(s.positions[0] == saved[0], "resume does not retain held movement")
    check(await walk(0, Vector2(1070,460)), "girl walks to rest exit")
    check(await walk(1, Vector2(1130,460)), "white cat walks to rest exit")
    await frames(50)
    tap_key(KEY_E)
    check(not s.finished, "one player cannot finish journey alone")
    tap_key(KEY_SPACE)
    await frames(2)
    check(s.finished and world.objective_label.text.contains("庭院试玩完成"), "whole party receives honest full-run completion")
    var content := FileAccess.get_file_as_string(SAVE)
    lobby.free()
    await frames(2)
    await new_lobby()
    check(not lobby.resume_button.disabled and lobby.stage == "bridge", "fresh scene finds save without silently auto-resuming")
    lobby.resume_button.pressed.emit()
    await frames(2)
    world = lobby.rest_area
    s = world.state
    check(world.visible and s.rested and s.full_run() and s.current_cat == 2 and s.hp == [3,3], "continue reconstructs saved safe rest in a fresh scene")
    tap_key(KEY_ESCAPE)
    await frames(2)
    lobby.get_node("LightPreview").pressed.emit()
    lobby.light_corridor.puzzle.finished = true
    tap_key(KEY_E)
    await frames(2)
    check(await load("res://tests/chime_driver.gd").solve(self,false),"preview gate exits with normal movement and tools")
    s = lobby.rest_area.state
    check(lobby.stage == "rest" and not lobby.rest_area.can_save and not s.full_run(), "single-level preview handoff cannot claim full run or overwrite save")
    check(await walk(0, Vector2(610,460)) and await walk(1, Vector2(690,460)), "preview party can still reach bench")
    await frames(50)
    tap_key(KEY_E)
    tap_key(KEY_SPACE)
    await frames(2)
    check(s.rested and FileAccess.get_file_as_string(SAVE) == content, "preview resting leaves previous checkpoint byte-for-byte unchanged")
    tap_key(KEY_ESCAPE)
    await frames(2)
    lobby.get_node("ReplayCourtyard").pressed.emit()
    check(lobby.stage == "bridge" and not lobby.preview_run and not lobby.courtyard.bridge.finished and not lobby.light_corridor.puzzle.finished, "restart journey resets stages and returns to entrance")
    check(FileAccess.get_file_as_string(SAVE) == content, "starting over does not delete saved safe point")
    lobby.get_node("RestPreview").pressed.emit()
    lobby.router.use_gamepads()
    for device in [9,18,9,18]: button(device,JOY_BUTTON_START)
    s = lobby.rest_area.state
    check(await pad_walk(0,Vector2(610,460)) and await pad_walk(1,Vector2(690,460)), "two controller sticks move players to bench")
    await frames(50)
    button(9,JOY_BUTTON_A)
    button(18,JOY_BUTTON_A)
    check(s.rested and not lobby.session.keyboard_mode, "two controller confirmations complete shared rest")
    button(18,JOY_BUTTON_Y)
    check(s.current_cat == 2 and s.hp == [3,3], "controller switches cats at rest without changing health")
    lobby._connection_changed(18,false)
    await frames(2)
    check(not lobby.session.running() and s.rested and FileAccess.get_file_as_string(SAVE) == content, "controller disconnect pauses rest and preserves prior saved journey")
    DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
    print("REST_SCENE: %d checks, %d failed" % [checks, failed])
    quit(1 if failed else 0)
