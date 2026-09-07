extends Node2D
const Bridge = preload("res://game/bridge_state.gd")
var state
var font: Font
var highlight: int = -1

func _init(bridge) -> void:
    state = bridge

func _draw() -> void:
    draw_rect(Rect2(1040, 100, 360, 960), Color("3d737b"))
    for y in range(130, 1060, 55):
        for x in range(1070, 1390, 95):
            draw_arc(Vector2(x + (y % 3) * 12, y), 18, 0.2, PI - 0.2, 14, Color("71a4a1"), 2, true)
    draw_line(Vector2(1034, 100), Vector2(1034, 1060), Color("bcc59c"), 10)
    draw_line(Vector2(1406, 100), Vector2(1406, 1060), Color("bcc59c"), 10)
    if state.unlocked == 3:
        draw_rect(Rect2(1010, 568, 420, 144), Color("6a5740"))
        for x in range(1014, 1425, 22):
            draw_rect(Rect2(x, 573, 18, 134), Color("c8ad75"))
        for y in [568, 712]:
            draw_line(Vector2(1010, y), Vector2(1430, y), Color("e3cb94"), 7)
    else:
        for i in range(3):
            var rect := Rect2(1024 + i * 120, 600, 136, 80)
            if i < state.deployed:
                draw_rect(rect, Color("725d43"))
                for x in range(int(rect.position.x) + 4, int(rect.end.x) - 4, 19):
                    draw_rect(Rect2(x, 606, 15, 68), Color("c5a56b"))
                draw_line(rect.position, Vector2(rect.end.x, rect.position.y), Color("bfb68e"), 6)
                draw_line(Vector2(rect.position.x, rect.end.y), rect.end, Color("bfb68e"), 6)
            else:
                draw_rect(rect, Color(0.07, 0.2, 0.22, 0.22))
                draw_rect(rect, Color("91a59c"), false, 2)
            var lock: Vector2 = Bridge.LOCKS[i]
            var color := Color("9bca88") if i < state.unlocked else Color("e7c579")
            if i >= state.deployed:
                color = Color("718c8b")
            draw_line(lock + Vector2(0, -48), lock + Vector2(0, -28), color, 7)
            draw_circle(lock + Vector2(0, -52), 10, color)
            if highlight == i + 1:
                draw_arc(lock + Vector2(0, -52), 17, 0, TAU, 32, Color("fff3bd"), 3, true)
            if font:
                draw_string(font, lock + Vector2(-50, -130), "%d  %s" % [i + 1, "已解锁" if i < state.unlocked else "卡扣"], HORIZONTAL_ALIGNMENT_CENTER, 100, 16, Color("fff1cb"))
        # Entrance arch represents a low cat passage without changing character hitboxes.
        draw_line(Vector2(1028, 598), Vector2(1028, 680), Color("d0c79d"), 8)
        if font:
            draw_string(font, Vector2(1035, 731), "团团的低通道", HORIZONTAL_ALIGNMENT_CENTER, 190, 18, Color("fff0ce"))
    var winch: Vector2 = Bridge.WINCH
    draw_line(winch, Vector2(1040, 620), Color("d2b880"), 3)
    draw_rect(Rect2(winch + Vector2(-24, -9), Vector2(48, 26)), Color("7c6143"))
    draw_circle(winch + Vector2(0, -12), 25, Color("d3b87b"))
    draw_arc(winch + Vector2(0, -12), 19, 0, TAU, 32, Color("705c42"), 4, true)
    var angle: float = state.deployed * PI / 3.0
    var spoke := Vector2(cos(angle), sin(angle)) * 23
    draw_line(winch + Vector2(0, -12) - spoke, winch + Vector2(0, -12) + spoke, Color("705c42"), 5)
    if highlight == 0:
        draw_arc(winch + Vector2(0, -12), 32, 0, TAU, 36, Color("fff3bd"), 3, true)
    if font:
        draw_string(font, winch + Vector2(-80, -140), "朵朵的绞盘", HORIZONTAL_ALIGNMENT_CENTER, 160, 18, Color("fff0ce"))
    var exit_color := Color("dfd09a") if state.unlocked == 3 else Color("8ca47a")
    draw_circle(Bridge.EXIT, 84, Color(exit_color, 0.12))
    draw_arc(Bridge.EXIT, 80, 0, TAU, 64, exit_color, 3, true)
    if font:
        var caption := "过桥成功" if state.finished else "桥后集合"
        draw_string(font, Bridge.EXIT + Vector2(-80, -150), caption, HORIZONTAL_ALIGNMENT_CENTER, 160, 21, exit_color)
        for slot in range(2):
            var point := Bridge.EXIT + Vector2(-36 + slot * 72, 105)
            draw_circle(point, 7, Color("f6d98a") if state.confirmed[slot] else Color("506f50"))
            draw_string(font, point + Vector2(-22, 30), "P%d" % [slot + 1], HORIZONTAL_ALIGNMENT_CENTER, 44, 16, Color("fff0ce"))
