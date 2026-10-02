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
const AIM_STAND := Vector2(580,350)
const WHEEL := Vector2(1070,495)
const CRADLE := Vector2(665,600)
const REPAIR_SLOT := Vector2(875,495)
const TEST_PLATE := Vector2(755,555)
const TEST_SOURCE := Vector2(570,555)
const TEST_END := Vector2(1095,555)
const ALIGHT := Vector2(1045,335)
const LIFT := Vector2(1120,605)
const MERCHANT := Vector2(360,350)
const GRANNY := Vector2(660,425)
const PORTAL := Vector2(1090,470)
const HOME_RACK := Vector2(350,370)
const HOME_BOWL := Vector2(630,520)
const HOME_SOFA := Vector2(955,420)
var route_lock := false
var route_supported := false
var route_lit := false
var bridge_locked := false
var arm_locked := false
var lid_open := false
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
    if BODY.grow(14).has_point(p):return false
    if Rect2(830,457,90,70).has_point(p) and phase in ["lure","unjam","withdraw"]:
        return role==1 and lid_open and fixed_light
    return true

func follow_allowed(role:int,p:Vector2)->bool:
    if phase in ["shield","lure","unjam","withdraw"]:return false
    return walkable(p,role)

func faces(role:int,p:Vector2)->bool:
    return facing[role].dot(positions[role].direction_to(p))>0.82

func target(role:int)->String:
    if phase=="approach":
        if near(role,LOW_LOCK,52):return "低锁扣"
        if near(role,SUPPORT,54):return "平台撑杆"
        if near(role,ROUTE_LAMP,58):return "通道导光口"
        if bridge_locked and near(role,CORE_GATE,65):return "树心维护门"
    elif phase=="shield":
        if near(role,ARM_LOCK,62):return "机械臂锁扣"
        if near(role,SHIELD_SLOT,65):return "盾牌维修卡槽"
    elif phase=="lure":
        if near(role,AIM_STAND,66):return "缓冲导光台"
        if near(role,WHEEL,65):return "外侧维护轮"
    elif phase=="unjam":
        if near(role,CRADLE,65):return "安全固定灯座"
        if near(role,REPAIR_SLOT,64):return "检修槽折枝"
        if near(role,WHEEL,65):return "外侧维护轮"
    elif phase=="withdraw":
        if near(role,CRADLE,65):return "解除定光保持"
    elif phase=="test":
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
    return ""

func objective()->String:
    match phase:
        "approach":return "低锁、撑杆、定光：接通树心维护通路"
        "shield":return "维修一：看摆臂预兆 → 面向夹臂举盾 → 团团锁住"
        "lure":return "维修二：圆圆主动向右引光到缓冲座；朵朵保持转轮"
        "unjam":return "维修三：先固定灯光，再让团团拉枝、朵朵转轮"
        "withdraw":return "机器停稳：团团退出检修槽，再解除圆圆的定光保持"
        "test":return "真正试光：朵朵向右对准导光板，圆圆照亮测试接点"
        "release":return "测试灯没有倒流。到阿灯身边，一起打开送光闸"
        "network":return "沿路重新亮起的灯，乘升降台去告别"
        "farewell":return "经过修好的路；三位在归途门相聚，插路牌并共同确认"
        "home":return "回到同一个下午：收好装备、擦猫爪，准备好后在沙发主动结束"
        _:return "都在就好 · 已回家，可继续走动和摸猫"

func request_hint()->void:
    hints+=1
    match phase:
        "approach":say("团团拉低锁；朵朵固定上方撑杆；圆圆在左下导光口面向右侧接光。桥固定后，三位走南侧桥。")
        "shield":say("地面卡槽在机器左下。朵朵面向右上方，黄色摆臂预告快结束时举盾；停稳后团团在卡槽右边拉锁。失误不丢已修进度。")
        "lure":say("圆圆站在左上导光台，面朝右侧缓冲灯座按互动，保持光束。朵朵去机器右下，按互动持续转轮；切换角色不会放手。")
        "unjam":say("圆圆在下方安全灯座固定光。团团进盖下的窄槽按互动拉折枝；朵朵在右侧转轮让出空间。可先保持，再切换。")
        "withdraw":say("团团先从检修槽向下走到安全平台，圆圆才能在下方灯座解除保持。")
        "test":say("朵朵在中下方导光板面向右侧按互动；圆圆在左下接点也面向右侧照光，观察最右端测试灯是否持续亮起。")
        "farewell":say("三位靠近右边归途门。朵朵先插家门路牌，再由朵朵和一只猫各按一次互动，三位一起回家。")
        "home":say("先在左侧架子收装备，再到中间水盆擦猫爪。想多待一会儿就摸摸猫；准备好了到右侧沙发按互动结束。")
        _:say(objective())

