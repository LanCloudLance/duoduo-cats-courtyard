extends SceneTree
const Five=preload("res://game/chapter_five_state.gd")
const M30=preload("res://game/puzzle_m30_checkpoint.gd")
var checks:=0
var failed:=0
var records:Dictionary={}
func check(ok:bool,label:String)->void:
    checks+=1
    if not ok:failed+=1;print("FAIL ",label)
func use(s,role:int,p:Vector2)->void:
    s.positions[role]=p;s.action_time[role]=0;s.interact(role)
func fixture(solo:bool):
    var s=Five.new();s.single=solo
    for key in ["route_lock","route_supported","route_lit","bridge_locked","arm_locked","lid_open","lower_pin","upper_pin"]:s.set(key,true)
    s.lid_pins=2;s.stage_checkpoint=2;s.phase="unjam"
    s.positions.assign([s.WHEEL,s.PIN_RACK,s.CRADLE])
    return s
func light(s)->void:
    use(s,1,s.ISOLATOR);use(s,2,s.CRADLE)
func _init()->void:
    if OS.get_user_data_dir().get_file()!="DuoduoCatsCourtyard-qa-m31-puzzle":quit(2);return
    for solo in [true,false]:
        manual(solo)
        stable(solo,"left");stable(solo,"right")
        beam(solo)
        hints(solo)
    var file=FileAccess.open("user://m31-c5-records.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(records));file.close()
    print("M31_C5_RULES: %d checks, %d failures"%[checks,failed]);quit(1 if failed else 0)
func manual(solo:bool)->void:
    var s=fixture(solo);light(s)
    check(not s.service_open("right"),"manual opening requires actual girl's hold")
    use(s,0,s.WHEEL)
    check(s.service_open("right") and not s.service_open("left"),"manual receiving weight opens only right entrance")
    check(s.support_site=="rack","manual plan needs no copied or inserted support")
    s.switch_actor()
    for i in range(240):s.step(.05,Vector2.ZERO,Vector2.ZERO,true)
    check(s.load_held and not s.machine_stopped,"manual posted hold remains without auto-solving")
    s.positions[1]=s.RIGHT_PULL
    var pending:Dictionary=s.checkpoint()
    var fresh=Five.new();fresh.single=solo
    check(pending.puzzle_revision==3,"C5 records explicitly use revision three")
    check(fresh.restore_checkpoint(pending) and not fresh.load_held and not fresh.fixed_light and not fresh.cat_in_service(),"unfinished manual read clears hold and returns cat to permanent platform")
    use(s,0,s.WHEEL)
    check(s.load_held and not s.machine_stopped,"girl cannot deliberately drop occupied manual mouth")
    use(s,2,s.CRADLE)
    check(s.fixed_light,"occupied manual mouth cannot lose isolated light")
    s.action_time[1]=0;s.interact(1)
    check(s.machine_stopped and s.get("extraction_method")=="held" and s.extraction_side=="right","one true manual pull records exact method")
    check(s.support_site=="rack" and not s.load_held,"permanent latch receives weight, unique pin remains on rack")
    check(s.service_open("right") and not s.service_open("left"),"after extraction original mouth remains actual retreat path")
    for i in range(16):s.move(1,Vector2.DOWN*5)
    check(not s.cat_in_service(),"manual cat can physically retreat without active girl")
    use(s,2,s.CRADLE)
    check(s.phase=="test","manual plan rejoins ordinary pilot verification")
    roundtrip(s,"manual-"+str(solo))
    for cause in ["wrong_girl_position","wrong_girl_action","no_light","no_isolation"]:
        var bad=fixture(solo);light(bad);use(bad,0,bad.WHEEL)
        if cause=="wrong_girl_position":bad.positions[0]=bad.WHEEL+Vector2(150,0)
        if cause=="wrong_girl_action":bad.actions[0]=""
        if cause=="no_light":bad.fixed_light=false
        if cause=="no_isolation":bad.isolation_open=false
        check(not bad.service_open("right") and not bad.manual_load_ready(),"manual visual and passage facts both reject "+cause)
        use(bad,1,bad.RIGHT_PULL)
        check(not bad.machine_stopped,"invalid hold cannot award extraction "+cause)
    var moved=fixture(solo);light(moved);use(moved,0,moved.WHEEL);moved.positions[1]=moved.RIGHT_PULL
    moved.controlled=0;moved.current_cat=1
    for i in range(30):moved.step(.05,Vector2.RIGHT,Vector2.ZERO,true)
    check(not moved.load_held and not moved.machine_stopped and not moved.cat_in_service(),"girl's deliberate motion safely returns cat locally without awarding success")
    check(moved.lid_open and moved.arm_locked,"local safety recovery preserves permanent repair")
func stable(solo:bool,side:String)->void:
    var s=fixture(solo);light(s);use(s,1,s.PIN_RACK);use(s,0,s.WHEEL)
    use(s,1,s.LEFT_SOCKET if side=="left" else s.RIGHT_SOCKET);use(s,0,s.WHEEL)
    check(s.service_open(side),"stable pin plan remains available "+side)
    s.positions[0]=s.WHEEL+Vector2(0,110);s.step(.05,Vector2.ZERO,Vector2.ZERO,true)
    check(s.service_open(side),"stable pin frees girl to move "+side)
    use(s,1,s.pull_point(side))
    check(s.machine_stopped and s.get("extraction_method")=="support" and s.extraction_side==side,"stable pull preserves actual support provenance "+side)
    roundtrip(s,"support-"+side+str(solo))
    var old:Dictionary=M30.capture(s)
    var migrated=Five.new();migrated.single=solo
    check(migrated.restore_checkpoint(old) and migrated.get("extraction_method")=="support" and migrated.support_site==side,"strict M30 migration preserves existing side instead of inventing manual plan "+side)
    roundtrip(migrated,"migrated-"+side+str(solo))
func beam(solo:bool)->void:
    var s=Five.new();s.single=solo;s.restore_complete();s.finished=false;s.phase="test";s.tested=false;s.network_lit=false;s.pilot_charged=false;s.charged_route="none";s.plate_aligned=false;s.pilot_open=false
    s.positions.assign([s.TEST_PLATE,Vector2(950,600),s.TEST_SOURCE]);s.actions[2]="light";s.beam_held=true
    check(s.has_method("pilot_trace"),"actual pilot trace is shared by drawing and charge rules")
    if not s.has_method("pilot_trace"):return
    for direction in [Vector2.LEFT,Vector2.DOWN,Vector2.UP]:
        s.facing[2]=direction
        var trace:Dictionary=s.pilot_trace()
        check(not trace.source_connected and not s.test_beam_ready(),"wrong beam direction never visually enters source")
        check(trace.rays.size()==1 and trace.rays[0][1].x!=s.TEST_PLATE.x,"wrong beam has actual missed endpoint")
        s.step(.05,Vector2.ZERO,Vector2.ZERO,true)
        check(not s.pilot_charged,"wrong direction never charges pilot")
    s.facing[2]=Vector2.RIGHT
    check(s.pilot_trace().source_connected and not s.pilot_trace().board_connected,"aligned source visibly stops at unopened board")
    s.plate_aligned=true
    check(s.pilot_trace().board_connected and not s.pilot_trace().valve_connected,"correct board still distinguishes unopened Alight valve")
    s.step(.05,Vector2.ZERO,Vector2.ZERO,true);check(not s.pilot_charged,"closed pilot valve never grants destination charge")
    s.pilot_open=true;s.step(.05,Vector2.ZERO,Vector2.ZERO,true)
    check(s.pilot_trace().valve_connected and s.pilot_charged and s.charged_route=="tower","true source, board and valve charge exact destination")
    s.positions[2]+=Vector2(150,0)
    check(not s.pilot_trace().source_connected,"portable light away from connection does not draw synthetic connected ray")
func hints(solo:bool)->void:
    var s=fixture(solo)
    s.request_hint();var early:String=s.message
    light(s);use(s,0,s.WHEEL)
    s.request_hint()
    check(s.message!=early and s.message.contains("保持"),"local hint follows manual-versus-support decision")
    s.request_hint();var level:int=s.hint_level
    use(s,0,s.WHEEL);s.request_hint()
    check(s.hint_level==level,"changed local configuration does not force three new help requests")
    s.phase="withdraw";s.positions[1]=s.RIGHT_PULL+Vector2(0,60)
    check(not s.cat_in_service() and s.near(1,s.REPAIR_SLOT,85) and s.hint_context_key()=="withdraw_light","withdraw hint uses actual mouth boundary even near former central slot")
    s.attack(0)
    check(not (s.message.contains("盾挡夹臂") or s.message.contains("爪钩拉锁")),"ordinary attack feedback does not reveal full future solution chain")
func roundtrip(s,label:String)->void:
    var record:Dictionary=s.checkpoint();var fresh=Five.new();fresh.single=s.single
    check(fresh.restore_checkpoint(record),"revision three record restores "+label)
    check(fresh.checkpoint().facts==record.facts,"exact permanent facts survive "+label)
    records[label]={"record":record,"solo":s.single}
