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

func _init() -> void:
    chapter=4;chapter_key="chapter-four";title="第四章 · 灯光躲起来了";joined=true;phase="market"
    positions=[Vector2(170,505),Vector2(215,550),Vector2(265,585)]
    say("集市的小备用灯还亮着，回家的主路却暗了。摊主：我的灯罩掉到下面了……")

func aimed(role:int,origin:Vector2,destination:Vector2)->bool:
    return near(role,origin,68) and facing[role].dot(positions[role].direction_to(destination))>0.7

func walkable(p:Vector2,role:int)->bool:
    if not super.walkable(p,role):return false
    if PIT.has_point(p):return role==1 and market_beam and cover_hooked and RETURN_PLANK.has_point(p)
    return true

func follow_allowed(role:int,p:Vector2)->bool:
    # A dormant cat never walks into an illuminated but temporary route.
    return not PIT.grow(12).has_point(p) and walkable(p,role)

func step(dt:float,a:Vector2,b:Vector2,enabled:bool)->void:
    if not enabled or not is_finite(dt) or dt<=0 or not a.is_finite() or not b.is_finite():return
    super.step(dt,a,b,enabled)
    if not enabled or finished:return
    market_beam=actions[2]=="light" and aimed(2,MARKET_LIGHT,COVER)
    patch_braced=actions[0]=="brace" and near(0,PATCH)
    # Extinguishing a temporary path safely returns the carrier to its bank.
    if PIT.has_point(positions[1]) and not market_beam:
        positions[1]=Vector2(295,446)
        say("团团退回宽岸。圆圆的光移开了，踏板又藏进阴影。")

func target(role:int)->String:
    if finished:return ""
    if phase=="market":
        if cover_carried and near(role,CATCH):return "接住灯罩"
        if role==1 and cover_hooked and near(role,COVER,43):return "低处灯罩"
        if near(role,MARKET_LIGHT,62):return "照向低处"
        if near(role,HOOK,62):return "灯罩拉环"
        if near(role,CATCH,54):return "接物宽岸"
    if phase in ["meet","investigate","test","offer"]:
        if near(role,ALIGHT):return "阿灯"
        if near(role,DUCT_LIGHT,60):return "暗槽照灯架"
        if near(role,BRANCH,60):return "回位扣"
        if near(role,ARROWS,60):return "收送试光柄"
    if phase=="exterior":
        if near(role,SEAM_LIGHT,60):return "外罩照灯架"
        if near(role,LATCH,60):return "外罩固定扣"
        if near(role,PATCH,60):return "破防风罩"
    if phase=="home_offer" and near(role,HOME,80):return "应急归途灯匣"
    if phase=="rest" and near(role,REST,85):return "树心前的休息桌"
    return ""

