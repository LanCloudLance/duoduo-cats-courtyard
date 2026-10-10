extends RefCounted
const Encounter = preload("res://game/battle_encounter.gd")
const Attacks = preload("res://game/battle_attacks.gd")
const Roster = preload("res://game/battle_roster.gd")
const Layout = preload("res://game/battle_layout.gd")
var roster = Roster.new()
var Space = Layout.new()
var attacks = Attacks.new()
var garden = preload("res://game/battle_terrain.gd").new()
var FIELD: Rect2:
    get: return Space.FIELD
var EXIT: Vector2:
    get: return Space.EXIT
const RESCUE_SECONDS := 1.2
const SWAP_SECONDS := 0.60
var context: Dictionary = {}
var positions: Array[Vector2] = [Vector2(295,470),Vector2(335,570),Vector2(205,175)]
var current_cat := 1
var solo_mode := false
var story_first := false
var story_encounter := "practice"
var wave_total := 2
var hp: Array[int] = [3,3]
var facing: Array[Vector2] = [Vector2.RIGHT,Vector2.RIGHT]
var velocity: Array[Vector2] = [Vector2.ZERO,Vector2.ZERO]
var attack_cooldown: Array[float] = [0.0,0.0]
var signature_cooldown: Array[float] = [0.0,0.0]
var attack_flash: Array[float] = [0.0,0.0]
var attack_direction: Array[Vector2] = [Vector2.RIGHT,Vector2.RIGHT]
var dodge_time: Array[float] = [0.0,0.0]
var dodge_cooldown: Array[float] = [0.0,0.0]
var dodge_direction: Array[Vector2] = [Vector2.RIGHT,Vector2.RIGHT]
var invulnerable: Array[float] = [0.0,0.0]
var action_dt: Array[float] = [0.0,0.0]
var contact_hold: Array[float] = [0.0,0.0]
var contact_progress: Array[float] = [0.0,0.0]
var hurt_time: Array[float] = [0.0,0.0]
var swap_cooldown: Array[float] = [0.0,0.0]
var swap_pending: Array[float] = [0.0,0.0]
var generation: Array[int] = [0,0]
var guarding := false
var guard_held := false
var guard_age := 0.0
var fx: Array[Dictionary] = []
var feedback_id := 0
var last_feedback := ""
var fallen: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var seeds: Array[Dictionary] = []
var hazards: Array[Dictionary] = []
var next_enemy_id := 1
var wave := 0
var cleared_segments := 0
var phase := "briefing"
var confirmed: Array[bool] = [false,false]
var intermission := 0.0
var retry_time := 0.0
var retries := 0
var rescuer := -1
var rescue_progress := 0.0
var message := "看清小路，再出发。"
var plant_noticed := false
func _init() -> void: garden.setup(self)
func configure(value: Dictionary) -> bool:
    var id: String=str(value.get("id","practice"))
    var mode: String=str(value.get("mode","dual"))
    var allowed=value.get("available_role_ids",[0,1] if id=="first" else [0,1,2])
    var selected=value.get("selected_role_id",0)
    var cat=value.get("current_cat",1)
    var cleared=value.get("cleared_segments",0)
    if id not in ["first","shell","reserve","practice"] or not allowed is Array or not selected is int or not cat is int or not cleared is int or cleared<0 or cleared>2:return false
    if id=="first" and 2 in allowed:return false
    var candidate=Roster.new()
    if not candidate.configure(mode,allowed,selected,cat):return false
    roster=candidate;solo_mode=roster.single;story_encounter=id;story_first=id=="first";current_cat=cat
    context=value.duplicate(true);Space.configure(id);cleared_segments=cleared;wave=cleared
    phase="clear" if cleared==2 else "briefing" if cleared==0 else "intermission"
    for slot in deployed_slots():positions[actor(slot)]=Space.STARTS[slot]
    park_reserves();garden.setup(self)
    message="小路露出来了。" if cleared==2 else "准备好了再出发。"
    return true
func result() -> Dictionary:
    return {"encounter_id":story_encounter,"mode":"solo" if solo_mode else "dual","completed_segments":cleared_segments,"outcome":"complete" if phase=="complete" else "failed" if phase=="failed" else "in_progress","selected_role_id":actor(0),"current_cat":current_cat,"story_run_id":context.get("story_run_id",""),"return_chapter":context.get("return_chapter",0),"return_phase":context.get("return_phase","")}
