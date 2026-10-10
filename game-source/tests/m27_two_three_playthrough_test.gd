extends "res://tests/m25_keyboard_driver.gd"
func run()->void:
    if not gate(OS.get_user_data_dir().ends_with("DuoduoCatsCourtyard-qa-m27-two-three"),"actual OS user directory matches isolated M27 two-three QA"):return
    print("M27_TWO_THREE_QA_USERDIR ",OS.get_user_data_dir())
    Engine.time_scale=3
    lobby=load("res://main.tscn").instantiate();root.add_child(lobby);await frames(3);lobby.session.set_focus(true)
    lobby.story_chapter.record_prefix="qa-m27-two-three-"+str(Time.get_ticks_usec())
    for mode in ([false] if "--dual-only" in OS.get_cmdline_user_args() else [true,false]):
        await start(2,mode)
        if not gate(await go(0,s.LAMP_A),"girl reaches first guide lamp"):return
        await touch(0)
        if not gate(await go(0,s.WINCH_A),"girl reaches first winch"):return
        await touch(0)
        if not gate(await go(1,Vector2(420,560)),"cat finds low inspection route"):return
        if not gate(await go(1,s.LATCH_A),"cat physically walks supported first lane"):return
        await touch(1)
        if not gate(s.locked_a,"first unloaded latch locks bridge checkpoint"):return
        if not gate(await go(0,s.WINCH_B),"girl crosses permanent first platform"):return
        await touch(0)
        if not gate(not s.lifted_b,"empty rear socket refuses to raise leaf"):return
        if not gate(await go(0,s.WINCH_A),"girl returns to unloaded prop"):return
        await tool_key(0)
        if not gate(s.support_site=="carried" and s.locked_a,"tool recovers unloaded support without dropping first bridge"):return
        if not gate(await go(0,s.WINCH_B),"same support crosses permanent first bridge"):return
        if not gate(await go(1,s.WINCH_B),"cat uses fixed short stairs to meet girl at empty rear socket"):return
        await touch(1)
        if not gate(s.support_site=="cat_carried" and not s.lifted_b,"safe handoff teaches real cat carrying before loaded transfer"):return
        if not gate(await go(0,s.BRACE_B),"girl tries empty rear load before first installation"):return
        await touch(0)
        if not gate(not s.rear_braced() and not s.rear_loaded_seen,"first handoff cannot skip actual rear support loading"):return
        await touch(1)
        if not gate(await go(0,s.WINCH_B),"girl reaches rear winch after safe practice"):return
        await touch(0)
        if not gate(s.support_site=="b" and s.lifted_b,"same prop supports raised rear leaf"):return
        await touch(1)
        if not gate(s.support_site=="b","cat cannot remove weight-loaded rear prop"):return
        if not gate(await go(0,s.LAMP_B),"girl reaches midspan lamp"):return
        await touch(0);await touch(0)
        if not gate(await go(0,s.BRACE_B),"girl approaches distinct lower load handle"):return
        await touch(0)
        if not gate(s.rear_braced(),"girl explicitly takes weight before role switch"):return
        if not gate(await go(1,s.WINCH_B),"cat reaches newly unloaded prop"):return
        await touch(1)
        if not gate(s.support_site=="cat_carried" and s.rear_braced(),"same physical prop transfers to cat while girl remains braced"):return
        if not gate(await go(1,Vector2(585,555)),"carrier goes down short fixed stairs"):return
        if not gate(await go(1,Vector2(675,555)),"carrier enters lit rear inspection track"):return
        if not gate(await go(0,Vector2(565,465)),"girl deliberately moves off load hold"):return
        if not gate(not s.rear_braced() and s.positions[1].x<615 and s.support_site=="cat_carried","moving holder safely returns cat and unique prop to fixed platform"):return
        if not gate(await go(0,s.BRACE_B),"girl resumes from nearby safe load handle"):return
        await touch(0)
        if not gate(s.rear_braced(),"brace resumes without forcing prop back into rear socket"):return
        if not gate(await go(1,Vector2(585,555)),"carrier returns via fixed stairs after recovery"):return
        if not gate(await go(1,s.LATCH_B),"cat brings actual prop along lit track to far socket"):return
        await touch(1)
        if not gate(s.support_site=="far" and not s.rear_braced(),"far socket takes permanent weight and releases girl"):return
        if not gate(s.locked_b and not s.hook_owned,"bridge solved before required claw hook reward"):return
        if not gate(await go(1,Vector2(795,555)),"cat exits low frame to right bank"):return
        if not gate(await go(1,s.BOX),"cat physically opens maintenance box"):return
        await touch(1)
        if not gate(await go(1,s.LOOP),"safe hook practice ring"):return
        await touch(1)
        if not gate(await go(1,s.SHORTCUT),"cat reaches shortcut pull ring"):return
        await touch(1)
        if not gate(await go(1,Vector2(795,555)),"cat naturally returns to rear inspection bank"):return
        if not gate(await go(1,s.LATCH_B),"cat revisits completed rear bridge latch"):return
        await touch(1)
        if not gate(s.phase=="window" and s.shortcut_open,"rear latch revisit preserves later window milestone"):return
        if not gate(c.read_record().get("phase")=="window","rear latch revisit keeps disk checkpoint at window"):return
        if not gate(await go(1,Vector2(795,555)),"cat leaves revisited bridge latch"):return
        if not gate(await go(0,Vector2(800,420)),"girl crosses restored main bridge"):return
        for role in [0,1]:
            if not gate(await go(role,Vector2(1040,425)),"party crosses hook shortcut"):return
            if not gate(await go(role,s.WINDOW+Vector2(role*20,20)),"party gathers at low window"):return
        if not gate(await go(0,s.WINDOW),"girl deliberately approaches window after companion travel"):return
        await touch(0)
        print("TWO_WINDOW_STATE ",s.positions," phase=",s.phase," finished=",s.finished," joined=",s.joined," message=",s.message," stage=",lobby.stage)
        if not gate(s.finished and not s.joined,"seeing safe white NPC does not prematurely unlock control"):return
        await saved()
        # Actual completion input advances directly to chapter three.
        await touch(0);await frames(3);s=c.state
        if not gate(s.chapter==3 and lobby.stage=="story-chapter","normal chapter-two completion input continues to reunion chapter"):return
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
        if not gate(await go(0,Vector2(910,425)),"girl returns from revealed exit to bridge bank"):return
        if not gate(await go(0,Vector2(670,425)),"girl crosses back over permanent bridge"):return
        if not gate(await go(0,s.EQUIPMENT),"girl naturally revisits equipped rack at map stage"):return
        await touch(0)
        if not gate(s.phase=="map" and s.exit_revealed,"rack revisit preserves revealed exit and map milestone"):return
        if not gate(c.read_record().get("phase")=="map","map-stage rack revisit disk checkpoint remains map"):return
        if not gate(await go(0,Vector2(670,425)),"girl returns to crossing after rack revisit"):return
        if not gate(await go(0,Vector2(910,425)),"girl crosses back toward revealed exit"):return
        for role in s.available_roles():
            if not gate(await go(role,Vector2(925,315)),"three roles approach revealed upper exit"):return
            if not gate(await go(role,s.MAP+Vector2(role*20,10)),"all three use actual revealed doorway to map"):return
        if not gate(await go(0,s.MAP),"girl approaches map after companion follow movement"):return
        await touch(0)
        if not gate(s.finished,"recovered route map completes third chapter"):
            print("MAP_FAILED ",s.positions," phase=",s.phase," message=",s.message," release=",s.light_released);return
        await saved()
        print("M27_TWO_THREE_NORMAL_COMPLETE solo=",single)
    lobby.queue_free();await frames(4)
    print("M27_TWO_THREE_PLAYTHROUGH: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)

func tool_key(role:int)->void:
    await select(role);tap_key(KEY_R if single or role!=0 else KEY_T);await frames(40)

func touch(role:int)->void:
    await super.touch(role)
    var restored=load("res://game/chapter_two_state.gd" if s.chapter==2 else "res://game/chapter_three_state.gd").new();restored.single=single
    gate(restored.restore_checkpoint(s.checkpoint()),"normal interaction remains a valid safe checkpoint")
