extends "res://game/story_chapter_base.gd"
## The shell and the recovery machine are two separate faults.
const PIT := Rect2(190,325,220,100)
const RETURN_PLANK := Rect2(266,325,58,115)
const HOOK := Vector2(230,467)
const COVER := Vector2(295,358)
const MARKET_LIGHT := Vector2(443,470)
const CATCH := Vector2(365,474)
const ALIGHT := Vector2(565,280)
const DUCT_LIGHT := Vector2(625,430)
const DUCT := Vector2(625,290)
const BRANCH := Vector2(715,290)
const ARROWS := Vector2(778,405)
const PATCH := Vector2(1040,300)
const LATCH := Vector2(1120,365)
const SEAM_LIGHT := Vector2(918,430)
const HOME := Vector2(520,580)
const REST := Vector2(835,580)
const STALL_LAMP:=Vector2(300,270)
const VIEW_LAMP:=Vector2(1090,595)
const MARKET_DOOR:=Vector2(420,410)
const VIEW_DOOR:=Vector2(980,530)
var visit_room:=""
var visit_pending:="none"
var lamp_dest:="rack"
var stall_seen:=false
var view_seen:=false
var early_patch:=false
var shell_examined:=false
var reconnected_seen:=false
var reserve_available:=false
var cover_hooked := false
var cover_carried := false
var cloth := false
var market_beam := false
var duct_seen := false
var branch_seen := false
var arrows_seen := false
var patch_braced := false
var latch_fixed := false
var seam_seen := false
var shell_fixed := false
var inward_verified := false
var lantern_offered := false
var reserve_retained := false
# Only the witnessed facts are checkpoint-worthy. A pulse and its display charge
# belong to the current experiment and are cleared when restoring a safe point.
var route_split := false
var bypass_isolated := false
var main_return_seen := false
var connected_split_seen := false
var hint_level := 0
var hint_context := ""
var shell_leak_seen := false
var reserve_hold_seen := false
var trial_count := 0
var pulse_active := false
var pulse_elapsed := 0.0
var return_charge := 0.0
var leak_charge := 0.0
var reserve_charge := 0.0
var return_flash_time := 0.0
const TRIAL_SECONDS := 1.2
const SPLITTER := Vector2(778,340)
const RESERVE := Vector2(855,295)
const SHELL_TEST := Vector2(994,314)


func _init() -> void:
    chapter=4;chapter_key="chapter-four";title="第四章 · 灯光躲起来了";joined=true;phase="market"
    positions=[Vector2(170,505),Vector2(215,550),Vector2(265,585)]
    say("集市的小备用灯还亮着，回家的主路却暗了。摊主：我的灯罩掉到下面了……")

func aimed(role:int,origin:Vector2,destination:Vector2)->bool:
    return near(role,origin,68) and facing[role].dot(positions[role].direction_to(destination))>0.7

func room_name()->String:
    if not visit_room.is_empty():return visit_room
    return "market" if phase=="market" else "exterior" if phase in ["exterior","battle_two"] else "interior"
func walkable(p:Vector2,role:int)->bool:
    if not super.walkable(p,role):return false
    if room_name()=="market" and PIT.has_point(p):return role==1 and market_beam and cover_hooked and RETURN_PLANK.has_point(p)
    return true

func follow_allowed(role:int,p:Vector2)->bool:
    # A dormant cat never walks into an illuminated but temporary route.
    return (room_name()!="market" or not PIT.grow(12).has_point(p)) and walkable(p,role)

func step(dt:float,a:Vector2,b:Vector2,enabled:bool)->void:
    if social_transition_active():
        if enabled and is_finite(dt) and dt>0 and a.is_finite() and b.is_finite():step_social_transition(dt)
        return
    if not enabled or not is_finite(dt) or dt<=0 or not a.is_finite() or not b.is_finite():return
    if dialogue_active() or social_transition_active():return
    super.step(dt,a,b,enabled)
    if phase=="battle_two" and reserve_retained and not battle_requested:battle_requested=true
    if not enabled or finished:return
    dt=minf(dt,0.05)
    step_trial(dt)
    market_beam=actions[2]=="light" and aimed(2,MARKET_LIGHT,COVER)
    patch_braced=actions[0]=="brace" and near(0,PATCH)
    # Extinguishing a temporary path safely returns the carrier to its bank.
    if room_name()=="market" and PIT.has_point(positions[1]) and not market_beam:
        positions[1]=Vector2(295,446)
        say("团团退回宽岸。圆圆的光移开了，踏板又藏进阴影。")