func deployed_slots() -> Array[int]:return roster.deployed_slots()
func available_roles() -> Array:return roster.available.duplicate()
func actor(slot: int) -> int:return roster.role_for_slot(slot)
func role_slot(role: int) -> int:return roster.role_slot(role)
func alive_slots() -> Array[int]:
    var result_slots: Array[int]=[]
    for slot in deployed_slots():
        if hp[slot]>0:result_slots.append(slot)
    return result_slots
func park_reserves() -> void:
    var reserves: Array[int]=roster.reserves()
    for index in range(reserves.size()):positions[reserves[index]]=Space.reserve_point(index)
func feedback(kind: String,point: Vector2,slot: int,detail: Dictionary={}) -> void:
    feedback_id+=1;last_feedback=kind
    var event: Dictionary={"id":feedback_id,"kind":kind,"pos":point,"slot":slot,"role":actor(slot) if slot in deployed_slots() else -1,"life":0.26}
    event.merge(detail,true);fx.append(event)
    if fx.size()>48:fx.pop_front()
func feedback_since(cursor: int) -> Array[Dictionary]:return fx.filter(func(event):return event.id>cursor)
func contact(enemy: Dictionary,slot: int,direction: Vector2,heavy: bool,blocked: bool) -> void:
    contact_hold[slot]=maxf(contact_hold[slot],0.032 if blocked else 0.070 if heavy else 0.042)
    contact_progress[slot]=1.0-attack_flash[slot]/attacks.durations[slot]
    enemy.impact_pause=maxf(enemy.get("impact_pause",0.0),contact_hold[slot]);enemy.simulation_dt=0.0
    enemy.impact_age=0.0;enemy.impact_direction=direction;enemy.impact_power=4.0 if blocked else 26.0 if heavy else 11.0
func _bounded(point: Vector2) -> Vector2:return point.clamp(FIELD.position+Vector2.ONE*26,FIELD.end-Vector2.ONE*26)
func linked_source(enemy: Dictionary) -> Dictionary:
    if story_encounter!="shell" or enemy.kind not in ["thorn","sprout"] or enemy.hp<=0:return {}
    for source in enemies:
        if source.kind=="weaver" and source.hp>0 and source.get("weave_break",0.0)<=0 and Space.clear_line(source.pos,enemy.pos,0):return source
    return {}
func nearest_slot(point: Vector2) -> int:
    var found: int=-1
    var distance:=INF
    for slot in alive_slots():
        var d: float=point.distance_squared_to(positions[actor(slot)])
        if d<distance:found=slot;distance=d
    return found
func interact(slot: int) -> void:
    if slot not in deployed_slots() or phase=="complete":return
    if phase=="failed":
        if retry_time>0:return
        confirmed[slot]=true
        if deployed_slots().all(func(s):return confirmed[s]):_retry_wave()
        return
    if hp[slot]<=0:return
    if not solo_mode and hp[1-slot]<=0:
        if positions[actor(slot)].distance_to(positions[actor(1-slot)])<=85:
            attacks.cancel(self,slot)
            if rescuer!=slot:rescuer=slot;rescue_progress=0
            message="扶住伙伴。"
        else:message="伙伴还在那边。"
        return
    if phase in ["briefing","intermission"]:
        if intermission>0:return
        confirmed[slot]=true
        if deployed_slots().all(func(s):return confirmed[s]):_start_wave(cleared_segments+1)
    elif phase=="clear":
        if positions[actor(slot)].distance_to(EXIT)>95:message="出口已经安全了。";return
        confirmed[slot]=true
        if deployed_slots().all(func(s):return confirmed[s] and positions[actor(s)].distance_to(EXIT)<=95):
            phase="complete";cancel_attacks();message="小路清开了。伙伴都在。"
func request_switch(slot: int) -> bool:
    if slot not in deployed_slots() or roster.next_role(slot)<0 or phase=="complete" or (hp[slot]<=0 and phase!="failed") or swap_cooldown[slot]>0:return false
    if phase!="failed" and _switch_locked(slot):swap_pending[slot]=0.18;return true
    _apply_switch(slot);return true
func switch_cat() -> void:request_switch(0 if solo_mode else 1)
func _switch_locked(slot: int) -> bool:
    return attacks.locked(slot) or contact_hold[slot]>0 or dodge_time[slot]>0.10 or hurt_time[slot]>0.14
