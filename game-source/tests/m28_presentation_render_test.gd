extends SceneTree
# Isolated visual fixtures. Normal inputs and child/player acceptance are separate.
var lobby:Control
var session
var c
var failures:=0
var captures:=0
func _initialize()->void:call_deferred("run")
func _process(_dt:float)->bool:
    if is_instance_valid(c):c.queue_redraw()
    return false
func frame()->void:
    await process_frame
    await RenderingServer.frame_post_draw
func capture(label:String)->void:
    c._refresh(0.016)
    c._refresh(0.5)
    await process_frame
    RenderingServer.force_draw()
    var args:=OS.get_cmdline_user_args()
    if args.is_empty():push_error("requires screenshot prefix");quit(1);return
    var out:String=args[0]+"-"+label+".png"
    if root.get_texture().get_image().save_png(out)!=OK:failures+=1
    else:captures+=1;print("M28_RENDER: ",out)
func run()->void:
    print("M28_PRESENTATION_RENDER_USERDIR: ",OS.get_user_data_dir())
    if OS.get_user_data_dir().get_file()!="DuoduoCatsCourtyard-qa-m28-presentation":push_error("wrong QA user directory");quit(1);return
    lobby=Control.new();lobby.theme=Theme.new();lobby.theme.default_font=load("res://assets/fonts/CourtyardSans.ttf");root.add_child(lobby)
    session=load("res://input/session_state.gd").new();session.keyboard_mode=true;session.single_player=true;session.ready_flags.assign([true,false])
    c=load("res://game/story_chapter_view.gd").new(session);lobby.add_child(c);c.set_physics_process(false)
    c.reset(2,true,false);c.set_active(true)
    var s=c.state;s.locked_a=true;s.support_site="outer";s.outer_locked=false;s.positions.assign([Vector2(585,620),Vector2(680,620),Vector2(900,450)])
    await capture("c2-outer-temporary")
    s.outer_locked=true;s.cart_open=true
    await capture("c2-outer-cart")
    c.reset(3,true,false);s=c.state;s.rig_ready=true;s.source_level=1;s.rig_angle=0;s.map_discovered=true
    s.start_dialogue(["圆圆把脸送进朵朵手里。团团把前爪搭过来。三位又在一起了。"],{"role":0,"kind":"pet","participants":[0,1,2],"duration":3.0})
    s.joined=true;s.positions.assign([Vector2(610,550),Vector2(675,550),Vector2(680,495)])
    await capture("c3-reunion")
    c.reset(4,true,false);s=c.state;s.positions.assign([Vector2(340,450),Vector2(465,440),Vector2(420,500)])
    await capture("c4-market")
    s.phase="test";s.reserve_available=true;s.lamp_dest="stall";s.stall_seen=true;s.message_time=0
    await capture("c4-interior")
    s.phase="exterior";s.patch_braced=true;s.latch_fixed=true;s.shell_fixed=true;s.lamp_dest="view";s.view_seen=true;s.positions.assign([Vector2(995,380),Vector2(1060,430),Vector2(945,480)])
    await capture("c4-exterior")
    c.reset(5,true,false);s=c.state;s.phase="shield";s.far_walkway=true;s.arm_route=1;s.positions.assign([Vector2(650,255),Vector2(725,330),Vector2(560,420)])
    await capture("c5-far-slot")
    s.phase="unjam";s.lid_open=true;s.arm_locked=true;s.arm_route=1;s.fixed_light=true;s.load_held=true;s.support_site="left";s.left_released=true;s.positions.assign([Vector2(1070,495),Vector2(815,570),Vector2(665,600)])
    await capture("c5-shared-support")
    s.phase="test";s.machine_stopped=true;s.plate_aligned=true;s.outward_light=true;s.beam_held=true;s.pilot_charged=true
    await capture("c5-outward-test")
    s.phase="network";s.network_lit=true
    s.start_dialogue(["驿站","运输桥","钟楼","集市"],{"kind":"network","participants":[],"duration":0.1})
    for i in range(4):
        await capture("network-"+str(i))
        s.advance_dialogue()
    s.phase="home";s.gear_stored=true;s.farewell_gift=true;s.cat_one_clean=true;s.cat_two_clean=true;s.journey_discoveries.assign(["prologue_ball","one_nightlight","two_cart","three_map","four_stall","four_view"])
    s.positions.assign([Vector2(388,433),Vector2(450,457),Vector2(340,455)])
    s.start_dialogue(["朵朵坐回原来的沙发。团团挨着膝盖，圆圆团在另一边。"],{"role":0,"kind":"sit","participants":[0,1,2],"duration":120.0})
    for i in range(36):c._refresh(1.0/60.0)
    await capture("home-keepsakes-sofa")
    s.advance_dialogue();s.phase="complete";s.finished=true;s.message_time=0
    await capture("home-complete")
    print("M28_PRESENTATION_RENDER: ",captures," screenshots, ",failures," file errors; fixtures only")
    lobby.free();call_deferred("quit",1 if failures else 0)
