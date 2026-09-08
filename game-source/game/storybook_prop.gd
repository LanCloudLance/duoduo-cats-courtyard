extends RefCounted
## Tight, bottom-anchored props. Original generated atlas is preserved.
const SHEET = preload("res://assets/visual-m15/props-atlas.png")
const KEY = preload("res://assets/visual-m13/chroma.gdshader")
const REGIONS = [Rect2(100,52,230,334),Rect2(498,84,260,260),Rect2(922,84,207,292),Rect2(43,508,349,253),Rect2(472,460,322,315),Rect2(948,442,145,343),Rect2(60,897,324,247),Rect2(449,850,340,335),Rect2(848,842,340,342)]
static func make(index: int, size: Vector2) -> Sprite2D:
    var view := Sprite2D.new()
    var atlas := AtlasTexture.new()
    atlas.atlas = SHEET
    atlas.region = REGIONS[index]
    atlas.filter_clip = true
    view.texture = atlas
    view.offset = Vector2(0,-atlas.region.size.y/2)
    view.scale = size/atlas.region.size
    view.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    var key := ShaderMaterial.new()
    key.shader = KEY
    view.material = key
    return view
