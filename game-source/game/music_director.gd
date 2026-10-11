extends Node
## A written score has accompaniment, a melody that can leave room for thought,
## and a complementary pressure part. Every part runs on the same sample grid.
var tracks := {
    "home": preload("res://assets/music/home.ogg"),
    "explore": preload("res://assets/music/explore.ogg"),
    "puzzle": preload("res://assets/music/puzzle.ogg"),
    "chapter3": preload("res://assets/music/chapter3.ogg"),
    "chapter4": preload("res://assets/music/chapter4.ogg"),
    "chapter5": preload("res://assets/music/chapter5.ogg"),
    "battle": preload("res://assets/music/battle.ogg"),
    "boss": preload("res://assets/music/boss.ogg"),
    "rest": preload("res://assets/music/rest.ogg")
}
var melodies := {
    "home": preload("res://assets/music/home-melody.ogg"),
    "explore": preload("res://assets/music/explore-melody.ogg"),
    "puzzle": preload("res://assets/music/puzzle-melody.ogg"),
    "chapter3": preload("res://assets/music/chapter3-melody.ogg"),
    "chapter4": preload("res://assets/music/chapter4-melody.ogg"),
    "chapter5": preload("res://assets/music/chapter5-melody.ogg"),
    "battle": preload("res://assets/music/battle-melody.ogg"),
    "boss": preload("res://assets/music/boss-melody.ogg"),
    "rest": preload("res://assets/music/rest-melody.ogg")
}
var pressure_tracks := {
    "battle": preload("res://assets/music/battle-pressure.ogg"),
    "boss": preload("res://assets/music/boss-pressure.ogg"),
    "chapter5": preload("res://assets/music/chapter5-pressure.ogg")
}
var accents := {
    "discovery": preload("res://assets/music/accent-discovery.ogg"),
    "resolved": preload("res://assets/music/accent-resolved.ogg"),
    "reunion": preload("res://assets/music/accent-reunion.ogg")
}
const TEMPOS := {"home":92.0,"explore":108.0,"puzzle":80.0,"chapter3":96.0,"chapter4":104.0,"chapter5":112.0,"battle":136.0,"boss":144.0,"rest":78.0}
const METERS := {"home":3,"explore":3,"puzzle":3,"chapter3":3,"chapter4":4,"chapter5":4,"battle":3,"boss":3,"rest":3}
const PROFILES := {"home":"home","explore":"explore","chapter2":"explore","chapter3":"chapter3","chapter4":"chapter4","chapter5":"chapter5","battle":"battle","boss":"boss","rest":"rest","puzzle":"puzzle"}
const FADE := 0.8
const VOICE_COUNT := 3
var voices: Array[AudioStreamPlayer] = []
var melody_voices: Array[AudioStreamPlayer] = []
var pressure_voices: Array[AudioStreamPlayer] = []
var accent_voice: AudioStreamPlayer
var context := ""
var scene_profile := ""
var mood := "flow"
var current_voice := -1
var track_clock := 0.0
var fade_clock := 0.0
var paused := false
var muted := false
var level := 0.28
var audible := true
var duck_clock := 0.0
var duck_gain := 1.0
var melody_gain := 1.0
var pressure_gain := 0.0
var voice_gains: Array[float] = [0.0,0.0,0.0]
var fade_starts: Array[float] = [0.0,0.0,0.0]
var bank_melodies: Array[float] = [1.0,1.0,1.0]
var bank_pressures: Array[float] = [0.0,0.0,0.0]
var bank_clocks: Array[float] = [0.0,0.0,0.0]
var saved_positions := {}
var pending_scene: Array[String] = []
var accent_serial := 0
var accent_cooldown := 0.0
var voice_contexts: Array[String] = ["", "", ""]

func _ready() -> void:
    for bank in [tracks,melodies,pressure_tracks]:
        for stream in bank.values(): stream.loop = true
    for stream in accents.values(): stream.loop = false
    for i in range(VOICE_COUNT):
        voices.append(_new_voice())
        melody_voices.append(_new_voice())
        pressure_voices.append(_new_voice())
    accent_voice = _new_voice()

