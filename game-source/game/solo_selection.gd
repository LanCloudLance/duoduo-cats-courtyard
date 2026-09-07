extends RefCounted
# One physical input controls one real actor; inactive puzzle mechanisms persist.
var actor := 0
var previous := 1
func select_next(state, backwards := false) -> void:
    var next: int = previous if backwards else (actor + 1) % 3
    if state.has_method("park_traveler"): state.park_traveler(actor)
    previous = actor
    actor = next
    if actor > 0 and state.current_cat != actor: state.switch_cat()
    if state.get("solo_actor") != null: state.solo_actor = actor
func slot() -> int:
    return 0 if actor == 0 else 1
func movement(input: Vector2, target: int) -> Vector2:
    return input if slot() == target else Vector2.ZERO
func title() -> String:
    return "你控制 · " + ["朵朵","团团","圆圆"][actor]
func help(keyboard: bool) -> String:
    return "Tab 换角色 · Q 切回上一位" if keyboard else "面键上换角色 · 右切回上一位"
