extends "res://tests/m25_keyboard_driver.gd"
func run()->void:
    lobby=load("res://main.tscn").instantiate();root.add_child(lobby);await frames(3)
    lobby.story_chapter.record_prefix="qa-m27-restart-contract"
    lobby.session.set_focus(true);await start(2,true)
    if "--checkpoint-reader" in OS.get_cmdline_user_args():
        check(s.locked_a and not s.locked_b and not s.finished,"separate process resumes actual first bridge repair")
        check(s.walkable(s.positions[0],0) and s.walkable(s.positions[1],1),"resumed party stands on permanent floor")
        axes(9,Vector2.LEFT);await frames(2);tap_key(KEY_TAB);await frames(1)
        check(lobby.session.movement(0).x<-.9,"role handoff retains held directional input")
        axes(9,Vector2.ZERO)
        c.reset(2,false,true);check(not c.state.locked_a,"solo checkpoint cannot leak into dual run")
        c.reset(2,true,true);s=c.state
        var path:String=c.checkpoint_path();var original:String=FileAccess.get_file_as_string(path)
        var f:=FileAccess.open(path,FileAccess.WRITE);f.store_string('{"version":2,"phase":"complete"}');f.close()
        c.reset(2,true,true);check(not c.state.locked_a and not c.state.finished,"truncated file starts safely without phantom completion")
        f=FileAccess.open(path,FileAccess.WRITE);f.store_string(original);f.close()
        c.reset(2,true,true);check(c.state.locked_a,"valid checkpoint remains recoverable after damaged-file probe")
    else:
        c.reset(2,true,false);s=c.state
        if not gate(await go(0,s.LAMP_A),"walk to first lamp"):return
        await touch(0)
        if not gate(await go(0,s.WINCH_A),"walk to loaded winch"):return
        await touch(0)
        if not gate(await go(1,Vector2(420,560)),"cat takes low maintenance approach"):return
        if not gate(await go(1,s.LATCH_A),"cat enters illuminated unloaded crawlway"):return
        await touch(1);check(s.locked_a,"actual interaction repairs first permanent bridge")
        lobby.session.pause_all();c.set_active(false)
        check(not c.read_record().is_empty(),"pausing flushes atomic unfinished chapter checkpoint")
        check(FileAccess.file_exists(c.checkpoint_path()) and not FileAccess.file_exists(c.checkpoint_path()+".tmp"),"completed atomic rename leaves durable file and no pending temp")
    print("M27_CHECKPOINT_RESTART: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
