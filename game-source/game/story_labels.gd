extends RefCounted
## Presentation-only label placement. Never changes actor scale, position or rules.
var previous:Dictionary={}
func place(key:String,base:Rect2,protected:Array[Rect2],area:Rect2)->Rect2:
    var offsets:Array[Vector2]=[Vector2.ZERO]
    if previous.has(key):offsets.push_front(previous[key])
    for y in [-36.0,36.0,-72.0,72.0,-108.0,108.0,-144.0,144.0,180.0]:
        for x in [0.0,-76.0,76.0,-132.0,132.0,-188.0,188.0]:offsets.append(Vector2(x,y))
    for x in [-76.0,76.0,-132.0,132.0,-188.0,188.0]:offsets.append(Vector2(x,0))
    var best:=base
    var best_score:=INF
    for offset in offsets:
        var candidate:=Rect2((base.position+offset).clamp(area.position,area.end-base.size),base.size)
        var score:float=base.position.distance_to(candidate.position)*0.1
        if previous.has(key) and (candidate.position-base.position).distance_to(previous[key])>2:score+=4
        for avoid in protected:
            if candidate.grow(3).intersects(avoid):score+=10000+candidate.grow(3).intersection(avoid).get_area()
        if score<best_score:best_score=score;best=candidate
    # Rare field-edge pileups need one wider search; avoid increasing every
    # normal frame's work or allowing a badge onto a telegraphed attack lane.
    if best_score>=10000:
        for y in [-216.0,216.0,-252.0,252.0,-288.0,288.0]:
            for x in [0.0,-264.0,264.0,-340.0,340.0]:
                var candidate:=Rect2((base.position+Vector2(x,y)).clamp(area.position,area.end-base.size),base.size)
                var score:float=base.position.distance_to(candidate.position)*0.1
                for avoid in protected:
                    if candidate.grow(3).intersects(avoid):score+=10000+candidate.grow(3).intersection(avoid).get_area()
                if score<best_score:best_score=score;best=candidate
    previous[key]=best.position-base.position
    return best
func update(actors:Array,protected:Array[Rect2]=[],area:=Rect2(90,100,1100,570))->Dictionary:
    var blocked:Array[Rect2]=protected.duplicate()
    for actor in actors:
        if actor.visible:blocked.append(world_rect(actor,actor.body_rect()))
    var rects:Array[Rect2]=[]
    var moved:=0
    var overlaps:=0
    for actor in actors:
        if not actor.visible or not actor.caption_visible:continue
        actor.caption_compact=true;actor.caption_offset=Vector2.ZERO
        var base:Rect2=world_rect(actor,actor.caption_rect())
        var rect:Rect2=place("actor-"+str(actor.get_instance_id()),base,blocked,area)
        actor.caption_offset=(rect.position-base.position)/actor.scale
        actor.queue_redraw()
        for avoid in blocked:
            if rect.grow(3).intersects(avoid):overlaps+=1
        if actor.caption_offset.length()>0.1:moved+=1
        rects.append(rect);blocked.append(rect.grow(3))
    return {"overlaps":overlaps,"moved":moved,"rects":rects}
static func world_rect(actor,rect:Rect2)->Rect2:
    return Rect2(actor.position+rect.position*actor.scale,rect.size*actor.scale)
