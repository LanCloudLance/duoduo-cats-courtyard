extends Control

const Session = preload("res://input/session_state.gd")
const Journal = preload("res://ui/story_journal.gd")
const Router = preload("res://input/event_router.gd")
const Stick = preload("res://ui/stick_indicator.gd")
const StoryChapter = preload("res://game/story_chapter_view.gd")
const ChapterOne = preload("res://game/chapter_one.gd")
const Prologue = preload("res://game/prologue.gd")
const Courtyard = preload("res://game/courtyard.gd")
const Arena = preload("res://game/arena.gd")
const LightCorridor = preload("res://game/light_corridor.gd")
const ChimeGate = preload("res://game/chime_gate.gd")
const RestArea = preload("res://game/rest_area.gd")
const StoryJourney = preload("res://game/story_journey.gd")
const Checkpoint = preload("res://game/checkpoint.gd")
const TEAM = preload("res://assets/team.png")
const Music = preload("res://game/music_director.gd")
const CREAM := Color("f6eedc")
const MUTE := Color("a8b9ad")
const GOLD := Color("e9c981")
var session = Session.new()
var router = Router.new(session)
var devices_text: Array[Label] = []
var ready_text: Array[Label] = []
var action_text: Array[Label] = []
var vector_text: Array[Label] = []
var sticks: Array[Control] = []
var top_status: Label
var footer_status: Label
var last_buttons: Array[int] = [-1, -1]
var selected_story_chapter := 2
var story_chapter: Node2D
var chapter_one: Node2D
var prologue: Node2D
var courtyard: Node2D
var arena: Node2D
var light_corridor: Node2D
var chime_gate: Node2D
var rest_area: Node2D
var checkpoint = Checkpoint.new()
var solo_checkpoint = Checkpoint.new("user://courtyard-solo-safe-v1.json")
var solo_resume_button: Button
var resume_button: Button
var stage := "bridge"
var preview_run := false
var story_progress=StoryJourney.new()
var story_run_id:=""
var story_route_active:=false
var story_manifest_error:=""
var story_pending_chapter:=0
var story_manifest_retry:=0.0
var story_save_notice:Label
var web_pause_callback: JavaScriptObject
var web_probe_clock := 0.0
var menu_index := -1
var menu_controls: Array[Button] = []
var mode_help: Label
var claim_buttons: Array[Button] = []
var slot_titles: Array[Label] = []
var slot_badges: Array[Label] = []
var slot_details: Array[Label] = []
var music: Node
var music_started := false
var music_setting := 1
var music_button: Button
var music_feedback_cursor := 0
var journal:CanvasLayer
var journal_button:Button
var journal_ready:Array=[]
var journal_devices:Array=[]
var journal_keyboard:=false