func target(role:int)->String:
    if finished:return ""
    if not visit_room.is_empty():
        var door:Vector2=MARKET_DOOR if visit_room=="market" else VIEW_DOOR
        if near(role,door,52):return "回阿灯屋"
        if visit_room=="market":
            if reserve_available and near(role,STALL_LAMP,55):return "集市备用灯座"
            if near(role,Vector2(182,290),60):return "重新摆摊的摊主"
        elif visit_room=="exterior":
            if cloth and phase in ["meet","investigate"] and near(role,PATCH,60):return "查看破罩"
            if reserve_available and near(role,VIEW_LAMP,55):return "观景台灯座"
        return ""
    if phase in ["meet","investigate","test","offer","home_offer","rest"]:
        if near(role,MARKET_DOOR,48):return "去集市灯座"
        if near(role,VIEW_DOOR,48):return "去观景外廊"
    if reserve_available and phase in ["investigate","test","offer","home_offer","rest"]:
        if near(role,RESERVE,38):return "独立小灯把手"
    if phase=="market":
        if cover_carried and near(role,CATCH):return "接住灯罩"
        if role==1 and cover_hooked and near(role,COVER,43):return "低处灯罩"
        if near(role,MARKET_LIGHT,62):return "照向低处"
        if near(role,HOOK,62):return "灯罩拉环"
        if near(role,CATCH,54):return "接物宽岸"
    if phase in ["meet","investigate","test","offer"]:
        if near(role,ALIGHT):return "阿灯"
        if near(role,DUCT_LIGHT,60):return "暗槽照灯架"
        if near(role,BRANCH,60):return "旁路隔离扣"
        if near(role,ARROWS,60):return "收送试光柄"
    if phase=="exterior":
        if near(role,SEAM_LIGHT,60):return "外罩照灯架"
        if near(role,LATCH,60):return "外罩固定扣"
        if near(role,PATCH,60):return "破防风罩"
    if phase=="home_offer" and near(role,HOME,80):return "应急归途灯匣"
    if phase=="rest" and near(role,REST,85):return "树心前的休息桌"
    return ""

