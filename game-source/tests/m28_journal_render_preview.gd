extends SceneTree
# Rendering fixture only; the mainline test proves that discovery earns this paper.
func _init()->void:call_deferred("run")
func run()->void:
    if OS.get_user_data_dir().get_file()!="DuoduoCatsCourtyard-qa-m28-root":quit(1);return
    var lobby=load("res://main.tscn").instantiate();root.add_child(lobby)
    for i in range(6):await process_frame
    lobby.journal.open(["团团沿着斜光看见纸背的折页。", "旅途发现：钟楼纸背的旧线路图"],"旅途记事")
    for earned in [false,true]:
        lobby.journal.show_saved_map(earned)
        for i in range(6):await process_frame
        lobby.journal.scroll.scroll_vertical=999999
        await process_frame;RenderingServer.force_draw()
        var suffix:="earned" if earned else "unearned"
        var status:=root.get_texture().get_image().save_png("res://m28-journal-"+suffix+".png")
        if status!=OK:push_error("journal screenshot failed");quit(1);return
    print("M28_JOURNAL_RENDER: 2 real pixel frames; fixture only")
    lobby.free();call_deferred("quit",0)