func interact(role:int)->void:
    if role not in available_roles() or finished or battle_requested or action_time[role]>0:return
    var item:=target(role)
    if item=="":return
    act(role,"touch")
    match item:
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
                say("阿灯：我怕昨夜的风吹散光，就收了回来。现在送出去又回来了，停止杆也卡住了。旧路曾被回收光误亮，那就是你们看见的小门。我只打开一小段线路给你们看。")
            elif phase=="offer" and inward_verified:
                lantern_offered=true;phase="home_offer"
                say("阿灯拿出封好的应急归途灯匣：它绕开主线，接通你家的门一次，足够你们三个一起回去。门里，熟悉的沙发和猫垫亮了起来。",2)
            else:say("阿灯：小备用灯和主线分开存着光，所以集市能歇脚。可回家的路还接在主线上。")
        "暗槽照灯架":
            if phase!="investigate":return
            if role!=2:say("这里的架子能固定圆圆的光，照进上方的暗槽。");return
            if not aimed(2,DUCT_LIGHT,DUCT):say("光落在槽外。圆圆要面向上方的暗槽，再固定定光扣。");return
            act(2,"light");duct_seen=true;say("暗槽亮了：细光正朝灯树里面流。外缘的回位扣后面压着一截折枝。",1)
        "回位扣":
            if phase!="investigate":return
            if role!=1:say("窄窄的外缘适合团团探看，先别硬拉机构。");return
            if not duct_seen:say("扣后太暗了，团团看不清是什么卡住了它。");return
            branch_seen=true;say("团团沿外缘找到缠进回位扣的折枝，向朵朵叫了一声。折枝还压在主机里，现在不能强拔。",1)
        "收送试光柄":
            if role!=0:say("箭头旁写着收、送，朵朵可以把它们和光流方向对照。");return
            if phase=="investigate":
                if not duct_seen or not branch_seen:say("朵朵：先看清光经过哪里，和哪个部件卡住了。");return
                arrows_seen=true;phase="battle_one";battle_requested=true;battle_waves=2
                say("朵朵：箭头停在收！光是被拉回来的。余风又穿过破罩，灯匣晃动，外面的荆棘也卷了过来。")
            elif phase=="test" and shell_fixed:
                inward_verified=true;phase="offer"
                say("防风罩稳稳不动。朵朵拨向送，一缕光却仍被卷回收光机。朵朵：外壳修好了，里面的折枝和收光机构还要处理。",1)
        "破防风罩":
            if role!=0:say("补片需要朵朵撑稳，才能够到外侧的固定扣。");return
            if not cloth or not arrows_seen:return
            if not latch_fixed:
                act(0,"brace");patch_braced=true;say("朵朵把修补布撑在破口。她不动时，团团就能拉来外侧固定扣。",1)
            elif seam_seen:
                shell_fixed=true;patch_braced=false;actions[0]="";actions[2]="";phase="battle_two";battle_requested=true;battle_waves=2
                say("朵朵沿照出的最后一道扣槽压牢补片。罩内的风停了，树梯旁还有一团荆棘挡路。",2)
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
            reserve_retained=true;phase="rest"
            say("朵朵：我很想回去。但我们已经找到坏在哪里了，再一起试一次吧。阿灯把灯匣重新封好留在身边，后备归途仍在。它拿起工具：这次一起把光送出去。",2)
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
        phase="test";positions=[Vector2(780,485),Vector2(730,535),Vector2(680,555)]
        say("回到试光柄旁。罩内已经没有风，再试一缕光，看看主路是否恢复。")

func objective()->String:
    match phase:
        "market":return "摊主的灯罩落在阴影里的踏板尽头。"
        "meet":return "带上修补布，去见守着送光台的阿灯。"
        "investigate":return "阿灯开了一小段测试线路。光到底流去了哪里？"
        "exterior":return "余风从破罩里穿过，补片边缘不停翻动。"
        "test":return "外罩安静下来，试光柄还停在收的位置。"
        "offer":return "阿灯看着牢固的外罩，从身后拿出一只灯匣。"
        "home_offer":return "一扇真实的家门亮了起来，三位都能通过。"
        "rest":return "备用灯仍亮着，树心前有一张休息桌。"
    return title

func tool(role:int)->void:
    interact(role)

func request_hint()->void:
    hints+=1
    if phase=="market":say("朵朵：爪钩能够到拉环。光得朝着旧踏板，团团回来时我在宽岸接。")
    elif phase=="investigate":say("阿灯：上面的暗槽连着回位扣，旁边是收、送箭头。照明和看清卡住的东西，比硬拉更有用。")
    elif phase=="exterior":say("朵朵：我撑住布，扣子就能拉过来。挂稳后，再找阴影里没有压紧的边。")
    else:say(objective())

func restore_complete()->void:
    finished=true;phase="complete";cloth=true;cover_hooked=true;duct_seen=true;branch_seen=true;arrows_seen=true
    latch_fixed=true;seam_seen=true;shell_fixed=true;inward_verified=true;lantern_offered=true;reserve_retained=true;battles_finished=2
    positions=[Vector2(815,570),Vector2(875,605),Vector2(780,615)]

func completion_text()->String:
    return "第四章完成 · 破罩已经修牢\n光仍朝树心回流，缠住回位扣的折枝还在。阿灯愿意一起修好主路。\n应急归途灯匣已经重新封好，为三位保留。下一站：树心。"

