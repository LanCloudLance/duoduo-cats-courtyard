extends SceneTree
const Arena=preload("res://game/arena.gd")
const Session=preload("res://input/session_state.gd")
var arena
var session
var frames:Array[Dictionary]=[]
var failed:=0
var folder:="res://m31-route-shots"
func _initialize()->void:call_deferred("run")
func shot(name:String)->void:
    arena._sync_actors(0.0);arena._refresh();await process_frame;await process_frame;RenderingServer.force_draw()
    var pixels:Image=root.get_texture().get_image()
    if pixels.is_empty():failed+=1;return
    var file:String=folder+"/"+name+".png"
    var status:int=pixels.save_png(file)
    if status!=OK:failed+=1
    var forecasts=[]
    for e in arena.battle.enemies:
        if e.mode=="windup":forecasts.append(arena.battle.rush_preview(e))
    frames.append({"file":file,"saved":status,"fixture":true,"phase":arena.battle.phase,"route_open":arena.battle.route_open,"players":str(arena.battle.positions),"title":arena.title_label.text,"title_rect":str(arena.title_label.get_rect()),"status_rect":str(arena.status_label.get_rect()),"title_clip":arena.title_label.clip_text,"title_ellipsis":arena.title_label.text_overrun_behavior==TextServer.OVERRUN_TRIM_ELLIPSIS,"forecasts":forecasts,"badges":Arena.RouteView.exit_badges(arena.battle,session.keyboard_mode)})
func reserve()->void:
    session.single_player=false
    arena.configure({"id":"reserve","encounter_revision":2,"mode":"dual","available_role_ids":[0,1,2],"selected_role_id":0,"current_cat":1,"title":"第四章 · 灯光躲起来了 · 树梯横枝","allow_next_level":false})
    arena.battle._start_wave(1);arena.battle.enemies=arena.battle.enemies.filter(func(e):return e.kind=="armored")
    arena.battle.Space.STUMPS.clear();arena.battle.positions[0]=Vector2(940,690);arena.battle.positions[1]=Vector2(760,380)
    var e:Dictionary=arena.battle.enemies[0];e.pos=Vector2(810,625);e.direction=Vector2.RIGHT;e.mode="windup";e.timer=1.2;e.pose_duration=1.2;e.pose_elapsed=0.7
    arena.set_active(true)
func shell()->void:
    session.single_player=true
    arena.configure({"id":"shell","encounter_revision":2,"mode":"solo","available_role_ids":[0,1,2],"selected_role_id":1,"current_cat":1,"title":"第四章 · 灯光躲起来了 · 检修路藤门","allow_next_level":false})
    arena.battle._start_wave(1);arena.battle.positions[1]=Vector2(780,420);arena.set_active(true)
func run()->void:
    if OS.get_user_data_dir().get_file()!="DuoduoCatsCourtyard-qa-m31-player" or DisplayServer.get_name()=="headless":quit(2);return
    root.size=Vector2i(1280,800);DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
    session=Session.new();session.keyboard_mode=true;session.devices.assign([-1,-1]);session.ready_flags.assign([true,true])
    var host=Control.new();host.theme=Theme.new();host.theme.default_font=load("res://assets/fonts/CourtyardSans.ttf");root.add_child(host)
    arena=Arena.new(session);host.add_child(arena);arena.set_physics_process(false);arena.rumble_enabled=false;arena.shake_enabled=false
    reserve();await shot("reserve-01-true-branch")
    reserve();arena.battle.positions[0]=Vector2(895,625);arena.battle.facing[0]=Vector2.LEFT;arena.battle.guarding=true;await shot("reserve-02-prior-shield")
    reserve();arena.battle.Space.STUMPS.assign([Vector2(905,625)]);arena._rebuild_props();await shot("reserve-03-prior-stump")
    reserve();arena.battle.enemies[0].pos=Vector2(710,625);await shot("reserve-04-out-of-reach")
    reserve();arena.battle.enemies[0].pos=Vector2(810,390);await shot("reserve-05-durable-hedge")
    reserve();arena.battle.Space.STUMPS.assign([Vector2(620,500),Vector2(925,340)]);arena._rebuild_props()
    arena.battle.enemies[0].pos=Vector2(835.986,362.2806);arena.battle.enemies[0].direction=Vector2(.375893,-.926663)
    await shot("reserve-06-edge-no-false-stump")
    reserve();session.single_player=true
    arena.configure({"id":"reserve","encounter_revision":2,"mode":"solo","available_role_ids":[0,1,2],"selected_role_id":0,"current_cat":1,"title":"最后一格体力 · 落点不是完成","allow_next_level":false})
    arena.battle._start_wave(1);arena.battle.enemies=arena.battle.enemies.filter(func(e):return e.kind=="armored")
    arena.battle.Space.STUMPS.clear();arena.battle.positions[0]=Vector2(870,625);arena.battle.hp[0]=1
    var target:Dictionary=arena.battle.enemies[0];target.pos=Vector2(810,625);target.direction=Vector2.RIGHT;target.mode="windup";target.timer=0.01
    await shot("reserve-07-last-heart-no-route-promise")
    reserve();arena.battle.enemies[0].hp=0;arena.battle.step(.01,Vector2.ZERO,Vector2.ZERO,true)
    await shot("reserve-08-human-release-dual-keys")
    shell();await shot("shell-01-bound")
    for e in arena.battle.enemies:
        if e.kind=="weaver":e.weave_break=2.2;e.mode="rest"
    await shot("shell-02-shield-loose-root-bound")
    for e in arena.battle.enemies:
        if e.kind=="weaver":e.hp=0
    arena.battle.step(0.01,Vector2.ZERO,Vector2.ZERO,true);await shot("shell-03-root-released")
    reserve();arena.battle._open_route("impact");arena.battle.positions[0]=arena.battle.EXIT+Vector2(-15,-24);arena.battle.positions[1]=arena.battle.EXIT+Vector2(-15,24)
    arena.battle.interact(0);await shot("exit-01-p1-confirmed-p2-ready")
    arena.battle.positions[0]=Vector2(930,500);arena.battle.step(0.01,Vector2.ZERO,Vector2.ZERO,true);await shot("exit-02-p1-left-confirmation-cleared")
    arena.battle.hp[1]=0;await shot("exit-03-p2-needs-human-rescue")
    var f=FileAccess.open(folder+"/frames.json",FileAccess.WRITE)
    f.store_string(JSON.stringify({"renderer":DisplayServer.get_name(),"namespace":OS.get_user_data_dir(),"frames":frames,"evidence":"controlled runtime render fixtures, not first-time player paths"},"  "));f.close()
    print("M31_ROUTE_RENDER: ",frames.size()," frames, ",failed," failed");quit(1 if failed else 0)
