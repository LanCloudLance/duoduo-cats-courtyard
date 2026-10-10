extends "res://game/story_chapter_base.gd"
## Two loaded bridge leaves, a cat repair crawlway, and a barred tower window.
const WINCH_A := Vector2(405,420)
const LAMP_A := Vector2(390,300)
const LATCH_A := Vector2(570,555)
const WINCH_B := Vector2(595,420)
const LAMP_B := Vector2(595,315)
const LATCH_B := Vector2(720,555)
const BRACE_B := Vector2(595,465)
const MID_STEPS := Rect2(555,460,60,88)
const BOX := Vector2(815,410)
const LOOP := Vector2(850,565)
const SHORTCUT := Vector2(915,425)
const WINDOW := Vector2(1100,425)
const OUTER_BENCH:=Vector2(585,620)
const OUTER_RATCHET:=Vector2(745,620)
const OUTER_PATH:=Rect2(555,606,215,39)
const OUTER_STEPS:=Rect2(555,460,60,185)
const CART_HOOK:=Vector2(870,610)
var outer_locked:=false
var cart_open:=false
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
# A single physical safety prop is shared by both winches. Mechanical bridge
# locks take over the load, making the prop removable without undoing progress.
var support_site := "a"
# The rear ratchet carriage stays at the handoff height once the supported
# winch raises it; this physical stop survives a dropped temporary leaf.
var rear_loaded_seen := false
var hint_level := 0
var hint_context := ""
func _init()->void:
    chapter=2;chapter_key="chapter-two";title="第二章 · 团团，去那边等我";phase="bridge"
    positions=[Vector2(230,420),Vector2(270,480),Vector2(1155,360)]
    say("朵朵：桥绞盘卡住了。你走下面的检修小道，我在外面帮你。")
func rear_braced()->bool:
    return not locked_b and locked_a and actions[0]=="brace" and near(0,BRACE_B,34)
func segment_ready(index:int)->bool:
    return locked_a or (lifted_a and support_site=="a" and lamp_a==1) if index==0 else locked_b or (lifted_b and (support_site=="b" or rear_braced()) and lamp_b==2)
func release_rear_brace()->void:
    actions[0]="";action_time[0]=0
    if not locked_b and support_site!="b" and not outer_locked:lifted_b=false
    recover_crawlway()
    say("朵朵松开受力柄。"+("远端桥锁已经接稳重量。" if locked_b else "撑扣仍托着桥叶。" if support_site=="b" else "团团带着同一枚撑扣退回固定台，桥叶安全落回；在这里重新撑住就能继续。"))
func guard(role:int,held:bool)->void:
    # View/session cancellation already reaches this public input boundary.
    if role==0 and not held and actions[0]=="brace":release_rear_brace()
func walkable(p:Vector2,role:int)->bool:
    if not super.walkable(p,role) or p.x>1130:return false
    if locked_a and OUTER_STEPS.has_point(p):return true
    if Rect2(725,545,45,100).has_point(p) and (outer_locked or support_site=="outer"):return role==1
    if OUTER_PATH.has_point(p):return role==1 and (outer_locked or support_site=="outer")
    if p.x>=460 and p.x<760:
        var index:=0 if p.x<615 else 1
        var locked:=locked_a if index==0 else locked_b
        if index==0 and locked_a and MID_STEPS.has_point(p):return true
        if p.y>=375 and p.y<=470:return locked
        if p.y>=520 and p.y<=595:return role==1 and segment_ready(index)
        # Lamp B is mounted on the first leaf's permanent upper landing.
        if p.x<615 and p.y>=280 and p.y<375:return locked_a
        return false
    if p.x>=940 and p.x<995:return (shortcut_open and p.y>=375 and p.y<=470) or (cart_open and p.y>=565 and p.y<=640)
    return true
func target(role:int)->String:
    if locked_a and near(role,OUTER_BENCH,29):return "outer_bench"
    if locked_a and near(role,OUTER_RATCHET,30):return "outer_ratchet"
    if locked_b and near(role,CART_HOOK,32):return "cart_hook"
    if near(role,WINDOW):return "window"
    if near(role,BOX,58):return "box"
    if near(role,LOOP,58):return "loop"
    if near(role,SHORTCUT,55):return "shortcut"
    if near(role,LATCH_B,48):return "latch_b"
    if near(role,LATCH_A,48):return "latch_a"
    # A cat always reaches the prop socket; the girl only targets the separate
    # lower handhold when actually standing there, never from the winch center.
    if role==0 and not locked_b and near(role,BRACE_B,29):return "brace_b"
    if near(role,WINCH_B,45):return "winch_b"
    if near(role,WINCH_A,55):return "winch_a"
    if near(role,LAMP_B,55):return "lamp_b"
    if near(role,LAMP_A,55):return "lamp_a"
    return ""
