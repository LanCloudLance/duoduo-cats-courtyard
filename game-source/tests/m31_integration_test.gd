extends SceneTree
# State fixture for real interaction/music edges, not a whole-story or human run.
var checks:=0
var failed:=0
func check(ok:bool,label:String)->void:
    checks+=1
    if not ok:failed+=1;push_error("FAIL: "+label)
func _initialize()->void:run.call_deferred()
func use(s,role:int,at:Vector2)->void:
    s.positions[role]=at;s.action_time[role]=0;s.interact(role)
func run()->void:
    if OS.get_user_data_dir().get_file()!="DuoduoCatsCourtyard-qa-m31-root":quit(2);return
    var lobby=load("res://main.tscn").instantiate();root.add_child(lobby);await process_frame
    lobby.set_process(false);lobby.arena.set_physics_process(false)
    lobby.music.audible=false;lobby.music.set_process(false);lobby.session.set_focus(true)
    for solo in [true,false]:
        lobby.session.single_player=solo;lobby.router.start_keyboard()
        lobby.story_chapter.reset(5,solo,false);lobby.stage="story-chapter"
        var s=lobby.story_chapter.state
        for key in ["route_lock","route_supported","route_lit","bridge_locked","arm_locked","lid_open","lower_pin","upper_pin"]:s.set(key,true)
        s.lid_pins=2;s.stage_checkpoint=2;s.phase="unjam"
        s.positions.assign([s.WHEEL,s.PIN_RACK,s.CRADLE])
        lobby.update_journey_music(true);lobby.music.accent_cooldown=0
        var before:int=lobby.music.accent_serial
        use(s,1,s.ISOLATOR);use(s,2,s.CRADLE);use(s,0,s.WHEEL)
        check(s.load_held and s.fixed_light,"actual manual posts established")
        lobby.update_journey_music(true)
        check(lobby.music.accent_serial==before,"temporary holds and light cannot sound like extraction success")
        use(s,1,s.LEFT_PULL);lobby.update_journey_music(true)
        check(not s.machine_stopped and lobby.music.accent_serial==before,"wrong mouth neither extracts nor awards music")
        use(s,1,s.RIGHT_PULL)
        check(s.machine_stopped and s.get("extraction_method")=="held","real quick pull creates truthful held result")
        lobby.update_journey_music(true)
        check(lobby.music.accent_serial==before+1,"real whole-branch removal produces exactly one musical response")
        for i in range(60):lobby.update_journey_music(true)
        check(lobby.music.accent_serial==before+1,"unchanged branch fact cannot replay reward")
        var record:Dictionary=s.checkpoint()
        check(record.get("puzzle_revision")==3,"new causal extraction saved under revision three")
        lobby.story_chapter.reset(5,solo,false)
        var fresh=lobby.story_chapter.state
        check(fresh.restore_checkpoint(record),"current quick-result record restores")
        lobby.music.accent_cooldown=0;lobby.update_journey_music(true)
        check(lobby.music.accent_serial==before+1,"state replacement primes the old fact silently")
        check(fresh.get("extraction_method")=="held" and not fresh.load_held,"readback keeps method, clears temporary post")
        lobby.update_journey_music(false)
        check(lobby.music.paused,"pause contract survives new method")
    lobby.queue_free();await process_frame;await process_frame
    print("M31_INTEGRATION: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
