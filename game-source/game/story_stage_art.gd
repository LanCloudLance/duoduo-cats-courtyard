extends RefCounted
## State-driven story presentation. Geometry belongs to the chapter state.
const NPC = preload("res://assets/visual-m28/npc-states.png")
const FOUR_STAGES = preload("res://assets/visual-m28/chapter-four-stages.png")
const PARTS=preload("res://assets/visual-m28/mechanism-states.png")
const PAPERS=preload("res://assets/visual-m28/journey-papers.png")
const EQUIPMENT=preload("res://assets/visual-m28/equipment-states.png")
const EQUIPMENT_REGIONS=[Rect2(24,104,407,326),Rect2(452,16,406,417),Rect2(912,17,409,419),Rect2(1336,78,416,376),Rect2(20,459,422,386),Rect2(459,459,423,386),Rect2(1050,452,186,387),Rect2(1457,455,281,383)]
const OLD_PARTS=preload("res://assets/visual-m26/mechanisms.png")
const FLOOR=preload("res://assets/visual-m26/floor-pieces.png")
const INK = Color("4c4030")
const WOOD = Color("9b754c")
const COPPER = Color("bc9860")
const EDGE = Color("e7c991")
const LIGHT = Color("fce6a0")
const MINT = Color("90cbb8")

static func data(state)->Dictionary:
    return state.presentation() if state.has_method("presentation") else {}

static func social_transition_active(state)->bool:
    return state.has_method("social_transition_active") and state.social_transition_active()

static func dialog_active(state)->bool:
    return state.has_method("dialogue_active") and state.dialogue_active()

static func social_kind(state,role:int)->String:
    var event:Dictionary=data(state).get("social",{})
    if not event.is_empty() and (event.get("role",-1)==role or role in event.get("participants",[])):
        var kind:String=event.get("kind","")
        if kind in ["sit","rest","home","relax"]:return "rest"
        if kind=="receive":return "greet"
        if kind in ["pet","reunion","care","wipe","greet","hug","gift","equip","paw"]:return "pet" if role==0 else "greet" if role==1 else "pet"
    var action:String=state.actions[role] if role<state.actions.size() else ""
    if action=="sit":return "rest"
    if action in ["pet","sniff"]:return "pet"
    if action=="paw":return "greet"
    return ""

static func npc(v:Node2D,kind:int,pose:int,feet:Vector2,height:float,clock:float)->void:
    # Equal atlas cells; tiny breathing never changes the interaction anchor.
    var region:=Rect2(clampi(pose,0,2)*410,clampi(kind,0,2)*426,410,426)
    var width:=height*410.0/426.0
    var breathe:=sin(clock*1.8+kind)*0.8
    var rect:=Rect2(feet-Vector2(width*.5,height)+Vector2(0,breathe),Vector2(width,height))
    v.draw_texture_rect_region(NPC,rect,region)

static func backdrop_four(v:Node2D,room:String)->bool:
    if room=="market":return false
    var region:=Rect2(0,0 if room=="interior" else 794,992,792)
    v.draw_texture_rect_region(FOUR_STAGES,Rect2(0,0,1280,800),region)
    return true

static func panel(v:Node2D,r:Rect2,fill:Color=WOOD)->void:
    var bevel:=minf(5,minf(r.size.x,r.size.y)*.3)
    var p:=PackedVector2Array([r.position+Vector2(bevel,0),Vector2(r.end.x-bevel,r.position.y),Vector2(r.end.x,r.position.y+bevel),r.end-Vector2(0,bevel),r.end-Vector2(bevel,0),Vector2(r.position.x+bevel,r.end.y),Vector2(r.position.x,r.end.y-bevel),r.position+Vector2(0,bevel)])
    v.draw_colored_polygon(p,INK)
    var inset:=r.grow(-3)
    v.draw_rect(inset,fill,true)
    v.draw_line(inset.position+Vector2(2,2),Vector2(inset.end.x-2,inset.position.y+2),fill.lightened(.25),1.5,true)
    for pnt in [r.position+Vector2(7,7),Vector2(r.end.x-7,r.position.y+7),r.end-Vector2(7,7),Vector2(r.position.x+7,r.end.y-7)]:
        v.draw_circle(pnt,2.2,COPPER);v.draw_circle(pnt-Vector2(.5,.5),.7,EDGE)

