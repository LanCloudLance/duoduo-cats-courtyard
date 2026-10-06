extends Node2D
## Presentation-only atlas, anchored at the feet. Gameplay owns position/collision.
const SHEET = preload("res://assets/visual-m13/party-atlas.png")
const KEY = preload("res://assets/visual-m13/chroma.gdshader")
var sprite := Sprite2D.new()
var role := 0
var last_frame := -1
var frame_cache: Array[AtlasTexture] = []
const MOTION_PATHS := ["res://assets/visual-m26/duoduo-front.png", "res://assets/visual-m26/tuantuan-cycle.png", "res://assets/visual-m26/yuanyuan-cycle.png"]
const MOTION_METADATA_PATHS := ["res://assets/visual-m26/duoduo-motion.json", "res://assets/visual-m26/tuantuan-motion.json", "res://assets/visual-m26/yuanyuan-motion.json"]
const WALK_CYCLE_DISTANCE := 96.0
var move_direction := Vector2.DOWN
var motion_kind := ""
var use_motion_sheet := true
var legacy_sheet: Texture2D = SHEET
var motion_frames: Array[AtlasTexture] = []
var motion_metadata: Dictionary = {}
var motion_anchors: Array[Vector2] = []
var motion_source_heights: Array[float] = []
var motion_checked := false
var using_motion := false
var motion_sheet_path := ""
var motion_metadata_path := ""

func _ready() -> void:
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    var mat := ShaderMaterial.new()
    mat.shader = KEY
    sprite.material = mat
    add_child(sprite)
    pose(0, 0, 1, 0)

func pose(phase: float, stride: float, facing: float, reaction: float) -> void:
    _prepare_motion()
    if not motion_frames.is_empty() and use_motion_sheet:
        _motion_pose(phase, stride, facing, reaction)
        return
    _legacy_pose(phase, stride, facing, reaction)

func _prepare_motion() -> void:
    if motion_checked or not use_motion_sheet: return
    motion_checked = true
    var image_path: String = MOTION_PATHS[role] if motion_sheet_path.is_empty() else motion_sheet_path
    if not ResourceLoader.exists(image_path): return
    var sheet: Texture2D = load(image_path)
    var metadata_path: String = MOTION_METADATA_PATHS[role] if motion_metadata_path.is_empty() else motion_metadata_path
    if not FileAccess.file_exists(metadata_path): return
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(metadata_path))
    if not parsed is Dictionary: return
    motion_metadata = parsed
    var sheets: Dictionary = {image_path: sheet}
    for entry in motion_metadata.frames:
        var rect: Array = entry.region
        var atlas := AtlasTexture.new()
        var entry_path: String = image_path.get_base_dir().path_join(entry.atlas) if entry.has("atlas") else image_path
        if not sheets.has(entry_path): sheets[entry_path] = load(entry_path)
        atlas.atlas = sheets[entry_path]
        atlas.region = Rect2(rect[0], rect[1], rect[2], rect[3])
        atlas.filter_clip = true
        motion_frames.append(atlas)
        motion_anchors.append(Vector2(entry.anchor[0], entry.anchor[1]) - atlas.region.position)
        motion_source_heights.append(float(entry.get("source_height", motion_metadata.source_height)))

func _motion_pose(phase: float, stride: float, facing: float, reaction: float) -> void:
    # Artist-provided pose sequence, sampled by actual distance rather than time.
    # A full left/right step cycle occupies 96 world pixels, at any frame rate.
    var rear := move_direction.y < -0.2
    var sequence: Array = motion_metadata.rear if rear else motion_metadata.front
    var step := int(floor(phase / (0.09 * WALK_CYCLE_DISTANCE) * sequence.size() + 0.0001)) % sequence.size()
    var frame: int = sequence[step] if stride > 0.12 else motion_metadata.idle_rear if rear else motion_metadata.idle_front
    var actions: Dictionary = motion_metadata.actions
    if actions.has(motion_kind): frame = actions[motion_kind]
    if frame != last_frame or not using_motion:
        sprite.texture = motion_frames[frame]
        sprite.centered = false
        last_frame = frame
    using_motion = true
    # Keep parent scale compatible with combat equipment and legacy action art.
    var source_height := 425.0 if role == 0 else 329.0
    sprite.scale = Vector2.ONE * source_height / motion_source_heights[frame]
    sprite.position = -motion_anchors[frame] * sprite.scale
    var factor := 0.30 if role == 0 else 0.285
    scale = Vector2(factor * facing, factor)
    position.y = -sin(reaction * PI) * 7
    rotation = sin(reaction * PI) * -0.045

func _legacy_pose(phase: float, stride: float, facing: float, reaction: float) -> void:
    var frame: int = [0, 1, 0, 2][int(phase * 0.4) % 4] if stride > 0.12 else 0
    var tops := [0, 478, 833]
    var bottoms := [478, 833, 1254]
    var feet := [454, 807, 1180]
    var anchors := [245, 650, 1040]
    if frame != last_frame or using_motion:
        if frame_cache.is_empty():
            for index in range(3):
                var atlas := AtlasTexture.new()
                atlas.atlas = legacy_sheet
                atlas.region = Rect2(index*418,tops[role],418,bottoms[role]-tops[role])
                atlas.filter_clip = true
                frame_cache.append(atlas)
        sprite.texture = frame_cache[frame]
        sprite.centered = false
        sprite.position = Vector2(frame * 418 - anchors[frame], tops[role] - feet[role])
        last_frame = frame
    using_motion = false
    sprite.scale = Vector2.ONE
    var factor := 0.30 if role == 0 else 0.285
    scale = Vector2(factor * facing, factor)
    position.y = -absf(sin(phase * 0.8)) * stride * 2.4 - sin(reaction * PI) * 7
    rotation = sin(phase * 0.4) * stride * 0.025 + sin(reaction * PI) * -0.045
