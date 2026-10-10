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
const RIG := Vector2(1030,605)
const SEARCH_STAND := Vector2(885,530)
const MAP := Vector2(1130,305)
const EXIT_WALL := 1090.0
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
var rig_angle := 0
var source_level := 0
var high_mirror_angle := 0
var exit_low_latched := false
var exit_high_latched := false
const HIGH_RING := Vector2(868,225)
const LOW_MIRROR := Vector2(1050,350)
const HIGH_MIRROR := Vector2(915,240)
const LOW_RECEIVER := Vector2(990,350)
const HIGH_RECEIVER := Vector2(915,285)
const LOWER_BEND := Vector2(1050,430)
const UPPER_BEND := Vector2(1050,240)
var hint_level := 0
var hint_context := ""
const BRIDGE_RECEIVER := Vector2(850,305)
const EXIT_RECEIVER := Vector2(1100,305)
func reflected_lock_lit()->bool:
    return beam_held and light_equipped and near(2,LIGHT_STAND,48) and beam_direction.dot(Vector2.UP)>0.8 and board_angle==1
func source_point()->Vector2:
    return Vector2(915,430 if source_level==0 else 350)
func search_beam_active()->bool:
    return beam_held and light_equipped and rig_ready and near(2,SEARCH_STAND,50) and beam_direction.dot(Vector2.RIGHT)>0.8
func transfer_trace()->Dictionary:
    # One ray, two mirrors and two fixed bends in the existing exit alcove.
    # Back faces transmit a visible scrape but never activate a receiver.
    var result:={"rays":[],"low":false,"high":false,"backfaces":[],"misses":[]}
    if not search_beam_active():return result
    var points:Array[Vector2]=[LOW_MIRROR,HIGH_MIRROR,LOW_RECEIVER,HIGH_RECEIVER,LOWER_BEND,UPPER_BEND]
    var point:=source_point()
    var direction:=Vector2.RIGHT
    var visited:={}
    for bounce in range(12):
        var key:=str([point,direction])
        if visited.has(key):result.misses.append(point);break
        visited[key]=true
        var nearest:=Vector2.ZERO
        var distance:=INF
        for candidate in points:
            var offset:=candidate-point
            var along:=offset.dot(direction)
            if along>0.5 and absf(offset.cross(direction))<0.5 and along<distance:
                distance=along;nearest=candidate
        if is_inf(distance):
            nearest=point+direction*65
            result.rays.append([point,nearest]);result.misses.append(nearest);break
        result.rays.append([point,nearest]);point=nearest
        if point==LOW_RECEIVER or point==HIGH_RECEIVER:
            var correct:=direction==Vector2.LEFT if point==LOW_RECEIVER else direction==Vector2.DOWN
            if correct:
                result["low" if point==LOW_RECEIVER else "high"]=true;break
            result.backfaces.append(point)
        elif point==LOW_MIRROR or point==HIGH_MIRROR:
            var angle:=rig_angle if point==LOW_MIRROR else high_mirror_angle
            direction=Vector2(direction.y,direction.x) if angle==0 else Vector2(-direction.y,-direction.x)
        elif point==LOWER_BEND:
            if direction==Vector2.RIGHT:direction=Vector2.UP
            elif direction==Vector2.DOWN:direction=Vector2.LEFT
            else:result.misses.append(point);break
        elif point==UPPER_BEND:
            if direction==Vector2.UP:direction=Vector2.LEFT
            elif direction==Vector2.RIGHT:direction=Vector2.DOWN
            else:result.misses.append(point);break
    return result
