extends Node2D

var role: int = 0
var controlled: bool = false
var held: bool = false
var phase: float = 0
var stride: float = 0
var facing: float = 1
var move_direction := Vector2.DOWN
var motion_kind := ""
var pose_initialized := false
var font: Font
var caption_visible: bool = true
var caption_override := ""
var combat_kind := ""
var combat_progress := 0.0
var combat_direction := Vector2.RIGHT
var charge_progress := 0.0
var combat_visual := false
var combat_active := false
var combat_contact := false
var combat_combo := 0
var impact_ratio := 0.22
var hurt_progress := 0.0
var dodging := false
var guarding := false
var guard_direction := Vector2.RIGHT
var storybook := false
var social_visual := false
var social_kind := ""
var presentation_clock := 0.0
var painted: Node2D
var reaction := 0.0
var caption_plaque: StyleBoxFlat


func _ready() -> void:
    if storybook:
        caption_plaque = StyleBoxFlat.new()
        caption_plaque.bg_color = Color(0.09,0.18,0.14,0.87)
        caption_plaque.set_corner_radius_all(9)
        painted = preload("res://game/combat_sprite.gd").new() if combat_visual else preload("res://game/social_sprite.gd").new() if social_visual else preload("res://game/storybook_sprite.gd").new()
        painted.role = role
        add_child(painted)

func update_pose(point: Vector2, selected: bool, staying: bool, delta: float) -> void:
    var displacement := point - position
    var distance := displacement.length()
    # Placement and checkpoint jumps are not steps. Sampling is scene-owned so
    # paused/zero-time refreshes cannot advance gait or its settling transition.
    var placement := not pose_initialized or distance > 96.0
    pose_initialized = true
    if delta > 0:
        var walking := not placement and distance > 0.001
        if walking:
            move_direction = displacement.normalized()
            if absf(displacement.x) > 0.01:
                facing = signf(displacement.x)
            phase += distance * 0.09
        stride = 0.0 if placement else move_toward(stride, 1.0 if walking else 0.0, delta * 12)
    position = point
    controlled = selected
    held = staying
    reaction = maxf(0, reaction - delta * 2.0)
    if painted:
        painted.move_direction = move_direction
        painted.motion_kind = motion_kind
        if social_visual:
            painted.social_kind = social_kind
            painted.presentation_clock = presentation_clock
        if combat_visual:
            painted.pose_delta = delta
            painted.combat_kind = combat_kind
            painted.combat_active = combat_active
            painted.combat_contact = combat_contact
            painted.combat_combo = combat_combo
            painted.impact_ratio = impact_ratio
            painted.hurt_progress = hurt_progress
            painted.dodging = dodging
            painted.combat_progress = combat_progress
            painted.combat_direction = combat_direction
            painted.charge_progress = charge_progress
            painted.guarding = guarding
            painted.guard_direction = guard_direction
            var direction: Vector2 = guard_direction if guarding else combat_direction
            if (combat_active or guarding or combat_kind == "charge") and absf(direction.x) > 0.01:
                facing = signf(direction.x)
        painted.pose(phase,stride,facing,reaction)
    z_index = int(point.y)
    queue_redraw()

func ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
    draw_set_transform(center, 0, radius)
    draw_circle(Vector2.ZERO, 1, color)
    draw_set_transform(Vector2.ZERO)