func _new_voice() -> AudioStreamPlayer:
    var voice := AudioStreamPlayer.new()
    voice.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
    voice.volume_db = -80
    add_child(voice)
    return voice

func all_players() -> Array[AudioStreamPlayer]:
    var result: Array[AudioStreamPlayer] = []
    result.append_array(voices)
    result.append_array(melody_voices)
    result.append_array(pressure_voices)
    if is_instance_valid(accent_voice): result.append(accent_voice)
    return result

func context_for(stage: String, phase: String = "", wave: int = 0) -> String:
    if stage == "combat":
        if phase in ["briefing","intermission","failed","clear","complete"]: return "rest"
        return "boss" if wave >= 3 else "battle"
    if stage in ["light", "gate"]: return "puzzle"
    if stage == "rest": return "rest"
    if stage == "bridge": return "explore"
    return "home"

func seconds_per_bar(value: String) -> float:
    return 60.0 / float(TEMPOS.get(value,92.0)) * float(METERS.get(value,3))

func set_scene(profile: String, feeling: String = "flow") -> void:
    if not PROFILES.has(profile) or feeling not in ["flow","reflect","pressure","resolved"]: return
    var target: String = PROFILES[profile]
    if feeling == "resolved": target = "rest" if profile != "home" else "home"
    if target == context and feeling == mood:
        pending_scene.clear()
        scene_profile = profile
        return
    # Combat entry/clear and renewed pressure cannot wait behind a quiet phrase.
    var immediate := current_voice < 0 or target in ["battle","boss"] and target != context or feeling in ["pressure","resolved"] or context in ["battle","boss"] and target != context
    if immediate:
        pending_scene.clear()
        _commit_scene(profile,feeling,target)
    else:
        pending_scene.assign([profile,feeling,target])

func _commit_scene(profile: String, feeling: String, target: String) -> void:
    scene_profile = profile
    mood = feeling
    if target != context: _start_track(target)
    _mix()

## Compatibility for legacy scenes/tests: explicitly changing context is immediate.
func set_context(value: String) -> void:
    if not tracks.has(value): return
    pending_scene.clear()
    if value == context: return
    scene_profile = value
    mood = "flow"
    _start_track(value)

func _start_track(value: String) -> void:
    if voices.is_empty(): return
    if current_voice >= 0:
        saved_positions[context] = _decoder_position() if audible and voices[current_voice].playing else fmod(track_clock,tracks[context].get_length())
        bank_melodies[current_voice] = melody_gain
        bank_pressures[current_voice] = pressure_gain
    var next := -1
    for i in range(VOICE_COUNT):
        if voice_contexts[i] == value and voice_gains[i] > 0.001:
            next = i
            break
    var continuing := next >= 0
    if not continuing:
        # The third bank keeps both sides of an interrupted transition alive.
        # Further rapid unique requests reuse the quietest bounded bank.
        next = voice_gains.find(voice_gains.min())
    context = value
    current_voice = next
    if continuing:
        track_clock = _decoder_position() if audible and voices[next].playing else bank_clocks[next]
        melody_gain = bank_melodies[next]
        pressure_gain = bank_pressures[next]
    else:
        voice_contexts[next] = value
        voice_gains[next] = 0.0
        track_clock = float(saved_positions.get(value,0.0))
        # All parts begin at the same sample position, including silent parts.
        for part in range(3):
            var voice: AudioStreamPlayer = [voices,melody_voices,pressure_voices][part][next]
            voice.stop()
            voice.stream = tracks[value] if part == 0 else melodies[value] if part == 1 else pressure_tracks.get(value)
            voice.volume_db = -80
            if audible and voice.stream != null: voice.play(track_clock)
            voice.stream_paused = paused
        melody_gain = 0.0 if mood == "reflect" else 1.0
        pressure_gain = 0.85 if mood == "pressure" else 0.0
    bank_clocks[next] = track_clock
    fade_starts.assign(voice_gains)
    fade_clock = 0
    _mix()

func accent(kind: String) -> void:
    if not accents.has(kind) or not is_instance_valid(accent_voice) or accent_cooldown > 0 or paused: return
    accent_voice.stop()
    accent_voice.stream = accents[kind]
    accent_serial += 1
    accent_cooldown = 2.4 if kind == "reunion" else 1.5
    # Muted events are consumed; they are not queued to surprise the player later.
    if audible and not muted and level > 0: accent_voice.play()
    accent_voice.stream_paused = paused
    duck(accent_voice.stream.get_length())
    _mix()