static func latch(v:Node2D,r:Rect2,locked:bool,angle:float)->void:
    v.draw_set_transform(r.get_center(),angle)
    v.draw_texture_rect_region(OLD_PARTS,Rect2(-r.size*.5,r.size),Rect2(1010,24,208,290))
    var y:float=r.size.y*.17
    var left:float=-r.size.x*.15 if locked else r.size.x*.1
    v.draw_line(Vector2(left,y),Vector2(left+r.size.x*.43,y),Color("664827"),r.size.y*.17,true)
    v.draw_line(Vector2(left,y-1),Vector2(left+r.size.x*.43,y-1),EDGE,r.size.y*.1,true)
    if locked:v.draw_circle(Vector2(-r.size.x*.02,-r.size.y*.13),r.size.x*.065,MINT)
    v.draw_set_transform(Vector2.ZERO)

static func painted(v:Node2D,index:int,r:Rect2,angle:=0.0,tint:=Color.WHITE)->void:
    var region:=Rect2((index%4)*362,floori(index/4.0)*362,362,362)
    v.draw_set_transform(r.get_center(),angle)
    v.draw_texture_rect_region(PARTS,Rect2(-r.size*.5,r.size),region,tint)
    v.draw_set_transform(Vector2.ZERO)

static func receiver(v:Node2D,r:Rect2,lit:bool,angle:=0.0)->void:
    var visual:=Rect2(r.get_center()-Vector2(r.size.x*.66,r.size.y*.65),r.size*1.3)
    painted(v,0,visual,angle)
    if lit:
        var glow:=visual.get_center()-Vector2(0,visual.size.y*.08)
        v.draw_circle(glow,visual.size.x*.25,Color(LIGHT,.3));v.draw_circle(glow,visual.size.x*.16,Color(LIGHT,.5))

static func pressure_plate(v:Node2D,r:Rect2,pressed:bool)->void:
    var visual:=r;visual.position.y-=r.size.y*.18;visual.size.y*=1.28
    painted(v,1,visual,0,Color("cdd6a4") if pressed else Color.WHITE)

static func handle(v:Node2D,r:Rect2,loaded:bool)->void:
    var height:=r.size.y*1.8
    painted(v,2,Rect2(r.position-Vector2(3,height-r.size.y),Vector2(r.size.x+6,height)),0,Color("eaddae") if loaded else Color.WHITE)

static func equipment(v:Node2D,index:int,r:Rect2)->void:
    v.draw_texture_rect_region(EQUIPMENT,r,EQUIPMENT_REGIONS[index])

static func tool_rack(v:Node2D,r:Rect2,stored:bool,cat_only:=false)->void:
    equipment(v,4 if stored and not cat_only else 5,r)
    if cat_only and stored:
        v.draw_texture_rect_region(EQUIPMENT,Rect2(r.position+Vector2(r.size.x*.28,r.size.y*.18),r.size*Vector2(.48,.62)),Rect2(265,535,152,222))

static func sword(v:Node2D,p:Vector2,size:float)->void:
    var tip:=p+Vector2(0,-45*size)
    v.draw_colored_polygon(PackedVector2Array([p+Vector2(-5,-4)*size,tip,p+Vector2(5,-4)*size]),EDGE)
    v.draw_polyline(PackedVector2Array([p+Vector2(-5,-4)*size,tip,p+Vector2(5,-4)*size]),INK,2,true)
    v.draw_line(p+Vector2(0,-2),p+Vector2(0,14)*size,WOOD,5*size,true)
    v.draw_line(p+Vector2(-12,0)*size,p+Vector2(12,0)*size,COPPER,4*size,true)

static func toolbox(v:Node2D,r:Rect2,opened:bool,empty:bool)->void:
    var visual:=Rect2(r.position-Vector2(0,r.size.y*.4 if opened else 0),r.size*Vector2(1,1.4 if opened else 1))
    equipment(v,2 if opened and empty else 1 if opened else 0,visual)

