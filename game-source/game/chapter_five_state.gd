extends "res://game/story_chapter_base.gd"
## Repair, not combat: each completed machine stage stays locked after a setback.
const GAP := Rect2(390,180,65,490)
const CROSSING := Rect2(380,510,90,85)
const LOW_LOCK := Vector2(325,545)
const SUPPORT := Vector2(355,440)
const ROUTE_LAMP := Vector2(290,610)
const CORE_GATE := Vector2(550,555)
const MACHINE := Vector2(875,340)
const BODY := Rect2(775,225,220,225)
const SHIELD_SLOT := Vector2(700,505)
const ARM_LOCK := Vector2(810,540)
const BUFFER := Vector2(700,350)
const UPPER_BUFFER := Vector2(700,255)
const ARM_RADIUS := 62.0
const AIM_STAND := Vector2(580,350)
const WHEEL := Vector2(1070,495)
const CRADLE := Vector2(665,600)
const REPAIR_SLOT := Vector2(875,495)
const TEST_PLATE := Vector2(755,555)
const TEST_SOURCE := Vector2(570,555)
const TEST_END := Vector2(1095,555)
const TEST_MARKET := Vector2(505,600)
const FAR_LAMP := TEST_END+Vector2(50,-25)
const BRANCH_DISPLAY := REPAIR_SLOT+Vector2(88,35)
const ALIGHT := Vector2(1045,335)
const LIFT := Vector2(1120,605)
const MERCHANT := Vector2(360,350)
const GRANNY := Vector2(660,425)
const PORTAL := Vector2(1090,470)
const HOME_RACK := Vector2(175,385)
const HOME_BOWL := Vector2(635,515)
const HOME_SOFA := Vector2(400,415)
const FAR_SLOT := Vector2(650,255)
const FAR_LOCK := Vector2(725,330)
const PREP_HANDLE := Vector2(560,420)
const PREP_LATCH := Vector2(620,360)
const FAR_PLATFORM := Rect2(610,220,135,95)
const SERVICE_SHORTCUT := Rect2(650,400,165,70)
const SERVICE_FRONT := Rect2(735,465,350,25)
const ISOLATOR := Vector2(615,585)
const PIN_RACK := Vector2(995,600)
const LEFT_SOCKET := Vector2(815,570)
const RIGHT_SOCKET := Vector2(940,570)
# Only these two narrow openings lead into the loaded frame. Their coordinates
# are shared by collision, interaction and presentation.
const LEFT_SERVICE := Rect2(785,470,60,65)
const RIGHT_SERVICE := Rect2(910,470,60,65)
const LEFT_PULL := Vector2(815,485)
const RIGHT_PULL := Vector2(940,485)
var extraction_side := "none"
var extraction_method := "none"
var charged_route := "none"
const HOME_TABLE := Vector2(175,270)
var arm_route := 0
var far_walkway := false
var prep_held := false
var isolation_open := false
var worklight_seen := false
var load_held := false
var load_return_time:=0.0
var load_return_from:=0.0
var support_site := "rack"
## Revision-one reader fields only; never used to grant new gameplay success.
var left_released := false
var right_released := false
var lower_pin := false
var upper_pin := false
var pilot_open := false
var pilot_route := 0
var pilot_charged := false
var pilot_waiting:=false
var gift_pending:=false
var care_pending:=-1
var home_rest_pending:=false
var keepsake_cursor:=0
var cat_one_clean := false
var cat_two_clean := false
var route_lock := false
var route_supported := false
var route_lit := false
var bridge_locked := false
var arm_locked := false
var lid_open := false
var lid_pins := 0
var wheel_notch := 0
var beam_route := 0
var wheel_ready := false
var recoil := 0.0
var stroke_time := 0.0
var wheel_motion := 0.0
var wheel_from := 0.0
var machine_stopped := false
var stage_checkpoint := 0
var boss_clock := 0.0
var shield_held := false
var shield_started := -20.0
var arm_arrest := 0.0
var failed_sweeps := 0
var beam_held := false
var fixed_light := false
var wheel_held := false
var hook_held := false
var wheel_progress := 0.0
var pull_progress := 0.0
var cleared_segments := 0
var plate_aligned := false
var test_progress := 0.0
var tested := false
var outward_light := false
var network_lit := false
var home_tag := true
var tag_inserted := false
var portal_confirms: Array[bool] = [false,false,false]
var farewell_gift := false
var gear_stored := false
var paws_clean := false
var home_pets := 0
var hint_level := 0
var hint_context := ""

func _init() -> void:
    chapter=5;chapter_key="chapter-five";title="第五章 · 把回家的路点亮"
    joined=true;phase="approach";allow_epilogue=true
    positions=[Vector2(225,465),Vector2(265,540),Vector2(230,605)]
    say("阿灯：维护通路打开了。我守着送光台。低锁、平台和导光口，你们都见过。")

func walkable(p:Vector2,role:int)->bool:
    if not super.walkable(p,role):return false
    if phase in ["home","complete","farewell"]:return true
    if phase=="approach":
        if GAP.grow(12).has_point(p):return bridge_locked and p.y>=CROSSING.position.y+10 and p.y<=CROSSING.end.y-10
        return true
    if phase in ["unjam","withdraw"]:
        for side in ["left","right"]:
            if service_rect(side).has_point(p):return role==1 and service_open(side)
        # The old central slot is now a closed rib between two physical entries.
        if Rect2(845,470,65,57).has_point(p):return false
    if FAR_PLATFORM.has_point(p) and not far_walkway:return false
    if arm_locked and arm_route==0 and SERVICE_SHORTCUT.has_point(p):return false
    # The front-edge catwalk connects both maintenance sides outside the shell.
    # The near-slot arm blocks the western entry; eastern access stays open.
    if SERVICE_FRONT.has_point(p):return p.x>=815 or (arm_locked and arm_route==1)
    if BODY.grow(14).has_point(p):return false
    if Rect2(830,457,90,70).has_point(p) and phase in ["lure","unjam","withdraw"]:
        return role==1 and lid_open and fixed_light
    return true

func follow_allowed(role:int,p:Vector2)->bool:
    if phase in ["shield","lure","unjam","withdraw"]:return false
    return walkable(p,role)

func faces(role:int,p:Vector2)->bool:
    return facing[role].dot(positions[role].direction_to(p))>0.82

func selected_slot()->Vector2:return SHIELD_SLOT if arm_route==0 else FAR_SLOT
func selected_lock()->Vector2:return ARM_LOCK if arm_route==0 else FAR_LOCK
func selected_test_end()->Vector2:return TEST_END if pilot_route==0 else TEST_MARKET
func service_rect(side:String)->Rect2:return LEFT_SERVICE if side=="left" else RIGHT_SERVICE
func pull_point(side:String)->Vector2:return LEFT_PULL if side=="left" else RIGHT_PULL
func cat_in_service()->bool:return LEFT_SERVICE.grow(3).has_point(positions[1]) or RIGHT_SERVICE.grow(3).has_point(positions[1])
func manual_load_ready()->bool:
    return lid_open and fixed_light and isolation_open and load_held and actions[0]=="hold" and near(0,WHEEL,65) and support_site=="rack"
func service_open(side:String)->bool:
    if not lid_open or not fixed_light:return false
    if machine_stopped:return extraction_side==side
    return (support_site==side and not load_held) or (side=="right" and isolation_open and manual_load_ready())
func recover_manual_mouth()->void:
    if phase!="unjam" or machine_stopped or not RIGHT_SERVICE.grow(3).has_point(positions[1]):return
    if service_open("right"):return
    positions[1]=RIGHT_PULL+Vector2(0,80);actions[1]="sit";action_time[1]=0.6
    observe("hold_recovery","受力绳松开，团团退到口边的固定台。轮架轻轻落回；已锁好的检修盖还在。",RIGHT_PULL)