func _ready() -> void:
    Input.ignore_joypad_on_unfocused_application = true
    var theme_value := Theme.new()
    theme_value.default_font = load("res://assets/fonts/CourtyardSans.ttf")
    theme_value.default_font_size = 20
    theme = theme_value
    _build()
    music = Music.new()
    # Offline state suites have no mixing device. Their scene context still runs;
    # the dedicated playback suite explicitly exercises real decoder voices.
    music.audible = DisplayServer.get_name() != "headless"
    music.name = "JourneyMusic"
    add_child(music)
    var music_hud := CanvasLayer.new()
    music_hud.layer = 30
    add_child(music_hud)
    music_button = Button.new()
    music_button.position = Vector2(18,774)
    music_button.size = Vector2(142,24)
    music_button.add_theme_font_override("font",theme.default_font)
    music_button.add_theme_font_size_override("font_size",14)
    music_button.text = "♫ 音乐：标准"
    music_button.tooltip_text = "轻声 / 标准 / 关闭；音效另行控制"
    music_hud.add_child(music_button)
    story_save_notice=Label.new();story_save_notice.name="JourneySaveNotice"
    story_save_notice.position=Vector2(28,78);story_save_notice.size=Vector2(1150,44)
    story_save_notice.add_theme_font_override("font",theme.default_font);story_save_notice.add_theme_font_size_override("font_size",17)
    story_save_notice.add_theme_color_override("font_color",Color("ffe3a1"));story_save_notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    var notice_style:=StyleBoxFlat.new();notice_style.bg_color=Color("243c32");notice_style.set_corner_radius_all(8);notice_style.content_margin_left=12;notice_style.content_margin_top=6
    story_save_notice.add_theme_stylebox_override("normal",notice_style);story_save_notice.visible=false;music_hud.add_child(story_save_notice)
    menu_controls.append(music_button)
    journal=Journal.new(theme.default_font);add_child(journal);journal.close_requested.connect(close_journal);journal.hint_requested.connect(journal_hint)
    journal_button=Button.new();journal_button.position=Vector2(174,774);journal_button.size=Vector2(180,24);journal_button.text="旅途记事 · H / 返回键";journal_button.add_theme_font_override("font",theme.default_font);journal_button.add_theme_font_size_override("font_size",14);music_hud.add_child(journal_button);journal_button.pressed.connect(open_journal)
    music_button.pressed.connect(func():
        music_setting = (music_setting+1)%3
        music.level = 0.12 if music_setting == 0 else 0.28
        music.set_muted(music_setting == 2)
        music_button.text = ["♫ 音乐：轻声","♫ 音乐：标准","♫ 音乐：关闭"][music_setting]
    )
    story_chapter = StoryChapter.new(session)
    story_chapter.name = "StoryChapter"
    add_child(story_chapter)
    story_chapter.battle_requested.connect(enter_story_combat)
    story_chapter.next_chapter_requested.connect(func(chapter):
        session.pause_all("下一章")
        start_story_chapter(chapter,session.single_player,true)
    )
    chapter_one = ChapterOne.new(session)
    chapter_one.name = "ChapterOne"
    add_child(chapter_one)
    chapter_one.battle_requested.connect(enter_chapter_combat)
    chapter_one.next_chapter_requested.connect(func():
        session.pause_all("进入第二章")
        start_story_chapter(2,session.single_player,true)
    )
    prologue = Prologue.new(session)
    prologue.name = "Prologue"
    add_child(prologue)
    courtyard = Courtyard.new(session)
    courtyard.name = "Courtyard"
    add_child(courtyard)
    arena = Arena.new(session)
    arena.name = "Arena"
    add_child(arena)
    light_corridor = LightCorridor.new(session)
    light_corridor.name = "LightCorridor"
    add_child(light_corridor)
    chime_gate = ChimeGate.new(session)
    chime_gate.name = "ChimeGate"
    add_child(chime_gate)
    rest_area = RestArea.new(session)
    rest_area.name = "RestArea"
    add_child(rest_area)
    prologue.next_chapter_requested.connect(func():
        router.clear_keyboard()
        session.pause_all("进入第一章")
        start_chapter_one(session.single_player,true)
    )
    courtyard.next_level_requested.connect(enter_combat)
    arena.next_level_requested.connect(func():
        if stage == "story-combat":
            router.clear_keyboard()
            story_chapter.state.after_battle()
            stage = "story-chapter"
            arena.set_active(false)
            story_chapter.set_active(session.running())
        elif stage == "chapter-combat":
            router.clear_keyboard()
            chapter_one.finish_battle()
            stage = "chapter-one"
            arena.set_active(false)
            chapter_one.set_active(session.running())
        else: enter_light()
    )
    light_corridor.next_level_requested.connect(enter_gate)
    chime_gate.next_level_requested.connect(enter_rest)
    rest_area.checkpoint_requested.connect(_save_checkpoint)
    router.action_pressed.connect(_action)
    router.action_released.connect(func(slot, button):
        if stage in ["combat","chapter-combat","story-combat"]: arena.release_action(slot, button)
        elif stage == "story-chapter": story_chapter.release_action(slot,button)
    )
    router.actions_cancelled.connect(func():
        arena.cancel_inputs()
        story_chapter.cancel_inputs()
    )
    Input.joy_connection_changed.connect(_connection_changed)
    if not OS.has_feature("web") and checkpoint.path == "user://courtyard-safe-v1.json":
        var legacy: Array = []
        for version in ["M10","M9","M8","M7","M6"]:
            legacy.append(OS.get_data_dir().path_join("Godot/app_userdata/朵朵与猫猫 · 庭院试玩 "+version+"/courtyard-safe-v1.json"))
        checkpoint.import_legacy(legacy)
    _refresh_checkpoint_button()
    print("CONNECTED GAMEPADS: ", Input.get_connected_joypads())
    var web_story := ""
    var web_solo := false
    if OS.has_feature("web"):
        web_story = str(JavaScriptBridge.eval("window.location.search",true))
        web_solo = str(JavaScriptBridge.eval("window.location.search",true)).contains("mode=solo")
        web_pause_callback = JavaScriptBridge.create_callback(func(_args):
            router.clear_keyboard()
            session.pause_all("已暂停 · 点回游戏后按 Enter 或菜单键继续")
        )
        JavaScriptBridge.get_interface("window").duoduoPause = web_pause_callback
        print("WEB_READY solo=",web_solo," persistent=",OS.is_userfs_persistent()," userdir=",OS.get_user_data_dir())
    var requested_chapter := 0
    for c in range(2,6):
        if web_story.contains("mode=chapter-"+str(c)+"-") or ("--chapter-"+str(c)) in OS.get_cmdline_user_args(): requested_chapter = c
    if requested_chapter>0:
        start_story_chapter(requested_chapter,web_story.contains("-solo") or "--solo-journey" in OS.get_cmdline_user_args())
    elif web_story.contains("mode=chapter-one") or "--chapter-one" in OS.get_cmdline_user_args():
        start_chapter_one(web_story.contains("-solo") or "--solo-journey" in OS.get_cmdline_user_args())
    elif web_story.contains("mode=trial-"):
        start_trial("combat" if web_story.contains("trial-combat") else ("gate" if web_story.contains("trial-gate") else "light"),web_story.contains("-solo"))
    elif web_story.contains("mode=story-") or "--story-prologue" in OS.get_cmdline_user_args():
        start_story(web_story.contains("story-solo"))
    elif web_story.contains("mode=resume-journey-"):
        resume_story_entry(web_story.contains("resume-journey-solo"))
    elif web_story.contains("mode=journey-") or "--story-journey" in OS.get_cmdline_user_args():
        start_journey(web_story.contains("journey-solo") or "--solo-journey" in OS.get_cmdline_user_args())
    elif web_solo or "--solo-journey" in OS.get_cmdline_user_args():
        start_courtyard(true)
    elif "--solo-combat-preview" in OS.get_cmdline_user_args():
        start_solo_combat()
    elif "--combat-preview" in OS.get_cmdline_user_args():
        leave_solo()
        preview_run = true
        enter_combat()
        router.start_keyboard()
    elif "--light-preview" in OS.get_cmdline_user_args():
        leave_solo()
        preview_run = true
        enter_light()
        router.start_keyboard()
    elif "--gate-preview" in OS.get_cmdline_user_args():
        start_trial("gate",false)
        router.start_keyboard()
    elif "--rest-preview" in OS.get_cmdline_user_args():
        leave_solo()
        preview_run = true
        enter_rest()
        router.start_keyboard()

func _panel(rect: Rect2, color: Color, line: Color, radius: int = 20) -> Panel:
    var panel := Panel.new()
    panel.position = rect.position
    panel.size = rect.size
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = line
    style.set_border_width_all(1)
    style.set_corner_radius_all(radius)
    panel.add_theme_stylebox_override("panel", style)
    add_child(panel)
    return panel

func _label(text_value: String, rect: Rect2, font_size: int, color: Color = CREAM) -> Label:
    var label := Label.new()
    label.text = text_value
    label.position = rect.position
    label.size = rect.size
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    add_child(label)
    return label

func _button(text_value: String, rect: Rect2, action: Callable) -> Button:
    var button := Button.new()
    button.text = text_value
    button.position = rect.position
    button.size = rect.size
    button.focus_mode = Control.FOCUS_ALL
    var style := StyleBoxFlat.new()
    style.bg_color = Color("25483f")
    style.border_color = Color("527568")
    style.set_border_width_all(1)
    style.set_corner_radius_all(10)
    button.add_theme_stylebox_override("normal", style)
    var hover := style.duplicate()
    hover.bg_color = Color("386456")
    button.add_theme_stylebox_override("hover", hover)
    button.add_theme_stylebox_override("pressed", hover)
    var focus := style.duplicate()
    focus.bg_color = Color(0,0,0,0)
    focus.border_color = GOLD
    focus.set_border_width_all(3)
    button.add_theme_stylebox_override("focus",focus)
    button.add_theme_color_override("font_color", CREAM)
    button.pressed.connect(action)
    add_child(button)
    return button

