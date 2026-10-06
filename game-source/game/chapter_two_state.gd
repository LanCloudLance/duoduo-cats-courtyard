extends "res://game/story_chapter_base.gd"
## Two loaded bridge leaves, a cat repair crawlway, and a barred tower window.
const WINCH_A := Vector2(405,420)
const LAMP_A := Vector2(390,300)
const LATCH_A := Vector2(570,555)
const WINCH_B := Vector2(595,420)
const LAMP_B := Vector2(595,315)
const LATCH_B := Vector2(720,555)
const BOX := Vector2(815,410)
const LOOP := Vector2(850,565)
const SHORTCUT := Vector2(915,425)
const WINDOW := Vector2(1100,425)
var lamp_a := 0
var lamp_b := 0
var lifted_a := false
var lifted_b := false
var locked_a := false
var locked_b := false
var hook_owned := false
var hook_practiced := false
var shortcut_open := false
var reverse_seen := false
func _init()->void:
    chapter=2;chapter_key="chapter-two";title="第二章 · 团团，去那边等我";phase="bridge"
    positions=[Vector2(230,420),Vector2(270,480),Vector2(1155,360)]
    say("朵朵：桥绞盘卡住了。你走下面的检修小道，我在外面帮你。")
func segment_ready(index:int)->bool:
    return locked_a or (lifted_a and lamp_a==1) if index==0 else locked_b or (lifted_b and lamp_b==2)
func walkable(p:Vector2,role:int)->bool:
    if not super.walkable(p,role) or p.x>1130:return false
    if p.x>=460 and p.x<760:
        var index:=0 if p.x<615 else 1
        var locked:=locked_a if index==0 else locked_b
        if p.y>=375 and p.y<=470:return locked
        if p.y>=520 and p.y<=595:return role==1 and segment_ready(index)
        # Lamp B is mounted on the first leaf's permanent upper landing.
        if p.x<615 and p.y>=280 and p.y<375:return locked_a
        return false
    if p.x>=940 and p.x<995:return shortcut_open and p.y>=375 and p.y<=470
    return true
func target(role:int)->String:
    if near(role,WINDOW):return "window"
    if near(role,BOX,58):return "box"
    if near(role,LOOP,58):return "loop"
    if near(role,SHORTCUT,55):return "shortcut"
    if near(role,LATCH_B,48):return "latch_b"
    if near(role,LATCH_A,48):return "latch_a"
    if near(role,WINCH_B,55):return "winch_b"
    if near(role,WINCH_A,55):return "winch_a"
    if near(role,LAMP_B,55):return "lamp_b"
    if near(role,LAMP_A,55):return "lamp_a"
    return ""
func interact(role:int)->void:
    if role not in available_roles() or finished or action_time[role]>0:return
    var item:=target(role)
    act(role,"inspect")
    match item:
        "lamp_a","lamp_b":
            if role!=0:say("团团拍拍灯架：转动把手太高了。");return
            if item=="lamp_a":lamp_a=(lamp_a+1)%4
            else:lamp_b=(lamp_b+1)%4
            say("朵朵转动导向灯。看光束是否落在检修轨道的反光片上。")
        "winch_a","winch_b":
            if role!=0:say("团团：喵。这个绞盘需要朵朵转。");return
            if item=="winch_a":
                if locked_a:say("第一段已锁牢，可以放心离开。");return
                lifted_a=not lifted_a
            else:
                if not locked_a:say("前段还没固定，后段不能承重。");return
                if locked_b:say("运输桥已经永久锁定。");return
                lifted_b=not lifted_b
            say("绞盘的棘轮停稳了。桥叶抬起时，下面卡扣才会卸力。",1)
        "latch_a","latch_b":
            if role!=1:say("朵朵：我进不去检修架，得让团团拨开卡扣。");return
            var second:=item=="latch_b"
            if not segment_ready(1 if second else 0):say("卡扣还在承重，轨道也没有照准。团团退回安全台。",3);return
            if second:
                locked_b=true;phase="hook";say("桥锁咔哒落下。团团蹭她的手。朵朵：太厉害了！好好好，先松爪。",2)
            else:
                locked_a=true;reverse_seen=true;say("第一段锁定。灯忽然暗了，光点朝灯树退去。朵朵：先站稳，我们换个角度。",1)
        "box":
            if not locked_b:say("检修箱随桥锁闭合着。");return
            if role!=1:say("朵朵：这是小伙伴用的爪钩，团团来试试。");return
            hook_owned=true;say("团团获得爪钩。先拉一拉旁边安全台上的试用环。",2)
        "loop":
            if role!=1 or not hook_owned:say("低处拉环适合小伙伴用爪钩。");return
            hook_practiced=true;act(role,"hook");say("爪钩扣住拉环，练习小车滑到安全台。可以拉下前面的短桥了。",1)
        "shortcut":
            if role!=1 or not hook_practiced:say("高处的环需要团团先学会使用爪钩。");return
            shortcut_open=true;phase="window";act(role,"hook");say("短桥落下并锁稳。钟楼就在前面。",2)
        "window":
            if not shortcut_open:return
            if role!=0:say("团团隔着窄栏杆，与圆圆碰了碰鼻子。");return
            if positions[1].x<995:say("朵朵：团团，先过短桥，到窗边来。");return
            if not exit_gather(WINDOW):return
            finished=true;phase="complete";extras={"hook":true,"reverse_flow":true,"white_seen":true}
            say("朵朵：圆圆！我们找你好久，你倒是把床找好了。门边的灯熄了，它被关在里面；窗栏太窄，我们得修门。",2)
        _:say("朵朵：留意桥叶的高度、灯的方向和下面的卡扣。")
    recover_crawlway()