func interact(role:int)->void:
    if role not in available_roles() or finished or battle_requested or action_time[role]>0 or dialogue_active() or social_transition_active():return
    var item:=target(role)
    if item=="":return
    if item=="暗槽照灯架" and role==2 and actions[2]=="light":
        release_trial_light();return
    act(role,"touch")
    match item:
        "去集市灯座","去观景外廊","回阿灯屋":
            if role!=0:say("团团和圆圆在门边等朵朵一起走。");return
            var destination:Vector2=MARKET_DOOR if item=="去集市灯座" or visit_room=="market" else VIEW_DOOR
            visit_pending="" if item=="回阿灯屋" else "market" if item=="去集市灯座" else "exterior"
            if pulse_active:cancel_trial()
            actions[2]="";market_beam=false
            stage_social([],{"role":0,"kind":"travel","target":destination,"duration":0.1,"participants":[0,1,2]}, {0:destination+Vector2(20,30),1:destination+Vector2(45,50),2:destination+Vector2(70,70)})
        "重新摆摊的摊主":say("摊主在小灯下铺好布：这会儿可以看清灯罩的花纹了。" if lamp_dest=="stall" else "摊主把灯罩抱在怀里，等摊面再亮一些。")
        "查看破罩":
            shell_examined=true
            if role==0:
                early_patch=true;act(0,"touch")
                observe("shell_wind","补片盖住一角，那里安静了；没压住的布边仍被余风吹起。",PATCH)
            else:observe("shell_wind","罩上的裂口透着风，里面的灯匣跟着晃。",PATCH)
        "独立小灯把手":
            if role!=0:say("封好的小灯有一个适合手提的把手。");return
            if lamp_dest=="rack":
                lamp_dest="carried";reserve_charge=0;observe("lamp_carried","朵朵提起仍亮着的小灯，实验台的灯架空了。",RESERVE)
            elif lamp_dest=="carried":
                lamp_dest="rack";reserve_charge=0.5;observe("lamp_returned","小灯回到试验架上。",RESERVE)
            else:say("小灯已经摆到另一处灯座，要从那里提回来。")
        "集市备用灯座","观景台灯座":
            if role!=0:say("封好的小灯有一个适合手提的把手。");return
            var destination:String="stall" if item=="集市备用灯座" else "view"
            if lamp_dest==destination:lamp_dest="carried";observe("lamp_carried","朵朵提起小灯，原来的灯座重新暗下来。",STALL_LAMP if destination=="stall" else VIEW_LAMP);return
            if lamp_dest!="carried":say("灯座是空的，摆在这里的小灯能照亮周围。");return
            lamp_dest=destination
            if lamp_dest=="stall":
                stall_seen=true;observe("stall_open","独立的小灯照亮摊面。摊主重新铺好布，摆出了带回家的小灯罩。",STALL_LAMP)
            else:
                view_seen=true;observe("view_open","观景台亮起来，风暴留下的折枝方向清清楚楚；远处钟楼还在等灯。",VIEW_LAMP)
        "灯罩拉环":
            if role!=1:say("铁环在低处，团团的爪钩够得着。");return
            cover_hooked=true;say("爪钩把灯罩拉到旧踏板尽头。踏板还埋在阴影里。",1)
        "照向低处":
            if role!=2:say("灯架的凹槽正好能托住圆圆的定光扣。");return
            if not aimed(2,MARKET_LIGHT,COVER):say("光斑落在宽岸上。圆圆可以面向左上方的低处，再架好光。 ");return
            act(2,"light");market_beam=true;say("圆圆的光照出一排有扶绳的返回踏板。",1)
        "低处灯罩":
            if role!=1 or not market_beam or not cover_hooked:return
            cover_carried=true;say("团团叼住灯罩，沿亮着的踏板原路返回。朵朵在宽岸接应。",1)
        "接住灯罩":
            if role!=0:say("团团把灯罩举向朵朵，等她接稳。");return
            if not near(1,CATCH,90) or PIT.has_point(positions[1]):say("朵朵伸出手，等团团沿踏板回到宽岸。");return
            cloth=true;cover_carried=false;phase="meet";actions[2]="";market_beam=false
            say("朵朵接稳灯罩。摊主：谢谢！这块修补布请带给灯树里的阿灯。",2)
        "接物宽岸":say("朵朵在宽岸伸手：团团，把灯罩带回来，我接着。")
        "阿灯":
            if role!=0:say("阿灯蹲下摸摸猫猫：我一直守着送光台，没有带走圆圆。");return
            if phase=="meet":
                phase="investigate"
                start_dialogue(["阿灯：昨夜风很大。我试着送光，可它们又回来了。","阿灯：停止杆也拉不动。我怕把最后的光弄丢。","朵朵：先试一小段，看看它真的去了哪里。"],{"role":0,"kind":"inspect","target":ALIGHT,"duration":1.5,"participants":[0,1,2]})
            elif phase=="investigate":
                if not diagnosis_ready():
                    say("阿灯：我看见的光会回来。你们的小灯为什么能留下？我们还得比较连接改变后的结果。");return
                arrows_seen=true;phase="battle_one";battle_requested=true;battle_waves=2
                clear_trial();actions[2]=""
                say("小灯被隔开时留住光，连回去却被收走。朵朵：余风和回收，是两件事。",1)
            elif phase=="offer" and inward_verified:
                lantern_offered=true;phase="home_offer"
                say("阿灯：备用灯匣不接主线，够你们三个一起回家。\n门里的沙发和猫垫亮了。主线还没修好。",2)
            else:say("阿灯：小备用灯和主线分开存着光，所以集市能歇脚。可回家的路还接在主线上。")
        "暗槽照灯架":
            if phase not in ["investigate","test"]:return
            if role!=2:say("这里的架子能固定圆圆的光，照进上方的暗槽。");return
            if not aimed(2,DUCT_LIGHT,DUCT):say("光落在槽外。圆圆要面向上方的暗槽，再固定定光扣。");return
            act(2,"light");duct_seen=true
            say("圆圆稳住试光源。试光柄旁有两条槽：一条接主机，一条接小灯。再互动或用工具可以撤光。",1)
        "旁路隔离扣":
            if phase not in ["investigate","test"]:return
            if role!=1:say("窄槽里的小隔离扣适合团团的爪钩。它只控制旁路。");return
            if not trial_lit():say("扣后太暗了，团团看不清，先把试光源稳住。");return
            if pulse_active:cancel_trial()
            branch_seen=true;bypass_isolated=not bypass_isolated
            if not bypass_isolated and reserve_charge>0 and lamp_dest=="rack":
                reconnected_seen=true;reserve_available=false;reserve_charge=0;return_charge=1;return_flash_time=1.2
                say("团团合回旁路，刚留住的光沿连接槽被主机吸走。折枝仍卡在主机里，没有被拔动。",1)
            else:
                say("团团打开旁路隔离扣，小灯和主机断开了。扣后能看见折枝，主机里的枝条不能强拔。" if bypass_isolated else "团团合回隔离扣，小灯重新连上主机。",1)
        "收送试光柄":
            if role!=0:say("试光柄有些重，让朵朵切换主线和分光，再用工具送一缕测试光。");return
            if phase not in ["investigate","test"]:return
            if pulse_active:cancel_trial()
            route_split=not route_split
            say("朵朵把镜片转向分光槽。工具键送出一缕测试光。" if route_split else "朵朵把镜片转回主线。工具键送出一缕测试光。",1)
        "破防风罩":
            if role!=0:say("补片需要朵朵撑稳，才能够到外侧的固定扣。");return
            if not cloth or not arrows_seen:return
            shell_examined=true
            if not latch_fixed:
                act(0,"brace");patch_braced=true;say("朵朵把修补布撑在破口。她不动时，团团就能拉来外侧固定扣。",1)
            elif seam_seen:
                shell_fixed=true;patch_braced=false;actions[0]="";actions[2]="";phase="test";visit_room="exterior"
                route_split=false;clear_trial()
                say("朵朵压牢最后一道扣槽，罩内的风停了。回试光台送一缕光，看看修补改变了什么。",2)
            else:say("扣子已经固定住补片，阴影里还有一道没有压紧的边。")
        "外罩固定扣":
            if role!=1:say("外侧固定扣离平台有一小段距离，团团的爪钩能把它拉来。");return
            if not patch_braced or actions[0]!="brace" or not near(0,PATCH):say("补片还在风里翻动，先等朵朵撑稳。");return
            latch_fixed=true;say("团团拉来固定扣，咔哒锁住。补片现在自己挂住了，朵朵可以松手。",1)
        "外罩照灯架":
            if role!=2:say("圆圆的光可以从这里照进补片上方的阴影。");return
            if not latch_fixed:say("补片还没有挂稳，光影随着布边来回乱晃。");return
            if not aimed(2,SEAM_LIGHT,PATCH):say("圆圆的光落在平台上；破口在右上方。");return
            act(2,"light");seam_seen=true;say("光穿过补片边缘，最后一道扣槽显出来了。朵朵可以沿这里压紧。",1)
        "应急归途灯匣":
            if role!=0:say("团团靠在朵朵脚边，圆圆望着门里的旧垫子。");return
            if not exit_gather(HOME):return
            reserve_retained=true;phase="battle_two";battle_waves=2
            start_dialogue(["门里的沙发和猫垫很熟悉。团团靠过来，圆圆眯起了眼。","朵朵：我很想回去。","她回头看看还暗着的路：但我们已经找到坏在哪里了。再一起试一次吧。","阿灯封好灯匣：归途替你们留着。这次我们一起把光送出去。"],{"role":0,"kind":"pet","target":positions[1],"duration":2.0,"participants":[0,1,2]})
        "树心前的休息桌":
            if role!=0 or not exit_gather(REST):return
            if not reserve_retained:return
            extras={"shell_fixed":true,"inward_verified":true,"reserve_retained":true,"battles_finished":battles_finished}
            finished=true;phase="complete";say("三位在独立备用灯旁歇好了。带着修好的外罩和保留的归途灯匣，准备进入树心。",2)

