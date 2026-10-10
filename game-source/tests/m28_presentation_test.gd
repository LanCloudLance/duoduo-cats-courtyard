extends SceneTree
const Stage=preload("res://game/story_stage_art.gd")
var checks:=0
var failures:=0
var lobby:Control
var session
var chapter
func check(value:bool,label:String)->void:
    checks+=1
    if not value:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
    print("M28_PRESENTATION_USERDIR: ",OS.get_user_data_dir())
    if OS.get_user_data_dir().get_file()!="DuoduoCatsCourtyard-qa-m28-presentation":push_error("wrong QA userdir");quit(1);return
    lobby=Control.new();lobby.theme=Theme.new();lobby.theme.default_font=load("res://assets/fonts/CourtyardSans.ttf");root.add_child(lobby)
    session=load("res://input/session_state.gd").new();session.keyboard_mode=true;session.single_player=true;session.ready_flags.assign([true,false])
    chapter=load("res://game/story_chapter_view.gd").new(session);lobby.add_child(chapter);chapter.set_physics_process(false);chapter.audio.muted=true
    for number in [2,3,4,5]:
        chapter.reset(number,true,false);chapter.set_active(true)
        chapter._refresh(0.016)
        await process_frame
        check(chapter.actors[0].painted.has_method("pose") and chapter.actors[0].social_visual,"adventure actor uses social presentation")
        check(chapter.presentation_data.has("mechanisms"),"chapter mechanism contract")
        var s=chapter.state
        s.start_dialogue(["第一句","第二句"],{"role":0,"kind":"pet","participants":[0,1],"duration":2.0})
        chapter._refresh(0.016)
        check(chapter.dialogue_view.visible and chapter.dialogue_view.body.text=="第一句","critical dialogue is visible")
        check(chapter.actors[0].painted.social_sprite.visible,"pet art is displayed during confirmed dialogue")
        var before:Array=s.positions.duplicate();var clock:float=s.clock
        chapter._physics_process(0.25)
        check(s.positions==before and s.clock==clock,"dialogue freezes gameplay")
        chapter.handle_action(0,JOY_BUTTON_RIGHT_SHOULDER)
        check(s.dialogue_index==0,"tool cannot advance dialogue")
        chapter.handle_action(0,JOY_BUTTON_A)
        check(s.dialogue_index==1 and chapter.dialogue_view.body.text=="第二句","A confirms exactly one line")
        chapter.handle_action(0,JOY_BUTTON_A)
        check(not chapter.dialogue_view.visible,"dialogue closes after final confirmation")
        chapter.active=false;chapter.visible=false;chapter.hud.visible=false;chapter.dialogue_view.visible=false
    chapter.state.start_dialogue(["驿站","运输桥","钟楼","集市"],{"kind":"network","duration":0.1})
    chapter._refresh(0.016)
    check(chapter.memory_scene.visible and chapter.memory_scene.index==0,"world outcome starts at repaired waystation")
    chapter.handle_action(0,JOY_BUTTON_A)
    check(chapter.memory_scene.index==1,"world outcome waits for confirmation")
    chapter.state.dialogue.clear();chapter.memory_scene.visible=false
    for role in range(3):
        var h=load("res://game/home_sprite.gd").new();h.role=role;lobby.add_child(h)
        h.update_motion(Vector2(100,500),0)
        h.update_motion(Vector2(100,480),0.1)
        check(h.last_frame>=8 and h.sprite.texture.atlas.resource_path.contains("home-rear"),"upward walk uses true rear art")
        for frame in h.motion_frames:
            check(Rect2(Vector2.ZERO,frame.atlas.get_size()).encloses(frame.region),"home source region is within its atlas")
        h.place_home(Vector2(400,415),"sit",0.1)
        check(h.position.y>275 and h.position.y<415,"sit settles continuously onto original sofa")
        h.place_home(Vector2(400,415),"sit",1.0)
        check(h.position.is_equal_approx(Stage.home_pose_position(Vector2(400,415),role,"sit")),"seat ends on original sofa")
        h.free()
    chapter.reset(5,true,false);chapter.set_active(true);chapter.state.phase="home";chapter.state.journey_discoveries.assign(["prologue_ball","three_map"]);chapter._refresh(0)
    check(chapter.presentation_data.home_discoveries==["prologue_ball","three_map"],"home uses only actual journey discoveries")
    for script in ["prologue","chapter_one"]:
        var view=load("res://game/"+script+".gd").new(session);lobby.add_child(view);view.set_physics_process(false);view.audio.muted=true;view.reset(true,false);view.set_active(true)
        view.state.start_dialogue(["慢慢读完这一句","下一句"],{"role":0,"kind":"pet","participants":[0,1],"duration":2.0})
        if script=="prologue":view._physics_process(0.016)
        else:view._refresh(0.016)
        check(view.dialogue_view.visible,"early chapter dialogue connected")
        view.handle_action(0,JOY_BUTTON_A);check(view.state.dialogue_index==1,"early chapter input advances one line")
        view.active=false;view.free()
    print("M28_PRESENTATION: ",checks," checks, ",failures," failed; structural tests, not player acceptance")
    lobby.free();call_deferred("quit",1 if failures else 0)
