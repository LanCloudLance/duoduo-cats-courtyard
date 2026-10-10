extends SceneTree
# Legal mechanism fixture followed by real interactions and elapsed state time.
# Does not claim a from-menu playthrough or subjective clarity.
var lobby
var view
var captures:=0
func _init()->void:call_deferred("run")
func shot(label:String)->void:
    view._refresh(.016);view.queue_redraw();await process_frame
    RenderingServer.force_draw()
    var args:=OS.get_cmdline_user_args()
    if args.is_empty():quit(1);return
    if root.get_texture().get_image().save_png(args[0]+"-"+label+".png")!=OK:quit(1);return
    captures+=1
func elapsed(seconds:float)->void:
    for i in range(ceili(seconds*60)):
        view.state.step(1.0/60,Vector2.ZERO,Vector2.ZERO,true)
        view._refresh(1.0/60)
func run()->void:
    if OS.get_user_data_dir().get_file()!="DuoduoCatsCourtyard-qa-m28-root":quit(1);return
    lobby=Control.new();lobby.theme=Theme.new();lobby.theme.default_font=load("res://assets/fonts/CourtyardSans.ttf");root.add_child(lobby)
    var session=load("res://input/session_state.gd").new();session.keyboard_mode=true;session.single_player=true;session.ready_flags.assign([true,false])
    view=load("res://game/story_chapter_view.gd").new(session);lobby.add_child(view);view.set_physics_process(false)
    view.reset(5,true,false);view.set_active(true);view.audio.muted=true
    var s=view.state;s.phase="unjam";s.arm_locked=true;s.arm_route=1;s.far_walkway=true
    s.lid_open=true;s.lid_pins=2;s.lower_pin=true;s.upper_pin=true
    s.fixed_light=true;s.worklight_seen=true;s.isolation_open=true
    s.load_held=true;s.support_site="left";s.actions[0]="hold"
    s.positions.assign([s.WHEEL,s.REPAIR_SLOT,s.CRADLE])
    await shot("load-held-level")
    s.interact(1);elapsed(.4);await shot("left-latched-right-heavy")
    s.interact(0);elapsed(.1);await shot("girl-unloads-again")
    s.clear_holds();s.phase="test";s.machine_stopped=true;s.plate_aligned=true
    s.pilot_open=true;s.pilot_charged=true;s.beam_held=true;s.actions[2]="light"
    s.positions.assign([s.selected_test_end(),Vector2(940,620),s.TEST_SOURCE]);s.facing[2]=Vector2.RIGHT
    s.interact(0);elapsed(.4);await shot("girl-waits-portable-on")
    s.tool(2);elapsed(.6);await shot("girl-stays-portable-off")
    print("M28_MECHANISM_RENDER: ",captures," actual timed fixture frames")
    view=null;s=null;lobby.free();lobby=null;call_deferred("quit",0)
