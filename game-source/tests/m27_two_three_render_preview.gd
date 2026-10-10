extends SceneTree
# Frozen graphical fixtures only: not native/OS-input playthrough evidence.
const Two=preload("res://game/chapter_two_state.gd")
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
    s.clock=1.0;view._refresh(.016);await process_frame;RenderingServer.force_draw()
    var path:="res://two-three-fixture-"+label+".png"
    print("M27_TWO_THREE_RENDER_FIXTURE ",path," status=",root.get_texture().get_image().save_png(path))
func run()->void:
    shell=Control.new();shell.theme=Theme.new();shell.theme.default_font=load("res://assets/fonts/CourtyardSans.ttf");root.add_child(shell)
    var session=Session.new();session.keyboard_mode=true
    view=View.new(session);shell.add_child(view);view.set_physics_process(false)
    s=Two.new();view.state=s;view.set_active(true)
    use(0,s.WINCH_A);use(0,s.LAMP_A);await capture("support-loaded")
    use(1,s.LATCH_A);use(0,s.WINCH_A,true);await capture("support-recovered")
    s.positions[0]=s.WINCH_B;use(1,s.WINCH_B);use(1,s.WINCH_B);use(0,s.WINCH_B);await capture("support-reused")
    s=Three.new();view.state=s;s.joined=true;s.wick_found=true;s.wick_ready=true;s.wick_fitted=true;s.door_angle=1;s.npc_called=true;s.door_open=true;s.light_equipped=true;s.phase="walkway"
    s.positions[0]=s.BOARD;s.positions[1]=s.LOCK;s.positions[2]=s.LIGHT_STAND;s.facing[2]=Vector2.RIGHT
    use(2,s.LIGHT_STAND);use(1,s.LOCK);use(0,s.BOARD);await capture("direct-path")
    use(0,s.BOARD);use(0,s.BOARD);use(0,s.BOARD)
    use(2,s.LIGHT_STAND,true);s.facing[2]=Vector2.UP;use(2,s.LIGHT_STAND)
    await capture("mirror-miss")
    use(0,s.BOARD);await capture("mirror-connected")
    use(2,s.LIGHT_STAND,true);s.narrow_open=true;use(0,s.RIG)
    s.facing[2]=Vector2.UP;use(2,s.SEARCH_STAND)
    s.positions[0]=s.RIG+Vector2(-45,20);s.positions[2]=s.SEARCH_STAND+Vector2(-25,10)
    await capture("exit-mirror-miss")
    use(2,s.SEARCH_STAND,true);s.facing[2]=Vector2.RIGHT;use(2,s.SEARCH_STAND)
    use(0,s.SEARCH_STAND);use(2,s.SEARCH_STAND);use(0,s.RIG);use(1,s.HIGH_RING)
    s.positions[0]=s.RIG+Vector2(-45,20);await capture("exit-mirror-connected")
    shell.queue_free();await process_frame;quit()