func _build() -> void:
    _label("朵朵与猫猫", Rect2(38, 23, 320, 50), 30)
    _label("准备 / 暂停", Rect2(354, 31, 260, 40), 18, MUTE)
    top_status = _label("", Rect2(762, 29, 480, 44), 18, GOLD)
    top_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _panel(Rect2(34, 97, 563, 552), Color("16392e"), Color("426052"), 24)
    _label("一起把回家的路点亮", Rect2(63, 119, 510, 54), 33, CREAM)
    _label("一位朵朵，两只猫咪。", Rect2(65, 177, 220, 40), 18, MUTE)
    resume_button = _button("继续休息点", Rect2(431, 181, 130, 35), resume_checkpoint)
    resume_button.name = "ResumeCheckpoint"
    solo_resume_button = _button("继续单人", Rect2(292,181,130,35),func(): resume_journey(true))
    solo_resume_button.name = "ResumeSolo"
    _panel(Rect2(59, 234, 513, 133), Color.WHITE, Color("eadfc5"), 16)
    var team := TextureRect.new()
    team.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    team.texture = TEAM
    team.position = Vector2(65, 240)
    team.size = Vector2(501, 78)
    team.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    add_child(team)
    _button("章节：第二章",Rect2(68,326,184,38),func():
        selected_story_chapter = 2+(selected_story_chapter-1)%4
        get_node("ChapterSelect").text = "章节："+["第二章","第三章","第四章","第五章"][selected_story_chapter-2]
    ).name = "ChapterSelect"
    _button("单人进入",Rect2(266,326,140,38),func():start_story_chapter(selected_story_chapter,true)).name="LaterChapterSolo"
    _button("双人进入",Rect2(420,326,140,38),func():start_story_chapter(selected_story_chapter,false)).name="LaterChapterDual"
    _button("第一章 · 单人",Rect2(68,376,240,38),func(): start_chapter_one(true)).name = "ChapterOneSolo"
    _button("第一章 · 双人",Rect2(320,376,240,38),func(): start_chapter_one(false)).name = "ChapterOneDual"
    _button("序章 · 单人",Rect2(68,430,240,38),func(): start_story(true)).name = "StorySolo"
    _button("序章 · 双人",Rect2(320,430,240,38),func(): start_story(false)).name = "StoryDual"
    _button("双人战斗",Rect2(68,482,114,38),func(): start_preview("combat")).name = "CombatPreview"
    _button("双猫灯廊",Rect2(194,482,114,38),func(): start_preview("light")).name = "LightPreview"
    _button("林边休息",Rect2(320,482,114,38),func(): start_preview("rest")).name = "RestPreview"
    _button("单人战斗",Rect2(446,482,114,38),start_solo_combat).name = "SoloCombatPreview"
    _button("从头开始 · 单人",Rect2(68,530,240,43),func(): start_journey(true)).name = "SingleJourney"
    _button("从头开始 · 双人",Rect2(320,530,240,43),func(): start_journey(false)).name = "DualJourney"
    var keyboard_button := _button("键盘试玩 · Enter", Rect2(68, 586, 253, 43), func(): router.start_keyboard())
    keyboard_button.name = "KeyboardPlay"
    var pads := _button("切回双手柄", Rect2(340, 586, 220, 43), func(): router.use_gamepads())
    pads.name = "GamepadMode"
    _build_slot(0, 97, "朵朵", "认真冒险，也认真休息。", Color("79c4b0"))
    _build_slot(1, 383, "猫咪伙伴", "团团与圆圆，共用一个玩家位置。", GOLD)
    _panel(Rect2(34, 671, 1212, 95), Color("1a342b"), Color("456153"), 16)
    footer_status = _label("", Rect2(58, 684, 900, 35), 23, GOLD)
    mode_help = _label("", Rect2(59, 724, 900, 28), 16, MUTE)
    var replay := _button("重玩庭院", Rect2(979, 692, 141, 46), func():
        router.clear_keyboard()
        if stage in ["story-chapter","story-combat"]:
            story_chapter.reset(story_chapter.state.chapter,session.single_player,false)
            arena.cancel_inputs()
            stage = "story-chapter"
            session.pause_all("本章已重置 · 准备后继续")
        elif stage in ["chapter-one","chapter-combat"]:
            chapter_one.reset(session.single_player,false)
            arena.cancel_inputs()
            stage = "chapter-one"
            session.pause_all("第一章已重置 · 准备后继续")
        elif stage == "prologue":
            prologue.reset(session.single_player,false)
            session.pause_all("序章已重置 · Enter 或手柄准备后继续")
        elif stage == "rest":
            restart_journey()
        elif stage == "light":
            light_corridor.restart()
            session.pause_all("双猫灯廊已重置 · Enter 或双手柄准备")
        elif stage == "gate":
            chime_gate.restart()
            session.pause_all("风铃门已重置 · Enter 或手柄准备")
        elif stage == "combat":
            arena.restart()
            arena.allow_next_level = not preview_run or not session.single_player
            session.pause_all("林间空地已重置 · Enter 或双手柄准备")
        else:
            courtyard.restart()
    )
    replay.name = "ReplayCourtyard"
    _button("返回" if OS.has_feature("web") else "退出", Rect2(1135, 692, 82, 46), exit_game).name = "ExitGame"
    for id in ["StorySolo","StoryDual","ChapterOneSolo","ChapterOneDual","ChapterSelect","LaterChapterSolo","LaterChapterDual","SingleJourney","DualJourney","ResumeSolo","ResumeCheckpoint","SoloCombatPreview","CombatPreview","LightPreview","RestPreview","ReplayCourtyard","KeyboardPlay","GamepadMode","ExitGame"]:
        menu_controls.append(get_node(id))