func draw_world(v:Node2D)->void:
    var wood:=Color("624334");var gold:=Color("ebbe71");var teal:=Color("74bbb4")
    v.wood(Rect2(135,255,100,62),wood);v.lamp(Vector2(177,253),true)
    v.draw_rect(PIT,Color("16262d"))
    for yy in range(340,421,21):
        v.wood(Rect2(269,yy,52,13),Color("baa170") if market_beam else Color("35413e"))
    v.rope(Vector2(262,326),Vector2(262,432));v.rope(Vector2(328,326),Vector2(328,432))
    if not cloth and not cover_carried:
        var cp:Vector2=COVER if cover_hooked else Vector2(220,365)
        v.draw_arc(cp,23,PI,TAU,18,gold,6);v.draw_line(cp+Vector2(-23,0),cp+Vector2(23,0),gold,3)
    if cover_carried:v.draw_arc(positions[1]+Vector2(0,-25),15,PI,TAU,14,gold,5)
    v.draw_arc(HOOK+Vector2(0,-12),13,0,TAU,18,gold,4)
    v.wood(Rect2(CATCH-Vector2(38,8),Vector2(76,18)),wood)
    for station in [MARKET_LIGHT,DUCT_LIGHT,SEAM_LIGHT]:
        v.wood(Rect2(station-Vector2(18,4),Vector2(36,16)),wood)
        v.draw_circle(station+Vector2(0,-10),8,gold)
    if actions[2]=="light":
        v.draw_line(positions[2]+Vector2(0,-15),positions[2]+facing[2]*180,Color(0.94,0.85,0.49,0.7),15)
    v.wood(Rect2(520,213,87,115),wood)
    v.draw_circle(ALIGHT-Vector2(0,26),20,gold);v.draw_circle(ALIGHT-Vector2(5,29),3,wood)
    for x in [543,580]:v.lamp(Vector2(x,230),true)
    v.wood(Rect2(608,235,142,95),Color("403b37"))
    v.draw_line(Vector2(635,258),Vector2(728,258),teal if duct_seen else Color("526662"),13)
    # Moving beads always flow inward until chapter five fixes the machine.
    for i in range(4):
        var x:=635+fposmod(clock*32+i*23,90)
        v.draw_circle(Vector2(x,258),4,gold if duct_seen else Color("778275"))
    v.gear(BRANCH,clock*0.06 if not branch_seen else 0.0,24)
    v.draw_line(BRANCH+Vector2(-22,-25),BRANCH+Vector2(19,21),Color("a87543"),8)
    v.draw_line(BRANCH+Vector2(-5,-8),BRANCH+Vector2(18,-22),Color("a87543"),5)
    v.wood(Rect2(ARROWS-Vector2(35,38),Vector2(70,58)),wood)
    v.arrow(ARROWS-Vector2(17,15),Vector2.LEFT,gold);v.arrow(ARROWS+Vector2(17,-15),Vector2.RIGHT,teal)
    v.ink(ARROWS+Vector2(-31,-45),"收    送",90,16)
    v.draw_line(ARROWS,ARROWS+Vector2(-22,-24),gold,6)
    v.wood(Rect2(969,243,178,133),Color("3b5556"))
    if not shell_fixed:
        v.draw_colored_polygon(PackedVector2Array([Vector2(996,266),Vector2(1082,280),Vector2(1020,344)]),Color("16262d"))
        for i in range(4):
            var yy:=274+i*24;var xx:=973+fposmod(clock*80+i*35,150)
            v.draw_line(Vector2(xx,yy),Vector2(xx+35,yy-6),Color(0.7,0.86,0.82,0.45),2)
    if patch_braced or latch_fixed or shell_fixed:
        var flutter:=0.0 if shell_fixed or latch_fixed else sin(clock*6)*7
        v.draw_colored_polygon(PackedVector2Array([Vector2(998,259),Vector2(1099,259),Vector2(1099+flutter,348),Vector2(998,348)]),Color("c78870"))
    v.rope(Vector2(940,376),Vector2(1150,376))
    v.draw_circle(LATCH,9,gold if latch_fixed else Color("71827e"))
    if seam_seen:v.draw_line(Vector2(1006,266),Vector2(1091,266),gold,3)
    if shell_fixed:
        for x in range(1004,1098,16):v.draw_line(Vector2(x,260),Vector2(x+7,270),gold,2)
    if lantern_offered:
        v.wood(Rect2(482,502,76,102),gold)
        v.draw_rect(Rect2(490,510,60,86),Color("8eaaa4") if reserve_retained else Color("f2d99c"))
        if not reserve_retained:
            v.wood(Rect2(497,545,46,26),Color("b87366"))
        else:v.draw_line(Vector2(491,535),Vector2(549,575),gold,5)
    v.wood(Rect2(REST-Vector2(52,22),Vector2(104,42)),wood);v.lamp(REST+Vector2(0,-30),true)
    if phase in ["meet","investigate","offer"] and near(0,ALIGHT,130):v.ink(ALIGHT+Vector2(-18,27),"阿灯",90,18)
