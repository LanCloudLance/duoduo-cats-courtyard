extends "res://tests/keyboard_scene_test.gd"
func run()->void:
    check(OS.get_user_data_dir().get_file()=="DuoduoCatsCourtyard-qa-m28-root","actual isolated root QA")
    if failed:quit(1);return
    lobby=load("res://main.tscn").instantiate();root.add_child(lobby);await frames(3)
    lobby.session.set_focus(true);lobby.story_progress.prefix="qa-m28-menu-input-"+str(Time.get_ticks_usec());lobby._refresh_checkpoint_button();await frames(2)
    check(lobby.journey_menu.visible and not lobby.get_node("SoloCombatPreview").visible and not lobby.get_node("ChapterSelect").visible,"release startup hides prototype navigation")
    tap_key(KEY_ENTER);await frames(4)
    check(lobby.stage=="prologue" and lobby.session.single_player and lobby.session.running(),"normal Enter starts full solo journey")
    var run_id:String=lobby.story_run_id
    tap_key(KEY_ESCAPE);await frames(3)
    check(lobby.journey_menu.visible and lobby.journey_menu.continue_button.visible and not lobby.prologue.active,"Escape shows paused journey, no gameplay progress")
    tap_key(KEY_ENTER);await frames(4)
    check(lobby.stage=="prologue" and lobby.story_run_id==run_id and lobby.session.running(),"normal Enter continues live state without reset")
    tap_key(KEY_ESCAPE);await frames(3)
    lobby.journey_menu.settings_panel.visible=true;lobby.journey_menu.music_button.grab_focus();await frames(2)
    var old:int=lobby.player_settings.music_level
    tap_key(KEY_ENTER);await frames(2)
    check(lobby.player_settings.music_level==(old+1)%3 and not lobby.session.running(),"settings selection cannot resume gameplay")
    tap_key(KEY_ESCAPE);await frames(2)
    check(not lobby.journey_menu.settings_panel.visible and not lobby.session.running(),"Esc returns settings to pause menu")
    lobby.session.set_focus(false);tap_key(KEY_ENTER);await frames(2)
    check(not lobby.session.running(),"unfocused menu cannot resume or create journey")
    lobby.session.set_focus(true);lobby.journey_menu.continue_button.grab_focus();tap_key(KEY_ENTER);await frames(3)
    check(lobby.story_run_id==run_id and lobby.prologue.active,"focused continuation restores the same journey")
    lobby.session.pause_all();lobby.queue_free();await frames(4)
    lobby=null
    var deadline:int=Time.get_ticks_msec()+100
    while Time.get_ticks_msec()<deadline:await process_frame
    print("M28_MENU_INPUT: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
