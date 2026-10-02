extends Node2D
const Prop = preload("res://game/storybook_prop.gd")
var font: Font
var progress: Dictionary = {}
func _ready() -> void:
    var board := Prop.make(4,Vector2(300,260))
    board.show_behind_parent = true
    add_child(board)
func _draw() -> void:
    if not font: return
    draw_string(font,Vector2(-115,-196),"这次一起走过的路",HORIZONTAL_ALIGNMENT_CENTER,230,19,Color("584b32"))
    var keys := ["bridge","combat","light","gate"]
    var names := ["合作调桥","林间空地","双猫灯廊","风铃门"]
    for i in range(4):
        if i == 3 and not progress.has("gate"):
            draw_string(font,Vector2(-115,-164+i*29),"风铃门 · 旧版未记录",HORIZONTAL_ALIGNMENT_CENTER,230,17,Color("4f5e3e"))
            continue
        var done: bool = progress.get(keys[i],false)
        draw_string(font,Vector2(-115,-164+i*29),("✓ " if done else "○ ")+names[i]+(" 已完成" if done else " 未完成"),HORIZONTAL_ALIGNMENT_CENTER,230,17,Color("4f5e3e"))
