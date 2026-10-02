extends Node

# One pair of voices belongs to the journey, rather than to individual scenes.
var tracks := {
    "home": preload("res://assets/music/home.ogg"),
    "explore": preload("res://assets/music/explore.ogg"),
    "puzzle": preload("res://assets/music/puzzle.ogg"),
    "battle": preload("res://assets/music/battle.ogg"),
    "boss": preload("res://assets/music/boss.ogg"),
    "rest": preload("res://assets/music/rest.ogg")
}
var voices: Array[AudioStreamPlayer] = []
var context := ""
var current_voice := -1
var track_clock := 0.0
var fade_clock := 0.0
var paused := false
var muted := false
var level := 0.28
var audible := true
var duck_clock := 0.0
const FADE := 0.8

func _ready() -> void:
    for stream in tracks.values(): stream.loop = true
    for i in range(2):
        var voice := AudioStreamPlayer.new()
        # Long scores stream through a bounded buffer. Short effects retain
        # the web platform's low-latency sample playback.
        voice.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
        voice.volume_db = -80
        add_child(voice)
        voices.append(voice)

func context_for(stage: String, phase: String = "", wave: int = 0) -> String:
    if stage == "combat":
        if phase == "clear": return "rest"
        return "boss" if wave >= 3 else "battle"
    if stage in ["light", "gate"]: return "puzzle"
    if stage == "rest": return "rest"
    if stage == "bridge": return "explore"
    return "home"

func set_context(value: String) -> void:
    if value == context or not tracks.has(value) or voices.is_empty(): return
    context = value
    current_voice = 0 if current_voice < 0 else 1-current_voice
    var voice := voices[current_voice]
    voice.stop()
    voice.stream = tracks[value]
    voice.volume_db = -80
    if audible: voice.play()
    voice.stream_paused = paused
    track_clock = 0
    fade_clock = 0
    _mix()

func set_paused(value: bool) -> void:
    if value == paused: return
    paused = value
    for voice in voices: voice.stream_paused = value

func set_muted(value: bool) -> void:
    muted = value
    _mix()

func duck(seconds: float) -> void:
    duck_clock = maxf(duck_clock,seconds)
    _mix()

func advance(dt: float) -> void:
    if paused or current_voice < 0: return
    track_clock += dt
    duck_clock = maxf(0,duck_clock-dt)
    fade_clock = minf(FADE,fade_clock+dt)
    _mix()
    if fade_clock >= FADE: voices[1-current_voice].stop()

func _mix() -> void:
    if current_voice < 0: return
    var ratio := clampf(fade_clock/FADE,0,1)
    for i in range(2):
        var gain := ratio if i == current_voice else 1-ratio
        voices[i].volume_db = -80 if muted or gain <= 0.001 or level <= 0 else linear_to_db(gain*level*(0.5 if duck_clock > 0 else 1.0))

func _process(dt: float) -> void:
    advance(dt)

func _exit_tree() -> void:
    for voice in voices:
        voice.stop()
        voice.stream = null
