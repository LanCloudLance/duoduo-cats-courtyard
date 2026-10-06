extends SceneTree
const Sprite = preload("res://game/storybook_sprite.gd")
var actors: Array = []
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var viewport := SubViewport.new()
    viewport.size = Vector2i(1440, 1080)
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var background := ColorRect.new()
    background.color = Color("6c8678")
    background.size = Vector2(1440, 1080)
    viewport.add_child(background)
    for row in range(6):
        for step in range(8):
            var carrier := Node2D.new()
            carrier.position = Vector2(90 + step * 180, 154 + row * 176)
            viewport.add_child(carrier)
            var foot := Line2D.new()
            foot.points = PackedVector2Array([Vector2(-65, 0), Vector2(65, 0)])
            foot.default_color = Color("edc968")
            foot.width = 1
            carrier.add_child(foot)
            var actor := Sprite.new()
            actor.role = row % 3
            carrier.add_child(actor)
            actor.move_direction = Vector2.UP if row >= 3 else Vector2.DOWN
            actor.pose((step * Sprite.WALK_CYCLE_DISTANCE / 8.0 + 1) * 0.09, 1, 1, 0)
            actors.append(actor)
    await process_frame
    await RenderingServer.frame_post_draw
    viewport.get_texture().get_image().save_png("/tmp/m26-native-motion-contact-sheet.png")
    print("M26_NATIVE_CONTACT_SHEET: /tmp/m26-native-motion-contact-sheet.png")
    quit()