func _build_slot(slot: int, y: float, title: String, detail: String, tint: Color) -> void:
    _panel(Rect2(621, y, 625, 266), Color("152c25"), Color("476052"), 20)
    slot_badges.append(_label("P%d" % [slot + 1], Rect2(645, y + 18, 70, 40), 26, tint))
    slot_titles.append(_label(title, Rect2(712, y + 16, 330, 44), 28))
    slot_details.append(_label(detail, Rect2(647, y + 61, 560, 28), 17, MUTE))
    devices_text.append(_label("", Rect2(647, y + 98, 557, 28), 17, MUTE))
    ready_text.append(_label("", Rect2(647, y + 129, 470, 34), 22, tint))
    action_text.append(_label("", Rect2(647, y + 176, 410, 31), 18, CREAM))
    vector_text.append(_label("", Rect2(647, y + 211, 415, 28), 16, MUTE))
    var stick := Stick.new()
    stick.position = Vector2(1146, y + 153)
    stick.size = Vector2(78, 78)
    stick.tint = tint
    add_child(stick)
    sticks.append(stick)
    claim_buttons.append(_button("重新认领", Rect2(1111, y + 24, 112, 38), func():
        session.release_slot(slot)
        last_buttons[slot] = -1
    ))

func _input(event: InputEvent) -> void:
    if journal!=null:
        var toggle:bool=event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode if event.physical_keycode else event.keycode) in ([KEY_H,KEY_ESCAPE,KEY_ENTER] if journal.active else [KEY_H])
        toggle=toggle or (event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_BACK)
        if toggle and session.focused and (journal.active or journal_button.visible):
            if journal.active:close_journal()
            else:open_journal()
            get_viewport().set_input_as_handled();return
        if journal.active:
            if session.focused:journal.handle_input(event)
            get_viewport().set_input_as_handled();return
    if _menu_input(event):
        get_viewport().set_input_as_handled()
        return
    router.handle(event)
    if not session.running() and is_instance_valid(arena):
        arena.cancel_inputs()
    if event is InputEventKey and session.keyboard_mode:
        get_viewport().set_input_as_handled()

func open_journal()->void:
    if journal.active or stage not in ["prologue","chapter-one","chapter-combat","story-chapter","story-combat"]:return
    var source=prologue.state if stage=="prologue" else chapter_one.state if stage in ["chapter-one","chapter-combat"] else story_chapter.state
    journal_ready=session.ready_flags.duplicate();journal_devices=session.devices.duplicate();journal_keyboard=session.keyboard_mode
    router.clear_keyboard();session.pause_all("旅途记事 · 回看已经出现的对话和观察")
    journal.open(source.history,source.message)
func journal_hint()->void:
    if not journal.active or not session.focused or stage in ["chapter-combat","story-combat"]:return
    var source=prologue.state if stage=="prologue" else chapter_one.state if stage=="chapter-one" else story_chapter.state
    source.request_hint();journal.open(source.history,source.message)
func close_journal()->void:
    journal.close();router.clear_keyboard()
    if session.focused and session.devices==journal_devices and session.keyboard_mode==journal_keyboard:session.ready_flags.assign(journal_ready)

func _action(slot: int, button: int) -> void:
    last_buttons[slot] = button
    if stage == "story-chapter":
        story_chapter.handle_action(slot,button)
    elif stage == "chapter-one":
        chapter_one.handle_action(slot,button)
    elif stage == "prologue":
        prologue.handle_action(slot,button)
    elif stage == "rest":
        rest_area.handle_action(slot, button)
    elif stage == "light":
        light_corridor.handle_action(slot, button)
    elif stage == "gate":
        chime_gate.handle_action(slot, button)
    elif stage in ["combat","chapter-combat","story-combat"]:
        arena.handle_action(slot, button)
    else:
        courtyard.handle_action(slot, button)

func enter_combat() -> void:
    arena.story_title="";arena.story_destination=""
    if arena.battle.solo_mode != session.single_player: arena.configure_solo(session.single_player)
    arena.allow_next_level = not preview_run or not session.single_player
    router.clear_keyboard()
    if stage == "bridge":
        arena.battle.current_cat = courtyard.party.current_cat
    stage = "combat"
    courtyard.set_active(false)
    light_corridor.set_active(false)
    rest_area.set_active(false)
    arena.set_active(session.running())

func enter_light() -> void:
    light_corridor.puzzle.solo_mode = session.single_player
    router.clear_keyboard()
    if stage != "light":
        light_corridor.puzzle.current_cat = arena.battle.current_cat if stage == "combat" else courtyard.party.current_cat
        light_corridor.puzzle.hp = arena.battle.hp.duplicate()
    stage = "light"
    courtyard.set_active(false)
    arena.set_active(false)
    rest_area.set_active(false)
    light_corridor.set_active(session.running())

func _show_rest() -> void:
    router.clear_keyboard()
    stage = "rest"
    courtyard.set_active(false)
    arena.set_active(false)
    light_corridor.set_active(false)
    chime_gate.set_active(false)
    rest_area.set_active(session.running())

func enter_gate() -> void:
    router.clear_keyboard()
    chime_gate.puzzle.solo_mode = session.single_player
    if stage == "light":
        chime_gate.puzzle.hp = light_corridor.puzzle.hp.duplicate()
        chime_gate.puzzle.current_cat = light_corridor.puzzle.current_cat
    stage = "gate"
    courtyard.set_active(false)
    arena.set_active(false)
    light_corridor.set_active(false)
    rest_area.set_active(false)
    chime_gate.set_active(session.running())

func enter_rest() -> void:
    if stage != "rest":
        rest_area.state = rest_area.Rest.new()
        rest_area.state.solo_mode = session.single_player
        rest_area.selection = rest_area.Selection.new()
        rest_area.state.progress = {"bridge":courtyard.bridge.finished,"combat":arena.battle.phase == "complete","light":light_corridor.puzzle.finished,"gate":chime_gate.puzzle.finished}
        rest_area.state.current_cat = chime_gate.puzzle.current_cat if stage == "gate" else light_corridor.puzzle.current_cat if stage == "light" else arena.battle.current_cat
        rest_area.state.hp = chime_gate.puzzle.hp.duplicate() if stage == "gate" else light_corridor.puzzle.hp.duplicate() if stage == "light" else arena.battle.hp.duplicate()
        rest_area.reported = false
        rest_area.can_save = stage == "gate" and chime_gate.puzzle.finished and light_corridor.puzzle.finished and not preview_run
        rest_area.save_status = "坐下休息后记录安全点" if rest_area.can_save else "单独试玩 · 不覆盖上次旅程"
    if preview_run:
        rest_area.can_save = false
        rest_area.save_status = "单独试玩 · 不覆盖上次旅程"
    _show_rest()