func interact(role:int)->void:
    if role not in available_roles() or finished or action_time[role]>0 or dialogue_active() or social_transition_active():return
    var item:=target(role)
    if role==0 and item=="brace_b" and rear_braced():release_rear_brace();return
    act(role,"inspect")
    match item:
        "outer_bench":
            if support_site in ["carried","cat_carried"]:
                if (support_site=="carried" and role!=0) or (support_site=="cat_carried" and role!=1):say("撑扣还在伙伴手里。");return
                support_site="outer";observe("outer_supported","撑扣接住旧作业台，外侧木板放平了。",OUTER_BENCH)
            elif support_site=="outer":
                if not outer_locked:
                    for member in available_roles():
                        if positions[member].x>615 and OUTER_PATH.has_point(positions[member]):say("外板还承着伙伴的重量，撑扣夹紧了。");return
                support_site="cat_carried" if role==1 else "carried"
                observe("outer_pin_free","撑扣松开；远端棘轮仍拉着作业台。" if outer_locked else "撑扣抽出，外板缓缓收回。",OUTER_BENCH)
            else:say("旧作业台的空座有同样的分叉，绳索一直连到外岸。")
        "outer_ratchet":
            if role!=1 or (support_site!="outer" and not outer_locked):say("外侧木板还没接稳重量。");return
            outer_locked=true;lifted_b=true;rear_loaded_seen=true
            observe("outer_latched","团团压下外侧棘轮，桥叶的重量换到外架；木板稳住了。",OUTER_RATCHET)
        "cart_hook":
            if role!=1 or not hook_owned:say("货车吊环挂在低处，车轴卡在岸边。");return
            cart_open=true;phase="window";act(1,"hook");observe("cart_shortcut","货车滑进轨道，空出的宽岸一直通向钟楼窗下。",CART_HOOK)
        "lamp_a","lamp_b":
            if role!=0:say("团团拍拍灯架：转动把手太高了。");return
            if item=="lamp_a":lamp_a=(lamp_a+1)%4
            else:lamp_b=(lamp_b+1)%4
            say("朵朵转动导向灯。看光束是否落在检修轨道的反光片上。")
        "brace_b":
            if role!=0 or not locked_a or locked_b:return
            if not ((support_site=="b" and lifted_b) or (support_site=="cat_carried" and rear_loaded_seen)):
                say("桥叶还低于受力柄，棘轮座没抬到承重点。装有撑扣的绞盘能把它抬上来。");return
            lifted_b=true;act(0,"brace")
            say("朵朵撑稳受力柄，绳索拉直了，撑扣两边露出松动的缝。",1)
        "winch_a","winch_b":
            if item=="winch_b" and role==1:
                handle_cat_support();return
            if role!=0:say("团团：喵。这个绞盘需要朵朵转。");return
            if item=="winch_a":
                if locked_a:say("第一段的桥锁已接住重量，绞盘旁的撑扣松开了。");return
                if support_site!="a":say("绞盘下面的撑扣座空着，桥叶抬不稳。两段用的是同一种撑扣。");return
                lifted_a=not lifted_a
            else:
                if not locked_a:say("前段还没固定，后段不能承重。");return
                if locked_b:say("同一枚撑扣已经锁进远端槽，永久桥锁独自承重。");return
                if support_site!="b":say("后段的撑扣座空着，转动时桥叶又落了回去。前段的扣槽形状和这里一样。");return
                lifted_b=not lifted_b
                if lifted_b:rear_loaded_seen=true
            if item=="winch_b" and lifted_b:
                say("后绞盘的棘轮座滑到高处承重点并卡住。桥叶抬起来了，下方受力柄现在够得到重量。",1)
            else:say("绞盘的棘轮停稳了。桥叶抬起时，下面卡扣才会卸力。",1)
        "latch_a","latch_b":
            if role!=1:say("朵朵：我进不去检修架，得让团团拨开卡扣。");return
            var second:=item=="latch_b"
            if (second and locked_b) or (not second and locked_a):
                say("桥锁已经接稳重量，团团检查了一下牢固的扣槽。后面的路仍然开着。");return
            if not (outer_locked and second) and not segment_ready(1 if second else 0):say("卡扣还在承重，轨道也没有照准。团团退回安全台。",3);return
            if second:
                if support_site!="cat_carried":say("远端锁槽和撑扣的形状一样，但槽里空着。当前重量还由近端接着。");return
                if not rear_braced() and not outer_locked:say("桥叶还没有稳定卸重，先回固定台。");recover_crawlway();return
                support_site="far";locked_b=true;phase="hook";act(1,"paw",0.7);act(0,"touch",0.7)
                facing[1]=positions[1].direction_to(positions[0]);facing[0]=positions[0].direction_to(positions[1])
                say("同一枚撑扣嵌进远端槽，桥锁咔哒接住重量。朵朵松手，团团举起前爪，她远远伸手回应：太厉害了！过来再摸摸。",2)
            else:
                locked_a=true;reverse_seen=true;say("第一段的桥锁接住重量，绞盘撑扣变松了。光点却朝灯树退去……朵朵：先站稳，看看后段为什么抬不动。",1)
        "box":
            if not locked_b:say("检修箱随桥锁闭合着。");return
            if role!=1:say("朵朵：这是小伙伴用的爪钩，团团来试试。");return
            hook_owned=true;say("团团把爪钩扣好，细钩能勾住远处的小环。",2)
        "loop":
            if role!=1 or not hook_owned:say("低处拉环适合小伙伴用爪钩。");return
            hook_practiced=true;cart_open=true;phase="window";act(role,"hook");observe("cart_shortcut","爪钩拉回货运小车，岸边空出一条通向钟楼的宽路。",LOOP)
        "shortcut":
            if role!=1 or not hook_owned:say("高处有一只细小的拉环。");return
            hook_practiced=true
            shortcut_open=true;phase="window";act(role,"hook");say("短桥落下并锁稳。钟楼就在前面。",2)
        "window":
            if not locked_b or not hook_owned or not (shortcut_open or cart_open):say("运输桥与岸边的路还没接稳，先让伙伴安全过来。");return
            if role!=0:say("团团隔着窄栏杆，与圆圆碰了碰鼻子。");return
            if positions[1].x<995:say("朵朵：团团，沿已经接通的路，到窗边来。");return
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
    if social_transition_active():
        if enabled and is_finite(dt) and dt>0 and a.is_finite() and b.is_finite():step_social_transition(dt)
        return
    super.step(dt,a,b,enabled)
    if not enabled or not is_finite(dt) or dt<=0:return
    if not locked_b and support_site!="b" and not rear_braced() and not outer_locked:lifted_b=false
    recover_crawlway()
