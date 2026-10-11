extends RefCounted
## Samples the simulation's action clock; never owns hits or collision movement.
static func progress(enemy: Dictionary) -> float:
    var spans := {"windup":1.2,"rush":0.48,"melee_windup":0.5,"melee":0.22,"cast":0.85,"burst":0.22,"slam_windup":0.82,"slam":0.22,"rest":0.85,"exposed":1.25}
    var span: float=enemy.get("opening_duration",1.25) if enemy.mode=="exposed" else enemy.get("pose_duration",spans.get(enemy.mode,1.0)) if enemy.get("pose_mode","")==enemy.mode else spans.get(enemy.mode,1.0)
    return clampf(1.0-enemy.timer/maxf(span,0.001),0,1)
static func rear_openness(enemy: Dictionary) -> float:
    if enemy.mode!="exposed":return 0.0
    # Leaves draw inward during the final third of a second, rather than vanishing.
    return smoothstep(0.0,0.35,maxf(0,enemy.timer))
static func sample(enemy: Dictionary) -> Dictionary:
    var mode: String = enemy.mode
    var spans := {"windup":1.2,"rush":0.48,"melee_windup":0.5,"melee":0.22,
        "cast":0.85,"burst":0.22,"slam_windup":0.82,"slam":0.22,"rest":0.85,"exposed":1.25}
    var tracked: bool = enemy.get("pose_mode","") == mode
    var span: float = maxf(enemy.get("pose_duration",1.0) if tracked else spans.get(mode,1.0),0.001)
    var age: float = enemy.get("pose_elapsed",0.0) if tracked else maxf(0,span-enemy.timer)
    var t := clampf(age/span,0,1)
    var ease := smoothstep(0,1,t)
    var direction: Vector2 = enemy.direction.normalized()
    var facing := direction.x
    var offset := Vector2.ZERO
    var stretch := Vector2.ONE
    var lean := 0.0
    var reach := 0.0
    var lift := 0.0
    if mode in ["windup","melee_windup"]:
        var weight := 1.0 if mode == "windup" else 0.8
        offset = -direction*13*ease*weight+Vector2(0,6*ease)
        stretch = Vector2(1-0.12*ease,1-0.22*ease)
        lean = -facing*0.20*ease
        reach = -15*ease
        lift = 5*ease
    elif mode in ["rush","melee"]:
        var release := 1.0 if mode == "rush" else 1.0-smoothstep(0.35,1,t)
        offset = direction*17*release+Vector2(0,-3*release)
        stretch = Vector2(1+0.16*release,1-0.12*release)
        lean = facing*0.26*release
        reach = 40*release
        lift = -4*release
    elif mode == "cast":
        offset.y = -12*ease
        stretch = Vector2(1-0.08*ease,1+0.16*ease)
        lean = -facing*0.08*ease
        reach = 10*ease
        lift = -30*ease
    elif mode == "burst":
        var release := 1.0-smoothstep(0.25,1,t)
        offset = -direction*9*release+Vector2(0,6*release)
        stretch = Vector2(1+0.12*release,1-0.15*release)
        lean = -facing*0.14*release
        reach = 36*release
        lift = -3*release
    elif mode == "slam_windup":
        offset.y = -24*ease
        stretch = Vector2(1-0.08*ease,1+0.18*ease)
        lean = -facing*0.10*ease
        reach = -5*ease
        lift = -35*ease
    elif mode == "slam":
        var release := 1.0-smoothstep(0.20,1,t)
        offset.y = 12*release
        stretch = Vector2(1+0.24*release,1-0.28*release)
        reach = 24*release
        lift = 20*release
    elif mode in ["rest","exposed"]:
        var recovery := 1.0-ease
        if mode=="exposed" and enemy.kind=="armored":
            recovery=rear_openness(enemy)*(0.45 if enemy.get("opening","")=="miss" else 1.0)
        offset.y = 4*recovery
        stretch = Vector2(1+0.09*recovery,1-0.10*recovery)
        lean = -facing*0.09*recovery
        reach = -6*recovery
        lift = 10*recovery
        if mode=="exposed" and enemy.kind=="armored":
            offset.y+=7*recovery
            lean-=facing*0.18*recovery
            lift+=8*recovery
    else:
        offset.y = -absf(sin(age*8))*2
    return {"offset":offset,"stretch":stretch,"lean":lean,"reach":reach,"lift":lift}