func load_center_side()->String:
    if machine_stopped:return "none"
    if support_site=="left":return "right"
    if support_site=="right":return "left"
    return "both"
func load_return_progress()->float:return 1.0-clampf(load_return_time/0.4,0.0,1.0)
func load_tilt()->float:
    if load_held:return 0.0
    var bias:=1.0 if load_center_side()=="right" else -1.0 if load_center_side()=="left" else 0.0
    return bias*0.12*load_return_progress()
func unloading_wheel_angle()->float:
    return -0.45 if load_held else lerpf(load_return_from,load_tilt(),load_return_progress())
func target(role:int)->String:
    if phase=="shield":
        if near(role,PREP_HANDLE,42):return "外台升降柄"
        if near(role,PREP_LATCH,40):return "外台棘轮"
        if near(role,FAR_SLOT,48):return "远侧维修卡槽"
        if near(role,selected_lock(),44):return "机械臂锁扣"
    if phase=="unjam":
        if role==1:
            for side in ["left","right"]:
                if near(role,pull_point(side),24):return "左侧取枝口" if side=="left" else "右侧取枝口"
        if near(role,ISOLATOR,37):return "工作灯隔离环"
        if near(role,PIN_RACK,35):return "备用撑扣"
        if near(role,LEFT_SOCKET,32):return "左卸重座"
        if near(role,RIGHT_SOCKET,32):return "右卸重座"
    if phase in ["home","complete"] and near(role,HOME_TABLE,60):return "旅途纪念"
    if phase=="approach":
        if near(role,LOW_LOCK,52):return "低锁扣"
        if near(role,SUPPORT,54):return "平台撑杆"
        if near(role,ROUTE_LAMP,58):return "通道导光口"
        if bridge_locked and near(role,CORE_GATE,65):return "树心维护门"
    elif phase=="shield":
        if near(role,selected_lock(),44):return "机械臂锁扣"
        if near(role,SHIELD_SLOT,65):return "盾牌维修卡槽"
    elif phase=="lure":
        if near(role,AIM_STAND,66):return "缓冲导光台"
        if near(role,WHEEL,65):return "外侧维护轮"
    elif phase=="unjam":
        if near(role,CRADLE,65):return "安全固定灯座"
        if near(role,REPAIR_SLOT,42):return "检查检修盖"
        if near(role,WHEEL,65):return "外侧维护轮"
    elif phase=="withdraw":
        if near(role,CRADLE,65):return "解除定光保持"
    elif phase=="test":
        if near(role,selected_test_end(),62):return "观察远灯"
        if near(role,TEST_PLATE,62):return "测试导光板"
        if near(role,TEST_SOURCE,64):return "测试接点"
        if near(role,ALIGHT,68):return "阿灯"
    elif phase=="release":
        if near(role,ALIGHT,72):return "阿灯送光闸"
    elif phase=="network":
        if near(role,LIFT,65):return "送往集市的升降台"
        if near(role,ALIGHT,70):return "阿灯"
    elif phase=="farewell":
        if near(role,MERCHANT,68):return "挂好路灯的摊主"
        if near(role,GRANNY,70):return "栗婆婆的木灯挂件"
        if near(role,PORTAL,75):return "归途门"
    elif phase in ["home","complete"]:
        if near(role,HOME_RACK,70):return "收好冒险装备"
        if near(role,HOME_BOWL,76):return "擦擦猫爪"
        if near(role,HOME_SOFA,90):return "安心休息 · 主动结束" if not finished else "家里的沙发"
        if role==0 and (near(0,positions[1],58) or near(0,positions[2],58)):return "摸摸猫"
    if phase not in ["approach","farewell","home","complete"]:
        for visible_item in [[WHEEL,"检查维护轮"],[CRADLE,"检查安全灯座"],[AIM_STAND,"检查导光轨"],[REPAIR_SLOT,"检查检修盖"],[ARM_LOCK,"检查夹臂锁"]]:
            if near(role,visible_item[0],58):return visible_item[1]
    return ""

func objective()->String:
    match phase:
        "approach":return "找到通往树心的安全通路"
        "shield":return "让摆动的夹臂停在维修槽里"
        "lure":return "检修盖被两枚销压住；观察吸光口与两条光路"
        "unjam":return "折枝卡在轮架里。让窄口接稳重量，带它出来"
        "withdraw":return "机器停稳了，让伙伴和工具安全离开检修区"
        "test":return "试送一小段光，亲自查看远端的结果"
        "release":return "测试灯没有倒流。到阿灯身边，一起打开送光闸"
        "network":return "沿路重新亮起的灯，乘升降台去告别"
        "farewell":return "和居民告别，找到属于三位的归途"
        "home":return "回到同一个下午，照顾好伙伴，准备好后安心休息"
        _:return "都在就好 · 已回家，可继续走动和摸猫"

func hint_context_key()->String:
    match phase:
        "approach":
            if bridge_locked:return "cross"
            if route_supported:return "route_light"
            if route_lock:return "support"
            return "low_lock"
        "shield":return "arm_latch" if arm_arrest>0 else "guard"
        "lure":return "lid_"+str(lid_pins)
        "unjam":
            if not isolation_open:return "work_return"
            if not fixed_light:return "work_light"
            if manual_load_ready():return "manual_entry"
            if support_site in ["left","right"]:return "pin_raised" if load_held else "pin_entry"
            return "support_choice"
        "withdraw":return "withdraw_cat" if cat_in_service() else "withdraw_light"
        "test":
            if pilot_charged:return "observe_borrowed" if beam_held else "observe_kept"
            if not pilot_open:return "pilot_valve"
            if not plate_aligned:return "test_plate"
            return "test_source"
        "farewell":return "confirm_"+str(portal_confirms[0])+str(portal_confirms[1] or portal_confirms[2]) if tag_inserted else "home_tag"
        "home":
            if not gear_stored:return "gear"
            return "rest" if paws_clean else "paws"
    return phase

