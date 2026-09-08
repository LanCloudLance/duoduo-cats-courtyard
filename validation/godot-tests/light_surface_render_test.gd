extends SceneTree
## Compare actual rendered solid pixels to gameplay support, including both edges.
const Light = preload("res://game/light_state.gd")
const Map = preload("res://game/light_layout.gd")
const PathView = preload("res://game/light_path_view.gd")
var failed := 0
var checks := 0
func _initialize() -> void: call_deferred("run")
func run() -> void:
    if DisplayServer.get_name() == "headless":
        print("LIGHT_SURFACE_RENDER requires graphical rendering")
        quit(1)
        return
    var viewport := SubViewport.new()
    viewport.size = Vector2i(1280,800)
    viewport.transparent_bg = true
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var paths := [Map.CAT_PATH,Map.GIRL_PATH,Map.SAFE_PATH,Map.FAST_PATH]
    var beams := [Vector2(340,440),Vector2(440,540),Vector2(845,320),Vector2(900,475)]
    for i in range(4):
        var s := Light.new()
        s.phase = ["cat","girl","route","route"][i]
        s.route = "safe" if i == 2 else "fast"
        s.source = "near" if i < 2 else s.route
        s.lit = true
        s.beam = beams[i]
        var view := PathView.new()
        view.configure(paths[i],s.path_width(),["cat","girl","safe","fast"][i])
        viewport.add_child(view)
        for powered in [true,false]:
            s.lit = powered
            view.update_state(s)
            for frame in range(3): await process_frame
            await RenderingServer.frame_post_draw
            var picture := viewport.get_texture().get_image()
            var mismatches := 0
            for x in range(285,1056,3):
                for y in range(265,636,3):
                    var point := Vector2(x+0.5,y+0.5)
                    if s.is_safe(point): continue
                    var expected := s.allows(s.traveler(),point)
                    var painted_solid := picture.get_pixel(x,y).a > 0.9
                    if expected != painted_solid: mismatches += 1
            checks += 1
            if mismatches:
                failed += 1
                push_error("Path %d powered=%s has %d mismatched support pixels" % [i,powered,mismatches])
        view.free()
    print("LIGHT_SURFACE_RENDER: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