func update_exit()->void:
    if exit_revealed:return
    var result:=transfer_trace()
    if result.low and not exit_low_latched:
        exit_low_latched=true;say("光从铜片开口进来了，第一只门扣落下。另一只铜片的开口朝向不同。",1)
    if result.high and not exit_high_latched:
        exit_high_latched=true;say("高镜把光送进朝上的开口，第二只门扣落下了。",1)
    if exit_low_latched and exit_high_latched:
        exit_revealed=true;phase="map"
        say("两只门扣都锁稳了。同一面镜子换了入光方向，出口终于打开；收光后它也不会关上。",2)
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
    if p.x>=EXIT_WALL and p.x<EXIT_WALL+25:
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
    # Source operators select their own control rather than the nearby cat ring.
    if role in [0,2] and near(role,SEARCH_STAND,42):return "search"
    if near(role,NARROW,52):return "narrow"
    if near(role,HIGH_RING,36):return "high_mirror"
    if near(role,RIG,42):return "rig"
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
            if positions[1].distance_to(positions[0])>65:say("朵朵拍拍身边：团团，靠近一点，我们一起迎圆圆。");return
            joined=true;phase="equipment";positions[2]=positions[0]+Vector2(28,15)
            facing[0]=positions[0].direction_to(positions[2]);facing[2]=positions[2].direction_to(positions[0]);facing[1]=positions[1].direction_to(positions[0])
            act(0,"pet",0.7);act(2,"pet",0.9);act(1,"paw",0.7)
            say("朵朵蹲下摸摸爪子，圆圆把脸安静地送进她手里；团团在身边举爪搭过来。朵朵：以后等我们一起，好不好？圆圆正式入队了。",2)
        "equipment":
            if role!=0 or not joined:say("工具架上挂着小伙伴背带和定光扣。");return
            if light_equipped:say("定光扣已经稳稳装好，工具架上没有缺下的零件。");return
            light_equipped=true;phase="walkway";say("朵朵给圆圆装上定光扣。站内备用光给它补充能量：在灯座旁选好方向，再互动保持；走动或再次互动就收光。",2)
        "light":
            if role!=2 or not light_equipped:say("这个安全灯座供圆圆展开定光扣。");return
            if beam_held:release_light();return
            beam_direction=facing[2];beam_held=true;act(2,"light")
            say("向右的低光照出了猫道，桥尾的高接收槽仍暗着。" if beam_active() else "光向上进入导光板，跟着反射光看看落在哪里。" if beam_direction.dot(Vector2.UP)>0.8 else "光落在普通墙面，猫道和接收槽都没有亮。")
        "board":
            if role!=0:say("外侧导光板需要朵朵转动。");return
            board_angle=(board_angle+1)%4;say("导光板转动了。观察光束与桥尾的接收槽。")
        "lock":
            if role!=1 or not beam_active():say("暗廊里的精密卡扣，需要团团在稳定照明下拨开。");return
            cat_lock=true;say("团团拨开机械保险，桥尾高处的接收槽露出来了。低光仍只照着脚下的猫道。",1)
        "narrow":
            if role!=1 or not bridge_locked:say("低处的窄道门，有一个爪钩能拉住的小环。");return
            narrow_open=true;act(1,"hook");say("团团拉开检修窄道，松出的灯架零件滑到朵朵这边。",1)
        "rig":
            if role!=0 or not narrow_open:say("灯架缺了支脚，检修窄道里能看见它。");return
            if not rig_ready:
                rig_ready=true;say("朵朵装好灯架支脚。灯座能升降两档，两块铜片的开口朝向不同。沿光槽看看镜子从哪边接光。",1)
            else:
                rig_angle=1-rig_angle
                say("朵朵转动灯架镜片。跟着入光方向，看看光从镜子的哪一边出去。",1)
        "high_mirror":
            if role!=1 or not rig_ready:say("高镜上的小环需要团团的爪钩，先把灯架装稳。");return
            high_mirror_angle=1-high_mirror_angle;act(1,"hook")
            say("团团拉转高处镜环。镜片下方的铜片开口朝上，看看光落到了哪一面。",1)
        "search":
            if not light_equipped or not rig_ready:say("灯架还缺一只支脚，下方检修窄道里能看见它。");return
            if role==0:
                source_level=1-source_level
                beam_held=false;actions[2]="";action_time[2]=0
                recover_walkway()
                say("灯座升到上档。圆圆先收光，留在安全灯座旁；朝右重新稳光后，看看新的入光方向。" if source_level==1 else "灯座降到下档。圆圆先收光，留在安全灯座旁；朝右重新稳光再观察。",1)
                return
            if role!=2:say("升降手柄适合朵朵转动；圆圆可以在旁边稳住光源。");return
            if beam_held:release_light();return
            beam_direction=facing[2];beam_held=true;act(2,"light")
            say("光从这一档灯口出发，沿着亮槽看看它到哪面铜片。" if search_beam_active() else "光还没进侧面的灯口。灯口朝右，墙上的光斑停在槽外。")
        "map":
            if role!=0 or not exit_revealed:return
            if not light_released:say("朵朵：桥已经锁稳，先请圆圆主动收回保持的光，再一起看地图。");return
            for member in available_roles():
                if positions[member].x<1005:say("朵朵：从上方出口过来吧，我们三位一起看地图。");return
            if not exit_gather(MAP):return
            finished=true;phase="complete";extras={"joined":true,"fixed_light":true,"inward_route":true}
            say("地图上的光点全倒流向森林中央。朵朵把家门路牌放近地图：不是没有光，是光都往里面去了。我们去灯树送光台看看。",2)
        _:say("朵朵：我们三位各有自己的工具。看看光路、卡扣和导光板。")
    update_bridge();update_exit();recover_walkway()
