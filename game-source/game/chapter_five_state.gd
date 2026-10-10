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
const FAR_LAMP := TEST_END+Vector2(50,-25)
const BRANCH_DISPLAY := REPAIR_SLOT+Vector2(88,35)
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
        if near(role,TEST_END,62):return "观察远灯"
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
        "unjam":return "折枝被轮架挤住；为弯曲的枝条让出空间"
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
        "unjam":return "bend_"+str(cleared_segments) if fixed_light else "safety"
        "withdraw":return "withdraw_cat" if near(1,REPAIR_SLOT,85) else "withdraw_light"
        "test":
            if test_beam_ready():return "observe"
            return "test_source" if plate_aligned else "test_plate"
        "farewell":return "confirm_"+str(portal_confirms[0])+str(portal_confirms[1] or portal_confirms[2]) if tag_inserted else "home_tag"
        "home":
            if not gear_stored:return "gear"
            return "rest" if paws_clean else "paws"
    return phase

func request_hint()->void:
    hints+=1
    var context:=hint_context_key()
    if context!=hint_context:hint_context=context;hint_level=0
    hint_level=mini(3,hint_level+1)
    var steps:Array=[]
    match context:
        "low_lock":steps=["平台下面有一枚低低的小锁，周围留着窄槽。","低锁牵着撑杆；窄槽里的东西需要细小的工具。","让团团走到平台左下的低锁旁，按互动或工具，用爪钩拉开。"]
        "support":steps=["低锁松开后，上方露出了一个撑杆凹槽。","只有把撑杆扣稳，平台才能承住后续的光路。","让朵朵到平台上方的撑杆旁按互动，把撑杆压进凹槽。"]
        "route_light":steps=["平台已经撑稳，但左下的导光口还暗着。","导光口要朝着平台对侧接光，机械销才会落锁。","让圆圆站在左下导光口，朝右按互动或工具。"]
        "cross":steps=["桥边的销已经落下，南侧出现了连续的木板路。","已经锁稳的桥不靠持续照明；伙伴都到门边才能一起进去。","沿南侧桥走到右边的维护门，等三位靠近后按互动。"]
        "guard":steps=["地面黄色圈对应夹臂落下的位置，旁边还有一个维修卡槽。","盾要迎着来臂的方向；正确举盾可以一直保持，不必猜隐藏时限。","让朵朵站进黄色圈，面向右上方的机器，按住举盾，等夹臂落入槽内。"]
        "arm_latch":steps=["夹臂暂时停住后，右边露出了一个小锁扣。","临时卡槽会松开，小锁扣才能把这次停稳变成永久固定。","趁夹臂还停着，让团团到卡槽右侧的小锁旁按互动或工具。"]
        "lid_0":steps=["吸光口旁有上下两个缓冲座，盖边的下销仍受着压力。","吸口会朝亮着的缓冲座偏转，同侧受压的销才有空间松开。","让圆圆在导光台朝右接通下方缓冲座，再让朵朵在外侧维护轮按一次互动。"]
        "lid_1":steps=["下销已经扣牢，上销还被吸口压住。","已锁住的销不会回退，但另一枚需要不同的缓冲光路。","让圆圆在导光台朝上重新接光，再让朵朵在维护轮按一次互动，扣住上销。"]
        "safety":steps=["打开的检修盖下很暗，下方还有一个独立灯座。","安全灯座能固定光，不需要持续占住一位操作者。","让圆圆到下方安全灯座按互动或工具，把定光扣接入；再查看盖下的弯枝。"]
        "bend_0","bend_1","bend_2":
            var direction:String=["左","上","右"][branch_direction()]
            var turns:=(branch_direction()-wheel_notch+3)%3
            if turns==0 and not wheel_ready:turns=3
            var method:="缺口已经让到正确的一侧。让团团在检修槽旁按互动或工具，主动拉出这一段。"
            if turns>0:method="当前弯枝朝%s。让朵朵在维护轮再按%s互动，把缺口让到%s侧；再让团团拉一次爪钩。"%[direction,["","一次","两次","三次"][turns],direction]
            steps=["这一段枝条有明显弯折，旁边的轮架只留出一处缺口。","缺口应让到弯枝伸出的一侧；拉过一段后，下一处弯折可能不同。",method]
        "withdraw_cat":steps=["机器已经停止，检修槽里还有伙伴，安全光仍亮着。","槽里有人时不能收灯；固定的棘轮会留住全部修复。","让团团从检修槽向下走，直到离开槽口、站回下面的平台。"]
        "withdraw_light":steps=["检修槽已经空了，安全灯座上的光还没有收回。","收回工具前要确认伙伴在安全处；现在可以解除定光保持。","让圆圆到安全灯座按互动或工具，收回定光扣。"]
        "test_plate":steps=["测试光路中间有一块可转动的板，右侧远灯还是暗的。","导光板决定光是向外走，还是重新回到树心。","让朵朵在中下方测试导光板旁，朝右边远灯按互动。"]
        "test_source":steps=["导光板已经朝向远端，左下的测试接点还没有有效光束。","试送只需要一小段连续光路；接点的朝向也必须通向远灯。","让圆圆到左下测试接点，面向右侧，按互动或工具接光。"]
        "observe":steps=["远处的接收灯已经亮了，光正在离开树心。","修复需要亲自确认送达的结果，亮着等待不会自动完成测试。","让朵朵走到右侧远灯的底座旁按互动，确认光已经送到。"]
        "release":steps=["试送成功后，送光闸旁的阿灯还在等消息。","远灯的验证只覆盖一小段，整条路网还需要打开送光闸。","让朵朵到机器右上方的阿灯身边按互动，一起打开闸口。"]
        "network":steps=["送光台下方的灯一路亮到了右下角。","升降台通向集市，但要让三位一起搭乘。","让三位靠近右下角升降台，再按互动前往集市。"]
        "home_tag":steps=["右侧归途门的灯座上，留着一个熟悉的路牌插口。","路牌记着来时的家门；居民的告别可以慢慢来，不会错过归途。","让三位靠近归途门，再让朵朵按互动插入家门路牌。"]
        "confirm_falsefalse","confirm_truefalse","confirm_falsetrue","confirm_truetrue":
            var next:="朵朵" if not portal_confirms[0] else "团团或圆圆"
            steps=["熟悉的走廊已经出现，门前还有等待确认的位置。","插路牌和愿意出发是两件事；三位要在门边，主角和一只猫各确认一次。","让%s在归途门旁按互动确认；三位仍需一起靠近门。"%next]
        "gear":steps=["家里左侧的装备架还空着，冒险工具还没有归位。","安心休息前，先给带回来的工具找个固定位置。","让朵朵到左侧装备架旁按互动，收好冒险装备。"]
        "paws":steps=["中间的水盆旁放着软布，猫爪上还有路上的灰。","检查猫爪时，两只猫都要在水盆旁边。","把三位带到水盆旁，让朵朵按互动擦拭并检查猫爪。"]
        "rest":steps=["装备和猫爪都整理好了，右侧沙发空着。","这一段没有自动结束的倒计时，可以多待一会儿再决定休息。","让三位靠近右侧沙发，由朵朵按互动，主动结束冒险。"]
        _:steps=["三位都回到了家，小木灯挂件留在桌上。","已经完成的故事可以保留，家里仍能自由走动。","可以靠近猫咪摸摸它们，或到沙发坐一会儿。"]
    if phase=="lure" and beam_held and beam_route==lid_pins+1 and near(2,AIM_STAND,70) and actions[2]=="light":
        steps[2]="当前缓冲光路已经正确，保持它亮着。让朵朵在外侧维护轮按一次互动，扣住露出的销。"
    say("提示 %d / 3 · %s"%[hint_level,steps[hint_level-1]])

