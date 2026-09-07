extends Node2D
## Presentation-only atlas, anchored at the feet. Gameplay owns position/collision.
const SHEET = preload("res://assets/visual-m13/party-atlas.png")
const KEY = preload("res://assets/visual-m13/chroma.gdshader")
var sprite := Sprite2D.new()
var role := 0
var last_frame := -1
var frame_cache: Array[AtlasTexture] = []

func _ready() -> void:
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    var mat := ShaderMaterial.new()
    mat.shader = KEY
    sprite.material = mat
    add_child(sprite)
    pose(0, 0, 1, 0)

func pose(phase: float, stride: float, facing: float, reaction: float) -> void:
    var frame: int = [0, 1, 0, 2][int(phase * 0.4) % 4] if stride > 0.12 else 0
    var tops := [0, 478, 833]
    var bottoms := [478, 833, 1254]
    var feet := [454, 807, 1180]
    var anchors := [245, 650, 1040]
    if frame != last_frame:
        if frame_cache.is_empty():
            for index in range(3):
                var atlas := AtlasTexture.new()
                atlas.atlas = SHEET
                atlas.region = Rect2(index*418,tops[role],418,bottoms[role]-tops[role])
                atlas.filter_clip = true
                frame_cache.append(atlas)
        sprite.texture = frame_cache[frame]
        sprite.centered = false
        sprite.position = Vector2(frame * 418 - anchors[frame], tops[role] - feet[role])
        last_frame = frame
    var factor := 0.30 if role == 0 else 0.285
    scale = Vector2(factor * facing, factor)
    position.y = -absf(sin(phase * 0.8)) * stride * 2.4 - sin(reaction * PI) * 7
    rotation = sin(phase * 0.4) * stride * 0.025 + sin(reaction * PI) * -0.045
