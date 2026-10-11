extends SceneTree
# Legal entry fixture + real state interactions; timed rendered evidence only.
# Natural input acceptance is m29_mainline_playthrough_test, not these frames.
var host
var view
var captures:=0
func _init()->void:call_deferred("run")
func shot(label:String)->void:
    view._refresh(.016);view.queue_redraw();await process_frame
    RenderingServer.force_draw()
    var args:=OS.get_cmdline_user_args()
    if args.is_empty() or root.get_texture().get_image().save_png(args[0]+"-"+label+".png")!=OK:quit(1);return
    captures+=1
func use(role:int,point:Vector2)->void:
    view.state.positions[role]=point;view.state.action_time[role]=0;view.state.interact(role)
func run()->void:
    if OS.get_user_data_dir().get_file()!="DuoduoCatsCourtyard-qa-m29-puzzle":quit(2);return
    host=Control.new();host.theme=Theme.new();host.theme.default_font=load("res://assets/fonts/CourtyardSans.ttf");root.add_child(host)
    var session=load("res://input/session_state.gd").new();session.keyboard_mode=true;session.single_player=true;session.ready_flags.assign([true,false])
    view=load("res://game/story_chapter_view.gd").new(session);host.add_child(view);view.set_physics_process(false)
    for side in ["left","right"]:
        view.reset(5,true,false);view.set_active(true);view.audio.muted=true
        var s=view.state
        var entry:Dictionary=s.checkpoint()
        entry.phase="unjam"
        for key in ["route_lock","route_supported","route_lit","bridge_locked","arm_locked","lid_open","lower_pin","upper_pin"]:entry.facts[key]=true
        entry.facts.lid_pins=2;entry.facts.stage_checkpoint=2
        entry.positions=[[1070,495],[995,600],[665,600]]
        if not s.restore_checkpoint(entry):push_error("invalid declared render entry");quit(3);return
        use(1,s.ISOLATOR);use(2,s.CRADLE);use(1,s.PIN_RACK);use(0,s.WHEEL)
        use(1,s.LEFT_SOCKET if side=="left" else s.RIGHT_SOCKET)
        await shot(side+"-unloaded")
        use(0,s.WHEEL)
        for i in range(30):s.step(.016,Vector2.ZERO,Vector2.ZERO,true)
        s.controlled=1;s.positions[1]=Vector2(s.pull_point(side).x,550)
        await shot(side+"-only-one-mouth")
        use(1,s.pull_point(side))
        await shot(side+"-whole-branch")
    print("M29_PUZZLE_RENDER: %d checks, 0 failures"%captures)
    view=null;host.free();host=null;call_deferred("quit",0)