func clear_holds()->void:
    beam_held=false;wheel_held=false;hook_held=false;shield_held=false
    beam_route=0;wheel_ready=false;recoil=0;stroke_time=0;wheel_motion=0;wheel_from=0
    for i in range(3):actions[i]="";action_time[i]=0.0

func interact(role:int)->void:
    if role not in [0,1,2] or action_time[role]>0.1:return
    var item:=target(role)
    if item.is_empty():return
    match item:
        "检查维护轮":say("轮架已经停稳了。" if machine_stopped else "夹臂仍在扫动，轮架还被安全锁扣住。先看看地上的维修槽。")
        "检查安全灯座":say("安全灯座照着检修槽，检修盖打开后才能接入。" if not lid_open else "安全灯已完成工作，检修槽里没有转动的构件了。")
        "检查导光轨":say("两条导轨通向不同的缓冲座。" if not lid_open else "缓冲座已卸下检修盖的压力，两枚销保持锁定。")
        "检查检修盖":say("盖上的销还被吸光口压住，不能硬拉。" if not lid_open else "检修盖已锁在打开的位置，折枝已经取出。")
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
            say("第一处锁定。夹臂停住了，吸光口仍然转动——把光引到旁边的缓冲座。",2)
        "盾牌维修卡槽":say("黄色圈是夹臂将接触的范围。面向机器举盾可以一直挡住，停稳后小锁才够得到。")
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
            wheel_from=float(wheel_notch)*TAU/3;wheel_motion=0.4
            act(0,"hold",0.4);wheel_held=true;stroke_time=0.55
            if phase=="lure":
                wheel_notch=lid_pins+1
                if beam_held and beam_route==lid_pins+1:
                    lid_pins+=1;wheel_progress=float(lid_pins)
                    say("维护轮扣住露出的销。另一枚仍被吸口压着，光路需要重新调整。",1)
                    if lid_pins==2:
                        lid_open=true;stage_checkpoint=2;phase="unjam";clear_holds();wheel_notch=0
                        say("两枚销都锁稳，检修盖翻开了。盖下的折枝仍受着轮架挤压。",2)
                else:
                    recoil=0.6;say("轮扣碰到遮住的销，轻轻弹回。吸口仍在这边，已锁住的销没有松。")
            else:
                wheel_notch=(wheel_notch+1)%3;wheel_ready=true
                say("卸力架换到下一处缺口，固定住了。看看折枝能否沿着空隙出来。",1)
        "安全固定灯座":
            if role!=2:say("圆圆的定光扣才能接入安全固定座。");return
            if fixed_light:
                if near(1,REPAIR_SLOT,85):say("团团还在检修槽里。先让它向下退出，再收灯。");return
                fixed_light=false;actions[2]="";say("圆圆收回安全光，已经拉出的枝条由棘轮锁住。");return
            fixed_light=true;beam_held=false;act(2,"light");say("光束接入安全固定座。圆圆可以自由走动，不需要第三路同时操作。",2)
        "检修槽折枝":
            if role!=1 or not fixed_light:say("安全光还没接好，窄槽里看不清。");return
            hook_held=true;act(1,"paw",0.55);stroke_time=0.55
            if not wheel_ready or wheel_notch!=branch_direction():
                recoil=0.6;say("弯枝顶住了轮架，爪钩轻轻弹回。换个卸力方向再试，棘轮留住了已拉出的部分。");return
            cleared_segments+=1;pull_progress=0;wheel_ready=false
            say("团团主动拉出一段，棘轮咔哒锁稳。下一处弯折露出来了。",1)
            if cleared_segments>=3:
                machine_stopped=true;stage_checkpoint=3;phase="withdraw";clear_holds()
                act(1,"paw",0.55);stroke_time=0.55
                say("最后一段折枝滑出，回位扣落进停止槽。团团先退到安全平台，再收灯。",2)
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
        "观察远灯":
            if role!=0:say("远灯的接点就在这里，等朵朵来一起确认。");return
            if not test_beam_ready():say("远灯还暗着。回头看看光在哪个接点拐走了。");return
            tested=true;phase="release";clear_holds();outward_light=true;act(0,"pet")
            say("朵朵摸了摸远灯底座：光送到这里了，没有回流。可以去告诉阿灯。",2)
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
    if role==0:
        guard(0,not shield_held)
        if phase!="shield":say("朵朵举起盾观察周围，附近没有摆动的夹臂。")
    elif role==1 and target(role) in ["低锁扣","机械臂锁扣","检修槽折枝"]:interact(role)
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
    return [1,0,2][mini(cleared_segments,2)]

