extends SceneTree
const Prologue=preload("res://game/prologue_state.gd")
const One=preload("res://game/chapter_one_state.gd")
const Two=preload("res://game/chapter_two_state.gd")
const Three=preload("res://game/chapter_three_state.gd")
const Four=preload("res://game/chapter_four_state.gd")
const Five=preload("res://game/chapter_five_state.gd")
const Legacy=preload("res://game/puzzle_legacy_checkpoint.gd")
var saved_cases:Dictionary={}
var checks:=0
var failed:=0
func check(ok:bool,label:String)->void:
    checks+=1
    if not ok:failed+=1;print("FAIL ",label)
func use(s,role:int,point:Vector2,tool:=false)->void:
    s.positions[role]=point;s.action_time[role]=0
    if tool:s.tool(role)
    else:s.interact(role)
func dialog(s)->void:
    if s.has_method("social_transition_active"):
        for i in range(240):
            if not s.social_transition_active():break
            s.step(0.05,Vector2.ZERO,Vector2.ZERO,true)
    while s.dialogue_active():s.advance_dialogue()
func ticks(s,count:=40)->void:
    for i in range(count):s.step(0.05,Vector2.ZERO,Vector2.ZERO,true)
func roundtrip(s,label:String)->void:
    var fresh=s.get_script().new();fresh.single=s.single
    check(fresh.restore_checkpoint(s.checkpoint()),label+" saved dependencies")
    saved_cases[label+str(checks)]={"path":s.get_script().resource_path,"solo":s.single,"record":s.checkpoint()}
func _init()->void:
    if not OS.get_user_data_dir().ends_with("DuoduoCatsCourtyard-qa-m28-puzzle"):push_error("wrong userdir");quit(2);return
    early()
    for solo in [true,false]:
        bridge(solo,false);bridge(solo,true)
        cart_window_route(solo)
        optics(solo,false);optics(solo,true)
        comparison(solo,false);comparison(solo,true)
        repair(solo,0,false);repair(solo,1,true)
        unloading_hold(solo)
        unloading_transfer(solo,false);unloading_transfer(solo,true)
    home()
    saves()
    print("M28_PUZZLE_RULES ",checks," checks / ",failed," failures; state fixtures, not natural-input acceptance")
    quit(1 if failed else 0)
func early()->void:
    var p=Prologue.new();use(p,0,p.SOFA_BALL)
    check(not p.ball_found,"girl cannot retrieve under-sofa discovery")
    use(p,1,p.SOFA_BALL);check(p.ball_found and p.presentation().discoveries==["prologue_ball"],"cat obtains actual optional ball")
    var before=p.positions.duplicate();p.step(.05,Vector2.RIGHT,Vector2.ZERO,true)
    check(p.positions==before and p.dialogue_active(),"dialogue freezes physical scene until confirmed")
    dialog(p);roundtrip(p,"ball")
    var one=One.new();one.enter_station();one.core_found=true;one.core_ready=true;one.core_installed=true;one.lit=true;one.phase="rest"
    use(one,1,one.PILLOW);one.facing[0]=Vector2.RIGHT;use(one,0,one.NIGHT_LAMP);use(one,1,one.NIGHT_LAMP)
    check(not one.night_lit,"wrong windward cloth placement has different result")
    one.facing[0]=Vector2.LEFT;use(one,0,one.NIGHT_LAMP)
    check(one.night_lit and not one.nightlight_taken,"repairing optional lamp does not invent gifted souvenir")
    use(one,0,one.GRANNY);check(not one.nightlight_taken and one.social_transition_active(),"gift waits for visible handover")
    dialog(one);check(one.nightlight_taken,"granny actually hands over repaired lamp");roundtrip(one,"nightlight")