func after_battle()->void:
    if not battle_requested:return
    super.after_battle()
    actions=["","",""];action_time=[0.0,0.0,0.0]
    if phase=="battle_one":
        phase="exterior";positions=[Vector2(850,495),Vector2(895,530),Vector2(805,545)]
        say("荆棘退开。宽树梯与扶绳通向外罩；带来的修补布正好能盖住破口。")
    elif phase=="battle_two":
        phase="rest";positions=[Vector2(780,485),Vector2(730,535),Vector2(680,555)]
        say("树梯旁的荆棘退开了。归途灯匣仍封好留着，一起到备用灯旁歇歇。")

func objective()->String:
    match phase:
        "market":return "摊主的灯罩落在阴影里的踏板尽头。"
        "meet":return "修补布已经拿到，阿灯守着的送光台却仍然暗着。"
        "investigate":return "阿灯开了一小段测试线路。光到底流去了哪里？"
        "exterior":return "余风从破罩里穿过，补片边缘不停翻动。"
        "test":return "外罩安静下来了。同一缕测试光会有什么变化？"
        "offer":return "阿灯看着牢固的外罩，从身后拿出一只灯匣。"
        "home_offer":return "备用归途安全亮着；朵朵准备回应阿灯。"
        "rest":return "备用灯仍亮着，树心前有一张休息桌。"
    return title

func trial_lit()->bool:
    return actions[2]=="light" and aimed(2,DUCT_LIGHT,DUCT)

func clear_trial()->void:
    pulse_active=false;pulse_elapsed=0.0
    return_charge=0.0;leak_charge=0.0;reserve_charge=0.5 if reserve_available and lamp_dest=="rack" else 0.0;return_flash_time=0.0

func cancel_trial()->void:
    clear_trial()
    say("试光中断，光点散回灯架。这一回没有留下结论，可以重新送光。")

func release_trial_light()->void:
    actions[2]="";action_time[2]=0
    if pulse_active:cancel_trial()
    else:say("圆圆撤下光源。已经看见的结果记住了，试光台可以随时再开。")

func step_trial(dt:float)->void:
    return_flash_time=maxf(0,return_flash_time-dt)
    if not pulse_active:return
    if phase not in ["investigate","test"] or not trial_lit():cancel_trial();return
    pulse_elapsed+=dt
    if pulse_elapsed<TRIAL_SECONDS:return
    pulse_active=false;trial_count+=1
    leak_charge=0.0 if shell_fixed else 0.35
    return_charge=0.65 if not shell_fixed else 1.0
    if not route_split:main_return_seen=true
    elif not bypass_isolated:connected_split_seen=true
    if leak_charge>0:shell_leak_seen=true;shell_examined=true
    if route_split and bypass_isolated and lamp_dest=="rack":
        reserve_charge=0.5;reserve_hold_seen=true;reserve_available=true
        say("分出去的小灯亮住了；主线那一半仍绕回收光机。隔离扣把两条路分开了。",1)
    else:
        if lamp_dest=="rack" and not bypass_isolated:reserve_available=false
        reserve_charge=0.5 if reserve_available and lamp_dest=="rack" else 0.0
        say("光沿槽倒流，回到卡住的收光机。"+("破罩边还有一股光被风吹散。" if not shell_fixed else "补好的罩边没有漏出光。"),1)
    if phase=="test" and shell_fixed and not route_split:
        inward_verified=true;phase="offer";actions[2]=""
        say("朵朵：罩边不漏了，主线却还是回流。\n阿灯：外罩修好还不够，里面的收光机没有停。",1)