func test_beam_ready()->bool:
    return plate_aligned and beam_held and near(2,TEST_SOURCE,72) and actions[2]=="light" and faces(2,TEST_END)

func arm_tip()->Vector2:
    if arm_locked or arm_arrest>0:return SHIELD_SLOT
    var t:=fmod(boss_clock,4.6)
    var rest:=Vector2(715,370)
    if t<=1.8:return rest.lerp(SHIELD_SLOT,smoothstep(1.1,1.8,t))
    return SHIELD_SLOT.lerp(rest,smoothstep(1.95,2.65,t))

func attack(role:int)->void:
    if role not in [0,1,2]:return
    act(role,"attack")
    say("厚外壳没有损坏。朵朵：不用敲坏它，盾挡夹臂，爪钩拉锁，定光扣引光。")

func safe_setback()->void:
    failed_sweeps+=1;arm_arrest=0;shield_held=false
    var pads:=[Vector2(590,565),Vector2(760,620),Vector2(575,620)]
    for role in available_roles():
        if near(role,SHIELD_SLOT,ARM_RADIUS):positions[role]=pads[role];actions[role]="sit";action_time[role]=0.6
    say("柔软夹臂把圈内的伙伴推回安全垫。没有受伤；圈外安全，已锁定的维修不倒退。")

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
            if shield_held and near(0,SHIELD_SLOT,ARM_RADIUS) and faces(0,MACHINE):
                arm_arrest=5.5;act(0,"brace");say("夹臂落入维修卡槽！团团趁它停稳拉下锁扣。",1)
            elif near(0,SHIELD_SLOT,ARM_RADIUS) or near(1,SHIELD_SLOT,ARM_RADIUS) or near(2,SHIELD_SLOT,ARM_RADIUS):safe_setback()
    recoil=maxf(0,recoil-dt);stroke_time=maxf(0,stroke_time-dt);wheel_motion=maxf(0,wheel_motion-dt)
    if stroke_time<=0:
        hook_held=false;wheel_held=false
        if actions[0]=="hold" and phase in ["lure","unjam"]:actions[0]=""
    if beam_held and actions[2]!="light":beam_held=false;beam_route=0
    if phase=="lure" and beam_held and not near(2,AIM_STAND,70):beam_held=false;beam_route=0
    if phase=="test":
        outward_light=test_beam_ready()
        test_progress=0

