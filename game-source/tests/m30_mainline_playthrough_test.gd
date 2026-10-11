extends "res://tests/m25_keyboard_driver.gd"
# Continuous known-solution InputEvent acceptance, not blind play or ease evidence.
# No direct chapter starts, state/position/health writes, or restore into live state.
const PREFIX := "qa-m30-mainline"
var receipts:Array[Dictionary]=[]
var route:Array[String]=[]
var encounters:Array[String]=[]
var lobby_identity:int
var entry_clicks:=0
var journey_ids:Array[String]=[]
func run()->void:
    print("M30_MAINLINE_QA_USERDIR ",OS.get_user_data_dir())
    if not gate(OS.get_user_data_dir().get_file() in ["DuoduoCatsCourtyard-qa-m30-puzzle","DuoduoCatsCourtyard-qa-m30-root"],"actual isolated mainline QA namespace"):return
    # Only this test's previous QA records, never production/default filenames.
    for filename in DirAccess.get_files_at("user://"):
        if filename.begins_with(PREFIX+"-") and filename.ends_with(".json"):
            DirAccess.remove_absolute("user://"+filename)
    Engine.time_scale=3
    lobby=load("res://main.tscn").instantiate();root.add_child(lobby);await frames(3);lobby.session.set_focus(true)
    lobby_identity=lobby.get_instance_id()
    lobby.story_progress.prefix=PREFIX
    for mode in [true,false]:
        single=mode;route=[];encounters=[]
        if lobby.session.running():tap_key(KEY_ESCAPE);await frames(2)
        await click_entry("新旅程 · 一个人" if single else "新旅程 · 两个人")
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
        print("M30_MAINLINE_COMPLETE solo=",single," route=",route," encounters=",encounters)
    check(journey_ids.size()==2 and journey_ids[0]!=journey_ids[1],"normal new journey creates independent run identifiers for both modes")
    for item in receipts:
        var readback=JSON.parse_string(FileAccess.get_file_as_string(item.path))
        check(readback is Dictionary and readback.get("completed")==true,"all earlier chapter completion records remain on disk: "+item.path)
    check(receipts.size()==12,"six chapter records retained independently for each mode")
    var report=FileAccess.open("user://"+PREFIX+"-receipt.json",FileAccess.WRITE)
    report.store_string(JSON.stringify({"known_solution":true,"namespace":OS.get_user_data_dir(),"records":receipts,"checks":checks,"failed":failed},"  "));report.close()
    await cleanup_mainline()
    print("M30_MAINLINE_PLAYTHROUGH: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
func click_entry(name:String)->void:
    var button:Button
    for candidate in lobby.journey_menu.buttons:
        if candidate.text==name:button=candidate;break
    if not gate(button!=null and button.is_visible_in_tree(),"visible normal menu journey entry"):return
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
        print("M30_MAINLINE_PLAYTHROUGH: %d checks, %d failed"%[checks,failed]);quit(1)
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
func snapshot(_label:String)->void:pass
func prologue_route()->void:
    if not gate(await go(1,s.ball-Vector2(40,0)),"cat walks to loose ball"):return
    await touch(1)
    if not gate(await go(1,s.SOFA_BALL),"cat looks below actual sofa for optional old ball"):return
    await touch(1)
    if not gate(s.ball_found,"real low cat reach earns first keepsake"):return
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
    if not gate(await go(0,s.NIGHT_LAMP),"girl investigates independent night lamp"):return
    await aim(0,Vector2.LEFT);await touch(0)
    if not gate(await go(1,s.NIGHT_LAMP),"cat adjusts separate low air inlet"):return
    await touch(1)
    if not gate(s.night_lit,"optional lamp uses learned draft rules"):return
    if not gate(await go(0,s.GRANNY),"girl returns to actually receive optional gift"):return
    await touch(0)
    if not gate(s.nightlight_taken,"gift is earned after optional lamp, not main completion"):return
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
    if not gate(await go(1,s.LATCH_A),"cat walks supported front leaf"):return
    await touch(1)
    if not gate(s.locked_a,"front latch holds permanent load"):return
    if not gate(await go(0,s.WINCH_A),"girl revisits unloaded pin"):return
    await tool_key(0)
    if not gate(s.support_site=="carried","same support removed only after front ratchet locks"):return
    if single:
        if not gate(await go(0,s.WINCH_B),"girl carries support over permanent front bridge"):return
        if not gate(await go(1,s.WINCH_B),"cat meets actual carrier"):return
        await touch(1);await touch(1)
        await touch(0)
        if not gate(s.support_site=="b" and s.lifted_b,"same pin fits rear loaded leaf"):return
        await touch(1)
        if not gate(s.support_site=="b","weight-bearing pin cannot be taken by force"):return
        if not gate(await go(0,s.LAMP_B),"girl reaches rear guide lamp"):return
        await touch(0);await touch(0)
        if not gate(await go(0,s.BRACE_B),"girl takes rear bridge load"):return
        await touch(0)
        if not gate(await go(1,s.WINCH_B),"cat reaches unloaded support"):return
        await touch(1)
        if not gate(await go(1,Vector2(585,555)),"cat takes fixed stairs"):return
        if not gate(await go(1,Vector2(675,555)),"cat walks lit low passage"):return
        if not gate(await go(0,Vector2(565,465)),"holder deliberately releases load by walking away"):return
        if not gate(not s.rear_braced() and s.positions[1].x<615 and s.support_site=="cat_carried","load release preserves unique pin and returns cat to nearby ground"):return
        if not gate(await go(0,s.BRACE_B),"girl resumes local load handle"):return
        await touch(0)
        if not gate(await go(1,Vector2(585,555)),"cat returns through stairs after setback"):return
        if not gate(await go(1,s.LATCH_B),"cat brings same support to far lock"):return
        await touch(1)
        if not gate(s.locked_b and s.support_site=="far","short route converts held load to permanent far lock"):return
    else:
        if not gate(await go(0,Vector2(585,470)),"carrier reaches outer stair top"):return
        if not gate(await go(0,s.OUTER_BENCH),"carrier walks to real outer bridge mount"):return
        await touch(0)
        if not gate(await go(1,Vector2(585,620)),"cat enters outer bridge on matching floor"):return
        if not gate(await go(1,Vector2(630,620)),"cat steps onto outer planks"):return
        if not gate(await go(1,Vector2(745,620)),"cat crosses physically supported outer passage"):return
        await touch(1)
        if not gate(s.outer_locked,"outer ratchet permanently takes weight"):return
        if not gate(await go(1,s.OUTER_BENCH),"cat returns to unloaded shared pin"):return
        await touch(1)
        if not gate(await go(1,Vector2(745,620)),"carrier recrosses locked outer bridge"):return
        if not gate(await go(1,Vector2(745,555)),"cat climbs actual far stair"):return
        await touch(1)
        if not gate(s.locked_b and not s.rear_braced() and s.lamp_b!=2,"outer route solves rear leaf without short-route light or held human load"):return
    if not gate(await go(1,Vector2(795,555)),"cat reaches far bank"):return
    if not gate(await go(1,s.BOX),"cat opens actual maintenance box"):return
    await touch(1)
    if not gate(await go(1,s.CART_HOOK),"cat chooses optional freight hook"):return
    await touch(1)
    if not gate(s.cart_open,"optional hook changes physical return path"):return
    if single:
        if not gate(await go(1,s.SHORTCUT),"cat chooses optional upper shortcut ring"):return
        await touch(1)
    for role in [0,1]:
        if single:
            if not gate(await go(role,Vector2(800,420)),"party walks restored bridge surface"):return
            if not gate(await go(role,Vector2(1040,425)),"party crosses the pulled shortcut"):return
        else:
            if role==0:
                if not gate(await go(0,Vector2(585,420)),"girl walks upstairs from outer support mount"):return
                if not gate(await go(0,Vector2(800,420)),"girl crosses permanently latched upper leaves"):return
            if not gate(await go(role,Vector2(800,550)),"party chooses lower freight bank"):return
            if not gate(await go(role,Vector2(930,610)),"party approaches actual freight crossing"):return
            if not gate(await go(role,Vector2(1020,610)),"party crosses lower cargo shortcut while upper bridge stays shut"):return
            if not gate(await go(role,Vector2(1100,610)),"party reaches east bank without upper-route permission"):return
        if not gate(await go(role,s.WINDOW+Vector2(role*20,20)),"party gathers at actual low window"):return
    if not gate(await go(0,s.WINDOW),"girl looks through window after both have arrived"):return
    await touch(0)
    if not gate(s.finished and not s.joined,"safe indoor white cat is still an NPC"):return
    await saved();await journal_check();await touch(0);await frames(3)
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
    if not gate(await go(1,s.MAP_BACK),"cat explores actual slanted light at the old map back"):return
    await touch(1)
    if not gate(s.map_discovered,"slanted light earns optional old-map discovery"):return
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
    await saved();await journal_check()
func four_route()->void:
    if not gate(await go(1,s.HOOK),"cat reaches market cover ring"):return
    await touch(1)
    if not gate(await go(2,s.MARKET_LIGHT),"white reaches actual market stand"):return
    await aim(2,Vector2(-1,-1));await touch(2)
    if not gate(await go(1,Vector2(295,450)),"cat reaches return plank entrance"):return
    if not gate(await go(1,Vector2(295,385)),"cat follows visible lit plank"):return
    await touch(1)
    if not gate(await go(1,Vector2(295,450)),"cat returns carrying the cover"):return
    if not gate(await go(1,s.CATCH),"cover arrives at catching bank"):return
    if not gate(await go(0,s.CATCH),"girl receives actual recovered cover"):return
    await touch(0)
    if not gate(s.cloth,"recovery yields cloth"):return
    if not gate(await go(0,s.VIEW_DOOR),"girl chooses exterior before any NPC permission"):return
    await touch(0)
    if not gate(s.room_name()=="exterior","family physically reaches gallery"):return
    if not single:
        if not gate(await go(0,s.TREE_ENTRY),"girl reaches real tree maintenance gate before diagnosis"):return
        await touch(0)
        if not gate(not s.diagnosis_ready(),"first gate does not require reporting evidence"):return
        if not await combat():return
        if not gate(s.battles_finished==1 and s.phase=="investigate" and s.room_name()=="exterior","gate-first return preserves physical room and missing diagnosis"):return
    if single:
        await c4_patch()
        if failed:return
        if not gate(not s.shell_leak_seen,"repair before experiments never invents leaked sample"):return
    if not gate(await go(0,s.VIEW_DOOR),"girl leaves repaired gallery"):return
    await touch(0)
    if not gate(await go(2,s.DUCT_LIGHT),"white cat holds physical testing source"):return
    await aim(2,Vector2.UP);await touch(2)
    if not gate(await go(0,s.ARROWS),"girl sends main sample without NPC permit"):return
    await select(0);tap_key(KEY_R if single else KEY_T);await frames(4)
    await select(2);tap_key(KEY_R);await frames(30)
    if not gate(not s.main_return_seen and not s.inward_verified and not s.pulse_active,"real early source withdrawal cancels sample without granting proof"):return
    await touch(2)
    await send_trial()
    if not gate(s.main_return_seen and not s.diagnosis_ready(),"main sample cannot invent isolated evidence"):return
    if not gate(s.inward_verified==single and (s.leak_charge==0)==single,"main pulse physically reflects actual early repair state"):return
    await touch(0)
    if not gate(await go(1,s.BRANCH),"cat isolates physical reserve branch"):return
    await touch(1);await send_trial()
    if not gate(s.reserve_hold_seen and s.diagnosis_ready(),"actual isolation supplies remaining causal comparison"):return
    if single:
        if not gate(s.phase!="offer" and s.battles_finished==0,"early proofs never skip actual first battle"):return
        if not gate(await go(0,s.VIEW_DOOR),"girl chooses tree maintenance path"):return
        await touch(0)
        if not gate(await go(0,s.TREE_ENTRY),"girl physically approaches blocked gate"):return
        await touch(0)
        if not await combat():return
        if not gate(s.room_name()=="exterior","successful battle returns to same exterior room"):return
        if not gate(await go(0,s.VIEW_DOOR),"girl returns after opened maintenance path"):return
        await touch(0)
    else:
        if not gate(s.phase=="exterior" and s.room_name()=="interior","diagnosis changes objective without room teleport"):return
        if not gate(await go(0,s.VIEW_DOOR),"diagnosed family chooses exterior repair"):return
        await touch(0);await c4_patch()
        if failed:return
        if not gate(s.phase=="test" and not s.inward_verified,"late repair needs an actual post-repair sample"):return
        if not gate(await go(0,s.VIEW_DOOR),"family returns to same test bench after repair"):return
        await touch(0)
        if not gate(await go(2,s.DUCT_LIGHT),"white cat relights after physical room trip"):return
        await aim(2,Vector2.UP);await touch(2)
        if not gate(await go(0,s.ARROWS),"girl switches same handle back to main"):return
        if s.route_split:await touch(0)
        await send_trial()
    if not gate(s.phase=="offer" and s.inward_verified and s.battles_finished==1,"both orders converge without repeating repair or retest"):return
    if not gate(await go(0,s.ALIGHT),"Alight offers a true reserve lantern"):return
    await touch(0)
    if not await gather(s.HOME):return
    if not gate(await go(0,s.HOME),"girl decides after companions have gathered"):return
    await touch(0);await frames(8)
    if not gate(s.reserve_retained,"choosing help keeps family's reserve"):return
    if not await combat():return
    if not await gather(s.REST):return
    if not gate(await go(0,s.REST),"girl voluntarily rests after second encounter"):return
    await touch(0);await saved()
func c4_patch()->void:
    if not gate(await go(1,s.LATCH),"cat tries unsupported cloth first"):return
    await touch(1)
    if not gate(not s.latch_fixed,"unbraced cloth rejects wrong hypothesis"):return
    if not gate(await go(0,s.PATCH),"girl braces actual early patch"):return
    await touch(0)
    if not gate(await go(1,s.LATCH),"cat latches early supported cloth"):return
    await touch(1)
    if not gate(s.latch_fixed,"early latch is durable before diagnosis"):return
    await pause_check()
    if not gate(s.latch_fixed,"ordinary pause and role handoff preserve permanent patch latch"):return
    if not gate(await go(2,s.SEAM_LIGHT),"white cat inspects seam with real light"):return
    await aim(2,Vector2.LEFT);await touch(2)
    if not gate(not s.seam_seen,"wrong angle gives no seam evidence"):return
    await aim(2,Vector2(1,-1));await touch(2)
    if not gate(await go(0,s.PATCH),"girl seals illuminated edge"):return
    await touch(0)
    if not gate(s.shell_fixed and s.room_name()=="exterior","full physical repair persists without room jump"):return

func five_route()->void:
    if not gate(await go(1,s.LOW_LOCK),"cat finds low approach lock"):return
    await touch(1)
    if not gate(await go(0,s.SUPPORT),"girl installs approach support"):return
    await touch(0)
    if not gate(await go(2,s.ROUTE_LAMP),"white holds approach light"):return
    await aim(2,Vector2.RIGHT);await touch(2)
    if not gate(s.bridge_locked,"three roles lock real approach bridge"):return
    for role in s.available_roles():
        if not gate(await go(role,Vector2(340,550)),"party approaches bridge"):return
        if not gate(await go(role,s.CORE_GATE+Vector2(role*15,0)),"party crosses locked bridge"):return
    if not gate(await go(0,s.CORE_GATE),"girl opens maintenance entrance"):return
    await touch(0)
    if not gate(s.phase=="shield","normal entrance reaches mechanical repair"):return
    if not single:
        if not gate(await go(0,s.PREP_HANDLE),"girl raises outer platform"):return
        await touch(0)
        if not gate(await go(1,s.PREP_LATCH),"cat uses extra cooperative preparation"):return
        await touch(1)
        if not gate(s.far_walkway,"extra latch unlocks actual upper platform"):return
    var shield:Vector2=s.SHIELD_SLOT if single else s.FAR_SLOT
    if not gate(await go(0,shield),"girl chooses physical near or far slot"):return
    await touch(0)
    await aim(0,s.positions[0].direction_to(s.MACHINE));key_event(KEY_G,true)
    if not gate(await go(1,s.ARM_LOCK if single else s.FAR_LOCK),"cat walks to selected arm lock"):return
    for i in range(500):
        if s.arm_arrest>0:break
        await frames(1)
    if not gate(s.arm_arrest>0,"held directional shield actually stops arm at selected slot"):return
    await touch(1);key_event(KEY_G,false)
    if not gate(s.arm_locked and s.phase=="lure" and s.arm_route==(0 if single else 1),"cat locks the chosen shield plan"):return
    check(not s.walkable(Vector2(710,425),0) if single else s.walkable(Vector2(710,425),0),"near arm blocks central shortcut, far plan leaves it open")
    if not gate(await go(2,s.AIM_STAND),"white reaches lid source"):return
    await aim(2,Vector2.RIGHT if single else Vector2.UP);await touch(2)
    if not gate(await go(0,Vector2(1070,550)),"girl walks around body on safe south bank"):return
    if not gate(await go(0,s.WHEEL),"girl reaches unloading wheel"):return
    await touch(0)
    if not gate(s.lid_pins==1,"chosen first lid pin stays locked"):return
    await touch(0)
    if not gate(s.lid_pins==1,"repeating same light cannot fake second pin"):return
    await aim(2,Vector2.UP if single else Vector2.RIGHT);await touch(2);await touch(0)
    if not gate(s.lid_open and s.phase=="unjam","both pin orders work"):return
    if single:
        if not gate(await go(2,Vector2(580,500)),"near-slot arm makes white take actual southern detour"):return
    if not gate(await go(2,s.CRADLE),"white tries maintenance lamp"):return
    await touch(2)
    if not gate(s.worklight_seen and not s.fixed_light,"connected maintenance lamp is visibly reclaimed"):return
    if not gate(await go(1,s.ISOLATOR),"cat cuts lamp return"):return
    await touch(1);await touch(2)
    if not gate(s.fixed_light,"isolated lamp persists while white is free to move"):return
    if not gate(await go(1,s.PIN_RACK),"cat picks up unique repair support"):return
    await touch(1)
    var side:String="left" if single else "right"
    var socket:Vector2=s.LEFT_SOCKET if single else s.RIGHT_SOCKET
    var opening:Vector2=s.pull_point(side)
    var wrong:Vector2=s.pull_point("right" if single else "left")
    if not gate(await go(0,s.WHEEL),"girl takes wheel load for single insertion"):return
    await touch(0)
    if not gate(await go(1,socket),"cat chooses actual support side"):return
    await touch(1)
    if not gate(s.support_site==side,"only physical pin occupies selected socket"):return
    await touch(0)
    if not gate(not s.load_held and s.service_open(side),"girl transfers weight into pin, opening only its side"):return
    if not gate(await go(1,Vector2(wrong.x,550)),"cat approaches wrong physical entrance"):return
    await select(1)
    axes(9 if single else 18,Vector2.UP);await frames(32);axes(9 if single else 18,Vector2.ZERO)
    await touch(1)
    if not gate(not s.service_rect("right" if single else "left").has_point(s.positions[1]) and not s.machine_stopped,"ordinary motion cannot enter opposite closed jaw or pull remotely"):return
    if not gate(await go(1,Vector2(wrong.x,550)),"cat backs off blocked entrance"):return
    if not gate(await go(1,Vector2(opening.x,550)),"cat chooses supported-side approach"):return
    if not gate(await go(1,opening),"cat walks actual supported narrow entrance"):return
    await touch(1)
    if not gate(s.machine_stopped and s.extraction_side==side,"one pull removes whole branch from chosen entrance"):return
    if not gate(not s.left_released and not s.right_released,"single pull does not counterfeit legacy two-jaw success"):return
    if not gate(await go(1,Vector2(opening.x,550)),"cat retreats through same still-open mouth"):return
    if not gate(await go(1,Vector2(875,620)),"cat reaches permanent south platform"):return
    await touch(2)
    if not gate(s.phase=="test","releasing maintenance lamp enters pilot test"):return
    if single:
        if not gate(await go(0,Vector2(1100,550)),"near-slot plan requires east bank around folded front deck"):return
        if not gate(await go(0,Vector2(1100,335)),"girl follows visible outer machine bank"):return
    if not gate(await go(0,s.ALIGHT),"girl asks Alight for safe pilot valve"):return
    await touch(0)
    if not gate(await go(0,Vector2(1100,335)),"girl returns along outer machine bank after valve opens"):return
    if not gate(await go(0,Vector2(1100,555)),"girl follows open southern bank to outgoing control"):return
    if not gate(await go(0,s.TEST_PLATE),"girl chooses actual outgoing branch"):return
    await aim(0,Vector2.RIGHT if single else Vector2.LEFT);await touch(0)
    if not gate(await go(2,s.TEST_SOURCE),"white temporarily feeds pilot light"):return
    await aim(2,Vector2.RIGHT);await touch(2)
    if not gate(await go(0,s.selected_test_end()),"girl visits chosen physical endpoint"):return
    await touch(0)
    if not gate(not s.tested,"connected borrowed light cannot be mistaken for working network"):return
    await touch(2)
    if not gate(await go(0,s.TEST_PLATE),"girl returns to change pilot destination after charge"):return
    await aim(0,Vector2.LEFT if single else Vector2.RIGHT);await touch(0)
    if not gate(not s.pilot_charged,"changing destination clears prior charge proof"):return
    if not gate(await go(0,s.selected_test_end()),"girl checks newly selected uncharged endpoint"):return
    await touch(0)
    if not gate(not s.tested and s.phase=="test","new destination cannot borrow old lamp proof"):return
    if not gate(await go(2,s.TEST_SOURCE),"white returns to actual source after route change"):return
    await aim(2,Vector2.RIGHT);await touch(2);await frames(8);await touch(2)
    if not gate(await go(0,s.selected_test_end()),"girl rechecks actual newly charged endpoint after release"):return
    await touch(0)
    if not gate(s.tested and s.phase=="release","real endpoint remains lit after temporary source release"):return
    if not gate(await go(0,Vector2(1050,550)),"girl follows safe bank back"):return
    if single:
        if not gate(await go(0,Vector2(1100,550)),"near arm still requires east bank after pilot test"):return
        if not gate(await go(0,Vector2(1100,335)),"girl returns around machine front rather than crossing a closed deck"):return
    if not gate(await go(0,s.ALIGHT),"girl opens network gate only after pilot verified"):return
    await touch(0)
    if not gate(s.network_lit,"network restores actual prior locations"):return
    if not await gather(s.LIFT):return
    await touch(0)
    if not gate(s.phase=="farewell","lift leads to farewell"):return
    if not gate(await go(0,s.GRANNY),"girl chooses optional actual farewell gift"):return
    await touch(0)
    if not await gather(s.PORTAL):return
    await touch(0);await touch(0)
    if not single:await touch(1)
    if not gate(s.phase=="home" and not s.finished,"family returns to home without premature completion"):return
    if not gate(await go(0,s.HOME_RACK),"girl stores expedition equipment"):return
    await touch(0)
    if not await gather(s.HOME_BOWL):return
    await touch(0);await touch(0)
    if not gate(s.paws_clean,"both cats receive visible care before resting"):return
    if not gate(await go(0,s.HOME_SOFA),"girl initiates voluntary family rest"):return
    await touch(0)
    if not gate(s.finished and s.gear_stored and s.paws_clean,"whole adventure ends after actual approach and seated rest"):return
    await saved()
class NormalBattlePilot extends "res://tests/m30_combat_driver.gd":
    var driver
    func axis(slot:int,vector:Vector2)->void:driver.drive(slot,vector)
    func button(slot:int,id:int,down:bool)->void:
        var keys:Dictionary={JOY_BUTTON_A:KEY_E,JOY_BUTTON_X:KEY_F,JOY_BUTTON_B:KEY_Q,JOY_BUTTON_Y:KEY_TAB,JOY_BUTTON_LEFT_SHOULDER:KEY_G} if slot==0 else {JOY_BUTTON_A:KEY_SPACE,JOY_BUTTON_X:KEY_J,JOY_BUTTON_B:KEY_K,JOY_BUTTON_Y:KEY_TAB,JOY_BUTTON_LEFT_SHOULDER:KEY_U}
        driver.key_event(keys[id],down)
func combat()->bool:
    var source_stage:String=lobby.stage
    if not gate(source_stage in ["story-combat","chapter-combat"],"normal puzzle causally enters combat"):return false
    b=lobby.arena.battle
    var prior_time_scale:float=Engine.time_scale
    Engine.time_scale=1.0
    print("M30_COMBAT_INPUT_RATE time_scale=",Engine.time_scale," fixed_fps=60 active_role=",b.actor(0))
    var encounter:String=b.story_encounter;encounters.append(encounter)
    check(encounter==["first","shell","reserve"][encounters.size()-1],"encounter ordering "+encounter)
    var pilot=NormalBattlePilot.new();pilot.driver=self;pilot.arena=lobby.arena
    for i in range(14000):
        if lobby.stage!=source_stage:break
        if b.phase=="complete":tap_key(KEY_E);await frames(3);continue
        pilot.tick_index+=1
        for slot in b.deployed_slots():pilot.pilot(slot)
        await frames(1)
    for slot in [0,1]:drive(slot,Vector2.ZERO)
    key_event(KEY_G,false);key_event(KEY_U,false);pilot.free()
    Engine.time_scale=prior_time_scale
    print("M30_MAINLINE_BATTLE ",encounter," mode=",single," retries=",b.retries," hp=",b.hp)
    print("BATTLE_EXIT_DIAGNOSTIC phase=",b.phase," wave=",b.wave," pos=",b.positions," exit=",b.EXIT)
    return gate(lobby.stage==("chapter-one" if source_stage=="chapter-combat" else "story-chapter"),"real combat actions return to same exploration instance")
func touch(role:int)->void:
    await select(role);tap_key(KEY_E if single or role==0 else KEY_SPACE);await frames(4)
    for i in range(1200):
        if s.has_method("social_transition_active") and s.social_transition_active():await frames(1);continue
        if s.has_method("dialogue_active") and s.dialogue_active():
            tap_key(KEY_E if single or role==0 else KEY_SPACE);await frames(2);continue
        break
    await frames(8)
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
    if "three_map" in lobby.journey_discoveries:gate(lobby.journal.saved_map.visible,"earned clock-paper diagram remains available in later journal")
    tap_key(KEY_H);await frames(3)
    gate(lobby.session.running() and s.phase==phase and s.history==history,"closing journal preserves earned chapter history and phase")

func cleanup_mainline()->void:
    c=null;s=null;b=null
    lobby.queue_free();await frames(4);lobby=null
    # Audio mixer cleanup uses wall time even when --fixed-fps races simulation.
    # Let freed players finish deferred audio-thread deletion before process exit.
    var deadline:int=Time.get_ticks_msec()+100
    while Time.get_ticks_msec()<deadline:await process_frame