func objective()->String:
    if not locked_a:return "把运输桥接稳，去钟楼找圆圆。"
    if not locked_b:return "后桥还没有站稳。内侧检修道与外侧作业台都通向对岸。"
    if not hook_owned:return "桥边的小检修箱打开了。"
    if not (shortcut_open or cart_open):return "钟楼前的短桥收着，货车也占住了下面的宽岸。"
    return "圆圆在低窗里面，门边的灯却是暗的。"
func tool(role:int)->void:
    if dialogue_active() or social_transition_active():return
    if role not in available_roles() or finished or action_time[role]>0 or dialogue_active() or social_transition_active():return
    var item:=target(role)
    if item in ["outer_bench","outer_ratchet","cart_hook"]:interact(role);return
    if role==0 and actions[0]=="brace":release_rear_brace();return
    if role==0 and item=="brace_b":interact(role);return
    if role==1 and item in ["winch_b","latch_b"]:interact(role);return
    if role==0 and item in ["winch_a","winch_b"]:
        if locked_b and support_site=="far":say("同一枚撑扣已经留在远端永久锁槽里，桥锁独自承重，不需要再取出。");return
        var site:="a" if item=="winch_a" else "b"
        var locked:bool=locked_a if site=="a" else locked_b
        if support_site==site:
            if not locked:say("撑扣还被整片桥叶压着。先让永久桥锁接住重量，不能硬拔。",3);return
            support_site="carried";act(0,"touch")
            say("朵朵取出同一枚撑扣。桥锁独自接住重量，固定好的桥不会掉下来。",1)
        elif support_site=="carried":
            if site=="b":say("撑扣握环露在外面。团团可以在这块固定台接过去，试着放进同形空座。");return
            support_site=site;act(0,"touch")
            say("同一枚撑扣咔哒嵌进扣座。现在绞盘能稳稳托起这片桥叶。",1)
        else:say("扣座空着。另一座绞盘上还装着唯一的撑扣。")
        return
    if role==1 and hook_owned and item in ["loop","shortcut"]:interact(role);return
    say("朵朵的工具能拆装已卸重的撑扣。" if role==0 else "团团可以用爪钩操作附近的小拉环。" if hook_owned else "团团还没有爪钩，可以先检查身边的小机关。")
