extends RefCounted
## Intent and damage use player slots; move identity is resolved from the roster.
const CHARGE_SECONDS := 0.42
const BUFFER_SECONDS := 0.18
const HURT_LOCK := 0.08
var charging := false
var charging_slot := -1
var charge_time := 0.0
var kinds: Array[String] = ["sword","claw"]
var durations: Array[float] = [0.30,0.26]
var pending: Array[float] = [-1.0,-1.0]
var buffered: Array[float] = [0.0,0.0]
var skill_buffer: Array[float] = [0.0,0.0]
var skill_owner: Array[int] = [-1,-1]
var skill_generation: Array[int] = [-1,-1]
var impact_times: Array[float] = [0.065,0.045]
var specs: Array[Dictionary] = [{},{}]
var active_left: Array[float] = [0.0,0.0]
var pounce_left: Array[float] = [0.0,0.0]
var pounce_hit: Array[bool] = [false,false]
var combo := 0
var combo_window := 0.0
var current_combo := 0
func available(b,slot: int) -> bool:
    return slot in b.deployed_slots() and b.hp[slot]>0 and b.phase not in ["complete","failed"] and b.attack_cooldown[slot]<=0 and b.dodge_time[slot]<=0 and b.contact_hold[slot]<=0 and b.hurt_time[slot]<=0.22-HURT_LOCK+0.00001 and not (b.actor(slot)==0 and b.guarding) and not (charging and charging_slot==slot)
func locked(slot: int) -> bool:
    return pending[slot]>=0 or active_left[slot]>0 or pounce_left[slot]>0
func aim(b,slot: int) -> Vector2:
    var direction: Vector2 = b.facing[slot]
    var nearest := INF
    for enemy in b.enemies:
        if enemy.hp<=0: continue
        var offset: Vector2 = enemy.pos-b.positions[b.actor(slot)]
        if offset.length()<nearest and offset.length()<145 and offset.length()>0.1 and direction.dot(offset.normalized())>=cos(deg_to_rad(16)) and b.Space.clear_line(b.positions[b.actor(slot)],enemy.pos,0):
            direction=offset.normalized();nearest=offset.length()
    return direction
func press(b,slot: int) -> void:
    if slot not in b.deployed_slots() or b.hp[slot]<=0 or b.phase in ["complete","failed"]: return
    skill_buffer[slot]=0
    if not available(b,slot):
        var remaining: float = maxf(b.attack_cooldown[slot],maxf(b.dodge_time[slot],b.hurt_time[slot]-(0.22-HURT_LOCK)))
        if not (b.actor(slot)==0 and b.guarding) and not (charging and charging_slot==slot) and (pending[slot]<0 or remaining<=BUFFER_SECONDS): buffered[slot]=remaining+BUFFER_SECONDS
        return
    buffered[slot]=0
    b.hurt_time[slot]=0
    if b.rescuer==slot:b._cancel_rescue()
    var role: int = b.actor(slot)
    if role==0:
        current_combo=combo if combo_window>0 else 0
        combo=(current_combo+1)%3;combo_window=0.85
        _begin(b,slot,"sword",0.38 if current_combo==2 else 0.30,0.11 if current_combo==2 else 0.065,{"reach":112.0,"angle":PI/3,"damage":2 if current_combo==2 else 1,"push":22.0 if current_combo==2 else 10.0,"heavy":current_combo==2})
    elif role==1:
        _begin(b,slot,"claw",0.26,0.045,{"reach":78.0,"angle":PI/3,"damage":1,"single":true,"push":8.0})
    else:
        _begin(b,slot,"slap",0.30,0.065,{"reach":86.0,"angle":PI/3,"damage":1,"push":13.0})
func signature(b,slot: int) -> void:
    if slot not in b.deployed_slots() or b.hp[slot]<=0 or b.phase in ["failed","complete"]:return
    var role: int = b.actor(slot)
    if role==0:
        b.hold_guard(true)
        return
    if not available(b,slot) or b.signature_cooldown[slot]>0:
        var remaining: float=maxf(b.signature_cooldown[slot],maxf(b.attack_cooldown[slot],maxf(b.dodge_time[slot],b.hurt_time[slot]-(0.22-HURT_LOCK))))
        if not (charging and charging_slot==slot) and remaining<=BUFFER_SECONDS and remaining>0:
            skill_buffer[slot]=BUFFER_SECONDS;skill_owner[slot]=role;skill_generation[slot]=b.generation[slot];buffered[slot]=0
        else:b.feedback("not_ready",b.positions[role],slot,{"remaining":remaining})
        return
    skill_buffer[slot]=0;buffered[slot]=0
    if b.rescuer==slot:b._cancel_rescue()
    if role==1:
        pounce_left[slot]=80;pounce_hit[slot]=false
        b.signature_cooldown[slot]=1.2
        _begin(b,slot,"pounce",0.34,0.08,{"reach":68.0,"angle":PI/5,"damage":1,"single":true,"interrupt":true,"push":12.0})
    else:
        charging=true;charging_slot=slot;charge_time=0
        kinds[slot]="charge";buffered[slot]=0
        b.feedback("charge",b.positions[role],slot)
