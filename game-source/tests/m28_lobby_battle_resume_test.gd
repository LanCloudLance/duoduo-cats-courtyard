extends "res://tests/keyboard_scene_test.gd"
## Independent actual Lobby persistence test. The preparation phase seeds only a
## validated chapter checkpoint; all combat and menus use ordinary InputEvents.
const QA_NAMESPACE := "DuoduoCatsCourtyard-qa-m28-lobby-battle-resume"
const Story = preload("res://game/chapter_one_state.gd")
var single := true
var phase_name := ""
var receipt: Dictionary = {}
var clicks := 0
var pilot

class NormalBattlePilot extends "res://tests/m28_combat_driver.gd":
    var driver
    func axis(slot:int,vector:Vector2)->void:driver.drive(slot,vector)
    func button(slot:int,id:int,down:bool)->void:
        var keys:Dictionary={JOY_BUTTON_A:KEY_E,JOY_BUTTON_X:KEY_F,JOY_BUTTON_B:KEY_Q,JOY_BUTTON_Y:KEY_TAB,JOY_BUTTON_LEFT_SHOULDER:KEY_G} if slot==0 else {JOY_BUTTON_A:KEY_SPACE,JOY_BUTTON_X:KEY_J,JOY_BUTTON_B:KEY_K,JOY_BUTTON_Y:KEY_TAB,JOY_BUTTON_LEFT_SHOULDER:KEY_U}
        driver.key_event(keys[id],down)

func drive(slot:int,direction:Vector2)->void:axes(9 if single or slot==0 else 18,direction)
func gate(value:bool,label:String)->bool:
    check(value,label)
    if not value:
        print("M28_LOBBY_RESUME_BLOCK phase=",phase_name," solo=",single," stage=",lobby.stage if lobby else "unstarted")
        print("M28_LOBBY_BATTLE_RESUME: %d checks, %d failed"%[checks,failed]);quit(1)
    return value
func receipt_path()->String:return "user://qa-lobby-resume-"+("solo" if single else "dual")+".json"
func write_receipt()->bool:
    var file:=FileAccess.open(receipt_path(),FileAccess.WRITE)
    if not gate(file!=null,"QA receipt opens only after actual namespace gate"):return false
    file.store_string(JSON.stringify(receipt,"  "));file.close();return true
func run()->void:
    print("M28_LOBBY_RESUME_USERDIR ",OS.get_user_data_dir()," pid=",OS.get_process_id())
    if not gate(OS.get_user_data_dir().get_file()==QA_NAMESPACE,"actual isolated QA namespace before any save access"):return
    var args:=OS.get_cmdline_user_args()
    if not gate(args.size()==2 and args[0] in ["prepare","segment","resume"] and args[1] in ["solo","dual"],"explicit process phase and player mode"):return
    phase_name=args[0];single=args[1]=="solo"
    Engine.time_scale=1
    lobby=load("res://main.tscn").instantiate()
    # The unrelated legacy courtyard importer otherwise probes absolute M6-M10
    # save paths during _ready. Disable that migration before entering the tree;
    # the actual story and battle stores retain their normal product paths.
    lobby.checkpoint.path="user://qa-no-legacy-courtyard.json"
    root.add_child(lobby);await frames(3);lobby.session.set_focus(true)
    if phase_name=="prepare":
        await prepare_fixture();return
    var data=JSON.parse_string(FileAccess.get_file_as_string(receipt_path()))
    if not gate(data is Dictionary,"prior process QA receipt exists"):return
    receipt=data
    if not gate(receipt.prepare_pid!=OS.get_process_id(),"new OS process after menu-created fixture"):return
    await click_menu("继续单人旅程" if single else "继续双人旅程")
    if failed:return
    for i in range(90):
        if lobby.stage=="chapter-combat":break
        await frames(1)
    if not gate(lobby.stage=="chapter-combat" and lobby.session.running(),"Continue restores chapter and naturally emits its battle request"):return
    if not gate(lobby.session.single_player==single and lobby.story_run_id==receipt.run_id and lobby.story_route_active and not lobby.preview_run,"Continue preserves mode and exact story run"):return
    var battle=lobby.arena.battle
    if not gate(battle.context.return_chapter==1 and battle.context.return_phase=="battle" and battle.story_encounter=="first","arena came from the same first-chapter story source"):return
    if not gate(battle.deployed_slots()==([0] if single else [0,1]),"restored mode deploys one solo or two human actors"):return
    if not gate(lobby.chapter_one.state.branch_clear and lobby.chapter_one.state.supported and lobby.chapter_one.state.equipment,"earned chapter checkpoint facts survive the battle boundary"):return
    pilot=NormalBattlePilot.new();pilot.driver=self;pilot.arena=lobby.arena
    if phase_name=="segment":await play_first_and_exit()
    else:await resume_and_finish()

