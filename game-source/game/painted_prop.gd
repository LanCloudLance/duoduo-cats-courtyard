extends RefCounted
const ART = preload("res://assets/visual-m13/props-atlas.png")
const KEY = preload("res://assets/visual-m13/chroma.gdshader")

static func make(region: Rect2, target: Rect2) -> Sprite2D:
    var sprite := Sprite2D.new()
    var atlas := AtlasTexture.new()
    atlas.atlas = ART
    atlas.region = region
    atlas.filter_clip = true
    sprite.texture = atlas
    sprite.centered = false
    sprite.position = target.position
    sprite.scale = target.size / region.size
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    var material := ShaderMaterial.new()
    material.shader = KEY
    sprite.material = material
    return sprite
