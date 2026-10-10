extends SceneTree
# Frozen fixtures for independent visual inspection. No input/performance claim.
const Three=preload("res://game/chapter_three_state.gd")
const View=preload("res://game/story_chapter_view.gd")
const Session=preload("res://input/session_state.gd")
var shell
var view
var s
func _initialize()->void:call_deferred("run")
func use(role:int,p:Vector2,tool:=false)->void:
    s.positions[role]=p;s.action_time[role]=0
    if tool:s.tool(role)
    else:s.interact(role)
func capture(label:String)->void:
    s.positions[0]=s.RIG;s.positions[1]=s.HIGH_RING
    s.clock=1.0;view._refresh(.016);await process_frame;RenderingServer.force_draw()
    var path:="res://three-transfer-fixture-"+label+".png"
    print("M27_THREE_TRANSFER_RENDER_FIXTURE ",path," status=",root.get_texture().get_image().save_png(path))
func run()->void:
    shell=Control.new();shell.theme=Theme.new();shell.theme.default_font=load("res://assets/fonts/CourtyardSans.ttf");root.add_child(shell)
    var session=Session.new();session.keyboard_mode=true
    view=View.new(session);shell.add_child(view);view.set_physics_process(false)
    s=Three.new();s.restore_complete();s.finished=false;s.phase="exit";s.exit_revealed=false;s.exit_low_latched=false;s.exit_high_latched=false
    s.source_level=0;s.rig_angle=1;s.high_mirror_angle=0;view.state=s;view.set_active(true)
    s.facing[2]=Vector2.RIGHT;use(2,s.SEARCH_STAND);await capture("low-wrong-mirror")
    use(0,s.RIG);await capture("low-front-locked")
    use(0,s.SEARCH_STAND);await capture("raised-source-off")
    use(2,s.SEARCH_STAND);await capture("high-backface-wrong-low-mirror")
    use(0,s.RIG);await capture("high-wrong-upper-mirror")
    use(1,s.HIGH_RING);await capture("two-front-locks")
    shell.queue_free();await process_frame;quit()
