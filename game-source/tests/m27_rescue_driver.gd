extends RefCounted
# Test-only rescuer: read telegraphs and choose a safe side; send ordinary inputs.
const Companion=preload("res://game/companion_ai.gd")
var pathfinder=Companion.new()
var host
var b
var relocations:=0
var goal:=Vector2(INF,INF)
func _init(owner,battle)->void:host=owner;b=battle
func danger_in(point:Vector2)->float:
    var delay:=INF
    for hazard in b.hazards:
        if point.distance_to(hazard.pos)<hazard.radius+12:delay=minf(delay,maxf(0,0.65-hazard.age))
    for enemy in b.enemies:
        if b.Encounter.danger(enemy,point,15):delay=minf(delay,enemy.timer if enemy.mode in ["cast","windup","melee_windup","slam_windup"] else 0)
    return delay
func step(slot:int)->void:
    var point:Vector2=b.positions[b.actor(slot)]
    var partner:Vector2=b.positions[b.actor(1-slot)]
    if b.hp[slot]<=0:host.drive(slot,Vector2.ZERO);return
    var remaining:float=b.RESCUE_SECONDS-b.rescue_progress if b.rescuer==slot else b.RESCUE_SECONDS
    if point.distance_to(partner)<=78 and (danger_in(point)>remaining+0.05 or b.invulnerable[slot]>remaining+0.05):
        host.drive(slot,Vector2.ZERO)
        if b.rescuer<0:host.tap_key(KEY_E if slot==0 else KEY_SPACE)
        return
    var best:=point
    var score:=INF
    for i in range(16):
        var candidate:Vector2=partner+Vector2.from_angle(i*TAU/16)*67
        if not b.Space.valid(candidate,b.Space.ACTOR_RADIUS):continue
        var cost:float=point.distance_to(candidate)*0.1
        if danger_in(candidate)<1.3:cost+=10000
        for enemy in b.enemies:
            if enemy.hp<=0:continue
            cost+=maxf(0,190-candidate.distance_to(enemy.pos))*8
        if cost<score:best=candidate;score=cost
    if not goal.is_finite() or best.distance_to(goal)>25:relocations+=1
    goal=best
    var heading:Vector2=pathfinder.path(point,goal,b.enemies)
    # Leaving an unsafe rescue spot cancels naturally, as for a human player.
    host.drive(slot,heading)
    if b.dodge_cooldown[slot]<=0 and heading.length()>0.1 and (danger_in(point)<0.3 or b.enemies.any(func(e):return e.hp>0 and e.pos.distance_to(point)<58)):
        host.tap_key(KEY_Q if slot==0 else KEY_K)