func _draw() -> void:
    var accent := Color("91d3c0") if role == 0 else Color("f1d695")
    ellipse(Vector2(0, 5), Vector2(27, 10), Color(0.03, 0.10, 0.07, 0.28))
    if controlled:
        draw_set_transform(Vector2(0, 4), 0, Vector2(1, 0.42))
        if storybook:
            draw_circle(Vector2.ZERO,32,Color(accent,0.19))
            draw_arc(Vector2.ZERO,34,0,TAU,48,Color("345346"),7,true)
        draw_arc(Vector2.ZERO, 33, 0, TAU, 48, accent, 3, true)
        draw_set_transform(Vector2.ZERO)
    if held:
        draw_arc(Vector2(0, -20), 45, 0, TAU, 48, Color(0.95, 0.85, 0.5, 0.6), 2, true)
    var bob := sin(phase * 2) * stride * 2
    var foot := sin(phase) * stride * 5
    var pose_scale := Vector2.ONE
    if combat_kind == "pounce" and combat_progress > 0:
        pose_scale = Vector2(1.18,0.72)
        bob += 4
    elif combat_kind == "charge":
        pose_scale = Vector2(1.08,0.88)
        bob += 3
    draw_set_transform(Vector2(0, bob),0,pose_scale)
    if storybook:
        pass
    elif role == 0:
        _girl(foot)
    else:
        _cat(foot)
    draw_set_transform(Vector2.ZERO)
    if font and caption_visible:
        var caption: String = ["P1 朵朵", "团团", "圆圆"][role]
        if role > 0:
            caption = ("P2 " if controlled else "") + caption + (" · 驻守" if held else "")
        if not caption_override.is_empty(): caption = caption_override
        var height := (-146.0 if role == 0 else -105.0) if storybook else (-99.0 if role == 0 else -77.0)
        if storybook:
            draw_style_box(caption_plaque,Rect2(-66,height-19,132,26))
        draw_string(font, Vector2(-65, height), caption, HORIZONTAL_ALIGNMENT_CENTER, 130, 17, Color("fff3d4"))

func _girl(foot: float) -> void:
    var ink := Color("263b34")
    var skin := Color("efd1af")
    ellipse(Vector2(18, -61), Vector2(14, 25), ink)
    draw_circle(Vector2(15, -83), 12, ink)
    draw_circle(Vector2(13, -83), 5, Color("e6bf74"))
    draw_line(Vector2(-11, -20), Vector2(-12, -4 + foot), Color("555b52"), 13, true)
    draw_line(Vector2(11, -20), Vector2(12, -4 - foot), Color("555b52"), 13, true)
    ellipse(Vector2(-13, foot), Vector2(10, 6), Color("6b4e36"))
    ellipse(Vector2(13, -foot), Vector2(10, 6), Color("6b4e36"))
    draw_colored_polygon(PackedVector2Array([Vector2(-17, -48), Vector2(16, -48), Vector2(22, -20), Vector2(-22, -20)]), Color("2f7864"))
    draw_line(Vector2(0, -45), Vector2(0, -22), Color("e4cc95"), 4)
    draw_line(Vector2(-20, -43), Vector2(-27, -25 + foot * .3), Color("f6e2b6"), 10, true)
    var hand := Vector2(27,-24)
    var sword_direction := Vector2(0.6,-0.8)
    if combat_kind == "sword" and combat_progress > 0:
        sword_direction = combat_direction.rotated(lerpf(-PI/3,PI/3,combat_progress))
        hand = Vector2(12,-35)+sword_direction*24
    draw_line(Vector2(20,-43),hand,Color("f6e2b6"),10,true)
    draw_circle(Vector2(-27, -24), 6, skin)
    draw_circle(hand,6,skin)
    if combat_kind != "":
        draw_line(hand,hand+sword_direction*47,Color("755339"),8,true)
        draw_line(hand+sword_direction*8,hand+sword_direction*45,Color("e4bc79"),4,true)
        var hilt := hand+sword_direction*5
        draw_line(hilt-sword_direction.orthogonal()*9,hilt+sword_direction.orthogonal()*9,Color("b88a50"),5,true)
    draw_line(Vector2(-20, -23), Vector2(20, -23), Color("77543b"), 5)
    draw_circle(Vector2(0, -65), 23, ink)
    draw_circle(Vector2(0, -61), 19, skin)
    draw_colored_polygon(PackedVector2Array([Vector2(-21, -66), Vector2(-16, -83), Vector2(12, -85), Vector2(23, -66), Vector2(5, -74), Vector2(-7, -64)]), ink)
    draw_circle(Vector2(-7 + facing, -61), 2.2, ink)
    draw_circle(Vector2(7 + facing, -61), 2.2, ink)
    draw_arc(Vector2(0, -56), 5, 0.25, PI - 0.25, 12, Color("9d6357"), 1.5, true)
    # Wooden shield, matching the approved adventure silhouette.
    ellipse(Vector2(-29, -23), Vector2(12, 17), Color("a78747"))
    draw_line(Vector2(-29, -37), Vector2(-29, -9), Color("e5c078"), 3)