func bridge(solo:bool,outer:bool)->void:
    var s=Two.new();s.single=solo
    use(s,1,s.LATCH_A);check(not s.locked_a,"unloaded hypothesis cannot skip first bridge")
    use(s,0,s.WINCH_A);use(s,0,s.LAMP_A);use(s,1,s.LATCH_A)
    check(s.locked_a,"front bridge takes weight")
    use(s,0,s.WINCH_A,true);check(s.support_site=="carried","only physical prop removed after permanent lock")
    if outer:
        use(s,0,s.OUTER_BENCH);check(s.support_site=="outer" and s.walkable(Vector2(680,620),1),"outer platform bears cat path")
        check(not s.walkable(Vector2(680,620),0),"outer plank is not a human bypass")
        s.positions[1]=Vector2(680,620);use(s,0,s.OUTER_BENCH)
        check(s.support_site=="outer","loaded outer prop cannot be pulled under traveler")
        use(s,1,s.OUTER_RATCHET);use(s,1,s.OUTER_BENCH)
        check(s.outer_locked and s.support_site=="cat_carried","outer ratchet permanently takes load and releases unique pin")
        check(s.walkable(Vector2(745,555),1) and s.walkable(Vector2(745,600),1),"outer end ladder connects to rear lock")
        use(s,1,Vector2(745,555))
        check(s.locked_b and s.lamp_b==0,"outer plan solves without short-route lighting")
    else:
        s.positions[0]=s.WINCH_B;use(s,1,s.WINCH_B);use(s,1,s.WINCH_B)
        use(s,0,s.WINCH_B);use(s,0,s.LAMP_B);use(s,0,s.LAMP_B)
        use(s,1,s.WINCH_B);check(s.support_site=="b","weight-loaded short route pin cannot be removed")
        use(s,0,s.BRACE_B);s.switch_actor();use(s,1,s.WINCH_B)
        check(s.rear_braced() and s.support_site=="cat_carried","manual role handoff preserves girl's actual hold")
        use(s,1,s.LATCH_B);check(s.locked_b and not s.outer_locked,"short illuminated plan has independent solution")
    use(s,1,s.BOX);use(s,1,s.SHORTCUT)
    check(s.shortcut_open,"hook can immediately operate real latch without practice checkbox")
    use(s,1,s.CART_HOOK);check(s.cart_open and s.presentation().discoveries.has("two_cart"),"optional freight route opens actual geometry")
    check(s.walkable(Vector2(965,610),0),"freight discovery creates useful human travel route")
    roundtrip(s,"two plans")
func optics(solo:bool,high_first:bool)->void:
    var s=Three.new();s.single=solo;s.restore_complete();s.finished=false;s.phase="exit";s.exit_low_latched=false;s.exit_high_latched=false;s.exit_revealed=false
    s.source_level=1;s.rig_angle=0;s.high_mirror_angle=0;s.beam_held=true;s.beam_direction=Vector2.RIGHT;s.positions[2]=s.SEARCH_STAND;s.actions[2]="light"
    check(not s.transfer_trace().low and not s.transfer_trace().high,"slant setting does not falsely activate either receiver")
    use(s,0,s.MAP_BACK);check(not s.map_discovered,"low paper rubbing needs cat reach")
    use(s,1,s.MAP_BACK);check(s.map_discovered,"wrong-for-door light yields useful old-map discovery")
    s.beam_held=false;use(s,1,s.MAP_BACK);check(s.map_discovered,"read paper survives withdrawing temporary light")
    s.beam_held=true;s.actions[2]="light"
    for high in ([true,false] if high_first else [false,true]):
        s.source_level=1 if high else 0;s.rig_angle=1 if high else 0;s.high_mirror_angle=1;s.update_exit()
    check(s.exit_low_latched and s.exit_high_latched and s.exit_revealed,"real optical receivers work in either order")
    s.beam_held=false;check(s.walkable(Vector2(990,305),0),"optical locks survive source withdrawal")
    roundtrip(s,"optics")
func walk_route(s,role:int,points:Array)->bool:
    for destination in points:
        for frame in range(500):
            if s.positions[role].distance_to(destination)<0.1:break
            var before:Vector2=s.positions[role]
            s.move(role,before.direction_to(destination)*minf(5.0,before.distance_to(destination)))
            if s.positions[role]==before:return false
        if s.positions[role].distance_to(destination)>=0.1:return false
    return true
