extends Node2D
signal next_level_requested
const Solo = preload("res://game/solo_battle.gd")
const Battle = preload("res://game/battle_state.gd")
const Actor = preload("res://game/actor_view.gd")
const StoryLabels = preload("res://game/story_labels.gd")
const EnemyView = preload("res://game/enemy_visual.gd")
const BACKDROP = preload("res://assets/visual-m14/arena-painted.png")
const BENCH_WOOD = preload("res://assets/visual-m26/floor-pieces.png")
var solo = Solo.new()
var battle = Battle.new()
var session
var active := false
var story_title := ""
var story_destination := ""
var allow_next_level := true
var encounter_context: Dictionary = {}
var held_actions: Dictionary = {}
var labels = StoryLabels.new()
var label_metrics: Dictionary = {}
var enemy_label_layout: Array[Dictionary] = []
var audio = preload("res://game/garden_audio.gd").new()
var heard_feedback := 0
var font: Font
var camera := Camera2D.new()
var hud := CanvasLayer.new()
var actors: Array[Node2D] = []
var props: Array[Node2D] = []
var enemy_views: Array[Node2D] = []
var fallen_views: Array[Node2D] = []
var title_label: Label
var girl_label: Label
var cat_label: Label
var girl_help: Label
var cat_help: Label
var objective_label: Label
var hint_label: Label
var status_label: Label
var reserve_label: Label
var impact_shake := 0.0
var shake_enabled := true
var rumble_enabled := true
var shake_clock := 0.0
func _init(state) -> void:session=state
func _ready() -> void:
    font=get_parent().theme.default_font
    audio.combat=true;add_child(audio)
    camera.enabled=false;camera.position=Vector2(640,470);camera.zoom=Vector2.ONE*0.90;add_child(camera)
    for role in range(3):
        var view=Actor.new();view.storybook=true;view.combat_visual=true;view.role=role;view.font=font
        add_child(view);actors.append(view)
    hud.layer=11;add_child(hud)
    _panel(Rect2(22,12,1236,62))
    title_label=_label("",Rect2(40,22,275,30),22)
    status_label=_label("",Rect2(315,28,205,25),16)
    girl_label=_label("",Rect2(550,22,320,30),20)
    cat_label=_label("",Rect2(910,22,310,30),20)
    reserve_label=_label("",Rect2(45,91,1150,25),17,Color("fff5db"))
    reserve_label.add_theme_color_override("font_outline_color",Color("27392b"));reserve_label.add_theme_constant_override("outline_size",5)
    girl_help=_label("",Rect2(680,112,530,58),17,Color("fff5db"))
    cat_help=_label("",Rect2(680,176,530,52),17,Color("fff5db"))
    for help in [girl_help,cat_help]:
        help.add_theme_color_override("font_outline_color",Color("27392b"));help.add_theme_constant_override("outline_size",5)
    _panel(Rect2(22,722,1236,65))
    objective_label=_label("",Rect2(42,732,1170,24),20)
    hint_label=_label("",Rect2(42,761,1170,23),16,Color("566d55"))
    if encounter_context.is_empty():configure_solo(session.single_player)
    else:_rebuild_props()
    set_active(false);_sync_actors(0.0);_refresh()
func configure(value: Dictionary) -> bool:
    if str(value.get("mode",""))!=("solo" if session.single_player else "dual"):return false
    var candidate=Battle.new()
    if not candidate.configure(value):return false
    if is_inside_tree():cancel_inputs()
    battle=candidate;solo=Solo.new();encounter_context=value.duplicate(true);held_actions.clear()
    story_title=str(value.get("title",""));story_destination=str(value.get("destination","小路清开了。"))
    allow_next_level=bool(value.get("allow_next_level",true));heard_feedback=0
    if is_inside_tree():_rebuild_props();_sync_actors(0.0);_refresh()
    return true
func result() -> Dictionary:return battle.result()
func configure_solo(value: bool) -> void:
    configure({"id":"practice","mode":"solo" if value else "dual","available_role_ids":[0,1,2],"selected_role_id":0,"current_cat":1,"allow_next_level":not value})
func restart() -> void:
    var next: Dictionary=encounter_context.duplicate(true);next["cleared_segments"]=0;configure(next)
