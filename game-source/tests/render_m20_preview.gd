extends SceneTree
## Frozen rendering fixtures only; no claim of a naturally played battle.
const Visual = preload("res://game/enemy_visual.gd")
var viewport: SubViewport
func _initialize() -> void:
    run.call_deferred()
func run() -> void:
    if DisplayServer.get_name() == "headless": quit(1); return
    viewport = SubViewport.new()
    viewport.size = Vector2i(960,720)
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var background := ColorRect.new()
    background.color = Color("253c32")
    background.size = Vector2(960,720)
    viewport.add_child(background)
    var font: Font = load("res://assets/fonts/CourtyardSans.ttf")
    for column in range(3):
        var label := Label.new()
        label.text = ["PREPARE","CONTACT","RECOVER"][column]
        label.position = Vector2(200+column*250,28)
        label.add_theme_font_override("font",font)
        label.add_theme_font_size_override("font_size",22)
        label.modulate = Color("f8e4b8")
        viewport.add_child(label)
    var kinds := ["sprout","weaver","elder"]
    var modes := [["melee_windup","melee","rest"],["cast","burst","rest"],["slam_windup","slam","rest"]]
    for row in range(3):
        var name_label := Label.new()
        name_label.text = kinds[row].to_upper()
        name_label.position = Vector2(18,175+row*195)
        name_label.add_theme_font_override("font",font)
        name_label.add_theme_font_size_override("font_size",17)
        viewport.add_child(name_label)
        for column in range(3):
            var point := Vector2(260+column*250,190+row*195)
            var enemy := {"kind":kinds[row],"pos":point,"direction":Vector2.RIGHT,"hp":5,"max_hp":5,
                "mode":modes[row][column],"timer":1,"flash":0.0,"bounce":0.0,
                "pose_mode":modes[row][column],"pose_duration":1.0,"pose_elapsed":[0.85,0.1,0.2][column]}
            var view = Visual.new()
            viewport.add_child(view)
            view.sync(enemy)
    for i in range(6): await process_frame
    await RenderingServer.frame_post_draw
    var path: String = OS.get_cmdline_user_args()[0]
    var result := viewport.get_texture().get_image().save_png(path)
    print("M20_POSE_PREVIEW: ",path," status=",result)
    quit(0 if result == OK else 1)