func _save_checkpoint() -> void:
    var store = solo_checkpoint if session.single_player else checkpoint
    if store.save_checkpoint(rest_area.state.record()):
        rest_area.save_status = "安全点已保存 · 下次可继续"
    else:
        rest_area.save_status = "安全点未保存 · 本次可继续"
        rest_area.state.message = store.last_error
    _refresh_checkpoint_button()

func _refresh_checkpoint_button() -> void:
    var story_dual:Dictionary=story_progress.read(false)
    var story_solo:Dictionary=story_progress.read(true)
    var data: Dictionary = checkpoint.read_checkpoint()
    resume_button.disabled = data.is_empty() and story_dual.is_empty()
    resume_button.text = "继续双人故事" if not story_dual.is_empty() else "暂无双人记录" if data.is_empty() else "继续双人庭院"
    var solo_data: Dictionary = solo_checkpoint.read_checkpoint()
    solo_resume_button.disabled = solo_data.is_empty() and story_solo.is_empty()
    solo_resume_button.text = "继续单人故事" if not story_solo.is_empty() else "暂无单人记录" if solo_data.is_empty() else "继续单人庭院"
    solo_resume_button.tooltip_text = solo_checkpoint.last_error
    resume_button.tooltip_text = checkpoint.last_error
    if story_route_active and not story_manifest_error.is_empty():
        var affected:Button=solo_resume_button if session.single_player else resume_button
        affected.disabled=true;affected.tooltip_text=story_manifest_error+" 当前冒险可按 Enter 继续，位置写入后这里恢复可用。"

func resume_checkpoint() -> void:
    resume_journey(false)

func resume_story_entry(single:bool)->void:
    if story_progress.read(single).is_empty():
        start_journey(single)
        prologue.state.say("这一人数还没有旅程记录。我们从家中的下午开始吧。")
    else:resume_journey(single)

func resume_journey(single: bool) -> void:
    if session.running():return
    if story_route_active and session.single_player==single and not story_manifest_error.is_empty():
        save_story_location(story_pending_chapter)
        if not story_manifest_error.is_empty():return
    var value:Dictionary=story_progress.read(single)
    if value.is_empty():resume_courtyard(single);return
    story_route_active=true;story_run_id=value.run_id;apply_story_prefix()
    match int(value.chapter):
        0:start_story(single,true)
        1:start_chapter_one(single,true)
        _:start_story_chapter(int(value.chapter),single,true)
func resume_courtyard(single: bool) -> void:
    detach_story_run()
    var store = solo_checkpoint if single else checkpoint
    var data: Dictionary = store.read_checkpoint()
    if data.is_empty():
        _refresh_checkpoint_button()
        return
    router.clear_keyboard()
    session.pause_all("正在恢复休息点")
    session.single_player = single
    if single: session.devices[1] = -1
    rest_area.restore(data)
    preview_run = false
    _show_rest()
    if session.keyboard_mode or session.devices == [-1,-1]:
        router.start_keyboard()
    else:
        session.pause_all("已回到休息点 · 两位准备后继续")

func restart_journey() -> void:
    router.clear_keyboard()
    session.pause_all("重新开始庭院")
    preview_run = false
    courtyard.restart()
    arena.restart()
    arena.allow_next_level = true
    light_corridor.restart()
    chime_gate.restart()
    chime_gate.set_active(false)
    light_corridor.puzzle.hp[0] = 3
    light_corridor.puzzle.hp[1] = 3
    rest_area.state = rest_area.Rest.new()
    rest_area.state.solo_mode = session.single_player
    rest_area.selection = rest_area.Selection.new()
    rest_area.reported = false
    rest_area.can_save = false
    rest_area.set_active(false)
    stage = "bridge"
    session.pause_all("已回到庭院入口 · Enter 或双方准备开始")

func _connection_changed(device: int, connected: bool) -> void:
    if not connected:
        var slot: int = session.slot_of(device)
        session.disconnect_device(device)
        arena.cancel_inputs()
        if slot >= 0:
            last_buttons[slot] = -1

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        router.clear_keyboard()
        session.set_focus(false)
    elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
        session.set_focus(true)

