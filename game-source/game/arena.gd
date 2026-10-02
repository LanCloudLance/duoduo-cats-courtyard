extends Node2D
signal next_level_requested
const Solo = preload("res://game/solo_battle.gd")
var solo = Solo.new()
var allow_next_level := true
const Battle = preload("res://game/battle_state.gd")
const Actor = preload("res://game/actor_view.gd")
var battle = Battle.new()
var session
var active := false
var audio := preload("res://game/garden_audio.gd").new()
var heard_feedback := 0
var font: Font
var camera := Camera2D.new()
var hud := CanvasLayer.new()
var actors: Array[Node2D] = []
var title_label: Label
var girl_label: Label
var cat_label: Label
var girl_help: Label
var cat_help: Label
var objective_label: Label
var hint_label: Label
var status_label: Label
var enemy_views: Array[Node2D] = []
var fallen_views: Array[Node2D] = []
var impact_shake := 0.0
var shake_enabled := true
var shake_clock := 0.0
const EnemyView = preload("res://game/enemy_visual.gd")
const BACKDROP = preload("res://assets/visual-m14/arena-painted.png")

func _init(state) -> void:
    session = state

func _ready() -> void:
    font = get_parent().theme.default_font
    audio.combat = true
    add_child(audio)
    camera.enabled = false
    camera.position = Vector2(640, 400)
    add_child(camera)
    for i in range(3):
        var actor_view := Actor.new()
        actor_view.storybook = true
        actor_view.combat_visual = true
        actor_view.role = i
        actor_view.font = font
        actor_view.position = battle.positions[i]
        add_child(actor_view)
        actors.append(actor_view)
    for stump in Battle.Space.STUMPS:
        var prop = EnemyView.prop(3, 82)
        prop.position = stump
        prop.z_index = int(stump.y)
        add_child(prop)
    hud.layer = 11
    add_child(hud)
    _panel(Rect2(24, 20, 274, 124))
    _panel(Rect2(306, 20, 427, 124))
    _panel(Rect2(741, 20, 515, 124))
    title_label = _label("林间空地", Rect2(48, 34, 230, 38), 28)
    status_label = _label("", Rect2(48, 84, 245, 45), 17)
    girl_label = _label("", Rect2(310, 34, 360, 38), 23, Color("316b60"))
    cat_label = _label("", Rect2(745, 34, 480, 38), 23)
    girl_help = _label("", Rect2(310, 81, 430, 50), 17)
    cat_help = _label("", Rect2(745, 81, 480, 50), 17)
    _panel(Rect2(24, 685, 1232, 91))
    objective_label = _label("", Rect2(48, 697, 1170, 32), 22)
    hint_label = _label("", Rect2(48, 738, 1170, 27), 17, Color("566d55"))
    var sound := Button.new()
    sound.text = "音效 开"
    sound.position = Vector2(1110,646)
    sound.add_theme_font_override("font",font)
    sound.pressed.connect(func():
        audio.muted = not audio.muted
        audio.silence()
        sound.text = "音效 关" if audio.muted else "音效 开")
    hud.add_child(sound)
    var deadzone := Button.new()
    deadzone.text = "摇杆死区 20%"
    deadzone.position = Vector2(934,646)
    deadzone.add_theme_font_override("font",font)
    deadzone.pressed.connect(func():
        session.stick_deadzone = 0.28 if session.stick_deadzone < 0.25 and session.stick_deadzone > 0.15 else 0.12 if session.stick_deadzone >= 0.25 else 0.20
        deadzone.text = "摇杆死区 %d%%" % roundi(session.stick_deadzone*100))
    hud.add_child(deadzone)
    var shake_button := Button.new()
    shake_button.text = "震动反馈 开"
    shake_button.position = Vector2(775,646)
    shake_button.add_theme_font_override("font",font)
    shake_button.pressed.connect(func():
        shake_enabled = not shake_enabled
        camera.offset = Vector2.ZERO
        shake_button.text = "震动反馈 开" if shake_enabled else "震动反馈 关")
    hud.add_child(shake_button)
    set_active(false)
    _refresh()

