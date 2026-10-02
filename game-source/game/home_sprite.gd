extends "res://game/storybook_sprite.gd"
const HOME = preload("res://assets/story-prologue/home-party.png")
func _ready() -> void:
    super._ready()
    for atlas in frame_cache: atlas.atlas = HOME
    _prepare_actions()
func pose(phase: float, stride: float, facing: float, reaction: float) -> void:
    super.pose(phase,stride,facing,reaction)
    for atlas in frame_cache: atlas.atlas = HOME

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
    sprite.visible = kind.is_empty()
    action_sprite.visible = not kind.is_empty()
    if kind.is_empty(): return
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
    if kind == "walk": position.y = -absf(sin(time*9))*2
