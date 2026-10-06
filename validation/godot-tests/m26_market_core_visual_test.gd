extends SceneTree
# Deterministic visual fixtures only: these are not normal-input playthrough evidence.
var lobby
var output_dir:String
func frames(n:int)->void:
    for i in range(n):await physics_frame;await process_frame
func _initialize()->void:call_deferred("run")
func capture(name:String)->void:
    lobby.session.set_focus(true);lobby.router.start_keyboard();lobby._process(.016)
    lobby.story_chapter.state.message="画面检查夹具 · "+name+"（非连续实玩）"
    lobby.story_chapter._refresh(.016)
    await frames(4);await RenderingServer.frame_post_draw
    var path:=output_dir+"/m26-fixture-"+name+".png"
    var result:int=root.get_texture().get_image().save_png(path)
    print("M26_VISUAL_FIXTURE ",path," status=",result)
    if result!=OK:quit(1)
func start(chapter:int)->void:
    lobby.session.pause_all();lobby.start_story_chapter(chapter,true);await frames(3)
func run()->void:
    output_dir=OS.get_cmdline_user_args()[0]
    lobby=load("res://main.tscn").instantiate();root.add_child(lobby);await frames(3)
    lobby.story_chapter.record_prefix="qa-m26-visual-"
    await start(4)
    await capture("c4-market")
    var s=lobby.story_chapter.state
    s.phase="home_offer";s.cloth=true;s.cover_hooked=true;s.duct_seen=true;s.branch_seen=true;s.arrows_seen=true
    s.latch_fixed=true;s.seam_seen=true;s.shell_fixed=true;s.inward_verified=true;s.lantern_offered=true
    s.positions.assign([Vector2(430,615),Vector2(385,630),Vector2(590,635)])
    await capture("c4-offer")
    s.phase="rest";s.reserve_retained=true;s.positions.assign([Vector2(750,610),Vector2(700,640),Vector2(900,645)])
    await capture("c4-rest")
    await start(5)
    await capture("c5-approach")
    s=lobby.story_chapter.state;s.bridge_locked=true;s.phase="shield";s.boss_clock=.9
    s.positions.assign([Vector2(680,535),Vector2(800,560),Vector2(580,580)])
    await capture("c5-shield")
    s.phase="unjam";s.arm_locked=true;s.stage_checkpoint=2;s.lid_open=true;s.fixed_light=true;s.wheel_held=true
    s.cleared_segments=1;s.positions.assign([Vector2(1070,530),Vector2(875,505),Vector2(665,635)])
    await capture("c5-repair")
    s.phase="release";s.machine_stopped=true;s.stage_checkpoint=3;s.tested=true;s.outward_light=true;s.wheel_held=false;s.fixed_light=false
    s.positions.assign([Vector2(755,585),Vector2(845,580),Vector2(570,585)])
    await capture("c5-release")
    s.phase="farewell";s.network_lit=true;s.farewell_gift=true;s.tag_inserted=true
    s.positions.assign([Vector2(845,515),Vector2(900,560),Vector2(790,555)])
    await capture("c5-farewell")
    s.phase="home";s.gear_stored=true;s.paws_clean=true
    s.positions.assign([Vector2(830,490),Vector2(915,535),Vector2(790,545)])
    await capture("c5-home")
    lobby.queue_free();await frames(3);quit()
