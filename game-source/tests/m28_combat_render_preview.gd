extends SceneTree
## GUI-only deterministic motion snapshots. The author does not launch this in headless QA.
const Arena=preload("res://game/arena.gd")
const Session=preload("res://input/session_state.gd")
var arena
var frames: Array[Dictionary]=[]
var folder: String="res://m28-combat-shots"
func _initialize() -> void:call_deferred("run")
func ctx(id: String,role: int=0,dual:=false) -> Dictionary:
    return {"id":id,"mode":"dual" if dual else "solo","available_role_ids":[0,1,2],"selected_role_id":role,"current_cat":1,"title":"战斗动作审查 · "+id,"destination":"维修道已清开。"}
func setup(id: String,role: int=0) -> void:
    arena.configure(ctx(id,role));arena.set_active(true);arena.battle.phase="combat";arena.battle.positions[role]=Vector2(500,630)
func advance(count: int,p1:=Vector2.ZERO,p2:=Vector2.ZERO) -> void:
    for i in range(count):
        arena.battle.step(1.0/60,p1,p2,true)
        arena._sync_actors(1.0/60);arena._refresh()
        await process_frame
func shot(name: String) -> void:
    arena._sync_actors(1.0/60);arena._refresh()
    arena.queue_redraw()
    await process_frame
    RenderingServer.force_draw()
    var image: Image=root.get_texture().get_image()
    if image.is_empty():push_error("No rendered pixels");quit(3);return
    var path: String=folder+"/"+name+".png"
    var status: int=image.save_png(path)
    var actors=[]
    for slot in arena.battle.deployed_slots():actors.append({"slot":slot,"role":arena.battle.actor(slot),"pos":str(arena.battle.positions[arena.battle.actor(slot)]),"kind":arena.battle.attacks.kinds[slot],"progress":arena.actors[arena.battle.actor(slot)].combat_progress})
    var reserves=[]
    for role in arena.battle.roster.reserves():reserves.append({"role":role,"pos":str(arena.battle.positions[role]),"body_rect":str(arena.actors[role].body_rect()),"caption_rect":str(arena.actors[role].caption_rect())})
    var enemies=[]
    for enemy in arena.battle.enemies:enemies.append({"kind":enemy.kind,"mode":enemy.mode,"pos":str(enemy.pos),"direction":str(enemy.direction),"hp":enemy.hp,"timer":enemy.timer,"link":not arena.battle.linked_source(enemy).is_empty()})
    frames.append({"file":path,"save_code":status,"phase":arena.battle.phase,"actors":actors,"reserves":reserves,"enemies":enemies,"hint":arena.hint_label.text,"label_overlaps":arena.label_metrics.get("overlaps",-1)})
    print("FRAME ",JSON.stringify(frames[-1]))
func run() -> void:
    print("QA_USER_DIR ",OS.get_user_data_dir())
    if not OS.get_user_data_dir().get_file().begins_with("DuoduoCatsCourtyard-qa-m28-"):quit(2);return
    if DisplayServer.get_name()=="headless":print("GUI renderer required; no pixel acceptance from dummy renderer");quit(2);return
    root.size=Vector2i(1280,800)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
    var s=Session.new();s.single_player=true;s.keyboard_mode=true;s.ready_flags.assign([true,false])
    var host=Control.new();host.theme=Theme.new();host.theme.default_font=load("res://assets/fonts/CourtyardSans.ttf");root.add_child(host)
    arena=Arena.new(s);host.add_child(arena);arena.set_physics_process(false);arena.rumble_enabled=false
    # Linked frontline: normal front strike bounces, then Tuantuan cancels the source's cast.
    setup("shell",1);arena.battle.positions[1]=Vector2(590,650)
    arena.battle._spawn("thorn",Vector2(650,650),false);arena.battle._spawn("weaver",Vector2(1030,585),false)
    arena.battle.enemies[0].mode="rest";arena.battle.enemies[0].timer=99;arena.battle.enemies[1].mode="rest";arena.battle.enemies[1].timer=99
    await shot("01-linked-front");arena.handle_action(0,JOY_BUTTON_X);arena.release_action(0,JOY_BUTTON_X);await advance(4);await shot("02-link-block")
    # Pounce sequence from actual action clock, not posed sprite booleans.
    setup("shell",1);arena.battle.positions[1]=Vector2(850,630);arena.battle.facing[0]=Vector2.RIGHT
    arena.battle._spawn("weaver",Vector2(980,630),false);var caster=arena.battle.enemies[0];caster.mode="cast";caster.timer=0.7;caster.aim=Vector2(850,630)
    arena.handle_action(0,JOY_BUTTON_LEFT_SHOULDER);arena.release_action(0,JOY_BUTTON_LEFT_SHOULDER)
    await advance(3);await shot("03-pounce-preparation");await advance(9);await shot("04-pounce-contact");await advance(15);await shot("05-interrupted-no-target")
    # Three separate live moments show crouch, ready and release.
    setup("reserve",2);arena.battle._spawn("sprout",Vector2(570,630),false);arena.battle.enemies[0].mode="rest";arena.battle.enemies[0].timer=99
    arena.handle_action(0,JOY_BUTTON_LEFT_SHOULDER);await advance(10);await shot("06-heavy-crouch");await advance(17);await shot("07-heavy-ready")
    arena.release_action(0,JOY_BUTTON_LEFT_SHOULDER);await advance(7);await shot("08-heavy-contact");await advance(15);await shot("09-heavy-recovery")
    # Closed shell, real shield stop and accessible rear node.
    setup("reserve",0);arena.battle._spawn("armored",Vector2(620,630),false);var shell=arena.battle.enemies[0];shell.mode="windup";shell.timer=0.10;shell.direction=Vector2.LEFT
    await shot("10-shell-front-closed");await advance(6);arena.handle_action(0,JOY_BUTTON_LEFT_SHOULDER);await advance(16);await shot("11-shell-parry-rear-open")
    arena.release_action(0,JOY_BUTTON_LEFT_SHOULDER);arena.battle.dodge(0,Vector2.RIGHT);await advance(14);arena.battle.facing[0]=Vector2.LEFT;arena.handle_action(0,JOY_BUTTON_X);arena.release_action(0,JOY_BUTTON_X);await advance(6);await shot("12-shell-rear-hit")
    arena.configure(ctx("reserve",0));arena.battle.cleared_segments=2;arena.battle.phase="clear";arena.battle.positions[0]=arena.battle.EXIT;await shot("13-exit-confirm")
    arena.handle_action(0,JOY_BUTTON_A);await shot("14-exit-continue")
    # Dual staging: exactly two owners; reserve is visibly away from both threats.
    s.single_player=false;s.ready_flags.assign([true,true]);arena.configure(ctx("shell",0,true));arena.battle.interact(0);arena.battle.interact(1);await advance(25);await shot("15-dual-staging")
    var record=FileAccess.open(folder+"/frames.json",FileAccess.WRITE);record.store_string(JSON.stringify({"user_dir":OS.get_user_data_dir(),"renderer":DisplayServer.get_name(),"frames":frames},"  "));record.close()
    print("M28_COMBAT_RENDER: ",frames.size()," frames written to ",ProjectSettings.globalize_path(folder))
    quit(0)
