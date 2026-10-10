extends SceneTree
var checks:=0
var failed:=0
func check(ok:bool,label:String)->void:
    checks+=1
    if not ok:failed+=1;push_error("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
    check(FileAccess.file_exists("res://game/story_labels.gd"),"shared labels layout exists")
    if failed:finish();return
    var Layout=load("res://game/story_labels.gd")
    var Actor=load("res://game/actor_view.gd")
    var actors:Array=[]
    for role in range(3):
        var actor=Actor.new();actor.role=role;actor.storybook=true
        actor.position=[Vector2(778,405),Vector2(701,312),Vector2(625,430)][role]
        actor.caption_override=["朵朵 · 你控制","团团 · 伙伴","圆圆 · 稳光中"][role]
        actors.append(actor)
    var obstacles:Array[Rect2]=[Rect2(677,242,76,96),Rect2(743,365,70,80),Rect2(593,385,64,90)]
    var solver=Layout.new()
    var metrics:Dictionary=solver.update(actors,obstacles)
    check(metrics.overlaps==0,"C4 nameplates avoid other actors and live mechanism cores")
    check(metrics.moved>0,"C4 reproduced overlap actually moves a label")
    check(actors[0].caption_text()=="朵朵" and actors[2].caption_text().contains("稳光"),"remove redundant control prose but retain live holding status")
    var original:Array=[]
    for actor in actors:
        original.append(actor.caption_offset)
        check(actor.scale==Vector2.ONE,"label solve preserves readable character scale")
    for frame in range(90):
        metrics=solver.update(actors,obstacles)
    for i in range(3):check(actors[i].caption_offset==original[i],"stationary labels remain stable without jitter")
    actors[0].position+=Vector2(15,0)
    check(solver.update(actors,obstacles).overlaps==0,"moving actor triggers safe dynamic label placement")
    actors[1].scale=Vector2(1,0.65)
    check(is_equal_approx(Layout.world_rect(actors[1],actors[1].caption_rect()).size.y,26),"downed pose never compresses readable nameplate height")
    actors[2].visible=false
    check(solver.update(actors,obstacles).rects.size()==2,"absent roles reserve no phantom label")
    for actor in actors:actor.free()
    finish()
func finish()->void:
    print("M27_LABELS: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