func _rebuild_props() -> void:
    for prop in props:prop.queue_free()
    props.clear()
    for stump in battle.Space.STUMPS:
        var prop=EnemyView.prop(3,82);prop.position=stump;prop.z_index=int(stump.y);add_child(prop);props.append(prop)
    camera.position=battle.FIELD.get_center()+Vector2(0,-15)
    camera.zoom=Vector2.ONE*minf(0.90,1080.0/battle.FIELD.size.x)
func set_active(value: bool) -> void:
    active=value;visible=value;hud.visible=value;camera.enabled=value
    if not value:cancel_inputs()
func cancel_inputs() -> void:
    audio.silence();held_actions.clear();battle.cancel_attacks();battle._cancel_rescue()
    if battle.phase in ["briefing","intermission","failed"]:battle.confirmed.assign([false,false])
    heard_feedback=battle.feedback_id;impact_shake=0;camera.offset=Vector2.ZERO
    for device in session.devices:
        if device>=0:Input.stop_joy_vibration(device)
    for view in actors:
        if view.painted:view.painted.reset_transition()
func handle_action(slot: int,button: int) -> void:
    if not session.running() or slot not in battle.deployed_slots():return
    var key: String=str(slot)+":"+str(button)
    if button in [JOY_BUTTON_X,JOY_BUTTON_LEFT_SHOULDER]:
        if held_actions.has(key):return
        held_actions[key]={"role":battle.actor(slot),"generation":battle.generation[slot]}
    var movement: Vector2=session.movement(slot)
    if movement.length()>0.1 and battle.dodge_time[slot]<=0:battle.facing[slot]=movement.normalized()
    if button==JOY_BUTTON_A and battle.phase=="complete" and allow_next_level:next_level_requested.emit();return
    match button:
        JOY_BUTTON_A:battle.interact(slot)
        JOY_BUTTON_X:battle.attack(slot)
        JOY_BUTTON_B:battle.dodge(slot,movement)
        JOY_BUTTON_Y:battle.request_switch(slot)
        JOY_BUTTON_LEFT_SHOULDER:battle.signature(slot)
func release_action(slot: int,button: int) -> void:
    var key: String=str(slot)+":"+str(button)
    var held: Dictionary=held_actions.get(key,{})
    held_actions.erase(key)
    if not session.running() or slot not in battle.deployed_slots() or held.is_empty():return
    if held.role!=battle.actor(slot) or held.generation!=battle.generation[slot]:return
    if button==JOY_BUTTON_LEFT_SHOULDER:battle.release_signature(slot)
    elif button==JOY_BUTTON_X:battle.release_attack(slot)
func _physics_process(delta: float) -> void:
    if not active or not session.running():return
    battle.step(delta,session.movement(0),Vector2.ZERO if battle.solo_mode else session.movement(1),true)
    for event in battle.feedback_since(heard_feedback):
        audio.play_feedback(event)
        if event.kind in ["heavy","parry","hurt"]:impact_shake=maxf(impact_shake,0.09 if event.kind=="hurt" else 0.07)
        if rumble_enabled and event.slot>=0 and event.kind in ["hit","heavy","blocked","hurt","parry","interrupt"]:
            var device: int=session.devices[event.slot]
            if device>=0:Input.start_joy_vibration(device,0.25,0.45 if event.kind in ["heavy","hurt"] else 0.12,0.075 if event.kind in ["heavy","hurt"] else 0.04)
    heard_feedback=battle.feedback_id;shake_clock+=delta;impact_shake=maxf(0,impact_shake-delta)
    camera.offset=Vector2(sin(shake_clock*171),cos(shake_clock*137))*minf(2,impact_shake*27) if shake_enabled else Vector2.ZERO
    _sync_actors(delta);_refresh()
