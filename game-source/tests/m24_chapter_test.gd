extends "res://tests/keyboard_scene_test.gd"
func run() -> void:
    lobby = load("res://main.tscn").instantiate()
    root.add_child(lobby)
    await frames(3)
    lobby.session.set_focus(true)
    check(lobby.has_method("start_chapter_one"),"first chapter has a real selectable entry")
    if not lobby.has_method("start_chapter_one"):
        print("M24_CHAPTER: %d checks, %d failed" % [checks,failed]);quit(1);return
    lobby.chapter_one.record_prefix = "qa-chapter-entry-"+str(Time.get_ticks_usec())
    lobby.session.pause_all()
    lobby.start_story(true)
    # Completed prologue fixture tests the real next-chapter input path.
    lobby.prologue.state.finished = true
    lobby.prologue.state.phase = "complete"
    lobby.prologue.recorded = true
    tap_key(KEY_E)
    await frames(3)
    check(lobby.stage == "chapter-one","completed prologue advances with the normal interaction key")
    lobby.session.pause_all()
    lobby.start_chapter_one(true)
    await frames(3)
    check(lobby.stage == "chapter-one" and lobby.chapter_one.visible,"chapter owns its view and input")
    check(not lobby.arena.visible and not lobby.prologue.visible,"story does not overlay old sample scenes")
    var c = lobby.chapter_one
    var s = c.state
    check(s.positions.size() == 2 and s.controlled == 0,"only Duoduo and Tuantuan are present")
    tap_key(KEY_TAB);await frames(2)
    check(s.controlled == 1,"single-player can switch to Tuantuan")
    tap_key(KEY_TAB);await frames(2)
    check(s.controlled == 0,"single-player cannot switch to absent Yuanyuan")
    key_event(KEY_D,true);await frames(4);key_event(KEY_D,false)
    check(s.positions[0].x > 210,"normal input moves the actual chapter actor")
    tap_key(KEY_ESCAPE);await frames(3)
    var saved: Array = s.positions.duplicate()
    var clock: float = s.clock
    await frames(10)
    check(s.positions == saved and s.clock == clock and not c.visible,"pause freezes story physics")
    tap_key(KEY_ENTER);await frames(3)
    check(c.visible and s.positions == saved,"resume clears held movement")
    c.start_battle()
    await frames(3)
    check(lobby.stage == "chapter-combat" and lobby.arena.visible,"chapter battle uses tested combat input and feedback")
    check(not lobby.arena.actors[2].visible,"white cat is absent from actual combat rendering")
    check(not "三位" in lobby.arena.objective_label.text,"chapter briefing only describes available roles")
    var b = lobby.arena.battle
    b.enemies.clear()
    b.positions[1] = Vector2(500,500)
    b.attack_direction[1] = Vector2.RIGHT
    b._spawn("weaver",Vector2(545,500))
    b.enemies[0].mode = "cast"
    b.attacks.strike(b,1,82,PI/3,1,false,false)
    check(not "圆圆" in b.message and "打断" in b.message,"Tuantuan interrupt never requests the absent white cat")
    for i in range(6):tap_key(KEY_TAB);await frames(1)
    check(lobby.arena.battle.current_cat == 1,"battle switching respects story party")
    check(lobby.arena.battle.wave_total == 2,"first chapter uses its own encounter length")
    lobby.session.pause_all()
    lobby.start_trial("combat",true);await frames(3)
    check(not lobby.arena.battle.story_first and lobby.arena.battle.wave_total == 3,"sample battle remains separate")
    print("M24_CHAPTER: %d checks, %d failed" % [checks,failed]);quit(1 if failed else 0)