func release_light()->void:
    beam_held=false;actions[2]="";light_released=bridge_locked
    say("圆圆主动收回定光扣，跟上伙伴。固定好的桥仍然牢固。" if bridge_locked else "圆圆收光了。团团先回到固定台。")
func tool(role:int)->void:
    if role not in available_roles() or finished or action_time[role]>0:return
    if role==2 and joined and light_equipped:
        if beam_held or (bridge_locked and not light_released):release_light();recover_walkway()
        elif target(role) in ["light","search"]:interact(role)
        else:say("圆圆的定光扣已收好。靠近灯座，朝好方向后可以再次展开。")
        return
    if role==1 and target(role) in ["duct","lock","narrow","high_mirror"]:interact(role);return
    if role==0 and target(role) in ["door_lamp","board","rig","search"]:interact(role);return
    say("朵朵可以调整身边的导光板和镜片。" if role==0 else "团团的爪钩需要靠近小拉环或精密卡扣。")
func update_bridge()->void:
    if not bridge_locked and reflected_lock_lit() and cat_lock:
        bridge_locked=true;phase="exit";say("反射光照到高接收槽，已卸开的机械扣落下，宽桥永久锁定。圆圆可以主动收光跟上了。",2)
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
    update_bridge();update_exit();recover_walkway()
func objective()->String:
    if not wick_fitted:return "门外灯座暗着，圆圆还在门里。"
    if not door_open:return "门锁与屋里的踏板，还没有一起接通。"
    if not joined:return "门开了，伙伴终于能团聚。"
    if not light_equipped:return "圆圆身旁的工具架上有一副定光扣。"
    if not bridge_locked:return "低处猫道和高处桥锁，接着不同的光槽。"
    if not light_released:return "宽桥已经锁稳，圆圆还守着灯座。"
    if not exit_revealed:return "出口的两只门扣接着不同开口的铜片，光能从哪一面进去？"
    return "三位终于能一起看到地图上的光流。"