func _sync_actors(delta: float) -> void:
    for role in range(actors.size()):
        var view=actors[role]
        var slot: int=battle.role_slot(role)
        var deployed: bool=slot>=0
        view.visible=role in battle.available_roles();view.caption_visible=true
        view.caption_override=["朵朵","团团","圆圆"][role]+(" · 你" if battle.solo_mode and deployed else " · P%d"%(slot+1) if deployed else " · 候补")
        view.scale=Vector2(1,0.65) if deployed and battle.hp[slot]<=0 else Vector2.ONE
        view.modulate=Color.WHITE if deployed else Color(0.86,0.88,0.81)
        if deployed and battle.invulnerable[slot]>0:view.modulate.a=0.45 if fmod(battle.invulnerable[slot],0.2)<0.1 else 1.0
        view.combat_active=deployed and battle.attack_flash[slot]>0
        view.guarding=deployed and role==0 and battle.guarding
        view.guard_direction=battle.facing[slot] if deployed else Vector2.RIGHT
        view.combat_kind=battle.attacks.kinds[slot] if deployed else ""
        if deployed and view.combat_kind=="charge" and not battle.attacks.charging:view.combat_kind=""
        var duration: float=battle.attacks.durations[slot] if deployed else 1.0
        view.combat_progress=1.0-battle.attack_flash[slot]/duration if deployed and battle.attack_flash[slot]>0 else 0.0
        if deployed and battle.contact_hold[slot]>0:view.combat_progress=battle.contact_progress[slot]
        view.combat_contact=deployed and battle.contact_hold[slot]>0;view.combat_combo=battle.attacks.current_combo if role==0 else 0
        view.impact_ratio=battle.attacks.impact_times[slot]/duration if deployed else 0.2
        view.hurt_progress=battle.hurt_time[slot]/0.22 if deployed else 0.0
        view.dodging=deployed and battle.dodge_time[slot]>0
        view.combat_direction=battle.attack_direction[slot] if deployed else Vector2.RIGHT
        view.charge_progress=battle.attacks.charge_time/battle.attacks.CHARGE_SECONDS if deployed and battle.attacks.charging and battle.attacks.charging_slot==slot else 0.0
        view.update_pose(battle.positions[role],deployed,false,delta)
func _health(slot: int) -> String:return ("暂时退下" if battle.solo_mode else "坐下待救") if battle.hp[slot]<=0 else "●".repeat(battle.hp[slot])+"○".repeat(3-battle.hp[slot])
func _refresh() -> void:
    if not is_instance_valid(title_label):return
    while enemy_views.size()>battle.enemies.size():enemy_views.pop_back().queue_free()
    while enemy_views.size()<battle.enemies.size():
        var view=EnemyView.new();add_child(view);enemy_views.append(view)
    for i in range(enemy_views.size()):enemy_views[i].sync(battle.enemies[i])
    while fallen_views.size()>battle.fallen.size():fallen_views.pop_back().queue_free()
    while fallen_views.size()<battle.fallen.size():
        var view=EnemyView.new();add_child(view);fallen_views.append(view)
    for i in range(fallen_views.size()):fallen_views[i].sync(battle.fallen[i])
    _layout_labels()
    title_label.text=story_title if not story_title.is_empty() else {"first":"驿站前的小路","shell":"外罩维修道","reserve":"归途树梯","practice":"林间空地"}.get(battle.story_encounter,"林间空地")
    status_label.text=("单人出战" if battle.solo_mode else "双人协作")+" · %d / 2"%battle.cleared_segments
    girl_label.text=["朵朵","团团","圆圆"][battle.actor(0)]+"   "+_health(0)
    cat_label.text="体力随出战共享" if battle.solo_mode else ["朵朵","团团","圆圆"][battle.actor(1)]+"   "+_health(1)
    var reserves: Array[String]=[]
    for role in battle.roster.reserves():reserves.append(["朵朵","团团","圆圆"][role])
    reserve_label.text=("候补  "+" / ".join(reserves)+(" · Tab 换人" if session.keyboard_mode else " · Y 换人")) if not reserves.is_empty() else "两位伙伴正在出战"
    if not battle.solo_mode and not reserves.is_empty():reserve_label.text+="（P2）"
    var swap_slot: int=0 if battle.solo_mode else 1
    if battle.swap_cooldown[swap_slot]>0:reserve_label.text+="  · 接棒 %.1f"%battle.swap_cooldown[swap_slot]
    if battle.signature_cooldown[swap_slot]>0:reserve_label.text+="  · 角色技 %.1f秒"%battle.signature_cooldown[swap_slot]
    if 2 not in battle.available_roles():reserve_label.text+="  · 圆圆尚未归队"
    girl_help.visible=battle.phase in ["briefing","failed"]
    cat_help.visible=girl_help.visible and not battle.solo_mode
    var role: int=battle.actor(0)
    var skill: String=["举盾","精扑打断","蓄力松开重拍"][role]
    girl_help.text="WASD移动 · F普攻 · Q闪避 · G"+skill+"\nE互动" if session.keyboard_mode else "左摇杆 / 十字方向移动 · X普攻 · B闪避\nLB"+skill+" · A互动"
    cat_help.text="方向键 · J普攻 · K闪避 · U"+(["","精扑打断","蓄力松开重拍"][battle.actor(1)])+"\n空格互动 · Tab切猫" if session.keyboard_mode else "P2 左摇杆移动 · X普攻 · B闪避\nLB角色技 · Y切猫 · A互动"
    var key: String="E" if session.keyboard_mode else "A"
    if not battle.solo_mode:key="E / 空格" if session.keyboard_mode else "双方 A"
    objective_label.text=EncounterText()
    hint_label.text=battle.message
    if battle.phase=="briefing":hint_label.text="准备好按 "+key+" 开始；可先试动作。"
    elif battle.phase=="intermission":hint_label.text="准备好按 "+key+" 继续。" if battle.intermission<=0 else "歇一小会。"
    elif battle.phase=="clear":hint_label.text="到亮起的出口，按 "+key+"。"
    elif battle.phase=="complete":hint_label.text=story_destination+"  "+(("E" if session.keyboard_mode else "A") if battle.solo_mode else ("任一位 E / 空格" if session.keyboard_mode else "任一位 A"))+" 继续返回。"
    elif battle.phase=="failed":hint_label.text="按 "+key+" 重试当前一段；可先换出战角色。"
    if battle.attacks.charging:hint_label.text="准备好了 · 松开角色技重拍" if battle.attacks.charge_time>=battle.attacks.CHARGE_SECONDS else "圆圆正在准备重拍"
    if battle.rescuer>=0:hint_label.text="扶起伙伴 %d%% · 移动或受击会松手"%int(battle.rescue_progress/battle.RESCUE_SECONDS*100)
    queue_redraw()
