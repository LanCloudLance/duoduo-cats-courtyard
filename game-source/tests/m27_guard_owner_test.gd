extends "res://tests/keyboard_scene_test.gd"
func joy(button:int,down:bool)->void:
    var event:=InputEventJoypadButton.new();event.device=7;event.button_index=button as JoyButton;event.pressed=down
    Input.parse_input_event(event);Input.flush_buffered_events()
func run()->void:
    lobby=load("res://main.tscn").instantiate();root.add_child(lobby);await frames(3);lobby.session.set_focus(true)
    lobby.story_chapter.record_prefix="qa-m27-guard-owner-"+str(Time.get_ticks_usec());lobby.start_story_chapter(5,true);await frames(3)
    var state=lobby.story_chapter.state
    key_event(KEY_G,true);tap_key(KEY_TAB);key_event(KEY_G,false)
    check(state.controlled==1 and not state.shield_held,"keyboard release targets the original shield owner after Tab")
    tap_key(KEY_Q);key_event(KEY_G,true);tap_key(KEY_TAB);tap_key(KEY_Q);key_event(KEY_G,false)
    check(state.controlled==0 and not state.shield_held,"Q return does not leave a held guard")
    key_event(KEY_G,true);lobby.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT);await frames(2)
    check(not state.shield_held and not lobby.session.running(),"focus loss cancels guard owner and held command")
    lobby.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN);tap_key(KEY_ENTER);await frames(2)
    lobby.session.keyboard_mode=false;lobby.session.devices.assign([7,-1]);lobby.session.ready_flags.assign([true,false]);state.controlled=0
    joy(JOY_BUTTON_LEFT_SHOULDER,true);joy(JOY_BUTTON_Y,true);joy(JOY_BUTTON_Y,false);joy(JOY_BUTTON_LEFT_SHOULDER,false)
    check(state.controlled==1 and not state.shield_held,"controller shoulder release targets original owner after handoff")
    lobby.router.start_keyboard();tap_key(KEY_H);await frames(3)
    var phase:String=state.phase;var points:Array=state.positions.duplicate();var hints:int=state.hints
    tap_key(KEY_V);await frames(3)
    check(state.hints==hints+1 and not state.shield_held and state.phase==phase and state.positions==points,"chapter five real hint input does not raise shield or advance machinery")
    tap_key(KEY_H);await frames(2);lobby.queue_free();await frames(3)
    print("M27_GUARD_OWNER: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