func _process(_delta: float) -> void:
    if not is_instance_valid(top_status):
        return
    if story_route_active and not story_manifest_error.is_empty():
        story_manifest_retry+=_delta
        if story_manifest_retry>=1.0:save_story_location(story_pending_chapter)
    story_save_notice.visible=story_route_active and not story_manifest_error.is_empty()
    story_save_notice.text="旅程位置未保存 · 当前冒险可继续；退出后暂时只能恢复旧记录。正在重试。" if story_save_notice.visible else ""
    if OS.has_feature("web") and OS.is_debug_build():
        web_probe_clock += _delta
        if web_probe_clock >= 0.1:
            web_probe_clock = 0
            var current = story_chapter.state if stage == "story-chapter" else chapter_one.state if stage == "chapter-one" else prologue.state if stage == "prologue" else courtyard.party if stage == "bridge" else (arena.battle if stage in ["combat","chapter-combat","story-combat"] else (light_corridor.puzzle if stage == "light" else (chime_gate.puzzle if stage == "gate" else rest_area.state)))
            var points: Array = []
            for point in current.positions: points.append([point.x,point.y])
            var report := {"stage":stage,"running":session.running(),"solo":session.single_player,"positions":points,"cat":1 if stage in ["prologue","chapter-one"] else current.current_cat,"bridge_locks":courtyard.bridge.unlocked,"bridge_done":courtyard.bridge.finished,"phase":arena.battle.phase,"wave":arena.battle.wave,"hp":arena.battle.hp,"persistent":OS.is_userfs_persistent(),"rested":rest_area.state.rested,"finished":rest_area.state.finished,"can_save":rest_area.can_save,"solo_saved":not solo_checkpoint.read_checkpoint().is_empty(),"dual_saved":not checkpoint.read_checkpoint().is_empty()}
            report["focused"]=session.focused;report["journal_open"]=journal.active
            report["story_run_id"]=story_run_id;report["story_route_active"]=story_route_active
            if stage in ["prologue","chapter-one","story-chapter"]:
                var view=prologue if stage=="prologue" else chapter_one if stage=="chapter-one" else story_chapter
                report["story_checkpoint"]=current.checkpoint()
                report["objective"]=current.objective();report["message"]=current.message
                report["save_status"]=view.save_status;report["recorded"]=view.recorded
            if stage in ["combat","chapter-combat","story-combat"]:
                report["human"] = arena.solo.human_slot
                report["enemies"] = arena.battle.enemies
            if stage == "light":
                report["light_phase"] = light_corridor.puzzle.phase
                report["beam"] = [light_corridor.puzzle.beam.x,light_corridor.puzzle.beam.y]
                report["operator"] = light_corridor.puzzle.operator_slot
                report["recoveries"] = light_corridor.puzzle.recoveries
            if stage == "gate":
                report["mirrors"] = chime_gate.puzzle.mirrors
                report["lens"] = chime_gate.puzzle.lens_site
                report["bells"] = chime_gate.puzzle.receivers
                report["gate_open"] = chime_gate.puzzle.finished
            JavaScriptBridge.eval("window.duoduoStatus = " + JSON.stringify(report),true)
    var playing: bool = session.running()
    journal_button.visible=stage in ["prologue","chapter-one","chapter-combat","story-chapter","story-combat"]
    if playing: music_started = true
    if not music_started: music.set_context("home")
    elif playing:
        if stage == "story-chapter": music.set_context("home" if story_chapter.state.phase in ["home","complete"] and story_chapter.state.chapter==5 else "rest" if story_chapter.state.finished else "boss" if story_chapter.state.chapter==5 and story_chapter.state.phase in ["shield","lure","unjam","withdraw"] else "puzzle")
        elif stage == "chapter-one": music.set_context("rest" if chapter_one.state.lit else "puzzle" if chapter_one.state.phase == "station" else "explore")
        else: music.set_context(music.context_for("combat" if stage in ["chapter-combat","story-combat"] else stage,arena.battle.phase,arena.battle.wave))
    if playing and stage in ["combat","chapter-combat","story-combat"]:
        if arena.battle.feedback_id < music_feedback_cursor: music_feedback_cursor = 0
        for event in arena.battle.feedback_since(music_feedback_cursor):
            if event.kind in ["hit","heavy","hurt","parry","danger","plant_burst"]: music.duck(0.18)
        music_feedback_cursor = arena.battle.feedback_id
    music.set_paused(not session.focused or (music_started and not playing))
    for child in get_children():
        if child is CanvasItem and child != story_chapter and child != chapter_one and child != prologue and child != courtyard and child != arena and child != light_corridor and child != chime_gate and child != rest_area:
            child.visible = not playing
    if story_chapter.active != (playing and stage == "story-chapter"):
        story_chapter.set_active(playing and stage == "story-chapter")
    if chapter_one.active != (playing and stage == "chapter-one"):
        chapter_one.set_active(playing and stage == "chapter-one")
    if prologue.active != (playing and stage == "prologue"):
        prologue.set_active(playing and stage == "prologue")
    if courtyard.active != (playing and stage == "bridge"):
        courtyard.set_active(playing and stage == "bridge")
    if arena.active != (playing and stage in ["combat","chapter-combat","story-combat"]):
        arena.set_active(playing and stage in ["combat","chapter-combat","story-combat"])
    if light_corridor.active != (playing and stage == "light"):
        light_corridor.set_active(playing and stage == "light")
    if chime_gate.active != (playing and stage == "gate"):
        chime_gate.set_active(playing and stage == "gate")
    if rest_area.active != (playing and stage == "rest"):
        rest_area.set_active(playing and stage == "rest")
    get_node("ReplayCourtyard").text = "重走庭院" if stage == "rest" else ("重玩庭院" if stage == "bridge" else "重玩本关")
    top_status.text = "键盘试玩" if session.keyboard_mode else "检测到 %d 只手柄" % Input.get_connected_joypads().size()
    footer_status.text = "双人输入已启用 · 试试两边的摇杆与按钮" if session.running() else session.pause_reason
    mode_help.text = "WASD / E：朵朵  ·  方向键 / 空格：猫咪  ·  Enter 继续" if session.keyboard_mode else "十字键选菜单，面键下选择；菜单键加入 / 准备。无手柄可按 Enter。"
    if not playing and not session.keyboard_mode and session.devices == [-1, -1]:
        footer_status.text = "按 Enter 开始键盘试玩，或接入两只手柄"
    get_node("GamepadMode").text = "切回单手柄" if session.single_player else "切回双手柄"
    for slot in range(2):
        slot_titles[slot].text = (["玩家控制","AI 伙伴"][slot] if session.single_player else ["朵朵","猫咪伙伴"][slot])
        slot_details[slot].text = (["一套按键切换朵朵、团团与圆圆。","协助战斗；机关解谜由玩家操作。"][slot] if session.single_player else ["认真冒险，也认真休息。","团团与圆圆，共用一个玩家位置。"][slot])
        var device: int = session.devices[slot]
        claim_buttons[slot].disabled = session.keyboard_mode
        claim_buttons[slot].text = "键盘模式" if session.keyboard_mode else "重新认领"
        if session.keyboard_mode:
            devices_text[slot].text = "WASD 移动 · E 互动" if slot == 0 else "方向键移动 · 空格互动 · Tab 切猫 · R 驻守"
            ready_text[slot].text = "键盘已就绪" if playing else "按 Enter 继续"
        elif device < 0:
            devices_text[slot].text = "未认领 · 接上手柄后按菜单键"
            ready_text[slot].text = "等待加入"
        else:
            var device_name := Input.get_joy_name(device)
            devices_text[slot].text = "设备 %d · %s" % [device, device_name if not device_name.is_empty() else "已认领设备"]
            ready_text[slot].text = "已准备  ✓" if session.ready_flags[slot] else "已加入 · 按菜单键准备"
        var movement: Vector2 = session.movement(slot)
        sticks[slot].set_value(movement)
        vector_text[slot].text = "摇杆   X %+.2f    Y %+.2f" % [movement.x, movement.y]
        if not session.running():
            action_text[slot].text = "按 Enter 开始／继续" if session.keyboard_mode else ("按菜单键准备后启用输入" if session.single_player else "双方准备后启用输入")
        elif last_buttons[slot] < 0:
            action_text[slot].text = "按下按钮，查看接收结果"
        else:
            action_text[slot].text = "已收到按钮 %d" % last_buttons[slot]
        slot_badges[slot].text = ("AI" if stage == "combat" else "伴") if session.single_player and slot == 1 else "P%d" % (slot+1)
    if session.single_player:
        top_status.text = ("单人战斗试玩" if preview_run else "单人完整庭院") + ""
        footer_status.text = "单人键盘 · Enter 开始 / 继续" if session.keyboard_mode else "单手柄 · 十字键选菜单 / 下确认 · 菜单键准备 / 继续"
        if not session.focused: footer_status.text = "返回游戏窗口后继续"
        mode_help.text = "WASD 移动 · E 互动 · Tab 换角色；战斗 F 攻击 / Q 闪避，解谜 R 工具 / Q 切回。"
        devices_text[0].text = "单人键盘 · WASD / F / Q / E / Tab" if session.keyboard_mode else devices_text[0].text
        devices_text[1].text = "无需第二只手柄"
        slot_titles[1].text = "AI 伙伴" if stage == "combat" else "伙伴分工"
        ready_text[1].text = "另一位角色由 AI 协助" if stage == "combat" else "解谜时由你切换三位角色"
        action_text[1].text = "接应、掩护和安全救援" if stage == "combat" else "战斗阶段会有 AI 协助"
        vector_text[1].text = "机关解谜由玩家亲自完成"
        claim_buttons[1].visible = false
        sticks[1].visible = false
    if stage in ["story-chapter","story-combat"]:
        top_status.text = story_chapter.state.title
        slot_details[0].text = "已进入主线章节 · 单人手动解谜，战斗由 AI 协助。"
        slot_details[1].text = "双猫已经入队。" if story_chapter.state.joined else "圆圆尚未入队。"
        ready_text[1].text = "另一位由 AI 协助战斗" if stage=="story-combat" else "解谜由你手动切角色" if session.single_player else ready_text[1].text
    if stage in ["chapter-one","chapter-combat"]:
        top_status.text = "第一章 · 点亮第一盏灯"
        slot_details[0].text = "朵朵与团团，一起寻找圆圆的去向。"
        slot_details[1].text = "圆圆尚未入队；单人战斗有 AI 协助。"
        if session.single_player and stage == "chapter-one": ready_text[1].text = "解谜由你切换朵朵 / 团团"
    if stage == "prologue":
        top_status.text = "序章 · 家中的下午"
        get_node("ReplayCourtyard").text = "重玩序章"
        slot_details[0].text = "在朵朵与团团之间切换，一起去接圆圆。" if session.single_player else "在家里逛逛，留意猫咪和物件的反应。"
        slot_details[1].text = "圆圆本章自由活动，暂不可操作。"
        if session.keyboard_mode:
            devices_text[0].text = "WASD 移动 · E 互动"+(" · Tab 换角色" if session.single_player else "")
            if not session.single_player: devices_text[1].text = "方向键移动 · 空格互动"
        if session.single_player:
            mode_help.text = "WASD 移动 · E 互动 · Tab 换朵朵 / 团团。" if session.keyboard_mode else "左摇杆移动 · 面键下互动 · 面键上换朵朵 / 团团。"
            ready_text[1].text = "关键互动由你切换角色完成"
            action_text[1].text = "摸猫、玩球、观察和尝试。"