func request_hint()->void:
    hints+=1
    if hint_context!=phase:hint_context=phase;hint_level=0
    hint_level=mini(3,hint_level+1)
    var steps:Array[String]=[]
    var context:=hint_context_key()
    match phase:
        "shield":steps=["地面有两条夹臂弧线，远侧卡槽在尚未升起的外台上。","近槽能直接接住夹臂；远槽需要先把外台锁稳，但会让下面的短道空出来。","朵朵在外台升降柄保持，团团拉棘轮即可开远台；选定卡槽后，朵朵迎着机器举盾，团团拉对应小锁。"]
        "lure":steps=["两枚盖销，各对应一个缓冲座。","吸口偏向哪一座，哪一侧的销就露出来；两枚不分先后。","圆圆在导光台朝右或朝上接光，朵朵拨维护轮。换另一条光路再试。"]
        "unjam":
            var local:Dictionary={
                "work_return":["灯座有一根细管接回主机。","接回的光会被回收口带走，独立支路才能留下工作光。","团团在工作灯隔离环开小闸，再由圆圆给安全灯座接光。"],
                "work_light":["小闸已断开回收口，检修口里仍暗着。","隔离后留下的灯不用让圆圆一直保持。","圆圆靠近安全固定灯座接光，先看看光是否留住。"],
                "support_choice":["轮架下左右都有窄口，右边受力绳连着维护轮。","朵朵保持接重时右口能进；撑扣托稳任一侧后，朵朵也能离开。","选人工法：朵朵在轮边互动保持，团团直接进右口；选稳定法：拿唯一撑扣，抬架装扣再放下。"],
                "manual_entry":["受力绳正绷着，右边的窄口留出空间。","朵朵保持接重，团团才能直接进右口；取枝后棘轮会接住重量。","保持朵朵在维护轮边，让团团从右口进入取整枝，再沿原口退出来。"],
                "pin_raised":["撑扣已装好，轮架仍托在朵朵手里。","重量落到撑扣后，对应窄口才会稳住。","团团先离开口边，朵朵在维护轮再互动放下，随后走撑扣同侧取枝。"],
                "pin_entry":["撑扣接着重量，同侧的窄口留出了空隙。","稳定撑扣能让朵朵离开；另一侧仍压着。","团团从撑扣同侧窄口进入，一次带出整根枝，再从原口退出。"]}
            steps.assign(local[context])
        "withdraw":steps=["原来的窄口仍开着，团团还在轮架下面。","永久棘轮已接住重量，伙伴沿原口退出后才能收工作灯。","让团团沿原窄口退到南边固定台，再由圆圆收灯。"] if cat_in_service() else ["团团已经到了口外的固定台，灯仍照着检修槽。","机器已停，退出安全口后就可以结束工作灯任务。","圆圆到安全灯座主动收灯，准备试送远端。"]
        "test":
            var local:Dictionary={
                "pilot_valve":["阿灯身旁的小闸仍合着。","试送支路需要从灯树接入，便携光只能引亮接点。","到阿灯身边打开一条试送小闸。"],
                "test_plate":["导光板还没有连向远灯。","板的方向决定本次试送目的地，两处的证据不共用。","朵朵在导光板面向右选钟楼、面向左选集市。"],
                "test_source":["便携光要从测试接点进入导光板。","光落在接点外不能充光；沿光斑看它有没有进入侧面的槽。","圆圆在测试接点朝右接光，再到选中的远灯看看。"],
                "observe_borrowed":["远灯亮着，圆圆手里也还留着光。","灯亮可能只是借光；收回后仍亮，才有机构送光的证据。","朵朵到选中远灯旁观察，圆圆主动收光，再由朵朵确认。"],
                "observe_kept":["便携光收回了，试送那一路仍亮着。","亲眼确认远端结果，才能准备开总闸。","朵朵去本次试送的远灯确认；改目的地要重新试送。"]}
            steps.assign(local[context])
        "home","complete":steps=["软布放在水盆旁，沙发还是出发前的那一张。","可以先照顾任意一只猫，也可以先慢慢看看带回来的纪念。","朵朵在水盆边照顾猫，两次不分先后；放好装备，准备好后坐回沙发。"]
        _:steps=[objective(),"留意已咬合的棘齿；这些锁住的修复不会因为放手而退回。","靠近能看见的物件，试试各位擅长的工具。"]
    say("提示 %d / 3 · %s"%[hint_level,steps[hint_level-1]])

func clear_holds()->void:
    beam_held=false;wheel_held=false;hook_held=false;shield_held=false
    load_held=false;prep_held=false
    load_return_time=0;load_return_from=0
    pilot_waiting=false
    beam_route=0;wheel_ready=false;recoil=0;stroke_time=0;wheel_motion=0;wheel_from=0
    for i in range(3):actions[i]="";action_time[i]=0.0

