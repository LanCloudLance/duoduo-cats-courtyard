extends "res://tests/m31_mainline_playthrough_test.gd"
# A declared fresh chapter entry; all later movement/actions are ordinary
# InputEvents from five_route. These frames do not claim full mainline entry.
var capture_count:=0
var image_records:Array=[]
var motion_captures:Dictionary={}
class RenderSession extends "res://input/session_state.gd":
    # This fixed-focus render fixture is not an OS focus/resume acceptance test.
    # Native test windows share a desktop with the browser review and other QA.
    func set_focus(_value:bool)->void:
        focused=true
func go(role:int,target:Vector2)->bool:
    await select(role)
    var device:=9 if single or role==0 else 18
    for i in range(1300):
        var delta:Vector2=target-s.positions[role]
        if delta.length()<7:axes(device,Vector2.ZERO);return true
        axes(device,Vector2(0 if absf(delta.x)<3 else signf(delta.x),0 if absf(delta.y)<3 else signf(delta.y)));await frames(1)
        if role==1 and s.phase=="unjam" and target==s.RIGHT_PULL and i%8==0:
            var label:String="held-moving" if single else "support-moving"
            var count:int=motion_captures.get(label,0)
            if count<2:
                await save_image(label,count,true);motion_captures[label]=count+1
    axes(device,Vector2.ZERO);print("C5_INPUT_GO_STUCK phase=",s.phase," role=",role," to=",target," actual=",s.positions," controlled=",s.controlled," cat=",s.current_cat," running=",lobby.session.running()," focus=",lobby.session.focused," pause=",lobby.session.pause_reason," walkable=",s.walkable(s.positions[role]+Vector2(0,3),role));return false
func saved()->void:
    gate(s.finished and c.recorded,"fresh chapter's natural completion writes its isolated chapter record")
    gate(c.read_record().get("completed")==true,"fresh chapter record reads back after ordinary actions")
func gate(value:bool,label:String)->bool:
    if not value and s:
        print("C5_RENDER_FAIL_FACTS phase=",s.phase," positions=",s.positions," facing=",s.facing," actions=",s.actions," trace=",s.pilot_trace()," running=",lobby.session.running())
    return super.gate(value,label)
func touch(role:int)->void:
    await super.touch(role)
    # Full mainline uses time_scale=3; these rendered frames use real rate=1.
    # Wait for the actual 0.4s gesture cooldown before the next ordinary tap.
    await frames(20)
func run()->void:
    if OS.get_user_data_dir().get_file()!="DuoduoCatsCourtyard-qa-m31-puzzle":quit(2);return
    print("M31_C5_RENDER_BEGIN ",OS.get_user_data_dir())
    Engine.time_scale=1
    lobby=load("res://main.tscn").instantiate()
    lobby.session=RenderSession.new();lobby.router=lobby.Router.new(lobby.session)
    root.add_child(lobby);await frames(3)
    lobby.session.set_focus(true);lobby.story_progress.prefix="qa-m31-render"
    for mode in [true,false]:
        single=mode;lobby.session.pause_all("独立终章画面审查")
        lobby.start_story_chapter(5,single);await frames(4)
        c=lobby.story_chapter;c.record_prefix="qa-m31-render";c.reset(5,single,false);s=c.state;await frames(3)
        print("M31_C5_RENDER_ENTRY mode=",single," phase=",s.phase," running=",lobby.session.running())
        route=["prologue","one","two","three","four","five"]
        c.audio.muted=true
        await five_route()
        if failed:return
        gate(s.finished and s.extraction_method==("held" if single else "support"),"ordinary chapter route reaches home with exact chosen method")
    var file=FileAccess.open("res://../evidence/m31-c5-input-render.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"namespace":OS.get_user_data_dir(),"input_events":true,"fresh_chapter_entry":true,"fixed_focus_render_fixture":true,"images":image_records,"checks":checks,"failures":failed},"  "));file.close()
    await cleanup_mainline()
    print("M31_C5_INPUT_RENDER: %d checks, %d failures"%[checks,failed]);quit(1 if failed else 0)
func capture(label:String)->void:
    axes(9,Vector2.ZERO);axes(18,Vector2.ZERO)
    for frame in range(2):
        await frames(3)
        await save_image(label,frame,false)
func save_image(label:String,frame:int,moving:bool)->void:
    c._refresh(.016);c.queue_redraw();await process_frame
    RenderingServer.force_draw()
    var mode:String="solo" if single else "dual"
    var path:String="res://../evidence/m31-c5-input-"+mode+"-"+label+"-"+str(frame)+".png"
    if not gate(root.get_texture().get_image().save_png(path)==OK,"rendered InputEvent image saved "+label):return
    image_records.append({"file":ProjectSettings.globalize_path(path),"phase":s.phase,"positions":str(s.positions),"actions":s.actions.duplicate(),"movement_key_held":moving,"manual_ready":s.manual_load_ready(),"extraction_method":s.extraction_method,"trace":str(s.pilot_trace())})
    capture_count+=1
