extends "res://game/story_chapter_base.gd"
const DUCT := Vector2(365,560)
const DOOR_LAMP := Vector2(395,415)
const WINDOW := Vector2(405,295)
const INDOOR_PLATE := Vector2(540,410)
const REUNION := Vector2(545,440)
const EQUIPMENT := Vector2(590,305)
const LIGHT_STAND := Vector2(645,445)
const BOARD := Vector2(665,305)
const LOCK := Vector2(785,425)
const NARROW := Vector2(925,555)
const RIG := Vector2(925,310)
const SEARCH_STAND := Vector2(920,425)
const MAP := Vector2(1080,305)
var wick_found := false
var wick_ready := false
var wick_fitted := false
var door_angle := 0
var npc_called := false
var npc_elapsed := 0.0
var door_open := false
var light_equipped := false
var beam_held := false
var beam_direction := Vector2.RIGHT
var board_angle := 0
var cat_lock := false
var bridge_locked := false
var light_released := false
var narrow_open := false
var rig_ready := false
var exit_revealed := false
func _init()->void:
    chapter=3;chapter_key="chapter-three";title="第三章 · 这次一起走";phase="door"
    positions=[Vector2(240,410),Vector2(250,520),Vector2(530,300)]
    say("朵朵：圆圆就在里面。检修槽只通外墙灯座，我们先找找门为什么没亮。")
func walkable(p:Vector2,role:int)->bool:
    if not super.walkable(p,role):return false
    if Rect2(310,505,115,105).has_point(p) and role!=1:return false
    if p.x>=450 and p.x<480:return door_open and p.y>=375 and p.y<=475
    if p.x>=700 and p.x<855:
        return p.y>=385 and p.y<=465 and (bridge_locked or (role==1 and beam_active()))
    if p.x>=980 and p.x<1005:
        return (exit_revealed and p.y>=270 and p.y<=355) or (role==1 and narrow_open and p.y>=520 and p.y<=595)
    return true
func follow_allowed(role:int,p:Vector2)->bool:
    return walkable(p,role) and not (p.x>=700 and p.x<855 and not bridge_locked)
func beam_active()->bool:
    return beam_held and light_equipped and near(2,LIGHT_STAND,48) and beam_direction.dot(Vector2.RIGHT)>0.8
func target(role:int)->String:
    if near(role,DUCT,50):return "duct"
    if near(role,DOOR_LAMP,52):return "door_lamp"
    if near(role,WINDOW,52):return "window"
    if not joined and near(role,REUNION,68):return "reunion"
    if near(role,EQUIPMENT,40):return "equipment"
    if near(role,BOARD,40):return "board"
    if near(role,LIGHT_STAND,48):return "light"
    if near(role,LOCK,48):return "lock"
    if near(role,NARROW,52):return "narrow"
    if near(role,RIG,52):return "rig"
    if near(role,SEARCH_STAND,50):return "search"
    if near(role,MAP,65):return "map"
    return ""
