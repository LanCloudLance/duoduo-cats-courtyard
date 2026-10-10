extends SceneTree
var lobby
func _initialize()->void:call_deferred("run")
func capture(path:String)->void:
    lobby.session.set_focus(true)
    lobby.router.start_keyboard()
    lobby._process(0.016)
    lobby.chapter_one._refresh(0.016)
    for i in range(8):await process_frame
    await RenderingServer.frame_post_draw
    var result:=root.get_texture().get_image().save_png(path)
    print("M24_RENDER ",path," status=",result)
func run()->void:
    if DisplayServer.get_name()=="headless":quit(1);return
    root.size=Vector2i(1280,800)
    lobby=load("res://main.tscn").instantiate();root.add_child(lobby)
    for i in range(3):await process_frame
    lobby.session.set_focus(true);lobby.start_chapter_one(true)
    var c=lobby.chapter_one
    c.record_prefix="qa-render-chapter"
    c.reset(true,false)
    c.state.phase="road";c.state.equipment=true;c.state.positions[0]=Vector2(510,445);c.state.positions[1]=Vector2(435,565)
    c._refresh(0.016)
    await capture("/Users/wangyuanlong/Documents/Codex/2026-09-05/ya/work/qa/m24-road.png")
    c.state.enter_station();c.state.core_installed=true;c.state.core_ready=true;c.state.core_found=true;c.state.hood=3;c.state.vent=1
    c.state.positions[0]=Vector2(980,455);c.state.positions[1]=Vector2(755,490)
    c._refresh(0.016)
    await capture("/Users/wangyuanlong/Documents/Codex/2026-09-05/ya/work/qa/m24-station.png")
    c.state.hood=1;c.state.vent=1
    for i in range(150):c.state.step(1.0/60,Vector2.ZERO,Vector2.ZERO,true)
    c._refresh(0.016)
    await capture("/Users/wangyuanlong/Documents/Codex/2026-09-05/ya/work/qa/m24-station-lit.png")
    quit()