func EncounterText() -> String:
    if battle.phase=="failed":return "先回安全处，再试这段小路。"
    if battle.phase in ["clear","complete"]:return "枝条散开，路露出来了。"
    return battle.Encounter.objective(battle,maxi(1,battle.wave))

func _panel(rect: Rect2) -> void:
    var panel := Panel.new()
    panel.position = rect.position
    panel.size = rect.size
    var style := StyleBoxFlat.new()
    style.bg_color = Color("f4e9cf")
    style.border_color = Color("8b9a70")
    style.set_border_width_all(1)
    style.set_corner_radius_all(16)
    panel.add_theme_stylebox_override("panel", style)
    hud.add_child(panel)

func _label(value: String, rect: Rect2, size: int, color := Color("354b3c")) -> Label:
    var label := Label.new()
    label.text = value
    label.position = rect.position
    label.size = rect.size
    label.add_theme_font_override("font", font)
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", color)
    hud.add_child(label)
    return label

func _draw() -> void:
    draw_rect(Rect2(-800, -800, 3000, 2500), Color("294d3b"))
    draw_texture_rect(BACKDROP,Rect2(-220,40,1720,940),false)
    # Individual seats share the same safe-apron coordinates as the reserve bodies.
    for index in range(battle.roster.reserves().size()):
        var seat: Vector2=battle.Space.reserve_point(index)+Vector2(0,14)
        draw_texture_rect_region(BENCH_WOOD,Rect2(seat-Vector2(37,7),Vector2(74,17)),Rect2(96,132,855,70))
        for side in [-1,1]:draw_line(seat+Vector2(side*27,3),seat+Vector2(side*27,19),Color("645438"),7)
    draw_rect(battle.FIELD.grow(20),Color(0.15,0.26,0.14,0.28),false,25)
    draw_rect(battle.FIELD,Color(0.83,0.85,0.61,0.45),false,3)
    for hazard in battle.hazards:
        var warning: bool = hazard.age < 0.65
        draw_circle(hazard.pos,hazard.radius,Color(0.58,0.14,0.24,0.15 if warning else 0.40))
        draw_arc(hazard.pos,hazard.radius,0,TAU,40,Color("ffc294") if warning else Color("80415b"),3,true)
        for i in range(7):
            var p: Vector2 = hazard.pos+Vector2.from_angle(i*TAU/7)*44
            draw_polyline(PackedVector2Array([p+Vector2(-9,8),p+Vector2(0,-14),p+Vector2(9,8)]),Color("ebbc81") if warning else Color("603c51"),3,true)
    for seed in battle.seeds:
        if seed.mode == "spent": continue
        var p: Vector2 = seed.pos
        draw_set_transform(p,seed.age*8 if seed.mode == "rolling" else sin(shake_clock*3+p.x)*0.06)
        draw_circle(Vector2(0,5),26,Color(0.15,0.24,0.14,0.3))
        draw_circle(Vector2.ZERO,23,Color("d5b066") if seed.mode != "rooted" else Color("a7b55c"))
        draw_arc(Vector2.ZERO,17,0.2,5.0,24,Color("f6e9a0"),3,true)
        for i in range(3):
            var angle := i*TAU/3
            var direction := Vector2.from_angle(angle)
            var side := direction.orthogonal()
            draw_polygon(PackedVector2Array([direction*13-side*9,direction*39,direction*13+side*9]),PackedColorArray([Color("789342") if seed.mode == "rooted" else Color("e2c363")]))
            draw_line(direction*15,direction*34,Color("b9c974"),2,true)
        if seed.mode == "rooted": draw_line(Vector2(0,22),Vector2(0,35),Color("667849"),5,true)
        draw_set_transform(Vector2.ZERO)
    for effect in battle.fx:
        if effect.kind == "plant_burst":
            var r: float = (1-effect.life/0.55)*125
            draw_arc(effect.pos,r,0,TAU,40,Color(0.91,0.85,0.45,effect.life/0.55),6,true)
    # Wide lanes remain on both sides of each stump.
    if battle.phase in ["clear", "complete"]:
        draw_circle(battle.EXIT, 88, Color(0.95, 0.78, 0.40, 0.13))
        draw_arc(battle.EXIT, 88, 0, TAU, 48, Color("eed293"), 3, true)
        draw_line(battle.EXIT + Vector2(-15, 5), battle.EXIT + Vector2(15, -5), Color("74553e"), 8)
        draw_line(battle.EXIT + Vector2(-15, -5), battle.EXIT + Vector2(15, 5), Color("74553e"), 8)
        draw_circle(battle.EXIT + Vector2(0, -15), 15, Color("eeb66b"))
        var camp_text := "营火集合  %s / %s" % ["✓" if battle.confirmed[0] else "朵朵", "✓" if battle.confirmed[1] else "猫咪"]
        if battle.solo_mode:
            camp_text = "战斗完成 ✓" if battle.phase == "complete" else ("营火 · E 确认" if session.keyboard_mode else "营火 · 面键下确认")
        _text(battle.EXIT + Vector2(-95, 104),camp_text,190,17)
    for enemy in battle.enemies:
        var source: Dictionary=battle.linked_source(enemy)
        if not source.is_empty():
            var from: Vector2=source.pos+Vector2(0,-36)
            var to: Vector2=enemy.pos+Vector2(0,-26)
            draw_line(from,to,Color("d1f69b") if source.get("link_flash",0)>0 else Color("5d9670"),5,true)
            for i in range(1,5):
                var knot: Vector2=from.lerp(to,i/5.0)
                draw_circle(knot,4,Color("c4e49c"))
            var angle: float=enemy.direction.angle()
            draw_arc(enemy.pos,40,angle-1.35,angle+1.35,28,Color("70bb85"),7,true)
            draw_arc(enemy.pos,40,angle-1.35,angle+1.35,28,Color("d9efaf"),2,true)
        if enemy.mode == "windup":
            var reach := 364.0 if enemy.kind == "roller" else 230.0
            var end: Vector2 = enemy.pos + enemy.direction * reach
            var side: Vector2 = enemy.direction.orthogonal() * 39
            var full: float = (0.9 if enemy.kind == "thorn" else 1.2)+(0.2 if battle.solo_mode else 0.0)
            var urgency: float = clampf(1.0-enemy.timer/full,0,1)
            draw_line(enemy.pos, end, Color(0.79, 0.26, 0.14, 0.18+urgency*0.14), 78)
            draw_line(enemy.pos, end, Color("865337"), 3, true)
            for step in range(1,4):
                var mark: Vector2 = enemy.pos+enemy.direction*reach*step/4.0
                draw_polyline(PackedVector2Array([mark-enemy.direction*9+side*0.24,mark,mark-enemy.direction*9-side*0.24]),Color("ffe2ad"),3,true)
            draw_line(enemy.pos + side, end + side, Color("f7b278"), 2, true)
            draw_line(enemy.pos - side, end - side, Color("f7b278"), 2, true)
            draw_line(end - enemy.direction * 24 + side * 0.4, end, Color("fbd29d"), 4, true)
            draw_line(end - enemy.direction * 24 - side * 0.4, end, Color("fbd29d"), 4, true)
        if enemy.mode in ["cast","burst","slam_windup","slam"]:
            var center: Vector2 = enemy.get("aim",enemy.pos) if enemy.mode in ["cast","burst"] else enemy.pos
            var radius := 58.0 if enemy.mode in ["cast","burst"] else 112.0
            var warning: bool = enemy.mode in ["cast","slam_windup"]
            draw_circle(center,radius,Color(0.75,0.2,0.27,0.16 if warning else 0.5))
            draw_arc(center,radius,0,TAU,48,Color("f9b19b"),3,true)
            draw_arc(center,radius-6,-PI/2,-PI/2+TAU*clampf(1-enemy.timer,0.02,1),48,Color("fff0ca"),4,true)
            draw_line(center-Vector2(8,0),center+Vector2(8,0),Color("ffd2bd"),2,true)
            draw_line(center-Vector2(0,8),center+Vector2(0,8),Color("ffd2bd"),2,true)
        elif enemy.mode in ["melee_windup","melee"]:
            var angle: float = enemy.direction.angle()
            draw_arc(enemy.pos,82,angle-1.3,angle+1.3,24,Color("efb072"),5,true)
        _draw_enemy(enemy,battle.enemies.find(enemy))
    for effect in battle.fx:
        _draw_impact(effect)
    for slot in battle.deployed_slots():
        var p: Vector2 = battle.positions[battle.actor(slot)]
        if battle.dodge_time[slot] > 0:
            draw_line(p - battle.dodge_direction[slot] * 80, p, Color("b4e5d4"), 6, true)
        elif battle.dodge_cooldown[slot] > 0 and (not battle.solo_mode or slot == solo.human_slot):
            draw_set_transform(p+Vector2(0,4),0,Vector2(1,0.42))
            draw_arc(Vector2.ZERO,39,-PI/2,-PI/2+TAU*(1-battle.dodge_cooldown[slot]/0.72),32,Color(0.65,0.82,0.77,0.72),2,true)
            draw_set_transform(Vector2.ZERO)
        if battle.attack_flash[slot] > 0 and battle.attacks.pending[slot] < 0:
            var direction: Vector2 = battle.attack_direction[slot]
            if battle.actor(slot) == 0:
                var t: float = actors[battle.actor(slot)].combat_progress
                var ratio: float = battle.attacks.impact_times[slot]/battle.attacks.durations[slot]
                var fade := clampf(1-(t-ratio)/0.42,0,1)
                var reverse := -1.0 if battle.attacks.current_combo == 1 else 1.0
                var angle: float = direction.angle()+reverse*clampf((t-ratio)/0.22,0,1)*1.05
                var center := p+Vector2(0,-32)
                var reach := 94.0 if battle.attacks.current_combo == 2 else 84.0
                draw_arc(center,reach,angle-0.85,angle,18,Color(0.83,0.96,0.87,fade*0.68),6 if battle.attacks.current_combo == 2 else 4,true)
                draw_arc(center,reach-4,angle-0.55,angle,14,Color(1,0.97,0.73,fade),2,true)
            elif battle.attacks.kinds[slot] == "claw":
                for side in [-1,0,1]:
                    var offset: Vector2=direction.orthogonal()*side*6
                    draw_line(p+Vector2(0,-18)+direction*32+offset,p+Vector2(0,-18)+direction*55+offset,Color("c8ece4"),2,true)
            elif battle.attacks.kinds[slot] == "pounce":
                for side in [-1,0,1]:
                    var offset: Vector2 = direction.orthogonal()*side*10
                    draw_line(p+direction*24+offset,p+direction*65+offset,Color("ffe2a0"),4,true)
            else:
                var impact := p+direction*49
                var heavy: bool = battle.attacks.kinds[slot] == "heavy"
                for side in [-1,1]:
                    var paw: Vector2 = impact+direction.orthogonal()*side*13
                    draw_circle(paw,9 if heavy else 6,Color("fff0c4"))
                    for toe in [-1,0,1]:
                        draw_circle(paw+direction*12+direction.orthogonal()*toe*5,3,Color("fff0c4"))
                if heavy:
                    var progress: float = 1.0-battle.attack_flash[slot]/battle.attacks.durations[slot]
                    draw_arc(impact,30+progress*24,0,TAU,36,Color(0.91,0.66,0.30,1-progress),4,true)
                    for side in [-1,1]:
                        draw_line(impact+direction.orthogonal()*side*29,impact+direction.orthogonal()*side*42+direction*8,Color("f6d589"),4,true)
        if battle.attacks.charging and battle.attacks.charging_slot == slot:
            var ratio: float = battle.attacks.charge_time/battle.attacks.CHARGE_SECONDS
            draw_arc(p,40,-PI/2,-PI/2+TAU*maxf(0.01,ratio),40,Color("fff0b6"),5,true)
        if battle.actor(slot) == 0 and battle.guarding:
            var angle: float = battle.facing[0].angle()
            draw_arc(p, 44, angle - 1.25, angle + 1.25, 24, Color("9be4d7"), 8, true)
        if battle.hp[slot] <= 0 and not battle.solo_mode:
            draw_circle(p, 38, Color(1.0, 0.8, 0.4, 0.2))
            _text(p + Vector2(-70, 35), "靠近扶起", 140, 18)
    if battle.rescuer >= 0:
        var p: Vector2 = battle.positions[battle.actor(1 - battle.rescuer)]
        draw_arc(p, 43, -PI / 2, -PI / 2 + TAU * battle.rescue_progress / Battle.RESCUE_SECONDS, 48, Color("a7ecd4"), 5, true)