func start_story(single: bool, continuation:=false) -> void:
    if session.running(): return
    router.clear_keyboard()
    if not continuation:detach_story_run()
    session.pause_all("序章 · 准备出发")
    session.single_player = single
    if single: session.devices[1] = -1
    preview_run = false
    prologue.reset(single,true)
    stage = "prologue"
    save_story_location(0)
    courtyard.set_active(false)
    arena.set_active(false)
    light_corridor.set_active(false)
    rest_area.set_active(false)
    if session.keyboard_mode or session.devices[0] < 0: router.start_keyboard()

func start_solo_combat() -> void:
    if session.running(): return
    router.clear_keyboard()
    session.pause_all("单人战斗 · 一只手柄加入后准备，或按 Enter")
    session.single_player = true
    session.devices[1] = -1
    preview_run = true
    arena.configure_solo(true)
    stage = "combat"
    courtyard.set_active(false)
    light_corridor.set_active(false)
    rest_area.set_active(false)
    if session.keyboard_mode or session.devices[0] < 0: router.start_keyboard()

func start_trial(target: String, single: bool) -> void:
    if session.running() or target not in ["combat","light","gate"]: return
    if target == "combat" and single:
        start_solo_combat()
        return
    start_preview(target)
    if target in ["light","gate"] and single:
        session.single_player = true
        session.devices[1] = -1
        session.ready_flags[1] = false
        light_corridor.puzzle.solo_mode = true
        light_corridor.selection = light_corridor.Selection.new()
        light_corridor._refresh()
        chime_gate.puzzle.solo_mode = true
        chime_gate.selection = chime_gate.Selection.new()
        chime_gate._refresh()

func leave_solo() -> void:
    if not session.single_player: return
    router.clear_keyboard()
    session.single_player = false
    session.pause_all("已回到双人模式 · Enter 或双方准备")
    arena.configure_solo(false)

func detach_story_run()->void:
    if story_route_active:
        prologue.record_prefix="story-prologue-v2"
        chapter_one.record_prefix="story-chapter-one"
        story_chapter.record_prefix="story"
    story_route_active=false;story_run_id=""
    story_manifest_error="";story_manifest_retry=0.0