func handle_cat_support()->void:
    if not locked_a:say("先让前桥锁稳，这里才有安全的固定台。");return
    if locked_b:say("撑扣已经留在远端永久锁里，后桥稳稳的。");return
    if support_site=="carried":
        if not near(0,WINCH_B,80):say("朵朵还带着唯一的撑扣，等她走近这块固定台。");return
        support_site="cat_carried";act(1,"carry")
        say("团团在固定台叼住撑扣外露的握环，朵朵松手。扣子跟着团团；再互动就能放进同形空座。",1)
    elif support_site=="cat_carried":
        support_site="b";act(1,"touch")
        say("团团把同一枚撑扣放进空座，咔哒吻合。现在可以试着抬起桥叶了。",1)
    elif support_site=="b":
        if lifted_b and not rear_braced():say("撑扣被重量紧紧夹住，团团拉不动；绳索的受力柄就在旁边。",3);return
        support_site="cat_carried";act(1,"carry")
        say("夹缝已经松开，团团叼起同一枚撑扣。朵朵撑着重量，光还照着通往远端槽的检修道。" if rear_braced() else "团团在固定台试着叼起撑扣；同形空座就在身边，可以安全放回。",1)
    else:say("唯一的撑扣还在前绞盘里，等桥锁接住重量后才能取出。")
func request_hint()->void:
    hints+=1
    var context:="first" if not locked_a else "reuse" if not locked_b else "hook" if not (shortcut_open or cart_open) else "window"
    if context=="reuse":context+="_"+str([support_site,rear_loaded_seen,lifted_b,rear_braced(),lamp_b])
    if context!=hint_context:hint_context=context;hint_level=0
    hint_level=mini(3,hint_level+1)
    var steps:={
        "first":["观察：桥叶、下方卡扣和铜片连着；绞盘里装着一枚撑扣。","规则：撑扣托住桥叶才能卸力；照准铜片后，团团能走检修轨道。","试试：朵朵把前灯转向右，转绞盘抬桥；团团从下方亮路拨开前扣。"],
        "hook":["观察：箱子、货运小车和短桥上都有适合细钩的小环。","规则：拿到爪钩就能拉远处小环；货车和短桥通向不同的路。","试试：团团开箱取钩，靠近短桥拉环；也可以先看看货车吊环。"],
        "window":["观察：低窗里面有一只熟悉的白猫。","规则：接通的上桥或下面宽岸，都能让伙伴安全到达窗边。","试试：朵朵和团团一起到低窗边，朵朵叫一声圆圆。"]}
    if context.begins_with("reuse_"):
        var local:Array[String]
        if outer_locked and support_site=="cat_carried":local=["观察：外架棘轮已接住重量，远端锁槽仍空着。","规则：沿稳定的外板走，撑扣就不用再放回临时座。","试试：团团带扣走到外板尽头，沿短梯上到远端锁槽边。"]
        elif outer_locked:local=["观察：外架绳索绷紧，作业台上的撑扣松了。","规则：永久棘轮承担重量后，撑扣可以取走复用。","试试：团团回外作业台取扣，再沿外板去远端锁槽。"]
        elif support_site=="outer":local=["观察：外板放平了，尽头连着一只棘轮。","规则：临时撑扣只能替台架承重，棘轮咬合后它才能安全取走。","试试：团团沿外板走到棘轮旁互动。"]
        elif support_site=="a":local=["观察：前桥锁落下后，撑扣不再夹紧。","规则：永久桥锁能接住重量，同一撑扣可以取出复用。","试试：朵朵在前绞盘用工具取扣。"]
        elif support_site=="carried":local=["观察：后绞盘与下方旧作业台，都有同形的空座。","规则：同一枚扣能临时撑不同的路；每条路都有把重量永久锁住的地方。","试试：选择后绞盘短路交给团团，或朵朵沿中台下阶把扣放到旧作业台。"]
        elif support_site=="cat_carried" and not rear_loaded_seen:local=["观察：团团叼住了握环，同形空座就在脚边。","规则：先在这块固定台安全放入，让绞盘接住重量。","试试：团团靠近后绞盘再互动，把同一枚扣放进空座。"]
        elif support_site=="b" and not lifted_b:local=["观察：后座已经装好，绞柄还没有抬起。","规则：撑扣先托住桥叶，重量才能交给别的支点。","试试：朵朵转动后绞盘，观察受力绳。"]
        elif lamp_b!=2:local=["观察：检修道的铜片还暗着。","规则：重量接稳还不够，团团需要看清脚下的轨道。","试试：朵朵调整后灯，让光朝下接到铜片。"]
        elif not rear_braced():local=["观察：近座承着重量，受力柄就在它的下方。","规则：朵朵能暂时接住桥叶；明确撑住后，切换角色不会让她松手。","试试：朵朵到下方受力柄互动，看看扣子是否松开。"]
        elif support_site=="b":local=["观察：绳子绷直了，撑扣露出松动的夹缝。","规则：女孩接重量后，团团就能带走这唯一的撑扣。","试试：团团在后绞盘互动取扣。"]
        else:local=["观察：远端锁槽与叼着的撑扣同形。","规则：只有远端锁接住重量，宽桥才会永久固定。","试试：团团沿亮起的检修道，把撑扣放进远端锁槽。"]
        say("提示 %d / 3 · %s"%[hint_level,local[hint_level-1]])
    else:say("提示 %d / 3 · %s"%[hint_level,steps[context][hint_level-1]])
