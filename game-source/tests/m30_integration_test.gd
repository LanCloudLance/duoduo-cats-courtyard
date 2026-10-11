extends SceneTree
var checks:=0
var failed:=0
func check(ok:bool,label:String)->void:
    checks+=1
    if not ok:failed+=1;push_error("FAIL: "+label)
func _initialize()->void:run.call_deferred()
func run()->void:
    if OS.get_user_data_dir().get_file()!="DuoduoCatsCourtyard-qa-m30-root":push_error("wrong QA namespace");quit(1);return
    var lobby=load("res://main.tscn").instantiate();root.add_child(lobby);await process_frame
    lobby.set_process(false);lobby.arena.set_physics_process(false)
    lobby.music.audible=false;lobby.music.set_process(false)
    lobby.session.set_focus(true);lobby.session.single_player=true;lobby.router.start_keyboard()
    lobby.story_route_active=false
    for encounter in ["shell","reserve"]:
        lobby.story_chapter.reset(4,true,false)
        var s=lobby.story_chapter.state
        s.phase="battle_one" if encounter=="shell" else "battle_two"
        s.reserve_retained=encounter=="reserve";s.battle_requested=true
        lobby.stage="story-chapter";lobby.enter_story_combat()
        check(lobby.stage=="story-combat","real chapter entry reaches arena: "+encounter)
        check(lobby.arena.battle.context.get("encounter_revision")==2,"real C4 entry selects new goal rules: "+encounter)
        var b=lobby.arena.battle
        b.phase="combat";lobby.update_journey_music(true)
        check(lobby.music.mood=="pressure","active route obstacle creates musical pressure: "+encounter)
        b.phase="clear";lobby.update_journey_music(true)
        check(lobby.music.scene_profile=="rest" and lobby.music.mood=="resolved","opened path resolves before exit: "+encounter)
        b.phase="complete";lobby.update_journey_music(true)
        check(lobby.music.context=="rest","completed route cannot restart battle score: "+encounter)
    lobby.story_chapter.reset(4,true,false);lobby.stage="story-chapter"
    var s=lobby.story_chapter.state;s.phase="investigate";s.visit_room="exterior"
    lobby.update_journey_music(true);lobby.music.accent_cooldown=0
    var serial:int=lobby.music.accent_serial
    s.shell_fixed=true;lobby.update_journey_music(true)
    check(lobby.music.accent_serial==serial+1,"early physical repair now earns a real once-only score response")
    for n in range(60):lobby.update_journey_music(true)
    check(lobby.music.accent_serial==serial+1,"holding/revisiting repair never repeats its musical success")
    lobby.story_chapter.reset(4,true,false);lobby.story_chapter.state.shell_fixed=true
    lobby.music.accent_cooldown=0;lobby.update_journey_music(true)
    check(lobby.music.accent_serial==serial+1,"loading an already repaired shell cannot replay success")
    lobby.update_journey_music(false)
    check(lobby.music.paused,"chapter changes preserve pause contract")
    lobby.queue_free();await process_frame;await process_frame
    print("M30_INTEGRATION: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
