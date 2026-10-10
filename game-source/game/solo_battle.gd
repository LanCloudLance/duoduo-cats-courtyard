extends RefCounted
const Companion = preload("res://game/companion_ai.gd")
var companion = Companion.new()
var human_slot := 0
var engagement := 0.0
var guard_handoff := 0.0

func cancel(b) -> void:
    b.cancel_attacks()
    b.hold_guard(false)
    b._cancel_rescue()
    engagement = 0
    guard_handoff = 0
    companion.reset()

func switch_role(b) -> void:
    if b.phase == "complete": return
    var current: int = b.actor(human_slot)
    var order := ([b.current_cat,3-b.current_cat,0] if b.attacks.charging else [1,2,0]) if current == 0 else [2,0,1] if current == 1 else [0,1,2]
    for next in order:
        var slot := 0 if next == 0 else 1
        if next not in b.available_roles() or b.hp[slot] <= 0: continue
        # Control ownership changes; committed partner actions do not.
        if human_slot != slot:
            if human_slot == 0:
                guard_handoff = 0.35 if b.guarding else 0.0
                b.guard_held = false
            elif b.attacks.charging:
                b.release_attack(1)
            if b.rescuer == human_slot: b._cancel_rescue()
        human_slot = slot
        if next > 0 and b.current_cat != next: b.switch_cat()
        b.message = "你控制%s，伙伴会协助战斗。" % ["朵朵","团团","圆圆"][next]
        return

func press(b, button: int, direction: Vector2) -> void:
    match button:
        JOY_BUTTON_Y: switch_role(b)
        JOY_BUTTON_A: b.interact(human_slot)
        JOY_BUTTON_X:
            b.attack(human_slot)
            if b.hp[human_slot] > 0: engagement = 3.5
        JOY_BUTTON_B:
            b.dodge(human_slot,direction)
            if b.hp[human_slot] > 0: engagement = 3.5
        JOY_BUTTON_LEFT_SHOULDER:
            if human_slot == 0 and b.hp[0] > 0:
                b.hold_guard(true)
                engagement = 3.5

func release(b, button: int) -> void:
    if button == JOY_BUTTON_X: b.release_attack(human_slot)
    if button == JOY_BUTTON_LEFT_SHOULDER and human_slot == 0: b.hold_guard(false)

func step(b, dt: float, direction: Vector2) -> void:
    if not is_finite(dt) or dt <= 0 or not direction.is_finite(): return
    dt = minf(dt,0.1)
    engagement = maxf(0,engagement-dt) if b.phase == "combat" else 0.0
    if human_slot == 0 and b.guarding and b.hp[0] > 0: engagement = 3.5
    # Recent player engagement persists while the player stays in the encounter.
    if engagement > 0 and direction.length() > 0.1 and b.enemies.any(func(e): return e.hp > 0 and e.pos.distance_to(b.positions[b.actor(human_slot)]) < 280):
        engagement = maxf(engagement,0.5)
    var handoff_expired := guard_handoff > 0 and guard_handoff <= dt
    guard_handoff = maxf(0,guard_handoff-dt)
    # Expiry must not wait another AI decision interval with a stale shield.
    # Reevaluate current threats now; a real frontal threat can earn fresh guard.
    if handoff_expired and human_slot != 0: companion.decision_time = 0
    var ai_move: Vector2 = companion.step(b,1-human_slot,human_slot,dt,engagement > 0)
    if human_slot != 0 and guard_handoff > 0 and b.hp[0] > 0 and b.dodge_time[0] <= 0:
        b.guarding = true
    ai_move = companion.safe_movement(b,1-human_slot,dt,ai_move)
    b.step(dt,direction if human_slot == 0 else ai_move,ai_move if human_slot == 0 else direction,true)