func interact(role:int)->void:
    if dialogue_active() or social_transition_active():return
    if role not in [0,1,2] or action_time[role]>0.1:return
    var item:=target(role)
    if item.is_empty():return
    match item:
        "外台升降柄":
            if role!=0:say("升降柄很重，松手就会回落。");return
            prep_held=not prep_held;actions[0]="brace" if prep_held else ""
            observe("outer_raise","外台抬了起来，旁边的棘轮仍未咬合。" if prep_held else "升降柄卸了力。",PREP_HANDLE)
        "外台棘轮":
            if role!=1:say("齿间的小绳环，只够爪钩穿过去。");return
            if not prep_held:say("棘齿压得很紧，钩子拉不动。");return
            far_walkway=true;prep_held=false;actions[0]="";act(1,"paw")
            observe("outer_locked","棘齿咬住了抬高的外台，远侧的卡槽也能靠近了。",PREP_LATCH)
        "远侧维修卡槽":
            if not far_walkway:return
            if role!=0:say("卡槽朝着夹臂，地上的弧线延伸到上方。");return
            arm_route=1;boss_clock=0;observe("far_plan","导轨转向外台，夹臂离开了下方短通道。",FAR_SLOT)
        "工作灯隔离环":
            if role!=1:say("细绳连着工作灯与回收口之间的小闸。");return
            if isolation_open and fixed_light and cat_in_service():say("灯照着检修槽，暂时不能让它熄掉。");return
            isolation_open=not isolation_open;act(1,"paw")
            if not isolation_open:fixed_light=false
            observe("work_isolation","小闸断开了回收口，灯座现在是一条独立支路。" if isolation_open else "小闸接回主线，灯里的光被吸走。",ISOLATOR)
        "备用撑扣":
            if role!=1:say("备用撑扣只有一枚，能沿着检修窄槽带进去。");return
            if support_site=="rack":support_site="carried";act(1,"paw");observe("pin_taken","团团叼起了唯一的撑扣，架上空了。",PIN_RACK)
            elif support_site=="carried":support_site="rack";observe("pin_returned","撑扣放回架上。",PIN_RACK)
        "左卸重座","右卸重座":
            if role!=1:say("撑扣要从侧面的小孔穿入。");return
            var side:String="left" if item=="左卸重座" else "right"
            if cat_in_service():say("团团还在轮架下面，先沿原来的窄口退出再移扣。");return
            if support_site==side:
                if not load_held:say("撑扣接着轮架重量。朵朵重新卸力，才能取出换边。");return
                support_site="carried";act(1,"paw");observe("pin_reused","轮架已经抬起，团团取出撑扣，可以带到另一边。",LEFT_SOCKET if side=="left" else RIGHT_SOCKET)
            elif support_site=="carried":
                if not fixed_light:say("槽内很暗，看不清扣齿。");return
                if not load_held:say("孔被沉下来的轮架压住，撑扣碰到边缘。");return
                support_site=side;act(1,"paw");observe("pin_loaded","撑扣放在"+("左" if side=="left" else "右")+"侧。放下轮架后，这一侧会留出取枝窄口。",LEFT_SOCKET if side=="left" else RIGHT_SOCKET)
            else:say("这里有一个撑扣孔，架上没有第二枚扣。")
        "旅途纪念":
            if journey_discoveries.is_empty():say("桌面空出了一小块。团团把爪子轻轻放上去。");return
            var earned:Array=[]
            for id in ["prologue_ball","one_nightlight","two_cart","three_map","four_stall","four_view"]:
                if id in journey_discoveries:earned.append(id)
            var memories:Dictionary={
                "prologue_ball":["团团把旧毛线球推到朵朵手边。出门前，它也这样来找她玩。","朵朵：认真做完正事，现在可以陪你慢慢玩啦。"],
                "one_nightlight":["小夜灯暖暖地亮着。驿站那扇窗里，也留着这样一盏灯。","圆圆把脸靠近灯罩，又慢吞吞地趴回朵朵身边。"],
                "two_cart":["团团用爪子点点货车小纸片。那天，他们走的是运输宽岸。","朵朵：大货车也能从那边过去，这条路留给大家。"],
                "three_map":["朵朵翻过钟楼线路纸。背面的斜线，曾让他们重新看懂光路。","圆圆望向图上的灯，团团压住了翘起的纸角。"],
                "four_stall":["小布旗画着集市灯罩的花纹。摊主在亮起来的台面上重新摆好了东西。","团团伸爪摸摸花纹。朵朵：还记得我们借给她的那盏小灯吗？"],
                "four_view":["观景纸上是远处钟楼的轮廓。带小灯去那里时，他们终于看清了远路。","圆圆贴着纸上的灯点坐下。朵朵：原来多绕一点，会看到这些呀。"]}
            if earned.is_empty():return
            var id:String=earned[keepsake_cursor%earned.size()];keepsake_cursor+=1
            start_dialogue(memories[id],{"role":0,"kind":"touch","target":HOME_TABLE,"duration":2.0,"participants":[0]})
        "检查维护轮":say("轮架已经停稳了。" if machine_stopped else "夹臂仍在扫动，轮架还被安全锁扣住。先看看地上的维修槽。")
        "检查安全灯座":say("安全灯座照着检修槽，检修盖打开后才能接入。" if not lid_open else "安全灯已完成工作，检修槽里没有转动的构件了。")
        "检查导光轨":say("两条导轨通向不同的缓冲座。" if not lid_open else "缓冲座已卸下检修盖的压力，两枚销保持锁定。")
        "检查检修盖":say("盖上的销还被吸光口压住，不能硬拉。" if not lid_open else "检修盖已锁在打开的位置，折枝已经取出。" if machine_stopped else "中央横梁压着枝条。左右各有窄口，托稳哪一侧，就能从那一侧伸进爪钩。")
        "检查夹臂锁":say("夹臂已牢牢扣在维修卡槽里。" if arm_locked else "夹臂仍在摆，小锁暂时够不到。")
        "低锁扣":
            if role!=1:say("低锁藏在窄槽里，要团团的爪钩。");return
            route_lock=true;act(role,"paw");say("爪钩拉下低锁，平台底部露出撑杆槽。",1)
        "平台撑杆":
            if role!=0 or not route_lock:say("先松低锁，再让朵朵把撑杆压入凹槽。");return
            route_supported=true;act(role,"hold");say("撑杆扣牢了，平台不会再回落。",1)
        "通道导光口":
            if role!=2 or not route_supported or not faces(role,Vector2(600,610)):
                say("圆圆需要让光朝右，穿过已经撑稳的平台。");return
            route_lit=true;bridge_locked=true;act(role,"light");say("定光接通，桥边的机械销落锁。放开灯，路也不会消失。",2)
        "树心维护门":
            if exit_gather(CORE_GATE):
                clear_holds();phase="shield";boss_clock=0
                positions=[Vector2(610,560),Vector2(675,595),Vector2(575,620)]
                say("朵朵：不用打坏它。把卡住的地方松开。地上有一个维修卡槽。")
        "机械臂锁扣":
            if role!=1:say("团团的爪钩能拉到夹臂下的小锁。");return
            if arm_arrest<=0:say("机械臂还在摆。等朵朵把它挡进维修卡槽。");return
            arm_locked=true;stage_checkpoint=1;phase="lure";clear_holds();arm_arrest=0
            observe("arm_locked","夹臂锁在外台，下面的短道空出来了。" if arm_route==1 else "夹臂锁稳了，横在中间的短道上；南边的平台仍通着。",selected_slot())
        "盾牌维修卡槽":
            if role==0:arm_route=0;boss_clock=0
            observe("near_plan","导轨停在近槽；夹臂锁在这里，会横过中间的短通道。",SHIELD_SLOT)
        "缓冲导光台":
            if role!=2:say("导光扣能把光接入上下两条导轨。");return
            var chosen:=light_route()
            if chosen==0:say("光落在导轨外，缓冲座没有亮。");act(role,"paw");return
            beam_held=not (beam_held and beam_route==chosen)
            beam_route=chosen if beam_held else 0
            actions[2]="light" if beam_held else "";action_time[2]=0.4
            say("吸光口朝亮起的缓冲座偏转，盖边的一枚销露出来。" if beam_held else "圆圆收光，吸口回到中央；已经扣牢的销不动。")
        "外侧维护轮":
            if role!=0:say("轮架很重，朵朵才能拨到下一处卡口。");return
            if phase=="lure":
                wheel_from=float(wheel_notch)*TAU/3;wheel_notch=(wheel_notch+1)%3;wheel_motion=0.4
                act(0,"hold",0.4)
                if beam_held and beam_route in [1,2]:
                    if beam_route==1:lower_pin=true
                    else:upper_pin=true
                    lid_pins=int(lower_pin)+int(upper_pin);wheel_progress=float(lid_pins)
                    observe("lid_pin","露出的销扣住了，另一个缓冲座可以独立试。",WHEEL)
                    if lid_pins==2:
                        lid_open=true;stage_checkpoint=2;phase="unjam";clear_holds();wheel_notch=0
                        observe("lid_open","两侧压力都落到销上，检修盖翻开，轮架下还压着一根折枝。",REPAIR_SLOT)
                else:recoil=0.6;observe("lid_blocked","轮扣碰到被吸口遮住的销，轻轻弹回；已扣牢的一枚没有松。",WHEEL)
            else:
                if cat_in_service():say("团团还在窄口里。先让它退出来，轮架才能换姿态。");return
                load_return_from=unloading_wheel_angle();load_return_time=0.4
                load_held=not load_held;actions[0]="hold" if load_held else ""
                observe("load_lift","朵朵接住轮架，右口留出空间；保持接重就能进去，也可装撑扣让她腾开手。" if manual_load_ready() else "轮架抬起，两个撑扣孔露出来；窄口还没有落稳。" if load_held else "重量落到撑扣，"+("左" if support_site=="left" else "右")+"侧窄口留了出来。" if support_site in ["left","right"] else "轮架落回两边，窄口都压住了。",WHEEL)
        "安全固定灯座":
            if role!=2:say("圆圆的定光扣才能接入安全固定座。");return
            if fixed_light:
                if cat_in_service():say("团团还在检修槽里。先让它沿窄口退出，再收灯。");return
                fixed_light=false;actions[2]="";say("圆圆收回安全光，已经拉出的枝条由棘轮锁住。");return
            worklight_seen=true;beam_held=false;act(2,"light")
            if not isolation_open:
                fixed_light=false;observe("work_return","光刚到灯座，就沿接回主线的细管被吸走了。",CRADLE);return
            fixed_light=true;observe("work_kept","圆圆收起爪子，独立灯座仍照着检修槽。",CRADLE)
        "左侧取枝口","右侧取枝口":
            var side:String="left" if item=="左侧取枝口" else "right"
            if role!=1 or not service_open(side):
                recoil=0.6;observe("branch_pinned","这一侧仍被压着。撑扣托稳的那一侧，才留得出取枝空间。",pull_point(side));return
            if not service_rect(side).has_point(positions[1]):return
            # One actual pull from the chosen reachable opening removes the whole
            # branch. No synthetic left/right completion flags are awarded.
            extraction_side=side;extraction_method="held" if manual_load_ready() else "support";machine_stopped=true;stage_checkpoint=3;phase="withdraw"
            clear_holds();hook_held=true;act(1,"paw",0.7);stroke_time=0.7
            observe("branch_out","团团带出整根折枝，永久棘轮咔哒接住轮架。朵朵松手，右口仍能退出，机器慢慢停了。" if extraction_method=="held" else "团团从"+("左" if side=="left" else "右")+"侧窄口拉出整根折枝。空出的轮架咔哒落稳，机器慢慢停了。",pull_point(side))
        "解除定光保持":
            if role!=2:return
            if cat_in_service():say("团团还在检修槽里。先让它沿窄口退出，再收灯。");return
            fixed_light=false;clear_holds();phase="test";say("三位退回安全平台。阿灯：如果又熄了呢？朵朵：先亮一小段，我们一起看。",1)
        "测试导光板":
            if role!=0:say("朵朵来对准导光板，圆圆照出接点。");return
            var next_route:=0 if facing[0].x>=0 else 1
            if next_route!=pilot_route:
                pilot_charged=false;charged_route="none";outward_light=false;pilot_waiting=false
            pilot_route=next_route;plate_aligned=true;act(role,"hold")
            observe("pilot_route","导光板连到钟楼试送支路。" if pilot_route==0 else "导光板连到集市试送支路。",TEST_PLATE)
        "测试接点":
            if role!=2:say("测试接点要圆圆的定光扣照亮。");return
            beam_held=not beam_held;actions[2]="light" if beam_held else "";action_time[2]=0.4
            say("圆圆打开测试光束；看光是在往外送，还是回到树心。" if beam_held else "圆圆暂时收光，测试可以再来。")
        "观察远灯":
            if role!=0:say("远灯的接点就在这里，等朵朵来一起确认。");return
            if not pilot_charged or charged_route!=("tower" if pilot_route==0 else "market"):say("这一处远灯还没有经过试送。回头看看光在哪个接点拐走了。");return
            if beam_held:
                pilot_waiting=true;actions[0]="hold";action_time[0]=0
                say("朵朵留在远灯旁等着：圆圆，先收回便携光。我在这里看看它还亮不亮。");return
            tested=true;phase="release";clear_holds();outward_light=true;act(0,"pet")
            start_dialogue(["圆圆收回光，远灯仍稳稳亮着。", "钟楼传来久违的报时声。阿灯抬起头，听完了整段钟声。" if pilot_route==0 else "摊主在远处挥了挥布旗，又把收起的小招牌挂回灯下。"],{"role":0,"kind":"touch","target":selected_test_end(),"duration":2.0,"participants":[0,2]})
        "阿灯":
            if phase=="test":
                pilot_open=true;observe("pilot_open","阿灯只打开一条试送小闸：我先陪你们看这一盏。",ALIGHT)
            else:say("阿灯：我和居民一起查线路。今天，不把灯都收回来了。")
        "阿灯送光闸":
            if role!=0:return
            network_lit=true;phase="network";clear_holds();extras["outward_verified"]=true
            start_dialogue(["驿站窗下的旧灯先亮了。栗婆婆放下油壶，抬头看向路牌。","运输桥边的长灯接着亮起。永久桥锁稳稳承着路，货车重新驶过河岸。","钟楼的铜片亮起来，钟声越过山坡。留在门外的人终于看清回家的路。","集市重新摆出晚间的小摊。阿灯：原来把光送出去，才看得见大家。"],{"role":0,"kind":"network","target":ALIGHT,"duration":0.1,"participants":[]})
        "送往集市的升降台":
            if not exit_gather(LIFT):return
            phase="farewell";clear_holds();positions=[Vector2(230,500),Vector2(285,550),Vector2(210,590)]
            say("升降台到了明亮的集市。摊主挂回路灯，栗婆婆从修好的桥上来接你们。可自由告别，再一起回家。",2)
        "挂好路灯的摊主":act(role,"pet" if role==0 else "paw");say("摊主：灯罩修好了，路灯也回来了。谢谢你们，路上慢慢走。")
        "栗婆婆的木灯挂件":
            if role!=0:say("栗婆婆摸摸猫背，从布包里拿出一个小挂件。");return
            if farewell_gift:say("栗婆婆：挂件放好了。路上慢慢走。");return
            gift_pending=true
            stage_social(["栗婆婆从布包里拿出一枚小木灯挂件，放进朵朵掌心。","栗婆婆：不带魔力。就是记着，这条路有人一起修过。","朵朵：我们会好好收着。还有这些工具，谢谢您。"],{"role":0,"kind":"receive","target":GRANNY,"duration":2.0,"participants":[0,1,2]},{0:GRANNY+Vector2(48,32)})
        "归途门":
            if not exit_gather(PORTAL):return
            if not tag_inserted:
                if role!=0 or not home_tag:say("朵朵把记着家门的路牌插入灯座，才能找到原来的走廊。");return
                tag_inserted=true;act(role,"pet");start_dialogue(["家门路牌插好了，熟悉的走廊慢慢出现。","朵朵低下头，等团团和圆圆靠过来：这次一起。"],{"role":0,"kind":"pet","target":PORTAL,"duration":2.0,"participants":[0,1,2]});return
            portal_confirms[role]=true;act(role,"pet" if role==0 else "paw")
            if single or (portal_confirms[0] and (portal_confirms[1] or portal_confirms[2])):
                phase="home";clear_holds();positions=[Vector2(420,540),Vector2(480,580),Vector2(360,590)]
                start_dialogue(["三位跨回家门。窗外的光，仍停在出发时的位置。","朵朵把手放在两个毛茸茸的脑袋之间，终于慢慢松了一口气。"],{"role":0,"kind":"pet","target":positions[1],"duration":2.0,"participants":[0,1,2]})
            else:say("确认好了，等另一位伙伴也准备好。")
        "收好冒险装备":
            if role!=0:say("猫咪蹭了蹭装备架，等朵朵把剑盾和定光扣放好。");return
            gear_stored=true;act(role,"pet");say("背包、木剑、盾和两套猫咪装备整齐放好。今天不用再出发了。",1)
        "擦擦猫爪":
            if role!=0:return
            var cat:int=1 if not cat_one_clean and (cat_two_clean or positions[1].distance_to(HOME_BOWL)<=positions[2].distance_to(HOME_BOWL)) else 2
            care_pending=cat
            var care_point:Vector2=HOME_BOWL+Vector2(-35 if cat==1 else 35,15)
            stage_social(["朵朵拧好软布，轻轻托起团团的前爪。" if cat==1 else "圆圆把爪子放到软布上，眯起了眼睛。", "团团抱住手指，舔了一下，才肯松开。" if cat==1 else "圆圆甩了甩尾尖，顺势把脸送进朵朵掌心。"],{"role":0,"kind":"pet","target":care_point,"duration":2.0,"participants":[0,cat]},{cat:care_point})
        "摸摸猫":
            home_pets+=1
            start_dialogue(["团团舔了舔手，又抱住手指；圆圆把脸送到掌心。","朵朵：都在就好。"],{"role":0,"kind":"pet","target":positions[1],"duration":2.0,"participants":[0,1,2]})
        "安心休息 · 主动结束":
            if role!=0:return
            if not gear_stored or not paws_clean:say("先把装备收好，检查两只猫的爪子，再安心休息。");return
            home_rest_pending=true
            stage_social(["朵朵坐回原来的沙发。团团挨着膝盖，圆圆团在另一边。","朵朵：好了……现在真的可以休息了。"],{"role":0,"kind":"sit","target":HOME_SOFA,"duration":120.0,"participants":[0,1,2]},{0:HOME_SOFA+Vector2(-12,18),1:HOME_SOFA+Vector2(50,42),2:HOME_SOFA+Vector2(-60,40)})
        "家里的沙发":act(role,"sit");say("小木灯挂件安静地放在桌上。路已经修好，大家都在家。")