func apply_story_prefix()->void:
    prologue.record_prefix=story_run_id+"-prologue"
    chapter_one.record_prefix=story_run_id+"-one"
    story_chapter.record_prefix=story_run_id+"-later"
func save_story_location(chapter:int)->void:
    if story_route_active:
        story_pending_chapter=chapter;story_manifest_retry=0.0
        var wrote:bool=story_progress.save(session.single_player,story_run_id,chapter)
        var actual:Dictionary=story_progress.read(session.single_player) if wrote else {}
        if wrote and actual.get("run_id")==story_run_id and actual.get("chapter")==chapter:
            story_manifest_error=""
        else:story_manifest_error="旅程位置未保存，继续入口尚未更新。"
        _refresh_checkpoint_button()
func start_journey(single: bool) -> void:
    if session.running():return
    story_run_id="story-run-"+str(int(Time.get_unix_time_from_system()*1000))+"-"+str(Time.get_ticks_usec())
    story_route_active=true;apply_story_prefix()
    start_story(single,true)
func start_courtyard(single: bool) -> void:
    if session.running(): return
    session.single_player = single
    if single: session.devices[1] = -1
    detach_story_run()
    restart_journey()
    if session.keyboard_mode or session.devices[0] < 0:
        router.start_keyboard()
    else:
        session.pause_all("单人庭院 · 菜单键准备" if single else "双人庭院 · 两位按菜单键准备")

func _menu_input(event: InputEvent) -> bool:
    if session.running() or not session.focused or not event is InputEventJoypadButton: return false
    if event.button_index not in [JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN,JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT,JOY_BUTTON_A]: return false
    if not event.pressed: return true
    if event.button_index == JOY_BUTTON_A:
        if menu_index < 0: menu_index = 0
        else:
            var chosen: Button = menu_controls[menu_index]
            if not chosen.disabled:
                if session.keyboard_mode: router.use_gamepads()
                if session.slot_of(event.device) < 0: session.claim(event.device)
                chosen.pressed.emit()
                if session.running(): chosen.release_focus()
                return true
    else:
        var offset := -1 if event.button_index in [JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_LEFT] else 1
        if menu_index < 0: menu_index = 0
        else:
            for i in range(menu_controls.size()):
                menu_index = posmod(menu_index+offset,menu_controls.size())
                if not menu_controls[menu_index].disabled: break
    menu_controls[menu_index].grab_focus()
    return true

func start_preview(target: String) -> void:
    if session.running(): return
    leave_solo()
    preview_run = true
    detach_story_run()
    match target:
        "gate":
            chime_gate.restart()
            chime_gate.puzzle.solo_mode = false
            enter_gate()
        "combat":
            arena.configure_solo(false)
            enter_combat()
        "light":
            light_corridor.restart()
            light_corridor.puzzle.solo_mode = false
            enter_light()
        "rest":
            rest_area.state = rest_area.Rest.new()
            rest_area.selection = rest_area.Selection.new()
            rest_area.reported = false
            rest_area.can_save = false
            rest_area.save_status = "单独试玩 · 不覆盖上次旅程"
            _show_rest()
    if session.keyboard_mode or session.devices == [-1,-1]: router.start_keyboard()

func exit_game() -> void:
    if OS.has_feature("web"):
        router.clear_keyboard()
        session.pause_all("已回到网页入口")
        JavaScriptBridge.eval("parent.postMessage({type:'duoduo-exit'}, location.origin)")
    else:
        get_tree().quit()

func start_chapter_one(single: bool, continuation:=false) -> void:
    if session.running(): return
    router.clear_keyboard()
    if not continuation:detach_story_run()
    session.pause_all("第一章 · 准备出发")
    session.single_player = single
    if single: session.devices[1] = -1
    preview_run = false
    chapter_one.reset(single,true)
    stage = "chapter-one"
    save_story_location(1)
    for scene in [prologue,courtyard,arena,light_corridor,chime_gate,rest_area]: scene.set_active(false)
    if session.keyboard_mode or session.devices[0] < 0: router.start_keyboard()

func enter_chapter_combat() -> void:
    router.clear_keyboard()
    arena.configure_solo(session.single_player)
    arena.story_title=""
    arena.battle.story_encounter = "first"
    arena.battle.wave_total = 2
    arena.battle.current_cat = 1
    arena.battle.positions[2] = Vector2(-4000,-4000)
    arena.battle.message = "荆棘缠住了小路。朵朵举盾开路，团团能扑断织藤花。准备好，按互动键出发。"
    arena.allow_next_level = true
    stage = "chapter-combat"
    chapter_one.set_active(false)
    arena.set_active(session.running())
    arena.actors[2].visible = false
    arena._refresh()

func start_story_chapter(chapter:int,single:bool,continuation:=false)->void:
    if session.running() or chapter<2 or chapter>5:return
    if not continuation:detach_story_run()
    router.clear_keyboard();session.pause_all("章节 · 准备出发")
    session.single_player=single
    if single:session.devices[1]=-1
    preview_run=false
    story_chapter.reset(chapter,single,true)
    stage="story-chapter"
    save_story_location(chapter)
    for scene in [chapter_one,prologue,courtyard,arena,light_corridor,chime_gate,rest_area]:scene.set_active(false)
    if session.keyboard_mode or session.devices[0]<0:router.start_keyboard()
func enter_story_combat()->void:
    router.clear_keyboard();arena.configure_solo(session.single_player)
    arena.battle.story_first=not story_chapter.state.joined
    arena.battle.story_encounter="first" if not story_chapter.state.joined else "reserve" if story_chapter.state.get("reserve_retained")==true else "shell"
    arena.battle.wave_total=story_chapter.state.battle_waves
    arena.battle.current_cat=story_chapter.state.current_cat
    if not story_chapter.state.joined:arena.battle.positions[2]=Vector2(-4000,-4000)
    arena.story_title=story_chapter.state.title+" · 荆棘阻路"
    arena.story_destination="小路清开了。按互动键，回到本章继续修复。"
    arena.battle.message="荆棘围住了维修通路。先看预兆，再用盾挡、扑断和绕后。"
    arena.allow_next_level=true
    stage="story-combat";story_chapter.set_active(false);arena.set_active(session.running());arena._refresh()
