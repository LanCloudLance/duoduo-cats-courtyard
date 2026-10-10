extends SceneTree
var checks := 0
var failed := 0
func check(value: bool, label: String) -> void:
    checks += 1
    if not value: failed += 1; push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var args := OS.get_cmdline_user_args()
    if args.is_empty(): push_error("Pass an exported PCK after --, from an empty probe project."); quit(1); return
    if not ProjectSettings.load_resource_pack(args[0],true): push_error("Cannot mount exported PCK"); quit(1); return
    var sprite_script = load("res://game/storybook_sprite.gd")
    var home_script = load("res://game/home_sprite.gd")
    check(sprite_script != null and home_script != null, "PCK includes animation scripts")
    if sprite_script == null or home_script == null: quit(1); return
    for prefix in ["duoduo", "tuantuan", "yuanyuan", "home-0", "home-1", "home-2"]:
        var path: String = "res://assets/visual-m26/" + prefix + "-motion.json"
        check(FileAccess.file_exists(path), "PCK includes raw JSON metadata: " + prefix)
        if not FileAccess.file_exists(path): continue
        var meta = JSON.parse_string(FileAccess.get_file_as_string(path))
        check(meta is Dictionary and meta.has("frames"), "PCK metadata parses: " + prefix)
        if not meta is Dictionary or not meta.has("frames"): continue
        var sources: Dictionary = {}
        for entry in meta.frames:
            var atlas_path: String = "res://assets/visual-m26/" + entry.get("atlas",meta.image)
            sources[atlas_path] = true
        for path_in_pack in sources:
            check(ResourceLoader.exists(path_in_pack) and load(path_in_pack) is Texture2D, "PCK texture resolves: " + path_in_pack)
    for role in range(3):
        var sprite = sprite_script.new()
        sprite.role = role
        root.add_child(sprite)
        check(sprite.using_motion and sprite.motion_frames.size() == 20, "PCK adventure actor cannot silently fall back to old art")
        sprite.move_direction = Vector2.UP
        sprite.pose(2,1,1,0)
        check(float(sprite.last_frame) in sprite.motion_metadata.rear, "PCK rear pose resolves")
        sprite.free()
        var home = home_script.new()
        home.role = role
        root.add_child(home)
        home.update_motion(Vector2.ZERO,0)
        home.update_motion(Vector2(4,0),1.0/60)
        check(home.using_motion and home.motion_frames.size() == 8, "PCK home actor uses its own motion sheet")
        home.free()
    print("M26_ANIMATION_PACK: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
