extends Node2D
const Bridge = preload("res://game/bridge_state.gd")
var state
var font: Font
var highlight: int = -1
var keyboard := true
var solo := false
var clock := 0.0
var displayed := [0.0,0.0,0.0]
var burst := 0.0
var burst_at := Vector2.ZERO
var last_unlocked := 0
var wheel := 0.0

func _init(bridge) -> void:
    state = bridge

func _ready() -> void:
    var prop := preload("res://game/painted_prop.gd").make(Rect2(680,100,490,484),Rect2(Bridge.WINCH-Vector2(52,102),Vector2(108,107)))
    prop.show_behind_parent = true
    add_child(prop)

func advance(delta: float) -> void:
    clock += delta
    wheel = lerp_angle(wheel,state.deployed*PI/3,1-exp(-delta*10))
    for i in range(3):
        displayed[i] = move_toward(displayed[i],1.0 if i < state.deployed else 0.0,delta*4)
    burst = maxf(0,burst-delta*1.6)
    if state.unlocked > last_unlocked:
        burst_at = Bridge.LOCKS[state.unlocked-1]+Vector2(0,-36)
        burst = 1.0
    last_unlocked = state.unlocked
    queue_redraw()

func box(rect: Rect2, fill: Color, edge: Color, radius: int = 3) -> void:
    var s := StyleBoxFlat.new()
    s.bg_color = fill
    s.border_color = edge
    s.set_border_width_all(2)
    s.set_corner_radius_all(radius)
    draw_style_box(s,rect)

func label_at(text: String, point: Vector2, enabled: bool = false) -> void:
    if not font: return
    var width := maxf(82,font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x+22)
    box(Rect2(point-Vector2(width/2,23),Vector2(width,32)),Color("fff0c8") if enabled else Color("243f34"),Color("c2a774"),9)
    draw_string(font,point+Vector2(-width/2,0),text,HORIZONTAL_ALIGNMENT_CENTER,width,17,Color("3d4934") if enabled else Color("f1e4c2"))

func plank(rect: Rect2, index: int) -> void:
    draw_rect(Rect2(rect.position+Vector2(0,7),rect.size),Color(0.04,0.12,0.12,0.35))
    for x in range(int(rect.position.x),int(rect.end.x),20):
        box(Rect2(x,rect.position.y,18,rect.size.y),Color("b58a51") if (x/20+index)%2 == 0 else Color("c7a06a"),Color("6c4b30"),2)
        draw_line(Vector2(x+4,rect.position.y+9),Vector2(x+5,rect.end.y-8),Color("dac08a"),1,true)
        for y in [rect.position.y+7,rect.end.y-7]:
            draw_circle(Vector2(x+9,y),1.5,Color("5b4933"))
    for y in [rect.position.y,rect.end.y]:
        draw_line(Vector2(rect.position.x,y),Vector2(rect.end.x,y),Color("65452d"),6,true)
        draw_line(Vector2(rect.position.x,y-2),Vector2(rect.end.x,y-2),Color("ddbf81"),2,true)

func _draw() -> void:
    # Only water highlights are dynamic; the painted bed remains visible below.
    for i in range(24):
        var p := Vector2(1048+(i*71)%330,100+fmod(i*47.0+clock*15,960))
        draw_arc(p,9+i%8,0.15,PI-0.15,12,Color(0.72,0.93,0.84,0.18),1.3,true)
    if state.unlocked == 3:
        plank(Rect2(1010,584,420,112),0)
        for x in range(1018,1430,80):
            for y in [582,696]:
                draw_line(Vector2(x,y+6),Vector2(x,y-19),Color("63462d"),8,true)
                draw_circle(Vector2(x,y-20),5,Color("d4b47b"))
        for y in [566,680]:
            draw_line(Vector2(1018,y),Vector2(1418,y),Color("e2c58a"),3,true)
    else:
        for i in range(3):
            var rect := Rect2(1024+i*120,616,136,48)
            if displayed[i] > 0:
                var amount: float = displayed[i]
                plank(Rect2(rect.position,Vector2(rect.size.x*amount,rect.size.y)),i)
            else:
                for n in range(5):
                    draw_line(rect.position+Vector2(n*28,24),rect.position+Vector2(n*28+12,24),Color(0.92,0.88,0.65,0.2),2,true)
            var lock: Vector2 = Bridge.LOCKS[i]
            var ready: bool = i == state.unlocked and i < state.deployed
            var color := Color("89c6a0") if i < state.unlocked else Color("e6bb69") if ready else Color("7e8b77")
            box(Rect2(lock+Vector2(-12,-50),Vector2(24,26)),Color("544a37"),color,4)
            draw_arc(lock+Vector2(0,-49),7,PI,TAU,16,color,3,true)
            if i < state.unlocked:
                draw_polyline(PackedVector2Array([lock+Vector2(-6,-38),lock+Vector2(-1,-33),lock+Vector2(8,-43)]),color,3,true)
            else:
                draw_circle(lock+Vector2(0,-39),3,color)
            if ready:
                draw_arc(lock+Vector2(0,-39),22+sin(clock*3)*2,0,TAU,40,Color(color,0.7),2,true)
            label_at("%d  %s" % [i+1,"已开" if i < state.unlocked else "卡扣"],lock+Vector2(0,-157))
            if highlight == i+1:
                label_at(("E" if solo else "空格")+"  开锁" if keyboard else "A  开锁",lock+Vector2(0,92),true)
        label_at("团团的短腿通道",Vector2(1200,810))
    var winch: Vector2 = Bridge.WINCH
    draw_line(winch+Vector2(0,-20),Vector2(1040,624),Color("61462c"),5,true)
    draw_line(winch+Vector2(0,-22),Vector2(1040,622),Color("dbc189"),2,true)
    var center := winch+Vector2(-8,-53)
    var handle := center+Vector2.from_angle(wheel)*17
    draw_line(center,handle,Color("d7b578"),3,true)
    draw_circle(handle,3,Color("f6d794"))
    label_at("朵朵 · 调桥",winch+Vector2(-25,-178))
    if highlight == 0:
        draw_arc(center,32+sin(clock*3)*2,0,TAU,40,Color("ffe6a1"),2,true)
        label_at("E  转动" if keyboard else "A  转动",winch+Vector2(-10,65),true)
    if state.unlocked == 3:
        var p: Vector2 = Bridge.EXIT
        draw_set_transform(p,0,Vector2(1,0.55))
        draw_circle(Vector2.ZERO,78,Color(0.99,0.87,0.5,0.09))
        draw_arc(Vector2.ZERO,76,0,TAU,80,Color("e3cc88"),3,true)
        draw_set_transform(Vector2.ZERO)
        label_at("一起出发" if state.finished else "三位到齐 · 集合",p+Vector2(0,-180))
        for slot in range(1 if solo else 2):
            draw_circle(p+Vector2(-16+slot*32,65),6,Color("ffe3a0") if state.confirmed[slot] else Color("668268"))
    if burst > 0:
        for i in range(12):
            var p := burst_at+Vector2.from_angle(i*TAU/12)*(1-burst)*68
            draw_circle(p,2.5*burst,Color(1,0.87,0.49,burst))
