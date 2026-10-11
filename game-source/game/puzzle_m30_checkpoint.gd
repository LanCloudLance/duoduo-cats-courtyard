extends RefCounted
const M28=preload("res://game/puzzle_m28_checkpoint.gd")
const Legacy=preload("res://game/puzzle_legacy_checkpoint.gd")
## Save only durable, verified progress. Live commands must be issued again.
const PHASES := {
    2:["bridge","hook","window","complete"],
    3:["door","call","reunion","equipment","walkway","exit","map","complete"],
    4:["market","meet","investigate","battle_one","exterior","test","offer","home_offer","battle_two","rest","complete"],
    5:["approach","shield","lure","unjam","withdraw","test","release","network","farewell","home","complete"]}
const FLAGS := {
    2:["locked_a","locked_b","hook_owned","hook_practiced","shortcut_open","reverse_seen","rear_loaded_seen","outer_locked","cart_open"],
    3:["wick_found","wick_ready","wick_fitted","npc_called","door_open","joined","light_equipped","cat_lock","bridge_locked","light_released","narrow_open","rig_ready","exit_revealed","exit_low_latched","exit_high_latched","map_discovered"],
    4:["cover_hooked","cover_carried","cloth","duct_seen","branch_seen","arrows_seen","latch_fixed","seam_seen","shell_fixed","inward_verified","lantern_offered","reserve_retained","main_return_seen","shell_leak_seen","reserve_hold_seen","connected_split_seen","stall_seen","view_seen","early_patch","shell_examined","reconnected_seen","reserve_available"],
    5:["route_lock","route_supported","route_lit","bridge_locked","arm_locked","lid_open","machine_stopped","plate_aligned","tested","network_lit","home_tag","tag_inserted","farewell_gift","gear_stored","paws_clean","far_walkway","isolation_open","worklight_seen","lower_pin","upper_pin","pilot_open","pilot_charged","cat_one_clean","cat_two_clean"]}
const NUMBERS := {
    2:{"lamp_a":3,"lamp_b":3}, 3:{"door_angle":3,"board_angle":3,"rig_angle":1,"source_level":1,"high_mirror_angle":1},
    4:{"battles_finished":2}, 5:{"lid_pins":2,"wheel_notch":2,"stage_checkpoint":3,"arm_route":1,"pilot_route":1}}
const CHOICES := {2:{"support_site":["a","carried","cat_carried","b","far","outer"]},3:{},4:{"lamp_dest":["rack","carried","stall","view"],"visit_room":["","market","exterior"]},5:{"support_site":["rack","carried","left","right"],"extraction_side":["none","left","right","restored"],"charged_route":["none","tower","market"]}}
static func capture(s)->Dictionary:
    if not PHASES.has(s.chapter):return {}
    var facts:Dictionary={}
    for key in FLAGS[s.chapter]:facts[key]=s.get(key)
    for key in NUMBERS[s.chapter]:facts[key]=s.get(key)
    for key in CHOICES[s.chapter]:facts[key]=s.get(key)
    var points:Array=[]
    for p in s.positions:points.append([p.x,p.y])
    return {"version":2,"puzzle_revision":2 if s.chapter in [4,5] else 1,"chapter":s.chapter_key,"mode":"solo" if s.single else "dual","phase":s.phase,"completed":s.finished,"facts":facts,"positions":points,"controlled":s.controlled,"current_cat":s.current_cat,"history":s.history.duplicate()}
static func valid_history(value)->bool:
    if not value is Array or value.size()>32:return false
    for entry in value:
        if not entry is String or entry.length()>280:return false
    return true
static func integer(value,minimum:int,maximum:int)->bool:
    return (typeof(value)==TYPE_INT or typeof(value)==TYPE_FLOAT) and is_finite(float(value)) and float(value)==floor(float(value)) and value>=minimum and value<=maximum
