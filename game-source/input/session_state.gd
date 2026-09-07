extends RefCounted

var devices: Array[int] = [-1, -1]
var ready_flags: Array[bool] = [false, false]
var pause_reason: String = "等待两位加入"
var focused: bool = true
var keyboard_mode: bool = false
var single_player := false
var axes: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]

func slot_of(device: int) -> int:
    return -1 if device < 0 else devices.find(device)

func claim(device: int) -> int:
    if device < 0 or not focused:
        return -1
    var existing := slot_of(device)
    if existing >= 0:
        return existing
    if single_player and devices[0] >= 0: return -1
    var empty := devices.find(-1)
    if empty >= 0:
        devices[empty] = device
        pause_all("请两位按菜单键准备")
    return empty

func running() -> bool:
    if single_player:
        return focused and ready_flags[0] and (keyboard_mode or devices[0] >= 0)
    return focused and ready_flags[0] and ready_flags[1] and (keyboard_mode or (devices[0] >= 0 and devices[1] >= 0))

func menu(device: int) -> void:
    if not focused:
        return
    var slot := slot_of(device)
    if slot < 0:
        claim(device)
    elif running():
        pause_all("已暂停 · 请双方重新准备")
    else:
        ready_flags[slot] = not ready_flags[slot]
        if running():
            pause_reason = "输入已启用"

func pause_all(reason: String = "已暂停") -> void:
    ready_flags = [false, false]
    axes = [Vector2.ZERO, Vector2.ZERO]
    pause_reason = reason

func disconnect_device(device: int) -> void:
    var slot := slot_of(device)
    if slot >= 0:
        devices[slot] = -1
        if not keyboard_mode:
            pause_all("手柄断开 · 请重新认领")

func set_focus(value: bool) -> void:
    focused = value
    if not value:
        pause_all("已切出窗口 · 返回后请重新准备")

func set_axis(device: int, axis: int, value: float) -> void:
    var slot := slot_of(device)
    if keyboard_mode or slot < 0 or not running() or not is_finite(value):
        return
    if axis == JOY_AXIS_LEFT_X:
        axes[slot].x = clampf(value, -1.0, 1.0)
    elif axis == JOY_AXIS_LEFT_Y:
        axes[slot].y = clampf(value, -1.0, 1.0)

func movement(slot: int) -> Vector2:
    if slot < 0 or slot > 1 or not running():
        return Vector2.ZERO
    var value := axes[slot]
    var strength := minf(value.length(), 1.0)
    if strength <= 0.2:
        return Vector2.ZERO
    return value.normalized() * ((strength - 0.2) / 0.8)

func release_slot(slot: int) -> void:
    if slot >= 0 and slot <= 1:
        devices[slot] = -1
        pause_all("位置已释放 · 请重新加入")
