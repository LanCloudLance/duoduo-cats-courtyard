extends SceneTree
var checks := 0
var failed := 0
func check(value: bool, label: String) -> void:
    checks += 1
    if not value:
        failed += 1
        push_error("FAIL: "+label)
func _initialize() -> void:
    run.call_deferred()
func run() -> void:
    check(ResourceLoader.exists("res://game/music_director.gd"),"continuous original scene music exists beyond short feedback cues")
    if failed: finish(); return
    var music = load("res://game/music_director.gd").new()
    root.add_child(music)
    await process_frame
    check(music.voices.all(func(v): return v.playback_type == AudioServer.PLAYBACK_TYPE_STREAM),"long music uses streaming playback rather than duplicated browser samples")
    check(music.context_for("combat","combat",1) == "battle","active encounter selects rhythmic score")
    check(music.context_for("combat","combat",3) == "boss","final encounter changes the arrangement")
    check(music.context_for("combat","clear",3) == "rest","cleared battle drops pressure without waiting for a new scene")
    check(music.context_for("combat","intermission",1) == "battle","short intermission keeps the ongoing battle phrase")
    check(music.context_for("light") == "puzzle" and music.context_for("gate") == "puzzle","linked puzzle scenes preserve their musical identity")
    music.set_context("explore")
    await create_timer(0.06).timeout
    music.advance(1.0)
    var voice: int = music.current_voice
    var stream = music.voices[voice].stream
    music.set_context("explore")
    check(music.current_voice == voice and music.voices[voice].stream == stream and music.track_clock > 0.9,"repeated scene refresh cannot restart its song")
    music.set_context("battle")
    await create_timer(0.06).timeout
    check(music.current_voice != voice and music.voices[voice].playing,"scene change crossfades instead of cutting the old arrangement")
    music.advance(1.0)
    check(not music.voices[voice].playing,"completed crossfade releases the previous voice")
    check(music.has_method("duck"),"impact cues can briefly make space in the score")
    if music.has_method("duck"):
        var volume: float = music.voices[music.current_voice].volume_db
        music.duck(0.18)
        music.advance(0.01)
        check(music.voices[music.current_voice].volume_db < volume-4,"music yields to contact feedback")
        music.advance(0.4)
        check(is_equal_approx(music.voices[music.current_voice].volume_db,volume),"contact dip recovers without restarting music")
    var clock: float = music.track_clock
    music.set_paused(true)
    music.advance(2.0)
    check(is_equal_approx(music.track_clock,clock) and music.voices[music.current_voice].stream_paused,"pause freezes musical time")
    music.set_paused(false)
    music.advance(0.2)
    check(music.track_clock > clock and not music.voices[music.current_voice].stream_paused,"resume continues the current song")
    music.set_muted(true)
    music.set_context("rest")
    await create_timer(0.06).timeout
    check(music.voices.all(func(v): return v.volume_db <= -70),"scene transition while muted cannot leak music")
    music.set_muted(false)
    music.advance(1.0)
    check(music.voices[music.current_voice].playing and music.voices[music.current_voice].volume_db > -70,"unmute returns one current arrangement")
    music.set_context("missing")
    check(music.context == "rest","unknown scene music keeps a safe valid arrangement")
    check(music.tracks.values().all(func(s): return s is AudioStreamOggVorbis and s.loop and s.get_length() >= 24),"each scene has an actual loopable composition beyond a tiny cue")
    music.queue_free()
    await process_frame
    # AudioServer frees decoder voices on its own mixing thread.
    await create_timer(0.3).timeout
    finish()
func finish() -> void:
    print("M21_MUSIC: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
