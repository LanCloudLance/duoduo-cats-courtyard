extends "res://tests/m29_combat_driver.gd"
## Known-solution ordinary InputEvent pilot. Rev1 retains the old route unchanged.
var route_method:="objective"
func pilot(slot:int)->void:
    var b=arena.battle
    if b.encounter_revision==2 and b.phase=="clear" and b.hp[slot]>0 and (b.solo_mode or b.hp[1-slot]>0):
        var exit_point:Vector2=b.positions[b.actor(slot)]
        var exit_move:Vector2=b.Space.direction(exit_point,b.EXIT,18) if exit_point.distance_to(b.EXIT)>25 else Vector2.ZERO
        axis(slot,exit_move)
        if exit_move==Vector2.ZERO and tick_index%10==0:tap(slot,JOY_BUTTON_A)
        return
    if b.encounter_revision!=2 or b.phase!="combat" or b.hp[slot]<=0 or (not b.solo_mode and b.hp[1-slot]<=0):
        super.pilot(slot);return
    if b.story_encounter=="shell":
        var prior:String=target_order;target_order="backline";super.pilot(slot);target_order=prior;return
    var armor:Dictionary={}
    for enemy in b.enemies:
        if enemy.kind=="armored" and enemy.hp>0:armor=enemy;break
    var point:Vector2=b.positions[b.actor(slot)]
    if armor.is_empty():
        var goal:Vector2=b.Space.GATE-Vector2(72,0)
        axis(slot,b.Space.direction(point,goal,18) if point.distance_to(goal)>12 else Vector2.ZERO)
        if point.distance_to(goal)<=12 and tick_index%10==0:tap(slot,JOY_BUTTON_A)
        return
    if route_method=="defeat":super.pilot(slot);return
    # Remove the mobile blocker if playing alone; the armored source stays alive.
    if b.solo_mode and b.enemies.any(func(e):return e.kind=="sprout" and e.hp>0):
        super.pilot(slot);return
    # P2 first handles the mobile blocker, then joins the shared lure. Either
    # human may be targeted; an unattended far-away lure is not safe cooperation.
    if slot==1 and b.enemies.any(func(e):return e.kind=="sprout" and e.hp>0):
        super.pilot(slot);return
    var lure:Vector2=b.Space.GATE-Vector2(45,0)
    if armor.mode in ["windup","rush"]:
        if (armor.mode=="rush" or armor.timer<0.30) and b.Encounter.danger(armor,point,16):
            var escape:Vector2=armor.direction.orthogonal()
            if escape.y>0 or (absf(escape.y)<0.1 and escape.x>0):escape=-escape
            if not b.Space.valid(point+escape*100,18):escape=-escape
            axis(slot,escape)
            if b.dodge_cooldown[slot]<=0 and b.dodge_time[slot]<=0:
                tap(slot,JOY_BUTTON_B);dodge_events+=1
        else:axis(slot,Vector2.ZERO)
    else:
        axis(slot,b.Space.direction(point,lure,18) if point.distance_to(lure)>9 else Vector2.ZERO)