func _apply_switch(slot: int) -> void:
    var incoming: int=roster.next_role(slot)
    if incoming<0:return
    var point: Vector2=positions[actor(slot)]
    var recovery: float=attack_cooldown[slot]
    attacks.cancel(self,slot)
    if actor(slot)==0:hold_guard(false)
    roster.roles[slot]=incoming;positions[incoming]=point
    if incoming>0:current_cat=incoming
    attack_cooldown[slot]=recovery
    generation[slot]+=1;swap_pending[slot]=0;swap_cooldown[slot]=SWAP_SECONDS
    if rescuer==slot:_cancel_rescue()
    park_reserves();feedback("swap",point,slot)
func attack(slot: int) -> void:attacks.press(self,slot)
func release_attack(slot: int) -> void:attacks.release(self,slot)
func signature(slot: int) -> void:attacks.signature(self,slot)
func release_signature(slot: int) -> void:attacks.release_signature(self,slot)
func cancel_attacks() -> void:
    attacks.cancel(self);hold_guard(false);swap_pending=[0.0,0.0]
    for slot in range(2):generation[slot]+=1
func hold_guard(value: bool) -> void:
    guard_held=value and actor(0)==0
    guarding=guard_held and hp[0]>0 and dodge_time[0]<=0 and hurt_time[0]<=0.14 and not attacks.locked(0)
    if not guarding:guard_age=0
func dodge(slot: int,direction: Vector2) -> void:
    if slot not in deployed_slots() or hp[slot]<=0 or dodge_cooldown[slot]>0 or phase in ["complete","failed"]:return
    if rescuer==slot:_cancel_rescue()
    attacks.cancel(self,slot);attack_cooldown[slot]=minf(attack_cooldown[slot],0.08);hurt_time[slot]=0
    dodge_direction[slot]=direction.normalized() if direction.length()>0.1 else facing[slot]
    dodge_time[slot]=0.22;dodge_cooldown[slot]=0.72
    feedback("dodge",positions[actor(slot)],slot,{"direction":dodge_direction[slot]})
    if actor(slot)==0:hold_guard(false)
func hurt(slot: int,source: Vector2,blockable:=true) -> bool:
    if slot not in deployed_slots() or hp[slot]<=0 or invulnerable[slot]>0 or dodge_time[slot]>0 or phase!="combat":return false
    if blockable and actor(slot)==0 and guarding and facing[slot].dot(positions[actor(slot)].direction_to(source))>=0.25:
        feedback("guard",positions[actor(slot)],slot,{"direction":facing[slot]});return false
    attacks.cancel(self,slot);generation[slot]+=1
    feedback("hurt",positions[actor(slot)],slot)
    attack_cooldown[slot]=0;hurt_time[slot]=0.22
    if actor(slot)==0:hold_guard(false)
    positions[actor(slot)]=Space.move(positions[actor(slot)],source.direction_to(positions[actor(slot)])*18,Space.ACTOR_RADIUS)
    hp[slot]-=1;invulnerable[slot]=1.2
    if rescuer==slot:_cancel_rescue()
    if hp[slot]==0:message="先退到安全处。" if solo_mode else "伙伴坐下了。"
    return true
func _cancel_rescue() -> void:rescuer=-1;rescue_progress=0
func _start_wave(number: int) -> void:
    cancel_attacks();_cancel_rescue();wave=number;phase="combat";confirmed=[false,false]
    enemies.clear();fallen.clear();garden.setup(self)
    Encounter.start(self,number);message=Encounter.objective(self,number)
func _spawn(kind: String,point: Vector2,protect_arrival:=true) -> void:
    if protect_arrival and (deployed_slots().any(func(s):return positions[actor(s)].distance_to(point)<190) or not Space.valid(point,Space.ENEMY_RADIUS)):
        var candidates: Array[Vector2]=[]
        for x in range(6):
            for y in range(4):
                var p: Vector2=FIELD.position+Vector2(65+x*(FIELD.size.x-130)/5,65+y*(FIELD.size.y-130)/3)
                if Space.valid(p,26) and deployed_slots().all(func(s):return positions[actor(s)].distance_to(p)>=190) and enemies.all(func(e):return e.pos.distance_to(p)>95):candidates.append(p)
        candidates.sort_custom(func(a,c):return a.distance_squared_to(point)<c.distance_squared_to(point))
        if not candidates.is_empty():point=candidates[0]
    var health: float={"sprout":4.0,"weaver":5.0,"armored":5.0,"elder":18.0,"roller":5.0}.get(kind,5.0)
    enemies.append({"id":next_enemy_id,"kind":kind,"pos":point,"hp":health,"max_hp":health,"mode":"approach","timer":0.7,"direction":Vector2.LEFT,"hit":{},"flash":0.0,"bounce":0.0,"target":nearest_slot(point),"opening":""})
    next_enemy_id+=1
