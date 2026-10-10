extends "res://game/garden_audio.gd"
## Original short material cues, driven by changes that the chapter actually made.
var materials:Array[AudioStreamWAV]=[]
var previous_observation:=""
func _ready()->void:
    super._ready()
    for index in range(5):materials.append(_material(index))
func silence()->void:
    super.silence()
    for player in players:player.stream=null
func _exit_tree()->void:
    silence()
func play_story(state)->void:
    var record:Dictionary={}
    if state.has_method("presentation"):
        var observations:Array=state.presentation().get("observations",[])
        if not observations.is_empty():record=observations[-1]
    var token:=str(record)
    if record.is_empty() or token==previous_observation:
        play(state.cue);return
    previous_observation=token
    var id:String=record.get("id","")
    var kind:=0
    if id.contains("pin") or id.contains("lock") or id.contains("latched"):kind=1
    elif id.contains("lamp") or id.contains("work_kept") or id.contains("pilot") or id.contains("view_open") or id.contains("stall_open"):kind=2
    elif id.contains("map") or id.contains("shell_wind"):kind=3
    elif id.contains("load") or id.contains("raise") or id.contains("supported") or id.contains("branch"):kind=4
    if muted or players.is_empty():return
    var player:AudioStreamPlayer=players[kind%players.size()]
    player.stream=materials[kind];player.volume_db=-22 if kind==3 else -20;player.play()
func _material(kind:int)->AudioStreamWAV:
    var duration:float=[.15,.22,.44,.25,.32][kind]
    var rate:=22050;var bytes:=PackedByteArray();bytes.resize(int(duration*rate)*2)
    var rng:=RandomNumberGenerator.new();rng.seed=4201+kind
    var smooth:=0.0
    for i in range(bytes.size()/2):
        var t:=float(i)/rate;var noise:=rng.randf_range(-1,1);smooth=lerpf(smooth,noise,.13)
        var env:=minf(1,t*200)*pow(maxf(0,1-t/duration),2)
        var value:=0.0
        match kind:
            0:value=sin(TAU*180*t)*exp(-t*24)*.45+smooth*.45
            1:value=(sin(TAU*1120*t)*.32+sin(TAU*1730*t)*.22)*exp(-t*17)+noise*exp(-t*100)*.35
            2:value=(sin(TAU*660*t)*.38+sin(TAU*990*t)*.18+sin(TAU*1320*t)*.09)*exp(-t*5)
            3:value=(noise-smooth)*(.16+.13*sin(TAU*27*t))*sin(PI*t/duration)
            4:value=sin(TAU*(125*t+12*sin(t*31)))*.25+smooth*.5+sin(TAU*63*t)*.22
        bytes.encode_s16(i*2,int(clampf(value*env,-1,1)*23000))
    var stream:=AudioStreamWAV.new();stream.format=AudioStreamWAV.FORMAT_16_BITS;stream.mix_rate=rate;stream.data=bytes;return stream
