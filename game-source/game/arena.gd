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
const EnemyView = preload("res://game/enemy_visual.gd")
const BACKDROP = preload("res://assets/visual-m14/arena-painted.png")

func _init(state) -> void:
    session = state

func _ready() -> void:
    font = get_parent().theme.default_font
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
    battle.guarding = false
    battle._cancel_rescue()
    battle.cancel_attacks()
    solo.cancel(battle)
    for actor_view in actors:
        if actor_view.painted: actor_view.painted.reset_transition()

func restart() -> void:
    configure_solo(session.single_player)

func configure_solo(value: bool) -> void:
    allow_next_level = not value
    battle = Battle.new()
    battle.solo_mode = value
    solo = Solo.new()
    if value: battle.message = "WASD 移动，F 攻击，Tab 换角色；按 E 开始单人战斗。"
    _refresh()

func handle_action(slot: int, button: int) -> void:
    if not session.running():
        return
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
            if slot == 0 and battle.hp[0] > 0 and battle.dodge_time[0] <= 0:
                battle.guarding = true

func release_action(slot: int, button: int) -> void:
    if battle.solo_mode:
        if slot == 0 and session.running(): solo.release(battle,button)
        return
    if slot == 0 and button == JOY_BUTTON_LEFT_SHOULDER:
        battle.guarding = false
    if session.running() and button == JOY_BUTTON_X:
        battle.release_attack(slot)

func _physics_process(delta: float) -> void:
    if not active or not session.running():
        return
    if battle.solo_mode: solo.step(battle,delta,session.movement(0))
    else: battle.step(delta, session.movement(0), session.movement(1), true)
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
        var duration := 0.24 if slot == 0 else (0.3 if battle.attacks.kinds[1] == "heavy" else 0.22)
        actors[i].combat_progress = 1.0-battle.attack_flash[slot]/duration if selected and battle.attack_flash[slot] > 0 else 0.0
        actors[i].combat_direction = battle.attack_direction[slot]
        actors[i].charge_progress = battle.attacks.charge_time/0.6 if selected and i == 2 else 0.0
        if not battle.attacks.charging and actors[i].combat_kind == "charge": actors[i].combat_kind = ""
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
    girl_label.text = "P1 朵朵   " + _health(0)
    cat_label.text = "P2 " + ("团团" if battle.current_cat == 1 else "圆圆") + "   " + _health(1) + "  · 双猫共用"
    status_label.text = "角色攻击 / M14.1   %d / 3\nEsc / 菜单键暂停" % battle.wave
    if session.keyboard_mode:
        girl_help.text = "WASD 移动 · F 横扫 · Q 闪避\n按住 G 正面举盾 · E 互动 / 救援"
        cat_help.text = ("方向键 · J 短扑快抓 · K 闪避" if battle.current_cat == 1 else "方向键 · J 轻拍 / 蓄力松开重拍")+"\n空格救援 · Tab 切猫 · K 闪避"
    else:
        girl_help.text = "左摇杆移动 · 面键左攻击 / 右闪避\n按住左肩举盾 · 面键下互动 / 救援"
        cat_help.text = ("左摇杆移动 · 面键左短扑快抓" if battle.current_cat == 1 else "面键左：短按轻拍 / 蓄力松开重拍")+"\n面键右闪避 · 下互动 · 上切猫"
    var interaction := "朵朵 E / 猫咪空格" if session.keyboard_mode else "双方的面键下方"
    match battle.phase:
        "briefing": objective_label.text = "准备好再出发：%s确认   %s / %s" % [interaction, "朵朵已准备" if battle.confirmed[0] else "朵朵待准备", "猫咪已准备" if battle.confirmed[1] else "猫咪待准备"]
        "combat": objective_label.text = "看预警，向侧面闪避；敌人停下时靠近攻击。" if battle.wave == 1 else "盾挡或引它撞树桩 → 结点展开 → 伙伴绕后进攻。"
        "intermission": objective_label.text = ("这一段安全了 · 整理 %d 秒" % ceili(battle.intermission)) if battle.intermission > 0 else ("下一段：%s确认  %s / %s" % [interaction,"朵朵 ✓" if battle.confirmed[0] else "朵朵待准备","猫咪 ✓" if battle.confirmed[1] else "猫咪待准备"])
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
        hint_label.text = "圆圆蓄满了 · 松开攻击键重拍；闪避可以取消。" if battle.attacks.charge_time >= 0.599 else "圆圆正在准备重拍 · 可以慢慢移动调整方向，松开攻击键出手。"
    if battle.solo_mode: _solo_hud()
    queue_redraw()

