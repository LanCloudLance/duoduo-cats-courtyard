extends SceneTree
var checks:=0
var failed:=0
func check(ok:bool,label:String)->void:
    checks+=1
    if not ok:failed+=1;push_error("FAIL: "+label)
func _initialize()->void:run.call_deferred()
func run()->void:
    var music=load("res://game/music_director.gd").new()
    music.audible=false;root.add_child(music);await process_frame
    music.set_process(false)
    music.set_context("explore");music.advance(1)
    var explore:int=music.current_voice
    music.set_context("battle");music.advance(.1)
    var battle:int=music.current_voice
    var explore_gain:float=music.voices[explore].volume_db
    var battle_gain:float=music.voices[battle].volume_db
    music.set_context("rest")
    check(music.voice_contexts[explore]=="explore","third score does not cut the still-loud original score")
    check(absf(music.voices[explore].volume_db-explore_gain)<.01,"old accompaniment has no immediate gain discontinuity")
    check(absf(music.voices[battle].volume_db-battle_gain)<.01,"interrupted incoming score has no 14dB jump")
    music.advance(.1)
    var returning:float=music.voices[battle].volume_db
    music.set_context("battle")
    check(absf(music.voices[music.current_voice].volume_db-returning)<.01,"returning audible score begins at its current gain")
    for n in range(40):
        music.advance(.02)
        var energy:=0.0
        for v in music.voices:energy+=pow(db_to_linear(v.volume_db)/music.level,2)
        check(energy<=1.001,"crossfade remains within full-score power")
    for i in range(music.voices.size()):
        if i!=music.current_voice:check(music.voices[i].volume_db<=-70,"all obsolete banks settle silent")
    music.queue_free();await process_frame
    var score=load("res://game/journey_score.gd").new()
    var battle_state=load("res://game/battle_state.gd").new()
    for phase in ["briefing","intermission","failed"]:
        battle_state.phase=phase
        var result:Dictionary=score.sample("combat",null,"routing",battle_state)
        check(result.profile=="rest" and result.mood=="reflect","noncombat phase removes battle accompaniment: "+phase)
    for stage in ["bridge","light","gate","rest"]:
        var result:Dictionary=score.sample(stage,null,"routing")
        check(result.profile=={"bridge":"explore","light":"puzzle","gate":"puzzle","rest":"rest"}[stage],"standalone route works with actual null story state: "+stage)
    print("M29_MUSIC_TRANSITION: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