func _retry_wave() -> void:
    retries+=1
    for slot in deployed_slots():
        positions[actor(slot)]=Space.STARTS[slot];hp[slot]=3;invulnerable[slot]=1.2
        attack_cooldown[slot]=0;signature_cooldown[slot]=0;dodge_cooldown[slot]=0;dodge_time[slot]=0;hurt_time[slot]=0
    park_reserves();retry_time=0;_start_wave(maxi(1,cleared_segments+1))
    message="只重试这一段；已经清开的路还在。"
func step(delta: float,p1: Vector2,p2: Vector2,enabled: bool) -> void:
    if not enabled or not is_finite(delta) or delta<=0 or not p1.is_finite() or not p2.is_finite():return
    var dt:=minf(delta,0.1)
    for effect in fx:effect.life-=dt
    fx=fx.filter(func(e):return e.life>0)
    if phase=="failed":
        retry_time=maxf(0,retry_time-dt)
        for slot in deployed_slots():swap_cooldown[slot]=maxf(0,swap_cooldown[slot]-dt)
        return
    if phase=="combat" and alive_slots().is_empty():
        phase="failed";retry_time=0.70;confirmed=[false,false];cancel_attacks();_cancel_rescue();message="在安全处重新准备。";return
    for body in fallen:body.death_age+=dt;body.flash=maxf(0,body.flash-dt)
    fallen=fallen.filter(func(body):return body.death_age<0.38)
    if guard_held:hold_guard(true)
    guard_age=guard_age+dt if guarding else 0.0
    for slot in deployed_slots():
        action_dt[slot]=maxf(0,dt-contact_hold[slot]);contact_hold[slot]=maxf(0,contact_hold[slot]-dt)
        var local: float=action_dt[slot]
        hurt_time[slot]=maxf(0,hurt_time[slot]-local);attack_cooldown[slot]=maxf(0,attack_cooldown[slot]-local)
        attack_flash[slot]=maxf(0,attack_flash[slot]-local);dodge_cooldown[slot]=maxf(0,dodge_cooldown[slot]-local)
        signature_cooldown[slot]=maxf(0,signature_cooldown[slot]-local);invulnerable[slot]=maxf(0,invulnerable[slot]-local)
        swap_cooldown[slot]=maxf(0,swap_cooldown[slot]-local)
    attacks.step(self,dt)
    var inputs: Array[Vector2]=[p1.limit_length(),p2.limit_length()]
    for slot in deployed_slots():
        if swap_pending[slot]>0:
            if not _switch_locked(slot):_apply_switch(slot)
            else:swap_pending[slot]=maxf(0,swap_pending[slot]-dt)
        if hp[slot]<=0 or phase=="complete":continue
        var local: float=0.0 if contact_hold[slot]>0 or hurt_time[slot]>0.14 else action_dt[slot]
        var motion: Vector2=inputs[slot]*(90.0 if actor(slot)==0 and guarding else 215.0)
        if attacks.charging and attacks.charging_slot==slot:motion*=0.55
        if attacks.pounce_left[slot]>0:motion=Vector2.ZERO
        if inputs[slot].length()>0.1 and attacks.pounce_left[slot]<=0:facing[slot]=inputs[slot].normalized()
        var dodging: bool=dodge_time[slot]>0
        if dodging:motion=dodge_direction[slot]*550;dodge_time[slot]=maxf(0,dodge_time[slot]-local)
        var before: Vector2=positions[actor(slot)]
        positions[actor(slot)]=_move_actor(before,motion*local,dodging);velocity[slot]=(positions[actor(slot)]-before)/dt
        if phase=="clear" and positions[actor(slot)].distance_to(EXIT)>95:confirmed[slot]=false
    if rescuer>=0:
        if inputs[rescuer].length()>0.1 or hp[rescuer]<=0 or positions[actor(rescuer)].distance_to(positions[actor(1-rescuer)])>85:_cancel_rescue()
        else:
            rescue_progress+=dt
            if rescue_progress>=RESCUE_SECONDS:
                hp[1-rescuer]=2;invulnerable[1-rescuer]=2;_cancel_rescue();message="一起站起来了。"
    if phase!="complete":garden.step(self,dt)
    if phase=="intermission":intermission=maxf(0,intermission-dt)
    elif phase=="combat":
        for enemy in enemies:
            if enemy.hp>0:_enemy_step(enemy,dt)
            else:
                var body: Dictionary=enemy.duplicate(true);body.death_age=0.0;fallen.append(body)
                feedback("defeat",enemy.pos,-1,{"direction":enemy.get("impact_direction",-enemy.direction),"target_id":enemy.id})
        enemies=enemies.filter(func(e):return e.hp>0)
        if enemies.is_empty() and not alive_slots().is_empty():
            cleared_segments=wave;phase="intermission" if wave<wave_total else "clear";intermission=0.8;confirmed=[false,false]
            hazards.clear();message="这段路清开了。" if wave<wave_total else "出口已经安全了。"