static func hatch(v:Node2D,r:Rect2,open:bool)->void:
    var visual:=Rect2(r.position-Vector2(r.size.x*.13,r.size.y*.45 if open else r.size.y*.1),r.size*Vector2(1.28,1.7 if open else 1.15))
    painted(v,11 if open else 10,visual)

static func keepsake(v:Node2D,p:Vector2,size:=1.0)->void:
    equipment(v,6,Rect2(p-Vector2(11,24)*size,Vector2(22,43)*size))

static func discoveries(v:Node2D,ids:Array,_table:Vector2)->void:
    # The original room's left writing desk, with an irregular small stack of
    # drawings rather than a HUD-like row of fabricated reward tokens.
    var papers:Dictionary={
        "three_map":[Rect2(143,188,52,33),Rect2(35,100,609,438),-.09],
        "two_cart":[Rect2(173,202,45,22),Rect2(654,178,581,324),.12],
        "four_stall":[Rect2(131,200,28,33),Rect2(99,578,480,574),-.18],
        "four_view":[Rect2(197,194,38,31),Rect2(675,622,522,510),.08]}
    for id in ["three_map","four_view","two_cart","four_stall"]:
        if not id in ids:continue
        var item:Array=papers[id];var rect:Rect2=item[0]
        v.draw_set_transform(rect.get_center(),float(item[2]))
        v.draw_texture_rect_region(PAPERS,Rect2(-rect.size*.5,rect.size),item[1])
        v.draw_set_transform(Vector2.ZERO)
    if "one_nightlight" in ids:equipment(v,7,Rect2(208,155,27,41))
    if "wood_lamp" in ids:keepsake(v,Vector2(243,236),.8)

static func home_pose_position(point:Vector2,role:int,kind:String)->Vector2:
    # Interaction feet are in front of the furniture. Only the seated tableau
    # projects onto the original sofa cushion; movement resumes at those feet.
    if kind=="sit":return [Vector2(394,275),Vector2(469,278),Vector2(313,278)][role]
    return point

static func draw_paths(v:Node2D,presentation:Dictionary)->void:
    if presentation.get("phase","") in ["home","complete","farewell","approach"]:return
    for path in presentation.get("paths",[]):
        var id:String=path.get("id","")
        if id not in ["outer_steps","outer_path","outer_end_ladder","cart_path","far_platform","service_shortcut","service_front"]:continue
        var points:PackedVector2Array=PackedVector2Array(path.get("points",[]))
        if points.size()<2:continue
        var width:float=path.get("width",24.0);var mode:String=path.get("state","closed")
        var available:bool=mode in ["permanent","locked","open","temporary"]
        for i in range(1,points.size()):
            var a:=points[i-1];var b:=points[i]
            var length:=a.distance_to(b)
            var center:Vector2=(a+b)*.5
            v.draw_set_transform(center,(b-a).angle())
            v.draw_texture_rect_region(FLOOR,Rect2(-length*.5,-width*.5,length,width),Rect2(96,132,855,302),Color.WHITE if available else Color("677461"))
            v.draw_line(Vector2(-length*.5,-width*.5),Vector2(length*.5,-width*.5),Color("63472c"),3,true)
            v.draw_line(Vector2(-length*.5,width*.5),Vector2(length*.5,width*.5),Color("b09160"),3,true)
            v.draw_set_transform(Vector2.ZERO)
        if not available:
            var stop:=points[points.size()/2];var axis:=(points[-1]-points[0]).normalized().orthogonal()
            v.draw_line(stop-axis*width*.55,stop+axis*width*.55,INK,9,true)
            v.draw_line(stop-axis*width*.55,stop+axis*width*.55,COPPER,5,true)
        elif mode=="temporary":
            for end in [points[0],points[-1]]:v.draw_circle(end,5,LIGHT)

