extends SceneTree
var lobby
func frames(n:int)->void:
    for i in range(n):await physics_frame;await process_frame
func _initialize()->void:call_deferred("run")
func capture(name:String)->void:
    lobby.session.set_focus(true);lobby.router.start_keyboard();lobby._process(.016);lobby.story_chapter._refresh(.016)
    await frames(8);await RenderingServer.frame_post_draw
    var path:String=OS.get_cmdline_user_args()[0]+"/m25-"+name+".png"
    print("M25_RENDER ",path," status=",root.get_texture().get_image().save_png(path))
func run()->void:
    lobby=load("res://main.tscn").instantiate();root.add_child(lobby);await frames(3);lobby.session.set_focus(true)
    for c in range(2,6):
        lobby.session.pause_all();lobby.start_story_chapter(c,true);await frames(3)
        await capture("chapter-"+str(c))
    # Explicit frozen graphical fixtures, never continuous-input evidence.
    var s=lobby.story_chapter.state;s.bridge_locked=true;s.phase="shield";s.positions.assign([Vector2(680,520),Vector2(800,560),Vector2(585,540)]);s.boss_clock=.9
    await capture("machine-warning")
    s.restore_complete();await capture("home")
    lobby.queue_free();await frames(3);quit()