static func implies(f:Dictionary,consequence:String,cause:String)->bool:return not f[consequence] or f[cause]
static func dependencies(chapter:int,f:Dictionary,phase:String,completed:bool)->bool:
    if completed!=(phase=="complete"):return false
    match chapter:
        2:
            if f.support_site!="a" and not f.locked_a:return false
            if f.locked_b!=(f.support_site=="far"):return false
            for pair in [["locked_b","locked_a"],["rear_loaded_seen","locked_a"],["locked_b","rear_loaded_seen"],["hook_owned","locked_b"],["hook_practiced","hook_owned"],["shortcut_open","hook_practiced"]]:
                if not implies(f,pair[0],pair[1]):return false
            if f.outer_locked and not f.locked_a:return false
            if f.cart_open and not f.hook_owned:return false
            if phase=="bridge" and f.locked_b:return false
            if phase=="hook" and (not f.locked_b or f.shortcut_open):return false
            if phase in ["window","complete"] and not (f.locked_b and f.hook_owned and (f.shortcut_open or f.cart_open)):return false
        3:
            if f.map_discovered and not f.rig_ready:return false
            for pair in [["wick_ready","wick_found"],["wick_fitted","wick_ready"],["npc_called","wick_fitted"],["door_open","npc_called"],["joined","door_open"],["light_equipped","joined"],["cat_lock","light_equipped"],["bridge_locked","cat_lock"],["narrow_open","bridge_locked"],["rig_ready","narrow_open"],["exit_low_latched","rig_ready"],["exit_high_latched","rig_ready"],["exit_revealed","rig_ready"]]:
                if not implies(f,pair[0],pair[1]):return false
            if f.exit_revealed!=(f.exit_low_latched and f.exit_high_latched):return false
            var required:Dictionary={"call":"npc_called","reunion":"door_open","equipment":"joined","walkway":"light_equipped","exit":"bridge_locked","map":"exit_revealed","complete":"exit_revealed"}
            if required.has(phase) and not f[required[phase]]:return false
            var milestones:Dictionary={"npc_called":"call","door_open":"reunion","joined":"equipment","light_equipped":"walkway","bridge_locked":"exit","exit_revealed":"map"}
            for key in milestones:
                if f[key] and PHASES[3].find(phase)<PHASES[3].find(milestones[key]):return false
        4:
            if f.visit_room!="" and phase not in ["meet","investigate","battle_one","exterior","test","offer","home_offer","battle_two","rest"]:return false
            for pair in [["cover_carried","cover_hooked"],["cloth","cover_hooked"],["branch_seen","cloth"],["main_return_seen","cloth"],["connected_split_seen","cloth"],["reserve_hold_seen","branch_seen"],["latch_fixed","cloth"],["seam_seen","latch_fixed"],["shell_fixed","latch_fixed"],["shell_fixed","seam_seen"],["inward_verified","shell_fixed"],["inward_verified","main_return_seen"],["lantern_offered","inward_verified"],["reserve_retained","lantern_offered"]]:
                if not implies(f,pair[0],pair[1]):return false
            if f.lamp_dest!="rack" and not f.reserve_available:return false
            if (f.stall_seen or f.view_seen) and not f.reserve_hold_seen:return false
            if f.reserve_available and not f.reserve_hold_seen:return false
            if f.shell_examined and not f.cloth:return false
            if f.early_patch and not (f.cloth and f.shell_examined):return false
            if f.reconnected_seen and not f.reserve_hold_seen:return false
            if phase!="market" and not f.cloth:return false
            var diagnosed:bool=f.reserve_hold_seen and (f.main_return_seen or f.connected_split_seen or f.reconnected_seen) and (f.shell_examined or f.shell_leak_seen)
            if phase in ["exterior","test","offer","home_offer","battle_two","rest","complete"] and not diagnosed:return false
            if phase in ["exterior","test","offer","home_offer","battle_two"] and f.battles_finished!=1:return false
            if phase in ["rest","complete"] and f.battles_finished!=2:return false
            if phase in ["market","meet","battle_one"] and f.battles_finished!=0:return false
            if phase=="investigate" and (f.battles_finished>1 or f.battles_finished==1 and diagnosed):return false
            if phase=="market" and (f.cloth or f.shell_fixed):return false
            if phase=="exterior" and f.shell_fixed:return false
            if phase in ["test","offer","home_offer","battle_two","rest","complete"] and not f.shell_fixed:return false
            if phase=="test" and f.inward_verified:return false
            if phase in ["offer","home_offer","battle_two","rest","complete"] and not f.inward_verified:return false
            if phase in ["home_offer","battle_two","rest","complete"] and not f.lantern_offered:return false
            if phase in ["battle_two","rest","complete"] and not f.reserve_retained:return false
            if phase in ["market","meet","investigate","battle_one","exterior","test","offer"] and f.lantern_offered:return false
            if phase in ["market","meet","investigate","battle_one","exterior","test","offer","home_offer"] and f.reserve_retained:return false
        5:
            if f.far_walkway and not f.bridge_locked:return false
            if (f.worklight_seen or f.isolation_open) and not f.lid_open:return false
            if f.pilot_open and not f.machine_stopped:return false
            if f.arm_route==1 and not f.far_walkway:return false
            if f.lid_pins!=int(f.lower_pin)+int(f.upper_pin):return false
            if f.machine_stopped!=(f.extraction_side!="none"):return false
            # Live extraction leaves the unique pin in its chosen support. No
            # post-extraction target can move it; historical migration carries
            # no trustworthy side provenance and is explicitly marked restored.
            if f.extraction_side in ["left","right"] and f.support_site!=f.extraction_side:return false
            if f.support_site!="rack" and not f.lid_open:return false
            if f.machine_stopped and not f.worklight_seen:return false
            if f.pilot_charged!=(f.charged_route!="none"):return false
            if f.pilot_charged and f.charged_route!=("tower" if f.pilot_route==0 else "market"):return false
            if f.pilot_charged and not (f.pilot_open and f.plate_aligned and f.machine_stopped):return false
            if f.tested and not f.pilot_charged:return false
            if f.paws_clean!=(f.cat_one_clean and f.cat_two_clean):return false
            if (f.cat_one_clean or f.cat_two_clean) and not f.tag_inserted:return false
            for pair in [["route_supported","route_lock"],["route_lit","route_supported"],["bridge_locked","route_lit"],["arm_locked","bridge_locked"],["lid_open","arm_locked"],["machine_stopped","lid_open"],["tested","machine_stopped"],["network_lit","tested"],["tag_inserted","network_lit"],["gear_stored","tag_inserted"],["paws_clean","tag_inserted"]]:
                if not implies(f,pair[0],pair[1]):return false
            if (f.lid_pins>0 and not f.arm_locked) or (f.lid_open!=(f.lid_pins==2)):return false
            var expected:=3 if f.machine_stopped else 2 if f.lid_open else 1 if f.arm_locked else 0
            if f.stage_checkpoint!=expected:return false
            if phase!="approach" and not f.bridge_locked:return false
            if phase in ["lure","unjam","withdraw","test","release","network","farewell","home","complete"] and not f.arm_locked:return false
            if phase in ["unjam","withdraw","test","release","network","farewell","home","complete"] and not f.lid_open:return false
            if phase in ["withdraw","test","release","network","farewell","home","complete"] and not f.machine_stopped:return false
            if phase in ["release","network","farewell","home","complete"] and not f.tested:return false
            if phase in ["network","farewell","home","complete"] and not f.network_lit:return false
            if phase in ["home","complete"] and not f.tag_inserted:return false
            if completed and not (f.gear_stored and f.paws_clean):return false
            if phase=="approach" and f.arm_locked:return false
            if phase=="shield" and f.arm_locked:return false
            if phase=="lure" and f.lid_open:return false
            if phase=="unjam" and f.machine_stopped:return false
            if phase=="withdraw" and f.tested:return false
            if phase=="test" and f.tested:return false
            if phase=="release" and f.network_lit:return false
            if phase=="network" and f.tag_inserted:return false
            if phase=="farewell" and (f.gear_stored or f.paws_clean):return false
    return true
