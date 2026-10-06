extends SceneTree
const Home = preload("res://game/home_sprite.gd")
var checks := 0
var failed := 0
func check(value: bool, label: String) -> void:
    checks += 1
    if not value: failed += 1; push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var phases: Array[float] = []
    for role in range(3):
        for fps in [30,60,120]:
            var home := Home.new()
            home.role = role
            root.add_child(home)
            home.update_motion(Vector2(300,300), 0)
            check(home.using_motion and home.walk_phase == 0, "home spawn uses its outfit without imaginary movement")
            var poses: Dictionary = {}
            var size: Vector2 = home.sprite.scale
            var correct_position := true
            var stable_size := true
            for step in range(fps):
                var point: Vector2 = Vector2(300,300) + Vector2.ONE.normalized() * 220.0 * (step+1)/fps
                home.update_motion(point, 1.0/fps)
                poses[home.last_frame] = true
                correct_position = correct_position and home.position.is_equal_approx(point)
                stable_size = stable_size and home.sprite.scale == size
            phases.append(home.walk_phase)
            check(correct_position, "home world position never accumulates previous x")
            check(stable_size, "home figure scale stays fixed throughout a stride")
            check(poses.size() == 8, "home travel displays all eight source poses")
            var frame: int = home.last_frame
            var stride: float = home.walk_stride
            home.update_motion(home.motion_position, 0)
            check(frame == home.last_frame and stride == home.walk_stride, "paused home pose freezes exactly")
            home.show_action("walk", 99, -1)
            check(home.sprite.visible and not home.action_sprite.visible, "walking never falls back to the old single action frame")
            for step in range(20): home.update_motion(home.motion_position, 1.0/60)
            check(home.last_frame == home.motion_metadata.idle_front, "home stops on its planted idle pose")
            var phase: float = home.walk_phase
            home.update_motion(Vector2(1200,900), 1.0/60)
            check(home.walk_phase == phase, "home teleport does not create a gait cycle")
            home.show_action("brace",0.5,1)
            check(home.action_sprite.visible and home.action_sprite.texture.atlas == home.ACTIONS, "home original interaction art remains intact")
            home.free()
    for phase in phases: check(is_equal_approx(phase,phases[0]), "home equal travel has equal phase at every FPS and role")
    print("M26_ANIMATION_HOME: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
