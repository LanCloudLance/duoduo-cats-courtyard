extends SceneTree
const Actor = preload("res://game/actor_view.gd")
var checks := 0
var failed := 0

func check(value: bool, label: String) -> void:
    checks += 1
    if not value:
        failed += 1
        push_error("FAIL: " + label)

func _initialize() -> void:
    call_deferred("run")

func actor_at(point: Vector2, visual := false):
    var actor = Actor.new()
    actor.storybook = visual
    root.add_child(actor)
    actor.update_pose(point, false, false, 1.0 / 60.0)
    return actor

func run() -> void:
    var actor = actor_at(Vector2(640, 400))
    check(is_zero_approx(actor.phase) and is_zero_approx(actor.stride), "spawn placement does not count as walking")
    actor.update_pose(Vector2(644, 400), false, false, 1.0 / 60.0)
    var phase: float = actor.phase
    actor.update_pose(Vector2(1200, 700), false, false, 1.0 / 60.0)
    check(is_equal_approx(actor.phase, phase), "checkpoint teleport does not advance the gait")
    actor.update_pose(actor.position + Vector2.RIGHT * 4, false, false, 1.0 / 60.0)
    phase = actor.phase
    var stride: float = actor.stride
    actor.update_pose(actor.position + Vector2.RIGHT * 2, false, false, 0.0)
    check(is_equal_approx(actor.phase, phase) and is_equal_approx(actor.stride, stride), "zero-time refresh freezes animation phase and transition")
    actor.free()
    var phases: Array[float] = []
    for fps in [30, 60, 120]:
        for direction in [Vector2.RIGHT, Vector2.ONE.normalized()]:
            actor = actor_at(Vector2.ZERO)
            for step in range(fps):
                actor.update_pose(direction * 220.0 * (step + 1) / fps, false, false, 1.0 / fps)
            phases.append(actor.phase)
            check(actor.stride > 0.99, "normal movement reaches full gait at %d FPS" % fps)
            for step in range(fps / 2):
                actor.update_pose(actor.position, false, false, 1.0 / fps)
            check(is_zero_approx(actor.stride), "idle settles at %d FPS" % fps)
            check(is_equal_approx(actor.phase, phases[-1]), "idle does not invent traveled distance")
            actor.free()
    for result in phases:
        check(is_equal_approx(result, phases[0]), "equal travel has equal gait at any FPS and direction")
    actor = actor_at(Vector2.ZERO, true)
    var frames: Dictionary = {}
    for step in range(96):
        actor.update_pose(Vector2((step + 1) * 2, 0), false, false, 1.0 / 60.0)
        frames[actor.painted.last_frame] = true
    check(frames.size() >= 8, "normal walking presents eight distinct drawn footfall frames")
    actor.free()
    if ResourceLoader.exists("res://assets/visual-m26/duoduo-motion.png"):
        visual_compatibility()
    print("M26_ANIMATION: %d checks, %d failed" % [checks, failed])
    quit(1 if failed else 0)

func visual_compatibility() -> void:
    for role in range(3):
        var actor = Actor.new()
        actor.storybook = true
        actor.role = role
        root.add_child(actor)
        actor.update_pose(Vector2(320, 300), false, false, 0)
        check(actor.painted.using_motion, "role %d loads its dedicated motion sheet" % role)
        var frame_scale: Vector2 = actor.painted.sprite.scale
        for step in range(8):
            actor.painted.pose((step * actor.painted.WALK_CYCLE_DISTANCE / 8.0 + 1) * 0.09, 1, 1, 0)
            check(actor.painted.sprite.scale == frame_scale, "all walk poses retain identical source scale")
        for direction in [Vector2.DOWN, Vector2.UP]:
            actor.painted.move_direction = direction
            var tops: Array[float] = []
            for step in range(8):
                actor.painted.pose((step * actor.painted.WALK_CYCLE_DISTANCE / 8.0 + 1) * 0.09, 1, 1, 0)
                tops.append((actor.painted.sprite.position.y + 2 * actor.painted.sprite.scale.y) * actor.painted.scale.y)
            check(tops.max() - tops.min() <= 3.0, "projected floor prevents the old 20-pixel head jump")
        actor.update_pose(Vector2(324, 300), false, false, 1.0 / 60.0)
        check(float(actor.painted.last_frame) in actor.painted.motion_metadata.front, "rightward travel selects front sequence")
        for step in range(12):
            actor.update_pose(actor.position + Vector2(0, -3), false, false, 1.0 / 60.0)
        check(float(actor.painted.last_frame) in actor.painted.motion_metadata.rear, "upward travel selects rear sequence")
        actor.update_pose(actor.position + Vector2(-3, 0), false, false, 1.0 / 60.0)
        check(actor.facing == -1 and actor.painted.scale.x < 0, "leftward travel mirrors whole character consistently")
        var anchor: Vector2 = actor.painted.sprite.position
        var phase: float = actor.phase
        var frame: int = actor.painted.last_frame
        for step in range(30): actor.update_pose(actor.position, false, false, 0)
        check(actor.painted.last_frame == frame and actor.phase == phase, "repeated paused updates keep the exact footfall")
        check(actor.painted.sprite.position.is_equal_approx(anchor), "repeated same-frame pose cannot compound its feet anchor")
        for step in range(20): actor.update_pose(actor.position, false, false, 1.0 / 60.0)
        check(actor.painted.last_frame == actor.painted.motion_metadata.idle_front, "stopping settles to a planted-foot idle pose")
        actor.motion_kind = "pull"
        actor.update_pose(actor.position, false, false, 1.0 / 60.0)
        check(actor.painted.last_frame == actor.painted.motion_metadata.actions.pull, "chapter pull uses the separate interaction pose")
        actor.free()
    var home = preload("res://game/home_sprite.gd").new()
    root.add_child(home)
    home.pose(1, 1, 1, 0)
    check(home.using_motion and home.sprite.texture.atlas.resource_path.ends_with("home-motion.png"), "home uses its separate outfit motion atlas")
    home.show_action("brace", 0.5, 1)
    check(home.action_sprite.visible and home.action_sprite.texture.atlas == home.ACTIONS, "original home actions stay available")
    home.free()
    var combat = Actor.new()
    combat.storybook = true
    combat.combat_visual = true
    root.add_child(combat)
    combat.update_pose(Vector2.ZERO, false, false, 0)
    combat.update_pose(Vector2(4, 0), false, false, 1.0 / 60.0)
    check(combat.painted.using_motion and is_equal_approx(combat.painted.scale.y, 0.30), "combat locomotion uses real frames and preserves equipment scale")
    combat.combat_active = true
    combat.combat_kind = "sword"
    combat.combat_contact = true
    combat.update_pose(combat.position, false, false, 1.0 / 60.0)
    check(combat.painted.action_sprite.visible and combat.painted.action_sprite.texture.atlas == combat.painted.COMBAT, "combat attack retains its action atlas")
    combat.free()
    var social = Actor.new()
    social.storybook = true
    social.social_visual = true
    root.add_child(social)
    social.social_kind = "rest"
    social.update_pose(Vector2.ZERO, false, false, 1.0 / 60.0)
    check(social.painted.social_sprite.visible and social.painted.social_sprite.texture.atlas == social.painted.SOCIAL, "social rest retains its action atlas")
    social.free()
