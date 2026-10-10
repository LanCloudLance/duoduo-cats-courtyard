extends "res://game/storybook_sprite.gd"
const HOME = preload("res://assets/story-prologue/home-party.png")
var motion_position := Vector2.ZERO
var motion_initialized := false
var walk_phase := 0.0
var walk_stride := 0.0
var walk_facing := 1.0
var seating_progress:=0.0
func place_home(point:Vector2,kind:String,delta:float)->void:
    seating_progress=move_toward(seating_progress,1.0 if kind=="sit" else 0.0,delta*2.5)
    var seat:Vector2=preload("res://game/story_stage_art.gd").home_pose_position(point,role,"sit")
    position=point.lerp(seat,smoothstep(0.0,1.0,seating_progress))
func _ready() -> void:
    legacy_sheet = HOME
    motion_sheet_path = "res://assets/visual-m26/home-motion.png"
    motion_metadata_path = "res://assets/visual-m26/home-%d-motion.json" % role
    use_motion_sheet = ResourceLoader.exists(motion_sheet_path) and FileAccess.file_exists(motion_metadata_path)
    super._ready()
    _prepare_actions()

func update_motion(point: Vector2, delta: float, affection := 0.0) -> void:
    var displacement := point - motion_position
    var distance := displacement.length()
    var placement := not motion_initialized or distance > 96.0
    motion_initialized = true
    motion_position = point
    if delta > 0:
        var walking := not placement and distance > 0.001
        if walking:
            move_direction = displacement.normalized()
            if absf(displacement.x) > 0.01: walk_facing = signf(displacement.x)
            walk_phase += distance * 0.09
        walk_stride = 0.0 if placement else move_toward(walk_stride, 1.0 if walking else 0.0, delta * 12)
    pose(walk_phase, walk_stride, walk_facing, affection)
    position = point + Vector2(0, position.y)

const ACTIONS = preload("res://assets/story-prologue/home-actions.png")
var action_sprite := Sprite2D.new()
var action_frames: Array[AtlasTexture] = []
func _prepare_actions() -> void:
    if not is_instance_valid(action_sprite.get_parent()):
        action_sprite.material = sprite.material
        action_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
        add_child(action_sprite)
        for index in range(3):
            var atlas := AtlasTexture.new()
            atlas.atlas = ACTIONS
            atlas.region = Rect2(index*418,[0,478,833][role],418,[478,355,421][role])
            atlas.filter_clip = true
            action_frames.append(atlas)

func show_action(kind: String, time: float, direction: float) -> void:
    _prepare_actions()
    # Walking keeps the displacement-driven home sheet; bespoke interactions
    # retain the approved legacy artwork.
    var using_action := not kind.is_empty() and kind != "walk"
    sprite.visible = not using_action
    action_sprite.visible = using_action
    if not using_action: return
    var frame := 0
    if role == 0: frame = 0 if kind == "sit" else 2 if kind == "brace" else 1
    elif role == 1: frame = 2 if kind == "pull" else 1 if kind == "paw" else 0
    else: frame = 0 if kind == "sleep" else 2 if kind == "walk" else 1
    action_sprite.texture = action_frames[frame]
    action_sprite.centered = false
    action_sprite.position = Vector2(frame*418-[245,650,1040][frame],[0,478,833][role]-[454,807,1180][role])
    var factor := 0.30 if role == 0 else 0.285
    scale = Vector2(factor*direction,factor)
    rotation = sin(time*6)*0.02 if kind in ["pet","sniff","paw","pull","brace"] else 0.0
    if kind == "sleep": scale.y *= 1+sin(time*2)*0.025
