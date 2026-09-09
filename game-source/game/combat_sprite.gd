extends "res://game/storybook_sprite.gd"
const COMBAT = preload("res://assets/visual-m14/combat-atlas.png")
var action_sprite := Sprite2D.new()
var combat_kind := ""
var combat_active := false
var combat_progress := 0.0
var combat_direction := Vector2.RIGHT
var guard_direction := Vector2.RIGHT
var guarding := false
var charge_progress := 0.0
var face := 1.0
var action_frame := -1
var pose_delta := 0.0
var action_mix := 0.0
var smooth_lean := 0.0
var smooth_lift := 0.0
var smooth_hand := Vector2(22,-48)
var smooth_sword := Vector2(0.35,-0.94).normalized()
var smooth_shield := Vector2(-22,-45)
var cached_frames: Array[AtlasTexture] = []

func reset_transition() -> void:
    action_mix = 0.0
    smooth_lean = 0.0
    smooth_lift = 0.0
    smooth_hand = Vector2(22,-48)
    smooth_sword = Vector2(0.35,-0.94).normalized()
    smooth_shield = Vector2(-22,-45)


func _ready() -> void:
    super._ready()
    sprite.show_behind_parent = true
    action_sprite.show_behind_parent = true
    action_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    action_sprite.material = sprite.material
    action_sprite.centered = false
    add_child(action_sprite)

func pose(phase: float, stride: float, facing: float, reaction: float) -> void:
    super.pose(phase,stride,facing,reaction)
    face = facing
    var active_pose: bool = combat_active or guarding or combat_kind == "charge"
    # Bounded visual blending; attack timing, hit resolution and input are unchanged.
    var blend := 1.0-exp(-maxf(0,pose_delta)*45.0)
    action_mix = lerpf(action_mix,1.0 if active_pose else 0.0,blend)
    if absf(action_mix-(1.0 if active_pose else 0.0)) < 0.015:
        action_mix = 1.0 if active_pose else 0.0
    sprite.visible = action_mix < 1.0
    sprite.modulate.a = 1.0-action_mix
    action_sprite.visible = action_mix > 0.0
    action_sprite.modulate.a = action_mix
    var target_lift := 0.0
    var target_lean := 0.0
    if active_pose:
        var frame := 0
        if role == 0: frame = 2 if guarding else 1
        elif role == 1: frame = 1 if combat_progress < 0.65 else 2
        else: frame = 1 if combat_kind == "charge" else 2 if combat_kind == "heavy" else 0
        if frame != action_frame:
            var tops := [0,478,833]
            var bottoms := [468,827,1254]
            var feet := [[431,429,435],[765,732,781],[1183,1184,1189]]
            var anchors := [[237,607,1030],[216,619,1030],[222,610,1030]]
            if cached_frames.is_empty():
                for index in range(3):
                    var atlas := AtlasTexture.new()
                    atlas.atlas = COMBAT
                    atlas.region = Rect2(index*418,tops[role],418,bottoms[role]-tops[role])
                    atlas.filter_clip = true
                    cached_frames.append(atlas)
            action_sprite.texture = cached_frames[frame]
            action_sprite.position = Vector2(frame*418-anchors[role][frame],tops[role]-feet[role][frame])
            action_frame = frame
        if combat_kind == "pounce":
            target_lift = -sin(combat_progress*PI)*9
            target_lean = sin(combat_progress*PI)*0.06*face
        if combat_kind == "sword": target_lean = sin(combat_progress*PI)*0.07*face
        if combat_kind == "heavy":
            target_lean = sin(combat_progress*PI)*0.09*face
            target_lift = sin(combat_progress*PI)*3
        if combat_kind == "charge":
            target_lean = sin(charge_progress*26)*0.012*charge_progress
            target_lift = charge_progress*3
    smooth_lean = lerpf(smooth_lean,target_lean,blend)
    smooth_lift = lerpf(smooth_lift,target_lift,blend)
    rotation += smooth_lean
    position.y += smooth_lift
    var hand := Vector2(22,-48)
    var direction := Vector2(0.35,-0.94).normalized()
    if combat_active and combat_kind == "sword":
        hand = Vector2(37,-49)
        direction = Vector2(combat_direction.x*face,combat_direction.y).rotated(lerpf(-PI/3,PI/3,clampf(combat_progress*2.3,0,1)))
    var shield := Vector2(-22,-45)
    if guarding: shield = Vector2(0,-49)+Vector2(guard_direction.x*face,guard_direction.y)*31
    smooth_hand = smooth_hand.lerp(hand,blend)
    smooth_sword = Vector2.from_angle(lerp_angle(smooth_sword.angle(),direction.angle(),blend))
    smooth_shield = smooth_shield.lerp(shield,blend)
    queue_redraw()

func _draw() -> void:
    if role != 0: return
    # Equipment stays separate from the body atlas and aims in gameplay direction.
    draw_set_transform(Vector2.ZERO,0,Vector2.ONE/0.30)
    var hand := smooth_hand
    var direction := smooth_sword
    var shield := smooth_shield
    _shield(shield,guarding)
    if not guarding:
        var side := direction.orthogonal()
        var start := hand+direction*5
        var tip := hand+direction*58
        draw_colored_polygon(PackedVector2Array([start-side*4,tip-direction*7-side*3,tip,tip-direction*7+side*3,start+side*4]),Color("d1ad70"))
        draw_polyline(PackedVector2Array([start-side*4,tip-direction*7-side*3,tip,tip-direction*7+side*3,start+side*4]),Color("63482f"),1.5,true)
        draw_line(start,tip-direction*4,Color("f5dca0"),1.7,true)
        draw_line(hand-direction*9,hand+direction*4,Color("644730"),6,true)
        draw_line(start-side*9,start+side*9,Color("b58a48"),4,true)
    draw_set_transform(Vector2.ZERO)

func _shield(center: Vector2, raised: bool) -> void:
    # Restore image-node scale compensation around an equipment-local origin.
    draw_set_transform(center/0.30,0,Vector2(1,1.16)/0.30)
    draw_circle(Vector2.ZERO,18,Color("533e2d"))
    draw_circle(Vector2.ZERO,16,Color("ad8249"))
    for x in [-9,0,9]:
        draw_line(Vector2(x,-12),Vector2(x,12),Color("d1ae71"),1.3,true)
    draw_arc(Vector2.ZERO,15,0,TAU,36,Color("e0c48a"),2,true)
    draw_circle(Vector2(0,3),4,Color("edcf8a"))
    for p in [Vector2(-7,-3),Vector2(-2,-6),Vector2(4,-6),Vector2(8,-2)]: draw_circle(p,2.1,Color("edcf8a"))
    if raised: draw_arc(Vector2.ZERO,20,0,TAU,40,Color("9fede1"),2,true)
    draw_set_transform(Vector2.ZERO,0,Vector2.ONE/0.30)