func interact(role:int)->void:
    if role not in available_roles() or finished or action_time[role]>0:return
    var item:=target(role)
    act(role,"inspect")
    match item:
        "duct":
            if role!=1:say("朵朵：这个外墙检修槽只有团团能进去。它不通室内。");return
            wick_found=true;say("团团叼出一支备用灯芯。把它带回外侧灯座。",1)
        "door_lamp":
            if role==1 and wick_found and not wick_ready:
                wick_ready=true;say("团团把灯芯放在外部灯座旁，等朵朵装回去。");return
            if role!=0:say("团团望向朵朵，灯座的卡槽需要她装好。");return
            if not wick_ready:say("灯座里缺了一支灯芯。导光板现在没有光源。");return
            if not wick_fitted:
                wick_fitted=true;say("灯芯装好了。转动门外导光板，让光束接到门锁上的铜片。");return
            door_angle=(door_angle+1)%4
            say("门锁轻轻动了一下，室内的启动踏板仍没有压下。" if door_angle==1 else "光束偏离了门锁的铜片。")
        "window":
            if role!=0:say("圆圆隔着窗蹭了蹭团团。等朵朵指给它看室内踏板。");return
            if not wick_fitted or door_angle!=1:say("朵朵：先让门边的光照准铜片，室内踏板才会亮。");return
            if not npc_called:
                npc_called=true;phase="call";say("朵朵指向室内踏板：去那边。对，就是那个圆圆的地方。圆圆先蹭蹭手，再走过去。",1)
            else:say("圆圆听见朵朵的指引，正去踩室内踏板。")
        "reunion":
            if role!=0 or not door_open:return
            if positions[0].x<480 or positions[1].x<480:say("朵朵：团团，我们先进门，再一起抱抱圆圆。");return
            if not exit_gather(REUNION):return
            joined=true;phase="equipment";positions[2]=Vector2(570,455)
            say("朵朵摸摸圆圆的爪子，抱住它：以后出门，等我们一起，好不好？团团挤回腿边。圆圆正式入队，可以切换两只猫了。",2)
        "equipment":
            if role!=0 or not joined:say("工具架上挂着小伙伴背带和定光扣。");return
            light_equipped=true;phase="walkway";say("朵朵给圆圆装上定光扣。站内备用光给它补充能量：在灯座旁选好方向，再互动保持；走动或再次互动就收光。",2)
        "light":
            if role!=2 or not light_equipped:say("这个安全灯座供圆圆展开定光扣。");return
            if beam_held:release_light();return
            beam_direction=facing[2];beam_held=true;act(2,"light")
            say("圆圆稳稳保持光束。" if beam_active() else "圆圆照向了另一边，暗廊里的踏板仍然看不清。")
        "board":
            if role!=0:say("外侧导光板需要朵朵转动。");return
            board_angle=(board_angle+1)%4;say("导光板转动了。观察光束与桥尾的接收槽。")
        "lock":
            if role!=1 or not beam_active():say("暗廊里的精密卡扣，需要团团在稳定照明下拨开。");return
            cat_lock=true;say("团团拨开卡扣。还要让外侧导光板对准桥尾，桥才会锁定。",1)
        "narrow":
            if role!=1 or not bridge_locked:say("低处的窄道门，有一个爪钩能拉住的小环。");return
            narrow_open=true;act(1,"hook");say("团团拉开检修窄道，松出的灯架零件滑到朵朵这边。",1)
        "rig":
            if role!=0 or not narrow_open:say("灯架缺了支脚，检修窄道里能看见它。");return
            rig_ready=true;say("朵朵搭好灯架。上方墙面有旧光槽，请圆圆主动换个方向照一照。",1)
        "search":
            if role!=2 or not light_equipped or not rig_ready:say("先让团团开窄道、朵朵搭好这边的灯架。");return
            beam_direction=facing[2];act(2,"light",0.7)
            if beam_direction.dot(Vector2.UP)>0.8:
                exit_revealed=true;phase="map";say("圆圆向上照出真正出口，接收槽把出口永久锁住。三位可以一起上楼了。",2)
            else:say("光照见普通墙面。墙上的旧光槽伸向上方。")
        "map":
            if role!=0 or not exit_revealed:return
            if not light_released:say("朵朵：桥已经锁稳，先请圆圆主动收回保持的光，再一起看地图。");return
            for member in available_roles():
                if positions[member].x<1005:say("朵朵：从上方出口过来吧，我们三位一起看地图。");return
            if not exit_gather(MAP):return
            finished=true;phase="complete";extras={"joined":true,"fixed_light":true,"inward_route":true}
            say("地图上的光点全倒流向森林中央。朵朵把家门路牌放近地图：不是没有光，是光都往里面去了。我们去灯树送光台看看。",2)
        _:say("朵朵：我们三位各有自己的工具。看看光路、卡扣和导光板。")
    update_bridge()
func release_light()->void:
    beam_held=false;actions[2]="";light_released=bridge_locked
    say("圆圆主动收回定光扣，跟上伙伴。固定好的桥仍然牢固。" if bridge_locked else "圆圆收光了。团团先回到固定台。")
func tool(role:int)->void:
    if role==2 and joined and light_equipped and (beam_held or (bridge_locked and not light_released)):
        release_light();recover_walkway()
    else:request_hint()
