extends "res://tests/m25_keyboard_driver.gd"
# Continuous known-solution InputEvent acceptance, not blind play or ease evidence.
# No direct chapter starts, state/position/health writes, or restore into live state.
const PREFIX := "qa-m27-mainline"
var receipts:Array[Dictionary]=[]
var route:Array[String]=[]
var encounters:Array[String]=[]
var lobby_identity:int
var entry_clicks:=0
var journey_ids:Array[String]=[]
func run()->void:
    print("M27_MAINLINE_QA_USERDIR ",OS.get_user_data_dir())
    if not gate(OS.get_user_data_dir().get_file()=="DuoduoCatsCourtyard-qa-m27-mainline","actual isolated mainline QA namespace"):return
    # Only this test's previous QA records, never production/default filenames.
    for filename in DirAccess.get_files_at("user://"):
        if filename.begins_with(PREFIX+"-") and filename.ends_with(".json"):
            DirAccess.remove_absolute("user://"+filename)
    Engine.time_scale=3
    lobby=load("res://main.tscn").instantiate();root.add_child(lobby);await frames(3);lobby.session.set_focus(true)
    lobby_identity=lobby.get_instance_id()
    for mode in [true,false]:
        single=mode;route=[];encounters=[]
        if lobby.session.running():tap_key(KEY_ESCAPE);await frames(2)
        await click_entry("SingleJourney" if single else "DualJourney")
        if not gate(lobby.stage=="prologue","legal start_journey button begins prologue, not legacy courtyard"):return
        journey_ids.append(lobby.story_run_id)
        c=lobby.prologue;s=c.state
        if not gate(lobby.session.single_player==single and lobby.session.running() and not lobby.preview_run,"normal entry selects running story mode"):return
        route.append("prologue")
        await prologue_route()
        if failed:return
        await saved()
        await touch(0)
        if not gate(lobby.stage=="chapter-one","prologue completion interaction enters chapter one"):return
        c=lobby.chapter_one;s=c.state;route.append("one")
        if not gate(c.title.text==s.objective() and s.positions.size()==2,"chapter one title and two-role roster"):return
        await one_route()
        if failed:return
        await saved();await touch(0)
        if not await bind_chapter(2):return
        await two_three_route()
        if failed:return
        await touch(0)
        if not await bind_chapter(4):return
        await four_route()
        if failed:return
        await touch(0)
        if not await bind_chapter(5):return
        await five_route()
        if failed:return
        if not gate(s.finished and s.gear_stored and s.paws_clean,"continuous journey voluntarily reaches clean family home"):return
        if not gate(route==["prologue","one","two","three","four","five"],"chapters advance once in correct order"):return
        if not gate(encounters==["first","shell","reserve"],"mainline contains all three distinct combat entries"):return
        var route_record:Dictionary=lobby.story_progress.read(single)
        if not gate(route_record.get("chapter")==5 and route_record.get("run_id")==lobby.story_run_id,"journey resume pointer belongs to completed current run"):return
        if not gate(lobby.get_instance_id()==lobby_identity,"entire journey uses the same lobby instance"):return
        print("M27_MAINLINE_COMPLETE solo=",single," route=",route," encounters=",encounters)
    check(journey_ids.size()==2 and journey_ids[0]!=journey_ids[1],"normal new journey creates independent run identifiers for both modes")
    for item in receipts:
        var readback=JSON.parse_string(FileAccess.get_file_as_string(item.path))
        check(readback is Dictionary and readback.get("completed")==true,"all earlier chapter completion records remain on disk: "+item.path)
    check(receipts.size()==12,"six chapter records retained independently for each mode")
    var report=FileAccess.open("user://"+PREFIX+"-receipt.json",FileAccess.WRITE)
    report.store_string(JSON.stringify({"known_solution":true,"namespace":OS.get_user_data_dir(),"records":receipts,"checks":checks,"failed":failed},"  "));report.close()
    await cleanup_mainline()
    print("M27_MAINLINE_PLAYTHROUGH: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
func click_entry(name:String)->void:
    var button:Button=lobby.get_node(name)
    var before:int=entry_clicks
    button.pressed.connect(func():entry_clicks+=1,CONNECT_ONE_SHOT)
    print("MAINLINE_CLICK rect=",button.get_global_rect()," viewport=",root.size," transform=",root.get_final_transform()," visible=",button.visible," running=",lobby.session.running())
    var motion:=InputEventMouseMotion.new();motion.position=root.get_final_transform()*button.get_global_rect().get_center();Input.parse_input_event(motion);Input.flush_buffered_events()
    for down in [true,false]:
        var event:=InputEventMouseButton.new();event.position=motion.position;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;Input.parse_input_event(event);Input.flush_buffered_events();await frames(1)
    await frames(3)
    gate(entry_clicks==before+1,"physical mouse event activates exactly one normal journey button")
func bind_chapter(number:int)->bool:
    c=lobby.story_chapter;s=c.state
    if not gate(lobby.stage=="story-chapter" and s.chapter==number,"normal completion enters chapter "+str(number)):return false
    if not gate(s.title=={2:"第二章 · 团团，去那边等我",3:"第三章 · 这次一起走",4:"第四章 · 灯光躲起来了",5:"第五章 · 把回家的路点亮"}[number] and c.title.text==s.objective() and s.single==single,"chapter title and input mode match route "+str(number)):return false
    if not gate(s.available_roles()==([0,1] if number<=3 else [0,1,2]),"chapter entry roster obeys reunion chronology"):return false
    route.append({2:"two",3:"three",4:"four",5:"five"}[number]);return true
func select(role:int)->void:
    if lobby.stage in ["prologue","chapter-one"]:
        if single and s.controlled!=role:tap_key(KEY_TAB);await frames(1)
        return
    await super.select(role)
func key_event(code:int,down:bool)->void:
    var mapped:int={KEY_J:KEY_F,KEY_K:KEY_Q,KEY_SPACE:KEY_E}.get(code,code) if single and lobby.stage in ["story-combat","chapter-combat"] else code
    super.key_event(mapped,down)
func tap_key(code:int)->void:
    key_event(code,true);key_event(code,false)
func gate(value:bool,label:String)->bool:
    check(value,label)
    if not value:
        print("MAINLINE_BLOCK stage=",lobby.stage if lobby else "unstarted"," mode=",single," route=",route)
        print("M27_MAINLINE_PLAYTHROUGH: %d checks, %d failed"%[checks,failed]);quit(1)
    return value
func saved()->void:
    if not gate(s.finished and c.recorded,"natural chapter completion records without resetting live state"):return
    var pointer:Dictionary=lobby.story_progress.read(single)
    gate(pointer.get("chapter")==route.size()-1 and pointer.get("run_id")==lobby.story_run_id,"every completed chapter pointer retains current chapter and run ID")
    var record:Dictionary=c.read_record()
    gate(record.get("completed")==true,"completed record reads back")
    var path:String=c.checkpoint_path() if c.has_method("checkpoint_path") else c.record_path()
    receipts.append({"path":path,"single":single,"route":route.duplicate(),"history":record.get("history",[]),"record":record,"pointer":pointer})
    print("MAINLINE_RECORD ",path)
func pause_check()->void:
    axes(9,Vector2.ZERO);axes(18,Vector2.ZERO)
    tap_key(KEY_ESCAPE);await frames(2)
    var points:Array=s.positions.duplicate();var clock:float=s.clock;var phase:String=s.phase
    await frames(12)
    gate(not lobby.session.running() and s.positions==points and s.clock==clock and s.phase==phase,"mid-journey pause freezes actual world")
    tap_key(KEY_ENTER);await frames(2)
    gate(lobby.session.running() and s.positions==points,"normal resume preserves earned progress without stale motion")
func tool_key(role:int)->void:
    await select(role);tap_key(KEY_R if single or role!=0 else KEY_T);await frames(40)
func send_trial()->void:
    await select(0);tap_key(KEY_R if single else KEY_T);await frames(90)
func capture(_label:String)->void:pass
func prologue_route()->void:
    if not gate(await go(1,s.ball-Vector2(40,0)),"cat walks to loose ball"):return
    await touch(1)
    if not gate(await go(0,s.DOOR+Vector2(-40,115)),"girl approaches hallway"):return
    if not gate(await go(0,s.DOOR+Vector2(-40,32)),"girl watches cat at door"):return
    for i in range(900):
        if s.phase=="jam":break
        await frames(1)
    if not gate(s.phase=="jam","visible departure reaches natural rug obstacle"):return
    await pause_check()
    if not gate(await go(1,Vector2(1120,440)),"cat enters hall"):return
    if not gate(await go(1,s.rug_position()+Vector2(0,18)),"cat reaches rug edge"):return
    await touch(1)
    if not gate(not s.rug_grab,"loaded rug cannot be solved alone"):return
    await touch(0);await touch(1)
    if not gate(s.brace and s.rug_grab,"girl braces while cat grips freed carpet"):return
    if not gate(await go(1,Vector2(1120,505)),"walking cat physically drags rug"):return
    if not gate(s.phase=="open","dragging clears doorway"):return
    for role in [0,1]:
        if not gate(await go(role,Vector2(1115,440)),"party walks hallway"):return
        if not gate(await go(role,Vector2(1120,315)),"party walks through real door"):return
    await frames(92)
    gate(s.finished,"whole party exits prologue naturally")
func one_route()->void:
    if not gate(await go(0,Vector2(330,405)),"walk to granny through real inputs"):return
    await touch(0)
    if not gate(s.equipment and s.phase=="road","granny sends party toward station and lends equipment"):return
    if not gate(await go(0,s.LIFT),"girl reaches branch handle"):return
    await touch(0)
    if not gate(s.bracing,"girl visibly keeps branch lifted"):return
    if not gate(await go(1,s.FORK),"cat reaches physical support"):return
    await touch(1)
    if not gate(await go(1,Vector2(575,570)),"cat carries support to notch"):return
    await touch(1)
    if not gate(s.supported,"support locks real cat path for single-player switching"):return
    if not gate(await go(1,Vector2(705,570)),"cat walks under lifted frame"):return
    if not gate(await go(1,s.KNOT),"cat reaches far rope"):return
    await touch(1)
    if not gate(s.branch_clear,"rope input permanently clears path"):return
    if not gate(await go(0,Vector2(1050,565)),"girl follows through open path"):return
    if not gate(await go(1,Vector2(1100,565)),"cat gathers by next road"):return
    await touch(0)
    if not gate(lobby.stage=="chapter-combat","story enters its combat without sample shortcut"):return
    if not await combat():return
    if not gate(await go(1,s.BENCH),"cat investigates low cabinet"):return
    await touch(1)
    if not gate(await go(1,s.LAMP+Vector2(18,10)),"cat carries missing wick to lamp"):return
    await touch(1)
    if not gate(await go(0,s.LAMP+Vector2(-15,20)),"girl reaches lamp assembly"):return
    await touch(0)
    if not gate(s.core_installed and not s.lit,"delivered wick alone does not solve draft puzzle"):return
    if not gate(await go(0,s.HOOD+Vector2(25,0)),"girl reaches wind cover"):return
    await touch(0);await touch(0)
    if not gate(await go(1,s.VENT+Vector2(-25,0)),"cat reaches lower air slats"):return
    await touch(1);await frames(100)
    if not gate(s.lit,"matching visible draft direction and small vent lights station"):return
    if not gate(await go(0,s.PILLOW+Vector2(-20,0)),"girl finds flattened pillow"):return
    await touch(0)
    if not gate(s.clue_seen,"white fur gives next story destination"):return
    if not gate(await go(0,s.SEAT),"girl reaches rest bench"):return
    if not gate(await go(1,s.SEAT+Vector2(45,0)),"cat joins rest without being teleported"):return
    await touch(0);await frames(100)
    if not gate(s.finished and c.recorded,"chapter completes through inputs and writes isolated record"):return
    await pause_check()
func two_three_route()->void:
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
    await journal_check()
    # Actual completion input advances directly to chapter three.
    await touch(0);await frames(3);s=c.state
    if not await bind_chapter(3):return
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
    if not gate(await go(1,s.NARROW),"black cat uses hook on narrow passage"):return
    await touch(1)
    if not gate(await go(0,s.RIG),"girl builds stable search light rig"):return
    await touch(0)
    if not gate(await go(2,s.SEARCH_STAND),"white chooses low source stand"):return
    await aim(2,Vector2.RIGHT);await touch(2)
    if not gate(s.exit_low_latched and not s.exit_high_latched and not s.exit_revealed,"lower source enters first copper opening without solving both locks"):return
    if not gate(await go(0,s.SEARCH_STAND),"girl reaches two-level source mount"):return
    await touch(0)
    if not gate(s.source_level==1 and not s.beam_held and s.exit_low_latched,"changing source height interrupts temporary light but keeps first physical latch"):return
    await aim(2,Vector2.RIGHT);await touch(2)
    if not gate(not s.exit_high_latched and not s.exit_revealed,"higher source with the same mirror face misses the second receiver"):return
    if not gate(await go(0,s.RIG),"girl changes lower reflection face for new incident direction"):return
    await touch(0)
    if not gate(not s.exit_high_latched,"lower reflection alone still leaves high mirror aimed away"):return
    if not gate(await go(1,s.HIGH_RING),"black cat reaches precise upper mirror ring"):return
    await touch(1)
    if not gate(s.exit_high_latched and s.exit_revealed,"correct height and both reflection faces enter second copper opening"):return
    await tool_key(2)
    if not gate(not s.beam_held and s.exit_revealed,"exit stays mechanically locked after release"):return
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
func four_route()->void:
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
func five_route()->void:
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
func combat()->bool:
    var source_stage:String=lobby.stage
    if not gate(source_stage in ["story-combat","chapter-combat"],"story puzzle causally enters combat"):return false
    var encounter:String="first" if source_stage=="chapter-combat" else lobby.arena.battle.story_encounter
    encounters.append(encounter)
    check(encounter==(["first","shell","reserve"][encounters.size()-1]),"encounter order and configuration "+encounter)
    print("MAINLINE_BATTLE_BEGIN ",encounter," solo=",single)
    b=lobby.arena.battle
    check(b.wave_total==2 and b.story_first==(encounter=="first"),"actual story encounter budget and roster match "+encounter)
    tap_key(KEY_E)
    if not single:tap_key(KEY_SPACE)
    var driver=BattleDriver.new(self,b)
    for i in range(14000):
        if b.phase=="clear":break
        driver.step_slot(lobby.arena.solo.human_slot if single else 0)
        if not single:driver.step_slot(1)
        await frames(1)
    drive(0,Vector2.ZERO);drive(1,Vector2.ZERO);key_event(KEY_G,false)
    if not gate(b.phase=="clear","actual attacks, shields, dodge and AI clear chapter encounter"):return false
    for i in range(1800):
        if b.hp[0]>0 and b.hp[1]>0:break
        driver.step_slot(lobby.arena.solo.human_slot if single else 0)
        if not single:driver.step_slot(1)
        await frames(1)
    for i in range(1800):
        if b.positions[0].distance_to(b.EXIT)<80 and b.positions[b.current_cat].distance_to(b.EXIT)<80:break
        for slot in range(2):
            if single and slot!=lobby.arena.solo.human_slot:continue
            var point:Vector2=b.positions[b.actor(slot)]
            drive(slot,b.Space.direction(point,b.EXIT,b.Space.ACTOR_RADIUS) if point.distance_to(b.EXIT)>20 else Vector2.ZERO)
        await frames(1)
    drive(0,Vector2.ZERO);drive(1,Vector2.ZERO);tap_key(KEY_E)
    if not single:tap_key(KEY_SPACE)
    await frames(3);tap_key(KEY_E);await frames(4)
    print("MAINLINE_BATTLE_END ",encounter," solo=",single," retries=",b.retries," hp=",b.hp)
    return gate(lobby.stage==("chapter-one" if source_stage=="chapter-combat" else "story-chapter") and not s.battle_requested,"actual combat gathers companions and returns to same chapter")

func go(role:int,target:Vector2)->bool:
    await select(role)
    var device:=9 if single or role==0 else 18
    for i in range(1300):
        var delta:Vector2=target-s.positions[role]
        if delta.length()<7:axes(device,Vector2.ZERO);return true
        axes(device,Vector2(0 if absf(delta.x)<3 else signf(delta.x),0 if absf(delta.y)<3 else signf(delta.y)));await frames(1)
    axes(device,Vector2.ZERO);print("STORY_GO_STUCK chapter=",lobby.stage," phase=",s.phase," role=",role," to=",target," actual=",s.positions," message=",s.message);return false

func journal_check()->void:
    var history:Array=s.history.duplicate();var phase:String=s.phase
    tap_key(KEY_H);await frames(3)
    gate(lobby.journal.active and not lobby.session.running(),"normal H opens earned journey observations and pauses")
    gate(not history.is_empty() and lobby.journal.lines.text.contains(history.back()),"journal shows observation earned on continuous route")
    tap_key(KEY_H);await frames(3)
    gate(lobby.session.running() and s.phase==phase and s.history==history,"closing journal preserves earned chapter history and phase")

func cleanup_mainline()->void:
    c=null;s=null;b=null
    lobby.queue_free();await frames(4);lobby=null
    # Audio mixer cleanup uses wall time even when --fixed-fps races simulation.
    # Let freed players finish deferred audio-thread deletion before process exit.
    var deadline:int=Time.get_ticks_msec()+100
    while Time.get_ticks_msec()<deadline:await process_frame