func request_hint()->void:
    hints+=1
    var context:="door" if not door_open else "reunion" if not light_equipped else "bridge" if not bridge_locked else "release" if not light_released else "exit" if not exit_revealed else "map"
    if context=="exit":context+="_"+str([rig_ready,source_level,rig_angle,high_mirror_angle,exit_low_latched,exit_high_latched,search_beam_active()])
    if hint_context!=context:hint_context=context;hint_level=0
    hint_level=mini(3,hint_level+1)
    var steps:={
        "door":["观察：外墙检修槽不通室内；门外灯座缺了灯芯。","规则：外灯对准门锁后，还要圆圆坐到屋里的亮踏板。","试试：团团取出灯芯并送到灯座，朵朵装入、向右转板，再从低窗指向室内踏板。"],
        "reunion":["观察：圆圆在敞开的门里面，工具架就在旁边。","规则：伙伴一起进门，靠近后再打招呼。","试试：朵朵和团团穿过门到圆圆身边，重逢后由朵朵到工具架装上定光扣。"],
        "bridge":["观察：右边低槽照脚下，上方镜片对着桥尾高铜片。","规则：同一束光只能走一条线路；先把机械保险拨开，再换成反射光。拨开的保险会保留。","试试：圆圆先向右稳光，让团团走猫道拨扣；朵朵把板向右，圆圆收光再改向上照板。错路时团团会回固定台。"],
        "release":["观察：两端大桥锁已经落下，木桥不会再变暗。","规则：永久桥不用继续保持光源，圆圆可以主动结束任务。","试试：切回圆圆，再按互动或工具收光。"],
        "map":["观察：出口机械扣已经落下，地图在门后。","规则：收光后门也不会关，大家都能过。","试试：沿上方出口一起到地图边，由朵朵查看。"]}
    if context.begins_with("exit_"):
        var local:Array[String]
        if not rig_ready:local=["观察：灯架少一只支脚，下方小门里露着零件。","规则：灯架固定后，才能调节光源和镜片。","试试：团团拉开检修窄道，朵朵装稳灯架。"]
        elif not search_beam_active():local=["观察：灯口还没有亮，光槽的转弯和铜片开口都能看见。","规则：升降会先断开光源，镜位和已经锁住的门扣会保留。","试试：圆圆到新灯座，朝右互动稳光。"]
        elif source_level==0 and not exit_low_latched:local=["观察：下档的光沿弯槽，从下方进入低镜。","规则：铜片右侧才是开口，光擦过背面不会落锁。","试试：朵朵转一次低镜，看反射光是否朝左进入铜片。"]
        elif source_level==0:local=["观察：第一只门扣已经落下，另一条上层光槽仍暗着。","规则：升降灯口会改变光进入同一面镜子的方向。","试试：朵朵到灯座升到上档，再请圆圆稳光。"]
        elif rig_angle==0:local=["观察：光擦过铜片背面，再从左侧进入低镜，却向下走了。","规则：源高度改变后，先前的镜角不一定仍能接上上层光槽。","试试：朵朵只转一次低镜，再看上方光槽。"]
        elif high_mirror_angle==0:local=["观察：上层光到了高镜，却从另一边离开，下面的开口没亮。","规则：这块铜片开口朝上，需要光从上面进入。","试试：让团团拉一次高镜的小环，观察铜片是否接住光。"]
        else:local=["观察：上面的门扣锁住了，下面的开口还暗着。","规则：铜片要从开口进光，不能靠背面擦光补上门扣。","试试：先回下档，沿弯槽观察低镜与第一块铜片。"]
        say("提示 %d / 3 · %s"%[hint_level,local[hint_level-1]])
    else:say("提示 %d / 3 · %s"%[hint_level,steps[context][hint_level-1]])
