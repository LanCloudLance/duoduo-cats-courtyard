extends SceneTree
# Frozen graphical fixtures, not OS-input or playthrough evidence.
const Four=preload("res://game/chapter_four_state.gd")
const View=preload("res://game/story_chapter_view.gd")
const Session=preload("res://input/session_state.gd")
var frame
var view
var s
func _initialize()->void:call_deferred("run")
func settled()->void:
    for i in range(30):s.step(0.05,Vector2.ZERO,Vector2.ZERO,true)
func use(role:int,p:Vector2)->void:
    s.positions[role]=p;s.action_time[role]=0;s.interact(role)
func send()->void:
    s.positions[0]=s.ARROWS;s.action_time[0]=0;s.tool(0)
func capture(label:String)->void:
    view._refresh(0.016)
    await process_frame
    RenderingServer.force_draw()
    var path:="res://four-fixture-"+label+".png"
    print("M27_FOUR_RENDER_FIXTURE ",path," status=",root.get_texture().get_image().save_png(path))
func run()->void:
    frame=Control.new();frame.theme=Theme.new();frame.theme.default_font=load("res://assets/fonts/CourtyardSans.ttf");root.add_child(frame)
    var session=Session.new();session.keyboard_mode=true
    view=View.new(session);frame.add_child(view);view.set_physics_process(false)
    s=Four.new();s.phase="investigate";s.cloth=true;s.single=true
    view.state=s;view.set_active(true)
    s.positions[2]=s.DUCT_LIGHT;s.facing[2]=Vector2.UP;use(2,s.DUCT_LIGHT)
    s.positions[1]=s.BRANCH+Vector2(-14,22)
    send();s.step(0.05,Vector2.ZERO,Vector2.ZERO,true)
    for i in range(4):s.step(0.05,Vector2.ZERO,Vector2.ZERO,true)
    await capture("outbound-pulse")
    settled();await capture("main-return-and-leak")
    use(0,s.ARROWS);send();settled();await capture("connected-split-empty")
    use(1,s.BRANCH);send();settled();await capture("isolated-reserve-held")
    use(1,s.BRANCH);await capture("reconnected-return")
    s.shell_fixed=true;s.phase="test";s.route_split=false
    send();settled();await capture("repaired-no-leak")
    frame.queue_free();await process_frame;quit()
