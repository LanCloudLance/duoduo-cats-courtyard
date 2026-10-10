extends "res://tests/m27_four_render_preview.gd"
# Configuration fixtures for visual inspection only; not natural-play evidence.
func capture(label:String)->void:
    view._refresh(0.016)
    await process_frame
    RenderingServer.force_draw()
    var path:="res://n2-four-"+label+".png"
    print("N2_FOUR_FIXTURE ",path," status=",root.get_texture().get_image().save_png(path))
func run()->void:
    frame=Control.new();frame.theme=Theme.new();frame.theme.default_font=load("res://assets/fonts/CourtyardSans.ttf");root.add_child(frame)
    var session=Session.new();session.keyboard_mode=true
    view=View.new(session);frame.add_child(view);view.set_physics_process(false)
    s=Four.new();s.phase="investigate";s.cloth=true;s.cover_hooked=true;s.single=true
    view.state=s;view.set_active(true)
    s.positions.assign([Vector2(779,432),Vector2(708,316),Vector2(625,430)])
    s.facing[2]=Vector2.UP;use(2,s.DUCT_LIGHT)
    await capture("unseen")
    use(1,s.BRANCH);use(0,s.ARROWS);send();settled()
    await capture("isolated-only")
    use(0,s.ARROWS);send();settled()
    use(0,s.ARROWS);use(1,s.BRANCH);send();settled()
    await capture("three-compared")
    use(2,s.DUCT_LIGHT);s.clear_trial()
    await capture("light-off-memory")
    s.shell_fixed=true;s.latch_fixed=true;s.seam_seen=true;s.phase="test";s.route_split=false
    await capture("patched-before-retest")
    s.facing[2]=Vector2.UP;use(2,s.DUCT_LIGHT);send();settled()
    await capture("retested")
    use(0,s.ALIGHT);s.positions.assign([s.HOME+Vector2(-55,45),s.HOME+Vector2(35,30),s.HOME+Vector2(60,60)])
    await capture("safe-home-offer")
    use(0,s.HOME)
    await capture("choose-to-stay")
    frame.queue_free();await process_frame;quit()