func set_active(value: bool) -> void:
    active = value
    visible = value
    hud.visible = value
    camera.enabled = value
    if not value:
        cancel_inputs()

func cancel_inputs() -> void:
    audio.silence()
    battle.hold_guard(false)
    battle._cancel_rescue()
    battle.cancel_attacks()
    heard_feedback = battle.feedback_id
    impact_shake = 0
    camera.offset = Vector2.ZERO
    for device in session.devices:
        if device >= 0: Input.stop_joy_vibration(device)
    solo.cancel(battle)
    for actor_view in actors:
        if actor_view.painted: actor_view.painted.reset_transition()

func restart() -> void:
    configure_solo(session.single_player)

func configure_solo(value: bool) -> void:
    allow_next_level = not value
    heard_feedback = 0
    battle = Battle.new()
    battle.solo_mode = value
    solo = Solo.new()
    if value: battle.message = "WASD 移动，F 攻击，Tab 换角色；按 E 开始单人战斗。"
    _refresh()

func handle_action(slot: int, button: int) -> void:
    if not session.running():
        return
    var controlled: int = solo.human_slot if battle.solo_mode else slot
    var movement: Vector2 = session.movement(0 if battle.solo_mode else slot)
    if movement.length() > 0.1 and battle.dodge_time[controlled] <= 0:
        battle.facing[controlled] = movement.normalized()
    if battle.solo_mode:
        if slot == 0 and button == JOY_BUTTON_A and battle.phase == "complete" and allow_next_level:
            next_level_requested.emit()
            return
        if slot == 0: solo.press(battle,button,session.movement(0))
        return
    if button == JOY_BUTTON_A and battle.phase == "complete":
        next_level_requested.emit()
        return
    match button:
        JOY_BUTTON_A: battle.interact(slot)
        JOY_BUTTON_X: battle.attack(slot)
        JOY_BUTTON_B: battle.dodge(slot, session.movement(slot))
        JOY_BUTTON_Y:
            if slot == 1:
                battle.switch_cat()
        JOY_BUTTON_LEFT_SHOULDER:
            if slot == 0 and battle.hp[0] > 0:
                battle.hold_guard(true)

func release_action(slot: int, button: int) -> void:
    if battle.solo_mode:
        if slot == 0 and session.running(): solo.release(battle,button)
        return
    if slot == 0 and button == JOY_BUTTON_LEFT_SHOULDER:
        battle.hold_guard(false)
    if session.running() and button == JOY_BUTTON_X:
        battle.release_attack(slot)

