extends Node
## Diagnostic known-solution pilot. Uses normal input events only, never game-state edits.
var router
var arena
var buttons: Dictionary={}
var skill_hold: Array[bool]=[false,false]
var basic_only:=false
var target_order: String="nearest"
var elapsed:=0.0
var tick_index:=0
var attack_events:=0
var dodge_events:=0
var signature_events:=0
var offside:=false
func _input(event: InputEvent) -> void:router.handle(event)
func send(event: InputEvent) -> void:
    Input.parse_input_event(event);Input.flush_buffered_events()
func axis(slot: int,vector: Vector2) -> void:
    for i in range(2):
        var e=InputEventJoypadMotion.new();e.device=slot+10;e.axis=JOY_AXIS_LEFT_X if i==0 else JOY_AXIS_LEFT_Y;e.axis_value=vector.x if i==0 else vector.y;send(e)
func button(slot: int,id: int,pressed: bool) -> void:
    var e=InputEventJoypadButton.new();e.device=slot+10;e.button_index=id;e.pressed=pressed;send(e)
func tap(slot: int,id: int) -> void:button(slot,id,true);button(slot,id,false)
func reset() -> void:
    for slot in [0,1]:axis(slot,Vector2.ZERO);button(slot,JOY_BUTTON_LEFT_SHOULDER,false)
    skill_hold.assign([false,false]);elapsed=0;tick_index=0;attack_events=0;dodge_events=0;signature_events=0
func pilot(slot: int) -> void:
    var b=arena.battle
    var role: int=b.actor(slot)
    var point: Vector2=b.positions[role]
    if b.phase in ["briefing","intermission","failed"]:
        axis(slot,Vector2.ZERO)
        if tick_index%12==0:tap(slot,JOY_BUTTON_A)
        return
    if b.hp[slot]<=0:axis(slot,Vector2.ZERO);return
    if b.phase=="clear":
        var move: Vector2=b.Space.direction(point,b.EXIT,18) if point.distance_to(b.EXIT)>55 else Vector2.ZERO
        axis(slot,move)
        if move==Vector2.ZERO and tick_index%10==0:tap(slot,JOY_BUTTON_A)
        return
    if b.phase!="combat":axis(slot,Vector2.ZERO);return
    if not b.solo_mode and b.hp[1-slot]<=0:
        var other: Vector2=b.positions[b.actor(1-slot)]
        axis(slot,b.Space.direction(point,other,18) if point.distance_to(other)>65 else Vector2.ZERO)
        if point.distance_to(other)<=65 and tick_index%12==0:tap(slot,JOY_BUTTON_A)
        return
    var target: Dictionary={}
    var best:=INF
    for e in b.enemies:
        if e.hp<=0:continue
        var score: float=point.distance_to(e.pos)+(300 if e.kind=="armored" and e.mode!="exposed" else 0)
        if target_order=="backline" and e.kind=="weaver":score-=1500
        if not b.solo_mode and slot==1:score-=170 if e.kind=="weaver" else 0
        if score<best:best=score;target=e
    if target.is_empty():axis(slot,Vector2.ZERO);return
    var aim: Vector2=point.direction_to(target.pos)
    var distance: float=point.distance_to(target.pos)
    var move:=Vector2.ZERO
    var danger:=false
    var evade:=Vector2.ZERO
    for e in b.enemies:
        if e.hp<=0:continue
        if b.Encounter.danger(e,point,25):
            if e.mode in ["windup","rush"]:
                danger=e.mode=="rush" or e.timer<0.40
                evade=e.direction.orthogonal()
                if not b.Space.valid(point+evade*100,18):evade=-evade
            elif e.mode in ["melee_windup","melee"]:
                danger=e.mode=="melee" or e.timer<0.18
                evade=e.pos.direction_to(point)
            elif e.mode in ["cast","burst"]:
                danger=e.mode=="burst" or e.timer<0.30;evade=e.get("aim",e.pos).direction_to(point)
                if evade.length()<0.1:evade=Vector2.UP
            if danger:break
    for hazard in b.hazards:
        if hazard.age>0.42 and point.distance_to(hazard.pos)<hazard.radius+16:
            danger=true;evade=hazard.pos.direction_to(point)
            if evade.length()<0.1:evade=Vector2.UP
    if danger and not (b.dodge_time[slot]>0):
        var best_escape:= -INF
        for i in range(16):
            var candidate:=Vector2.from_angle(i*TAU/16)
            var landing: Vector2=b.Space.move(point,candidate*100,18)
            var score: float=landing.distance_to(point)+candidate.dot(evade)*20-landing.distance_to(target.pos)*0.45
            for hazard in b.hazards:score-=maxf(0,hazard.radius+25-landing.distance_to(hazard.pos))*3
            for e in b.enemies:
                if e.mode in ["burst","rush","melee"] and b.Encounter.danger(e,landing,12):score-=180
            if score>best_escape:best_escape=score;move=candidate
        if b.attacks.charging and b.attacks.charging_slot==slot:button(slot,JOY_BUTTON_LEFT_SHOULDER,false);skill_hold[slot]=false
        if b.dodge_cooldown[slot]<=0:
            axis(slot,move);tap(slot,JOY_BUTTON_B);dodge_events+=1
    elif target.kind=="armored":
        if target.mode=="exposed":
            var rear: Vector2=target.pos-target.direction*67
            if target.direction.dot(target.pos.direction_to(point))>-0.25 or distance>(88 if role==0 else 62):move=b.Space.direction(point,rear,18)
            else:move=Vector2.ZERO
        else:
            # Keep a lateral retreat available; locked rush exposes its rear on a miss.
            var goal: Vector2=target.pos+target.direction*170
            move=b.Space.direction(point,goal,18) if distance>210 else Vector2.ZERO
    elif distance>58:move=b.Space.direction(point,target.pos,18)
    if b.attacks.charging and b.attacks.charging_slot==slot:
        if distance<100 and not danger:move=Vector2.ZERO
        if b.attacks.charge_time>=b.attacks.CHARGE_SECONDS:button(slot,JOY_BUTTON_LEFT_SHOULDER,false);skill_hold[slot]=false
    axis(slot,move)
    if not danger and b.dodge_time[slot]<=0 and (target.kind!="armored" or target.mode=="exposed" and target.direction.dot(target.pos.direction_to(point))<-0.25):
        if distance<=100 if role==0 else distance<=72:
            # A tiny direction event aims without moving the character between actions.
            axis(slot,aim)
            if not basic_only and role==2 and b.signature_cooldown[slot]<=0 and b.attack_cooldown[slot]<=0 and not b.attacks.charging:
                button(slot,JOY_BUTTON_LEFT_SHOULDER,true);skill_hold[slot]=true;signature_events+=1
            elif not basic_only and role==1 and target.mode in ["cast","melee_windup"] and b.signature_cooldown[slot]<=0 and b.attack_cooldown[slot]<=0:
                tap(slot,JOY_BUTTON_LEFT_SHOULDER);signature_events+=1
            elif b.attack_cooldown[slot]<=0 and not (b.attacks.charging and b.attacks.charging_slot==slot):
                tap(slot,JOY_BUTTON_X);attack_events+=1
            axis(slot,move)
func frame() -> void:
    tick_index+=1;elapsed+=1.0/60
    for slot in arena.battle.deployed_slots():pilot(slot)
    arena.battle.step(1.0/60,arena.session.movement(0),arena.session.movement(1),true)