static func draw_mechanisms(v:Node2D,presentation:Dictionary)->void:
    var phase:String=presentation.get("phase","")
    var room:String=presentation.get("room","")
    for m in presentation.get("mechanisms",[]):
        var id:String=m.get("id","");var p:Vector2=m.get("position",Vector2.ZERO)
        var loaded:bool=bool(m.get("load",false));var lit:bool=bool(m.get("lit",false))
        var connection:String=m.get("connection","");var angle:float=float(m.get("angle",0.0))
        if phase in ["home","complete","farewell","approach"] and id not in ["sofa_ball"]:continue
        match id:
            "outer_bench":
                handle(v,Rect2(p-Vector2(31,18),Vector2(62,34)),loaded)
            "outer_ratchet","prep_latch","far_lock":latch(v,Rect2(p-Vector2(21,30),Vector2(42,49)),loaded,angle*.15)
            "prep_handle":handle(v,Rect2(p-Vector2(33,18),Vector2(66,36)),loaded)
            "cart_hook":
                equipment(v,3,Rect2(p-Vector2(42,51),Vector2(84,66)))
                if connection=="open":v.draw_arc(p+Vector2(-20,-4),8,0,PI,16,MINT,2,true)
            "map_back":
                v.draw_set_transform(p,angle)
                panel(v,Rect2(-34,-26,68,46),Color("d6c896"))
                var trace:Color=Color("537868") if lit or connection=="read" else Color("bbb18b")
                v.draw_polyline(PackedVector2Array([Vector2(-26,10),Vector2(-11,-9),Vector2(5,6),Vector2(26,-15)]),trace,2,true)
                v.draw_circle(Vector2(26,-15),4,trace)
                v.draw_set_transform(Vector2.ZERO)
                if lit:v.draw_line(p-Vector2(80,7),p+Vector2(36,-7),Color(LIGHT,.55),3,true)
            "source_lift":
                v.draw_line(p+Vector2(-29,23),p+Vector2(-29,-65),INK,7,true)
                for y in range(-60,20,13):v.draw_line(p+Vector2(-33,y),p+Vector2(-25,y),COPPER,2,true)
                handle(v,Rect2(p-Vector2(21,4),Vector2(42,19)),connection=="upper")
            "near_slot","far_slot":
                pressure_plate(v,Rect2(p-Vector2(35,17),Vector2(70,34)),loaded)
                for x in [-39,39]:panel(v,Rect2(p+Vector2(x-4,-31),Vector2(8,38)),COPPER)
                if connection=="selected":v.draw_arc(p,42,PI*.1,PI*.9,22,LIGHT,2,true)
            "load_frame":
                if phase in ["unjam","withdraw"]:
                    v.machine_arm(p+Vector2(-67,0).rotated(angle),p+Vector2(67,0).rotated(angle),18)
            "work_isolator":
                painted(v,3,Rect2(p-Vector2(31,58),Vector2(62,67)))
                var end:=p+Vector2(21,-50) if connection=="isolated" else p+Vector2(21,-22)
                v.draw_line(p+Vector2(18,-30),end,Color("6e4826"),8,true);v.draw_line(p+Vector2(18,-30),end,EDGE,4,true)
            "pin_rack":painted(v,8 if loaded else 9,Rect2(p-Vector2(29,63),Vector2(58,73)))
            "left_socket","right_socket":
                var frame:int=7 if connection=="locked" else 6 if loaded else 5 if connection=="raised" else 4
                painted(v,frame,Rect2(p-Vector2(37,59),Vector2(74,71)))
            "sofa_ball":
                if connection=="hidden":
                    v.draw_arc(Vector2(p.x,313),8,PI,TAU,14,Color("b98164"),5,true)
            "night_lamp":
                if connection!="taken":
                    v.draw_line(p+Vector2(0,3),p-Vector2(0,55),WOOD,5,true)
                    keepsake(v,p-Vector2(0,40),1.15)
                    if loaded:v.draw_colored_polygon(PackedVector2Array([p+Vector2(-19,-65),p+Vector2(19,-65),p+Vector2(13,-43),p+Vector2(-13,-43)]),Color("8ead86"))
                    if lit:v.draw_circle(p-Vector2(0,44),29,Color(LIGHT,.19))
                else:v.draw_line(p+Vector2(-15,0),p+Vector2(15,0),WOOD,4,true)
            "flower_cloth":
                if not loaded:
                    v.draw_colored_polygon(PackedVector2Array([p+Vector2(-11,1),p+Vector2(15,-3),p+Vector2(19,16),p+Vector2(-8,20)]),Color("9ab58a"))
                    for offset in [Vector2(-2,7),Vector2(9,10)]:v.draw_circle(p+offset,2,EDGE)
            "market_door","view_door":
                var visiting:String=presentation.get("visit_room","")
                if room!="interior" and connection!="return":continue
                if room=="interior" and phase not in ["meet","investigate","test","offer","home_offer","rest"]:continue
                var frame:=Rect2(p-Vector2(31,80),Vector2(62,91))
                v.prop(7,frame)
                v.draw_line(p+Vector2(-14,-25),p+Vector2(14,-25),EDGE,3,true)
                var end:=p+Vector2(-14,-25) if connection=="return" else p+Vector2(14,-25)
                v.draw_line(end,end+Vector2(8 if connection=="return" else -8,-7),EDGE,3,true)
                v.draw_line(end,end+Vector2(8 if connection=="return" else -8,7),EDGE,3,true)
                v.draw_circle(p+Vector2(20,-33),3,COPPER)
            "stall_lamp","view_lamp","reserve_lamp":
                if (id=="stall_lamp" and room!="market") or (id=="view_lamp" and room!="exterior") or (id=="reserve_lamp" and room!="interior"):continue
                if not lit:
                    v.draw_arc(p,14,0,TAU,20,COPPER.darkened(.25),5,true)
                    continue
                v.lamp(p,lit)
                if lit:
                    for i in range(3):v.draw_circle(p+Vector2(11,-38),44+i*15,Color(LIGHT,.025))
                    if id=="stall_lamp":
                        panel(v,Rect2(p+Vector2(-40,18),Vector2(90,28)),Color("687e5b"))
                        v.draw_circle(p+Vector2(8,30),8,EDGE)
                    if id=="view_lamp":
                        for i in range(4):v.draw_circle(p+Vector2(-95-i*29,-75-i*12),3,Color(LIGHT,.75-i*.12))

