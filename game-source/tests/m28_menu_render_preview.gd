extends SceneTree
func _init()->void:call_deferred("run")
func run()->void:
    if not OS.get_user_data_dir().get_file().begins_with("DuoduoCatsCourtyard-qa-m28-"):quit(1);return
    var parent:=Control.new();var theme:=Theme.new();theme.default_font=load("res://assets/fonts/CourtyardSans.ttf");parent.theme=theme;root.add_child(parent)
    var settings=preload("res://ui/game_settings.gd").new()
    var menu=preload("res://ui/journey_menu.gd").new(settings);parent.add_child(menu)
    for i in range(8):await process_frame
    await RenderingServer.frame_post_draw
    var result:=root.get_texture().get_image().save_png("res://m28-menu.png")
    print("M28_MENU_RENDER: ",result)
    parent.queue_free();await process_frame;quit(0 if result==OK else 1)
