extends SceneTree
# Signal/dispatch/lifecycle proof only. Does not claim perceived sound quality.
var checks:=0
var failures:=0
func _initialize()->void:call_deferred("run")
func check(value:bool,label:String)->void:
    checks+=1
    if not value:failures+=1;push_error(label)
func run()->void:
    print("M28_STORY_AUDIO_USERDIR: ",OS.get_user_data_dir())
    if OS.get_user_data_dir().get_file()!="DuoduoCatsCourtyard-qa-m28-presentation":push_error("wrong QA directory");quit(1);return
    var audio=load("res://game/story_audio.gd").new();root.add_child(audio)
    check(audio.materials.size()==5,"five material cues exist")
    var hashes:Dictionary={}
    for stream in audio.materials:
        check(stream.format==AudioStreamWAV.FORMAT_16_BITS and stream.mix_rate==22050,"PCM format is correct")
        check(stream.data.size()>4400,"cue contains real PCM samples")
        var nonzero:=false
        for index in range(stream.data.size()/2):
            if stream.data.decode_s16(index*2)!=0:nonzero=true;break
        check(nonzero,"PCM is not silence")
        hashes[hash(stream.data)]=true
    check(hashes.size()==5,"material PCM differs for all five cues")
    var s=load("res://game/chapter_five_state.gd").new()
    var ids:=["cart_shortcut","pin_taken","lamp_carried","map_back_read","load_lift"]
    for index in range(5):
        s.observe(ids[index],"material probe "+str(index),Vector2.ZERO)
        audio.play_story(s)
        await create_timer(.05).timeout
        check(audio.players[index%4].stream==audio.materials[index],"real observation selects its material")
        audio.silence()
        await process_frame
    audio.muted=true;s.observe("pin_returned","muted probe",Vector2.ZERO);audio.play_story(s)
    var stopped:=true
    for player in audio.players:stopped=stopped and not player.playing
    check(stopped,"muted observation starts no voice")
    audio.free()
    var lobby:=Control.new();lobby.theme=Theme.new();lobby.theme.default_font=load("res://assets/fonts/CourtyardSans.ttf");root.add_child(lobby)
    var session=load("res://input/session_state.gd").new();session.keyboard_mode=true;session.single_player=true;session.ready_flags.assign([true,false])
    var view=load("res://game/story_chapter_view.gd").new(session);lobby.add_child(view);view.set_physics_process(false);view.record_prefix="m28-audio-lifecycle"
    view.reset(2,true,false);view.set_active(true)
    view.state.observe("pin_taken","lifecycle probe",Vector2.ZERO);view.audio.play_story(view.state)
    await create_timer(.05).timeout
    check(view.audio.players[1].playing,"active chapter starts selected voice")
    view.set_active(false)
    stopped=true
    for player in view.audio.players:stopped=stopped and not player.playing
    check(stopped,"set_active(false) stops every story voice")
    lobby.free();await create_timer(.25).timeout
    print("M28_STORY_AUDIO: ",checks," checks, ",failures," failed; PCM and lifecycle only, not listening acceptance")
    call_deferred("quit",1 if failures else 0)
