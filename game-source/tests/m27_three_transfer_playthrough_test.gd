extends "res://tests/m25_keyboard_driver.gd"
func run()->void:
    if not gate(OS.get_user_data_dir().ends_with("DuoduoCatsCourtyard-qa-m27-three-transfer"),"actual OS user directory is isolated transfer QA"):return
    print("M27_THREE_TRANSFER_QA_USERDIR ",OS.get_user_data_dir())
    Engine.time_scale=3
    lobby=load("res://main.tscn").instantiate();root.add_child(lobby);await frames(3);lobby.session.set_focus(true)
    lobby.story_chapter.record_prefix="qa-m27-three-transfer-"+str(Time.get_ticks_usec())
    for mode in [true,false]:
        await start(3,mode)
        if not gate(await go(1,s.DUCT),"cat reaches outside-only service duct"):return
        await touch(1)
        if not gate(await go(1,s.DOOR_LAMP),"cat delivers external spare wick"):return
        await touch(1)
        if not gate(await go(0,s.DOOR_LAMP),"girl fits and turns door light"):return
        await touch(0);await touch(0)
        if not gate(await go(0,s.WINDOW),"girl reaches window to cue indoor NPC"):return
        await touch(0);await frames(50)
        if not gate(s.door_open and not s.joined,"explicit cue opens real door before white control unlock"):return
        for role in [0,1]:
            if not gate(await go(role,Vector2(410,425)),"approach actual open doorway"):return
            if not gate(await go(role,s.REUNION+Vector2(role*15,0)),"party passes real door to reunion"):return
        if not gate(await go(0,s.REUNION),"girl steps close to greet both cats"):return
        await touch(0)
        print("THREE_REUNION_STATE ",s.positions," joined=",s.joined," message=",s.message)
        if not gate(s.joined,"reunion unlocks third role only here"):return
        if not gate(await go(0,s.EQUIPMENT),"girl equips local fixed-light device"):return
        await touch(0)
        if not gate(await go(2,s.LIGHT_STAND),"white cat chooses light stand"):return
        await aim(2,Vector2.RIGHT);await touch(2)
        if not gate(await go(1,Vector2(665,425)),"black cat finds light walkway approach"):return
        if not gate(await go(1,s.LOCK),"black cat walks true lit temporary bridge"):return
        await touch(1)
        if not gate(await go(0,s.BOARD),"girl adjusts actual guide board"):return
        await touch(0)
        if not gate(s.cat_lock and not s.bridge_locked,"direct light cannot power high receiver despite correctly turned board"):return
        await tool_key(2)
        if not gate(s.cat_lock and not s.beam_held and s.positions[1].x<700,"release preserves fine lock and returns cat safely"):return
        await aim(2,Vector2.DOWN);await touch(2)
        if not gate(not s.bridge_locked,"wrong source direction cannot lock bridge"):return
        await tool_key(2);await aim(2,Vector2.UP);await touch(2)
        if not gate(s.bridge_locked,"redirecting same source through mirror locks permanent bridge"):return
        await touch(2)
        if not gate(s.light_released,"white explicitly releases its held light"):return
        if not gate(await go(0,s.EQUIPMENT),"girl revisits rack after fixing bridge"):return
        await touch(0)
        if not gate(s.phase=="exit","equipped rack preserves fixed bridge stage"):return
        if not gate(c.read_record().get("phase")=="exit","rack revisit disk checkpoint retains fixed bridge milestone"):return
        for role in s.available_roles():
            if not gate(await go(role,Vector2(670,425)),"three roles reach crossing start"):return
            if not gate(await go(role,Vector2(910,425)),"three roles cross permanent bridge"):return
        if not gate(await go(1,s.NARROW),"cat opens real exit alcove maintenance ring"):return
        await touch(1)
        if not gate(await go(0,s.RIG),"girl installs exit low mirror support"):return
        await touch(0);await touch(0)
        if not gate(await go(2,s.SEARCH_STAND),"white reaches two-height source stand"):return
        await aim(2,Vector2.UP);await touch(2)
        if not gate(not s.exit_low_latched and not s.exit_high_latched and not s.search_beam_active(),"wrong source facing leaves both receivers dark"):return
        await tool_key(2);await aim(2,Vector2.RIGHT);await touch(2)
        if not gate(not s.exit_low_latched and s.transfer_trace().misses.size()>0,"wrong low mirror emits visible miss without progress"):return
        if not gate(await go(0,s.RIG),"girl revisits low mirror to correct miss"):return
        await touch(0)
        if not gate(s.exit_low_latched and not s.exit_high_latched and not s.exit_revealed,"low geometry locks only first receiver"):return
        if not gate(c.read_record().get("facts",{}).get("exit_low_latched",false) and not c.read_record().get("facts",{}).get("exit_high_latched",true),"real disk save retains only witnessed first lock"):return
        if not gate(await go(0,s.SEARCH_STAND),"girl reaches source height control while white holds"):return
        await touch(0)
        if not gate(s.source_level==1 and not s.beam_held and s.actions[2]=="" and s.exit_low_latched,"height change safely interrupts source while keeping first lock"):return
        if not gate(s.positions[2].distance_to(s.SEARCH_STAND)<70,"white remains on fixed source bank after height change"):return
        await aim(2,Vector2.RIGHT);await touch(2)
        if not gate(not s.exit_high_latched and s.transfer_trace().backfaces.size()>0,"raised source visibly scrapes receiver back without granting second lock"):return
        if not gate(await go(0,s.RIG),"girl follows raised wrong ray to low mirror"):return
        await touch(0)
        if not gate(not s.exit_high_latched and s.transfer_trace().misses.size()>0,"changed low mirror reaches high mirror but wrong upper angle still misses"):return
        if not gate(await go(1,s.HIGH_RING),"cat physically reaches high mirror hook ring"):return
        await touch(1)
        if not gate(s.exit_high_latched and s.exit_revealed and s.phase=="map","high mirror correction lights second front and opens permanent exit"):return
        await tool_key(2)
        if not gate(not s.beam_held and s.exit_revealed,"explicit release leaves both permanent locks intact"):return
        for role in s.available_roles():
            if not gate(await go(role,Vector2(925,315)),"three roles approach opened upper exit"):return
            if not gate(await go(role,s.MAP+Vector2(role*20,10)),"three roles cross actual exit to map"):return
        if not gate(await go(0,s.MAP),"girl approaches map after companion travel"):return
        await touch(0)
        if not gate(s.finished,"two new geometries still lead to original chapter completion"):return
        await saved()
        print("M27_THREE_TRANSFER_NORMAL_COMPLETE solo=",single)
    lobby.queue_free();await frames(4)
    print("M27_THREE_TRANSFER_PLAYTHROUGH: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
func tool_key(role:int)->void:
    await select(role);tap_key(KEY_R if single or role!=0 else KEY_T);await frames(40)
func touch(role:int)->void:
    await super.touch(role)
    var restored=load("res://game/chapter_three_state.gd").new();restored.single=single
    gate(restored.restore_checkpoint(s.checkpoint()),"each normal interaction restores a legal checkpoint without inventing facts")
