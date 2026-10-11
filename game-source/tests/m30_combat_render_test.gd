extends SceneTree
const Arena=preload("res://game/arena.gd")
const Session=preload("res://input/session_state.gd")
const Router=preload("res://input/event_router.gd")
const Pilot=preload("res://tests/m30_combat_driver.gd")
var arena
var pilot
var frames:Array[Dictionary]=[]
var folder:="res://m30-combat-shots"
var failed:=0
func _initialize()->void:call_deferred("run")
func shot(name:String)->void:
    arena._sync_actors(0.0);arena._refresh();await process_frame;await process_frame;RenderingServer.force_draw()
    var pixels:Image=root.get_texture().get_image()
    if pixels.is_empty():failed+=1;return
    var file:String=folder+"/"+name+".png"
    var status:int=pixels.save_png(file)
    if status!=OK:failed+=1
    var enemies=[]
    for e in arena.battle.enemies:enemies.append({"kind":e.kind,"hp":e.hp,"mode":e.mode,"position":str(e.pos)})
    frames.append({"file":file,"saved":status,"phase":arena.battle.phase,"route_open":arena.battle.route_open,"cause":arena.battle.route_cause,"enemies":enemies,"time":pilot.elapsed,"players":str(arena.battle.positions)})
    print("FRAME ",JSON.stringify(frames[-1]))
func run()->void:
    if OS.get_user_data_dir().get_file()!="DuoduoCatsCourtyard-qa-m30-combat" or DisplayServer.get_name()=="headless":quit(2);return
    root.size=Vector2i(1280,800);DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
    var s=Session.new();s.single_player=true;s.devices.assign([10,-1]);s.ready_flags.assign([true,false])
    var host=Control.new();host.theme=Theme.new();host.theme.default_font=load("res://assets/fonts/CourtyardSans.ttf");root.add_child(host)
    arena=Arena.new(s);host.add_child(arena);arena.set_physics_process(false);arena.rumble_enabled=false;arena.shake_enabled=false
    var router=Router.new(s);pilot=Pilot.new();pilot.router=router;pilot.arena=arena;root.add_child(pilot)
    router.action_pressed.connect(arena.handle_action);router.action_released.connect(arena.release_action);router.actions_cancelled.connect(arena.cancel_inputs)
    for id in ["shell","reserve"]:
        pilot.reset();pilot.route_method="objective"
        arena.configure({"id":id,"encounter_revision":2,"mode":"solo","available_role_ids":[0,1,2],"selected_role_id":1,"current_cat":1,"title":"检修藤门 · 断开源头" if id=="shell" else "归途树梯 · 引冲锋破障"})
        arena.set_active(true);pilot.tap(0,JOY_BUTTON_A);await shot(id+"-01-closed")
        var lock_shot:=false
        for i in range(7200):
            pilot.frame()
            if id=="reserve" and not lock_shot:
                for e in arena.battle.enemies:
                    if e.kind=="armored" and e.mode=="windup" and e.direction.x>0.1 and e.pos.x>arena.battle.Space.GATE.x-110:
                        lock_shot=true;await shot(id+"-02-lock")
            if arena.battle.route_open:break
        if not arena.battle.route_open:failed+=1;continue
        await shot(id+"-03-open")
        for i in range(32):pilot.frame()
        await shot(id+"-04-retreat")
        for i in range(1200):
            pilot.frame()
            if arena.battle.phase=="complete":break
        if arena.battle.phase!="complete":failed+=1
        await shot(id+"-05-exited")
    var f=FileAccess.open(folder+"/frames.json",FileAccess.WRITE)
    f.store_string(JSON.stringify({"renderer":DisplayServer.get_name(),"namespace":OS.get_user_data_dir(),"frames":frames},"  "));f.close()
    print("M30_COMBAT_RENDER: ",frames.size()," frames, ",failed," failed");quit(1 if failed else 0)