func clear_holds()->void:
    beam_held=false;wheel_held=false;hook_held=false;shield_held=false
    for i in range(3):actions[i]="";action_time[i]=0.0

func interact(role:int)->void:
    if role not in [0,1,2] or action_time[role]>0.1:return
    var item:=target(role)
    if item.is_empty():return
    match item:
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
            say("第一处锁定。夹臂停住了，吸光口仍然转动——把光引到旁边的缓冲座。",2)
        "盾牌维修卡槽":say("面向机器，等黄色预告快结束时举盾。用盾挡进卡槽，再让团团拉锁。")
        "缓冲导光台":
            if role!=2:say("这里需要圆圆主动调整定光扣的朝向。");return
            if not faces(role,BUFFER):say("光偏离了缓冲座。缓冲座在导光台右边。");act(role,"paw");return
            beam_held=not beam_held;actions[2]="light" if beam_held else "";action_time[2]=0.4
            say("圆圆把光稳稳投到缓冲灯座。可以保持光束，切换给朵朵转轮。" if beam_held else "圆圆收起光束。吸光口重新朝向中央。")
        "外侧维护轮":
            if role!=0:say("维护轮要朵朵握住。团团负责检修槽，圆圆负责光。");return
            wheel_held=not wheel_held;actions[0]="hold" if wheel_held else "";action_time[0]=0.4
            say("朵朵握住维护轮持续转动。移动或再次互动会松手。" if wheel_held else "朵朵松开维护轮，已锁定的修复仍保留。")
        "安全固定灯座":
            if role!=2:say("圆圆的定光扣才能接入安全固定座。");return
            if fixed_light:say("定光扣已经在灯座上保持。先让团团退出检修槽再解开。");return
            fixed_light=true;beam_held=false;act(2,"light");say("光束接入安全固定座。圆圆可以自由走动，不需要第三路同时操作。",2)
        "检修槽折枝":
            if role!=1 or not fixed_light:say("先让圆圆把灯固定，团团才可进入检修槽。");return
            hook_held=not hook_held;actions[1]="hold" if hook_held else "";action_time[1]=0.4
            say("团团的爪钩钩住折枝。等维护轮让出空间，分段拉出。" if hook_held else "团团松开爪钩。棘轮保留已拉出的长度。")
        "解除定光保持":
            if role!=2:return
            if near(1,REPAIR_SLOT,85):say("团团还在检修槽里。先让它向下退出，再收灯。");return
            fixed_light=false;clear_holds();phase="test";say("三位退回安全平台。阿灯：如果又熄了呢？朵朵：先亮一小段，我们一起看。",1)
        "测试导光板":
            if role!=0:say("朵朵来对准导光板，圆圆照出接点。");return
            plate_aligned=faces(0,TEST_END);act(role,"hold")
            say("导光板对准右侧远灯，送出的光沿箭头前进。" if plate_aligned else "导光板还朝错方向。箭头指向右侧的远灯。")
        "测试接点":
            if role!=2:say("测试接点要圆圆的定光扣照亮。");return
            beam_held=not beam_held;actions[2]="light" if beam_held else "";action_time[2]=0.4
            say("圆圆打开测试光束；看光是在往外送，还是回到树心。" if beam_held else "圆圆暂时收光，测试可以再来。")
        "阿灯":say("阿灯：备用灯匣已经分送驿站。我会和居民一起查线路，把收、送两个闸口标清楚。" if network_lit else "阿灯：先试一段吧。我在这儿看着。")
        "阿灯送光闸":
            if role!=0:return
            network_lit=true;phase="network";clear_holds();extras["outward_verified"]=true
            say("阿灯打开送光闸。树根、集市、钟楼和运输桥依次亮起。阿灯：原来一直收着，路也会不见。",2)
        "送往集市的升降台":
            if not exit_gather(LIFT):return
            phase="farewell";clear_holds();positions=[Vector2(230,500),Vector2(285,550),Vector2(210,590)]
            say("升降台到了明亮的集市。摊主挂回路灯，栗婆婆从修好的桥上来接你们。可自由告别，再一起回家。",2)
        "挂好路灯的摊主":act(role,"pet" if role==0 else "paw");say("摊主：灯罩修好了，路灯也回来了。谢谢你们，路上慢慢走。")
        "栗婆婆的木灯挂件":
            farewell_gift=true;extras["wood_lamp"]=true;act(role,"pet" if role==0 else "paw")
            say("栗婆婆送来不带魔力的小木灯挂件，也把旅人工具赠给大家。朵朵：回去准备好好休息。",3)
        "归途门":
            if not exit_gather(PORTAL):return
            if not tag_inserted:
                if role!=0 or not home_tag:say("朵朵把记着家门的路牌插入灯座，才能找到原来的走廊。");return
                tag_inserted=true;act(role,"pet");say("家门路牌插好了。熟悉的走廊出现。朵朵：这次一起。朵朵和猫咪各确认一次。",1);return
            portal_confirms[role]=true;act(role,"pet" if role==0 else "paw")
            if portal_confirms[0] and (portal_confirms[1] or portal_confirms[2]):
                phase="home";clear_holds();positions=[Vector2(420,540),Vector2(480,580),Vector2(360,590)]
                farewell_gift=true;extras["wood_lamp"]=true;say("仍是那个下午。三位一起跨回家门，桌上多了一枚小木灯挂件。先放好装备，擦掉猫爪上的灰。",2)
            else:say("确认好了，等另一位伙伴也准备好。")
        "收好冒险装备":
            if role!=0:say("猫咪蹭了蹭装备架，等朵朵把剑盾和定光扣放好。");return
            gear_stored=true;act(role,"pet");say("背包、木剑、盾和两套猫咪装备整齐放好。今天不用再出发了。",1)
        "擦擦猫爪":
            if role!=0:return
            if not all_near(HOME_BOWL,160):say("把两只猫都带到水盆旁，检查一下猫爪。");return
            paws_clean=true;act(0,"pet");act(1,"paw");act(2,"paw");say("朵朵检查两只猫的爪子，擦掉灰。团团抱住手指，圆圆舒服地眯起眼。",3)
        "摸摸猫":home_pets+=1;act(0,"pet");say("团团舔了舔手，又抱着手指玩；圆圆把脸送到掌心。都在就好。",3)
        "安心休息 · 主动结束":
            if role!=0:return
            if not gear_stored or not paws_clean:say("先把装备收好，检查两只猫的爪子，再安心休息。");return
            if not exit_gather(HOME_SOFA):return
            finished=true;phase="complete";extras["home_finished"]=true;extras["wood_lamp"]=true
            act(0,"sit");say("朵朵：好了，现在真的可以休息了。都在就好。\n栗婆婆照看驿站，集市亮着灯，阿灯和居民一起检查道路。",2)
        "家里的沙发":act(role,"sit");say("小木灯挂件安静地放在桌上。路已经修好，大家都在家。")

