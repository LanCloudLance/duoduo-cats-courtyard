extends Node
## Small original synthesized cues; no external sound license or network needed.
var muted := false
var cues: Array[AudioStreamWAV] = []
var players: Array[AudioStreamPlayer] = []

func _ready() -> void:
    for kind in range(4):
        cues.append(_make_cue(kind))
        var player := AudioStreamPlayer.new()
        player.volume_db = -17
        add_child(player)
        players.append(player)

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
