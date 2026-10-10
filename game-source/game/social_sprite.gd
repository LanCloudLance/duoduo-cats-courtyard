extends "res://game/storybook_sprite.gd"
const SOCIAL = preload("res://assets/visual-m15/social-atlas.png")
var social_kind := ""
var presentation_clock := 0.0
var seated_support := true
var social_frames: Array[AtlasTexture] = []
var social_sprite := Sprite2D.new()
func _ready() -> void:
    super._ready()
    social_sprite.centered = false
    social_sprite.material = sprite.material
    social_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    add_child(social_sprite)
func pose(phase: float, stride: float, facing: float, reaction: float) -> void:
    super.pose(phase,stride,facing,reaction)
    var using_pose := not social_kind.is_empty()
    sprite.visible = not using_pose
    social_sprite.visible = using_pose
    if using_pose:
        var frame := 2 if social_kind == "pet" else 1 if social_kind == "rest" else 0
        var tops := [0,478,833]
        var bottoms := [478,833,1254]
        var feet := [[450,442,443],[805,805,805],[1171,1162,1169]]
        var anchors := [[235,650,1010],[225,632,1000],[230,625,1010]]
        if social_frames.is_empty():
            for index in range(3):
                var atlas := AtlasTexture.new()
                atlas.atlas = SOCIAL
                atlas.region = Rect2(index*418,tops[role],418,bottoms[role]-tops[role])
                atlas.filter_clip = true
                social_frames.append(atlas)
        social_sprite.texture = social_frames[frame]
        social_sprite.position = Vector2(frame*418-anchors[role][frame],tops[role]-feet[role][frame])
        # Scene-owned time freezes with pause; feet remain at the gameplay point.
        rotation = sin(presentation_clock*(1.4 if role == 2 else 2.0))*0.008
        position.y = -sin(presentation_clock*1.5)*0.6
    queue_redraw()
func _draw() -> void:
    if role != 0 or social_kind != "rest" or not seated_support: return
    # A folding stool under the seated pose works at every valid gathering point.
    draw_set_transform(Vector2.ZERO,0,Vector2.ONE/0.30)
    draw_line(Vector2(-17,-36),Vector2(16,1),Color("694e32"),5,true)
    draw_line(Vector2(17,-36),Vector2(-16,1),Color("694e32"),5,true)
    draw_line(Vector2(-22,-37),Vector2(22,-37),Color("b59159"),7,true)
    draw_line(Vector2(-20,-39),Vector2(20,-39),Color("e1c78f"),2,true)
    draw_set_transform(Vector2.ZERO)
