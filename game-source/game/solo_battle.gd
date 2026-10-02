extends RefCounted
const Companion = preload("res://game/companion_ai.gd")
var companion = Companion.new()
var human_slot := 0
var engagement := 0.0

func cancel(b) -> void:
    b.cancel_attacks()
    b.hold_guard(false)
    b._cancel_rescue()
    engagement = 0
    companion.reset()

func switch_role(b) -> void:
    if b.phase == "complete": return
    var current: int = b.actor(human_slot)
    for offset in range(1,4):
        var next := (current+offset)%3
        var slot := 0 if next == 0 else 1
        if next not in b.available_roles() or b.hp[slot] <= 0: continue
        cancel(b)
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
    var ai_move: Vector2 = companion.step(b,1-human_slot,human_slot,dt,engagement > 0)
    ai_move = companion.safe_movement(b,1-human_slot,dt,ai_move)
    b.step(dt,direction if human_slot == 0 else ai_move,ai_move if human_slot == 0 else direction,true)
