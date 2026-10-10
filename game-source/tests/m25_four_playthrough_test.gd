extends "res://tests/m25_keyboard_driver.gd"
func run()->void:
    Engine.time_scale=3
    lobby=load("res://main.tscn").instantiate();root.add_child(lobby);await frames(3);lobby.session.set_focus(true)
    lobby.story_chapter.record_prefix="qa-m25-four-"+str(Time.get_ticks_usec())
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
        if not gate(await go(1,s.BRANCH),"black cat reaches actual jam evidence"):return
        await touch(1)
        if not gate(await go(0,s.ARROWS),"girl inspects recovery direction"):return
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
        if not await combat():return
        if not gate(await go(0,s.ARROWS),"girl tests fixed shell against actual inward flow"):return
        await touch(0)
        if not gate(s.inward_verified,"shell repair alone does not repair machine"):return
        if not gate(await go(0,s.ALIGHT),"Alight can offer real reserve lantern"):return
        await touch(0)
        if not await gather(s.HOME):return
        await touch(0)
        if not gate(s.reserve_retained,"Duoduo chooses help and retains reserve for the whole family"):return
        if not await gather(s.REST):return
        await touch(0);await saved()
        print("M25_FOUR_NORMAL_COMPLETE solo=",single)
    print("M25_FOUR_PLAYTHROUGH: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