static func support_pin(v:Node2D,p:Vector2)->void:
    v.draw_line(p-Vector2(0,12),p+Vector2(0,9),INK,11,true)
    v.draw_line(p-Vector2(0,12),p+Vector2(0,9),EDGE,6,true)
    v.draw_arc(p-Vector2(0,13),7,0,TAU,18,COPPER,4,true)

static func draw_four(v:Node2D,s,presentation:Dictionary)->void:
    var room:String=presentation.get("room","market" if s.phase=="market" else "exterior" if s.phase in ["exterior","battle_two"] else "interior")
    if room=="market":
        npc(v,1,1 if s.cover_carried else 2 if s.stall_seen else 0,presentation.get("merchant_position",Vector2(182,290)),120,s.clock)
        if s.phase=="market":v.pit(s.PIT)
        for yy in range(338,429,19):
            panel(v,Rect2(268,yy,55,13),WOOD if s.market_beam else WOOD.darkened(.35))
        if not s.cloth and not s.cover_carried:
            var point:Vector2=s.COVER if s.cover_hooked else Vector2(220,365)
            v.support_prop(2,Rect2(point-Vector2(29,40),Vector2(58,48)))
        if s.cover_carried:
            v.support_prop(2,Rect2(s.positions[1]-Vector2(21,45),Vector2(42,35)))
        v.prop(5,Rect2(s.HOOK-Vector2(21,42),Vector2(42,50)))
        pressure_plate(v,Rect2(s.CATCH-Vector2(32,10),Vector2(64,22)),s.cover_carried)
        v.lamp(s.MARKET_LIGHT,s.market_beam)
        if s.market_beam:v.draw_line(s.MARKET_LIGHT-Vector2(0,35),s.COVER,LIGHT,5,true)
    elif room=="exterior":
        # A real work platform and its support, separate from the market stage.
        for x in [940,1140]:
            v.machine_arm(Vector2(x+5,280),Vector2(x+5,455),14);v.machine_arm(Vector2(x+5,420),Vector2(1040,345),9)
        v.prop(11,Rect2(970,226,176,145))
        if s.patch_braced or s.latch_fixed or s.shell_fixed:v.prop(12,Rect2(977,229,162,137),0 if s.shell_fixed or s.latch_fixed else sin(s.clock*6)*.02)
        latch(v,Rect2(s.LATCH-Vector2(18,28),Vector2(36,49)),s.latch_fixed,0)
        v.lamp(s.SEAM_LIGHT,s.seam_seen)
        if s.seam_seen:v.draw_line(s.SEAM_LIGHT-Vector2(0,35),Vector2(1050,254),LIGHT,4,true)
        if not s.shell_fixed:
            for i in range(5):
                var p:=Vector2(944+fposmod(s.clock*55+i*32,210),244+i*22)
                v.draw_line(p,p+Vector2(20,-3),Color(.75,.87,.85,.35),1.5,true)
        else:
            v.draw_line(Vector2(1007,264),Vector2(1092,264),EDGE,3,true)
        npc(v,0,1,Vector2(660,305),111,s.clock)
    else:
        npc(v,0,2 if s.inward_verified else 1 if s.pulse_active else 0,s.ALIGHT,115,s.clock)
        # The testing rig is a physical copper manifold, not a picture of a mirror.
        v.prop(0,Rect2(596,236,182,101))
        receiver(v,Rect2(s.DUCT-Vector2(18,25),Vector2(36,45)),s.duct_seen)
        v.gear(s.BRANCH,s.clock*.05 if not s.branch_seen else 0,24)
        v.support_prop(3,Rect2(s.BRANCH-Vector2(28,43),Vector2(56,48)))
        handle(v,Rect2(s.ARROWS-Vector2(34,20),Vector2(68,37)),s.route_split)
        v.lamp(s.DUCT_LIGHT,s.trial_lit())
        v.prop(11,Rect2(974,249,123,103))
        if s.shell_fixed:v.prop(12,Rect2(974,249,123,103))
        if s.has_method("draw_trial"):s.draw_trial(v)
        if s.lantern_offered:
            if not s.reserve_retained:
                v.draw_texture_rect_region(v.HOME,Rect2(s.HOME-Vector2(36,79),Vector2(72,95)),Rect2(190,100,560,600))
                v.prop(7,Rect2(s.HOME-Vector2(51,110),Vector2(102,132)))
            else:
                toolbox(v,Rect2(s.HOME-Vector2(32,46),Vector2(64,45)),false,false)
                v.draw_circle(s.HOME-Vector2(0,34),5,MINT)
        if s.phase in ["rest","complete"]:
            panel(v,Rect2(s.REST-Vector2(70,27),Vector2(140,20)));v.lamp(s.REST-Vector2(0,37),true)
    draw_paths(v,presentation);draw_mechanisms(v,presentation)
    if presentation.get("lamp_dest","")=="carried":
        var carried:Vector2=presentation.get("lamp_position",s.positions[0])
        keepsake(v,carried,.95)
        v.draw_circle(carried,23,Color(LIGHT,.14))

