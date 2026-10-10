extends RefCounted
## Only facts cross sessions. Poses, holds, velocities and timers are rebuilt.
const PHASES := ["home","listen","sniff","peek","slip","jam","open","leaving","complete"]
const EXTRA_KEYS := ["yuanyuan","wedge","toy","tuantuan"]
static func number(value) -> bool:
    return (value is int or value is float) and is_finite(float(value))
static func integer(value, low: int, high: int) -> bool:
    return number(value) and float(value) == floorf(float(value)) and value >= low and value <= high
static func point(value) -> bool:
    return value is Array and value.size() == 2 and number(value[0]) and number(value[1])
static func vector(value) -> Vector2: return Vector2(value[0],value[1])
static func extras_valid(value) -> bool:
    if not value is Dictionary: return false
    for key in value:
        if key not in EXTRA_KEYS or not value[key] is bool: return false
    return true
static func capture(s) -> Dictionary:
    var points := []
    for slot in range(2):
        var p: Vector2 = s.positions[slot]
        if s.phase in ["leaving","complete"]: p = Vector2(1085+slot*55,350)
        points.append([p.x,p.y])
    var wedge: Vector2 = vector(points[s.carrier]) if s.carrier >= 0 else s.wedge
    if s.wedged: wedge = Vector2(1085,320)
    return {"version":2,"chapter":"prologue","mode":"solo" if s.single else "dual","phase":s.phase,"completed":s.finished,"controlled":s.controlled,"positions":points,"facts":{"wedged":s.wedged,"rug_pull":s.rug_pull,"carrier":s.carrier,"wedge":[wedge.x,wedge.y],"ball":[s.ball.x,s.ball.y]},"extras":s.extras.duplicate(true),"history":Array(s.history)}
static func restore(s, data: Dictionary) -> bool:
    if data.get("version") != 2 or data.get("chapter") != "prologue" or data.get("mode") != ("solo" if s.single else "dual"): return false
    var phase = data.get("phase")
    if not phase is String or phase not in PHASES: return false
    if not data.get("completed") is bool or data.completed != (phase == "complete"): return false
    if not integer(data.get("controlled"),0,1): return false
    var points = data.get("positions")
    if not points is Array or points.size() != 2: return false
    for p in points:
        if not point(p) or not s.valid(vector(p)): return false
    var facts = data.get("facts")
    if not facts is Dictionary or facts.size() != 5: return false
    if not facts.get("wedged") is bool or not number(facts.get("rug_pull")) or facts.rug_pull < 0 or facts.rug_pull > 115: return false
    if not integer(facts.get("carrier"),-1,1): return false
    for key in ["wedge","ball"]:
        if not point(facts.get(key)) or not s.valid(vector(facts[key])): return false
    if facts.wedged and facts.carrier != -1: return false
    if phase in ["home","listen","sniff","peek","slip"] and (facts.wedged or facts.rug_pull != 0): return false
    if phase == "jam" and facts.rug_pull >= 105: return false
    if phase in ["open","leaving","complete"] and facts.rug_pull < 105: return false
    if not extras_valid(data.get("extras")): return false
    var history = data.get("history")
    if not history is Array or history.size() > 32: return false
    for line in history:
        if not line is String or line.length() > 280: return false
    # Validate everything before touching the live state.
    s.phase = "open" if phase == "leaving" else phase
    s.finished = phase == "complete"
    s.controlled = int(data.controlled)
    for slot in range(2): s.positions[slot] = vector(points[slot])
    s.wedged = facts.wedged
    s.rug_pull = float(facts.rug_pull)
    s.wedge = s.positions[int(facts.carrier)] if facts.carrier >= 0 else vector(facts.wedge)
    s.carrier = -1
    s.ball = vector(facts.ball)
    s.extras = data.extras.duplicate(true)
    s.history.assign(history)
    s.cancel_inputs()
    s.ball_velocity = Vector2.ZERO
    s.ball_spin = 0
    s.timer = 0
    s.clock = 0
    s.white_wait = 0
    s.exit_time = 0
    s.rug_shake = 0
    s.rug_anchor = Vector2.ZERO
    s.rug_start = s.rug_pull
    s.affection = 0
    s.hint_level = 0
    s.facing.assign([Vector2.RIGHT,Vector2.RIGHT,Vector2.RIGHT])
    s.positions[2] = Vector2(1095,362) if phase in ["peek","slip"] else Vector2(900,365)
    s.white_visible = phase in ["home","listen","sniff","peek","slip"]
    s.white_alpha = 1 if s.white_visible else 0
    s.actions[2] = "sleep" if phase == "home" else ("walk" if phase in ["sniff","slip"] else "listen")
    s.door_open = 1 if s.phase in ["open","complete"] else (0.4 if s.wedged else (0.2 if phase in ["peek","slip"] else 0.035))
    s.message = "已回来：门挡和地毯保持原样，需要时重新抓住卷边。" if phase == "jam" else "已回到这个下午，伙伴们都在。"
    s.message_time = 5
    s.cue = 0
    s.event_id += 1
    return true
static func restore_legacy(s, data: Dictionary) -> bool:
    if data.get("version") != 1 or data.get("chapter") != "prologue" or not data.get("completed") is bool or data.get("completed") != true or not extras_valid(data.get("extras",{})): return false
    var fresh := capture(s)
    fresh.phase = "complete"
    fresh.completed = true
    fresh.positions = [[1085,350],[1140,350]]
    fresh.facts = {"wedged":false,"rug_pull":115,"carrier":-1,"wedge":[160,415],"ball":[680,500]}
    fresh.extras = data.get("extras",{}).duplicate(true)
    fresh.history = []
    return restore(s,fresh)
