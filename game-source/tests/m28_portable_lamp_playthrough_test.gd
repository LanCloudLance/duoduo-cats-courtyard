extends "res://tests/m25_keyboard_driver.gd"
# Chapter-local known-solution InputEvent test. One validated entry checkpoint per
# mode skips the already-tested market recovery; this is not a full journey.
const Four=preload("res://game/chapter_four_state.gd")
var door_trips:=0
func run()->void:
    if not gate(OS.get_user_data_dir().get_file()=="DuoduoCatsCourtyard-qa-m28-portable","actual isolated portable-lamp QA namespace"):return
    print("M28_PORTABLE_USERDIR ",OS.get_user_data_dir())
    Engine.time_scale=3
    lobby=load("res://main.tscn").instantiate();root.add_child(lobby);await frames(3);lobby.session.set_focus(true)
    for mode in [true,false]:
        lobby.story_chapter.record_prefix="qa-m28-portable-"+str(Time.get_ticks_usec())
        await start(4,mode)
        var fixture:Dictionary=Four.new().checkpoint();fixture.mode="solo" if mode else "dual";fixture.phase="investigate"
        fixture.facts.cover_hooked=true;fixture.facts.cloth=true
        fixture.positions=[[565,480],[610,520],[650,550]]
        var probe=Four.new();probe.single=mode
        if not gate(probe.restore_checkpoint(fixture),"declared chapter-entry checkpoint is legal before loading fixture"):return
        if not gate(s.restore_checkpoint(fixture),"one entry fixture only; subsequent gameplay uses InputEvent"):return
        await frames(40)
        if not gate(await go(2,s.DUCT_LIGHT),"white cat walks to interior light stand"):return
        await aim(2,Vector2.UP);await touch(2)
        if not gate(s.trial_lit(),"real facing and action sustain trial light"):return
        if not gate(await go(0,s.ARROWS),"girl walks to splitter handle"):return
        await touch(0)
        if not gate(await go(1,s.BRANCH),"cat walks to physical isolation clasp"):return
        await touch(1);await pulse()
        if not gate(s.reserve_available and s.reserve_hold_seen and s.bypass_isolated and s.lamp_dest=="rack","isolated trial creates exactly one retained rack lamp"):return
        if not gate(await go(1,s.BRANCH),"cat returns to reconnect retained lamp"):return
        await touch(1)
        if not gate(s.reconnected_seen and not s.reserve_available and not s.connected_split_seen and not s.main_return_seen,"reconnecting actual retained light drains it without inventing other trials"):return
        await touch(1);await pulse()
        if not gate(s.reserve_available and s.bypass_isolated,"re-isolating and sending fresh light recovers the same lamp"):return
        if not gate(await go(0,s.RESERVE),"girl reaches actual lamp handle"):return
        await touch(0)
        if not gate(s.lamp_dest=="carried" and lit_lamps()==0,"taking lamp leaves empty rack and does not remotely light destinations"):return
        axes(9,Vector2.ZERO);axes(18,Vector2.ZERO);tap_key(KEY_ESCAPE);await frames(2)
        var frozen:Array=s.positions.duplicate();await frames(12)
        if not gate(not lobby.session.running() and s.positions==frozen and s.lamp_dest=="carried","pause freezes carrier while preserving actual carried lamp"):return
        tap_key(KEY_ENTER);await frames(3)
        if not await door(s.MARKET_DOOR,"market"):return
        if not gate(await go(0,Vector2(445,270)),"carrier walks outside the market pit's east edge"):return
        if not gate(await go(0,s.STALL_LAMP),"carrier walks to merchant lamp base"):return
        await touch(0)
        if not gate(s.lamp_dest=="stall" and s.stall_seen and s.presentation().discoveries.has("four_stall") and lit_lamps()==1,"physical placement reopens stall and earns only actual stall discovery"):return
        await touch(0)
        if not gate(s.lamp_dest=="carried" and lit_lamps()==0,"picking lamp back up darkens old stall instead of copying light"):return
        if not gate(await go(0,Vector2(445,270)),"carrier retraces safe upper edge of market pit"):return
        if not await door(s.MARKET_DOOR,"interior"):return
        if not await door(s.VIEW_DOOR,"exterior"):return
        if not gate(await go(0,s.VIEW_LAMP),"carrier walks to actual exterior viewing lamp base"):return
        await touch(0)
        if not gate(s.lamp_dest=="view" and s.view_seen and s.presentation().discoveries==["four_stall","four_view"] and lit_lamps()==1,"same lamp reveals storm branch direction and records second real discovery"):return
        await touch(0)
        if not gate(s.lamp_dest=="carried" and lit_lamps()==0,"viewing lamp base becomes empty when same lamp is retrieved"):return
        if not await door(s.VIEW_DOOR,"interior"):return
        if not gate(await go(0,s.RESERVE),"girl physically carries lamp back to original rack"):return
        await touch(0)
        if not gate(s.lamp_dest=="rack" and lit_lamps()==1,"returning lamp restores only rack light"):return
        if not gate(await go(2,s.DUCT_LIGHT),"white cat returns to relight experiment after travel released beam"):return
        await aim(2,Vector2.UP);await touch(2)
        if not gate(await go(1,s.BRANCH),"cat reaches clasp after lamp returned"):return
        await touch(1)
        if not gate(not s.reserve_available and lit_lamps()==0 and s.stall_seen and s.view_seen,"returned lamp drains on reconnect; earned observations survive without duplicated light"):return
        await frames(40)
        var saved:Dictionary=c.read_record();var restored=Four.new();restored.single=mode
        if not gate(not saved.is_empty() and restored.restore_checkpoint(saved) and restored.lamp_dest=="rack" and not restored.reserve_available and restored.stall_seen and restored.view_seen,"normal autosave preserves actual destinations, discoveries, and final drained state"):return
        print("M28_PORTABLE_MODE_COMPLETE solo=",mode," doors=",door_trips," discoveries=",s.presentation().discoveries)
    lobby.session.pause_all();c=null;s=null;b=null;lobby.queue_free();await frames(4);lobby=null
    # Audio mixer disposal follows wall time when fixed-fps simulation runs fast.
    var deadline:int=Time.get_ticks_msec()+100
    while Time.get_ticks_msec()<deadline:await process_frame
    print("M28_PORTABLE_LAMP_PLAYTHROUGH: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
func lit_lamps()->int:
    var count:=0
    for mechanism in s.presentation().mechanisms:
        if mechanism.id in ["reserve_lamp","stall_lamp","view_lamp"] and mechanism.lit:count+=1
    return count
func pulse()->void:
    if not gate(await go(0,s.ARROWS),"girl walks to send actual isolated pulse"):return
    await select(0);tap_key(KEY_R if single else KEY_T);await frames(45)
func door(point:Vector2,expected:String)->bool:
    if not gate(await go(0,point),"carrier reaches real room door for "+expected):return false
    await select(0);tap_key(KEY_E);await frames(1)
    if not gate(s.social_transition_active(),"door begins continuous approach rather than room teleport"):return false
    var previous:Array=s.positions.duplicate()
    var max_step:=0.0
    for i in range(500):
        if not s.social_transition_active():break
        await frames(1)
        for role in [0,1,2]:
            max_step=maxf(max_step,s.positions[role].distance_to(previous[role]))
        previous=s.positions.duplicate()
    await frames(20);door_trips+=1
    if not gate(max_step<=6.6,"door approach preserves bounded actual feet movement"):return false
    return gate(not s.social_transition_active() and not c.scene_transition.blocking and s.room_name()==expected and s.lamp_dest=="carried","door reaches visible room with same carried lamp: "+expected)
func touch(role:int)->void:
    await select(role);tap_key(KEY_E if single or role==0 else KEY_SPACE);await frames(16)
func go(role:int,target:Vector2)->bool:
    await select(role)
    var device:=9 if single or role==0 else 18
    for i in range(400):
        var offset:Vector2=target-s.positions[role]
        if offset.length()<7:axes(device,Vector2.ZERO);return true
        axes(device,Vector2(0 if absf(offset.x)<3 else signf(offset.x),0 if absf(offset.y)<3 else signf(offset.y)));await frames(1)
    axes(device,Vector2.ZERO);print("PORTABLE_STUCK ",s.room_name()," role=",role," target=",target," positions=",s.positions," message=",s.message);return false
func gate(value:bool,label:String)->bool:
    check(value,label)
    if not value:
        print("M28_PORTABLE_LAMP_PLAYTHROUGH: %d checks, %d failed"%[checks,failed]);quit(1)
    return value