func completion_text()->String:return "第三章完成 · 圆圆加入，三位学会合作。\n路线图显示光正倒流向灯树。下一章：前往灯树送光台。"
func restore_complete()->void:
    wick_found=true;wick_ready=true;wick_fitted=true;door_angle=1;npc_called=true;door_open=true
    joined=true;light_equipped=true;cat_lock=true;board_angle=1;bridge_locked=true;light_released=true
    narrow_open=true;rig_ready=true;rig_angle=1;source_level=1;high_mirror_angle=1
    exit_low_latched=true;exit_high_latched=true;exit_revealed=true;beam_held=false
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
    view.lamp(LIGHT_STAND,beam_held and near(2,LIGHT_STAND,48))
    view.prop(3,Rect2(LOCK-Vector2(25,27),Vector2(50,54)),0,Color("ffe7b8") if cat_lock else Color.WHITE)
    if cat_lock:view.draw_line(LOCK+Vector2(-17,5),LOCK+Vector2(18,5),Color("e5c785"),4,true)
    if bridge_locked:
        for anchor in [Vector2(709,424),Vector2(846,424)]:
            view.prop(3,Rect2(anchor-Vector2(12,16),Vector2(24,32)))
    view.prop(8,Rect2(BOARD-Vector2(28,32),Vector2(56,58)))
    view.arrow(BOARD,dirs[board_angle]*37,Color("ffdf9a"))
    view.prop(8,Rect2(834,281,32,44),0,Color("ffe6aa") if reflected_lock_lit() else Color("b7c0a3"))
    view.rope(Vector2(850,315),LOCK)
    if beam_held and near(2,LIGHT_STAND,48):
        if beam_direction.dot(Vector2.UP)>0.8:
            optical_ray(view,LIGHT_STAND,BOARD)
            var end:=BRIDGE_RECEIVER if board_angle==1 else BOARD+dirs[board_angle]*90
            optical_ray(view,BOARD,end)
            if board_angle!=1:optical_miss(view,end)
        else:
            optical_ray(view,LIGHT_STAND,LIGHT_STAND+beam_direction*200)
            if not beam_active():optical_miss(view,LIGHT_STAND+beam_direction*200)
    for wall in [Rect2(EXIT_WALL,195,25,75),Rect2(EXIT_WALL,355,25,165),Rect2(EXIT_WALL,595,25,55)]:
        view.draw_texture_rect_region(TIMBER_ART,wall,Rect2(741,394,69,132))
        view.draw_line(wall.position,Vector2(wall.position.x,wall.end.y),Color("634a31"),3,true)
        view.draw_line(Vector2(wall.end.x,wall.position.y),wall.end,Color("c5a571"),2,true)
    view.prop(7 if exit_revealed else 6,Rect2(EXIT_WALL-5,263,35,92))
    view.prop(7 if narrow_open else 6,Rect2(EXIT_WALL-5,515,35,80))
    view.rope(NARROW+Vector2(0,-10),Vector2(EXIT_WALL+8,550))
    view.prop(5,Rect2(NARROW-Vector2(28,48),Vector2(56,60)),0.1 if narrow_open else 0)
    view.lamp(RIG,rig_ready)
    if rig_ready:
        view.rope(RIG+Vector2(0,-32),RIG+Vector2(-28,9))
        view.rope(RIG+Vector2(0,-32),RIG+Vector2(28,9))
    else:
        view.prop(0,Rect2((Vector2(901,345) if narrow_open else Vector2(1010,565))-Vector2(20,8),Vector2(40,16)),-0.25)
    draw_exit_transfer(view)
    # A small map fixed to an actual timber easel: painted routes converge at the lamp tree.
    view.prop(9,Rect2(1079,241,120,119),0,Color("b8aa88"))
    var parchment:=PackedVector2Array([Vector2(1088,252),Vector2(1120,254),Vector2(1152,251),Vector2(1195,255),Vector2(1193,279),Vector2(1197,324),Vector2(1157,326),Vector2(1124,323),Vector2(1088,328),Vector2(1090,291)])
    view.draw_colored_polygon(parchment,Color("dec797"))
    view.draw_polyline(parchment+PackedVector2Array([parchment[0]]),Color("9c7547"),2,true)
    view.draw_line(Vector2(1095,259),Vector2(1188,260),Color("f7e3b3"),2,true)
    for pin in [Vector2(1094,259),Vector2(1190,260)]:
        view.draw_circle(pin,2.5,Color("83643d"))
        view.draw_circle(pin-Vector2.ONE,1,Color("f1dca0"))
    var route_points:Array[Vector2]=[Vector2(1100,270),Vector2(1107,307),Vector2(1179,310)]
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
    view.ink(Vector2(1076,241),"灯树送光台",135,16)

