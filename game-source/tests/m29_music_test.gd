extends SceneTree
var checks:=0
var failed:=0
func check(ok:bool,label:String)->void:
    checks+=1
    if not ok:failed+=1;push_error("FAIL: "+label)
func _initialize()->void:run.call_deferred()
func run()->void:
    print("QA_USERDIR="+OS.get_user_data_dir())
    check(OS.get_user_data_dir().contains("DuoduoCatsCourtyard-qa-m29-music"),"music QA uses isolated actual OS namespace")
    var music=load("res://game/music_director.gd").new()
    music.audible=false
    root.add_child(music);await process_frame
    music.set_process(false)
    check(music.has_method("set_scene") and music.has_method("accent"),"story events can request musical scene and accent")
    if not music.has_method("set_scene"):music.queue_free();await process_frame;finish();return
    music.set_scene("explore")
    music.advance(.9)
    var voice:int=music.current_voice
    var clock:float=music.track_clock
    music.set_scene("explore")
    check(music.current_voice==voice and music.track_clock==clock,"repeated same scene preserves musical phrase")
    music.set_scene("chapter3","reflect")
    check(music.context=="explore","normal chapter change waits for next measure")
    music.advance(music.seconds_per_bar("explore")+.05)
    check(music.context=="chapter3" and music.mood=="reflect","measure boundary commits chapter and reflective arrangement")
    music.advance(1.0)
    check(music.melody_voices[music.current_voice].volume_db<=-70,"reflect leaves actual melody voice silent, not merely quieter whole mix")
    check(music.voices[music.current_voice].volume_db>-70,"reflect retains sparse accompaniment")
    music.set_scene("battle","pressure")
    check(music.context=="battle","combat responds immediately without waiting old measure")
    music.advance(1.0)
    check(music.pressure_voices[music.current_voice].volume_db>-70,"pressure adds a synchronized musical part")
    check(music.pressure_voices[music.current_voice].stream.get_length()==music.voices[music.current_voice].stream.get_length(),"battle stems have same complete loop length")
    music.set_scene("battle","flow");music.advance(music.seconds_per_bar("battle")+1)
    check(music.pressure_voices[music.current_voice].volume_db<=-70,"flow withdraws added pressure part")
    var battle_clock:float=music.track_clock
    music.set_scene("rest","resolved")
    check(music.context=="rest","clear responds immediately")
    music.advance(1)
    music.set_scene("battle","pressure")
    check(absf(music.track_clock-battle_clock)<.02,"return to score restores saved phrase position")
    music.advance(1)
    var before_accent:float=music.voices[music.current_voice].volume_db
    music.accent("discovery")
    check(music.voices[music.current_voice].volume_db<before_accent-4.5,"event cadence makes harmonic room in underlying score")
    var serial:int=music.accent_serial
    music.accent("discovery")
    check(music.accent_serial==serial,"repeated event cannot spam musical accent")
    music.accent("missing")
    check(music.accent_serial==serial,"unknown event does not replace accent")
    music.set_muted(true)
    music.accent("resolved")
    music.advance(.2)
    check(music.all_players().all(func(v):return v.volume_db<=-70),"mute covers accompaniment melody pressure and accent")
    music.set_muted(false);music.level=.12;music.advance(1)
    var quiet:float=music.voices[music.current_voice].volume_db
    var quiet_accent:float=music.accent_voice.volume_db
    music.level=.28;music.advance(.1)
    check(music.voices[music.current_voice].volume_db>quiet+6 and music.accent_voice.volume_db>quiet_accent+6,"level setting controls all musical voices")
    music.set_paused(true)
    clock=music.track_clock
    music.advance(4)
    check(music.track_clock==clock and music.all_players().all(func(v):return not v.playing or v.stream_paused),"pause freezes every active stem and accent")
    music.set_paused(false);music.advance(.1)
    check(music.track_clock>clock and music.all_players().all(func(v):return not v.stream_paused),"resume restores all music clocks")
    music.set_scene("chapter4","reflect")
    music.set_scene("battle","pressure")
    music.advance(4)
    check(music.context=="battle","return to current request cancels stale queued chapter change")
    for profile in ["home","explore","chapter2","chapter3","chapter4","chapter5","battle","boss","rest"]:
        music.set_context("home")
        music.set_scene(profile,"flow");music.advance(5)
        check(music.context!="" and music.tracks.has(music.context),"valid score for "+profile)
    for phase in ["briefing","intermission","failed","clear","complete"]:
        check(music.context_for("combat",phase,3)=="rest","legacy noncombat phase stays restful: "+phase)
    music.set_paused(true);music.set_muted(true)
    music.set_scene("chapter5","pressure");music.set_scene("boss","pressure");music.set_scene("rest","resolved")
    clock=music.track_clock;music.advance(5)
    check(music.context=="rest" and music.track_clock==clock,"rapid changes during pause keep final restful scene frozen")
    check(music.all_players().all(func(v):return v.volume_db<=-70),"rapid paused transitions never leak muted stems")
    music.set_paused(false);music.set_muted(false);music.advance(1)
    for i in range(music.voices.size()):
        if i!=music.current_voice:check(not music.voices[i].playing and not music.pressure_voices[i].playing,"rapid crossfade releases every discarded bank")
    music.queue_free();await process_frame
    # Real decoders, separate from deterministic scheduling fixtures above.
    var live=load("res://game/music_director.gd").new()
    root.add_child(live);await process_frame
    live.set_scene("battle","pressure")
    await create_timer(.2).timeout
    var pos:float=live.voices[live.current_voice].get_playback_position()
    check(absf(pos-live.melody_voices[live.current_voice].get_playback_position())<.035 and absf(pos-live.pressure_voices[live.current_voice].get_playback_position())<.035,"real decoder playback aligns all battle parts")
    check(absf(live.track_clock-live._decoder_position())<.05,"audible score clock follows decoder rather than visual frame accumulation")
    OS.delay_msec(120)
    await process_frame
    await process_frame
    check(absf(live.track_clock-live._decoder_position())<.05,"visual stall does not drift the audible musical clock")
    var departing:int=live.current_voice
    live.set_scene("rest","resolved")
    await create_timer(.1).timeout
    var returning:float=live.voices[departing].get_playback_position()+AudioServer.get_time_since_last_mix()
    live.set_scene("battle","pressure")
    check(absf(live.track_clock-returning)<.06,"return during a fade continues the still-audible decoder")
    live.set_paused(true)
    var frozen:float=live.voices[live.current_voice].get_playback_position()
    await create_timer(.12).timeout
    check(absf(live.voices[live.current_voice].get_playback_position()-frozen)<.035,"real decoder stops under pause")
    live.queue_free();await process_frame
    var deadline:int=Time.get_ticks_msec()+300
    while Time.get_ticks_msec()<deadline:await process_frame
    finish()
func finish()->void:
    print("M29_MUSIC: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