func _move_actor(origin: Vector2, offset: Vector2, dodging: bool) -> Vector2:
    var end := Space.move(origin,offset,Space.ACTOR_RADIUS)
    if dodging: return end
    # Same contact radius as pounce; tangential input slides, retreat always works.
    for enemy in enemies:
        if enemy.hp <= 0: continue
        var radial: Vector2 = enemy.pos.direction_to(origin)
        var distance: float = origin.distance_to(enemy.pos)
        if distance < 44.01:
            if end.distance_to(enemy.pos) >= distance: continue
            var slide: Vector2 = offset-radial*minf(0,offset.dot(radial))
            end = Space.move(origin,slide,Space.ACTOR_RADIUS)
        else:
            var t := Space.contact(origin,end,enemy.pos,44)
            if t != INF: end = origin.lerp(end,maxf(0,t-0.001))
    return end

func _busy(except_enemy: Dictionary) -> bool:
    var count := 0
    for other in enemies:
        if is_same(other,except_enemy) or other.hp <= 0: continue
        if other.mode in ["windup","rush","cast","burst","slam_windup","slam","melee_windup","melee"]:
            count += 1
            # Never stack melee and a major attack on the same player.
            if other.target == except_enemy.target: return true
    return count >= (1 if solo_mode else 2)
func _expose(enemy: Dictionary, cause: String) -> void:
    enemy.mode = "exposed" if enemy.kind in ["armored","elder"] else "rest"
    enemy.timer = (2.4 if cause == "shield" else 2.0) if enemy.kind == "armored" else 1.25
    var precise: bool=cause=="shield" and guard_age<=0.18
    if precise:enemy.timer+=0.60 if enemy.kind=="armored" else 0.45
    enemy.perfect_guard=precise
    if solo_mode and enemy.kind == "armored": enemy.timer += 0.8
    if enemy.kind == "elder": enemy.timer = 2.0 if cause == "stump" or guard_age <= 0.18 else 1.15
    if cause == "shield": feedback("parry" if guard_age <= 0.18 else "guard",enemy.pos,0)
    enemy.opening = cause
    enemy.heavy_extended = false
    if not alive_slots().is_empty():
        if enemy.kind == "armored":
            message = "背后的结点展开了。"
        else:
            message = "枝球停住了。"
