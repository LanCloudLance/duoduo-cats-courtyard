extends SceneTree
# Render fixtures only: normal-input traversal is covered in m27_five_playthrough.
var lobby
var c
var s
var failures:=0
func _initialize()->void:call_deferred("run")
func frame()->void:
    await process_frame
    await RenderingServer.frame_post_draw
func capture(label:String)->void:
    c._refresh(0.016)
    await frame();await frame()
    var args:=OS.get_cmdline_user_args()
    if args.is_empty():push_error("requires screenshot prefix");quit(1);return
    if root.get_texture().get_image().save_png(args[0]+"-"+label+".png")!=OK:failures+=1
func run()->void:
    print("M27_FIVE_QA_USERDIR: ",OS.get_user_data_dir())
    if OS.get_user_data_dir().get_file()!="DuoduoCatsCourtyard-qa-m27-five":push_error("wrong QA user directory");quit(1);return
    lobby=Control.new();lobby.theme=Theme.new()
    lobby.theme.default_font=load("res://assets/fonts/CourtyardSans.ttf");root.add_child(lobby)
    var session=load("res://input/session_state.gd").new();session.keyboard_mode=true
    c=load("res://game/story_chapter_view.gd").new(session);lobby.add_child(c)
    c.set_physics_process(false);c.reset(5,true,false);c.set_active(true);s=c.state
    await frame();await frame()
    # Isolated production View: explicit fixtures, no lobby or focus handling.
    s.phase="shield";s.bridge_locked=true;s.boss_clock=1.5
    s.positions.assign([Vector2(700,505),Vector2(800,580),Vector2(580,620)])
    s.facing[0]=Vector2(1,-1).normalized();s.guard(0,true)
    await capture("shield-warning")
    s.boss_clock=1.8;s.arm_arrest=5.5
    await capture("shield-contact")
    s.phase="lure";s.arm_locked=true;s.arm_arrest=0;s.clear_holds();s.stage_checkpoint=1
    s.positions.assign([Vector2(1070,540),Vector2(800,580),Vector2(580,350)])
    s.beam_held=true;s.beam_route=1;s.actions[2]="light";s.lid_pins=1;s.wheel_notch=1
    await capture("lower-pin")
    s.beam_route=2
    await capture("upper-route")
    s.phase="unjam";s.lid_open=true;s.lid_pins=2;s.fixed_light=true;s.stage_checkpoint=2;s.clear_holds()
    s.positions[1]=Vector2(875,550);s.positions[2]=Vector2(665,600)
    for index in range(3):
        s.cleared_segments=index;s.wheel_notch=[1,0,2][index];s.wheel_ready=true
        await capture("branch-"+str(index))
    s.wheel_notch=2;s.cleared_segments=1;s.recoil=.4
    await capture("wrong-clearance")
    s.cleared_segments=1;s.stroke_time=.3;s.hook_held=true;s.act(1,"paw",.3)
    await capture("active-hook")
    s.phase="test";s.machine_stopped=true;s.cleared_segments=3;s.stage_checkpoint=3;s.clear_holds()
    s.positions.assign([Vector2(1090,600),Vector2(875,620),Vector2(570,555)])
    s.beam_held=true;s.actions[2]="light";s.facing[2]=Vector2.RIGHT;s.plate_aligned=true;s.outward_light=true
    await capture("far-light")
    print("M27_FIVE_RENDER: 10 fixture screenshots, ",failures," errors; not normal input")
    lobby.queue_free();await process_frame;quit(1 if failures else 0)
