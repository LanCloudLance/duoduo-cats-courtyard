extends "res://tests/m25_keyboard_driver.gd"
const Checkpoint=preload("res://game/story_checkpoint.gd")
const Five=preload("res://game/chapter_five_state.gd")
func touch(role:int)->void:
    await super.touch(role)
    var restored=Five.new();restored.single=single
    var captured:Dictionary=Checkpoint.capture(s)
    check(Checkpoint.restore(restored,captured),"real interaction checkpoint restores: "+s.phase)
    check(restored.phase==s.phase and restored.lid_pins==s.lid_pins and restored.cleared_segments==s.cleared_segments,"restored chapter retains phase and permanent pins/segments")
    for actor in restored.available_roles():check(restored.walkable(restored.positions[actor],actor),"restored actor stands on safe floor: "+s.phase)

func run()->void:
    print("M27_FIVE_QA_USERDIR: ",OS.get_user_data_dir())
    if OS.get_user_data_dir().get_file()!="DuoduoCatsCourtyard-qa-m27-five":push_error("wrong QA user directory");quit(1);return
    Engine.time_scale=3
    lobby=load("res://main.tscn").instantiate();root.add_child(lobby);await frames(3);lobby.session.set_focus(true)
    lobby.story_chapter.record_prefix="qa-m27-five-"+str(Time.get_ticks_usec())
    for mode in [true,false]:
        await start(5,mode)
        if not gate(await go(1,s.LOW_LOCK),"black cat reaches core approach low latch"):return
        await touch(1)
        if not gate(await go(0,s.SUPPORT),"girl fits learned platform support"):return
        await touch(0)
        if not gate(await go(2,s.ROUTE_LAMP),"white chooses learned route lamp"):return
        await aim(2,Vector2.RIGHT);await touch(2)
        if not gate(s.bridge_locked,"learned three-role tools lock real approach bridge"):return
        for role in s.available_roles():
            if not gate(await go(role,Vector2(340,550)),"party reaches bridge approach"):return
            if not gate(await go(role,s.CORE_GATE+Vector2(role*15,0)),"all three cross real permanent core bridge"):return
        if not gate(await go(0,s.CORE_GATE),"girl returns to door after moving her partners"):return
        await frames(100);await touch(0)
        if not gate(s.phase=="shield","gathered party enters repair boss through normal input"):return
        # Controlled repeatable route; this is normal InputEvent validation, not blind play.
        # First deliberately face away inside the visible warning, recover, then hold early.
        if not gate(await go(1,Vector2(800,575)),"cat reaches lower maintenance slot safely"):return
        if not gate(await go(0,s.SHIELD_SLOT),"girl reaches shield slot"):return
        await aim(0,Vector2.LEFT)
        var failures:int=s.failed_sweeps
        for i in range(350):
            if s.failed_sweeps>failures:break
            await frames(1)
        if not gate(s.failed_sweeps>failures and s.walkable(s.positions[0],0),"wrong-facing visible contact returns to a real safe platform"):return
        if not gate(await go(0,s.SHIELD_SLOT),"girl returns after safe setback"):return
        await aim(0,Vector2(1,-1))
        key_event(KEY_G,true)
        for i in range(180):
            if s.arm_arrest>0:break
            await frames(1)
        key_event(KEY_G,false)
        if not gate(s.arm_arrest>0,"normal sustained directional shield arrests moving mechanical arm"):return
        if not gate(await go(1,s.ARM_LOCK),"cat approaches arrested arm before timeout"):return
        await touch(1)
        if not gate(s.phase=="lure" and s.stage_checkpoint==1,"hook input preserves first repair checkpoint"):return
        await touch(1)
        if not gate(s.phase=="lure" and s.arm_locked and s.stage_checkpoint==1,"natural revisit of stopped arm only observes and never restarts shield stage"):return
        if not gate(await go(2,s.AIM_STAND),"white reaches buffer light operator"):return
        await aim(2,Vector2.RIGHT);await touch(2)
        if not gate(await go(0,Vector2(1070,550)),"girl goes around actual machine body"):return
        if not gate(await go(0,s.WHEEL),"girl reaches outside wheel"):return
        await touch(0);await frames(65)
        if not gate(s.phase=="lure" and s.lid_pins==1,"first manual pin remains locked without auto-opening lid"):return
        # The retained lower route is now wrong; it cannot open the second pin.
        await touch(0)
        if not gate(s.lid_pins==1 and not s.lid_open,"wrong buffer keeps prior pin and safely recoils"):return
        await snapshot("-lower-pin-"+str(single))
        await aim(2,Vector2.UP);await touch(2)
        await snapshot("-upper-route-"+str(single))
        await touch(0)
        if not gate(s.phase=="unjam" and s.lid_open,"changed buffer and second manual wheel stroke open the cover"):return
        await touch(2)
        if not gate(s.phase=="unjam" and s.lid_pins==2 and not s.beam_held,"natural revisit of old lure stand keeps both pins without reactivating old light route"):return
        if not gate(await go(2,s.CRADLE),"white brings beam to independent safety cradle"):return
        await touch(2)
        if not gate(await go(1,s.REPAIR_SLOT),"black cat enters actual open low repair slot"):return
        await touch(1)
        if not gate(s.cleared_segments==0,"pull before unloading safely springs back"):return
        await touch(0);await touch(1);await frames(70)
        if not gate(s.cleared_segments==1 and not s.machine_stopped,"one active hook stroke cannot auto-ratchet later bends"):return
        await snapshot("-middle-bend-"+str(single))
        var pause_segment:int=s.cleared_segments;var pause_clock:float=s.clock
        lobby.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
        await frames(25)
        if not gate(s.cleared_segments==pause_segment and s.clock==pause_clock,"focus pause freezes live repair without losing completed segment"):return
        lobby.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN);tap_key(KEY_ENTER);await frames(3)
        await touch(1)
        if not gate(s.cleared_segments==1,"same old unloading direction cannot pull opposite bend"):return
        await touch(0);await touch(0);await touch(1)
        if not gate(s.cleared_segments==2,"second bend needs changed clearance and a fresh hook stroke"):return
        await touch(0);await touch(0);await touch(1)
        if not gate(s.machine_stopped and s.stage_checkpoint==3,"three deliberate repair strokes stop machine"):return
        if not gate(await go(1,Vector2(875,600)),"cat physically withdraws from stopped mechanism"):return
        if not gate(await go(2,s.CRADLE),"white returns to light cradle"):return
        await touch(2)
        if not gate(s.phase=="test" and not s.finished,"boss stop alone never ends story"):return
        await touch(0)
        if not gate(s.phase=="test" and s.machine_stopped and s.cleared_segments==3,"natural revisit of maintenance wheel cannot restart a repaired machine"):return
        if not gate(await go(0,s.TEST_PLATE),"girl reaches outgoing test plate"):return
        await aim(0,Vector2.RIGHT);await touch(0)
        if not gate(await go(2,s.TEST_SOURCE),"white reaches outgoing test source"):return
        await aim(2,Vector2.RIGHT);await touch(2);await frames(75)
        if not gate(not s.tested and s.outward_light,"outgoing beam stays inspectable without automatic acceptance"):return
        if not gate(await go(0,s.TEST_END),"girl walks to lit far receiver"):return
        await touch(0)
        if not gate(s.tested and s.phase=="release","normal interaction confirms physical outgoing result"):return
        await snapshot("-far-light-"+str(single))
        if not gate(await go(0,Vector2(1050,550)),"girl takes safe route around machine"):return
        if not gate(await go(0,s.ALIGHT),"girl reaches Alight send-light gate"):return
        await touch(0)
        if not gate(s.network_lit,"Alight releases repaired network only after verified test"):return
        for role in s.available_roles():
            if not gate(await go(role,Vector2(1120,600)),"all three reach real elevator"):return
        await touch(0)
        if not gate(s.phase=="farewell","elevator reaches playable farewell route"):return
        if not gate(await go(0,s.GRANNY),"girl can take optional memento from granny"):return
        await touch(0)
        if not await gather(s.PORTAL):return
        await touch(0);await touch(0);await touch(1)
        if not gate(s.phase=="home" and not s.finished,"both player positions confirm gathered portal into actual home"):return
        if not gate(await go(0,s.HOME_RACK),"girl stores adventure equipment at home"):return
        await touch(0)
        if not await gather(s.HOME_BOWL):return
        await touch(0)
        if not await gather(s.HOME_SOFA):return
        await touch(0)
        if not gate(s.finished and s.gear_stored and s.paws_clean,"home epilogue ends voluntarily with whole family"):return
        await saved()
        print("M27_FIVE_NORMAL_COMPLETE solo=",single," setbacks=",s.failed_sweeps)
    lobby.queue_free();await frames(4)
    print("M27_FIVE_PLAYTHROUGH: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