func _cat(foot: float) -> void:
    var ink := Color("23342e")
    var fur := Color("25302e") if role == 1 else Color("f4eddb")
    var eye := Color("e6c375") if role == 1 else Color("74afba")
    draw_polyline(PackedVector2Array([Vector2(17, -14), Vector2(33, -23), Vector2(37, -42), Vector2(30, -47)]), fur, 8, true)
    ellipse(Vector2(-10, foot), Vector2(8, 6), fur)
    ellipse(Vector2(10, -foot), Vector2(8, 6), fur)
    ellipse(Vector2(0, -15), Vector2(20, 20), fur)
    draw_colored_polygon(PackedVector2Array([Vector2(-17, -24), Vector2(17, -24), Vector2(15, -5), Vector2(-15, -5)]), Color("407463"))
    draw_line(Vector2(0, -22), Vector2(0, -6), Color("cda869"), 4)
    draw_colored_polygon(PackedVector2Array([Vector2(-21, -38), Vector2(-19, -63), Vector2(-4, -48)]), fur)
    draw_colored_polygon(PackedVector2Array([Vector2(21, -38), Vector2(19, -63), Vector2(4, -48)]), fur)
    draw_colored_polygon(PackedVector2Array([Vector2(-17, -46), Vector2(-17, -56), Vector2(-10, -48)]), Color("b8877f"))
    draw_colored_polygon(PackedVector2Array([Vector2(17, -46), Vector2(17, -56), Vector2(10, -48)]), Color("b8877f"))
    ellipse(Vector2(0, -36), Vector2(24, 20), fur)
    for x in [-9, 9]:
        draw_circle(Vector2(x, -37), 5, eye)
        draw_line(Vector2(x + facing, -40), Vector2(x + facing, -34), ink, 2)
        draw_circle(Vector2(x - 1, -39), 1, Color.WHITE)
    draw_circle(Vector2(0, -29), 2.5, Color("bd8179"))
    draw_arc(Vector2(-3, -27), 3, 0, PI, 8, Color("ac9c83"), 1, true)
    draw_arc(Vector2(3, -27), 3, 0, PI, 8, Color("ac9c83"), 1, true)
    if combat_kind == "pounce" and combat_progress > 0:
        for side in [-1,1]:
            var paw: Vector2 = Vector2(0,-18)+combat_direction*34+combat_direction.orthogonal()*side*8
            draw_line(Vector2(side*12,-19),paw,fur,9,true)
            ellipse(paw,Vector2(7,5),fur)
            draw_line(paw+combat_direction*3,paw+combat_direction*12,Color("eedbae"),2,true)
    elif combat_kind == "charge":
        for side in [-1,1]:
            var paw: Vector2 = Vector2(side*15,-24-charge_progress*12)
            draw_line(Vector2(side*12,-15),paw,fur,9,true)
            ellipse(paw,Vector2(8,7),fur)
            draw_circle(paw+Vector2(0,2),3,Color("d59b94"))
    elif combat_kind in ["slap","heavy"] and combat_progress > 0:
        for side in [-1,1]:
            var paw: Vector2 = Vector2(0,-12)+combat_direction*(26+sin(combat_progress*PI)*12)+combat_direction.orthogonal()*side*10
            draw_line(Vector2(side*12,-20),paw,fur,10,true)
            ellipse(paw,Vector2(9,6),fur)
