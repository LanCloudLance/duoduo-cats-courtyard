extends "res://tests/m25_keyboard_driver.gd"
func run()->void:
    Engine.time_scale=3
    lobby=load("res://main.tscn").instantiate();root.add_child(lobby);await frames(3);lobby.session.set_focus(true)
    lobby.story_chapter.record_prefix="qa-m25-five-"+str(Time.get_ticks_usec())
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
        await touch(0)
        if not gate(s.phase=="shield","gathered party enters repair boss through normal input"):return
        # Position cat safely first, then time girl's facing shield using visible cycle.
        if not gate(await go(1,Vector2(800,575)),"cat reaches lower maintenance slot safely"):return
        if not gate(await go(0,s.SHIELD_SLOT),"girl reaches shield slot"):return
        await aim(0,Vector2(1,-1))
        for i in range(250):
            var cycle:float=fmod(s.boss_clock,4.6)
            if cycle>.55 and cycle<1.45:break
            await frames(1)
        key_event(KEY_G,true)
        for i in range(180):
            if s.arm_arrest>0:break
            await frames(1)
        key_event(KEY_G,false)
        if not gate(s.arm_arrest>0,"normal timed directional shield arrests moving mechanical arm"):return
        if not gate(await go(1,s.ARM_LOCK),"cat approaches arrested arm before timeout"):return
        await touch(1)
        if not gate(s.phase=="lure" and s.stage_checkpoint==1,"hook input preserves first repair checkpoint"):return
        if not gate(await go(2,s.AIM_STAND),"white reaches buffer light operator"):return
        await aim(2,Vector2.RIGHT);await touch(2)
        if not gate(await go(0,Vector2(1070,550)),"girl goes around actual machine body"):return
        if not gate(await go(0,s.WHEEL),"girl reaches outside wheel"):return
        await touch(0);await frames(65)
        if not gate(s.phase=="unjam" and s.lid_open,"aimed lure and wheel hold open maintenance cover"):return
        if not gate(await go(2,s.CRADLE),"white brings beam to independent safety cradle"):return
        await touch(2)
        if not gate(await go(1,s.REPAIR_SLOT),"black cat enters actual open low repair slot"):return
        await touch(1)
        await touch(0);await frames(70)
        if not gate(s.machine_stopped and s.stage_checkpoint==3,"real wheel and hook holds free jam in permanent ratchet stages"):return
        if not gate(await go(1,Vector2(875,600)),"cat physically withdraws from stopped mechanism"):return
        if not gate(await go(2,s.CRADLE),"white returns to light cradle"):return
        await touch(2)
        if not gate(s.phase=="test" and not s.finished,"boss stop alone never ends story"):return
        if not gate(await go(0,s.TEST_PLATE),"girl reaches outgoing test plate"):return
        await aim(0,Vector2.RIGHT);await touch(0)
        if not gate(await go(2,s.TEST_SOURCE),"white reaches outgoing test source"):return
        await aim(2,Vector2.RIGHT);await touch(2);await frames(75)
        if not gate(s.tested and s.outward_light,"physical outgoing light remains outside for real test duration"):return
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
        print("M25_FIVE_NORMAL_COMPLETE solo=",single," setbacks=",s.failed_sweeps)
    lobby.queue_free();await frames(4)
    print("M25_FIVE_PLAYTHROUGH: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
