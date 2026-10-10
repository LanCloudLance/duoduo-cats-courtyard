extends SceneTree
# Frozen fixtures only, for independent visual inspection; no player/input claim.
const Two=preload("res://game/chapter_two_state.gd")
const View=preload("res://game/story_chapter_view.gd")
const Session=preload("res://input/session_state.gd")
var shell
var view
var s
func _initialize()->void:call_deferred("run")
func use(role:int,p:Vector2)->void:s.positions[role]=p;s.action_time[role]=0;s.interact(role)
func capture(label:String)->void:
    s.clock=1.0;view._refresh(.016);await process_frame;RenderingServer.force_draw()
    var path:="res://two-handoff-fixture-"+label+".png"
    print("M27_TWO_HANDOFF_RENDER_FIXTURE ",path," status=",root.get_texture().get_image().save_png(path))
func run()->void:
    shell=Control.new();shell.theme=Theme.new();shell.theme.default_font=load("res://assets/fonts/CourtyardSans.ttf");root.add_child(shell)
    var session=Session.new();session.keyboard_mode=true
    view=View.new(session);shell.add_child(view);view.set_physics_process(false)
    s=Two.new();s.locked_a=true;s.lifted_a=true;s.lamp_a=1;s.reverse_seen=true;s.support_site="b";s.lifted_b=true;s.rear_loaded_seen=true;s.lamp_b=2
    s.positions[0]=s.BRACE_B;s.positions[1]=s.WINCH_B;view.state=s;view.set_active(true)
    await capture("prop-bears-load")
    use(0,s.BRACE_B);await capture("girl-bears-load-prop-loose")
    use(1,s.WINCH_B);s.positions[1]=Vector2(685,555);await capture("cat-carries-unique-prop")
    s.guard(0,false);await capture("canceled-safe-platform")
    use(0,s.BRACE_B);use(1,s.LATCH_B);await capture("far-lock-bears-load")
    shell.queue_free();await process_frame;quit()