func cart_window_route(solo:bool)->void:
    var s=Two.new();s.single=solo
    use(s,0,s.WINCH_A);use(s,0,s.LAMP_A);use(s,1,s.LATCH_A)
    use(s,0,s.WINCH_A,true);use(s,0,s.OUTER_BENCH);use(s,1,s.OUTER_RATCHET);use(s,1,s.OUTER_BENCH);use(s,1,Vector2(745,555));use(s,1,s.BOX)
    use(s,1,s.CART_HOOK)
    check(s.phase=="window" and s.cart_open and not s.shortcut_open and not s.hook_practiced,"cart opens independent window route without granting upper bridge or practice")
    roundtrip(s,"cart route open")
    s.positions[0]=Vector2(815,420)
    for role in [0,1]:check(walk_route(s,role,[Vector2(930,610),Vector2(965,610)]),"actual feet cross onto freight bank with upper bridge closed")
    roundtrip(s,"cart bank crossing")
    var restored=Two.new();restored.single=solo
    check(restored.restore_checkpoint(s.checkpoint()) and restored.positions[0]==s.positions[0] and restored.positions[1]==s.positions[1],"cart bank restore keeps legitimate crossing positions")
    for role in [0,1]:check(walk_route(s,role,[Vector2(1020,610),Vector2(1100,610),s.WINDOW]),"actual feet reach window by lower bank and east stairs")
    check(s.all_near(s.WINDOW) and s.target(0)=="window","cart travelers gather at real window hotspot")
    roundtrip(s,"cart window arrival")
    s.action_time[0]=0;s.interact(0)
    check(s.finished and not s.shortcut_open and not s.hook_practiced,"lower-route window completes without touching optional upper bridge")
    roundtrip(s,"cart only complete")
    var bad:Dictionary=s.checkpoint();bad.facts.cart_open=false
    var before:Dictionary=restored.checkpoint()
    check(not restored.restore_checkpoint(bad) and restored.checkpoint()==before,"unearned route completion save is rejected without mutation")
    bad=s.checkpoint();bad.positions[0]=[960,425]
    check(restored.restore_checkpoint(bad) and restored.walkable(restored.positions[0],0) and restored.positions[0].x>995 and not restored.shortcut_open,"invalid upper-bridge position restores to safe reachable window shore without opening bridge")
func four_fixture(solo:bool):
    var s=Four.new();s.single=solo;s.cover_hooked=true;s.cloth=true;s.phase="investigate"
    use(s,0,s.VIEW_DOOR);dialog(s);use(s,0,s.PATCH);use(s,0,s.VIEW_DOOR);dialog(s);s.facing[2]=Vector2.UP;use(s,2,s.DUCT_LIGHT)
    return s
func pulse(s)->void:
    use(s,0,s.ARROWS,true);ticks(s,27)
func comparison(solo:bool,reconnect:bool)->void:
    var s=four_fixture(solo)
    check(s.early_patch and s.shell_examined and not s.shell_fixed,"cloth can reveal partial wind effect before full diagnosis")
    if not reconnect:pulse(s)
    use(s,0,s.ARROWS);use(s,1,s.BRANCH);pulse(s)
    check(s.reserve_hold_seen and s.reserve_available,"isolated branch keeps a real independent lamp")
    if reconnect:
        use(s,1,s.BRANCH)
        check(s.reconnected_seen and not s.connected_split_seen and not s.main_return_seen,"reconnect comparison records observed drain, not extra test checkboxes")
        check(s.diagnosis_ready(),"isolated plus reconnect is sufficient causal comparison")
    else:
        check(s.diagnosis_ready() and not s.connected_split_seen,"main plus isolated needs no connected-sample checklist")
        use(s,0,s.STALL_LAMP);check(not s.stall_seen,"lamp is not fabricated at a distant destination")
        use(s,0,s.RESERVE);use(s,0,s.MARKET_DOOR);dialog(s);
        check(s.room_name()=="market" and s.target(0)!="阿灯","door enters actual market room; no remote machine hotspot")
        use(s,0,s.STALL_LAMP)
        check(s.stall_seen and s.lamp_dest=="stall","girl carries retained lamp to merchant")
        use(s,0,s.STALL_LAMP);use(s,0,s.MARKET_DOOR);dialog(s);use(s,0,s.VIEW_DOOR);dialog(s);use(s,0,s.VIEW_LAMP)
        check(s.view_seen and s.lamp_dest=="view" and s.presentation().discoveries.size()==2,"same lamp can be moved to a second meaningful destination")
    roundtrip(s,"free experiment")
    if not s.visit_room.is_empty():use(s,0,s.VIEW_DOOR);dialog(s)
    use(s,0,s.ALIGHT);check(s.battle_requested and s.phase=="battle_one","sufficient comparison advances story")
    roundtrip(s,"experiment consequence")