func _ground() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color("71825d")
    style.border_color = Color("a9aa7a")
    style.set_border_width_all(9)
    style.set_corner_radius_all(55)
    return style

func _text(point: Vector2, value: String, width: float, size: int) -> void:
    if font:
        draw_string_outline(font, point, value, HORIZONTAL_ALIGNMENT_CENTER, width, size, 4, Color("f4e9cf"))
        draw_string(font, point, value, HORIZONTAL_ALIGNMENT_CENTER, width, size, Color("394b36"))

func _draw_enemy(enemy: Dictionary,index:int) -> void:
    var p: Vector2 = enemy.pos
    if enemy.kind == "armored" and enemy.mode == "exposed":
        var angle: float = enemy.direction.angle()
        draw_arc(p,48,angle+PI-1.31,angle+PI+1.31,32,Color("527b47"),9,true)
        draw_arc(p,48,angle+PI-1.31,angle+PI+1.31,32,Color("d7f5a9"),4,true)
    if index>=enemy_label_layout.size():return
    var badge:Dictionary=enemy_label_layout[index]
    var rect:Rect2=badge.rect
    _text(rect.position+Vector2(0,18),badge.text,rect.size.x,17)
    var bar:=Rect2(rect.position+Vector2((rect.size.x-50)/2,25),Vector2(50,5))
    draw_rect(bar,Color("424e3e"))
    draw_rect(Rect2(bar.position,Vector2(50.0*enemy.hp/enemy.max_hp,5)),Color("efc08b"))

