extends SceneTree
const Arena=preload("res://game/arena.gd")
const Session=preload("res://input/session_state.gd")
const Router=preload("res://input/event_router.gd")
const Pilot=preload("res://tests/m29_combat_driver.gd")
var arena
var pilot
var frames:Array[Dictionary]=[]
var folder:="res://m29-combat-shots"
func _initialize()->void:call_deferred("run")
func setup()->void:
    arena.configure({"id":"reserve","mode":"solo","available_role_ids":[0,1,2],"selected_role_id":0,"current_cat":1,"title":"归途树梯"})
    arena.set_active(true);arena.battle.phase="combat";arena.battle.positions[0]=Vector2(500,630)
    arena.battle._spawn("armored",Vector2(690,630),false)
func step(count:int)->void:
    for i in range(count):
        arena.battle.step(1.0/60,arena.session.movement(0),Vector2.ZERO,true)
        arena._sync_actors(1.0/60);arena._refresh()
        await process_frame
func shot(name:String)->void:
    arena._sync_actors(0);arena._refresh();await process_frame;RenderingServer.force_draw()
    var pixels:Image=root.get_texture().get_image()
    if pixels.is_empty():quit(3);return
    var file:String=folder+"/"+name+".png"
    var status:int=pixels.save_png(file)
    var enemy:Dictionary=arena.battle.enemies[0]
    frames.append({"file":file,"saved":status,"mode":enemy.mode,"opening":enemy.get("opening",""),"duration":enemy.get("opening_duration",0),"remaining":enemy.timer,"body_pose":arena.enemy_views[0].action_pose,"rear_scale":str(arena.enemy_views[0].bud.scale)})
    print("FRAME ",JSON.stringify(frames[-1]))
func run()->void:
    print("QA_USER_DIR ",OS.get_user_data_dir())
    if OS.get_user_data_dir().get_file()!="DuoduoCatsCourtyard-qa-m29-combat" or DisplayServer.get_name()=="headless":quit(2);return
    root.size=Vector2i(1280,800);DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
    var s=Session.new();s.single_player=true;s.devices.assign([10,-1]);s.ready_flags.assign([true,false])
    var host=Control.new();host.theme=Theme.new();host.theme.default_font=load("res://assets/fonts/CourtyardSans.ttf");root.add_child(host)
    arena=Arena.new(s);host.add_child(arena);arena.set_physics_process(false);arena.rumble_enabled=false
    var router=Router.new(s);pilot=Pilot.new();pilot.router=router;pilot.arena=arena;root.add_child(pilot)
    router.action_pressed.connect(arena.handle_action);router.action_released.connect(arena.release_action);router.actions_cancelled.connect(arena.cancel_inputs)
    setup();arena.battle.enemies[0].timer=0;await step(1);await shot("01-windup-start");await step(42);await shot("02-windup-half")
    # Miss is produced by the simulated rush. No direct _expose in render fixtures.
    setup();var e=arena.battle.enemies[0];e.mode="rush";e.timer=0.01;e.direction=Vector2.RIGHT
    await step(1);await shot("03-miss-open");await step(56);await shot("04-miss-folding");await step(14);await shot("05-miss-closed")
    setup();e=arena.battle.enemies[0];e.pos=Vector2(800,500);e.mode="rush";e.timer=0.48;e.direction=Vector2.LEFT
    await step(16);await shot("06-stump-long-open");await step(90);await shot("07-stump-still-open")
    await step(61);await shot("08-stump-folding")
    # Normal/precise guard use ordinary InputEvents, differing only in press timing.
    for early in [true,false]:
        setup();e=arena.battle.enemies[0];e.mode="rest";e.timer=99
        pilot.axis(0,Vector2.RIGHT);pilot.button(0,JOY_BUTTON_LEFT_SHOULDER,true);pilot.axis(0,Vector2.ZERO)
        if early:await step(30)
        e.pos=Vector2(615,630);e.mode="rush";e.timer=0.48;e.direction=Vector2.LEFT
        await step(7);pilot.button(0,JOY_BUTTON_LEFT_SHOULDER,false)
        await shot("09-shield-long-open" if early else "10-parry-longest-open")
    setup();e=arena.battle.enemies[0];e.pos=Vector2(800,630);e.mode="rush";e.timer=0.48;e.direction=Vector2.LEFT
    arena.battle._spawn("sprout",Vector2(650,630),false);arena.battle.enemies[1].mode="rest";arena.battle.enemies[1].timer=99
    await step(14);await shot("11-collision-open")
    var output=FileAccess.open(folder+"/frames.json",FileAccess.WRITE);output.store_string(JSON.stringify({"renderer":DisplayServer.get_name(),"namespace":OS.get_user_data_dir(),"frames":frames},"  "));output.close()
    print("M29_COMBAT_RENDER: ",frames.size()," frames");quit(0)