func prepare_fixture()->void:
    await click_menu("新旅程 · 一个人" if single else "新旅程 · 两个人")
    if not gate(lobby.stage=="prologue" and lobby.session.running() and lobby.session.single_player==single and lobby.story_run_id.begins_with("story-run-"),"ordinary new-journey menu creates correct mode and run"):return
    var run_id:String=lobby.story_run_id
    tap_key(KEY_ESCAPE);await frames(3)
    if not gate(not lobby.session.running() and lobby.journey_menu.visible,"ordinary Escape opens product pause menu"):return
    # This is an explicitly permitted checkpoint fixture, NOT a played prologue
    # or chapter puzzle. Never restore it into any live arena or chapter state.
    var offline=Story.new();offline.single=single
    var checkpoint:Dictionary=offline.checkpoint()
    checkpoint.phase="battle";checkpoint.facts.equipment=true;checkpoint.facts.supported=true;checkpoint.facts.branch_clear=true
    checkpoint.facts.fork_pos=[585,570];checkpoint.positions=[[1080,560],[1115,590]]
    checkpoint.history=["QA fixture: legal first-chapter battle checkpoint; puzzles were not played in this test."]
    var validator=Story.new();validator.single=single
    if not gate(validator.restore_checkpoint(checkpoint),"offline fixture passes production checkpoint dependency validation"):return
    var path:String="user://"+run_id+"-one"+("-solo-v2.json" if single else "-dual-v2.json")
    var file:=FileAccess.open(path,FileAccess.WRITE)
    if not gate(file!=null,"chapter fixture opens in isolated namespace"):return
    file.store_string(JSON.stringify(checkpoint));file.close()
    if not gate(lobby.story_progress.save(single,run_id,1,[]),"legal story pointer is seeded for a fresh process"):return
    receipt={"run_id":run_id,"mode":"solo" if single else "dual","prepare_pid":OS.get_process_id(),"fixture":true,"fixture_scope":"chapter-one battle checkpoint only; not full-route play","checkpoint_path":path,"source_facts":checkpoint.facts,"source_history":checkpoint.history}
    if not write_receipt():return
    await exit_via_menu()

func click_menu(label:String)->void:
    var choice:Button
    for candidate in lobby.journey_menu.buttons:
        if candidate.text==label and candidate.is_visible_in_tree():choice=candidate;break
    if not gate(choice!=null and not choice.disabled,"visible enabled ordinary menu button: "+label):return
    var before:int=clicks
    choice.pressed.connect(func():clicks+=1,CONNECT_ONE_SHOT)
    var motion:=InputEventMouseMotion.new();motion.position=root.get_final_transform()*choice.get_global_rect().get_center()
    Input.parse_input_event(motion);Input.flush_buffered_events()
    for down in [true,false]:
        var event:=InputEventMouseButton.new();event.position=motion.position;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down
        Input.parse_input_event(event);Input.flush_buffered_events();await frames(1)
    await frames(3)
    gate(clicks==before+1,"physical input activates exactly one menu action: "+label)

func tick_pilot()->void:
    pilot.tick_index+=1
    for slot in lobby.arena.battle.deployed_slots():pilot.pilot(slot)
    await frames(1)
func release_inputs()->void:
    for slot in [0,1]:drive(slot,Vector2.ZERO)
    key_event(KEY_G,false);key_event(KEY_U,false)

func play_first_and_exit()->void:
    var battle=lobby.arena.battle
    if not gate(battle.cleared_segments==0 and battle.phase=="briefing","fresh fixture grants no combat victory"):return
    for i in range(10000):
        if battle.cleared_segments==1:break
        await tick_pilot()
    release_inputs()
    if not gate(battle.cleared_segments==1 and battle.phase=="intermission","ordinary combat inputs actually clear only segment one"):return
    receipt.segment_pid=OS.get_process_id();receipt.first_result=lobby.arena.result().duplicate(true)
    # Enter segment two and earn real partial damage before leaving. This is
    # deliberately not a safe-segment completion and must not survive restart.
    var partial:=false
    for i in range(6000):
        await tick_pilot()
        if battle.wave==2 and battle.phase=="combat" and battle.enemies.any(func(enemy):return enemy.hp<enemy.max_hp):partial=true;break
        if battle.cleared_segments>1:break
    release_inputs()
    if not gate(partial and battle.cleared_segments==1,"ordinary inputs start segment two and damage an enemy without clearing it"):return
    receipt.partial_wave=battle.wave;receipt.partial_enemies=[]
    for enemy in battle.enemies:receipt.partial_enemies.append({"kind":enemy.kind,"hp":enemy.hp,"max_hp":enemy.max_hp})
    receipt.attack_events=pilot.attack_events;receipt.dodge_events=pilot.dodge_events;receipt.signature_events=pilot.signature_events
    tap_key(KEY_ESCAPE);await frames(4)
    if not gate(not lobby.session.running() and lobby.journey_menu.visible and not lobby.arena.active,"Escape pauses actual battle and opens exit menu"):return
    var points:Array=battle.positions.duplicate();var enemies:String=JSON.stringify(battle.enemies)
    await frames(20)
    if not gate(battle.positions==points and JSON.stringify(battle.enemies)==enemies,"paused battle does not simulate while preparing exit"):return
    var saved:Dictionary=lobby.battle_journey.read(battle.context)
    if not gate(saved.get("cleared_segments")==1,"product pause/autosave records only the cleared first segment"):return
    receipt.saved_after_pause=saved;receipt.segment_checks=checks
    if not write_receipt():return
    pilot.free();pilot=null
    await exit_via_menu()

