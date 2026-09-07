extends Control

var value := Vector2.ZERO
var tint := Color("72c4b0")

func _draw() -> void:
    var center := size / 2.0
    draw_circle(center, 34, Color("213d36"))
    draw_arc(center, 34, 0, TAU, 48, Color("476157"), 1.5, true)
    draw_line(center - Vector2(34, 0), center + Vector2(34, 0), Color("476157"))
    draw_line(center - Vector2(0, 34), center + Vector2(0, 34), Color("476157"))
    draw_circle(center + value * 25, 8, tint)

func set_value(next: Vector2) -> void:
    if not value.is_equal_approx(next):
        value = next
        queue_redraw()