func draw_exit_transfer(view:Node2D)->void:
    var trace:=transfer_trace()
    var gold:=Color("f5d899")
    var wood:=Color("8a7255")
    # The copper elbow channels are fixed, readable geometry, not more controls.
    for channel in [PackedVector2Array([Vector2(915,430),LOWER_BEND,LOW_MIRROR]),PackedVector2Array([LOW_MIRROR,UPPER_BEND,HIGH_MIRROR])]:
        view.draw_polyline(channel,Color("726d59"),9,true)
        view.draw_polyline(channel,Color("bcad83"),3,true)
    view.draw_line(Vector2(915,340),Vector2(915,440),wood,8,true)
    view.draw_line(Vector2(911,340),Vector2(911,440),Color("c7b386"),2,true)
    for height in [350,430]:view.draw_line(Vector2(907,height),Vector2(925,height),gold,3,true)
    view.rope(SEARCH_STAND,Vector2(915,430))
    view.lamp(SEARCH_STAND,search_beam_active())
    view.draw_circle(source_point(),9,Color("c6b477"))
    view.draw_circle(source_point(),5,gold if search_beam_active() else Color("596b60"))
    view.arrow(source_point()+Vector2(12,0),Vector2.RIGHT*17,gold)
    view.ink(Vector2(917,455),"上档" if source_level==1 else "下档",70,14)
    view.ink(SEARCH_STAND+Vector2(-35,37),"升降 / 稳光",110,13)
    if rig_ready:
        for data in [[LOW_MIRROR,rig_angle],[HIGH_MIRROR,high_mirror_angle]]:
            var point:Vector2=data[0]
            view.prop(8,Rect2(point-Vector2(16,16),Vector2(32,32)))
            var axis:=Vector2(12,12) if data[1]==0 else Vector2(12,-12)
            view.draw_line(point-axis,point+axis,Color("fff1c5"),5,true)
            view.draw_line(point-axis+Vector2(1,2),point+axis+Vector2(1,2),Color("7db6b3"),2,true)
        view.rope(RIG,LOW_MIRROR)
        view.draw_arc(HIGH_RING+Vector2(0,21),7,0,TAU,18,gold,3,true)
        view.rope(HIGH_MIRROR,HIGH_RING+Vector2(0,15))
    view.ink(LOW_MIRROR+Vector2(-24,-24),"低镜",52,13)
    view.ink(HIGH_MIRROR+Vector2(-18,-27),"高镜 · 爪钩",113,13)
    draw_transfer_receiver(view,LOW_RECEIVER,Vector2.RIGHT,exit_low_latched,trace.low)
    draw_transfer_receiver(view,HIGH_RECEIVER,Vector2.UP,exit_high_latched,trace.high)
    for pair in [[Vector2(EXIT_WALL+7,282),exit_low_latched],[Vector2(EXIT_WALL+7,330),exit_high_latched]]:
        var at:Vector2=pair[0]
        view.draw_circle(at,6,gold if pair[1] else Color("6c7865"))
        if pair[1]:view.draw_line(at+Vector2(-3,0),at+Vector2(3,0),Color("fff5cf"),2,true)
    for ray in trace.rays:optical_ray(view,ray[0],ray[1])
    for miss in trace.misses:optical_miss(view,miss)
    for back in trace.backfaces:
        for offset in [-6,0,6]:view.draw_line(back+Vector2(-4,offset-3),back+Vector2(4,offset+1),Color("da996b"),2,true)
        view.ink(back+Vector2(-47,-31),"擦过背面",90,12)
    if beam_held and near(2,SEARCH_STAND,50) and not search_beam_active():
        optical_ray(view,SEARCH_STAND,SEARCH_STAND+beam_direction*55)
        optical_miss(view,SEARCH_STAND+beam_direction*55)
func draw_transfer_receiver(view:Node2D,p:Vector2,opening:Vector2,locked:bool,lit:bool)->void:
    var tangent:=Vector2(-opening.y,opening.x)
    var color:=Color("f6d794") if lit else Color("bfb991")
    var back:=p-opening*6
    view.draw_line(back-tangent*9,back+tangent*9,color,4,true)
    for side in [-1,1]:view.draw_line(back+tangent*side*9,p+opening*8+tangent*side*9,color,3,true)
    if lit:view.draw_circle(p,5,Color("fff1b8"))
    view.draw_circle(p-opening*13,3,Color("f3d58e") if locked else Color("566c62"))

func optical_ray(view:Node2D,a:Vector2,b:Vector2)->void:
    view.draw_line(a,b,Color(1,0.85,0.5,0.2),12,true)
    view.draw_line(a,b,Color(1,0.94,0.74,0.8),3,true)
    for i in range(3):view.draw_circle(a.lerp(b,fposmod(clock*0.6+i/3.0,1)),3,Color("fff1be"))
func optical_miss(view:Node2D,p:Vector2)->void:
    view.draw_arc(p,10+sin(clock*4)*2,0,TAU,18,Color("eed799"),2,true)
    view.draw_line(p+Vector2(-7,-7),p+Vector2(7,7),Color("bc8762"),2,true)
