extends SceneTree
var checks := 0
var failed := 0
func check(value: bool,label: String) -> void:
    checks += 1
    if not value: failed += 1; push_error("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var lobby = load("res://main.tscn").instantiate()
    root.add_child(lobby)
    await process_frame
    var font: Font = lobby.music_button.get_theme_font("font")
    check(font == lobby.theme.default_font and font.has_char("音".unicode_at(0)),"music button uses bundled Chinese font without relying on OS fallback")
    lobby.music_button.pressed.emit()
    check(lobby.music.muted and lobby.music_button.text.contains("关闭"),"music control can mute background separately")
    lobby.music_button.pressed.emit()
    check(not lobby.music.muted and lobby.music.level < 0.2,"light music setting restores a quieter level")
    lobby.queue_free()
    await process_frame
    await process_frame
    print("M21_MUSIC_SCENE: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