func guard(role:int,held:bool)->void:
    if role!=0:return
    if held and not shield_held:shield_started=boss_clock
    shield_held=held
    if phase=="shield":actions[0]="brace" if held else ""

func tool(role:int)->void:
    if dialogue_active() or social_transition_active():return
    if role==0 and target(role) in ["外台升降柄","外侧维护轮"]:interact(role);return
    if role==1 and target(role) in ["外台棘轮","工作灯隔离环","备用撑扣","左卸重座","右卸重座"]:interact(role);return
    if role==0:
        guard(0,not shield_held)
        if phase!="shield":say("朵朵举起盾观察周围，附近没有摆动的夹臂。")
    elif role==1 and target(role) in ["低锁扣","机械臂锁扣","左侧取枝口","右侧取枝口"]:interact(role)
    elif role==2:
        if beam_held:
            beam_held=false;beam_route=0;actions[2]="";say("圆圆收起手中的光，已锁定的机关保持原样。")
        elif target(role) in ["通道导光口","缓冲导光台","安全固定灯座","解除定光保持","测试接点"]:interact(role)
        else:say("定光扣准备好了，要接近导光口或灯座才能接光。")
    else:say("爪钩够不到可拉动的小锁，团团把钩子收回。")

func light_route()->int:
    if facing[2].dot(Vector2.RIGHT)>0.82:return 1
    if facing[2].dot(Vector2.UP)>0.82:return 2
    return 0