func _physics_process(delta: float) -> void:
    if not active or not session.running():
        return
    if battle.solo_mode: solo.step(battle,delta,session.movement(0))
    else: battle.step(delta, session.movement(0), session.movement(1), true)
    for event in battle.feedback_since(heard_feedback):
        audio.play_feedback(event)
        if event.kind in ["heavy","combo","parry","hurt"]:
            impact_shake = maxf(impact_shake,0.09 if event.kind == "hurt" else 0.07)
        if shake_enabled and event.slot >= 0 and event.kind in ["hit","heavy","blocked","hurt","parry","combo"]:
            var device: int = session.devices[0 if session.single_player else event.slot]
            if device >= 0:
                var strong: bool = event.kind in ["heavy","combo","hurt"]
                Input.start_joy_vibration(device,0.25,0.45 if strong else 0.12,0.075 if strong else 0.04)
    heard_feedback = battle.feedback_id
    shake_clock += delta
    impact_shake = maxf(0,impact_shake-delta)
    camera.offset = Vector2(sin(shake_clock*171),cos(shake_clock*137))*minf(2,impact_shake*27) if shake_enabled else Vector2.ZERO
    for i in range(3):
        var slot := 0 if i == 0 else 1
        var selected: bool = i == 0 or i == battle.current_cat
        actors[i].caption_visible = selected
        actors[i].caption_override = ""
        if battle.solo_mode:
            actors[i].caption_override = ["朵朵","团团","圆圆"][i]+(" · 你控制" if selected and slot == solo.human_slot else " · AI")
        actors[i].scale = Vector2(1, 0.65) if selected and battle.hp[slot] <= 0 else Vector2.ONE
        actors[i].modulate = Color(0.7, 0.75, 0.7) if selected and battle.hp[slot] <= 0 else Color.WHITE
        if selected and battle.invulnerable[slot] > 0:
            actors[i].modulate.a = 0.45 if fmod(battle.invulnerable[slot], 0.2) < 0.1 else 1.0
        actors[i].combat_active = selected and battle.attack_flash[slot] > 0
        actors[i].guarding = i == 0 and battle.guarding and battle.hp[0] > 0
        actors[i].guard_direction = battle.facing[0]
        actors[i].combat_kind = battle.attacks.kinds[slot] if selected else ""
        var duration: float = battle.attacks.durations[slot]
        actors[i].combat_progress = 1.0-battle.attack_flash[slot]/duration if selected and battle.attack_flash[slot] > 0 else 0.0
        if selected and battle.contact_hold[slot] > 0:
            actors[i].combat_progress = battle.contact_progress[slot]
        actors[i].combat_contact = selected and battle.contact_hold[slot] > 0
        actors[i].combat_combo = battle.attacks.current_combo if i == 0 else 0
        actors[i].impact_ratio = battle.attacks.impact_times[slot]/duration
        actors[i].hurt_progress = battle.hurt_time[slot]/0.22 if selected else 0.0
        actors[i].dodging = selected and battle.dodge_time[slot] > 0
        actors[i].combat_direction = battle.attack_direction[slot]
        actors[i].charge_progress = battle.attacks.charge_time/battle.attacks.CHARGE_SECONDS if selected and i == 2 else 0.0
        if not battle.attacks.charging and actors[i].combat_kind == "charge": actors[i].combat_kind = ""
        if not selected and i == battle.assist_role and battle.assist_time > 0:
            actors[i].combat_active = true
            actors[i].combat_kind = "pounce" if i == 1 else "slap"
            actors[i].combat_progress = 1-battle.assist_time/0.22
            actors[i].combat_direction = battle.positions[i].direction_to(battle.assist_point)
        actors[i].update_pose(battle.positions[i], selected and (not battle.solo_mode or slot == solo.human_slot), false, delta)
    _refresh()