func _health(slot: int) -> String:
    return "坐下待救" if battle.hp[slot] <= 0 else "●".repeat(battle.hp[slot]) + "○".repeat(3 - battle.hp[slot])

func _solo_hud() -> void:
    var actor: int = battle.actor(solo.human_slot)
    var who: String = ["朵朵","团团","圆圆"][actor]
    girl_label.text = "朵朵 · "+("你控制" if solo.human_slot == 0 else "AI")+"  "+_health(0)
    cat_label.text = ("团团" if battle.current_cat == 1 else "圆圆")+" · "+("你控制" if solo.human_slot == 1 else "AI")+"  "+_health(1)
    status_label.text = "单人战斗 / M14.1   %d / 3\nEsc / 菜单键暂停" % battle.wave
    girl_help.text = "WASD 移动 · F 攻击 · Q 闪避\nE 互动 / 救援 · G 朵朵举盾" if session.keyboard_mode else "左摇杆 · 面键左攻击 / 右闪避\n面键下互动 · 左肩朵朵举盾"
    if actor > 0:
        girl_help.text = ("WASD · F "+("短扑快抓" if actor == 1 else "轻拍 / 蓄力松开重拍")+"\nE 互动 / 救援 · Q 闪避") if session.keyboard_mode else ("面键左："+("短扑快抓" if actor == 1 else "轻拍 / 蓄力松开重拍")+"\n左摇杆移动 · 右闪避 · 下互动")
    cat_help.text = ("Tab 换角色" if session.keyboard_mode else "面键上换角色")+" · 当前："+who+"\nAI："+solo.companion.status
    var key := "E" if session.keyboard_mode else "面键下"
    match battle.phase:
        "briefing": objective_label.text = "先试试三位动作 · 按 %s 开始，AI 伙伴会协助战斗。" % key
        "intermission": objective_label.text = "整理 %d 秒" % ceili(battle.intermission) if battle.intermission > 0 else "准备好了按 %s，开始下一轮。" % key
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
        _draw_enemy(enemy)
    for slot in range(2):
        var p: Vector2 = battle.positions[battle.actor(slot)]
        if battle.dodge_time[slot] > 0:
            draw_line(p - battle.dodge_direction[slot] * 80, p, Color("b4e5d4"), 6, true)
        if battle.attack_flash[slot] > 0:
            var direction: Vector2 = battle.attack_direction[slot]
            if slot == 0:
                draw_arc(p,103,direction.angle()-PI/3,direction.angle()+PI/3,28,Color(0.52,0.86,0.74,0.85),7,true)
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
                    var progress: float = 1.0-battle.attack_flash[slot]/0.3
                    draw_arc(impact,30+progress*24,0,TAU,36,Color(0.91,0.66,0.30,1-progress),4,true)
                    for side in [-1,1]:
                        draw_line(impact+direction.orthogonal()*side*29,impact+direction.orthogonal()*side*42+direction*8,Color("f6d589"),4,true)
        if slot == 1 and battle.attacks.charging:
            var ratio: float = battle.attacks.charge_time/0.6
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
    var label := "硬壳荆棘团" if enemy.kind == "armored" else ("荆棘团" if enemy.kind == "thorn" else "枝球")
    if enemy.mode == "windup":
        label += " · 蓄力！"
    elif enemy.mode == "rest":
        label += " · 休息"
    elif enemy.mode == "exposed":
        label = "背后结点展开 · 绕后！"
    var label_point: Vector2 = p+Vector2(-115,-70)
    for offset in [Vector2(-115,-70),Vector2(0,-120),Vector2(-115,85)]:
        var candidate: Vector2 = p+offset
        var rect := Rect2(candidate-Vector2(0,18),Vector2(230,22))
        if candidate.x < 100 or candidate.x+230 > 1180 or candidate.y < 230 or candidate.y > 650: continue
        if battle.positions.all(func(point): return not rect.intersects(Rect2(point-Vector2(36,102),Vector2(72,118)))):
            label_point = candidate
            break
    _text(label_point, label, 230, 17)
    draw_rect(Rect2(p + Vector2(-25, -87), Vector2(50, 5)), Color("424e3e"))
    draw_rect(Rect2(p + Vector2(-25, -87), Vector2(50.0 * enemy.hp / enemy.max_hp, 5)), Color("efc08b"))