func branch_direction()->int:
    return 0 if support_site=="left" else 2

func pilot_trace()->Dictionary:
    var active:bool=beam_held and actions[2]=="light"
    var source_connected:bool=active and near(2,TEST_SOURCE,72) and faces(2,TEST_END)
    var board_connected:bool=source_connected and plate_aligned
    var valve_connected:bool=board_connected and pilot_open
    var rays:Array=[];var misses:Array=[]
    var origin:Vector2=positions[2]+Vector2(11,-38)
    var plate:Vector2=TEST_PLATE+Vector2(0,-10)
    if active:
        if source_connected:
            rays.append([origin,plate])
            if not board_connected:misses.append(plate)
        else:
            var miss:Vector2=origin+facing[2]*95
            rays.append([origin,miss]);misses.append(miss)
    return {"active":active,"source_connected":source_connected,"board_connected":board_connected,"valve_connected":valve_connected,"rays":rays,"misses":misses}
func test_beam_ready()->bool:
    return pilot_trace().board_connected

func arm_tip()->Vector2:
    if arm_locked or arm_arrest>0:return selected_slot()
    var t:=fmod(boss_clock,4.6)
    var rest:=Vector2(715,370)
    if t<=1.8:return rest.lerp(selected_slot(),smoothstep(1.1,1.8,t))
    return selected_slot().lerp(rest,smoothstep(1.95,2.65,t))

func attack(role:int)->void:
    if role not in [0,1,2]:return
    act(role,"attack")
    say("厚壳没有损坏，里面的构件已经安静了。" if machine_stopped else "厚壳没有损坏，里面的构件仍在动。")

func safe_setback()->void:
    failed_sweeps+=1;arm_arrest=0;shield_held=false
    var pads:=[Vector2(590,565),Vector2(760,620),Vector2(575,620)]
    for role in available_roles():
        if near(role,selected_slot(),ARM_RADIUS):positions[role]=pads[role];actions[role]="sit";action_time[role]=0.6
    say("柔软夹臂把圈内的伙伴推回安全垫。没有受伤；圈外安全，已锁定的维修不倒退。")

func step(dt:float,a:Vector2,b:Vector2,enabled:bool)->void:
    if social_transition_active():
        if enabled and is_finite(dt) and dt>0 and a.is_finite() and b.is_finite():step_social_transition(dt)
        return
    if not enabled or not is_finite(dt) or dt<=0 or not a.is_finite() or not b.is_finite():return
    if dialogue_active() or social_transition_active():return
    super.step(dt,a,b,enabled);dt=minf(dt,0.05)
    if pilot_waiting and (phase!="test" or not near(0,selected_test_end(),62) or actions[0]!="hold"):pilot_waiting=false
    load_return_time=maxf(0,load_return_time-dt)
    if prep_held and (not near(0,PREP_HANDLE,58) or actions[0]!="brace"):prep_held=false
    if load_held and (not near(0,WHEEL,65) or actions[0]!="hold"):load_held=false
    recover_manual_mouth()
    if load_held:actions[0]="hold"
    if prep_held:actions[0]="brace"
    if phase=="shield":
        if arm_arrest>0:
            arm_arrest=maxf(0,arm_arrest-dt)
            if arm_arrest<=0:boss_clock=0;say("夹臂滑出了临时卡槽。下次挡住后，团团及时拉锁。")
            return
        var before:=fmod(boss_clock,4.6)
        boss_clock+=dt
        var now:=fmod(boss_clock,4.6)
        if before<1.8 and now>=1.8:
            if shield_held and near(0,selected_slot(),ARM_RADIUS) and faces(0,MACHINE):
                arm_arrest=5.5;act(0,"brace");say("夹臂落入维修卡槽！团团趁它停稳拉下锁扣。",1)
            elif near(0,selected_slot(),ARM_RADIUS) or near(1,selected_slot(),ARM_RADIUS) or near(2,selected_slot(),ARM_RADIUS):safe_setback()
    recoil=maxf(0,recoil-dt);stroke_time=maxf(0,stroke_time-dt);wheel_motion=maxf(0,wheel_motion-dt)
    if stroke_time<=0:
        hook_held=false;wheel_held=false
    # A lure stroke is brief; unloading is a posted hold until release or movement.
    if phase=="lure" and action_time[0]<=0 and actions[0]=="hold":actions[0]=""
    if beam_held and actions[2]!="light":beam_held=false;beam_route=0
    if phase=="lure" and beam_held and not near(2,AIM_STAND,70):beam_held=false;beam_route=0
    if phase=="test":
        if pilot_open and test_beam_ready():pilot_charged=true;charged_route="tower" if pilot_route==0 else "market"
        outward_light=pilot_charged
        test_progress=0

func restore_complete()->void:
    joined=true;finished=true;allow_epilogue=true;phase="complete"
    route_lock=true;route_supported=true;route_lit=true;bridge_locked=true;arm_locked=true;lid_open=true;machine_stopped=true;stage_checkpoint=3;lid_pins=2;cleared_segments=0;extraction_side="restored";extraction_method="restored"
    tested=true;outward_light=true;network_lit=true;gear_stored=true;paws_clean=true
    lower_pin=true;upper_pin=true;left_released=false;right_released=false;worklight_seen=true;plate_aligned=true;pilot_open=true;pilot_charged=true;charged_route="tower";cat_one_clean=true;cat_two_clean=true
    farewell_gift=true;tag_inserted=true;clear_holds()
    positions=[HOME_SOFA+Vector2(-12,18),HOME_SOFA+Vector2(50,42),HOME_SOFA+Vector2(-60,40)]
    say("三位已经平安回家。可以继续走走、摸摸猫，桌上的小木灯挂件还在。")

func completion_text()->String:
    return "第五章完成 · 都在就好\n回收机构修好了，路网重新送光。朵朵、团团和圆圆回到同一个下午。\n家中仍可走动、摸猫；小木灯挂件是这趟旅程的纪念。"