func recover_crawlway()->void:
    if positions[1].x>=460 and positions[1].x<760 and not walkable(positions[1],1):
        positions[1]=Vector2(585,430) if locked_a else Vector2(420,560)
        say("团团退回最近的固定台。已经锁好的桥段仍然牢固。",3)
func step(dt:float,a:Vector2,b:Vector2,enabled:bool)->void:
    super.step(dt,a,b,enabled)
    if not enabled or not is_finite(dt) or dt<=0:return
    recover_crawlway()
func objective()->String:
    if not locked_a:return "卸开第一段桥扣，让运输桥停稳"
    if not locked_b:return "在固定台调整第二盏导向灯，解开后段桥锁"
    if not hook_owned:return "查看桥边的小伙伴检修箱"
    if not hook_practiced:return "在安全侧台试用爪钩"
    if not shortcut_open:return "用爪钩放下钟楼短桥"
    return "朵朵和团团一起到低窗看看圆圆"
func request_hint()->void:
    hints+=1
    if hints%2==1:say("灯架上的短线是出光方向；轨道末端的铜片只有照准才发亮。绞盘先把重量托住。")
    else:say("第一盏灯向右，第二盏灯向下。朵朵转灯和绞盘，团团走低道拨扣；桥段锁住后不必再保持。")
func completion_text()->String:return "第二章完成 · 运输桥已修好，团团学会爪钩。\n圆圆就在锁着的钟楼里。下一章：修门，三位一起走。"
func restore_complete()->void:
    locked_a=true;locked_b=true;lifted_a=true;lifted_b=true;lamp_a=1;lamp_b=2
    hook_owned=true;hook_practiced=true;shortcut_open=true;reverse_seen=true
    positions=[Vector2(1080,420),Vector2(1100,480),Vector2(1155,360)]
    super.restore_complete()