func tool(role:int)->void:
    if dialogue_active() or social_transition_active():return
    if role not in available_roles() or finished or battle_requested or action_time[role]>0:return
    if role==2 and actions[2]=="light":
        release_trial_light();return
    if role==0 and phase in ["investigate","test"] and near(0,ARROWS,60):
        if pulse_active:say("这缕光还在路上，先看看它去了哪里。");return
        if not trial_lit():say("试光源暗着。圆圆可以在灯架上稳住朝向暗槽的光。");return
        clear_trial();pulse_active=true;act(0,"touch")
        say("一缕测试光沿"+("分光槽" if route_split else "主线")+"出发了。",1)
        return
    interact(role)

func request_hint()->void:
    hints+=1
    var context:=str([phase,cover_hooked,cover_carried,market_beam,cloth,duct_seen,trial_lit(),route_split,bypass_isolated,patch_braced,main_return_seen,connected_split_seen,reserve_hold_seen,shell_leak_seen,latch_fixed,seam_seen,shell_fixed,inward_verified])
    if hint_context!=context:hint_context=context;hint_level=0
    hint_level=mini(hint_level+1,3)
    var lines:Array[String]=[]
    match phase:
        "market":
            if not cover_hooked:lines=["灯罩下方的铁环垂在低处。","爪钩能拉动物件，朵朵够不到这个低环。","让团团到灯罩拉环旁试试爪钩。"]
            elif not cover_carried and market_beam:lines=["亮起的踏板通到了灯罩脚下。","团团能走这段窄路，圆圆需要继续稳光。","让团团沿亮着的踏板取灯罩，再原路返回宽岸。"]
            elif not cover_carried:lines=["灯罩到了踏板尽头，踏板还在阴影中。","稳定的光能照出供团团返回的路。","让圆圆在集市灯架朝左上稳光，团团沿亮起的踏板取灯罩。"]
            else:lines=["团团叼着灯罩，宽岸有人可以接应。","灯罩要在安全的宽岸交接。","让团团沿踏板回接物宽岸，朵朵靠近接住。"]
        "meet":lines=["阿灯一直守着暗下来的送光台。","带来的修补布让它知道你们愿意帮忙。","让朵朵走近阿灯，聊聊昨夜的灯光。"]
        "investigate":
            if diagnosis_ready():lines=["独立小灯与接回主机的光，已经留下不同结果。","改变连接后去向改变，说明破罩的风与主机回收是两件事。","到阿灯身边说说对照；不需要把每条可能线路再做一遍。"]
            elif not trial_lit():lines=["上方暗槽连着两条试光线路。","试光柄需要稳定光源才能送出样本。","圆圆在暗槽灯架面向上方，互动稳光。"]
            elif not reserve_hold_seen:lines=["小灯到主机之间，有一个能打开的小扣。","分出支路仍可能接着收光机；断开连接后，会不会不同？","团团打开旁路扣，朵朵选择分光，再用工具送一缕光。"]
            elif not (main_return_seen or connected_split_seen or reconnected_seen):lines=["独立小灯留住了光，主机那边还在转动。","可以改送主线，也可以把亮着的小灯重新接回去，比较去向。","在灯仍在试验架上时，团团合回隔离扣；或朵朵切到主线送一缕光。"]
            else:lines=["灯路有了对照，罩边仍有风声。","断线能留住小灯，不会堵住破罩的风。","带着修补布去破罩边，先看看、压住一角。"]
        "exterior":
            if not latch_fixed and patch_braced:lines=["朵朵已经撑稳补片，外侧固定扣不再来回晃。","撑布时保持站位，爪钩才能把远处的扣拉来。","让团团到外罩固定扣旁拉住它。"]
            elif not latch_fixed:lines=["补片边沿翻动，外侧有一只固定扣。","布撑稳后，爪钩才能拉住远处的扣。","朵朵撑住破罩上的布，团团拉外侧固定扣。"]
            elif not seam_seen:lines=["补片挂住了，阴影里还有一道翘边。","斜照的光能显出未压紧的扣槽。","圆圆在外罩灯架朝右上照向补片。"]
            else:lines=["光照出了补片最后一道扣槽。","挂住补片之后，还要压牢边缘。","朵朵沿破罩的亮边压紧最后一道扣槽。"]
        "test":lines=["罩边的风停了，主机却还在动。","重复同一路线的测试，才能看出修补改变了什么。","圆圆朝暗槽稳光，朵朵选择主线，用工具重送一缕光。"]
        "offer":lines=["阿灯拿出了独立封存的小灯匣。","那里面的备用光没有接回主机。","到阿灯旁听听灯匣能做什么。"]
        "home_offer":lines=["门里熟悉的沙发和猫垫亮起来了。","这盏备用光够三位一起回去，是否留下由朵朵决定。","三位靠近归途灯匣，让朵朵回应阿灯。"]
        "rest":lines=["休息桌旁的备用灯还亮着。","同伴到齐才能一起准备去树心。","三位到休息桌旁，让朵朵招呼大家歇歇。"]
        _:lines=[objective(),"先处理眼前的荆棘，守住大家。","和伙伴一起完成当前遭遇。"]
    var labels:=["观察","规则","局部做法"]
    say("提示 %d / 3 · %s：%s"%[hint_level,labels[hint_level-1],lines[hint_level-1]])