func shield_fixture(solo:bool):
    var s=Five.new();s.single=solo;s.route_lock=true;s.route_supported=true;s.route_lit=true;s.bridge_locked=true;s.phase="shield"
    s.positions.assign([Vector2(610,560),Vector2(675,595),Vector2(575,620)])
    return s
func repair(solo:bool,plan:int,right_first:bool)->void:
    var s=shield_fixture(solo)
    if plan==1:
        use(s,1,s.PREP_LATCH);check(not s.far_walkway,"far platform does not latch under weight")
        use(s,0,s.PREP_HANDLE);s.switch_actor();use(s,1,s.PREP_LATCH)
        check(s.far_walkway and not s.prep_held,"explicit co-op raises and permanently locks outside platform")
        use(s,0,s.FAR_SLOT)
    else:use(s,0,s.SHIELD_SLOT)
    s.positions[0]=s.selected_slot();s.facing[0]=s.positions[0].direction_to(s.MACHINE);s.guard(0,true);ticks(s,37)
    check(s.arm_arrest>0,"chosen slot arrests actual moving arm")
    use(s,1,s.selected_lock());check(s.arm_locked and s.phase=="lure","cat permanently latches selected repair plan")
    check(s.walkable(Vector2(700,430),1)==(plan==1),"repair plan changes actual short-route geometry")
    for role in [0,1,2]:
        var start:Vector2=s.positions[role];s.positions[role]=Vector2(630,435)
        check(walk_route(s,role,[Vector2(735,435),Vector2(735,478),Vector2(1070,478),s.WHEEL])==(plan==1),"far plan physically crosses machine front to wheel before worklight; near plan blocks through route")
        s.positions[role]=Vector2(630,435)
        check(walk_route(s,role,[Vector2(630,550),Vector2(1070,550),s.WHEEL]),"south detour stays available in either repair plan")
        s.positions[role]=start
    check(not s.walkable(s.REPAIR_SLOT,0) and not s.walkable(s.REPAIR_SLOT,1),"front catwalk does not permit entering dark repair recess")
    for route in ([2,1] if right_first else [1,2]):
        s.facing[2]=Vector2.UP if route==2 else Vector2.RIGHT;use(s,2,s.AIM_STAND);use(s,0,s.WHEEL)
    check(s.lid_open,"two pressure pins release in either order")
    use(s,2,s.CRADLE);check(not s.fixed_light and s.worklight_seen,"connected worklight visibly drains")
    use(s,1,s.ISOLATOR);use(s,2,s.CRADLE)
    check(s.fixed_light and s.isolation_open,"isolated worklight frees its owner to move")
    use(s,1,s.PIN_RACK);var first:Vector2=s.RIGHT_SOCKET if right_first else s.LEFT_SOCKET;var second:Vector2=s.LEFT_SOCKET if right_first else s.RIGHT_SOCKET
    use(s,1,first);check(s.support_site=="carried","cannot insert support into a weight-closed socket")
    use(s,0,s.WHEEL);s.switch_actor();ticks(s,80);use(s,1,first)
    check(s.support_site in ["left","right"],"girl's persistent unloading allows cat to install the pin")
    use(s,0,s.WHEEL);use(s,1,first);check(s.support_site!="carried","loaded pin cannot be removed prematurely")
    use(s,1,s.REPAIR_SLOT);check(s.cleared_segments==1,"support opens first jaw; hook ratchet makes it permanent")
    use(s,1,first);check(s.support_site=="carried","same physical pin can now be reused")
    roundtrip(s,"mid-repair pin reuse")
    use(s,0,s.WHEEL);use(s,1,second);use(s,0,s.WHEEL);use(s,1,s.REPAIR_SLOT)
    check(s.left_released and s.right_released and s.cleared_segments==2,"either second jaw completes load transfer")
    use(s,1,s.REPAIR_SLOT);check(s.machine_stopped and s.phase=="withdraw","branch exits after real unloading, no direction password")
    s.positions[1]=Vector2(760,620);use(s,2,s.CRADLE);check(s.phase=="test","tool withdrawal opens controlled test")
    s.facing[0]=Vector2.RIGHT if plan==0 else Vector2.LEFT;use(s,0,s.TEST_PLATE);use(s,0,s.ALIGHT)
    s.facing[2]=Vector2.RIGHT;use(s,2,s.TEST_SOURCE);ticks(s,2)
    use(s,0,s.selected_test_end());check(not s.tested,"portable beam cannot falsely prove machine sending")
    use(s,2,s.TEST_SOURCE);use(s,0,s.selected_test_end())
    check(s.tested and s.outward_light and s.dialogue_active(),"remote lamp stays after portable light withdrawal")
    dialog(s);roundtrip(s,"repair plan and pilot")
