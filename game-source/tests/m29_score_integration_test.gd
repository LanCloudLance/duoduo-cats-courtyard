extends SceneTree
var checks:=0
var failed:=0
func check(value:bool,label:String)->void:
    checks+=1
    if not value:failed+=1;push_error("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
    var lobby=load("res://main.tscn").instantiate();root.add_child(lobby)
    await process_frame
    lobby.set_process(false)
    if not lobby.has_method("update_journey_music"):
        check(false,"lobby routes actual chapter and encounter states through music policy")
    else:
        lobby.session.set_focus(true)
        lobby.story_chapter.reset(4,true,false);lobby.stage="story-combat"
        lobby.arena.battle.story_encounter="reserve"
        lobby.arena.battle.phase="combat"
        lobby.update_journey_music(true)
        check(lobby.music.scene_profile=="boss" and lobby.music.mood=="pressure","actual combat routes identity and pressure")
        lobby.arena.battle.phase="clear";lobby.update_journey_music(true)
        check(lobby.music.scene_profile=="rest" and lobby.music.mood=="resolved","clear routes a resolved score")
        lobby.arena.battle.phase="complete";lobby.update_journey_music(true)
        check(lobby.music.scene_profile=="rest","exit cannot return to combat score")
        lobby.stage="story-chapter";lobby.story_chapter.state.phase="investigate"
        lobby.update_journey_music(true);lobby.music.advance(4.0)
        check(lobby.music.scene_profile=="chapter4" and lobby.music.mood=="reflect","actual investigation gets chapter theme with space")
        lobby.update_journey_music(false)
        check(lobby.music.paused,"pause freezes all score time before observing any new events")
        lobby.session.set_focus(false);lobby.update_journey_music(true)
        check(lobby.music.paused,"focus loss mutes score transport even when caller says playing")
        lobby.session.set_focus(true);lobby.music.set_muted(true);lobby.update_journey_music(true)
        check(lobby.music.muted,"state updates preserve user's music-off setting")
    lobby.queue_free();await process_frame;await process_frame
    print("M29_SCORE_INTEGRATION: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
