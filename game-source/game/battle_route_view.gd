extends RefCounted
# Presentation reads durable gameplay facts; it never confirms, heals or opens a route.
static func exit_badges(b,keyboard:bool)->Array[Dictionary]:
    var result:Array[Dictionary]=[]
    for slot in b.deployed_slots():
        var state:String="down" if b.hp[slot]<=0 else "away" if not b.at_exit(slot) else "confirmed" if b.confirmed[slot] else "ready"
        result.append({"slot":slot,"state":state,"key":("E" if slot==0 else "空格") if keyboard else "A"})
    return result
static func source_cue(enemy:Dictionary)->String:
    return "护藤松脱" if enemy.get("weave_break",0)>0 else ""
static func root_tether(b)->Dictionary:
    if b.encounter_revision!=2 or b.story_encounter!="shell":return {}
    if b.route_open:return {"state":"released"}
    for enemy in b.enemies:
        if enemy.id==b.objective_enemy_id and enemy.hp>0:
            var start:Vector2=enemy.pos+Vector2(0,-38)
            var end:Vector2=b.Space.GATE+Vector2(-12,-25)
            return {"state":"bound","from":start,"end":end,"middle":(start+end)*0.5+Vector2(-30,-25)}
    return {"state":"waiting"}