func restore_complete()->void:
    finished=true;phase="complete";cloth=true;cover_hooked=true;duct_seen=true;branch_seen=true;arrows_seen=true
    main_return_seen=true;connected_split_seen=true;shell_leak_seen=true;reserve_hold_seen=true;clear_trial()
    latch_fixed=true;seam_seen=true;shell_fixed=true;inward_verified=true;lantern_offered=true;reserve_retained=true;battles_finished=2
    positions=[Vector2(815,570),Vector2(875,605),Vector2(780,615)]

func completion_text()->String:
    return "第四章完成 · 破罩已经修牢\n光仍朝树心回流，缠住回位扣的折枝还在。阿灯愿意一起修好主路。\n应急归途灯匣已经重新封好，为三位保留。下一站：树心。"

func draw_world(v:Node2D)->void:
    var wood:=Color("937451");var gold:=Color("ebbe71");var teal:=Color("74bbb4")
    # The merchant and all tools stay at the original interaction anchors.
    v.prop(4,Rect2(130,258,103,67))
    v.merchant(Vector2(182,290));v.lamp(Vector2(151,263),true)
    # A recessed service trench, with the real return boards laid inside it.
    v.pit(PIT)
    v.wood(Rect2(185,317,231,13),wood);v.wood(Rect2(185,422,231,12),wood)
    for yy in range(340,421,21):
        v.prop(0,Rect2(269,yy,52,16),0.0,Color.WHITE if market_beam else Color("596c65"))
    v.rope(Vector2(262,326),Vector2(262,432));v.rope(Vector2(328,326),Vector2(328,432))
    if not cloth and not cover_carried:
        var cp:Vector2=COVER if cover_hooked else Vector2(220,365)
        v.support_prop(2,Rect2(cp-Vector2(29,40),Vector2(58,48)))
    if cover_carried:
        var carried:Vector2=positions[1]+Vector2(0,-25)
        v.support_prop(2,Rect2(carried-Vector2(21,28),Vector2(42,35)))
    v.prop(5,Rect2(HOOK-Vector2(21,32),Vector2(42,43)))
    v.prop(0,Rect2(CATCH-Vector2(38,8),Vector2(76,23)))
    for station in [MARKET_LIGHT,DUCT_LIGHT,SEAM_LIGHT]:
        v.prop(2,Rect2(station-Vector2(22,49),Vector2(44,59)))
    if actions[2]=="light":
        v.draw_line(positions[2]+Vector2(0,-15),positions[2]+facing[2]*180,Color(0.94,0.85,0.49,0.7),15)
    v.alight(ALIGHT)
    v.prop(4,Rect2(505,290,93,52))
    v.prop(11,Rect2(601,217,155,126))
    v.draw_line(Vector2(635,258),Vector2(728,258),teal if duct_seen else Color("526662"),9)
    # The test rack only carries moving samples while the player sends a pulse.
    v.gear(BRANCH,clock*0.06 if not branch_seen else 0.0,24)
    v.support_prop(3,Rect2(BRANCH-Vector2(31,43),Vector2(62,52)))
    v.prop(8,Rect2(ARROWS-Vector2(36,45),Vector2(72,66)))
    v.arrow(ARROWS-Vector2(17,15),Vector2.LEFT,gold);v.arrow(ARROWS+Vector2(17,-15),Vector2.RIGHT,teal)
    v.ink(ARROWS+Vector2(30,6),"分光" if route_split else "主线",90,16)
    v.prop(3,Rect2(ARROWS-Vector2(12,26),Vector2(24,32)),0.6 if route_split else -0.6)
    v.prop(11,Rect2(969,238,178,143))
    if not shell_fixed:
        for i in range(4):
            var yy:=274+i*24;var xx:=973+fposmod(clock*80+i*35,150)
            v.draw_line(Vector2(xx,yy),Vector2(xx+35,yy-6),Color(0.7,0.86,0.82,0.45),2)
    if early_patch or patch_braced or latch_fixed or shell_fixed:
        var flutter:=0.0 if shell_fixed or latch_fixed else sin(clock*6)*0.04
        v.prop(12,Rect2(985,247,137,113),flutter)
    v.rope(Vector2(940,376),Vector2(1150,376))
    v.prop(3,Rect2(LATCH-Vector2(16,27),Vector2(32,39)),0.0,Color.WHITE if latch_fixed else Color("9aa49a"))
    if seam_seen:v.draw_line(Vector2(1006,266),Vector2(1091,266),gold,3)
    draw_trial(v)
    draw_trial_records(v)
    if lantern_offered:
        v.ink(HOME+Vector2(-116,-124),"备用归途 · 安全封存" if reserve_retained else "备用归途 · 已接通",232,17)
        v.draw_circle(HOME+Vector2(-54,-18),5,Color("8fe2d0"))
        v.draw_line(HOME+Vector2(-54,-18),HOME+Vector2(-54,-62),Color("8fe2d0"),3,true)
        v.ink(HOME+Vector2(-122,54),"已决定留下 · 灯匣保留" if reserve_retained else "主线仍暗 · 到灯匣旁回应",244,16)
        if not reserve_retained:
            v.draw_texture_rect_region(v.HOME,Rect2(HOME-Vector2(33,82),Vector2(66,92)),Rect2(190,100,560,600))
            v.prop(7,Rect2(HOME-Vector2(51,110),Vector2(102,132)))
            v.prop(14,Rect2(HOME-Vector2(28,25),Vector2(56,36)))
        else:
            v.prop(13,Rect2(HOME-Vector2(41,55),Vector2(82,71)))
    v.prop(14,Rect2(REST-Vector2(58,29),Vector2(116,58)))
    v.lamp(REST+Vector2(0,-30),true)
    if phase in ["meet","investigate","offer"] and near(0,ALIGHT,130):v.ink(ALIGHT+Vector2(-18,27),"阿灯",90,18)

