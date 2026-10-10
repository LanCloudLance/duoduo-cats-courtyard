extends RefCounted
## Combat deployment only; exploration keeps its independent three-role model.
var single := false
var available: Array[int] = [0,1,2]
var roles: Array[int] = [0,1]
func configure(mode: String, allowed: Array, selected: int, cat: int) -> bool:
    if mode not in ["solo","dual"] or allowed.is_empty(): return false
    var clean: Array[int] = []
    for role in allowed:
        if not role is int or role < 0 or role > 2 or clean.has(role): return false
        clean.append(role)
    if not clean.has(0) or not clean.has(1): return false
    if mode == "solo" and not clean.has(selected): return false
    if cat not in [1,2] or not clean.has(cat): return false
    single = mode == "solo"
    available = clean
    roles = [selected if single else 0,cat]
    return true
func deployed_slots() -> Array[int]: return [0] if single else [0,1]
func role_for_slot(slot: int) -> int:
    return roles[slot] if slot in deployed_slots() else -1
func role_slot(role: int) -> int:
    for slot in deployed_slots():
        if roles[slot] == role: return slot
    return -1
func reserves() -> Array[int]:
    var result: Array[int] = []
    for role in available:
        if role_slot(role) < 0: result.append(role)
    return result
func next_role(slot: int) -> int:
    if slot not in deployed_slots() or (not single and slot == 0): return -1
    var allowed: Array = available.duplicate() if single else [1,2] if 2 in available else [1]
    if allowed.size() < 2: return -1
    return allowed[(allowed.find(roles[slot])+1)%allowed.size()]
