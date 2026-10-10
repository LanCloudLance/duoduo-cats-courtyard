extends "res://tests/m27_mainline_playthrough_test.gd"
func run()->void:
    print("M27_ONE_TOOLS_USERDIR ",OS.get_user_data_dir())
    if not gate(OS.get_user_data_dir().get_file()=="DuoduoCatsCourtyard-qa-m27-regression","isolated actual tool QA namespace"):return
    Engine.time_scale=3
    lobby=load("res://main.tscn").instantiate();root.add_child(lobby);await frames(3);lobby.session.set_focus(true)
    lobby.chapter_one.record_prefix="qa-m27-one-tools-"+str(Time.get_ticks_msec())
    await click_entry("ChapterOneSolo")
    c=lobby.chapter_one;s=c.state;single=true
    if not gate(lobby.stage=="chapter-one" and s.phase=="arrival","normal selected chapter input starts a fresh test run"):return
    if not gate(await go(0,s.GRANNY+Vector2(0,55)),"girl walks to granny"):return
    await touch(0)
    if not gate(s.equipment and s.phase=="road","equipment comes from actual meeting"):return
    if not gate(await go(0,s.LIFT),"girl walks to load handle"):return
    tap_key(KEY_R);await frames(2)
    check(s.bracing and s.hint_level==0,"tool key performs the physical brace without requesting a hint")
    check(c.actors[0].motion_kind=="brace","physical brace supplies a continuing actor pose")
    var cat_before:Vector2=s.positions[1]
    key_event(KEY_D,true);tap_key(KEY_TAB);await frames(3);key_event(KEY_D,false)
    check(s.controlled==1 and s.positions[1].x>cat_before.x,"held movement survives role handoff into the cat")
    check(s.bracing,"role handoff keeps the girl's declared load hold")
    var old_positions:Array=s.positions.duplicate();tap_key(KEY_G);await frames(2)
    check(s.hint_level==1 and s.bracing and s.positions==old_positions,"hint first tier leaves apparatus and actors unchanged")
    if not gate(await go(1,s.FORK),"cat reaches movable support"):return
    tap_key(KEY_R);await frames(2)
    check(s.carrier==1 and s.hint_level==1,"cat tool picks up support instead of consuming another hint")
    check(c.actors[1].motion_kind=="inspect","cat pickup supplies the claw interaction pose")
    await cleanup_mainline()
    print("M27_ONE_TOOLS_INPUT: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
