extends "res://tests/keyboard_scene_test.gd"
# Bounded visual fixture: initial C4 state/positions are seeded only to reproduce
# label occlusion. Subsequent movement goes through production InputEvent routing.
const Driver=preload("res://tests/battle_driver.gd")
var b
var meter
var trace:Array=[]
var feedback:Array=[]
var feedback_cursor:=0
var switched:=0
var used_guard:=false
var used_attack:=false
var moved_frames:=0
var visual_index:=0
func drive(slot:int,vector:Vector2)->void:axes(9 if slot==0 else 18,vector)
func tap_key(code:int)->void:
    if code==KEY_J and b!=null and b.current_cat==2:
        key_event(KEY_J,true);return
    super.tap_key(code)
func run()->void:
    if DisplayServer.get_name()=="headless":push_error("native render required");quit(1);return
    if OS.get_user_data_dir().get_file()!="DuoduoCatsCourtyard-qa-m27-labels":push_error("wrong QA namespace");quit(1);return
    Engine.max_fps=60
    root.size=Vector2i(1280,800);root.position=Vector2i(45,55)
    lobby=load("res://main.tscn").instantiate();root.add_child(lobby);await frames(10)
    root.grab_focus();await frames(20)
    print("LABELS_NATIVE_FOCUS ",lobby.session.focused," userdir=",OS.get_user_data_dir())
    if not lobby.session.focused:push_error("fixture window did not obtain focus");quit(1);return
    lobby.story_chapter.record_prefix="qa-m27-label-fixture"
    lobby.start_story_chapter(4,true);await frames(3)
    var s=lobby.story_chapter.state
    s.phase="investigate";s.cloth=true
    s.positions[0]=s.ARROWS;s.positions[1]=s.BRANCH+Vector2(-14,22);s.positions[2]=s.DUCT_LIGHT
    s.controlled=0
    await frames(5)
    await capture("c4-before")
    var origin:Vector2=s.positions[0]
    key_event(KEY_D,true);await frames(8)
    print("LABELS_NATIVE_INPUT focused=",lobby.session.focused," move=",lobby.session.movement(0)," delta=",s.positions[0]-origin)
    if not lobby.session.focused or s.positions[0].x<=origin.x:push_error("real input not accepted");quit(1);return
    key_event(KEY_D,false)
    await capture("c4-moved")
    # A second actual movement direction samples layout changes, without reseeding.
    key_event(KEY_A,true)
    for frame in range(12):
        await frames(1)
        if frame in [4,5,6]:await capture("c4-moving-%02d"%frame)
    key_event(KEY_A,false)
    await frames(2)
    tap_key(KEY_ESCAPE);await frames(2);await click_button("CombatPreview")
    b=lobby.arena.battle;b.story_encounter="reserve"
    tap_key(KEY_E);tap_key(KEY_SPACE);await frames(3)
    var driver=Driver.new(self,b)
    for frame in range(660):
        if frame in [120,300,480]:tap_key(KEY_TAB);switched+=1
        if frame in [15,16,17,160,161,162,330,331,332]:
            key_event(KEY_G,true);used_guard=used_guard or b.guarding
        else:driver.step_slot(0)
        driver.step_slot(1)
        if b.attacks.charging and b.attacks.charge_time>=0.48:key_event(KEY_J,false)
        await frames(1)
        record_visual("capture")
        if frame in [15,16,17,160,161,162,330,331,332]:await capture("combat-live-%03d"%frame)
        if b.phase=="clear":driver=await repeat_combat()
    key_event(KEY_G,false)
    meter=load("res://tests/m27_frame_meter.gd").new();root.add_child(meter)
    var started:int=Time.get_ticks_msec()
    var next_switch:int=started+7000
    while Time.get_ticks_msec()-started<61000:
        if Time.get_ticks_msec()>=next_switch:
            tap_key(KEY_TAB);switched+=1;next_switch+=7000
        driver.step_slot(0);driver.step_slot(1)
        if b.attacks.charging and b.attacks.charge_time>=0.48:key_event(KEY_J,false)
        await frames(1)
        record_visual("performance")
        if not lobby.session.focused:push_error("native focus lost during measurement");break
        if b.phase=="clear":driver=await repeat_combat()
    var report:Dictionary=meter.report();report["focus"]=lobby.session.focused
    report["renderer"]=RenderingServer.get_rendering_device().get_device_name() if RenderingServer.get_rendering_device() else "OpenGL compatibility"
    report["switches"]=switched;report["guard_seen"]=used_guard;report["attack_seen"]=used_attack;report["moving_samples"]=moved_frames
    report["label_overlap_samples"]=trace.filter(func(row):return row.overlaps>0).size()
    var file=FileAccess.open("res://labels-native-timeline.json",FileAccess.WRITE);file.store_string(JSON.stringify({"performance":report,"trace":trace,"feedback":feedback},"  "));file.close()
    var summary:Dictionary=report.duplicate();summary.erase("raw_render_ms");summary.erase("raw_physics_ms");summary.erase("raw_process_ms")
    print("M27_LABELS_NATIVE_PERFORMANCE ",JSON.stringify(summary))
    var accepted:bool=report.seconds>=60 and used_guard and used_attack and switched>0 and moved_frames>0 and report.focus
    meter.queue_free();driver=null;b=null
    lobby.queue_free();await frames(5)
    var deadline:int=Time.get_ticks_msec()+100
    while Time.get_ticks_msec()<deadline:await process_frame
    print("M27_LABELS_NATIVE: current-source bounded C4 fixture plus actual reserve encounter inputs")
    quit(0 if accepted else 1)
