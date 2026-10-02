extends RefCounted
## Shared input/save rules only; each chapter owns its puzzle and world.
const FLOOR := Rect2(90,180,1100,490)
var chapter := 2
var title := "第二章"
var chapter_key := "chapter-two"
var phase := "arrival"
var positions: Array[Vector2] = [Vector2(210,470),Vector2(275,510),Vector2(240,575)]
var facing: Array[Vector2] = [Vector2.RIGHT,Vector2.RIGHT,Vector2.RIGHT]
var current_cat := 1
var controlled := 0
var single := true
var joined := false
var finished := false
var allow_epilogue := false
var clock := 0.0
var message := ""
var message_time := 0.0
var event_id := 0
var cue := 0
var hints := 0
var actions: Array[String] = ["","",""]
var action_time: Array[float] = [0.0,0.0,0.0]
var extras := {}
var battle_requested := false
var battle_waves := 2
var battles_finished := 0
var follow_paths := {}
var follow_goals := {}
var follow_retry := 0.0
func available_roles() -> Array:
    return [0,1,2] if joined else [0,1]
func switch_actor() -> void:
    if not single:return
    var roles:=available_roles();controlled = roles[(roles.find(controlled)+1)%roles.size()]
func switch_cat() -> void:
    if joined:current_cat=3-current_cat
func actor_for_slot(slot:int)->int:return controlled if single else (0 if slot==0 else current_cat)
func say(text:String,sound:=0)->void:
    message=text;message_time=8;event_id+=1;cue=clampi(sound,0,3)
func act(role:int,kind:String,seconds:=0.55)->void:
    actions[role]=kind;action_time[role]=seconds
func near(role:int,p:Vector2,reach:=65.0)->bool:return positions[role].distance_to(p)<reach
func all_near(p:Vector2,reach:=130.0)->bool:
    for role in available_roles():
        if not near(role,p,reach):return false
    return true
func exit_gather(p:Vector2)->bool:
    if not all_near(p):say("朵朵：先让伙伴都到身边，我们一起走。");return false
    return true
func walkable(p:Vector2,_role:int)->bool:return p.is_finite() and FLOOR.grow(-16).has_point(p)
func follow_allowed(role:int,p:Vector2)->bool:return walkable(p,role)
func move(role:int,offset:Vector2)->void:
    var n:=maxi(1,ceili(offset.length()/5))
    for i in range(n):
        for part in [Vector2(offset.x/n,0),Vector2(0,offset.y/n)]:
            if walkable(positions[role]+part,role):positions[role]+=part
func step(dt:float,a:Vector2,b:Vector2,enabled:bool)->void:
    if not enabled or not is_finite(dt) or dt<=0 or not a.is_finite() or not b.is_finite():return
    dt=minf(dt,0.05);clock+=dt;message_time=maxf(0,message_time-dt)
    if finished and not allow_epilogue:return
    for role in available_roles():
        action_time[role]=maxf(0,action_time[role]-dt)
        var motion:=Vector2.ZERO
        if single:
            if role==controlled:motion=a
        elif role==0:motion=a
        elif role==current_cat:motion=b
        if motion.length()>0.1:
            facing[role]=motion.normalized()
            if actions[role] in ["hold","brace","light"]:actions[role]=""
        elif action_time[role]<=0 and actions[role] not in ["hold","brace","light"]:actions[role]=""
        move(role,motion.limit_length()*200*dt)
    if not single and joined:
        follow_retry=maxf(0,follow_retry-dt)
        var follower:=3-current_cat
        var goal:=positions[current_cat]+Vector2(-32,26)
        if not follow_allowed(follower,goal):goal=positions[current_cat]
        if actions[follower] not in ["hold","brace","light"] and positions[follower].distance_to(goal)>22:
            follow_partner(follower,goal,dt)
