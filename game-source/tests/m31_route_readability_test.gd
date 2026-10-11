extends SceneTree
const Battle=preload("res://game/battle_state.gd")
const Arena=preload("res://game/arena.gd")
const Session=preload("res://input/session_state.gd")
var failed:=0
var checks:=0
func check(value:bool,label:String)->void:
    checks+=1
    if not value:failed+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func fixture(mode:String="dual")->RefCounted:
    var b=Battle.new()
    b.configure({"id":"reserve","encounter_revision":2,"mode":mode,"available_role_ids":[0,1,2],"selected_role_id":0,"current_cat":1})
    b._start_wave(1);b.enemies=b.enemies.filter(func(e):return e.kind=="armored")
    b.Space.STUMPS.clear();b.positions[0]=Vector2(430,410);b.positions[1]=Vector2(440,505)
    var e:Dictionary=b.enemies[0];e.pos=Vector2(810,625);e.direction=Vector2.RIGHT;e.mode="windup";e.timer=1.2;e.hit.clear()
    return b
func prediction_checks()->void:
    var b=fixture()
    check(b.has_method("rush_preview"),"windup exposes actual stopping contact instead of a generic arrow")
    if not b.has_method("rush_preview"):return
    var e:Dictionary=b.enemies[0]
    var before:=JSON.stringify({"result":b.result(),"enemies":b.enemies,"positions":b.positions,"hp":b.hp,"fx":b.fx})
    var p:Dictionary=b.rush_preview(e)
    check(p.opens_route and p.contact.kind=="route","clear locked rush marks the breakable branch")
    var contact_radius:float=p.contact.position.distance_to(p.contact.point)
    check(contact_radius>=49 and contact_radius<49.3,"preview uses physical enemy radius and precontact safety margin")
    check(JSON.stringify({"result":b.result(),"enemies":b.enemies,"positions":b.positions,"hp":b.hp,"fx":b.fx})==before,"preview cannot aim, damage, confirm or complete")
    var direction:Vector2=e.direction;b.positions[0]=Vector2(540,370);b.rush_preview(e)
    check(e.direction==direction,"moving a player does not retarget the locked rush")
    b=fixture();e=b.enemies[0];b.positions[0]=Vector2(870,625)
    p=b.rush_preview(e);check(p.opens_route and p.contact.kind=="route","an unshielded body does not stop the charge prediction")
    b._rush(e,0.48);check(b.route_open and b.hp[0]==2,"actual charge still hurts then passes the body and opens route")
    b=fixture();e=b.enemies[0];b.positions[0]=Vector2(885,625);b.facing[0]=Vector2.LEFT;b.guarding=true
    p=b.rush_preview(e);check(not p.opens_route and p.contact.kind=="shield","a prior shield suppresses the branch promise")
    b._rush(e,0.48);check(not b.route_open and e.opening=="shield","actual first shield keeps old opening behaviour")
    b=fixture();e=b.enemies[0];b.Space.STUMPS.assign([Vector2(905,625)])
    p=b.rush_preview(e);check(not p.opens_route and p.contact.kind=="stump","a prior stump suppresses the branch promise")
    b._rush(e,0.48);check(not b.route_open and e.opening=="stump","actual first stump keeps old opening behaviour")
    b=fixture();e=b.enemies[0];b._spawn("sprout",Vector2(905,625),false)
    p=b.rush_preview(e);check(not p.opens_route and p.contact.kind=="enemy","a prior enemy suppresses the branch promise")
    b._rush(e,0.48);check(not b.route_open and e.opening=="collision" and b.enemies[1].hp==3,"actual enemy collision still damages and interrupts")
    b=fixture();e=b.enemies[0];e.pos=Vector2(710,625)
    p=b.rush_preview(e);check(not p.opens_route and p.contact.is_empty(),"a branch beyond the real rush length is not promised")
    b=fixture();e=b.enemies[0];e.pos=Vector2(810,390)
    p=b.rush_preview(e);check(not p.opens_route and p.contact.get("surface","")=="fence","upper durable hedge is distinct from breakable branch")
    b=fixture();e=b.enemies[0];b.objective_enemy_id=e.id+99
    p=b.rush_preview(e);check(not p.opens_route,"a nonobjective hard shell cannot be shown opening the route")
    b=fixture();e=b.enemies[0];e.kind="thorn"
    p=b.rush_preview(e);check(not p.opens_route,"other charging kinds cannot promise to open")
    b=fixture();e=b.enemies[0];b._open_route("impact")
    p=b.rush_preview(e);check(p.is_empty(),"retreat has no live charge promise")
    b=fixture();e=b.enemies[0];e.mode="rush";e.timer=0.20
    p=b.rush_preview(e);check(not p.opens_route,"rush forecast shrinks to remaining travel time")
    b=fixture("solo");e=b.enemies[0];e.timer=0.01;b.positions[0]=Vector2(870,625);b.hp[0]=1
    p=b.rush_preview(e);check(not p.opens_route,"a last-heart body before the branch cannot promise a successful route")
    await_rush(b);check(not b.route_open and b.hp[0]==0,"per-physics rush kills the last-heart solo before the route")
    b=fixture("solo");e=b.enemies[0];e.timer=0.01;b.positions[0]=Vector2(870,625);b.hp[0]=1;b.invulnerable[0]=1.2
    p=b.rush_preview(e);check(p.opens_route,"invulnerability lasting past the projected body contact can still permit a route")
    await_rush(b);check(b.route_open and b.hp[0]==1,"per-physics protected last-heart body passes without damage")
    b=fixture("solo");e=b.enemies[0];e.timer=0.01;b.positions[0]=Vector2(870,625);b.hp[0]=1;b.dodge_time[0]=0.22;b.dodge_direction[0]=Vector2.UP
    p=b.rush_preview(e);check(not p.opens_route,"short dodge does not promise survival across unknown capped windup updates")
    await_rush(b);check(b.route_open and b.hp[0]==1,"per-physics dodging actor remains alive while the locked rush hits the branch")
    b=fixture("solo");e=b.enemies[0];e.timer=0.01;b.positions[0]=Vector2(870,625);b.hp[0]=1;b.invulnerable[0]=0.16
    p=b.rush_preview(e);check(not p.opens_route,"fading immunity cannot promise survival across both transition updates")
    await_rush(b,0.1);check(not b.route_open and b.hp[0]==0,"maximum capped physics updates expose the fading-immunity counterexample")
    b=fixture();e=b.enemies[0];e.timer=0.01;b.positions[0]=Vector2(870,625);b.hp[0]=1
    p=b.rush_preview(e);check(p.opens_route,"another actual living deployed partner preserves the possible route")
    await_rush(b);check(b.route_open and b.hp[0]==0 and b.hp[1]==3,"per-physics other partner remains alive after a body knockout")
    for edge in [{"start":Vector2(835.986,362.2806),"direction":Vector2(.375893,-.926663)},{"start":Vector2(794.8035,363.0348),"direction":Vector2(.702325,-.711856)}]:
        b=fixture();e=b.enemies[0];b.Space.STUMPS.assign([Vector2(620,500),Vector2(925,340)])
        e.pos=edge.start;e.direction=edge.direction;e.mode="rush";e.timer=0.48
        p=b.rush_preview(e)
        check(p.boundary_limited and p.contact.is_empty(),"exact edge counterexample never invents a stump from a bent clamped chord")
        check(absf(e.direction.cross((p.end-p.from).normalized()))<0.001,"edge-clipped forecast preserves the locked rush direction")
        for i in range(30):
            if e.mode!="rush":break
            e.timer-=.016;b._rush(e,.016)
        check(e.opening!="stump" and e.pos.y>=246,"actual .016-step edge path still has no invented stump impact")
