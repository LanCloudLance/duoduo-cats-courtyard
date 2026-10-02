extends Node
## Small original synthesized cues; no external sound license or network needed.
var muted := false
var cues: Array[AudioStreamWAV] = []
var players: Array[AudioStreamPlayer] = []
var combat := false
var voice_cursor := 0
const COMBAT_CUES := {"swing":0,"dodge":0,"hit":1,"heavy":2,"blocked":3,"hurt":4,"parry":5,"guard":3,"ready":6,"charge":7,"defeat":8,"interrupt":9,"combo":2,"assist":9,"plant_burst":2}

func _ready() -> void:
    for kind in range(10 if combat else 4):
        cues.append(_make_combat_cue(kind) if combat else _make_cue(kind))
    for kind in range(8 if combat else 4):
        var player := AudioStreamPlayer.new()
        player.volume_db = -17
        add_child(player)
        players.append(player)

func play_feedback(event: Dictionary) -> void:
    if muted or not combat or players.is_empty() or not COMBAT_CUES.has(event.kind): return
    var kind: int = COMBAT_CUES[event.kind]
    var voice := players[voice_cursor]
    voice_cursor = (voice_cursor+1)%players.size()
    voice.stream = cues[kind]
    var role: int = event.get("role",0)
    voice.pitch_scale = [1.0,1.32,0.84][clampi(role,0,2)] if kind in [0,1,9] else 1.0
    voice.volume_db = -21 if kind in [0,7] else -16 if kind in [2,4,5] else -19
    voice.play()

func _make_combat_cue(kind: int) -> AudioStreamWAV:
    var rate := 22050
    var duration: float = [0.12,0.11,0.22,0.13,0.20,0.26,0.15,0.30,0.23,0.12][kind]
    var bytes := PackedByteArray()
    bytes.resize(int(duration*rate)*2)
    var rng := RandomNumberGenerator.new()
    rng.seed = 19000+kind
    var filtered := 0.0
    for i in range(bytes.size()/2):
        var t := float(i)/rate
        var noise := rng.randf_range(-1,1)
        filtered = lerpf(filtered,noise,0.18)
        var envelope := minf(t*350,1.0)*pow(maxf(0,1-t/duration),2.0)
        var value := 0.0
        match kind:
            0: value = (noise-filtered)*sin(PI*t/duration)*0.42
            1: value = filtered*0.85+sin(TAU*(210*t-340*t*t))*0.43
            2: value = filtered*0.75+sin(TAU*(100*t-105*t*t))*0.73
            3: value = sin(TAU*1250*t)*exp(-t*30)*0.38+(noise-filtered)*0.52
            4: value = filtered*0.60+sin(TAU*(150*t-150*t*t))*0.47
            5: value = sin(TAU*880*t)*0.44+sin(TAU*1320*t)*0.23+filtered*0.16
            6: value = sin(TAU*(700*t+1100*t*t))*0.38
            7: value = filtered*0.35+sin(TAU*(80*t+190*t*t))*0.25
            8: value = filtered*0.55+sin(TAU*(85*t-100*t*t))*0.30
            9: value = (noise-filtered)*0.45+sin(TAU*460*t)*0.31
        bytes.encode_s16(i*2,int(clampf(value*envelope,-1,1)*27000))
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = rate
    stream.data = bytes
    return stream

func play(kind: int) -> void:
    if muted or players.is_empty(): return
    players[kind].stream = cues[kind]
    players[kind].play()

func silence() -> void:
    for player in players: player.stop()

func _make_cue(kind: int) -> AudioStreamWAV:
    var rate := 22050
    var duration := [0.24,0.32,0.65,0.10][kind] as float
    var bytes := PackedByteArray()
    bytes.resize(int(duration*rate)*2)
    for i in range(bytes.size()/2):
        var t := float(i)/rate
        var hz := [180.0,740.0,520.0,980.0][kind] as float
        var envelope := minf(t*80,1.0)*exp(-t*(13 if kind == 0 else 7))
        var value := sin(TAU*hz*t)*0.65+sin(TAU*hz*1.5*t)*0.2
        if kind == 0: value *= sin(TAU*19*t)
        if kind == 2: value += sin(TAU*780*t)*0.22+sin(TAU*1040*t)*0.13
        bytes.encode_s16(i*2,int(clampf(value*envelope,-1,1)*22000))
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = rate
    stream.data = bytes
    return stream