func _layout_labels()->void:
    var protected:Array[Rect2]=[]
    for enemy in battle.enemies:
        var size:=Vector2(142,154) if enemy.kind=="elder" else Vector2(106,120)
        protected.append(Rect2(enemy.pos-Vector2(size.x/2,size.y-18),size))
        if enemy.mode=="windup":
            var reach:=364.0 if enemy.kind=="roller" else 230.0
            var end:Vector2=enemy.pos+enemy.direction*reach
            protected.append(Rect2(enemy.pos.min(end),enemy.pos.max(end)-enemy.pos.min(end)).grow(42))
        elif enemy.mode in ["cast","burst","slam_windup","slam"]:
            var center:Vector2=enemy.get("aim",enemy.pos) if enemy.mode in ["cast","burst"] else enemy.pos
            var radius:=58.0 if enemy.mode in ["cast","burst"] else 112.0
            protected.append(Rect2(center-Vector2.ONE*radius,Vector2.ONE*radius*2))
        elif enemy.mode in ["melee_windup","melee"]:
            protected.append(Rect2(enemy.pos-Vector2(83,83),Vector2(166,166)))
    for stump in battle.Space.STUMPS:protected.append(Rect2(stump-Vector2(43,78),Vector2(86,95)))
    for hazard in battle.hazards:protected.append(Rect2(hazard.pos-Vector2.ONE*hazard.radius,Vector2.ONE*hazard.radius*2))
    var area:=Rect2(-130,110,1540,735)
    label_metrics=labels.update(actors,protected,area)
    for actor in actors:
        if actor.visible:protected.append(StoryLabels.world_rect(actor,actor.body_rect()))
    for rect in label_metrics.rects:protected.append(rect.grow(3))
    enemy_label_layout.clear()
    for index in range(battle.enemies.size()):
        var enemy:Dictionary=battle.enemies[index]
        var text:String={"armored":"硬壳","thorn":"荆棘","roller":"枝球","sprout":"嫩芽","weaver":"织藤花","elder":"树怪"}.get(enemy.kind,"树怪")
        var cue:String={"windup":"将冲锋","cast":"将落藤","slam_windup":"将重拍","melee_windup":"将挥扫"}.get(enemy.mode,"")
        if enemy.mode=="exposed":cue="背结展开"
        if not battle.linked_source(enemy).is_empty() and cue.is_empty():cue="连藤护住正面"
        if enemy.kind=="weaver" and battle.story_encounter=="shell" and enemy.get("weave_break",0)>0:cue="连藤断开"
        if not cue.is_empty():text+=" · "+cue
        var width:float=maxf(62,font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x+12)
        var base:=Rect2(enemy.pos+Vector2(-width/2,-166 if enemy.kind=="elder" else -127),Vector2(width,32))
        var rect:Rect2=labels.place("enemy-"+str(index),base,protected,area)
        enemy_label_layout.append({"rect":rect,"text":text})
        for avoid in protected:
            if rect.grow(3).intersects(avoid):label_metrics.overlaps+=1
        protected.append(rect.grow(3))