func set_paused(value: bool) -> void:
    if value == paused: return
    paused = value
    for voice in all_players(): voice.stream_paused = value

func set_muted(value: bool) -> void:
    muted = value
    _mix()

func duck(seconds: float) -> void:
    duck_clock = maxf(duck_clock,seconds)
    duck_gain = 0.5
    _mix()

func advance(dt: float) -> void:
    if paused or current_voice < 0: return
    # Split the step at the measure boundary so automated clocks and real frame
    # clocks enter the new score at the same point rather than skipping its start.
    var remaining := maxf(dt,0.0)
    if not pending_scene.is_empty():
        var bar := seconds_per_bar(context)
        var until_bar := bar-fmod(track_clock,bar)
        if remaining >= until_bar:
            _advance_mix(until_bar)
            remaining -= until_bar
            var request := pending_scene.duplicate()
            pending_scene.clear()
            _commit_scene(request[0],request[1],request[2])
    _advance_mix(remaining)

func _advance_mix(dt: float) -> void:
    track_clock += dt
    for i in range(VOICE_COUNT):
        if not voice_contexts[i].is_empty() and voice_gains[i] > 0.001:
            bank_clocks[i] = fposmod(bank_clocks[i]+dt,tracks[voice_contexts[i]].get_length())
    bank_clocks[current_voice] = track_clock
    accent_cooldown = maxf(0,accent_cooldown-dt)
    duck_clock = maxf(0,duck_clock-dt)
    if duck_clock <= 0: duck_gain = move_toward(duck_gain,1.0,dt*5.0)
    fade_clock = minf(FADE,fade_clock+dt)
    melody_gain = move_toward(melody_gain,0.0 if mood == "reflect" else 1.0,dt*2.5)
    pressure_gain = move_toward(pressure_gain,0.85 if mood == "pressure" else 0.0,dt*2.0)
    _mix()
    if fade_clock >= FADE:
        for i in range(VOICE_COUNT):
            if i == current_voice: continue
            voices[i].stop()
            melody_voices[i].stop()
            pressure_voices[i].stop()

func _volume(gain: float) -> float:
    return -80.0 if muted or level <= 0 or gain <= 0.001 else linear_to_db(level*gain)

func _mix() -> void:
    if current_voice < 0: return
    var ratio := clampf(fade_clock/FADE,0,1)
    for i in range(VOICE_COUNT):
        var weight := pow(sin(ratio*PI*.5),2)
        var gain := sqrt(lerpf(fade_starts[i]*fade_starts[i],1.0 if i == current_voice else 0.0,weight))
        voice_gains[i] = gain
        var tune := melody_gain if i == current_voice else bank_melodies[i]
        var pressure := pressure_gain if i == current_voice else bank_pressures[i]
        voices[i].volume_db = _volume(gain*duck_gain)
        melody_voices[i].volume_db = _volume(gain*tune*duck_gain)
        pressure_voices[i].volume_db = _volume(gain*pressure*duck_gain)
    if is_instance_valid(accent_voice): accent_voice.volume_db = _volume(0.85)

func _decoder_position() -> float:
    var position := voices[current_voice].get_playback_position()
    if not paused: position += AudioServer.get_time_since_last_mix()
    return fposmod(position,tracks[context].get_length())

func _process(dt: float) -> void:
    if paused or current_voice < 0: return
    if audible and voices[current_voice].playing:
        # Audio runs independently of frame rate. A slow rendered frame must not
        # schedule the next section using an accumulated visual-frame clock.
        var duration: float = tracks[context].get_length()
        var elapsed := _decoder_position()-fposmod(track_clock,duration)
        if elapsed < -duration*.5: elapsed += duration
        # A newly started decoder can report zero until its first mixer block.
        # Do not mistake that startup delay for an entire loop.
        if elapsed >= 0 and elapsed < duration*.5: advance(elapsed)
    else:
        advance(dt)

func _exit_tree() -> void:
    for voice in all_players():
        voice.stop()
        voice.stream = null