func completion_text()->String:return "第二章完成 · 运输桥已修好，团团学会爪钩。\n圆圆就在锁着的钟楼里。下一章：修门，三位一起走。"
func restore_complete()->void:
    locked_a=true;locked_b=true;lifted_a=true;lifted_b=true;lamp_a=1;lamp_b=2;support_site="far";rear_loaded_seen=true
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
        for y in range(472,549,14):
            view.wood(Rect2(555,y,60,12),Color("c8ad7b"))
        view.rope(Vector2(555,464),Vector2(555,548))
        view.rope(Vector2(615,464),Vector2(615,548))
        view.wood(Rect2(555,280,60,95),Color("c8ad7b"))
        for edge_x in [555,615]:view.rope(Vector2(edge_x,288),Vector2(edge_x,379))
    for data in [[WINCH_A,lifted_a,locked_a,Vector2(502,386)],[WINCH_B,lifted_b,locked_b,Vector2(663,386)]]:
        var tension:bool=data[1] or data[2]
        var end:Vector2=data[3]+Vector2(0,-43 if tension and not data[2] else 0)
        view.rope(data[0]+Vector2(12,-8),end)
        view.gear(data[0],0.6 if tension else 0.0,29)
        if data[2]:view.prop(3,Rect2(data[0]+Vector2(20,-15),Vector2(24,28)))
    # The ratchet carriage is a permanent height adjustment, not an invisible
    # visited-step flag. Temporary leaf release does not lower this stop.
    var stop_top:=Vector2(636,369)
    var stop_bottom:=Vector2(636,425)
    view.draw_line(stop_top,stop_bottom,Color("74694e"),9,true)
    view.draw_line(stop_top+Vector2(-3,0),stop_bottom+Vector2(-3,0),Color("c0ab7f"),2,true)
    view.draw_arc(stop_top,8,0,TAU,16,Color("edd397"),2,true)
    var carriage:=stop_top if rear_loaded_seen else stop_bottom
    view.prop(3,Rect2(carriage-Vector2(9,11),Vector2(18,22)),0,Color("ffe1a0") if rear_loaded_seen else Color("a5aa8b"))
    view.ink(stop_top+Vector2(12,-9),"承重点",66,13)
    # One numbered prop, with matching empty sockets, visibly transfers its role.
    for entry in [[WINCH_A,"a",locked_a],[WINCH_B,"b",locked_b]]:
        var socket:Vector2=entry[0]+Vector2(33,25)
        view.draw_arc(socket,12,0,TAU,20,Color("bdab80"),3,true)
        if support_site==entry[1]:
            draw_support(view,socket)
            var unloaded:bool=entry[2] or (entry[1]=="b" and rear_braced())
            var gap:=19.0 if unloaded else 11.0
            for side in [-1,1]:view.draw_line(socket+Vector2(gap*side,-14),socket+Vector2(gap*side,10),Color("e6ce97") if unloaded else Color("8b684c"),4,true)
            view.ink(socket+Vector2(-35,33),"已卸重" if unloaded else "承重中",75,14)
        else:view.ink(socket+Vector2(-25,29),"空座",60,14)
    if support_site=="carried":draw_support(view,positions[0]+Vector2(48,-13))
    elif support_site=="cat_carried":
        var mouth:=positions[1]+Vector2(37 if facing[1].x>=0 else -37,-22)
        draw_support(view,mouth)
        view.draw_arc(mouth+Vector2(-9 if facing[1].x>=0 else 9,-9),5,0,TAU,14,Color("f0d798"),2,true)
    elif support_site=="far":draw_support(view,LATCH_B+Vector2(0,-5))
    # The second load path is visibly slack until Duoduo explicitly braces it.
    var hand:=BRACE_B+Vector2(0,-19)
    var load_point:=Vector2(657,388 if lifted_b or locked_b else 429)
    view.prop(8,Rect2(BRACE_B-Vector2(25,12),Vector2(50,23)))
    view.draw_line(hand-Vector2(17,0),hand+Vector2(17,0),Color("d8bc86"),7,true)
    if rear_braced():
        view.draw_line(hand,load_point,Color("80664b"),6,true)
        view.draw_line(hand,load_point,Color("edcf93"),2,true)
    else:
        view.draw_polyline(PackedVector2Array([hand,hand.lerp(load_point,.5)+Vector2(0,20),load_point]),Color("9b8764"),3,true)
    view.ink(BRACE_B+Vector2(-41,32),"朵朵承重" if rear_braced() else "受力柄",94,14)
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
    var cart:=Vector2(840 if cart_open else 900,600)
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