# The same route used for the result is drawn in world space; result lamps stay
# visible until the next sample. No HUD counter is needed to read the comparison.
func trial_bead(v:Node2D,path:PackedVector2Array,t:float,color:Color)->void:
    var total:=0.0
    for i in range(1,path.size()):total+=path[i-1].distance_to(path[i])
    var distance:=clampf(t,0,1)*total
    for i in range(1,path.size()):
        var length:=path[i-1].distance_to(path[i])
        if distance<=length or i==path.size()-1:
            var point:=path[i-1].lerp(path[i],clampf(distance/maxf(length,0.01),0,1))
            v.draw_circle(point,11,Color(color,0.15));v.draw_circle(point,5,color);return
        distance-=length

func draw_trial(v:Node2D)->void:
    if phase=="market":return
    var gold:=Color("ffe59a");var teal:=Color("8fe2d0");var dark:=Color("536c68")
    var out:=PackedVector2Array([ARROWS+Vector2(0,-20),SPLITTER,Vector2(941,340),SHELL_TEST])
    var back:=PackedVector2Array([SHELL_TEST,Vector2(953,230),Vector2(625,230),DUCT,BRANCH])
    var split:=PackedVector2Array([SPLITTER,Vector2(820,340),RESERVE])
    for path in [out,back,split]:
        v.conduit(path,false)
    # A visible gap in the return link is the reversible isolation control.
    var join:=RESERVE+Vector2(-36,0)
    v.conduit(PackedVector2Array([BRANCH,join]),false)
    v.draw_line(join,RESERVE+Vector2(-12,-17 if bypass_isolated else 0),teal if bypass_isolated else gold,5,true)
    v.draw_circle(join,5,Color("a88350"))
    if lamp_dest=="rack":v.lamp(RESERVE+Vector2(0,42),reserve_available)
    else:v.draw_arc(RESERVE+Vector2(0,30),13,0,TAU,20,Color("8b7959"),4)
    v.ink(RESERVE+Vector2(-48,65),"旁路小灯",100,15)
    v.ink(BRANCH+Vector2(-65,43),"隔开" if bypass_isolated else "相连",110,15)
    v.ink(ARROWS+Vector2(-74,77),"工具 · 送光",150,15)
    if trial_lit():v.draw_circle(ARROWS+Vector2(0,-20),7,gold)
    if pulse_active:
        var progress:=pulse_elapsed/TRIAL_SECONDS
        if progress<0.5:
            trial_bead(v,out,progress*2,gold)
            if route_split:trial_bead(v,split,progress*2,teal)
        else:
            trial_bead(v,back,(progress-0.5)*2,gold)
            if route_split:
                if bypass_isolated:v.draw_circle(RESERVE,8,teal)
                else:trial_bead(v,PackedVector2Array([RESERVE,BRANCH]),(progress-0.5)*2,teal)
            if not shell_fixed:
                for i in range(3):
                    trial_bead(v,PackedVector2Array([SHELL_TEST,SHELL_TEST+Vector2(75+i*15,-32+i*22)]),(progress-0.5)*2,gold)
    if return_charge>0:
        v.draw_arc(BRANCH,30,0,TAU,24,Color(gold,0.65),3,true)
        for i in range(3):v.draw_circle(BRANCH+Vector2.from_angle(clock*1.5+i*TAU/3)*21,3,gold)
        v.ink(Vector2(610,150),"光被收回",120,15)
    if leak_charge>0:
        for i in range(4):
            v.draw_circle(SHELL_TEST+Vector2(30+fposmod(clock*22+i*14,65),-10-i*9),3,Color(gold,0.6))
        v.ink(SHELL_TEST+Vector2(5,-40),"漏光",85,15)
    elif shell_fixed and return_charge>0:v.ink(SHELL_TEST+Vector2(5,-40),"罩边不漏了",115,15)
    if return_flash_time>0:trial_bead(v,PackedVector2Array([RESERVE,BRANCH]),1-return_flash_time/1.2,teal)