func restore_complete()->void:
    joined=true;finished=true;allow_epilogue=true;phase="complete"
    route_lock=true;route_supported=true;route_lit=true;bridge_locked=true;arm_locked=true;lid_open=true;machine_stopped=true;stage_checkpoint=3;lid_pins=2;cleared_segments=3
    tested=true;outward_light=true;network_lit=true;gear_stored=true;paws_clean=true
    farewell_gift=true;tag_inserted=true;clear_holds()
    positions=[Vector2(850,450),Vector2(940,510),Vector2(835,540)]
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
    v.prop(8,Rect2(SHIELD_SLOT-Vector2(38,24),Vector2(76,49)))
    v.draw_line(SHIELD_SLOT+Vector2(-25,-7),SHIELD_SLOT+Vector2(25,-7),amber,5)
    if phase=="shield" and arm_arrest<=0 and fmod(boss_clock,4.6)<1.8:
        var bright:=0.35+0.35*sin(boss_clock*13)
        v.draw_circle(SHIELD_SLOT,ARM_RADIUS,Color(1,0.72,0.35,bright*0.2))
        v.draw_arc(SHIELD_SLOT,ARM_RADIUS,0,TAU,48,Color(1,0.72,0.35,bright),4)
        v.arrow(SHIELD_SLOT+Vector2(0,-70),SHIELD_SLOT.direction_to(MACHINE),amber)
        v.ink(SHIELD_SLOT+Vector2(-205,-75),"夹臂将落在圈内",220,22)
    if shield_held:
        v.draw_arc(positions[0]+facing[0]*25,28,facing[0].angle()-1.1,facing[0].angle()+1.1,14,Color("e9d6a4"),9)
    v.prop(3,Rect2(ARM_LOCK-Vector2(20,30),Vector2(40,49)),0.0,Color("b3ce9e") if arm_locked else Color.WHITE)
    v.rope(ARM_LOCK,SHIELD_SLOT)
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
        v.prop(3,Rect2(pin-Vector2(12,18),Vector2(24,36)),PI/2 if lid_pins>index else 0,Color("b3ce9e") if lid_pins>index else Color.WHITE)
    v.lamp(AIM_STAND,false)
    v.arrow(AIM_STAND+Vector2(30,-25),Vector2.RIGHT,amber)
    v.arrow(AIM_STAND+Vector2(-15,-45),Vector2.UP,amber)
    var wheel_angle:=lerpf(wheel_from,float(wheel_notch)*TAU/3,1-wheel_motion/0.4)+sin(recoil*30)*recoil*0.2
    v.prop(1,Rect2(WHEEL-Vector2(43,43),Vector2(86,86)),wheel_angle)
    if phase=="unjam":
        var dirs:=[Vector2.LEFT,Vector2.UP,Vector2.RIGHT]
        for i in range(3):
            v.arrow(WHEEL+dirs[i]*54,dirs[i],amber if wheel_notch==i else Color("737e6e"))
    if lid_open:
        v.prop(11,Rect2(830,452,90,55))
        v.prop(12,Rect2(800,403,63,54),-0.95)
    else:v.prop(12,Rect2(830,452,90,55))
    if phase=="unjam":
        var gap_angle:float=[PI,-PI/2,0.0][wheel_notch]
        # Wooden jaws surround the branch except on the selected unloading side.
        v.draw_arc(BRANCH_DISPLAY,43,gap_angle+0.65,gap_angle+TAU-0.65,40,Color("493f33"),15)
        v.draw_arc(BRANCH_DISPLAY,43,gap_angle+0.65,gap_angle+TAU-0.65,40,Color("b6a078"),8)
        v.draw_line(BRANCH_DISPLAY+Vector2(45,0),WHEEL+Vector2(-40,0),Color("9f8a69"),3)
        v.machine_arm(REPAIR_SLOT+Vector2(18,8),BRANCH_DISPLAY+Vector2(-45,0),8)
    if lid_open and not machine_stopped:
        var dirs:=[Vector2.LEFT,Vector2.UP,Vector2.RIGHT]
        var root_point:=BRANCH_DISPLAY
        var bend:Vector2=root_point+dirs[branch_direction()]*34+Vector2(sin(recoil*30)*recoil*16,0)
        var branch_dir:Vector2=dirs[branch_direction()]
        var end_point:=bend+branch_dir*12+branch_dir.orthogonal()*22
        for segment in [[root_point,bend],[bend,end_point]]:
            v.draw_line(segment[0],segment[1],Color("392719"),15,true)
            v.draw_line(segment[0],segment[1],Color("bd9059"),9,true)
            v.draw_line(segment[0]+Vector2(0,-2),segment[1]+Vector2(0,-2),Color("e1bf83"),2,true)
        v.draw_circle(bend,7,Color("392719"));v.draw_circle(bend,4,Color("d6b079"))
        v.draw_line(end_point,end_point+branch_dir.orthogonal()*10,Color("392719"),5,true)
        v.ink(BRANCH_DISPLAY+Vector2(-38,75),"棘轮 %d / 3"%cleared_segments,150,16)
    if hook_held or stroke_time>0 and phase=="withdraw":
        var pull_end:=BRANCH_DISPLAY+Vector2(-sin(stroke_time/0.55*PI)*22,0)
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
        v.lamp(TEST_SOURCE,beam_held or tested);v.lamp(FAR_LAMP,tested or outward_light)
        v.draw_line(TEST_END,FAR_LAMP,Color("9f8a69"),4)
        v.prop(8,Rect2(TEST_PLATE-Vector2(31,33),Vector2(62,58)),0.45 if plate_aligned else -0.55)
        if beam_held or tested:
            v.draw_line(TEST_SOURCE+Vector2(11,-38),TEST_PLATE+Vector2(0,-10),amber,4)
            v.draw_line(TEST_PLATE+Vector2(0,-10),FAR_LAMP+Vector2(11,-38) if outward_light else MACHINE,amber if outward_light else Color("8e9bb2"),5)
            for i in range(5):
                var t:=fmod(clock*0.35+i*0.2,1.0)
                v.draw_circle((TEST_PLATE+Vector2(0,-10)).lerp(FAR_LAMP+Vector2(11,-38) if outward_light else MACHINE,t),5,Color("fff0b4"))
        v.arrow(TEST_PLATE+Vector2(65,27),Vector2.RIGHT,amber)
    v.alight(ALIGHT)
    v.prop(3,Rect2(ALIGHT+Vector2(25,-25),Vector2(34,45)),0.8 if network_lit else 0.0)
    v.lamp(ALIGHT+Vector2(44,-42),network_lit)
    v.ink(ALIGHT+Vector2(-25,-107),"阿灯",120,20)
    if network_lit:
        for i in range(6):
            var p:=Vector2(270+i*135,625)
            v.lamp(p,true)
            if i>0:v.draw_line(p-Vector2(135,0),p,amber,4)
        v.prop(0,Rect2(LIFT-Vector2(47,15),Vector2(94,35)))