func update_bridge()->void:
    if not bridge_locked and beam_active() and cat_lock and board_angle==1:
        bridge_locked=true;phase="exit";say("导光板、卡扣和稳定光束接通，暗廊的机械桥永久锁定。请圆圆主动收光，再出发。",2)
func recover_walkway()->void:
    if not bridge_locked and not beam_active() and positions[1].x>=700 and positions[1].x<855:
        positions[1]=Vector2(665,440);say("照明中断，团团退回固定台。已拨开的卡扣会保留。",3)
func step(dt:float,a:Vector2,b:Vector2,enabled:bool)->void:
    super.step(dt,a,b,enabled)
    if not enabled or not is_finite(dt) or dt<=0 or finished:return
    if npc_called and not door_open:
        npc_elapsed+=minf(dt,0.05)
        positions[2]=Vector2(530,300).lerp(INDOOR_PLATE,minf(1,npc_elapsed/1.8))
        if npc_elapsed>=1.8 and wick_fitted and door_angle==1:
            door_open=true;phase="reunion";say("圆圆坐在亮起的室内踏板上，门缓缓打开。朵朵和团团可以进去了。",2)
    if beam_held and actions[2]!="light":
        beam_held=false;say("圆圆移动后收起光束。固定桥不会消失；保持任务需要主动收光来结束。")
    update_bridge();recover_walkway()
func objective()->String:
    if not wick_found:return "从外墙检修槽找回灯芯"
    if not wick_fitted:return "团团送回灯芯，朵朵装好外侧灯座"
    if not door_open:return "调整门外导光板，再由朵朵隔窗呼唤圆圆"
    if not joined:return "朵朵和团团进门，与圆圆重逢"
    if not light_equipped:return "给圆圆穿上工具架上的定光扣"
    if not bridge_locked:return "圆圆定光、团团拨扣、朵朵调板，修好试灯廊"
    if not light_released:return "桥已永久锁定，请圆圆主动收光跟上"
    if not exit_revealed:return "团团开窄道，朵朵搭灯架，圆圆寻找真正出口"
    return "三位一起在地图前确认灯树路线"
func request_hint()->void:
    hints+=1
    if not joined:say("检修槽只通外部灯座。团团叼出并送回灯芯；朵朵装好后将板向右，再到低窗明确叫圆圆去踏板。")
    elif not bridge_locked:say("圆圆站安全灯座，面向右边互动保持。团团走亮起的廊道拨扣，朵朵把外侧板转向右。")
    else:say("用圆圆再次互动或工具键主动收光。过桥后团团拉开低门、朵朵搭灯架，圆圆在新灯座面向上方互动。")
func completion_text()->String:return "第三章完成 · 圆圆加入，三位学会合作。\n路线图显示光正倒流向灯树。下一章：前往灯树送光台。"
func restore_complete()->void:
    wick_found=true;wick_ready=true;wick_fitted=true;door_angle=1;npc_called=true;door_open=true
    joined=true;light_equipped=true;cat_lock=true;board_angle=1;bridge_locked=true;light_released=true
    narrow_open=true;rig_ready=true;exit_revealed=true;beam_held=false
    positions=[Vector2(1080,305),Vector2(1050,350),Vector2(1110,355)]
    super.restore_complete()
