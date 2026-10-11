extends SceneTree
# Explicit chapter-entry fixture and actual rule interactions, not InputEvent play.
var host
var view
var captures:=0
func _init()->void:call_deferred("run")
func use(role:int,point:Vector2,tool:=false)->void:
    view.state.positions[role]=point;view.state.action_time[role]=0
    if tool:view.state.tool(role)
    else:view.state.interact(role)
func settle()->void:
    var s=view.state
    for i in range(240):
        if not s.social_transition_active():break
        s.step(.05,Vector2.ZERO,Vector2.ZERO,true)
    while s.dialogue_active():s.advance_dialogue()
func shot(label:String)->void:
    # Advance the actual view transition, rather than capturing its opaque cover.
    for i in range(75):
        view._refresh(.016);view.queue_redraw();await process_frame
    RenderingServer.force_draw()
    var args:=OS.get_cmdline_user_args()
    if args.is_empty() or root.get_texture().get_image().save_png(args[0]+"-"+label+".png")!=OK:quit(1);return
    captures+=1
func run()->void:
    if OS.get_user_data_dir().get_file()!="DuoduoCatsCourtyard-qa-m30-puzzle":quit(2);return
    host=Control.new();host.theme=Theme.new();host.theme.default_font=load("res://assets/fonts/CourtyardSans.ttf");root.add_child(host)
    var session=load("res://input/session_state.gd").new();session.keyboard_mode=true;session.single_player=true;session.ready_flags.assign([true,false])
    view=load("res://game/story_chapter_view.gd").new(session);host.add_child(view);view.set_physics_process(false)
    view.reset(4,true,false);view.set_active(true);view.audio.muted=true
    var s=view.state;var entry:Dictionary=s.checkpoint()
    entry.phase="investigate";entry.facts.cover_hooked=true;entry.facts.cloth=true
    entry.positions=[[565,480],[610,520],[650,550]]
    if not s.restore_checkpoint(entry):push_error("invalid declared C4 render entry");quit(3);return
    use(0,s.VIEW_DOOR);settle();use(0,s.PATCH)
    await shot("early-braced")
    use(1,s.LATCH);await shot("early-latched")
    s.facing[2]=Vector2(1,-1).normalized();use(2,s.SEAM_LIGHT);use(0,s.PATCH)
    await shot("early-sealed")
    use(0,s.VIEW_DOOR);settle();s.facing[2]=Vector2.UP;use(2,s.DUCT_LIGHT);use(0,s.ARROWS,true)
    for i in range(27):s.step(.05,Vector2.ZERO,Vector2.ZERO,true)
    await shot("repaired-main-return")
    use(0,s.VIEW_DOOR);settle();s.positions[0]=s.TREE_ENTRY-Vector2(55,0)
    await shot("tree-gate-blocked")
    use(0,s.TREE_ENTRY)
    if not s.battle_requested:push_error("render entry did not request gate encounter");quit(4);return
    # Declared callback fixture: battle's own actual-input evidence is separate.
    s.after_battle();await shot("tree-gate-cleared")
    print("M30_C4_RENDER: %d frames, 0 failures"%captures)
    view=null;host.free();host=null;call_deferred("quit",0)