func draw_world(v:Node2D)->void:
    if phase=="approach":
        v.pit(GAP)
        v.wood(Rect2(GAP.position-Vector2(8,0),Vector2(13,GAP.size.y)),Color("8d7853"))
        v.wood(Rect2(GAP.position+Vector2(GAP.size.x-5,0),Vector2(13,GAP.size.y)),Color("8d7853"))
        if bridge_locked:v.bridge(CROSSING,true)
        v.rope(LOW_LOCK,SUPPORT)
        v.prop(3,Rect2(LOW_LOCK-Vector2(21,30),Vector2(42,49)),0.0,Color.WHITE if route_lock else Color("aaa493"))
        v.machine_arm(SUPPORT,SUPPORT+Vector2(35,65) if route_supported else SUPPORT+Vector2(-20,60),12)
        v.prop(3,Rect2(SUPPORT-Vector2(17,23),Vector2(34,41)))
        v.lamp(ROUTE_LAMP,route_lit);v.arrow(ROUTE_LAMP+Vector2(55,0),Vector2.RIGHT,Color("f3d78c"))
        if route_lit:v.draw_line(ROUTE_LAMP,Vector2(490,610),Color("f4df96"),5)
        v.prop(7 if bridge_locked else 6,Rect2(CORE_GATE-Vector2(40,85),Vector2(80,106)))
        v.ink(CORE_GATE+Vector2(-85,-103),"树心维护门",190,20)
        return
    if phase in ["home","complete"]:
        v.prop(9,Rect2(HOME_RACK-Vector2(83,100),Vector2(166,126)),0.0,Color.WHITE if gear_stored else Color("a3a694"))
        v.prop(15,Rect2(HOME_BOWL-Vector2(50,35),Vector2(100,69)))
        # The background sofa is decorative; this soft seat marks the real rest anchor.
        v.prop(14,Rect2(HOME_SOFA-Vector2(84,94),Vector2(168,124)))
        v.prop(4,Rect2(765,270,100,58))
        v.lamp(Vector2(815,264),false)
        v.ink(HOME_RACK+Vector2(-78,-108),"装备已收好" if gear_stored else "装备架",170,20)
        v.ink(HOME_BOWL+Vector2(-60,65),"干净的猫爪" if paws_clean else "水盆和软布",180,20)
        if phase=="complete":v.ink(Vector2(690,625),"驿站、集市、道路，都亮着灯。",510,20)
        return
    if phase=="farewell":
        for p in [Vector2(260,300),Vector2(530,300),Vector2(830,300)]:v.lamp(p,true)
        v.prop(4,Rect2(MERCHANT-Vector2(68,-3),Vector2(136,63)))
        v.merchant(MERCHANT);v.ink(MERCHANT+Vector2(-50,-112),"挂回路灯",180,20)
        v.granny(GRANNY);v.ink(GRANNY+Vector2(-39,-112),"栗婆婆",180,20)
        if farewell_gift:v.lamp(GRANNY+Vector2(42,-12),false)
        if tag_inserted:v.draw_texture_rect_region(v.HOME,Rect2(PORTAL-Vector2(43,78),Vector2(86,120)),Rect2(190,100,560,600))
        v.prop(7 if tag_inserted else 6,Rect2(PORTAL-Vector2(66,115),Vector2(132,171)))
        v.prop(2,Rect2(PORTAL+Vector2(-23,47),Vector2(46,64)))
        if tag_inserted:v.lamp(PORTAL+Vector2(0,83),true)
        v.ink(PORTAL+Vector2(-75,121),"家门路牌灯座",210,20)
        return
    # The painted shell is independent of the real moving joints and physical locks.
    var amber:=Color("f1cd7e")
    v.prop(10,Rect2(758,219,240,237))
    v.gear(MACHINE+Vector2(-44,25),0.0 if machine_stopped else clock*0.8,30)
    v.gear(MACHINE+Vector2(42,25),0.0 if machine_stopped else -clock*0.8,27)
    var tip:=arm_tip()
    var elbow:Vector2=(MACHINE+tip)*0.5+Vector2(-55,-35)
    v.machine_arm(MACHINE+Vector2(-70,20),elbow,23)
    v.machine_arm(elbow,tip,17)
    v.prop(5,Rect2(tip-Vector2(26,26),Vector2(52,52)),elbow.angle_to_point(tip)-PI*0.5)
    if not machine_stopped and arm_locked:
        var buffer_pos:=UPPER_BUFFER if beam_route==2 else BUFFER
        var mouth:Vector2=buffer_pos+Vector2(36,-15) if phase=="lure" and beam_held else MACHINE+Vector2(90+sin(clock*1.5)*25,70)
        var pivot:=MACHINE+Vector2(55,-35)
        v.machine_arm(pivot,mouth,15)
        v.prop(5,Rect2(mouth-Vector2(27,27),Vector2(54,54)),pivot.angle_to_point(mouth)-PI*0.5)
        if phase=="lure" and beam_held:
            for i in range(3):
                var t:=fmod(clock*0.8+i*0.33,1.0)
                v.draw_circle((buffer_pos+Vector2(11,-38)).lerp(mouth,t),4,amber)
    v.prop(8,Rect2(selected_slot()-Vector2(38,24),Vector2(76,49)))
    v.draw_line(selected_slot()+Vector2(-25,-7),selected_slot()+Vector2(25,-7),amber,5)
    if phase=="shield" and arm_arrest<=0 and fmod(boss_clock,4.6)<1.8:
        var bright:=0.35+0.35*sin(boss_clock*13)
        v.draw_circle(selected_slot(),ARM_RADIUS,Color(1,0.72,0.35,bright*0.2))
        v.draw_arc(selected_slot(),ARM_RADIUS,0,TAU,48,Color(1,0.72,0.35,bright),4)
        v.arrow(selected_slot()+Vector2(0,-70),selected_slot().direction_to(MACHINE),amber)
        v.ink(selected_slot()+Vector2(-205,-75),"夹臂将落在圈内",220,22)
    if shield_held:
        v.draw_arc(positions[0]+facing[0]*25,28,facing[0].angle()-1.1,facing[0].angle()+1.1,14,Color("e9d6a4"),9)
    v.prop(3,Rect2(selected_lock()-Vector2(20,30),Vector2(40,49)),0.0,Color("b3ce9e") if arm_locked else Color.WHITE)
    v.rope(selected_lock(),selected_slot())
    # Both reversible light rails and their pins remain visible in world space.
    for index in range(2):
        var buffer_pos:=BUFFER if index==0 else UPPER_BUFFER
        var bend:=AIM_STAND if index==0 else Vector2(AIM_STAND.x,UPPER_BUFFER.y)
        var live:=phase=="lure" and beam_held and beam_route==index+1
        var rail_color:=amber if live else Color("676f65")
        v.draw_line(AIM_STAND+Vector2(11,-38),bend+Vector2(11,-38),rail_color,4);v.draw_line(bend+Vector2(11,-38),buffer_pos+Vector2(11,-38),rail_color,4)
        v.lamp(buffer_pos,live)
        var pin:=Vector2(845+index*58,455-index*20)
        v.draw_line(buffer_pos+Vector2(11,-38),pin,Color(rail_color,0.45),2)
        var pin_locked:bool=lower_pin if index==0 else upper_pin
        v.prop(3,Rect2(pin-Vector2(12,18),Vector2(24,36)),PI/2 if pin_locked else 0,Color("b3ce9e") if pin_locked else Color.WHITE)
    v.lamp(AIM_STAND,false)
    v.arrow(AIM_STAND+Vector2(30,-25),Vector2.RIGHT,amber)
    v.arrow(AIM_STAND+Vector2(-15,-45),Vector2.UP,amber)
    var wheel_angle:=lerpf(wheel_from,float(wheel_notch)*TAU/3,1-wheel_motion/0.4)+sin(recoil*30)*recoil*0.2
    if phase=="unjam":wheel_angle=unloading_wheel_angle()
    v.prop(1,Rect2(WHEEL-Vector2(43,43),Vector2(86,86)),wheel_angle)
    if lid_open:
        v.prop(11,Rect2(830,452,90,55))
        v.prop(12,Rect2(800,403,63,54),-0.95)
    else:v.prop(12,Rect2(830,452,90,55))
    if lid_open and not machine_stopped:
        var branch_points:Array[Vector2]=[LEFT_PULL+Vector2(0,10),Vector2(877,506),RIGHT_PULL+Vector2(0,10)]
        for index in range(2):
            v.draw_line(branch_points[index],branch_points[index+1],Color("392719"),14,true)
            v.draw_line(branch_points[index],branch_points[index+1],Color("bd9059"),8,true)
        v.rope(WHEEL,RIGHT_PULL+Vector2(0,15))
        if manual_load_ready():v.draw_line(RIGHT_PULL+Vector2(-22,35),RIGHT_PULL+Vector2(22,35),Color("f1cd7e"),4)
        v.ink(Vector2(710,642),"人工接重 · 右口可进" if manual_load_ready() else "轮架抬起 · 等撑扣接重" if load_held else "左口留出空隙" if support_site=="left" else "右口留出空隙" if support_site=="right" else "轮架压住折枝",350,16)
    if hook_held or stroke_time>0 and phase=="withdraw":
        var pull_end:=pull_point(extraction_side)+Vector2(0,30*(1-stroke_time/0.7)) if extraction_side in ["left","right"] else BRANCH_DISPLAY
        v.rope(positions[1]+Vector2(0,-18),pull_end)
        if recoil<=0:
            v.draw_line(pull_end+Vector2(-12,-5),pull_end+Vector2(12,13),Color("392719"),14)
            v.draw_line(pull_end+Vector2(-12,-5),pull_end+Vector2(12,13),Color("bd9059"),9)
            v.draw_line(pull_end+Vector2(12,13),pull_end+Vector2(25,6),Color("bd9059"),7)
    v.lamp(CRADLE,fixed_light)
    if fixed_light:v.draw_line(CRADLE+Vector2(11,-38),Vector2(872,462),amber,6)
    v.ink(MACHINE+Vector2(-64,-147),"停止" if machine_stopped else "回收机构",220,24)
    v.ink(MACHINE+Vector2(-74,-124),"维修进度 %d / 3"%stage_checkpoint,210,17)
    if phase in ["test","release","network"]:
        var trace:Dictionary=pilot_trace()
        v.lamp(TEST_SOURCE,trace.source_connected);v.lamp(selected_test_end()+Vector2(50,-25),tested or outward_light)
        v.draw_line(selected_test_end(),selected_test_end()+Vector2(50,-25),Color("9f8a69"),4)
        v.prop(8,Rect2(TEST_PLATE-Vector2(31,33),Vector2(62,58)),0.45 if plate_aligned else -0.55)
        for ray in trace.rays:v.draw_line(ray[0],ray[1],amber,4)
        for miss in trace.misses:
            v.draw_circle(miss,10,Color(0.95,0.84,0.55,0.16));v.draw_arc(miss,8,0,TAU,20,amber,2)
        if trace.board_connected and not trace.valve_connected and not pilot_charged:
            v.draw_line(TEST_PLATE+Vector2(0,-10),ALIGHT+Vector2(25,-25),Color("8e9bb2"),3)
            v.draw_line(ALIGHT+Vector2(16,-34),ALIGHT+Vector2(35,-15),Color("9f8a69"),5)
        if pilot_charged:
            v.draw_line(ALIGHT+Vector2(25,-25),TEST_PLATE+Vector2(0,-10),amber,3)
            v.draw_line(TEST_PLATE+Vector2(0,-10),selected_test_end()+Vector2(61,-63),amber,5)
            for i in range(5):
                var t:=fmod(clock*0.35+i*0.2,1.0)
                v.draw_circle((TEST_PLATE+Vector2(0,-10)).lerp(selected_test_end()+Vector2(61,-63),t),5,Color("fff0b4"))
        v.arrow(TEST_PLATE+Vector2(65,27),Vector2.RIGHT,amber if pilot_route==0 else Color("737e6e"))
        v.arrow(TEST_PLATE+Vector2(-65,27),Vector2.LEFT,amber if pilot_route==1 else Color("737e6e"))
        v.ink(TEST_MARKET+Vector2(-30,44),"集市试送",140,16)
        v.ink(TEST_END+Vector2(-30,44),"钟楼试送",140,16)
    v.alight(ALIGHT)
    v.prop(3,Rect2(ALIGHT+Vector2(25,-25),Vector2(34,45)),0.8 if network_lit else 0.4 if pilot_open else 0.0)
    v.lamp(ALIGHT+Vector2(44,-42),network_lit or pilot_open)
    v.ink(ALIGHT+Vector2(-25,-107),"阿灯",120,20)
    if network_lit:
        for i in range(6):
            var p:=Vector2(270+i*135,625)
            v.lamp(p,true)
            if i>0:v.draw_line(p-Vector2(135,0),p,amber,4)
        v.prop(0,Rect2(LIFT-Vector2(47,15),Vector2(94,35)))