func draw_world(view:Node2D)->void:
    const TIMBER_ART=preload("res://assets/visual-m26/mechanisms.png")
    # Slender timber uprights follow the real wall strips; the door aperture stays clear.
    for wall in [Rect2(450,195,30,180),Rect2(450,475,30,175)]:
        view.draw_texture_rect_region(TIMBER_ART,wall,Rect2(741,394,69,132))
        view.draw_line(wall.position,Vector2(wall.position.x,wall.end.y),Color("634a31"),3,true)
        view.draw_line(Vector2(wall.end.x,wall.position.y),wall.end,Color("c5a571"),2,true)
    view.prop(7 if door_open else 6,Rect2(440,365,50,110))
    view.prop(11,Rect2(310,505,115,105))
    view.prop(5,Rect2(DUCT-Vector2(20,27),Vector2(40,40)),0,Color("aeb89a"))
    # The recovered wick travels with Tuantuan, then rests beside the lamp until fitted.
    var wick_at:=DUCT+Vector2(0,-7)
    if wick_found and not wick_ready:wick_at=positions[1]+Vector2(43 if facing[1].x>=0 else -43,-38)
    elif wick_ready:wick_at=DOOR_LAMP+Vector2(23,3)
    if not wick_fitted:
        view.draw_line(wick_at-Vector2(9,1),wick_at+Vector2(9,-2),Color("785a3b"),7,true)
        view.draw_line(wick_at-Vector2(9,2),wick_at+Vector2(9,-3),Color("ffdda1"),3,true)
    view.lamp(DOOR_LAMP,wick_fitted)
    var dirs:Array[Vector2]=[Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT]
    view.prop(8,Rect2(DOOR_LAMP+Vector2(-16,-28),Vector2(32,32)))
    view.arrow(DOOR_LAMP+Vector2(0,-18),dirs[door_angle]*32,Color("ffe6a2") if wick_fitted else Color("a1a38b"))
    view.prop(3,Rect2(450,394,30,42),0,Color("ffe7b8") if door_open else Color.WHITE)
    if wick_fitted:
        var beam_end:=Vector2(462,415) if door_angle==1 else DOOR_LAMP+dirs[door_angle]*57
        view.draw_line(DOOR_LAMP,beam_end,Color(1,0.87,0.51,0.32),7,true)
        view.draw_line(DOOR_LAMP,beam_end,Color(1,0.94,0.72,0.75),2,true)
    # A low, latticed window gives the outside caller a sightline to the indoor cat.
    view.prop(7,Rect2(432,249,52,88))
    for y in [270,290,310]:
        view.draw_line(Vector2(438,y),Vector2(478,y),Color("786e54"),3,true)
    view.draw_texture_rect_region(TIMBER_ART,Rect2(431,327,56,10),Rect2(741,394,69,132))
    view.prop(8,Rect2(INDOOR_PLATE-Vector2(31,16),Vector2(62,33)),0,Color("ffe3a4") if door_open or (wick_fitted and door_angle==1) else Color("a1aa8d"))
    view.rope(INDOOR_PLATE-Vector2(28,0),Vector2(480,415))
    if not joined:view.white_cat(positions[2])
    view.prop(9,Rect2(EQUIPMENT-Vector2(41,74),Vector2(82,91)))
    if light_equipped:
        # An empty peg remains on the rack after Yuanyuan takes the clasp.
        view.draw_arc(EQUIPMENT+Vector2(12,-25),7,0,TAU,16,Color("9c825a"),2,true)
    else:
        view.draw_arc(EQUIPMENT+Vector2(12,-25),10,0,TAU,20,Color("ead59b"),4,true)
    # The visible service pit follows only its actual non-walkable span.
    view.pit(Rect2(700,195,155,460))
    for edge_x in [700.0,855.0]:
        view.rope(Vector2(edge_x,208),Vector2(edge_x,378))
        view.rope(Vector2(edge_x,474),Vector2(edge_x,635))
    if bridge_locked or beam_active():view.bridge(Rect2(700,385,155,80),true)
    if beam_active() and not bridge_locked:
        # Warm edge light marks the supported temporary crossing without claiming a lock.
        view.draw_line(Vector2(705,396),Vector2(850,396),Color(1,0.85,0.46,0.65),2,true)
        view.draw_line(Vector2(705,454),Vector2(850,454),Color(1,0.85,0.46,0.65),2,true)
    view.lamp(LIGHT_STAND,beam_active())
    view.prop(3,Rect2(LOCK-Vector2(25,27),Vector2(50,54)),0,Color("ffe7b8") if cat_lock else Color.WHITE)
    if cat_lock:view.draw_line(LOCK+Vector2(-17,5),LOCK+Vector2(18,5),Color("e5c785"),4,true)
    if bridge_locked:
        for anchor in [Vector2(709,424),Vector2(846,424)]:
            view.prop(3,Rect2(anchor-Vector2(12,16),Vector2(24,32)))
    view.prop(8,Rect2(BOARD-Vector2(28,32),Vector2(56,58)))
    view.arrow(BOARD,dirs[board_angle]*37,Color("ffdf9a"))
    view.prop(8,Rect2(834,281,32,44),0,Color("ffe6aa") if board_angle==1 and beam_active() else Color("b7c0a3"))
    view.rope(Vector2(850,315),LOCK)
    if board_angle==1 and beam_active():
        view.draw_line(BOARD,Vector2(850,305),Color(1,0.85,0.45,0.25),9,true)
        view.draw_line(BOARD,Vector2(850,305),Color(1,0.94,0.73,0.8),2,true)
    if beam_held:
        var ray_start:=positions[2]+Vector2(0,-19)
        view.draw_line(ray_start,ray_start+beam_direction*200,Color(1,0.85,0.5,0.18),17,true)
        view.draw_line(ray_start,ray_start+beam_direction*200,Color(1,0.91,0.64,0.7),3,true)
    for wall in [Rect2(980,195,25,75),Rect2(980,355,25,165),Rect2(980,595,25,55)]:
        view.draw_texture_rect_region(TIMBER_ART,wall,Rect2(741,394,69,132))
        view.draw_line(wall.position,Vector2(wall.position.x,wall.end.y),Color("634a31"),3,true)
        view.draw_line(Vector2(wall.end.x,wall.position.y),wall.end,Color("c5a571"),2,true)
    view.prop(7 if exit_revealed else 6,Rect2(975,263,35,92))
    view.prop(7 if narrow_open else 6,Rect2(975,515,35,80))
    view.rope(NARROW+Vector2(0,-10),Vector2(988,550))
    view.prop(5,Rect2(NARROW-Vector2(28,48),Vector2(56,60)),0.1 if narrow_open else 0)
    view.lamp(RIG,rig_ready)
    if rig_ready:
        view.rope(RIG+Vector2(0,-32),RIG+Vector2(-28,9))
        view.rope(RIG+Vector2(0,-32),RIG+Vector2(28,9))
    else:
        view.prop(0,Rect2((Vector2(901,345) if narrow_open else Vector2(1010,565))-Vector2(20,8),Vector2(40,16)),-0.25)
    view.lamp(SEARCH_STAND,rig_ready)
    view.draw_line(Vector2(950,410),Vector2(950,300),Color("998c65"),5,true)
    view.draw_line(Vector2(950,410),Vector2(950,300),Color("d1c795"),2,true)
    view.prop(8,Rect2(935,275,30,35),0,Color("ffe3a5") if exit_revealed else Color("a8b397"))
    # A small map fixed to an actual timber easel: painted routes converge at the lamp tree.
    view.prop(9,Rect2(1029,241,120,119),0,Color("b8aa88"))
    var parchment:=PackedVector2Array([Vector2(1038,252),Vector2(1070,254),Vector2(1102,251),Vector2(1145,255),Vector2(1143,279),Vector2(1147,324),Vector2(1107,326),Vector2(1074,323),Vector2(1038,328),Vector2(1040,291)])
    view.draw_colored_polygon(parchment,Color("dec797"))
    view.draw_polyline(parchment+PackedVector2Array([parchment[0]]),Color("9c7547"),2,true)
    view.draw_line(Vector2(1045,259),Vector2(1138,260),Color("f7e3b3"),2,true)
    for pin in [Vector2(1044,259),Vector2(1140,260)]:
        view.draw_circle(pin,2.5,Color("83643d"))
        view.draw_circle(pin-Vector2.ONE,1,Color("f1dca0"))
    var route_points:Array[Vector2]=[Vector2(1050,270),Vector2(1057,307),Vector2(1129,310)]
    for p in route_points:
        var bend:=p.lerp(MAP,0.5)+Vector2(0,-8)
        view.draw_polyline(PackedVector2Array([p,bend,MAP]),Color("699a96"),2,true)
        view.draw_circle(p,3,Color("9aab87"))
        if exit_revealed:
            var dot:=p.lerp(MAP,fmod(clock*0.3,1.0))
            view.draw_circle(dot,2.5,Color("fff0bb"))
    view.draw_line(MAP+Vector2(0,4),MAP+Vector2(0,-17),Color("8d7953"),3,true)
    for offset in [Vector2(-7,-12),Vector2(7,-12),Vector2(0,-20)]:
        view.draw_circle(MAP+offset,5,Color("b2b47c"))
    view.ink(Vector2(1026,241),"灯树送光台",135,16)
