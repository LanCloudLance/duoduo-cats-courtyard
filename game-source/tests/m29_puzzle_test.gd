extends SceneTree
# Targeted state fixtures, not a normal input playthrough. Both new decisions
# would fail if the old central three-pull chain or global pilot proof returned.
const Five=preload("res://game/chapter_five_state.gd")
const M28=preload("res://game/puzzle_m28_checkpoint.gd")
var cases:Dictionary={}
var checks:=0
var failed:=0
func check(ok:bool,label:String)->void:
    checks+=1
    if not ok:failed+=1;print("FAIL ",label)
func use(s,role:int,point:Vector2)->void:
    s.positions[role]=point;s.action_time[role]=0;s.interact(role)
func fixture(solo:bool):
    var s=Five.new();s.single=solo
    # Explicit legal maintenance entry, before any light/support/branch success.
    for key in ["route_lock","route_supported","route_lit","bridge_locked","arm_locked","lid_open","lower_pin","upper_pin"]:s.set(key,true)
    s.lid_pins=2;s.stage_checkpoint=2;s.phase="unjam"
    s.positions.assign([s.WHEEL,s.PIN_RACK,s.CRADLE])
    return s
func _init()->void:
    if OS.get_user_data_dir().get_file()!="DuoduoCatsCourtyard-qa-m29-puzzle":quit(2);return
    for solo in [true,false]:
        for side in ["left","right"]:extraction(solo,side)
        pilot(solo)
        saving(solo)
        moving_pin(solo)
    var file=FileAccess.open("user://m29-puzzle-records.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(cases));file.close()
    print("M29_PUZZLE: %d checks, %d failures"%[checks,failed]);quit(1 if failed else 0)
func extraction(solo:bool,side:String)->void:
    var s=fixture(solo)
    use(s,1,s.ISOLATOR);use(s,2,s.CRADLE);use(s,1,s.PIN_RACK)
    var socket:Vector2=s.LEFT_SOCKET if side=="left" else s.RIGHT_SOCKET
    var mouth:=Vector2(815,485) if side=="left" else Vector2(940,485)
    var wrong:=Vector2(940,485) if side=="left" else Vector2(815,485)
    use(s,0,s.WHEEL);use(s,1,socket);use(s,0,s.WHEEL)
    check(s.walkable(mouth,1),"supported side opens actual cat entrance "+side)
    check(not s.walkable(wrong,1),"opposite loaded side closes actual cat entrance "+side)
    use(s,1,wrong);check(not s.machine_stopped,"wrong entrance cannot pull whole branch "+side)
    s.positions[1]=Vector2(mouth.x,555)
    for i in range(15):s.move(1,Vector2(0,-5))
    check(s.positions[1].distance_to(mouth)<8,"cat can physically enter chosen mouth "+side)
    s.action_time[1]=0;s.interact(1)
    check(s.machine_stopped and s.phase=="withdraw","one physical side pull removes whole branch "+side)
    check(not (s.left_released and s.right_released),"new completion does not counterfeit both legacy jaw flags")
    use(s,2,s.CRADLE);check(s.phase=="withdraw" and s.fixed_light,"occupied exit cannot lose its lamp")
    s.positions[1]=Vector2(mouth.x,485)
    for i in range(15):s.move(1,Vector2(0,5))
    check(s.positions[1].y>=550,"cat physically leaves the chosen mouth after removal")
    use(s,2,s.CRADLE);check(s.phase=="test","withdrawal needs real safe exit and lamp release")
    roundtrip(s,"extracted-"+side+str(solo))
func pilot(solo:bool)->void:
    var s=Five.new();s.single=solo;s.restore_complete();s.finished=false;s.phase="test";s.tested=false;s.network_lit=false;s.pilot_charged=false;s.plate_aligned=false
    s.positions.assign([s.TEST_PLATE,Vector2(950,600),s.TEST_SOURCE]);s.pilot_open=true
    s.facing[0]=Vector2.RIGHT;use(s,0,s.TEST_PLATE)
    s.facing[2]=Vector2.RIGHT;use(s,2,s.TEST_SOURCE);s.step(0.05,Vector2.ZERO,Vector2.ZERO,true)
    check(s.pilot_charged,"tower actually receives pilot source")
    s.action_time[2]=0;use(s,2,s.TEST_SOURCE)
    s.facing[0]=Vector2.LEFT;use(s,0,s.TEST_PLATE)
    check(not s.pilot_charged,"changing pilot destination clears old unverified charge")
    use(s,0,s.TEST_MARKET)
    check(not s.tested and s.phase=="test","uncharged market cannot borrow tower proof")

func roundtrip(s,label:String)->void:
    var record:Dictionary=s.checkpoint();var fresh=Five.new();fresh.single=s.single
    check(fresh.restore_checkpoint(record),"new valid checkpoint restores "+label)
    check(fresh.checkpoint().facts==record.facts,"new durable facts preserved "+label)
    check(not fresh.load_held and not fresh.fixed_light and not fresh.beam_held,"transient posts are never replayed "+label)
    cases[label]={"record":record,"solo":s.single}
func moving_pin(solo:bool)->void:
    var s=fixture(solo)
    use(s,1,s.ISOLATOR);use(s,2,s.CRADLE);use(s,1,s.PIN_RACK)
    use(s,1,s.LEFT_SOCKET);check(s.support_site=="carried","insertion without unloading rejected")
    use(s,0,s.WHEEL)
    s.switch_actor()
    for i in range(100):s.step(.05,Vector2.ZERO,Vector2.ZERO,true)
    check(s.load_held,"manual handoff preserves unloading across time")
    use(s,1,s.LEFT_SOCKET);use(s,0,s.WHEEL)
    use(s,1,s.LEFT_SOCKET);check(s.support_site=="left","loaded support cannot be removed")
    s.positions[1]=s.LEFT_PULL
    use(s,0,s.WHEEL);check(not s.load_held,"girl cannot close occupied cat mouth")
    use(s,2,s.CRADLE);check(s.fixed_light,"white cat cannot extinguish occupied mouth")
    # The cat leaves by actual movement, then the girl can change the posture.
    for i in range(16):s.move(1,Vector2.DOWN*5)
    use(s,0,s.WHEEL);check(s.load_held,"safe withdrawal permits reconfiguration")
    use(s,1,s.LEFT_SOCKET);check(s.support_site=="carried","unloading releases same physical pin")
    use(s,1,s.RIGHT_SOCKET);use(s,0,s.WHEEL)
    check(s.service_open("right") and not s.service_open("left"),"moving unique pin swaps actual open entrance")
    check(not s.walkable(s.RIGHT_PULL,0) and not s.walkable(s.RIGHT_PULL,2),"only small cat fits opened service mouth")
    roundtrip(s,"moved-pin-"+str(solo))
    var restored=Five.new();restored.single=solo
    check(restored.restore_checkpoint(s.checkpoint()),"restore inserted side")
    check(restored.support_site=="right" and not restored.walkable(restored.RIGHT_PULL,1),"support survives but dark temporary path does not")
    use(restored,2,restored.CRADLE)
    check(restored.service_open("right"),"restored side becomes reachable after explicit relighting")
    use(restored,1,restored.RIGHT_PULL);check(restored.machine_stopped,"restored chosen route remains solvable")
func saving(solo:bool)->void:
    var s=fixture(solo);roundtrip(s,"maintenance-entry-"+str(solo))
    # Historical fixtures are strictly passed through the frozen M28 validator.
    s.worklight_seen=true;s.isolation_open=true;s.left_released=true;s.cleared_segments=1;s.support_site="left"
    var old:Dictionary=M28.capture(s)
    check(old.puzzle_revision==1,"historical record explicitly revision one")
    var migrated=Five.new();migrated.single=solo
    check(migrated.restore_checkpoint(old),"valid old half-repair migrates")
    check(migrated.lid_open and migrated.arm_locked and migrated.bridge_locked and not migrated.machine_stopped,"migration preserves old permanent stages without granting extraction")
    check(migrated.support_site=="rack" and migrated.extraction_side=="none" and not migrated.cat_in_service(),"old partial jaw resumes safe new maintenance entry")
    roundtrip(migrated,"migrated-mid-"+str(solo))
    var broken:Dictionary=old.duplicate(true);broken.facts.lid_open=false
    var before:Dictionary=migrated.checkpoint()
    check(not migrated.restore_checkpoint(broken) and migrated.checkpoint()==before,"invalid old dependencies rejected before mutation")
    var complete=Five.new();complete.single=solo;complete.restore_complete()
    complete.left_released=true;complete.right_released=true;complete.cleared_segments=3
    var old_complete:Dictionary=M28.capture(complete)
    check(migrated.restore_checkpoint(old_complete) and migrated.finished and migrated.network_lit,"old completed journey remains completed")
    check(migrated.extraction_side=="restored" and migrated.charged_route=="tower","historical completion labelled restored, not invented player route")
    roundtrip(migrated,"migrated-complete-"+str(solo))
    var ancient:Dictionary=preload("res://game/puzzle_legacy_checkpoint.gd").capture(complete)
    check(migrated.restore_checkpoint(ancient) and migrated.finished,"pre-M28 completed record remains completed")
    var old_test=complete
    old_test.finished=false;old_test.phase="test";old_test.tested=false;old_test.network_lit=false
    old_test.tag_inserted=false;old_test.gear_stored=false;old_test.paws_clean=false;old_test.cat_one_clean=false;old_test.cat_two_clean=false
    var unverified:Dictionary=M28.capture(old_test)
    check(migrated.restore_checkpoint(unverified),"old unverified pilot snapshot migrates")
    check(not migrated.pilot_charged and migrated.charged_route=="none","old unverified global charge cannot invent destination evidence")

    var next:Dictionary=fixture(solo).checkpoint()
    for field in ["machine_stopped","tested","network_lit","paws_clean"]:
        var bad:Dictionary=next.duplicate(true);bad.facts[field]=true
        before=migrated.checkpoint()
        check(not migrated.restore_checkpoint(bad) and migrated.checkpoint()==before,"new dependent fact rejects impossible "+field)
    var mismatch:Dictionary=migrated.checkpoint();mismatch.facts.charged_route="market"
    check(not migrated.restore_checkpoint(mismatch),"saved pilot route must match actual charged destination")