func guard(role:int,held:bool)->void:
    if role!=0:return
    if held and not shield_held:shield_started=boss_clock
    shield_held=held
    if phase=="shield":actions[0]="brace" if held else ""

func tool(role:int)->void:
    if role in [1,2] and not target(role).is_empty():interact(role)
    else:request_hint()

func attack(role:int)->void:
    if role not in [0,1,2]:return
    act(role,"attack")
    say("厚外壳没有损坏。朵朵：不用敲坏它，盾挡夹臂，爪钩拉锁，定光扣引光。")

func safe_setback()->void:
    failed_sweeps+=1;arm_arrest=0;shield_held=false
    positions[0]=Vector2(590,565);actions[0]="sit";action_time[0]=0.6
    if near(1,ARM_LOCK,110):positions[1]=Vector2(760,620)
    say("柔软夹臂把朵朵推回安全垫。没有受伤；已锁定的维修不会倒退。再看一次摆动预告。")

func step(dt:float,a:Vector2,b:Vector2,enabled:bool)->void:
    if not enabled or not is_finite(dt) or dt<=0 or not a.is_finite() or not b.is_finite():return
    super.step(dt,a,b,enabled);dt=minf(dt,0.05)
    if phase=="shield":
        if arm_arrest>0:
            arm_arrest=maxf(0,arm_arrest-dt)
            if arm_arrest<=0:boss_clock=0;say("夹臂滑出了临时卡槽。下次挡住后，团团及时拉锁。")
            return
        var before:=fmod(boss_clock,4.6)
        boss_clock+=dt
        var now:=fmod(boss_clock,4.6)
        if before<1.8 and now>=1.8:
            if shield_held and near(0,SHIELD_SLOT,64) and faces(0,MACHINE) and boss_clock-shield_started<1.5:
                arm_arrest=5.5;act(0,"brace");say("夹臂落入维修卡槽！团团趁它停稳拉下锁扣。",1)
            elif near(0,SHIELD_SLOT,140) or near(1,ARM_LOCK,110):safe_setback()
    if wheel_held and (actions[0]!="hold" or not near(0,WHEEL,72)):wheel_held=false
    if hook_held and (actions[1]!="hold" or not near(1,REPAIR_SLOT,72)):hook_held=false
    if beam_held and actions[2]!="light":beam_held=false
    if phase=="lure":
        var aligned:=beam_held and near(2,AIM_STAND,70) and faces(2,BUFFER)
        if wheel_held and aligned:
            wheel_progress+=dt
            if wheel_progress>=2.3:
                lid_open=true;stage_checkpoint=2;phase="unjam";clear_holds();wheel_progress=0
                say("检修盖打开并扣牢，第二处维修保留。圆圆先把光接到下方安全固定座。",2)
        elif wheel_progress>0:
            wheel_progress=maxf(0,wheel_progress-dt*0.8)
    elif phase=="unjam":
        if hook_held and wheel_held and fixed_light:
            pull_progress+=dt
            if pull_progress>=0.9:
                pull_progress-=0.9;cleared_segments+=1
                if cleared_segments>=3:
                    machine_stopped=true;stage_checkpoint=3;phase="withdraw";clear_holds()
                    say("最后一段折枝滑出，回位扣落进“停止”槽。所有机械臂停了。团团先退出来，再让圆圆解除定光保持。",2)
        else:pull_progress=0
    elif phase=="test":
        var good:=plate_aligned and beam_held and near(2,TEST_SOURCE,72) and faces(2,TEST_END)
        outward_light=good
        if good:
            test_progress+=dt
            if test_progress>=3.0:
                tested=true;phase="release";clear_holds();outward_light=true
                say("远灯稳定亮了三秒，光没有倒流！朵朵：现在可以送大家回家了。去告诉阿灯。",2)
        else:test_progress=0