func resume_and_finish()->void:
    var battle=lobby.arena.battle
    if not gate(receipt.segment_pid!=OS.get_process_id(),"fresh OS process after real pause/exit"):return
    if not gate(battle.cleared_segments==1 and battle.phase=="intermission" and battle.wave==1 and battle.enemies.is_empty(),"Continue retains first segment only and discards unfinished combat transients"):return
    if not gate(battle.actor(0)==receipt.first_result.selected_role_id and battle.current_cat==receipt.first_result.current_cat,"saved role and selected cat are restored"):return
    if not gate(receipt.source_history.all(func(entry):return entry in lobby.chapter_one.state.history),"original chapter exploration history survives alongside resume notices"):return
    for i in range(90):
        if battle.phase=="combat":break
        await tick_pilot()
    if not gate(battle.phase=="combat" and battle.wave==2 and battle.cleared_segments==1,"normal confirmations begin only uncleared segment two"):return
    if not gate(not battle.enemies.is_empty() and battle.enemies.all(func(enemy):return enemy.hp==enemy.max_hp),"unfinished segment enemies restart at full encounter health"):return
    var waves:Array[int]=[]
    for i in range(14000):
        if lobby.stage!="chapter-combat":break
        if not waves.has(battle.wave):waves.append(battle.wave)
        if battle.phase=="complete":tap_key(KEY_E);await frames(3)
        else:await tick_pilot()
    release_inputs()
    if not gate(lobby.stage=="chapter-one" and lobby.chapter_one.state.phase=="station","ordinary second-segment combat and exit inputs return to the same story source"):return
    if not gate(waves==[2] and battle.cleared_segments==2 and battle.phase=="complete","resume never replays first segment or grants completion before second victory"):return
    if not gate(lobby.story_run_id==receipt.run_id and lobby.session.single_player==single and lobby.session.running(),"return to story preserves exact run and player mode"):return
    if not gate(lobby.chapter_one.state.branch_clear and lobby.chapter_one.state.supported and lobby.chapter_one.state.equipment,"battle completion preserves checkpoint exploration achievements"):return
    var pointer:Dictionary=lobby.story_progress.read(single)
    if not gate(pointer.get("run_id")==receipt.run_id and pointer.get("chapter")==1,"story continue pointer still belongs to the original chapter and run"):return
    var durable:Dictionary=lobby.battle_journey.read(battle.context)
    if not gate(durable.get("cleared_segments")==2,"actual second victory is durable through product save integration"):return
    receipt.resume_pid=OS.get_process_id();receipt.resumed_waves=waves;receipt.final_result=lobby.arena.result();receipt.final_stage=lobby.stage;receipt.final_story_phase=lobby.chapter_one.state.phase;receipt.resume_checks=checks
    if not write_receipt():return
    pilot.free();pilot=null
    tap_key(KEY_ESCAPE);await frames(3)
    await exit_via_menu()

func exit_via_menu()->void:
    var exit_button:Button
    for choice in lobby.journey_menu.buttons:
        if choice.text=="退出" and choice.is_visible_in_tree():exit_button=choice;break
    if not gate(exit_button!=null and not lobby.session.running(),"real product pause menu exposes desktop Exit"):return
    print("M28_LOBBY_BATTLE_RESUME phase=",phase_name," mode=",("solo" if single else "dual"),": %d checks, %d failed"%[checks,failed])
    # Unwind the test coroutine's offline fixture / battle references before
    # process shutdown. The actual Exit still receives physical events.
    call_deferred("click_exit")

func click_exit()->void:
    var exit_button:Button
    for choice in lobby.journey_menu.buttons:
        if choice.text=="退出" and choice.is_visible_in_tree():exit_button=choice;break
    if not gate(exit_button!=null,"exit remains visible after test stack unwinds"):return
    exit_button.pressed.connect(func():print("M28_LOBBY_RESUME_EXIT_BUTTON phase=",phase_name," solo=",single," pid=",OS.get_process_id()),CONNECT_ONE_SHOT)
    var motion:=InputEventMouseMotion.new();motion.position=root.get_final_transform()*exit_button.get_global_rect().get_center()
    Input.parse_input_event(motion);Input.flush_buffered_events()
    for down in [true,false]:
        var event:=InputEventMouseButton.new();event.position=motion.position;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down
        Input.parse_input_event(event);Input.flush_buffered_events()