func draw_support(view:Node2D,p:Vector2)->void:
    view.prop(3,Rect2(p-Vector2(13,20),Vector2(26,36)),0,Color("ffe3a0"))
    view.draw_circle(p+Vector2(0,-4),5,Color("716348"))
    view.ink(p+Vector2(-4,-11),"1",13,12)

func presentation()->Dictionary:
    var data:=super.presentation()
    data.mechanisms=[
        {"id":"outer_bench","position":OUTER_BENCH,"angle":0.0,"load":support_site=="outer","lit":true,"connection":"latched" if outer_locked else "temporary"},
        {"id":"outer_ratchet","position":OUTER_RATCHET,"angle":1.0 if outer_locked else 0.0,"load":outer_locked,"lit":true,"connection":"bridge_b"},
        {"id":"cart_hook","position":CART_HOOK,"angle":0.0,"load":false,"lit":cart_open,"connection":"open" if cart_open else "blocked"}]
    data.paths=[{"id":"outer_steps","points":[Vector2(585,470),OUTER_BENCH],"width":60.0,"state":"permanent" if locked_a else "closed","roles":[0,1]},
        {"id":"outer_path","points":[OUTER_BENCH,OUTER_RATCHET],"width":39.0,"state":"permanent" if outer_locked else "temporary" if support_site=="outer" else "closed","roles":[1]},
        {"id":"inner_path","points":[Vector2(615,555),LATCH_B],"width":65.0,"state":"permanent" if locked_b else "temporary" if segment_ready(1) else "dark","roles":[1]}]
    for lamp in [[LAMP_A,lamp_a],[LAMP_B,lamp_b]]:
        var direction:Vector2=[Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT][lamp[1]]
        data.paths.append({"id":"lamp_ray_"+str(lamp[0]),"points":[lamp[0],lamp[0]+direction*150],"width":3.0,"state":"light","roles":[]})
    if cart_open:data.discoveries.append("two_cart")
    data.paths.append({"id":"outer_end_ladder","points":[OUTER_RATCHET,Vector2(745,555)],"width":40.0,"state":"permanent" if outer_locked else "temporary" if support_site=="outer" else "closed","roles":[1]})
    data.paths.append({"id":"cart_path","points":[Vector2(900,610),Vector2(1030,610)],"width":65.0,"state":"permanent" if cart_open else "closed","roles":[0,1]})
    data.support_site=support_site
    return data