func await_rush(b,delta:float=1.0/60)->void:
    for i in range(90):
        b.step(delta,Vector2.ZERO,Vector2.ZERO,true)
        if b.route_open or b.phase=="failed":break
func visual_state_checks()->void:
    var s=Session.new();s.single_player=true;s.keyboard_mode=true
    var host=Control.new();host.theme=Theme.new();host.theme.default_font=load("res://assets/fonts/CourtyardSans.ttf");root.add_child(host)
    var a=Arena.new(s);host.add_child(a);a.set_physics_process(false)
    a.configure({"id":"shell","encounter_revision":2,"mode":"solo","available_role_ids":[0,1,2],"selected_role_id":1,"current_cat":1,"title":"第四章 · 灯光躲起来了 · 检修路藤门"})
    a.battle._start_wave(1)
    for e in a.battle.enemies:
        if e.kind=="weaver":e.weave_break=2.2;e.mode="rest"
    a._refresh()
    await process_frame
    check(a.font.get_string_size(a.title_label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,22).x>275,"actual C4 shell title challenges the allotted header width")
    check(a.title_label.get_rect().end.x<=a.status_label.position.x,"actual long C4 title cannot expand into the combat status")
    check(a.title_label.clip_text and a.title_label.text_overrun_behavior==TextServer.OVERRUN_TRIM_ELLIPSIS,"overflow title retains an ellipsis instead of covering the status")
    var source_caption:=""
    for label in a.enemy_label_layout:
        if label.text.begins_with("织藤花"):source_caption=label.text
    check(source_caption.contains("护藤松脱") and not source_caption.contains("连藤断开"),"temporary interruption is labelled as shield vine loss, not permanent root break")
    check(not a.battle.route_open,"temporary shield loss does not invent the permanent route result")
    var script_path:="res://game/battle_route_view.gd"
    check(FileAccess.file_exists(script_path),"exit and tether view is available as read-only state")
    if FileAccess.file_exists(script_path):
        var view=load(script_path)
        var tether:Dictionary=view.root_tether(a.battle)
        check(tether.state=="bound","temporary shield loss keeps the gate root bound")
        var b=fixture();b._open_route("impact");b.positions[0]=b.EXIT+Vector2(-15,-24);b.positions[1]=b.EXIT+Vector2(-15,24)
        var badges:Array=view.exit_badges(b,true)
        check(badges.size()==2 and badges[0].key=="E" and badges[1].key=="空格","each keyboard player sees their own actual confirmation key")
        check(badges[0].state=="ready" and badges[1].state=="ready","arriving is shown separately from confirming")
        b.interact(0);badges=view.exit_badges(b,true)
        check(badges[0].state=="confirmed" and badges[1].state=="ready" and b.phase=="clear","P1 cannot confirm P2 and view shows the outstanding partner")
        b.interact(0);check(b.phase=="clear","repeated P1 confirm never returns without P2")
        b.positions[0]=Vector2(930,500);b.step(0.01,Vector2.ZERO,Vector2.ZERO,true);badges=view.exit_badges(b,true)
        check(badges[0].state=="away" and not b.confirmed[0],"walking away clears the visible individual confirmation")
        b.hp[1]=0;badges=view.exit_badges(b,true)
        check(badges[1].state=="down" and b.hp[1]==0,"down partner is shown without automatic rescue")
        badges=view.exit_badges(b,false);check(badges[0].key=="A" and badges[1].key=="A","each gamepad remains manual A")
        var solo=Battle.new();solo.configure({"id":"shell","encounter_revision":2,"mode":"solo","available_role_ids":[0,1,2],"selected_role_id":2,"current_cat":2,"cleared_segments":2,"route_open":true})
        check(view.exit_badges(solo,true).size()==1,"single-player exit does not demand an absent partner")
    s.single_player=false
    a.configure({"id":"reserve","encounter_revision":2,"mode":"dual","available_role_ids":[0,1,2],"selected_role_id":0,"current_cat":1,"title":"第四章 · 灯光躲起来了 · 树梯横枝"})
    a.battle._start_wave(1);a.battle._open_route("impact")
    a.battle.positions[0]=a.battle.EXIT+Vector2(-15,-24);a.battle.positions[1]=a.battle.EXIT+Vector2(-15,24);a.battle.interact(0);a._refresh()
    await process_frame
    check(a.title_label.get_rect().end.x<=a.status_label.position.x and a.status_label.text.contains("路已打开"),"long C4 reserve title leaves the actual retreat status visible")
    a.free();host.free()
func run()->void:
    if OS.get_user_data_dir().get_file()!="DuoduoCatsCourtyard-qa-m31-player":quit(2);return
    prediction_checks();await visual_state_checks()
    print("M31_ROUTE_READABILITY: ",checks," checks, ",failed," failed");quit(1 if failed else 0)