func capture(label:String)->void:
    await process_frame;await RenderingServer.frame_post_draw
    var file:String="res://labels-"+label+".png"
    print("LABELS_CAPTURE ",file," status=",root.get_texture().get_image().save_png(file))

func click_button(name:String)->void:
    var point:Vector2=root.get_final_transform()*lobby.get_node(name).get_global_rect().get_center()
    var motion:=InputEventMouseMotion.new();motion.position=point;Input.parse_input_event(motion);Input.flush_buffered_events()
    for down in [true,false]:
        var event:=InputEventMouseButton.new();event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;Input.parse_input_event(event);Input.flush_buffered_events();await frames(1)
    await frames(3)
func repeat_combat():
    drive(0,Vector2.ZERO);drive(1,Vector2.ZERO);key_event(KEY_G,false);key_event(KEY_J,false)
    tap_key(KEY_ESCAPE);await frames(2);await click_button("ReplayCourtyard")
    b=lobby.arena.battle;b.story_encounter="reserve";feedback_cursor=0
    tap_key(KEY_ENTER);await frames(2);tap_key(KEY_E);tap_key(KEY_SPACE);await frames(2)
    return Driver.new(self,b)
func record_visual(segment:String)->void:
    used_guard=used_guard or b.guarding
    used_attack=used_attack or b.attack_flash[0]>0 or b.attack_flash[1]>0
    if lobby.session.movement(0).length()>0 or lobby.session.movement(1).length()>0:moved_frames+=1
    for event in b.feedback_since(feedback_cursor):feedback.append({"sample":visual_index,"kind":event.kind,"role":event.role})
    feedback_cursor=b.feedback_id
    var badges:Array=[]
    for actor in lobby.arena.actors:badges.append({"role":actor.role,"at":str(actor.position),"offset":str(actor.caption_offset),"kind":actor.combat_kind,"t":actor.combat_progress,"guard":actor.guarding})
    trace.append({"sample":visual_index,"time_ms":Time.get_ticks_msec(),"segment":segment,"phase":b.phase,"wave":b.wave,"hp":b.hp.duplicate(),"focus":lobby.session.focused,"current_cat":b.current_cat,"poses":badges,"overlaps":lobby.arena.label_metrics.get("overlaps",-1),"enemy_modes":b.enemies.map(func(e):return e.mode),"enemies":b.enemies.map(func(e):return {"pos":str(e.pos),"aim":str(e.get("aim",e.pos)),"mode":e.mode}),"enemy_labels":str(lobby.arena.enemy_label_layout),"label_rects":str(lobby.arena.label_metrics.get("rects",[]))})
    visual_index+=1
