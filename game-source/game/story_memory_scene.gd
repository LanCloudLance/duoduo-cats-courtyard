extends CanvasLayer
## A confirmed story beat revisits the four places the party actually repaired.
const Stage=preload("res://game/story_stage_art.gd")
const BACKGROUNDS=[preload("res://assets/story-chapter-one/waystation.png"),preload("res://assets/visual-m26/chapter-two.png"),preload("res://assets/visual-m26/chapter-three.png"),preload("res://assets/visual-m26/chapter-four.png")]
const MECHANISMS=preload("res://assets/visual-m26/mechanisms.png")
const FLOOR=preload("res://assets/visual-m26/floor-pieces.png")
var canvas:=Node2D.new()
var scene_canvas:=Node2D.new()
var font:Font
var index:=0
var clock:=0.0
var regions:Dictionary
func _init(value:Font)->void:font=value
func _ready()->void:
    layer=32;add_child(canvas);canvas.draw.connect(_draw_scene);visible=false
    add_child(scene_canvas);scene_canvas.position=Vector2(280,92);scene_canvas.scale=Vector2(.5625,.5625);scene_canvas.draw.connect(_draw_landmark)
    regions=JSON.parse_string(FileAccess.get_file_as_string("res://assets/visual-m26/props-regions.json"))
func present(state,delta:float)->void:
    var social:Dictionary=Stage.data(state).get("social",{})
    visible=Stage.dialog_active(state) and social.get("kind","")=="network"
    if visible:index=clampi(state.dialogue_index,0,3);clock+=delta;canvas.queue_redraw();scene_canvas.queue_redraw()
func _draw_scene()->void:
    canvas.draw_rect(Rect2(0,0,1280,800),Color(.08,.14,.12,.83))
    Stage.panel(canvas,Rect2(266,79,748,474),Color("dac594"))
    canvas.draw_string(font,Vector2(280,59),["驿站的窗又亮了","运输桥不再等人撑住","钟楼走完了整段报时","集市有人挂回了招牌"][index],HORIZONTAL_ALIGNMENT_CENTER,720,26,Color("fff0ce"))
    for i in range(4):canvas.draw_circle(Vector2(580+i*40,549),6,Color("f3d28a") if i<=index else Color("766d56"))
func _draw_landmark()->void:
    scene_canvas.draw_texture_rect(BACKGROUNDS[index],Rect2(0,0,1280,800),false)
    if index==0:
        _lamp(Vector2(980,520));Stage.npc(scene_canvas,2,2,Vector2(830,505),150,clock)
    elif index==1:
        for r in [Rect2(460,375,155,95),Rect2(615,375,145,95),Rect2(460,520,155,75),Rect2(615,520,145,75),Rect2(555,460,60,88)]:scene_canvas.draw_texture_rect_region(FLOOR,r,Rect2(96,132,855,302))
        for edge in [375,470]:
            scene_canvas.draw_line(Vector2(455,edge),Vector2(765,edge),Color("795f3a"),6,true);scene_canvas.draw_line(Vector2(455,edge-2),Vector2(765,edge-2),Color("d6bd8d"),2,true)
        _lamp(Vector2(390,300));_lamp(Vector2(595,315))
        Stage.latch(scene_canvas,Rect2(548,525,42,49),true,0);Stage.latch(scene_canvas,Rect2(698,525,42,49),true,0)
    elif index==2:
        _lamp(Vector2(580,315));_lamp(Vector2(945,385))
        scene_canvas.draw_arc(Vector2(665,251),49,-PI*.5,clock*.7,30,Color("f7dc9f"),4,true)
    else:
        _lamp(Vector2(290,350));_lamp(Vector2(590,315));_lamp(Vector2(945,340))
        Stage.npc(scene_canvas,1,2,Vector2(310,510),150,clock)
        Stage.panel(scene_canvas,Rect2(200,354,104,43),Color("6c8763"))
        scene_canvas.draw_circle(Vector2(251,375),12,Color("efd697"))
func _lamp(p:Vector2)->void:
    var r:Array=regions.mechanisms[2]
    scene_canvas.draw_texture_rect_region(MECHANISMS,Rect2(p-Vector2(33,95),Vector2(66,105)),Rect2(r[0],r[1],r[2],r[3]))
    for j in range(4):scene_canvas.draw_circle(p+Vector2(12,-43),50-j*9,Color(1,.77,.34,.035+j*.02))