func _rush(enemy: Dictionary, dt: float) -> void:
    var before: Vector2 = enemy.pos
    var speed := 560.0 if enemy.kind == "roller" else 480.0
    var end := _bounded(before+enemy.direction*speed*dt)
    var hits: Array[Dictionary] = []
    for stump in Space.STUMPS:
        var t := Space.contact(before,end,stump,Space.STUMP_RADIUS+Space.ENEMY_RADIUS)
        if t != INF: hits.append({"t":t,"kind":"stump","slot":-1})
    for slot in deployed_slots():
        if hp[slot] <= 0 or enemy.hit.has(slot): continue
        var shield: bool = slot == 0 and guarding and dodge_time[0] <= 0 and facing[0].dot(-enemy.direction) >= 0.25 and facing[0].dot(positions[0].direction_to(before)) >= 0.25
        var t := Space.contact(before,end,positions[actor(slot)],64.0 if shield else 44.0)
        if t != INF: hits.append({"t":t,"kind":"shield" if shield else "body","slot":slot})
    for other in enemies:
        if is_same(other,enemy) or other.hp <= 0 or other.kind == "armored": continue
        var t := Space.contact(before,end,other.pos,Space.ENEMY_RADIUS*2)
        if t != INF: hits.append({"t":t,"kind":"enemy","slot":-1,"enemy":other})
    hits.sort_custom(func(a,b): return a.t < b.t)
    for hit in hits:
        if hit.kind == "enemy":
            var other: Dictionary = hit.enemy
            other.hp = maxf(0,other.hp-1)
            other.flash = 0.13
            if other.mode != "rush":
                other.mode = "rest"
                other.timer = 0.7
                other.weave_break = 2.2
            enemy.pos = before.lerp(end,maxf(0,hit.t-0.001))
            _expose(enemy,"collision")
            feedback("interrupt",other.pos,-1)
            message = "枝条撞散了，后排停了。"
            return
        if hit.kind == "stump" or hit.kind == "shield":
            enemy.pos = before.lerp(end,maxf(0,hit.t-0.001))
            if hit.slot >= 0: enemy.hit[hit.slot] = true
            _expose(enemy,"shield" if hit.kind == "shield" else "stump")
            return
        hurt(hit.slot,positions[actor(hit.slot)]-enemy.direction*50)
        enemy.hit[hit.slot] = true
    enemy.pos = end
    if enemy.timer <= 0 or enemy.pos == before:
        if enemy.kind == "armored":
            _expose(enemy,"miss")
            enemy.timer = 1.7
            return
        enemy.mode = "rest"
        enemy.timer = 1.4 if enemy.kind == "armored" else (1.25 if enemy.kind == "thorn" else 1.65)
func _enemy_step(enemy: Dictionary, dt: float) -> void:
    dt = enemy.get("simulation_dt",dt)
    if dt <= 0: return
    if enemy.get("pose_mode","") != enemy.mode:
        enemy.pose_mode = enemy.mode
        enemy.pose_duration = maxf(enemy.timer,0.001)
        enemy.pose_elapsed = 0.0
    var held: bool = enemy.get("impact_pause",0.0) > 0 or enemy.get("control_time",0.0) > 0
    _enemy_ai(enemy,dt)
    if enemy.pose_mode != enemy.mode:
        enemy.pose_mode = enemy.mode
        enemy.pose_duration = maxf(enemy.timer,0.001)
        enemy.pose_elapsed = 0.0
    elif not held:
        enemy.pose_elapsed += dt

func _enemy_ai(enemy: Dictionary, dt: float) -> void:
    enemy.flash = maxf(0,enemy.flash-dt)
    enemy.bounce = maxf(0,enemy.bounce-dt)
    if enemy.get("control_time",0.0) > 0: return
    enemy.timer -= dt
    if Encounter.step(self,enemy,dt): return
    if enemy.mode == "approach":
        var target: int = nearest_slot(enemy.pos)
        if target<0:return
        enemy.target = target
        var offset: Vector2 = positions[actor(target)]-enemy.pos
        if offset.length() > 250:
            enemy.pos = Space.move(enemy.pos,Space.direction(enemy.pos,positions[actor(target)],Space.ENEMY_RADIUS)*85*dt,Space.ENEMY_RADIUS)
        elif enemy.timer <= 0 and not _busy(enemy):
            enemy.direction = offset.normalized() if offset.length() > 0.1 else Vector2.LEFT
            enemy.mode = "windup"
            enemy.timer = (0.9 if enemy.kind == "thorn" else 1.2)+(0.2 if solo_mode else 0.0)
    elif enemy.mode == "windup" and enemy.timer <= 0:
        enemy.mode = "rush"
        enemy.timer = 0.65 if enemy.kind == "roller" else 0.48
        enemy.hit.clear()
        enemy.opening = ""
    elif enemy.mode == "rush":
        _rush(enemy,dt)
    elif enemy.mode in ["rest","exposed"] and enemy.timer <= 0:
        enemy.mode = "approach"
        enemy.timer = 0.2
        enemy.opening = ""
