extends "res://tests/m25_keyboard_driver.gd"
func run()->void:
    if not gate(OS.get_user_data_dir().ends_with("DuoduoCatsCourtyard-qa-m27-four"),"actual OS directory is isolated M27 four QA"):return
    print("M27_FOUR_QA_USERDIR ",OS.get_user_data_dir())
    Engine.time_scale=3
    lobby=load("res://main.tscn").instantiate();root.add_child(lobby);await frames(3);lobby.session.set_focus(true)
    lobby.story_chapter.record_prefix="qa-m27-four-"+str(Time.get_ticks_usec())
    for mode in [true,false]:
        await start(4,mode)
        if not gate(await go(1,s.HOOK),"black cat reaches market ring"):return
        await touch(1)
        if not gate(await go(2,s.MARKET_LIGHT),"white cat reaches safe lamp stand"):return
        await aim(2,Vector2(-1,-1));await touch(2)
        if not gate(s.market_beam,"real facing aims the stable light onto return planks"):return
        if not gate(await go(1,Vector2(295,450)),"black cat enters lower return route"):return
        if not gate(await go(1,Vector2(295,385)),"black cat traverses actual lit planks"):return
        await touch(1)
        if not gate(await go(1,Vector2(295,450)),"black cat returns carrying cover"):return
        if not gate(await go(1,s.CATCH),"cover arrives at safe catching bank"):return
        if not gate(await go(0,s.CATCH),"girl physically catches cover"):return
        await touch(0)
        if not gate(s.cloth,"successful recovery produces repair cloth"):return
        if not gate(await go(0,s.ALIGHT),"girl reaches Alight"):return
        await touch(0)
        if not gate(await go(2,s.DUCT_LIGHT),"white cat reaches testing duct"):return
        await aim(2,Vector2.UP);await touch(2)
        if not gate(await go(0,s.ARROWS),"girl reaches test handle"):return
        await send_trial()
        if not gate(s.main_return_seen and s.shell_leak_seen,"sent main pulse returns and leaks"):return
        await capture("main")
        await touch(0)
        if not gate(await go(1,s.BRANCH),"cat reaches reversible bypass latch"):return
        await touch(1)
        if not gate(await go(0,s.ARROWS),"girl returns to split control"):return
        await send_trial()
        if not gate(s.reserve_hold_seen and s.reserve_charge>0,"isolated split retains light in visible lamp"):return
        await capture("retained")
        if not gate(await go(0,s.ALIGHT),"party tries diagnosis before connected sample"):return
        await touch(0)
        if not gate(not s.battle_requested and not s.connected_split_seen,"main plus isolated split cannot skip connected observation"):return
        if not gate(await go(1,s.BRANCH),"cat reconnects retained reserve"):return
        await touch(1)
        if not gate(not s.connected_split_seen and s.reserve_charge==0,"reconnection drains stored light but does not fabricate sent sample"):return
        if not gate(await go(0,s.ARROWS),"girl returns for connected sample"):return
        await send_trial()
        if not gate(s.connected_split_seen and s.reserve_charge==0,"full connected sample visibly drains and records evidence"):return
        if not gate(await go(0,s.ALIGHT),"party returns to diagnose all three observed routes"):return
        await touch(0)
        if not await combat():return
        if not gate(await go(0,s.PATCH),"girl reaches outside patch"):return
        await touch(0)
        if not gate(await go(1,s.LATCH),"black cat uses hook on actual exterior latch"):return
        await touch(1)
        if not gate(await go(2,s.SEAM_LIGHT),"white cat reaches last seam lamp"):return
        await aim(2,Vector2(1,-1));await touch(2)
        if not gate(await go(0,s.PATCH),"girl follows observed seam"):return
        await touch(0)
        if not gate(s.phase=="test" and s.shell_fixed,"repair invites another experiment before second encounter"):return
        if not gate(await go(2,s.DUCT_LIGHT),"white cat returns to test light"):return
        await aim(2,Vector2.UP);await touch(2)
        if not gate(await go(0,s.ARROWS),"girl repeats same pulse with repaired shell"):return
        await send_trial()
        await capture("repaired")
        if not gate(s.inward_verified,"shell repair alone does not repair machine"):return
        if not gate(await go(0,s.ALIGHT),"Alight can offer real reserve lantern"):return
        await touch(0)
        if not await gather(s.HOME):return
        if not gate(await go(0,s.HOME),"girl approaches reserve lantern after party gathering"):return
        await touch(0)
        if not gate(s.reserve_retained,"Duoduo chooses help and retains reserve for the whole family"):return
        if not await combat():return
        if not gate(s.phase=="rest" and s.battles_finished==2,"last encounter protects choice and opens rest"):return
        if not await gather(s.REST):return
        if not gate(await go(0,s.REST),"girl approaches rest table after party gathering"):return
        await touch(0);await saved()
        print("M27_FOUR_NORMAL_COMPLETE solo=",single)
    print("M27_FOUR_PLAYTHROUGH: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)

func send_trial()->void:
    await select(0);tap_key(KEY_R if single else KEY_T);await frames(90)

func capture(label:String)->void:
    if DisplayServer.get_name()=="headless":return
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://four-"+label+("-solo" if single else "-dual")+".png")

func touch(role:int)->void:
    await super.touch(role)
    var restored=load("res://game/chapter_four_state.gd").new();restored.single=single
    gate(restored.restore_checkpoint(s.checkpoint()),"normal interaction remains a valid safe checkpoint")