func draw_world(view:Node2D)->void:
    const TIMBER_ART=preload("res://assets/visual-m26/mechanisms.png")
    # The painted river remains visible between the two real, load-bearing leaves.
    # Shore posts and water ripples describe the collision gap without a dark overlay.
    for bank_x in [459.0,761.0]:
        view.rope(Vector2(bank_x,260),Vector2(bank_x,365))
        view.rope(Vector2(bank_x,482),Vector2(bank_x,518))
        view.rope(Vector2(bank_x,599),Vector2(bank_x,628))
    for ripple in [Vector2(500,490),Vector2(675,510),Vector2(540,610),Vector2(695,340)]:
        view.draw_arc(ripple,22,0.15,2.45,18,Color(0.76,0.91,0.87,0.44),2,true)
    for data in [[Rect2(460,375,155,95),locked_a,lifted_a],[Rect2(615,375,145,95),locked_b,lifted_b]]:
        var deck:Rect2=data[0]
        view.bridge(deck,data[1])
        if not data[1]:
            # The unlatched leaf visibly changes height when the winch takes its load.
            var raised:bool=data[2]
            var leaf:=Rect2(deck.position+Vector2(2,-43 if raised else 28),Vector2(deck.size.x-4,54))
            view.prop(0,leaf,-0.32 if raised else 0.18,Color("e9d3a4") if raised else Color("9caa9a"))
            view.rope(Vector2(deck.position.x+9,370),leaf.get_center()+Vector2(18,-14))
    view.bridge(Rect2(460,520,155,75),segment_ready(0))
    view.bridge(Rect2(615,520,145,75),segment_ready(1))
    if locked_a:
        view.wood(Rect2(555,280,60,95),Color("c8ad7b"))
        for edge_x in [555,615]:view.rope(Vector2(edge_x,288),Vector2(edge_x,379))
    for data in [[WINCH_A,lifted_a,locked_a,Vector2(502,386)],[WINCH_B,lifted_b,locked_b,Vector2(663,386)]]:
        var tension:bool=data[1] or data[2]
        var end:Vector2=data[3]+Vector2(0,-43 if tension and not data[2] else 0)
        view.rope(data[0]+Vector2(12,-8),end)
        view.gear(data[0],0.6 if tension else 0.0,29)
        if data[2]:view.prop(3,Rect2(data[0]+Vector2(20,-15),Vector2(24,28)))
    var directions:Array[Vector2]=[Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT]
    for data in [[LAMP_A,lamp_a],[LAMP_B,lamp_b]]:
        view.lamp(data[0],true)
        view.prop(8,Rect2(data[0]+Vector2(-18,-29),Vector2(36,34)))
        view.arrow(data[0]+Vector2(0,-12),directions[data[1]]*36,Color("ffe9a3"))
    # Each copper receiver is connected to its own latch, even before illumination.
    for data in [[LAMP_A,Vector2(510,300),LATCH_A,lamp_a==1],[LAMP_B,Vector2(595,490),LATCH_B,lamp_b==2]]:
        view.rope(data[1],data[2])
        view.prop(8,Rect2(data[1]-Vector2(17,19),Vector2(34,38)),0,Color("ffe5a5") if data[3] else Color("b3bda4"))
        if data[3]:
            view.draw_line(data[0],data[1],Color(1,0.85,0.45,0.28),9,true)
            view.draw_line(data[0],data[1],Color(1,0.94,0.7,0.8),2,true)
    for data in [[LATCH_A,locked_a,segment_ready(0)],[LATCH_B,locked_b,segment_ready(1)]]:
        view.prop(3,Rect2(data[0]-Vector2(26,27),Vector2(52,54)),0,Color("ffe7b8") if data[1] else Color.WHITE)
        if data[1]:view.draw_line(data[0]+Vector2(-17,5),data[0]+Vector2(18,5),Color("e5c785"),4,true)
        view.draw_circle(data[0]+Vector2(0,-29),4,Color("ffe6a0") if data[2] else Color("687a73"))
    view.prop(4,Rect2(BOX-Vector2(36,43),Vector2(72,56)))
    if not hook_owned:
        view.draw_arc(BOX+Vector2(1,-21),8,-0.5,4.3,16,Color("ffe0a0"),3,true)
        view.rope(BOX+Vector2(-6,-17),BOX+Vector2(-10,-4))
    view.prop(5,Rect2(LOOP-Vector2(29,48),Vector2(58,62)))
    var cart:=Vector2(840 if hook_practiced else 900,600)
    view.rope(LOOP+Vector2(0,-10),cart)
    view.prop(0,Rect2(cart-Vector2(24,15),Vector2(48,28)))
    for dx in [-15,15]:view.gear(cart+Vector2(dx,11),0,7)
    view.prop(5,Rect2(SHORTCUT-Vector2(26,50),Vector2(52,62)))
    view.rope(SHORTCUT+Vector2(0,-25),Vector2(972,340))
    view.bridge(Rect2(940,375,55,95),shortcut_open)
    if not shortcut_open:view.prop(0,Rect2(944,310,48,78),-0.13)
    # Low barred window: the opening and sill frame the waiting cat, not a flat wall block.
    for post in [Rect2(1130,252,20,75),Rect2(1130,435,20,165)]:
        view.draw_texture_rect_region(TIMBER_ART,post,Rect2(741,394,69,132))
        view.draw_line(post.position,Vector2(post.position.x,post.end.y),Color("61482c"),2,true)
    view.prop(7,Rect2(1129,317,73,112))
    view.white_cat(Vector2(1158,418))
    for x in [1138,1154,1170,1186]:
        view.draw_line(Vector2(x,335),Vector2(x,419),Color("625f4a"),4,true)
        view.draw_line(Vector2(x-1,335),Vector2(x-1,419),Color("c2b591"),1,true)
    view.draw_texture_rect_region(TIMBER_ART,Rect2(1126,419,78,13),Rect2(741,394,69,132))
    view.ink(Vector2(310,238),"运输桥 · 检修道在下方",265,16)
    if reverse_seen:
        for i in range(4):
            var flow_x:=fmod(clock*28.0+i*25,100.0)
            view.draw_circle(Vector2(650+flow_x,220+sin(i*1.4)*5),2.6,Color(0.72,0.91,0.91,0.72))
