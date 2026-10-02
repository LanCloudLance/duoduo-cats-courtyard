extends SceneTree
const Battle = preload("res://game/battle_state.gd")
const Visual = preload("res://game/enemy_visual.gd")
var checks := 0
var failed := 0
func check(value: bool, label: String) -> void:
    checks += 1
    if not value:
        failed += 1
        push_error("FAIL: "+label)
func _initialize() -> void:
    run.call_deferred()
func run() -> void:
    var b = Battle.new()
    b.phase = "combat"
    b.positions[0] = Vector2(500,440)
    b.positions[1] = Vector2(300,600)
    b._spawn("sprout",Vector2(560,440))
    var enemy: Dictionary = b.enemies[0]
    enemy.timer = 0
    b._enemy_step(enemy,0.01)
    check(enemy.get("pose_mode","") == "melee_windup","animation phase begins with actual melee preparation")
    if failed:
        finish()
        return
    var view = Visual.new()
    root.add_child(view)
    b._enemy_step(enemy,0.30)
    view.sync(enemy)
    var preparation: Vector2 = view.body.position
    var prep_scale: Vector2 = view.body.scale
    var clock: float = enemy.pose_elapsed
    enemy.impact_pause = 0.07
    b._enemy_step(enemy,0.02)
    check(enemy.pose_elapsed == clock,"local contact hold freezes the target's action animation clock")
    enemy.impact_pause = 0
    b._enemy_step(enemy,0.25)
    check(enemy.mode == "melee" and enemy.pose_elapsed == 0,"attack animation starts when damaging mode actually begins")
    b._enemy_step(enemy,0.05)
    view.sync(enemy)
    check(view.body.position.distance_to(preparation) > 8 and view.body.scale.distance_to(prep_scale) > 0.01,
        "melee body releases out of the prepared crouch")
    var attack_pose: Vector2 = view.body.position
    b._enemy_step(enemy,0.30)
    view.sync(enemy)
    check(enemy.mode == "rest" and enemy.pose_mode == "rest" and view.body.position.distance_to(attack_pose) > 5,
        "damaging action ends in a different recovery pose")
    check(enemy.pos == Vector2(560,440),"body animation does not move the real melee collision center")
    b._spawn("weaver",Vector2(700,440))
    var caster: Dictionary = b.enemies[1]
    caster.timer = 0
    b._enemy_step(caster,0.01)
    var locked: Vector2 = caster.aim
    b.positions[0] += Vector2(0,50)
    b._enemy_step(caster,0.45)
    view.sync(caster)
    var cast_lift: float = view.body.position.y
    b._enemy_step(caster,0.50)
    view.sync(caster)
    check(caster.mode == "burst" and caster.aim == locked,"casting animation retains the already telegraphed target")
    check(view.body.position.y > cast_lift+6,"casting release differs visibly from raised preparation")
    b._spawn("elder",Vector2(760,440))
    var elder: Dictionary = b.enemies[2]
    elder.mode = "slam_windup"
    elder.timer = 0.82
    b._enemy_step(elder,0.40)
    view.sync(elder)
    var raised: float = view.body.position.y
    b._enemy_step(elder,0.45)
    view.sync(elder)
    check(elder.mode == "slam" and view.body.position.y > raised+10,"tree slam visibly drops from raised body to ground contact")
    var elapsed: float = elder.pose_elapsed
    b.step(0.1,Vector2.RIGHT,Vector2.ZERO,false)
    check(elder.pose_elapsed == elapsed,"pausing freezes enemy action presentation")
    view.free()
    finish()
func finish() -> void:
    print("M20_ENEMY_MOTION: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