func presentation()->Dictionary:
    var data:Dictionary=super.presentation()
    data["mechanisms"]=[
        {"id":"near_slot","position":SHIELD_SLOT,"load":arm_locked and arm_route==0,"lit":false,"angle":0.0,"connection":"selected" if arm_route==0 else "idle"},
        {"id":"far_slot","position":FAR_SLOT,"load":arm_locked and arm_route==1,"lit":false,"angle":0.0,"connection":"selected" if arm_route==1 else "idle"},
        {"id":"far_lock","position":FAR_LOCK,"load":arm_locked and arm_route==1,"lit":false,"angle":0.0,"connection":"arm"},
        {"id":"prep_handle","position":PREP_HANDLE,"load":prep_held,"lit":false,"angle":0.4 if prep_held else 0.0,"connection":"far_platform"},
        {"id":"prep_latch","position":PREP_LATCH,"load":far_walkway,"lit":false,"angle":0.5 if far_walkway else 0.0,"connection":"far_platform"},
        {"id":"work_isolator","position":ISOLATOR,"load":false,"lit":fixed_light,"angle":1.0 if isolation_open else 0.0,"connection":"isolated" if isolation_open else "main"},
        {"id":"pin_rack","position":PIN_RACK,"load":support_site=="rack","lit":false,"angle":0.0,"connection":support_site},
        {"id":"load_frame","position":Vector2(867.5,540),"load":not load_held and load_center_side()!="none","lit":false,"angle":load_tilt(),"connection":load_center_side()},
        {"id":"left_socket","position":LEFT_SOCKET,"load":support_site=="left","lit":service_open("left"),"angle":0.0,"connection":"raised" if load_held else "loaded"},
        {"id":"right_socket","position":RIGHT_SOCKET,"load":support_site=="right","lit":service_open("right"),"angle":0.0,"connection":"raised" if load_held else "loaded"}]
    data["paths"]=[{"id":"far_platform","points":[Vector2(615,312),Vector2(700,255)],"width":65.0,"state":"permanent" if far_walkway else "closed","roles":[0,1,2]},
        {"id":"service_shortcut","points":[Vector2(630,435),Vector2(735,435),Vector2(735,478),Vector2(815,478)],"width":22.0,"state":"permanent" if arm_locked and arm_route==1 else "closed","roles":[0,1,2]},
        {"id":"service_front","points":[Vector2(815,478),Vector2(1070,478)],"width":22.0,"state":"permanent","roles":[0,1,2]}]
    if phase in ["unjam","withdraw"]:
        for side in ["left","right"]:
            var point:Vector2=pull_point(side)
            data.paths.append({"id":side+"_service","points":[Vector2(point.x,540),point],"width":48.0,"state":"temporary" if service_open(side) else "closed","roles":[1]})
            data.mechanisms.append({"id":"service_jaw","position":point,"load":not service_open(side),"lit":fixed_light,"angle":load_tilt(),"connection":side})
    data["extraction_side"]=extraction_side
    data["charged_route"]=charged_route
    data["paths"].append({"id":"pilot_light","points":[ALIGHT+Vector2(25,-25),TEST_PLATE,selected_test_end()],"width":3.0,"state":"light" if pilot_charged else "dark","roles":[]})
    data["selected_test_end"]=selected_test_end()
    data["arm_route"]=arm_route;data["support_site"]=support_site;data["worklight"]=fixed_light;data["load_held"]=load_held
    data["load_center_side"]=load_center_side();data["load_tilt"]=load_tilt();data["load_return_progress"]=load_return_progress()
    data["pilot_route"]=pilot_route;data["pilot_charged"]=pilot_charged;data["lower_pin"]=lower_pin;data["upper_pin"]=upper_pin
    data["pilot_waiting"]=pilot_waiting
    data["extraction_method"]=extraction_method
    data["manual_load_ready"]=manual_load_ready()
    data["pilot_trace"]=pilot_trace()
    data["home_discoveries"]=journey_discoveries.duplicate();data["cat_one_clean"]=cat_one_clean;data["cat_two_clean"]=cat_two_clean
    return data

func social_arrived()->void:
    if gift_pending:farewell_gift=true;extras["wood_lamp"]=true;gift_pending=false
    if care_pending==1:cat_one_clean=true
    elif care_pending==2:cat_two_clean=true
    if care_pending>0:paws_clean=cat_one_clean and cat_two_clean;care_pending=-1
    if home_rest_pending:
        finished=true;phase="complete";extras["home_finished"]=true;home_rest_pending=false
