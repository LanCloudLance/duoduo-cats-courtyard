extends SceneTree
# Explicit local-entry fixtures; ordinary InputEvent journeys are separate.
const Four=preload("res://game/chapter_four_state.gd")
const M28=preload("res://game/puzzle_m28_checkpoint.gd")
const ENTRY=Vector2(1170,570)
var checks:=0
var failed:=0
var records:Dictionary={}
func check(ok:bool,label:String)->void:
    checks+=1
    if not ok:failed+=1;print("FAIL ",label)
func use(s,role:int,point:Vector2,tool:=false)->void:
    s.positions[role]=point;s.action_time[role]=0
    if tool:s.tool(role)
    else:s.interact(role)
func ticks(s,n:=40)->void:
    for i in range(n):s.step(.05,Vector2.ZERO,Vector2.ZERO,true)
func settle(s)->void:
    for i in range(240):
        if not s.social_transition_active():break
        s.step(.05,Vector2.ZERO,Vector2.ZERO,true)
    while s.dialogue_active():s.advance_dialogue()
func entry(solo:bool):
    var s=Four.new();s.single=solo;s.cover_hooked=true;s.cloth=true;s.phase="meet"
    return s
func outside(s)->void:
    use(s,0,s.VIEW_DOOR);settle(s)
func inside(s)->void:
    if not s.visit_room.is_empty():use(s,0,s.VIEW_DOOR);settle(s)
func source(s)->void:
    s.facing[2]=Vector2.UP;use(s,2,s.DUCT_LIGHT)
func pulse(s)->void:
    use(s,0,s.ARROWS,true);ticks(s,27)
func fix(s)->void:
    use(s,0,s.PATCH);use(s,1,s.LATCH)
    s.facing[2]=Vector2(1,-1).normalized();use(s,2,s.SEAM_LIGHT);use(s,0,s.PATCH)
func roundtrip(s,label:String)->void:
    var value:Dictionary=s.checkpoint();var next=Four.new();next.single=s.single
    check(value.puzzle_revision==2,"C4 captures revision two "+label)
    check(next.restore_checkpoint(value),"valid checkpoint restores "+label)
    check(next.checkpoint().facts==value.facts,"durable facts preserved "+label)
    check(not next.patch_braced and not next.pulse_active and not next.trial_lit(),"restore clears temporary work "+label)
    records[label+str(s.single)]={"record":value,"solo":s.single}