static func restore(s,value:Dictionary)->bool:
    # Guard Variant types before comparison, including strict legacy readers.
    if not integer(value.get("version"),2,2):return false
    if not value.get("chapter") is String or value.chapter!=s.chapter_key:return false
    if not value.get("mode") is String or value.mode!=("solo" if s.single else "dual"):return false
    if value.has("puzzle_revision") and not integer(value.puzzle_revision,1,2):return false
    if not value.has("puzzle_revision"):
        var probe=s.get_script().new()
        probe.single=s.single
        if not Legacy.restore(probe,value):return false
        if value.get("completed")==true:
            var completed_state=s.get_script().new();completed_state.single=s.single;completed_state.restore_complete();completed_state.history.assign(value.get("history",[]))
            if not restore(s,capture(completed_state)):return false
            s.say("已恢复旧旅程的完成记录。探索纪念只保留实际发现的物件。")
            return true
        var fresh=s.get_script().new()
        fresh.single=s.single
        if not restore(s,capture(fresh)):return false
        s.say("旧旅程的章节已保留；这里的机关重新布置过，从本章安全入口继续。")
        return true
    if s.chapter==4 and value.get("puzzle_revision")==1:
        # Validate the complete old dependency graph before translating phases.
        var old_state=s.get_script().new();old_state.single=s.single
        if not M28.restore(old_state,value):return false
        if old_state.phase in ["exterior","battle_two"] and old_state.visit_room.is_empty():old_state.visit_room="exterior"
        if old_state.phase=="meet":old_state.phase="investigate"
        old_state.reconcile_progress()
        if not restore(s,capture(old_state)):return false
        s.say("旧旅程的补片、试光结果和实际开路成果已经保留。维修现在可以按自己的顺序继续。")
        return true
    if s.chapter==5 and value.get("puzzle_revision")==1:
        # Decode through the frozen strict schema before any migration mutation.
        var old_state=s.get_script().new();old_state.single=s.single
        if not M28.restore(old_state,value):return false
        old_state.left_released=false;old_state.right_released=false;old_state.cleared_segments=0
        old_state.extraction_side="restored" if old_state.machine_stopped else "none"
        # Revision one had no per-destination evidence. Preserve witnessed final
        # verification, but require a fresh pilot for an unfinished test.
        if not old_state.tested:old_state.pilot_charged=false
        old_state.charged_route=("tower" if old_state.pilot_route==0 else "market") if old_state.pilot_charged else "none"
        if old_state.phase=="unjam":
            old_state.support_site="rack"
            old_state.positions.assign(safe_points(old_state))
        if not restore(s,capture(old_state)):return false
        s.say("维修入口已更新。已锁好的桥、夹臂和检修盖保留；未取出的折枝从安全平台重新选侧。" if s.phase=="unjam" else "旧旅程的永久成果已经保留。")
        return true
    if value.get("puzzle_revision")!=(2 if s.chapter in [4,5] else 1):return false
    if value.get("version")!=2 or value.get("chapter")!=s.chapter_key or value.get("mode")!=("solo" if s.single else "dual"):return false
    var phase_value=value.get("phase")
    if not phase_value is String or phase_value not in PHASES[s.chapter] or typeof(value.get("completed"))!=TYPE_BOOL:return false
    var facts=value.get("facts")
    if not facts is Dictionary:return false
    for key in FLAGS[s.chapter]:
        if typeof(facts.get(key))!=TYPE_BOOL:return false
    for key in NUMBERS[s.chapter]:
        if not integer(facts.get(key),0,NUMBERS[s.chapter][key]):return false
    for key in CHOICES[s.chapter]:
        if not facts.get(key) is String or facts[key] not in CHOICES[s.chapter][key]:return false
    if facts.size()!=FLAGS[s.chapter].size()+NUMBERS[s.chapter].size()+CHOICES[s.chapter].size():return false
    if not dependencies(s.chapter,facts,phase_value,value.completed):return false
    if not integer(value.get("controlled"),0,2) or not integer(value.get("current_cat"),1,2):return false
    if not valid_history(value.get("history",[])):return false
    var raw=value.get("positions")
    if not raw is Array or raw.size()!=3:return false
    var points:Array[Vector2]=[]
    for point in raw:
        if not point is Array or point.size()!=2:return false
        for coordinate in point:
            if typeof(coordinate) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(coordinate)):return false
        var p:=Vector2(point[0],point[1])
        if not Rect2(90,180,1100,490).has_point(p):return false
        points.append(p)
    # All validation precedes mutation, so a damaged file cannot half-open a level.
    for key in facts:s.set(key,facts[key])
    s.phase=phase_value;s.finished=value.completed;s.controlled=int(value.controlled);s.current_cat=int(value.current_cat)
    s.dialogue.clear();s.dialogue_index=0;s.social_goals.clear();s.social_paths.clear();s.social_lines.clear();s.social_gesture.clear();s.social.clear();s.social_remaining=0;s.observations.clear()
    s.positions=points;s.battle_requested=false;s.follow_paths.clear();s.follow_goals.clear()
    s.history.assign(value.get("history",[]))
    for i in range(3):s.actions[i]="";s.action_time[i]=0.0;s.facing[i]=Vector2.RIGHT
    match s.chapter:
        2:s.lifted_a=s.locked_a;s.lifted_b=s.locked_b or s.outer_locked
        3:
            s.beam_held=false;s.npc_elapsed=0;s.light_released=s.bridge_locked
            if s.joined and not s.light_equipped:s.phase="equipment"
        4:
            s.visit_pending="none";s.clear_trial();s.route_split=false;s.bypass_isolated=false;s.market_beam=false;s.patch_braced=false
            if s.reserve_available and s.lamp_dest=="rack":s.reserve_charge=0.5;s.bypass_isolated=true
            s.battle_requested=s.phase in ["battle_one","battle_two"]
        5:
            s.clear_holds();s.care_pending=-1;s.home_rest_pending=false;s.gift_pending=false;s.fixed_light=false;s.boss_clock=0;s.arm_arrest=0;s.wheel_progress=0;s.pull_progress=0;s.test_progress=0
            s.wheel_motion=0;s.wheel_from=s.wheel_notch;s.outward_light=s.pilot_charged
            s.portal_confirms.assign([false,false,false])
    var fallback:Array=safe_points(s)
    for role in s.available_roles():
        if not s.follow_allowed(role,s.positions[role]):s.positions[role]=fallback[role]
    if s.controlled not in s.available_roles():s.controlled=0
    if s.current_cat not in s.available_roles():s.current_cat=1
    s.extras={}
    if s.chapter==2:
        if s.get("hook_owned"):s.extras["hook"]=true
        if s.get("reverse_seen"):s.extras["reverse_flow"]=true
        if s.finished:s.extras["white_seen"]=true
    elif s.chapter==3 and s.finished:s.extras={"joined":true,"fixed_light":true,"inward_route":true}
    elif s.chapter==4 and s.finished:s.extras={"shell_fixed":true,"inward_verified":true,"reserve_retained":true,"battles_finished":s.battles_finished}
    elif s.chapter==5:
        if s.network_lit:s.extras["outward_verified"]=true
        if s.farewell_gift:s.extras["wood_lamp"]=true
        if s.finished:s.extras["home_finished"]=true
    s.say("安全进度已恢复。已经修好的机关保留；保持中的光、盾和工具请重新操作。")
    return true
static func safe_points(s)->Array:
    match s.chapter:
        2:
            if s.phase in ["window","complete"] and (s.shortcut_open or s.cart_open):return [Vector2(1080,420),Vector2(1100,480),Vector2(1155,360)]
            if s.locked_b:return [Vector2(815,420),Vector2(835,480),Vector2(1155,360)]
            if s.locked_a:return [Vector2(580,420),Vector2(570,445),Vector2(1155,360)]
            return [Vector2(230,420),Vector2(270,480),Vector2(1155,360)]
        3:
            if s.bridge_locked:return [Vector2(920,425),Vector2(925,470),Vector2(900,490)]
            if s.door_open:return [Vector2(570,430),Vector2(550,470),Vector2(590,480)]
            return [Vector2(240,410),Vector2(250,470),Vector2(530,300)]
        4:return [Vector2(565,480),Vector2(610,520),Vector2(650,550)] if s.cloth else [Vector2(170,505),Vector2(215,550),Vector2(265,585)]
        5:
            if s.phase=="approach":return [Vector2(225,465),Vector2(265,540),Vector2(230,605)]
            return [Vector2(590,565),Vector2(760,620),Vector2(575,620)]
    return []