func unloading_hold(solo:bool)->void:
    var s=Five.new();s.single=solo;s.joined=true;s.phase="unjam"
    s.positions.assign([s.WHEEL,s.PIN_RACK,Vector2(570,620)])
    use(s,1,s.ISOLATOR);use(s,2,s.CRADLE)
    use(s,1,s.PIN_RACK);use(s,0,s.WHEEL)
    var held_at:Vector2=s.positions[0]
    ticks(s,120)
    check(s.load_held and s.actions[0]=="hold" and s.positions[0]==held_at,"unloading remains held across six seconds of zero stroke timer")
    check(s.posted_role(0),"unloading girl is explicitly posted, never a travel follower")
    if solo:s.switch_actor()
    else:s.switch_cat()
    for i in range(24):s.step(.05,Vector2.RIGHT if solo else Vector2.ZERO,Vector2.RIGHT if not solo else Vector2.ZERO,true)
    check(s.load_held and s.actions[0]=="hold" and s.positions[0]==held_at,"solo role handoff or dual cat movement keeps girl at unloading handle")
    if solo:s.switch_actor()
    else:s.switch_cat()
    ticks(s,30)
    check(s.load_held and s.positions[0]==held_at,"second cat switch leaves unloading held")
    var frozen_positions:Array=s.positions.duplicate();var frozen_clock:float=s.clock
    for i in range(30):s.step(.05,Vector2.DOWN,Vector2.DOWN,false)
    check(s.load_held and s.actions[0]=="hold" and s.positions==frozen_positions and s.clock==frozen_clock,"pause freezes unloading and all movement without releasing it")
    ticks(s,30);use(s,1,s.LEFT_SOCKET)
    check(s.support_site=="left" and s.load_held,"pin installs after delayed handoff and pause, not only immediate interact")
    use(s,0,s.WHEEL);ticks(s,5)
    check(not s.load_held and s.actions[0]!="hold","explicit second interaction releases unloading")
    use(s,1,s.LEFT_SOCKET)
    check(s.support_site=="left","released handle cannot free a still-loaded pin")
    use(s,0,s.WHEEL);use(s,1,s.LEFT_SOCKET)
    check(s.support_site=="carried","reacquiring unloading recovers from release")
    s.controlled=0
    s.step(.05,Vector2.DOWN,Vector2.ZERO,true)
    check(not s.load_held and s.actions[0]!="hold" and s.positions[0]!=held_at,"girl's own movement intentionally releases unloading")
    use(s,1,s.RIGHT_SOCKET)
    check(s.support_site=="carried","closed second socket refuses pin after girl moves away")
    use(s,0,s.WHEEL);ticks(s,30);use(s,1,s.RIGHT_SOCKET)
    check(s.load_held and s.support_site=="right","returning to handle restores playable unloading")
    s=Five.new();s.single=solo;s.joined=true;s.phase="lure";s.positions[0]=s.WHEEL
    use(s,0,s.WHEEL);s.step(.05,Vector2.ZERO,Vector2.ZERO,true)
    check(s.actions[0]=="hold" and not s.load_held,"lure shows its brief wheel stroke without becoming a persistent unloading hold")
    ticks(s,10)
    check(s.actions[0]!="hold" and not s.load_held,"lure stroke ends after its own action duration")