func _refresh() -> void:
    if not is_instance_valid(title_label):
        return
    while enemy_views.size() > battle.enemies.size():
        enemy_views.pop_back().queue_free()
    while enemy_views.size() < battle.enemies.size():
        var view = EnemyView.new()
        add_child(view)
        enemy_views.append(view)
    for i in range(enemy_views.size()):
        enemy_views[i].sync(battle.enemies[i])
    while fallen_views.size() > battle.fallen.size(): fallen_views.pop_back().queue_free()
    while fallen_views.size() < battle.fallen.size():
        var view = EnemyView.new()
        add_child(view)
        fallen_views.append(view)
    for i in range(fallen_views.size()): fallen_views[i].sync(battle.fallen[i])
    girl_label.text = "P1 朵朵   " + _health(0)
    cat_label.text = "P2 " + ("团团" if battle.current_cat == 1 else "圆圆") + "   " + _health(1) + "  · 双猫共用"
    status_label.text = "协作战斗   %d / 3\nEsc / 菜单键暂停" % battle.wave
    if session.keyboard_mode:
        girl_help.text = "WASD 移动 · F 连击 · Q 闪避\n按住 G 正面举盾 · E 互动 / 救援"
        cat_help.text = ("方向键 · J 短扑快抓 · K 闪避" if battle.current_cat == 1 else "方向键 · J 轻拍 / 蓄力松开重拍")+"\n空格救援 · Tab 切猫 · K 闪避"
    else:
        girl_help.text = "左摇杆移动 · 面键左攻击 / 右闪避\n按住左肩举盾 · 面键下互动 / 救援"
        cat_help.text = ("左摇杆移动 · 面键左短扑快抓" if battle.current_cat == 1 else "面键左：短按轻拍 / 蓄力松开重拍")+"\n面键右闪避 · 下互动 · 上切猫"
    var interaction := "朵朵 E / 猫咪空格" if session.keyboard_mode else "双方的面键下方"
    match battle.phase:
        "briefing": objective_label.text = "准备好再出发：%s确认   %s / %s" % [interaction, "朵朵已准备" if battle.confirmed[0] else "朵朵待准备", "猫咪已准备" if battle.confirmed[1] else "猫咪待准备"]
        "combat": objective_label.text = ["移动连击清小怪，侧闪冲锋；别被逼到树桩旁。","后排藤蔓会锁定脚下：打断它，或分头处理硬壳。","取回树怪的灯芯：挡冲锋、绕侧输出，红圈亮起就拉开。"][battle.wave-1]
        "intermission": objective_label.text = "喘口气 · 下一段即将开始，先扶起坐下的伙伴。"
        "clear": objective_label.text = "到右边营火集合，%s确认休息。" % interaction
        "complete": objective_label.text = "林间空地完成 ✓ 再按互动键，前往双猫灯廊。"
    if battle.hp[0] == 0 and battle.hp[1] == 0:
        objective_label.text = "两位一起歇一下……马上从本波重新开始，已解开的桥保留。"
    elif battle.hp[0] == 0 or battle.hp[1] == 0:
        objective_label.text = "靠近坐下的伙伴，按互动键，停留 1.2 秒扶起。"
    if battle.rescuer >= 0:
        objective_label.text = "正在扶起伙伴  %d%%  · 不要移动，被击中会中断" % int(battle.rescue_progress / Battle.RESCUE_SECONDS * 100)
    hint_label.text = battle.message.replace("互动键", "E / 空格" if session.keyboard_mode else "面键下方")
    if battle.attacks.charging and battle.hp[0] > 0 and battle.hp[1] > 0:
        hint_label.text = "圆圆蓄满了 · 松开攻击键重拍；闪避可以取消。" if battle.attacks.charge_time >= battle.attacks.CHARGE_SECONDS-0.00001 else "圆圆正在准备重拍 · 可以慢慢移动调整方向，松开攻击键出手。"
    if battle.solo_mode: _solo_hud()
    queue_redraw()

func _health(slot: int) -> String:
    return "坐下待救" if battle.hp[slot] <= 0 else "●".repeat(battle.hp[slot]) + "○".repeat(3 - battle.hp[slot])