func _init()->void:
    if OS.get_user_data_dir().get_file()!="DuoduoCatsCourtyard-qa-m30-puzzle":quit(2);return
    for solo in [true,false]:
        early_repair(solo);gate_first(solo);wrong_recovery(solo);old_records(solo)
        intermediate_old_records(solo);impossible_records(solo)
    var file=FileAccess.open("user://m30-c4-records.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(records));file.close()
    print("M30_C4_RULES: %d checks, %d failures"%[checks,failed]);quit(1 if failed else 0)
func early_repair(solo:bool)->void:
    var s=entry(solo);outside(s)
    use(s,0,s.PATCH);check(s.patch_braced,"cloth immediately enters real brace without NPC or diagnosis")
    use(s,1,s.LATCH);check(s.latch_fixed,"early brace permits permanent latch")
    roundtrip(s,"early-latch")
    s.facing[2]=Vector2(1,-1).normalized();use(s,2,s.SEAM_LIGHT);use(s,0,s.PATCH)
    check(s.shell_fixed and not s.shell_leak_seen,"early repair seals without inventing pre-repair leak")
    roundtrip(s,"early-sealed")
    inside(s);source(s);pulse(s)
    check(s.main_return_seen and s.inward_verified and s.leak_charge==0 and s.return_charge>0,"real early repaired main pulse leaves no leak and still returns")
    check(not s.diagnosis_ready() and not s.battle_requested and s.phase!="offer","one main pulse cannot invent isolation or battle")
    roundtrip(s,"early-verified")
    use(s,0,s.ARROWS);use(s,1,s.BRANCH);pulse(s)
    check(s.diagnosis_ready() and not s.battle_requested,"sufficient evidence does not auto-complete or summon battle")
    use(s,0,s.ALIGHT);settle(s)
    check(not s.battle_requested,"optional NPC no longer submits a battle report")
    outside(s);use(s,0,ENTRY)
    check(s.battle_requested and s.phase=="battle_one","real exterior tree route requests first encounter")
    roundtrip(s,"early-battle")
    s.after_battle()
    check(s.battles_finished==1 and s.phase=="offer" and s.shell_fixed and s.inward_verified,"real battle return honors all early work")
    roundtrip(s,"early-offer")
func gate_first(solo:bool)->void:
    var s=entry(solo);outside(s);use(s,0,ENTRY)
    check(s.battle_requested and not s.diagnosis_ready(),"tree gate may be cleared before diagnosis")
    s.after_battle()
    check(s.battles_finished==1 and s.phase=="investigate","first encounter does not fabricate diagnostic evidence")
    roundtrip(s,"gate-first")
    if s.visit_room.is_empty():outside(s)
    fix(s);inside(s);source(s);pulse(s)
    use(s,0,s.ARROWS);use(s,1,s.BRANCH);pulse(s)
    check(s.phase=="offer" and s.inward_verified and s.diagnosis_ready(),"gate-first repair and real experiments converge to offer")
    check(not s.shell_leak_seen,"gate-first early repair never invents leaked sample")
    roundtrip(s,"gate-first-offer")
func wrong_recovery(solo:bool)->void:
    var s=entry(solo);outside(s)
    use(s,1,s.LATCH);check(not s.latch_fixed,"unstable patch cannot latch")
    use(s,2,s.SEAM_LIGHT);check(not s.seam_seen,"unlatched cloth cannot yield seam")
    use(s,0,s.PATCH);s.positions[0]+=Vector2(-100,0);ticks(s,1)
    use(s,1,s.LATCH);check(not s.latch_fixed,"walking away actually releases support")
    use(s,0,s.PATCH);use(s,1,s.LATCH)
    s.facing[2]=Vector2.LEFT;use(s,2,s.SEAM_LIGHT);use(s,0,s.PATCH)
    check(s.latch_fixed and not s.shell_fixed and not s.seam_seen,"wrong light cannot seal but preserves fixed latch")
    inside(s);source(s);use(s,0,s.ARROWS,true);ticks(s,5);use(s,2,s.DUCT_LIGHT)
    check(not s.main_return_seen and not s.inward_verified,"interrupted sample cannot grant result")
    source(s);pulse(s);check(s.shell_leak_seen and not s.inward_verified,"unfixed sample visibly leaks without repaired proof")
    use(s,0,s.ARROWS);use(s,1,s.BRANCH);pulse(s)
    use(s,1,s.BRANCH);check(s.reconnected_seen and not s.reserve_available,"reconnect drains real rack lamp")
    use(s,1,s.BRANCH);pulse(s);check(s.reserve_available,"re-isolation recovers without resetting earned repair")
    outside(s);use(s,0,ENTRY);s.after_battle()
    check(s.phase=="exterior" and s.latch_fixed and not s.shell_fixed,"unfixed real battle return asks for remaining repair")
    fix(s);check(s.phase=="test" and not s.inward_verified,"sealed after battle still needs actual repaired sample")
    inside(s);source(s)
    if s.route_split:use(s,0,s.ARROWS)
    pulse(s);check(s.phase=="offer" and s.inward_verified,"repaired main pulse finishes after wrong hypotheses")
    roundtrip(s,"recovered-offer")
func old_records(solo:bool)->void:
    var old=entry(solo);old.early_patch=true;old.shell_examined=true
    var record:Dictionary=M28.capture(old);var live=Four.new();live.single=solo
    check(live.restore_checkpoint(record) and live.early_patch and not live.latch_fixed and not live.shell_fixed,"old loose early cloth does not become complete repair")
    old.restore_complete();record=M28.capture(old)
    check(live.restore_checkpoint(record) and live.finished and live.battles_finished==2,"old full chapter remains complete")
    records["old-complete"+str(solo)]={"record":record,"solo":solo}
    var bad:Dictionary=record.duplicate(true);bad.facts.latch_fixed=false
    var before:Dictionary=live.checkpoint()
    check(not live.restore_checkpoint(bad) and live.checkpoint()==before,"invalid old dependencies reject before migration mutation")
func intermediate_old_records(solo:bool)->void:
    for phase in ["battle_one","exterior","test","offer","home_offer","battle_two","rest"]:
        var old=entry(solo);old.phase=phase
        # Revision-one fixtures reproduce old mandatory diagnosis and battle order.
        old.branch_seen=true;old.reserve_hold_seen=true;old.main_return_seen=true;old.shell_examined=true;old.arrows_seen=true
        old.battles_finished=0 if phase=="battle_one" else 2 if phase=="rest" else 1
        old.latch_fixed=phase!="battle_one";old.seam_seen=old.latch_fixed
        old.shell_fixed=phase not in ["battle_one","exterior"]
        old.inward_verified=phase in ["offer","home_offer","battle_two","rest"]
        old.lantern_offered=phase in ["home_offer","battle_two","rest"]
        old.reserve_retained=phase in ["battle_two","rest"]
        var value:Dictionary=M28.capture(old);var live=Four.new();live.single=solo
        var historical=Four.new();historical.single=solo
        check(M28.restore(historical,value),"old fixture obeys frozen revision-one rules "+phase)
        check(live.restore_checkpoint(value),"old intermediate migration succeeds "+phase)
        check(live.latch_fixed==old.latch_fixed and live.shell_fixed==old.shell_fixed and live.battles_finished==old.battles_finished and live.inward_verified==old.inward_verified,"old intermediate keeps only actual durable results "+phase)
        check(live.battle_requested==(phase in ["battle_one","battle_two"]),"old active encounter still requests actual battle "+phase)
        if phase in ["exterior","battle_two"]:check(live.room_name()=="exterior","old implicit exterior room explicitly migrates")
        roundtrip(live,"migrated-"+phase)
func impossible_records(solo:bool)->void:
    var s=entry(solo);outside(s);fix(s);inside(s);source(s);pulse(s)
    var base:Dictionary=s.checkpoint();var live=Four.new();live.single=solo
    check(live.restore_checkpoint(base),"bad-record live baseline is valid")
    var variants:Array=[]
    var bad:Dictionary=base.duplicate(true);bad.facts.latch_fixed=false;variants.append(bad)
    bad=base.duplicate(true);bad.facts.seam_seen=false;variants.append(bad)
    bad=base.duplicate(true);bad.facts.main_return_seen=false;variants.append(bad)
    bad=base.duplicate(true);bad.phase="offer";variants.append(bad)
    bad=base.duplicate(true);bad.facts.battles_finished=1;bad.phase="offer";variants.append(bad)
    bad=base.duplicate(true);bad.facts.battles_finished=2;variants.append(bad)
    var before:Dictionary=live.checkpoint()
    for value in variants:check(not live.restore_checkpoint(value) and live.checkpoint()==before,"new impossible outcome/phase rejects without mutation")
    var offer:Dictionary=records["early-offer"+str(solo)].record.duplicate(true)
    offer.phase="investigate"
    check(not live.restore_checkpoint(offer) and live.checkpoint()==before,"fully earned offer cannot masquerade as canonical investigate")