func _draw_impact(effect: Dictionary) -> void:
    if effect.kind in ["swing","charge","ready","danger"]: return
    if effect.kind=="not_ready":
        _text(effect.pos+Vector2(-65,-100),"动作还在恢复",130,16)
        return
    var t: float = clampf(1-effect.life/0.26,0,1)
    var center: Vector2 = effect.pos+Vector2(0,-30)
    var axis: Vector2 = effect.get("direction",Vector2.RIGHT)
    var color := Color("fff1b9")
    color.a = 1-t
    if effect.kind in ["heavy","control"]:
        var ground: Vector2 = effect.pos
        draw_set_transform(ground,0,Vector2(1,0.45))
        draw_arc(Vector2.ZERO,14+t*58,0,TAU,32,Color(1,0.84,0.45,(1-t)*0.8),4*(1-t)+1,true)
        draw_set_transform(Vector2.ZERO)
        for i in range(7):
            var ray := Vector2.from_angle(float(i)*TAU/7)
            var dust := ground+ray*(14+t*45)+Vector2(0,-sin(t*PI)*13)
            draw_circle(dust,3*(1-t)+1,Color(0.86,0.73,0.43,(1-t)*0.75))
    elif effect.kind in ["blocked","guard"]:
        color = Color(0.85,0.9,1,1-t)
        for i in range(4):
            var ray := axis.rotated(-0.8+float(i)*0.55)
            draw_line(center+ray*(7+t*13),center+ray*(17+t*23),color,2,true)
        draw_arc(center,13,axis.angle()-1.1,axis.angle()+1.1,12,color,2,true)
    elif effect.kind == "hurt":
        for i in range(4):
            var ray := Vector2.from_angle(i*PI/2+0.4)
            draw_line(center+ray*(8+t*14),center+ray*(20+t*22),Color(1,0.52,0.39,1-t),3,true)
    elif effect.kind == "defeat":
        for i in range(5):
            var ray := Vector2.from_angle(i*TAU/5)
            var leaf := center+ray*(12+t*28)+Vector2(0,t*t*40)
            draw_line(leaf,leaf+ray.orthogonal()*5,Color(0.69,0.81,0.47,1-t),3,true)
    else:
        for i in range(5):
            var ray := axis.rotated(-PI/2+float(i)*PI/4)
            draw_line(center+ray*(3+t*8),center+ray*(14+t*17),color,2.5,true)
        var slash := axis.orthogonal()
        draw_line(center-slash*(15*(1-t)),center+slash*(15*(1-t)),Color(1,1,0.96,1-t),4*(1-t)+1,true)
    if effect.kind in ["parry","control","interrupt"]:
        var title: String = {"parry":"精挡 · 空当更长","control":"压住了","interrupt":"藤条停了"}[effect.kind]
        _text(center+Vector2(-70,-44-t*15),title,140,18)