func restore_complete()->void:
    joined=true;finished=true;allow_epilogue=true;phase="complete"
    bridge_locked=true;arm_locked=true;lid_open=true;machine_stopped=true;stage_checkpoint=3
    tested=true;outward_light=true;network_lit=true;gear_stored=true;paws_clean=true
    farewell_gift=true;tag_inserted=true;clear_holds()
    positions=[Vector2(850,450),Vector2(940,510),Vector2(835,540)]
    say("三位已经平安回家。可以继续走走、摸摸猫，桌上的小木灯挂件还在。")

func completion_text()->String:
    return "第五章完成 · 都在就好\n回收机构修好了，路网重新送光。朵朵、团团和圆圆回到同一个下午。\n家中仍可走动、摸猫；小木灯挂件是这趟旅程的纪念。"

func draw_world(v:Node2D)->void:
    if phase=="approach":
        v.draw_rect(GAP,Color("303f3e"));v.bridge(CROSSING,bridge_locked)
        v.rope(LOW_LOCK,SUPPORT);v.wood(Rect2(LOW_LOCK-Vector2(25,12),Vector2(50,24)),Color("6e6550"))
        v.draw_line(SUPPORT,SUPPORT+Vector2(35,65) if route_supported else SUPPORT+Vector2(-20,60),Color("b99561"),12)
        v.lamp(ROUTE_LAMP,route_lit);v.arrow(ROUTE_LAMP+Vector2(55,0),Vector2.RIGHT,Color("f3d78c"))
        if route_lit:v.draw_line(ROUTE_LAMP,Vector2(490,610),Color("f4df96"),5)
        v.wood(Rect2(CORE_GATE-Vector2(25,45),Vector2(50,75)),Color("76694e"))
        v.ink(Vector2(180,245),"树心维护通路",400,26)
        return
    if phase in ["home","complete"]:
        v.wood(Rect2(270,290,180,100),Color("806247"))
        for i in range(3):v.draw_line(Vector2(305+i*42,300),Vector2(305+i*42,355),Color("c5b89a") if gear_stored else Color("69533b"),7)
        v.draw_circle(HOME_BOWL,30,Color("abbfc0"));v.draw_circle(HOME_BOWL,23,Color("d9e2d7"))
        v.wood(Rect2(875,330,210,135),Color("ae8976"));v.wood(Rect2(765,270,100,45),Color("77593f"))
        v.lamp(Vector2(815,264),false);v.ink(Vector2(475,245),"还是那个下午 · 都在就好",560,26)
        v.ink(Vector2(265,285),"装备架",170,20);v.ink(Vector2(575,585),"干净的猫爪" if paws_clean else "水盆和软布",180,20)
        if phase=="complete":v.ink(Vector2(690,625),"驿站、集市、道路，都亮着灯。",510,20)
        return
    if phase=="farewell":
        for p in [Vector2(260,300),Vector2(530,300),Vector2(830,300)]:v.lamp(p,true)
        v.wood(Rect2(MERCHANT-Vector2(45,25),Vector2(90,60)),Color("98714a"));v.ink(MERCHANT+Vector2(-50,-50),"挂回路灯",180,20)
        v.draw_circle(GRANNY,25,Color("b1987c"));v.ink(GRANNY+Vector2(-65,-45),"栗婆婆",180,20)
        v.draw_arc(PORTAL,65,PI,TAU,40,Color("ead8a2"),14)
        v.draw_line(PORTAL+Vector2(-65,0),PORTAL+Vector2(-65,80),Color("ad9974"),13)
        v.draw_line(PORTAL+Vector2(65,0),PORTAL+Vector2(65,80),Color("ad9974"),13)
        if tag_inserted:v.draw_rect(Rect2(PORTAL+Vector2(-46,-45),Vector2(92,117)),Color(0.95,0.85,0.58,0.28))
        v.ink(PORTAL+Vector2(-75,110),"家门路牌灯座",210,20)
        v.ink(Vector2(195,230),"经过我们修过的路",580,26)
        return
    # Rounded reclaim machine, real moving joints, directional prewarning and physical locks.
    var amber:=Color("f1cd7e")
    v.draw_circle(MACHINE+Vector2(0,32),116,Color(0.08,0.12,0.12,0.4))
    v.draw_circle(MACHINE,112,Color("7c948d"));v.draw_circle(MACHINE+Vector2(0,-22),83,Color("b9b79b"))
    v.draw_arc(MACHINE+Vector2(0,-20),85,PI,TAU,32,Color("ddd0a5"),16)
    v.gear(MACHINE+Vector2(-44,25),0.0 if machine_stopped else clock*0.8,30)
    v.gear(MACHINE+Vector2(42,25),0.0 if machine_stopped else -clock*0.8,27)
    var tip:=SHIELD_SLOT if arm_locked or arm_arrest>0 else MACHINE+Vector2(-125+sin(boss_clock*1.8)*55,95+cos(boss_clock*1.8)*45)
    var elbow:Vector2=(MACHINE+tip)*0.5+Vector2(-55,-35)
    v.draw_line(MACHINE+Vector2(-70,20),elbow,Color("5f7771"),23);v.draw_circle(elbow,17,Color("a7ae97"))
    v.draw_line(elbow,tip,Color("a8b2a4"),17)
    v.draw_arc(tip,22,0.15,PI-0.15,15,Color("d2c6a0"),9)
    if not machine_stopped and arm_locked:
        var mouth:Vector2=BUFFER+Vector2(36,-15) if phase=="lure" and beam_held else MACHINE+Vector2(90+sin(clock*1.5)*25,70)
        var pivot:=MACHINE+Vector2(55,-35)
        v.draw_line(pivot,mouth,Color("718780"),15)
        v.draw_circle(pivot,14,Color("c2b79a"))
        v.draw_arc(mouth,22,-0.8,PI+0.8,18,Color("bdc4af"),8)
        if phase=="lure" and beam_held:
            for i in range(3):
                var t:=fmod(clock*0.8+i*0.33,1.0)
                v.draw_circle(BUFFER.lerp(mouth,t),4,amber)
    v.wood(Rect2(SHIELD_SLOT-Vector2(38,15),Vector2(76,30)),Color("71664f"))
    v.draw_line(SHIELD_SLOT+Vector2(-25,-7),SHIELD_SLOT+Vector2(25,-7),amber,5)
    if phase=="shield" and arm_arrest<=0 and fmod(boss_clock,4.6)<1.8:
        var bright:=0.35+0.35*sin(boss_clock*13)
        v.draw_arc(SHIELD_SLOT,62,-PI*0.8,PI*0.1,32,Color(1,0.72,0.35,bright),6)
        v.arrow(SHIELD_SLOT+Vector2(0,-70),SHIELD_SLOT.direction_to(MACHINE),amber)
        v.ink(Vector2(535,250),"摆臂预告" if fmod(boss_clock,4.6)<1.4 else "现在举盾",220,22)
    if shield_held:
        v.draw_arc(positions[0]+facing[0]*25,28,facing[0].angle()-1.1,facing[0].angle()+1.1,14,Color("e9d6a4"),9)
    v.wood(Rect2(ARM_LOCK-Vector2(14,12),Vector2(28,25)),Color("83ab84") if arm_locked else Color("a08760"))
    v.rope(ARM_LOCK,SHIELD_SLOT)
    v.lamp(BUFFER,phase=="lure" and beam_held);v.lamp(AIM_STAND,false)
    if phase=="lure" and beam_held:v.draw_line(positions[2],BUFFER,amber,7)
    v.arrow(AIM_STAND+Vector2(30,-36),Vector2.RIGHT,amber)
    v.gear(WHEEL,clock*1.9 if wheel_held else wheel_progress,38)
    v.draw_line(WHEEL+Vector2(-12,-31),WHEEL+Vector2(12,31),Color("dec79e"),6)
    v.wood(Rect2(830,452,90,55),Color("3d504b") if lid_open else Color("b0a88f"))
    if lid_open:v.draw_line(Vector2(826,453),Vector2(801,410),Color("bcbea4"),11)
    if not machine_stopped:v.draw_line(REPAIR_SLOT+Vector2(-35-cleared_segments*12,12),REPAIR_SLOT+Vector2(38,-9),Color("805c3e"),12)
    if hook_held:v.rope(positions[1]+Vector2(0,-18),REPAIR_SLOT+Vector2(-35-cleared_segments*12,12))
    v.lamp(CRADLE,fixed_light)
    if fixed_light:v.draw_line(CRADLE,Vector2(872,462),amber,6)
    v.ink(MACHINE+Vector2(-64,-130),"停止" if machine_stopped else "回收机构",220,24)
    if phase in ["test","release","network"]:
        v.lamp(TEST_SOURCE,beam_held or tested);v.lamp(TEST_END,tested or outward_light)
        v.draw_line(TEST_PLATE+Vector2(-18,15),TEST_PLATE+Vector2(18,-15) if plate_aligned else TEST_PLATE+Vector2(-18,-20),Color("dad5b9"),9)
        if beam_held or tested:
            v.draw_line(TEST_SOURCE,TEST_PLATE,amber,4)
            v.draw_line(TEST_PLATE,TEST_END if outward_light else MACHINE,amber if outward_light else Color("8e9bb2"),5)
            for i in range(5):
                var t:=fmod(clock*0.35+i*0.2,1.0)
                v.draw_circle(TEST_PLATE.lerp(TEST_END if outward_light else MACHINE,t),5,Color("fff0b4"))
        v.arrow(TEST_PLATE+Vector2(65,27),Vector2.RIGHT,amber)
    v.draw_circle(ALIGHT,24,Color("b0a071"));v.lamp(ALIGHT+Vector2(0,-30),network_lit)
    v.ink(ALIGHT+Vector2(-25,-60),"阿灯",120,20)
    if network_lit:
        for i in range(6):
            var p:=Vector2(270+i*135,625)
            v.lamp(p,true)
            if i>0:v.draw_line(p-Vector2(135,0),p,amber,4)
        v.wood(Rect2(LIFT-Vector2(47,15),Vector2(94,35)),Color("a28a65"))
    v.ink(Vector2(125,230),"维修进度 %d / 3"%stage_checkpoint,350,24)