func release_signature(b,slot: int) -> void:
    if slot not in b.deployed_slots():return
    if b.actor(slot)==0:b.hold_guard(false)
    if b.actor(slot)==2:skill_buffer[slot]=0
    if not charging or charging_slot!=slot:return
    var heavy := charge_time>=CHARGE_SECONDS-0.00001
    charging=false;charging_slot=-1;charge_time=0
    if b.actor(slot)!=2 or b.hp[slot]<=0 or b.phase in ["failed","complete"]:return
    if not heavy:
        kinds[slot]="slap"
        b.feedback("release",b.positions[2],slot)
        return
    b.signature_cooldown[slot]=0.70
    _begin(b,slot,"heavy",0.40,0.09,{"reach":113.0,"angle":PI/2,"damage":3,"heavy":true,"push":45.0,"control":0.40})
func release(_b,_slot: int) -> void: pass # Basic attacks are taps; no held ownership.
func _begin(b,slot: int,kind: String,duration: float,impact: float,spec: Dictionary) -> void:
    kinds[slot]=kind;specs[slot]=spec
    durations[slot]=duration;impact_times[slot]=impact
    pending[slot]=impact;active_left[slot]=0
    b.attack_cooldown[slot]=duration;b.attack_flash[slot]=duration
    b.attack_direction[slot]=aim(b,slot)
    b.feedback("swing",b.positions[b.actor(slot)],slot,{"attack":kind,"direction":b.attack_direction[slot],"combo":current_combo if b.actor(slot)==0 else 0})
func cancel(b,slot: int=-1) -> void:
    if slot<0 or slot==charging_slot:charging=false;charging_slot=-1;charge_time=0
    if slot<0 or (slot in b.deployed_slots() and b.actor(slot)==0):combo=0;combo_window=0
    for index in range(2):
        if slot<0 or slot==index:
            pending[index]=-1;buffered[index]=0;skill_buffer[index]=0;skill_owner[index]=-1;skill_generation[index]=-1;active_left[index]=0;pounce_left[index]=0;pounce_hit[index]=false
            b.contact_hold[index]=0;b.attack_flash[index]=0
func step(b,dt: float) -> void:
    combo_window=maxf(0,combo_window-b.action_dt[0])
    for enemy in b.enemies:
        var pause: float=enemy.get("impact_pause",0.0)
        var local: float=maxf(0,dt-pause)
        enemy.impact_pause=maxf(0,pause-dt);enemy.simulation_dt=local
        enemy.impact_age=enemy.get("impact_age",1.0)+local
        enemy.weave_break=maxf(0,enemy.get("weave_break",0.0)-local)
        enemy.link_flash=maxf(0,enemy.get("link_flash",0.0)-local)
        enemy.control_immune=maxf(0,enemy.get("control_immune",0.0)-local)
        enemy.control_time=maxf(0,enemy.get("control_time",0.0)-local)
    for slot in b.deployed_slots():
        var local: float=b.action_dt[slot]
        active_left[slot]=maxf(0,active_left[slot]-local)
        if pending[slot]>=0:
            pending[slot]-=local
            if pending[slot]<=0:
                pending[slot]=-1;active_left[slot]=0.045
                if kinds[slot]!="pounce":strike(b,slot,specs[slot])
        if pounce_left[slot]>0 and pending[slot]<0 and local>0 and b.contact_hold[slot]<=0:
            var origin: Vector2=b.positions[b.actor(slot)]
            var amount: float=minf(pounce_left[slot],500*local)
            var end: Vector2=b.Space.move(origin,b.attack_direction[slot]*amount,b.Space.ACTOR_RADIUS)
            var fraction:=1.0
            for enemy in b.enemies:
                if enemy.hp<=0:continue
                var t: float=b.Space.contact(origin,end,enemy.pos,44)
                if t!=INF:fraction=minf(fraction,maxf(0,t-0.001))
            b.positions[b.actor(slot)]=origin.lerp(end,fraction)
            pounce_left[slot]=maxf(0,pounce_left[slot]-amount)
            if fraction<1 or origin.distance_to(end)<amount*0.5:pounce_left[slot]=0
            if not pounce_hit[slot]:pounce_hit[slot]=strike(b,slot,specs[slot])
        if skill_buffer[slot]>0:
            if skill_owner[slot]!=b.actor(slot) or skill_generation[slot]!=b.generation[slot]:skill_buffer[slot]=0
            elif available(b,slot) and b.signature_cooldown[slot]<=0:signature(b,slot)
            else:skill_buffer[slot]=maxf(0,skill_buffer[slot]-local)
        if buffered[slot]>0:
            if available(b,slot):press(b,slot)
            else:buffered[slot]=maxf(0,buffered[slot]-local)
    if charging:
        var before:=charge_time
        charge_time=minf(CHARGE_SECONDS,charge_time+b.action_dt[charging_slot])
        if before<CHARGE_SECONDS and charge_time>=CHARGE_SECONDS:b.feedback("ready",b.positions[b.actor(charging_slot)],charging_slot)
