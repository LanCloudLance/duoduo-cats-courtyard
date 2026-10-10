extends "res://tests/m27_mainline_playthrough_test.gd"
# Run in a NEW Godot process after the continuous writer. No direct restores.
func run()->void:
    print("M27_MAINLINE_RESUME_QA_USERDIR ",OS.get_user_data_dir())
    if not gate(OS.get_user_data_dir().get_file()=="DuoduoCatsCourtyard-qa-m27-mainline","fresh reader uses isolated mainline QA namespace"):return
    var receipt_path:String="user://"+PREFIX+"-receipt.json"
    if not gate(FileAccess.file_exists(receipt_path),"continuous writer receipt exists before reader"):return
    var receipt=JSON.parse_string(FileAccess.get_file_as_string(receipt_path))
    if not gate(receipt is Dictionary and receipt.get("failed")==0 and receipt.get("records",[]).size()==12,"reader consumes completed two-mode mainline writer"):return
    lobby=load("res://main.tscn").instantiate();root.add_child(lobby);await frames(3);lobby.session.set_focus(true)
    var ids:Array[String]=[]
    for mode in [true,false]:
        single=mode
        var expected:Dictionary={}
        for item in receipt.records:
            if item.single==single and item.route.back()=="five":expected=item
        if not gate(not expected.is_empty(),"matching mode has a chapter-five writer receipt"):return
        if lobby.session.running():tap_key(KEY_ESCAPE);await frames(2)
        await click_entry("ResumeSolo" if single else "ResumeCheckpoint")
        c=lobby.story_chapter;s=c.state
        if not gate(lobby.stage=="story-chapter" and s.chapter==5 and s.single==single and lobby.session.running(),"normal Continue button resumes correct final chapter and mode"):return
        var pointer:Dictionary=lobby.story_progress.read(single)
        if not gate(pointer==expected.pointer and lobby.story_run_id==expected.pointer.run_id,"fresh process resolves matching manifest and run ID"):return
        ids.append(lobby.story_run_id)
        if not gate(s.finished and s.phase=="complete" and c.recorded and s.gear_stored and s.paws_clean,"actual restored world remains completed playable home"):return
        var actual:Dictionary=s.checkpoint()
        if not gate(JSON.parse_string(JSON.stringify(actual.facts))==expected.record.facts,"all earned durable machine and home tool facts survive process restart"):return
        if not gate(s.available_roles()==[0,1,2] and s.current_cat==int(expected.record.current_cat) and s.controlled==int(expected.record.controlled),"reunion roster and selected actors resume for matching mode"):return
        if not gate(s.machine_stopped and s.cleared_segments==3 and s.lid_pins==2 and s.tested and s.network_lit,"repaired tools and outgoing network cannot regress on Continue"):return
        var earned:Array=expected.history
        if not gate(not earned.is_empty() and s.history.has(earned.back()),"earned final observation survives restart"):return
        var retained:Array=earned.slice(maxi(0,earned.size()-31))
        if not gate(s.history.slice(0,s.history.size()-1)==retained,"bounded history preserves earned sequence before adding restore notice"):return
        for role in s.available_roles():
            if not gate(s.walkable(s.positions[role],role),"restored home actor stands on valid floor"):return
        await journal_check()
        await pause_check()
        print("M27_MAINLINE_RESUME_COMPLETE solo=",single," run_id=",lobby.story_run_id," phase=",s.phase)
    check(ids.size()==2 and ids[0]!=ids[1],"reader resumes separate solo and dual runs")
    for item in receipt.records:
        var data=JSON.parse_string(FileAccess.get_file_as_string(item.path))
        check(data is Dictionary and data.get("completed")==true,"fresh process still reads earlier completed chapter: "+item.path)
    await cleanup_mainline()
    print("M27_MAINLINE_RESUME: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