func follow_segment(role:int,a:Vector2,b:Vector2)->bool:
    var count:=maxi(1,ceili(a.distance_to(b)/5.0))
    for i in range(1,count+1):
        if not follow_allowed(role,a.lerp(b,float(i)/count)):return false
    return true
func follow_partner(role:int,goal:Vector2,dt:float)->void:
    var waypoint:=goal
    if not follow_segment(role,positions[role],goal):
        var path:Array=follow_paths.get(role,[])
        var old_goal:Vector2=follow_goals.get(role,Vector2.INF)
        if (path.is_empty() and follow_retry<=0) or old_goal.distance_to(goal)>45:
            path=permanent_route(role,positions[role],goal)
            follow_paths[role]=path;follow_goals[role]=goal;follow_retry=0.5
        while not path.is_empty() and positions[role].distance_to(path[0])<5:path.pop_front()
        if path.is_empty():return
        waypoint=path[0]
        if not follow_segment(role,positions[role],waypoint):follow_paths.erase(role);return
    else:follow_paths.erase(role)
    var offset:=positions[role].direction_to(waypoint)*minf(170*dt,positions[role].distance_to(waypoint))
    if follow_segment(role,positions[role],positions[role]+offset):move(role,offset)
# Route only on chapter-approved permanent floor. It cannot actuate any puzzle.
func permanent_route(role:int,start:Vector2,goal:Vector2)->Array:
    var origin:=Vector2(110,200)
    var unit:=20.0
    var cell:=Vector2i(roundi((start.x-origin.x)/unit),roundi((start.y-origin.y)/unit))
    var first:=Vector2i(-100,-100)
    var best:=INF
    for x in range(cell.x-2,cell.x+3):
        for y in range(cell.y-2,cell.y+3):
            var point:=origin+Vector2(x,y)*unit
            if follow_allowed(role,point) and follow_segment(role,start,point) and start.distance_to(point)<best:
                first=Vector2i(x,y);best=start.distance_to(point)
    if first.x==-100:return []
    var queue:Array[Vector2i]=[first]
    var parent:Dictionary={first:first}
    var cursor:=0
    var last:=Vector2i(-100,-100)
    while cursor<queue.size():
        var here:Vector2i=queue[cursor];cursor+=1
        var point:=origin+Vector2(here)*unit
        if point.distance_to(goal)<30 and follow_segment(role,point,goal):last=here;break
        for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
            var next:Vector2i=here+direction
            if next.x<0 or next.x>53 or next.y<0 or next.y>22 or parent.has(next):continue
            var next_point:=origin+Vector2(next)*unit
            if follow_allowed(role,next_point) and follow_segment(role,point,next_point):parent[next]=here;queue.append(next)
    if last.x==-100:return []
    var path:Array=[goal]
    while last!=first:
        path.push_front(origin+Vector2(last)*unit);last=parent[last]
    path.push_front(origin+Vector2(first)*unit)
    return path
func target(_role:int)->String:return ""
func interact(_role:int)->void:pass
func objective()->String:return title
func request_hint()->void:say("朵朵：看一看物件的变化，再试不同的方法。")
func tool(_role:int)->void:request_hint()
func guard(_role:int,_held:bool)->void:pass
func attack(_role:int)->void:say("朵朵：这里的机关需要工具和观察。")
func after_battle()->void:
    battles_finished+=1;battle_requested=false
func draw_world(_view:Node2D)->void:pass
func completion_text()->String:return title+" ✓\n伙伴们一起走过了这段路。"
func record()->Dictionary:
    if not finished:return {}
    return {"version":1,"chapter":chapter_key,"completed":true,"extras":extras.duplicate()}
func restore(value:Dictionary)->void:
    if value.get("version")!=1 or value.get("chapter")!=chapter_key or typeof(value.get("completed"))!=TYPE_BOOL or value.get("completed")!=true or not value.get("extras",{}) is Dictionary:return
    extras=value.get("extras",{}).duplicate();restore_complete()
func restore_complete()->void:finished=true;phase="complete"
