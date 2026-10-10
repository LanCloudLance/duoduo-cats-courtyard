extends SceneTree
# Motion evidence is a scene/state fixture; root performs separate normal inputs.
var lobby:Control
var session
var c
var captures:=0
func _initialize()->void:call_deferred("run")
func _process(_dt:float)->bool:
    if is_instance_valid(c):c.queue_redraw()
    return false
func capture(label:String)->void:
    await process_frame;RenderingServer.force_draw()
    var args:=OS.get_cmdline_user_args()
    if args.is_empty():push_error("requires screenshot prefix");quit(1);return
    root.get_texture().get_image().save_png(args[0]+"-"+label+".png");captures+=1
func frames(label:String,count:int)->void:
    for index in range(count):
        c.state.step(1.0/60,Vector2.ZERO,Vector2.ZERO,true);c._refresh(1.0/60)
        if index in [0,8,20,36,59,89]:await capture(label+"-"+str(index))
func run()->void:
    print("M28_SOCIAL_RENDER_USERDIR: ",OS.get_user_data_dir())
    if OS.get_user_data_dir().get_file()!="DuoduoCatsCourtyard-qa-m28-presentation":push_error("wrong QA user directory");quit(1);return
    lobby=Control.new();lobby.theme=Theme.new();lobby.theme.default_font=load("res://assets/fonts/CourtyardSans.ttf");root.add_child(lobby)
    session=load("res://input/session_state.gd").new();session.keyboard_mode=true;session.single_player=true;session.ready_flags.assign([true,false])
    c=load("res://game/story_chapter_view.gd").new(session);lobby.add_child(c);c.set_physics_process(false);c.audio.muted=true
    c.reset(4,true,false);c.set_active(true);var s=c.state;s.phase="investigate";s.reserve_available=true;s.positions.assign([Vector2(420,410),Vector2(465,480),Vector2(490,470)])
    c._refresh(.016);s.interact(0);await frames("market-door",90)
    c.reset(5,true,false);s=c.state;s.phase="home";s.gear_stored=true;s.paws_clean=true;s.cat_one_clean=true;s.cat_two_clean=true
    s.positions.assign([Vector2(400,435),Vector2(515,495),Vector2(305,495)]);c._refresh(.016);s.interact(0);await frames("same-sofa",90)
    c.reset(5,true,false);s=c.state;s.phase="home";s.gear_stored=true
    s.positions.assign([Vector2(605,530),Vector2(490,585),Vector2(790,565)]);c._refresh(.016);s.interact(0);await frames("cat-care",90)
    print("M28_SOCIAL_RENDER: ",captures," frames, scene fixture only")
    lobby.free();call_deferred("quit",0)