func _solo_hud() -> void:
    var actor: int = battle.actor(solo.human_slot)
    var who: String = ["朵朵","团团","圆圆"][actor]
    girl_label.text = "朵朵 · "+("你控制" if solo.human_slot == 0 else "AI")+"  "+_health(0)
    cat_label.text = ("团团" if battle.current_cat == 1 else "圆圆")+" · "+("你控制" if solo.human_slot == 1 else "AI")+"  "+_health(1)
    status_label.text = "单人协作   %d / 3\nEsc / 菜单键暂停" % battle.wave
    girl_help.text = "WASD 移动 · F 攻击 · Q 闪避\nE 互动 / 救援 · G 朵朵举盾" if session.keyboard_mode else "左摇杆 · 面键左攻击 / 右闪避\n面键下互动 · 左肩朵朵举盾"
    if actor > 0:
        girl_help.text = ("WASD · F "+("短扑快抓" if actor == 1 else "轻拍 / 蓄力松开重拍")+"\nE 互动 / 救援 · Q 闪避") if session.keyboard_mode else ("面键左："+("短扑快抓" if actor == 1 else "轻拍 / 蓄力松开重拍")+"\n左摇杆移动 · 右闪避 · 下互动")
    cat_help.text = ("Tab 换角色" if session.keyboard_mode else "面键上换角色")+" · 当前："+who+"\nAI："+solo.companion.status
    var key := "E" if session.keyboard_mode else "面键下"
    match battle.phase:
        "briefing": objective_label.text = "先试试三位动作 · 按 %s 开始，AI 伙伴会协助战斗。" % key
        "intermission": objective_label.text = "喘口气 · 下一段即将开始，先扶起坐下的伙伴。"
        "clear": objective_label.text = "带伙伴到右边营火，按 %s 完成本次单人战斗。" % key
        "complete": objective_label.text = ("林间空地完成 ✓ 再按 %s，前往双猫灯廊。" % key) if allow_next_level else "单人战斗试玩完成 ✓ Esc / 菜单键可以重玩或选择其他关卡。"
    if battle.hp[solo.human_slot] <= 0 and battle.hp[1-solo.human_slot] > 0:
        objective_label.text = "伙伴正在找机会救你；也可按 %s 接管伙伴救援。" % ("Tab" if session.keyboard_mode else "面键上")
    elif battle.hp[1-solo.human_slot] <= 0:
        objective_label.text = "靠近伙伴，按 %s 并停留片刻扶起。" % key
    if battle.hp[0] <= 0 and battle.hp[1] <= 0:
        objective_label.text = "一起歇一下……马上重试当前轮。"
    if battle.attacks.charging and solo.human_slot == 0:
        hint_label.text = "圆圆正在准备重拍，留意敌人的冲锋预警。"
    if battle.rescuer >= 0:
        objective_label.text = "正在救援 %d%%" % int(battle.rescue_progress/battle.RESCUE_SECONDS*100)

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
    draw_texture_rect(BACKDROP,Rect2(0,0,1280,800),false)
    for stump in Battle.Space.STUMPS:
        var prompt_rect := Rect2(stump+Vector2(-75,43),Vector2(150,24))
        if battle.positions.all(func(point): return not prompt_rect.intersects(Rect2(point-Vector2(42,146),Vector2(84,164)))):
            _text(stump+Vector2(-75,62),"可引它撞树桩",150,16)
    # Wide lanes remain on both sides of each stump.
    if battle.phase in ["clear", "complete"]:
        draw_circle(Battle.EXIT, 88, Color(0.95, 0.78, 0.40, 0.13))
        draw_arc(Battle.EXIT, 88, 0, TAU, 48, Color("eed293"), 3, true)
        draw_line(Battle.EXIT + Vector2(-15, 5), Battle.EXIT + Vector2(15, -5), Color("74553e"), 8)
        draw_line(Battle.EXIT + Vector2(-15, -5), Battle.EXIT + Vector2(15, 5), Color("74553e"), 8)
        draw_circle(Battle.EXIT + Vector2(0, -15), 15, Color("eeb66b"))
        var camp_text := "营火集合  %s / %s" % ["✓" if battle.confirmed[0] else "朵朵", "✓" if battle.confirmed[1] else "猫咪"]
        if battle.solo_mode:
            camp_text = "战斗完成 ✓" if battle.phase == "complete" else ("营火 · E 确认" if session.keyboard_mode else "营火 · 面键下确认")
        _text(Battle.EXIT + Vector2(-95, 104),camp_text,190,17)
    for enemy in battle.enemies:
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
        _draw_enemy(enemy)
    for effect in battle.fx:
        _draw_impact(effect)
    for slot in range(2):
        var p: Vector2 = battle.positions[battle.actor(slot)]
        if battle.dodge_time[slot] > 0:
            draw_line(p - battle.dodge_direction[slot] * 80, p, Color("b4e5d4"), 6, true)
        elif battle.dodge_cooldown[slot] > 0 and (not battle.solo_mode or slot == solo.human_slot):
            draw_set_transform(p+Vector2(0,4),0,Vector2(1,0.42))
            draw_arc(Vector2.ZERO,39,-PI/2,-PI/2+TAU*(1-battle.dodge_cooldown[slot]/0.72),32,Color(0.65,0.82,0.77,0.72),2,true)
            draw_set_transform(Vector2.ZERO)
        if battle.attack_flash[slot] > 0 and battle.attacks.pending[slot] < 0:
            var direction: Vector2 = battle.attack_direction[slot]
            if slot == 0:
                var t: float = actors[0].combat_progress
                var ratio: float = battle.attacks.impact_times[0]/battle.attacks.durations[0]
                var fade := clampf(1-(t-ratio)/0.42,0,1)
                var reverse := -1.0 if battle.attacks.current_combo == 1 else 1.0
                var angle: float = direction.angle()+reverse*clampf((t-ratio)/0.22,0,1)*1.05
                var center := p+Vector2(0,-32)
                var reach := 94.0 if battle.attacks.current_combo == 2 else 84.0
                draw_arc(center,reach,angle-0.85,angle,18,Color(0.83,0.96,0.87,fade*0.68),6 if battle.attacks.current_combo == 2 else 4,true)
                draw_arc(center,reach-4,angle-0.55,angle,14,Color(1,0.97,0.73,fade),2,true)
            elif battle.attacks.kinds[1] == "pounce":
                for side in [-1,0,1]:
                    var offset: Vector2 = direction.orthogonal()*side*10
                    draw_line(p+direction*24+offset,p+direction*65+offset,Color("ffe2a0"),4,true)
            else:
                var impact := p+direction*49
                var heavy: bool = battle.attacks.kinds[1] == "heavy"
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
        if slot == 1 and battle.attacks.charging:
            var ratio: float = battle.attacks.charge_time/battle.attacks.CHARGE_SECONDS
            draw_arc(p,40,-PI/2,-PI/2+TAU*maxf(0.01,ratio),40,Color("fff0b6"),5,true)
        if slot == 0 and battle.guarding:
            var angle: float = battle.facing[0].angle()
            draw_arc(p, 44, angle - 1.25, angle + 1.25, 24, Color("9be4d7"), 8, true)
        if battle.hp[slot] <= 0:
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

