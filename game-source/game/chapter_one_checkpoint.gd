extends RefCounted
const BOOLS := ["supported","branch_clear","equipment","core_found","core_ready","core_installed","lit","clue_seen"]
const PHASES := ["arrival","road","battle","station","rest","complete"]
static func capture(s)->Dictionary:
    var facts:Dictionary={}
    for key in BOOLS:facts[key]=s.get(key)
    facts.hood=s.hood;facts.vent=s.vent;facts.carrier=s.carrier;facts.fork_pos=[s.fork_pos.x,s.fork_pos.y]
    var points:Array=[]
    for p in s.positions:points.append([p.x,p.y])
    return {"version":2,"chapter":"chapter-one","mode":"solo" if s.single else "dual","phase":s.phase,"completed":s.finished,"controlled":s.controlled,"facts":facts,"positions":points,"history":s.history.duplicate()}
static func point(value)->bool:
    if not value is Array or value.size()!=2:return false
    for number in value:
        if typeof(number) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(number)):return false
    return Rect2(90,210,1100,450).has_point(Vector2(value[0],value[1]))
static func restore(s,value:Dictionary)->bool:
    const Common=preload("res://game/story_checkpoint.gd")
    if value.get("version")!=2 or value.get("chapter")!="chapter-one" or value.get("mode")!=("solo" if s.single else "dual"):return false
    var p=value.get("phase");var f=value.get("facts");var points=value.get("positions")
    if not p is String or p not in PHASES or not f is Dictionary or f.size()!=BOOLS.size()+4:return false
    if typeof(value.get("completed"))!=TYPE_BOOL or value.completed!=(p=="complete") or not Common.integer(value.get("controlled"),0,1):return false
    for key in BOOLS:
        if typeof(f.get(key))!=TYPE_BOOL:return false
    if not Common.integer(f.get("hood"),0,3) or not Common.integer(f.get("vent"),0,2) or not Common.integer(f.get("carrier"),-1,1) or not point(f.get("fork_pos")):return false
    if not points is Array or points.size()!=2 or not point(points[0]) or not point(points[1]):return false
    if not Common.valid_history(value.get("history",[])):return false
    for pair in [["core_ready","core_found"],["core_installed","core_ready"],["lit","core_installed"]]:
        if f[pair[0]] and not f[pair[1]]:return false
    if p!="arrival" and not f.equipment:return false
    if p in ["battle","station","rest","complete"] and not f.branch_clear:return false
    if p in ["rest","complete"] and not f.lit:return false
    if p=="complete" and not f.clue_seen:return false
    if p=="arrival" and (f.equipment or f.supported or f.branch_clear):return false
    if p in ["arrival","road","battle"] and (f.core_found or f.clue_seen or f.lit):return false
    if p=="station" and f.lit:return false
    if p in ["station","rest","complete"] and f.carrier!=-1 and not (f.carrier==1 and f.core_found and not f.core_ready):return false
    for key in BOOLS:s.set(key,f[key])
    s.hood=int(f.hood);s.vent=int(f.vent);s.carrier=int(f.carrier);s.fork_pos=Vector2(f.fork_pos[0],f.fork_pos[1])
    s.phase=p;s.finished=value.completed;s.controlled=int(value.controlled)
    s.history.assign(value.get("history",[]))
    s.positions.assign([Vector2(points[0][0],points[0][1]),Vector2(points[1][0],points[1][1])])
    s.bracing=false;s.resting=0;s.steady=0;s.flame=1 if s.lit else 0;s.light_reveal=1 if s.lit else 0;s.battle_requested=p=="battle"
    s.actions.assign(["",""]);s.action_time.assign([0.0,0.0]);s.facing.assign([Vector2.RIGHT,Vector2.RIGHT])
    for role in range(2):
        if not s.walkable(s.positions[role],role):s.positions[role]=Vector2(550,480) if role==0 else Vector2(560,580)
    s.extras={"tag":true} if s.equipment else {}
    if s.clue_seen:s.extras["route"]=true
    s.say("安全进度已恢复。修好的枝架和灯保留；举起枝架的动作请重新操作。")
    return true
