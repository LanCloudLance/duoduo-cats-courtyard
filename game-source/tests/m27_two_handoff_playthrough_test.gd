extends "res://tests/m25_keyboard_driver.gd"
func run()->void:
    if not gate(OS.get_user_data_dir().ends_with("DuoduoCatsCourtyard-qa-m27-two-handoff"),"actual OS user directory is isolated handoff QA"):return
    print("M27_TWO_HANDOFF_QA_USERDIR ",OS.get_user_data_dir())
    Engine.time_scale=3
    lobby=load("res://main.tscn").instantiate();root.add_child(lobby);await frames(3);lobby.session.set_focus(true)
    lobby.story_chapter.record_prefix="qa-m27-two-handoff-"+str(Time.get_ticks_usec())
    for mode in [true,false]:
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
        print("M27_TWO_HANDOFF_NORMAL_COMPLETE solo=",single)
    lobby.queue_free();await frames(4)
    print("M27_TWO_HANDOFF_PLAYTHROUGH: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
func tool_key(role:int)->void:
    await select(role);tap_key(KEY_R if single or role!=0 else KEY_T);await frames(40)
func touch(role:int)->void:
    await super.touch(role)
    var restored=load("res://game/chapter_two_state.gd").new();restored.single=single
    gate(restored.restore_checkpoint(s.checkpoint()),"each normal handoff interaction remains a valid safe checkpoint")
