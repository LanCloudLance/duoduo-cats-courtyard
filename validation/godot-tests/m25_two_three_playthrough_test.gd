extends "res://tests/m25_keyboard_driver.gd"
func run()->void:
    Engine.time_scale=3
    lobby=load("res://main.tscn").instantiate();root.add_child(lobby);await frames(3);lobby.session.set_focus(true)
    lobby.story_chapter.record_prefix="qa-m25-two-three-"+str(Time.get_ticks_usec())
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
        if not gate(await go(0,s.LAMP_B),"girl reaches midspan lamp"):return
        await touch(0);await touch(0)
        if not gate(await go(1,s.LATCH_B),"cat crosses correctly lit second lane"):return
        await touch(1)
        if not gate(s.locked_b and not s.hook_owned,"bridge solved before required claw hook reward"):return
        if not gate(await go(1,Vector2(795,555)),"cat exits low frame to right bank"):return
        if not gate(await go(1,s.BOX),"cat physically opens maintenance box"):return
        await touch(1)
        if not gate(await go(1,s.LOOP),"safe hook practice ring"):return
        await touch(1)
        if not gate(await go(1,s.SHORTCUT),"cat reaches shortcut pull ring"):return
        await touch(1)
        if not gate(await go(0,Vector2(800,420)),"girl crosses restored main bridge"):return
        for role in [0,1]:
            if not gate(await go(role,Vector2(1040,425)),"party crosses hook shortcut"):return
            if not gate(await go(role,s.WINDOW+Vector2(role*20,20)),"party gathers at low window"):return
        await touch(0)
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
        await touch(0)
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
        if not gate(s.bridge_locked,"combined cat lock and guide board create permanent crossing"):return
        await touch(2)
        if not gate(s.light_released,"white explicitly releases its held light"):return
        for role in s.available_roles():
            if not gate(await go(role,Vector2(670,425)),"three roles reach crossing start"):return
            if not gate(await go(role,Vector2(910,425)),"three roles cross permanent bridge"):return
        if not gate(await go(1,s.NARROW),"black cat uses hook on narrow passage"):return
        await touch(1)
        if not gate(await go(0,s.RIG),"girl builds stable search light rig"):return
        await touch(0)
        if not gate(await go(2,s.SEARCH_STAND),"white chooses search direction"):return
        await aim(2,Vector2.UP);await touch(2)
        for role in s.available_roles():
            if not gate(await go(role,Vector2(925,315)),"three roles approach revealed upper exit"):return
            if not gate(await go(role,s.MAP+Vector2(role*20,10)),"all three use actual revealed doorway to map"):return
        await touch(0)
        if not gate(s.finished,"recovered route map completes third chapter"):
            print("MAP_FAILED ",s.positions," phase=",s.phase," message=",s.message," release=",s.light_released);return
        await saved()
        print("M25_TWO_THREE_NORMAL_COMPLETE solo=",single)
    lobby.queue_free();await frames(4)
    print("M25_TWO_THREE_PLAYTHROUGH: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