func unloading_transfer(solo:bool,right_first:bool)->void:
    var s=Five.new();s.single=solo;s.joined=true;s.phase="unjam"
    use(s,1,s.ISOLATOR);use(s,2,s.CRADLE);use(s,1,s.PIN_RACK)
    var first:Vector2=s.RIGHT_SOCKET if right_first else s.LEFT_SOCKET
    var second:Vector2=s.LEFT_SOCKET if right_first else s.RIGHT_SOCKET
    use(s,0,s.WHEEL);ticks(s,60);use(s,1,first);use(s,1,s.REPAIR_SLOT)
    check(s.cleared_segments==1 and not s.load_held and s.actions[0]!="hold","first ratchet shifts weight and returns handle despite continuous girl hold")
    check(s.load_center_side()==("left" if right_first else "right") and s.presentation().load_center_side==s.load_center_side(),"actual remaining jaw determines visible load side in either order")
    check(s.load_return_time>0 and s.unloading_wheel_angle()<-.4,"handle starts visible return from held angle")
    var before:float=s.load_return_time
    s.step(.05,Vector2.ZERO,Vector2.ZERO,false)
    check(s.load_return_time==before and not s.load_held,"pause freezes load-transfer return animation")
    ticks(s,12)
    check(s.load_return_time==0 and (s.load_tilt()<0 if right_first else s.load_tilt()>0),"settled frame visibly leans toward still-loaded side")
    use(s,1,first);use(s,1,second)
    check(s.support_site=="carried" and s.cleared_segments==1,"one initial hold cannot support second socket after ratchet changes balance")
    use(s,0,s.WHEEL)
    if solo:s.switch_actor()
    else:s.switch_cat()
    ticks(s,100);s.step(.05,Vector2.RIGHT,Vector2.RIGHT,false)
    check(s.load_held and s.load_tilt()==0,"new unloading levels frame and remains held through handoff time and pause")
    use(s,1,second);use(s,1,s.REPAIR_SLOT)
    check(s.left_released and s.right_released and not s.load_held and s.load_center_side()=="none","second independent unloading completes either left-first or right-first order")
    ticks(s,10);check(s.load_tilt()==0,"both locked jaws leave frame level")
    use(s,1,s.REPAIR_SLOT)
    check(s.machine_stopped and s.phase=="withdraw","unique pin reuse and renewed unloading complete actual repair")
func home()->void:
    for first in [1,2]:
        var s=Five.new();s.restore_complete();s.finished=false;s.phase="home";s.gear_stored=false;s.cat_one_clean=false;s.cat_two_clean=false;s.paws_clean=false
        s.positions[first]=s.HOME_BOWL+Vector2(80,0);s.positions[3-first]=Vector2(200,600)
        var original:Vector2=s.positions[first]
        use(s,0,s.HOME_BOWL)
        check(s.social_transition_active() and s.positions[first]==original,"care command begins visible approach without teleport")
        s.step(.05,Vector2.ZERO,Vector2.ZERO,false);check(s.positions[first]==original,"pause freezes approach")
        s.step(.05,Vector2.ZERO,Vector2.ZERO,true);check(s.positions[first].distance_to(original)>0 and s.positions[first].distance_to(original)<=6.51,"care moves continuously at bounded speed")
        dialog(s);check((s.cat_one_clean if first==1 else s.cat_two_clean) and not s.paws_clean,"either cat can be cared for first")
        use(s,0,s.HOME_BOWL);dialog(s);check(s.paws_clean,"second cat care finishes naturally")
        use(s,0,s.HOME_RACK);use(s,0,s.HOME_SOFA)
        check(not s.finished and s.social_transition_active(),"home completion waits for real sofa approach")
        dialog(s);check(s.finished and s.positions[0].distance_to(s.HOME_SOFA)<25,"three actors settle at original sofa")
        roundtrip(s,"continuous home")
func saves()->void:
    for script in [Two,Three,Four,Five]:
        var s=script.new();var before:Dictionary=s.checkpoint();var bad:Dictionary=before.duplicate(true);bad.facts["unexpected"]=true
        check(not s.restore_checkpoint(bad) and s.checkpoint()==before,"invalid new facts have no side effects")
        var old:Dictionary=Legacy.capture(s)
        check(s.restore_checkpoint(old) and not s.finished,"validated old in-progress save restarts trustworthy entry")
        var complete=script.new();complete.restore_complete();old=Legacy.capture(complete)
        check(s.restore_checkpoint(old) and s.finished,"old completed story remains readable")
        roundtrip(s,"legacy migration")
    var records:Dictionary={}
    for script in [Prologue,One,Two,Three,Four,Five]:
        var s=script.new();records[s.get_script().resource_path]=s.checkpoint()
    var file=FileAccess.open("user://m28-puzzle-process-records.json",FileAccess.WRITE)
    check(file!=null,"isolated save file opens after actual namespace assertion")
    if file:file.store_string(JSON.stringify({"initial":records,"cases":saved_cases}));file.close()