static func social_items(v:Node2D,state,elapsed:float)->void:
    var social:Dictionary=data(state).get("social",{})
    if social.is_empty():return
    var kind:String=social.get("kind","")
    var target:Vector2=social.get("target",state.positions[0])
    if kind=="receive":
        var from:Vector2=target-Vector2(0,64)
        var to:Vector2=state.positions[0]+Vector2(27,-55)
        var point:=from.lerp(to,smoothstep(0.0,1.0,minf(elapsed/.8,1.0)))
        var first_chapter:bool=state.get_script().resource_path.ends_with("chapter_one_state.gd")
        if first_chapter and not state.nightlight_taken:
            sword(v,point,.7)
            v.draw_circle(point+Vector2(21,9),13,INK);v.draw_circle(point+Vector2(21,9),10,WOOD);v.draw_arc(point+Vector2(21,9),8,0,TAU,18,EDGE,2,true)
        else:keepsake(v,point,1.0)
    elif kind=="pet" and state.get_script().resource_path.ends_with("chapter_five_state.gd") and state.phase=="home" and target.distance_to(state.HOME_BOWL)<90:
        var hand:Vector2=target+Vector2(-10+sin(elapsed*5)*4,-15)
        var cloth:=PackedVector2Array([hand+Vector2(-12,-5),hand+Vector2(9,-9),hand+Vector2(14,5),hand+Vector2(-7,10)])
        v.draw_colored_polygon(cloth,Color("e9dfbd"));v.draw_polyline(cloth,Color("aa9e7a"),1.5,true)