func _draw_enemy(enemy: Dictionary) -> void:
    var p: Vector2 = enemy.pos
    if enemy.kind == "armored" and enemy.mode == "exposed":
        var angle: float = enemy.direction.angle()
        draw_arc(p,48,angle+PI-1.31,angle+PI+1.31,32,Color("527b47"),9,true)
        draw_arc(p,48,angle+PI-1.31,angle+PI+1.31,32,Color("d7f5a9"),4,true)
    var label: String = {"armored":"硬壳荆棘团","thorn":"荆棘团","roller":"枝球","sprout":"嫩芽怪","weaver":"织藤花","elder":"灯芯树怪"}.get(enemy.kind,"树怪")
    if enemy.mode in ["windup","cast","slam_windup","melee_windup"]:
        label += " · 蓄力！"
    elif enemy.mode == "rest":
        label += " · 休息"
    elif enemy.mode == "exposed":
        label = "露出破绽 · 追击！" if enemy.kind == "elder" else "背后结点展开 · 绕后！"
    var top := -150.0 if enemy.kind == "elder" else -108.0
    var label_point: Vector2 = p+Vector2(-115,top)
    for offset in [Vector2(-115,top),Vector2(0,top),Vector2(-115,75)]:
        var candidate: Vector2 = p+offset
        var rect := Rect2(candidate-Vector2(0,18),Vector2(230,22))
        if candidate.x < 100 or candidate.x+230 > 1180 or candidate.y < 230 or candidate.y > 625: continue
        if battle.positions.all(func(point): return not rect.intersects(Rect2(point-Vector2(68,169),Vector2(136,184)))):
            label_point = candidate
            break
    _text(label_point, label, 230, 17)
    draw_rect(Rect2(p + Vector2(-25, top-15), Vector2(50, 5)), Color("424e3e"))
    draw_rect(Rect2(p + Vector2(-25, top-15), Vector2(50.0 * enemy.hp / enemy.max_hp, 5)), Color("efc08b"))

func _draw_impact(effect: Dictionary) -> void:
    if effect.kind in ["swing","charge","ready","danger"]: return
    var t: float = clampf(1-effect.life/0.26,0,1)
    var center: Vector2 = effect.pos+Vector2(0,-30)
    var axis: Vector2 = effect.get("direction",Vector2.RIGHT)
    var color := Color("fff1b9")
    color.a = 1-t
    if effect.kind in ["heavy","combo"]:
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
    if effect.kind in ["parry","combo","assist","interrupt"]:
        var title: String = {"parry":"完美挡招","combo":"接力掀翻","assist":"接棒追击","interrupt":"打断成功"}[effect.kind]
        _text(center+Vector2(-70,-44-t*15),title,140,18)
