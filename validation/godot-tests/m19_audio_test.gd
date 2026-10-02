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
    var audio = load("res://game/garden_audio.gd").new()
    check(audio.has_method("play_feedback"),"combat audio consumes individual typed feedback events")
    if failed:
        finish()
        return
    audio.combat = true
    root.add_child(audio)
    await process_frame
    check(audio.cues[0].data != audio.cues[1].data,"swing and contact have distinct sounds")
    check(audio.cues[1].data != audio.cues[2].data and audio.cues[1].data != audio.cues[4].data,"ordinary hit heavy hit and hurt are distinct waveforms")
    audio.play_feedback({"kind":"hit","role":0,"slot":0})
    audio.play_feedback({"kind":"heavy","role":2,"slot":1})
    check(audio.players[0].stream != audio.players[1].stream and audio.players[0].playing and audio.players[1].playing,"two simultaneous players retain both audio voices")
    audio.silence()
    check(audio.players.all(func(p): return not p.playing),"pause and mute stop every combat voice")
    audio.muted = true
    audio.play_feedback({"kind":"hit","role":0,"slot":0})
    check(audio.players.all(func(p): return not p.playing),"muting prevents feedback audio from restarting")
    audio.queue_free()
    await process_frame
    await create_timer(0.1).timeout
    finish()
func finish() -> void:
    print("M19_AUDIO: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