# The plaques are memories of witnessed samples, never a source of new facts.
# Unseen routes have geometry only; current charge and permanent memory differ.
func trial_records()->Array:
    return [
        {"label":"主线","seen":main_return_seen,"result":"回流" if main_return_seen else "","split":false,"isolated":false},
        {"label":"连通旁路","seen":connected_split_seen,"result":"回流" if connected_split_seen else "","split":true,"isolated":false},
        {"label":"隔离旁路","seen":reserve_hold_seen,"result":"留光" if reserve_hold_seen else "","split":true,"isolated":true}]

func draw_trial_records(v:Node2D)->void:
    if phase=="market":return
    var records:Array=[]
    for record in trial_records():
        if record.seen:records.append(record)
    if reconnected_seen:records.append({"label":"接回小灯","seen":true,"result":"被收回","split":true,"isolated":false})
    if records.is_empty():return
    var bronze:=Color("8b795c");var dark:=Color("4b5750");var gold:=Color("e9c883");var mint:=Color("87cdb8")
    v.ink(Vector2(876,474),"试光留下的印记",276,17)
    for index in range(records.size()):
        var record:Dictionary=records[index]
        var center:=Vector2(975+(index%2)*105,515+floori(index/2.0)*94)
        v.draw_rect(Rect2(center-Vector2(43,40),Vector2(86,86)),Color("d2bf91"),true)
        v.draw_rect(Rect2(center-Vector2(43,40),Vector2(86,86)),bronze,false,2)
        v.ink(center+Vector2(-43,-20),record.label,86,14)
        var start:=center+Vector2(-28,0);var end:=center+Vector2(28,0)
        v.draw_line(start,end,dark,3,true)
        v.draw_circle(start,4,bronze)
        v.draw_circle(end,7,dark,false,2,true)
        if record.split:
            var lamp:=center+Vector2(0,-10)
            v.draw_line(start,lamp,dark,2,true)
            v.draw_circle(lamp,5,dark,false,2,true)
            if record.isolated:
                v.draw_line(lamp+Vector2(6,0),lamp+Vector2(13,0),dark,2,true)
                v.draw_line(lamp+Vector2(21,0),end,dark,2,true)
            else:v.draw_line(lamp,end,dark,2,true)
        if record.seen:
            var color:Color=mint if record.isolated else gold
            if record.isolated:v.draw_circle(center+Vector2(0,-10),3,color)
            else:
                v.draw_polyline(PackedVector2Array([end+Vector2(0,3),end+Vector2(0,12),start+Vector2(0,12)]),color,3,true)
                v.arrow(start+Vector2(0,12),Vector2.LEFT,color)
            v.ink(center+Vector2(-43,35),record.result,86,17)
    if shell_leak_seen:
        v.ink(Vector2(946,174),"先前罩边：漏光",224,15)
    if shell_fixed:
        v.ink(Vector2(946,195),"复测：不漏光 / 仍回流" if inward_verified else "补片封稳 · 尚未复测",224,15)

func diagnosis_ready()->bool:
    return reserve_hold_seen and (main_return_seen or connected_split_seen or reconnected_seen) and (shell_examined or shell_leak_seen)
func presentation()->Dictionary:
    var data:=super.presentation()
    data.mechanisms=[{"id":"early_patch","position":PATCH,"angle":0.0,"load":early_patch,"lit":shell_fixed,"connection":"sealed" if shell_fixed else "loose"},
        {"id":"stall_lamp","position":STALL_LAMP,"angle":0.0,"load":false,"lit":reserve_available and lamp_dest=="stall","connection":"isolated"},
        {"id":"view_lamp","position":VIEW_LAMP,"angle":0.0,"load":false,"lit":reserve_available and lamp_dest=="view","connection":"isolated"},
        {"id":"reserve_lamp","position":RESERVE,"angle":0.0,"load":false,"lit":reserve_available and lamp_dest=="rack","connection":"isolated" if bypass_isolated else "main"}]
    if stall_seen:data.discoveries.append("four_stall")
    if view_seen:data.discoveries.append("four_view")
    data.lamp_position=positions[0]+Vector2(20,-30) if lamp_dest=="carried" else STALL_LAMP if lamp_dest=="stall" else VIEW_LAMP if lamp_dest=="view" else RESERVE
    data.diagnosis_ready=diagnosis_ready();data.lamp_dest=lamp_dest
    data.merchant_position=Vector2(270,280) if stall_seen else Vector2(182,290)
    data.room=room_name()
    data.visit_room=visit_room
    data.mechanisms.append({"id":"market_door","position":MARKET_DOOR,"angle":0.0,"load":false,"lit":false,"connection":"return" if visit_room=="market" else "market"})
    data.mechanisms.append({"id":"view_door","position":VIEW_DOOR,"angle":0.0,"load":false,"lit":false,"connection":"return" if visit_room=="exterior" else "exterior"})
    data.stage="market" if phase=="market" else "exterior" if phase=="exterior" else "tree_room"
    return data

func social_arrived()->void:
    if visit_pending!="none":visit_room=visit_pending;visit_pending="none"
