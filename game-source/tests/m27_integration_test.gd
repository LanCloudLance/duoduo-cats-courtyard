extends "res://tests/keyboard_scene_test.gd"
func run()->void:
    lobby=load("res://main.tscn").instantiate();root.add_child(lobby);await frames(3);lobby.session.set_focus(true)
    check(lobby.has_method("start_story_chapter"),"remaining story chapters have real independent entries")
    if not lobby.has_method("start_story_chapter"):
        print("M27_INTEGRATION: %d checks, %d failed"%[checks,failed]);quit(1);return
    for chapter in range(2,6):
        for single in [true,false]:
            lobby.session.pause_all();lobby.story_chapter.record_prefix="qa-m27-entry-"+str(Time.get_ticks_usec())
            lobby.start_story_chapter(chapter,single);await frames(3)
            var v=lobby.story_chapter;var s=v.state
            check(lobby.stage=="story-chapter" and v.visible,"chapter entry owns active view")
            check(not lobby.chapter_one.visible and not lobby.prologue.visible and not lobby.arena.visible,"previous scene does not overlap new chapter")
            check(s.chapter==chapter and s.single==single,"selected mode and chapter reach simulation")
            var party:Array=s.available_roles()
            check(party==[0,1] if chapter<=3 else party==[0,1,2],"roster follows reunion chronology")
            for i in range(4):tap_key(KEY_TAB);await frames(1)
            check(s.actor_for_slot(0 if single else 1) in party,"switching cannot control absent actor")
            tap_key(KEY_ESCAPE);await frames(2)
            var p=s.positions.duplicate();var clock:float=s.clock
            await frames(8);check(s.positions==p and s.clock==clock and not v.visible,"pause freezes complete chapter world")
            tap_key(KEY_ENTER);await frames(2);check(v.visible,"normal keyboard resumes chapter")
            var record_before=v.read_record();check(record_before.get("version")==2 and record_before.get("completed")==false,"paused unfinished chapter reads as progress without forging completion")
    # Explicit music-context fixtures, separate from normal-input completion.
    lobby.session.pause_all();lobby.start_story_chapter(5,true);await frames(3)
    for phase in ["shield","lure","unjam","withdraw"]:
        lobby.story_chapter.state.phase=phase;lobby._process(.016)
        check(lobby.music.context=="boss","every live repair stage retains boss music")
    lobby.story_chapter.state.phase="home";lobby._process(.016)
    check(lobby.music.context=="home","playable home epilogue changes back to home music")
    lobby.session.pause_all();lobby.start_chapter_one(true);await frames(3)
    var one=lobby.chapter_one
    one.recorded=true;one.state.finished=true;one.state.phase="complete"
    tap_key(KEY_E);await frames(3)
    check(lobby.stage=="story-chapter" and lobby.story_chapter.state.chapter==2,"completed first chapter advances using real interaction")
    lobby.queue_free();await frames(4)
    print("M27_INTEGRATION: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
