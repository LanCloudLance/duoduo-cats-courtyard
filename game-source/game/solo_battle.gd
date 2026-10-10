extends RefCounted
## SOLO has one human-owned slot. There is deliberately no combat companion AI.
var human_slot := 0
func cancel(b) -> void:b.cancel_attacks();b._cancel_rescue()
func switch_role(b) -> void:b.request_switch(0)
func press(b,button: int,direction: Vector2) -> void:
    match button:
        JOY_BUTTON_Y:b.request_switch(0)
        JOY_BUTTON_A:b.interact(0)
        JOY_BUTTON_X:b.attack(0)
        JOY_BUTTON_B:b.dodge(0,direction)
        JOY_BUTTON_LEFT_SHOULDER:b.signature(0)
func release(b,button: int) -> void:
    if button==JOY_BUTTON_LEFT_SHOULDER:b.release_signature(0)
func step(b,dt: float,direction: Vector2) -> void:b.step(dt,direction,Vector2.ZERO,true)