func strike(b,slot: int,spec: Dictionary) -> bool:
    var origin: Vector2=b.positions[b.actor(slot)]
    var direction: Vector2=b.attack_direction[slot]
    var heavy: bool=spec.get("heavy",false)
    var seed_hit: bool=b.garden.strike(b,origin,direction,spec.reach,spec.angle,heavy)
    var targets: Array[Dictionary]=[]
    for enemy in b.enemies:
        if enemy.hp<=0:continue
        var offset: Vector2=enemy.pos-origin
        if offset.length()<=spec.reach and (offset.length()<0.01 or direction.dot(offset.normalized())>=cos(spec.angle)) and b.Space.clear_line(origin,enemy.pos,0):targets.append(enemy)
    targets.sort_custom(func(a,c):return origin.distance_squared_to(a.pos)<origin.distance_squared_to(c.pos))
    for enemy in targets:
        var link: Dictionary=b.linked_source(enemy)
        var vine_block: bool=not link.is_empty() and enemy.direction.dot(enemy.pos.direction_to(origin))>0.20
        var blocked: bool=vine_block or (enemy.kind=="armored" and (enemy.mode!="exposed" or enemy.direction.dot(enemy.pos.direction_to(origin))>-0.20))
        if blocked:
            enemy.bounce=0.2
            if vine_block:link.link_flash=0.20
            b.feedback("blocked",enemy.pos,slot,{"direction":direction,"target_id":enemy.id,"reason":"vine_link" if vine_block else "shell"})
        else:
            var amount: float=spec.damage
            if enemy.kind=="elder" and enemy.mode!="exposed" and enemy.direction.dot(enemy.pos.direction_to(origin))>0.2:amount*=0.4
            enemy.hp=maxf(0,enemy.hp-amount);enemy.flash=0.13
            b.feedback("heavy" if heavy else "hit",enemy.pos,slot,{"direction":direction,"attack":kinds[slot],"target_id":enemy.id})
            if spec.get("interrupt",false) and enemy.mode in ["cast","melee_windup"] and enemy.get("control_immune",0.0)<=0:
                enemy.mode="rest";enemy.timer=0.85;enemy.control_immune=2.2;enemy.weave_break=2.2
                enemy.erase("aim")
                b.feedback("interrupt",enemy.pos,slot,{"target_id":enemy.id})
            if spec.get("control",0.0)>0 and enemy.hp>0:
                if enemy.kind=="armored":enemy.timer=maxf(enemy.timer,0.9)
                elif enemy.mode!="rush" and enemy.get("control_immune",0.0)<=0:
                    enemy.mode="rest";enemy.timer=0.30;enemy.control_time=spec.control;enemy.control_immune=2.2;enemy.weave_break=2.2;enemy.erase("aim")
                    b.feedback("control",enemy.pos,slot,{"target_id":enemy.id})
            if enemy.kind!="armored" and enemy.mode!="rush":enemy.pos=b.Space.move(enemy.pos,direction*spec.get("push",0.0),b.Space.ENEMY_RADIUS)
        b.contact(enemy,slot,direction,heavy,blocked)
        if spec.get("single",false):break
    return not targets.is_empty() or seed_hit
