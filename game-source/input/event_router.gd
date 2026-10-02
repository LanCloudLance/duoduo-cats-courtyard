extends RefCounted
signal action_pressed(slot: int, button: int)
signal action_released(slot: int, button: int)
signal actions_cancelled
var session
var pressed_keys: Dictionary = {}

func _init(state) -> void:
    session = state

func handle(event: InputEvent) -> void:
    if not session.focused:
        clear_keyboard()
        return
    if event is InputEventKey:
        _key(event)
        return
    if session.keyboard_mode:
        return
    if event is InputEventJoypadButton:
        if event.button_index == JOY_BUTTON_START and event.pressed:
            session.menu(event.device)
        elif session.running():
            var slot: int = session.slot_of(event.device)
            if slot >= 0:
                if event.pressed:
                    if session.single_player and event.button_index == JOY_BUTTON_Y:
                        session.axes[0] = Vector2.ZERO
                        actions_cancelled.emit()
                    action_pressed.emit(slot, event.button_index)
                else:
                    action_released.emit(slot, event.button_index)
    elif event is InputEventJoypadMotion:
        session.set_axis(event.device, event.axis, event.axis_value)

func clear_keyboard() -> void:
    pressed_keys.clear()
    actions_cancelled.emit()
    action_released.emit(0, JOY_BUTTON_LEFT_SHOULDER)
    if session.keyboard_mode:
        session.axes[0] = Vector2.ZERO
        session.axes[1] = Vector2.ZERO

func start_keyboard() -> void:
    if not session.focused:
        return
    clear_keyboard()
    session.keyboard_mode = true
    session.pause_all("键盘试玩 · Esc 暂停，Enter 继续")
    session.ready_flags[0] = true
    session.ready_flags[1] = not session.single_player

func use_gamepads() -> void:
    clear_keyboard()
    session.keyboard_mode = false
    session.pause_all("已切换手柄 · 请两位加入并准备")

func _key(event: InputEventKey) -> void:
    var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
    if not event.pressed:
        if code == KEY_G and pressed_keys.has(code):
            action_released.emit(0, JOY_BUTTON_LEFT_SHOULDER)
        if code == KEY_F and pressed_keys.has(code) and session.single_player and session.running():
            action_released.emit(0,JOY_BUTTON_X)
        if code == KEY_J and pressed_keys.has(code) and session.keyboard_mode and session.running():
            action_released.emit(1, JOY_BUTTON_X)
        pressed_keys.erase(code)
        _update_keyboard_axes()
        return
    if event.echo or pressed_keys.has(code) or event.ctrl_pressed or event.meta_pressed or event.alt_pressed:
        return
    if code == KEY_ENTER or code == KEY_KP_ENTER:
        if not session.running():
            start_keyboard()
        return
    if not session.keyboard_mode:
        return
    if code == KEY_ESCAPE:
        clear_keyboard()
        session.pause_all("已暂停 · 按 Enter 继续键盘试玩")
        return
    if not session.running():
        return
    if session.single_player and code in [KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT,KEY_J,KEY_K,KEY_SPACE]: return
    if session.single_player and code == KEY_TAB:
        clear_keyboard()
        action_pressed.emit(0,JOY_BUTTON_Y)
        return
    pressed_keys[code] = true
    _update_keyboard_axes()
    match code:
        KEY_E: action_pressed.emit(0, JOY_BUTTON_A)
        KEY_SPACE: action_pressed.emit(1, JOY_BUTTON_A)
        KEY_TAB: action_pressed.emit(1, JOY_BUTTON_Y)
        KEY_R: action_pressed.emit(0 if session.single_player else 1, JOY_BUTTON_RIGHT_SHOULDER)
        KEY_T: action_pressed.emit(0, JOY_BUTTON_RIGHT_SHOULDER)
        KEY_F: action_pressed.emit(0, JOY_BUTTON_X)
        KEY_Q: action_pressed.emit(0, JOY_BUTTON_B)
        KEY_G: action_pressed.emit(0, JOY_BUTTON_LEFT_SHOULDER)
        KEY_J: action_pressed.emit(1, JOY_BUTTON_X)
        KEY_K: action_pressed.emit(1, JOY_BUTTON_B)

func _update_keyboard_axes() -> void:
    if not session.keyboard_mode or not session.running():
        return
    session.axes[0] = Vector2(int(pressed_keys.has(KEY_D)) - int(pressed_keys.has(KEY_A)), int(pressed_keys.has(KEY_S)) - int(pressed_keys.has(KEY_W))).limit_length()
    session.axes[1] = Vector2(int(pressed_keys.has(KEY_RIGHT)) - int(pressed_keys.has(KEY_LEFT)), int(pressed_keys.has(KEY_DOWN)) - int(pressed_keys.has(KEY_UP))).limit_length()
