extends SceneTree
const Battle = preload("res://game/battle_state.gd")
var checks := 0
var failed := 0
func check(value: bool, label: String) -> void:
    checks += 1
    if not value:
        failed += 1
        push_error("FAIL: "+label)
func _initialize() -> void:
    var b = Battle.new()
    b.current_cat = 2
    b.attack(1)
    for i in range(34): b.step(1.0/60,Vector2.ZERO,Vector2.ZERO,true)
    b.release_attack(1)
    b.dodge(1,Vector2.DOWN)
    for i in range(14): b.step(1.0/60,Vector2.ZERO,Vector2.ZERO,true)
    b.attack(1)
    check(b.attacks.charging,"white can attack again when cancel dodge finishes, without invisible heavy recovery")
    b = Battle.new()
    b.attack(0)
    b.attack(1)
    var partner_cooldown: float = b.attack_cooldown[0]
    b.dodge(1,Vector2.DOWN)
    check(b.attack_cooldown[0] == partner_cooldown,"cancel affects only the player who dodged")
    b = Battle.new()
    b.dodge(0,Vector2.DOWN)
    for i in range(9): b.step(1.0/60,Vector2.ZERO,Vector2.ZERO,true)
    b.attack(0)
    for i in range(6): b.step(1.0/60,Vector2.ZERO,Vector2.ZERO,true)
    check(b.attack_flash[0] > 0,"late dodge input buffers one attack on landing")
    print("M19_INPUT_FEEL: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
