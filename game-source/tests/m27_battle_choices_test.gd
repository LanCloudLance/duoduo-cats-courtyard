extends "res://tests/keyboard_scene_test.gd"
# Known-solution two-choice route probe. All progress uses ordinary input events.
const Driver=preload("res://tests/battle_driver.gd")
var b
var single:=false
var records:Array=[]
func drive(slot:int,vector:Vector2)->void:axes(9 if single or slot==0 else 18,vector)
func tap_key(code:int)->void:
    var mapped:int={KEY_J:KEY_F,KEY_K:KEY_Q,KEY_SPACE:KEY_E}.get(code,code) if single else code
    key_event(mapped,true);key_event(mapped,false)
func click_button(name:String)->void:
    var button_node:Button=lobby.get_node(name)
    var point:Vector2=root.get_final_transform()*button_node.get_global_rect().get_center()
    for down in [true,false]:
        var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=point;event.global_position=point
        Input.parse_input_event(event);Input.flush_buffered_events()
    await frames(2)
func flank_step(waypoint:int)->int:
    var point:Vector2=b.positions[b.current_cat]
    var path:Array[Vector2]=[Vector2(550,700),Vector2(870,710)]
    if waypoint<path.size():
        if point.distance_to(path[waypoint])<28:waypoint+=1
        else:drive(1,b.Space.direction(point,path[waypoint],18));return waypoint
    var target:Dictionary={}
    for enemy in b.enemies:
        if enemy.kind=="weaver":target=enemy;break
    if target.is_empty():return 3
    var direction:Vector2=point.direction_to(target.pos)
    var distance:float=point.distance_to(target.pos)
    drive(1,b.Space.direction(point,target.pos,18) if distance>72 else direction if b.facing[1].dot(direction)<0.94 else Vector2.ZERO)
    if distance<93 and b.facing[1].dot(direction)>0.9 and b.attack_cooldown[1]<=0:tap_key(KEY_J)
    for enemy in b.enemies:
        if b.Encounter.danger(enemy,point,12) and enemy.timer<0.25 and b.dodge_cooldown[1]<=0:
            drive(1,enemy.direction.orthogonal() if enemy.mode in ["windup","rush"] else enemy.get("aim",enemy.pos).direction_to(point))
            tap_key(KEY_K)
    return waypoint
func run()->void:
    Engine.time_scale=1
    lobby=load("res://main.tscn").instantiate();root.add_child(lobby);await frames(2)
    lobby.session.set_focus(true)
    for solo_mode in [false,true]:
        for choice in ["front_guard","lower_flank"]:
            single=solo_mode
            await click_button("SoloCombatPreview" if single else "CombatPreview")
            b=lobby.arena.battle;b.story_encounter="shell"
            check(lobby.arena.visible and b.phase=="briefing","ordinary menu click opens fresh battle")
            if single and choice=="lower_flank":tap_key(KEY_TAB)
            tap_key(KEY_E)
            if not single:tap_key(KEY_SPACE)
            await frames(2)
            var driver=Driver.new(self,b)
            var waypoint:=0
            var cursor:=0
            var tactical_done:=false
            var marked_weaver:=false
            var guard_samples:=0
            var lane_samples:=0
            var input_frames:=0
            var counts:Dictionary={}
            var first_death:=""
            for frame in range(11000):
                if b.phase=="clear":break
                input_frames=frame
                if b.wave!=1 or b.retries>0:tactical_done=true
                if frame==90:
                    drive(0,Vector2.ZERO)
                    if not single:drive(1,Vector2.ZERO)
                    tap_key(KEY_ESCAPE);var before:Array=b.positions.duplicate();await frames(6)
                    check(b.positions==before,"pause does not advance tactical choice")
                    tap_key(KEY_ENTER)
                if choice=="lower_flank" and not tactical_done and b.phase=="combat":
                    if not single:driver.step_slot(0)
                    waypoint=flank_step(waypoint)
                    if b.positions[b.current_cat].y>645:lane_samples+=1
                    for enemy in b.enemies:
                        if enemy.kind=="weaver" and enemy.get("mark_time",0.0)>0:
                            marked_weaver=true;tactical_done=true
                    if b.hp[1]<=0:tactical_done=true
                elif choice=="front_guard" and not tactical_done and b.phase=="combat":
                    driver.step_slot(0)
                    if not single:
                        drive(1,b.Space.direction(b.positions[b.current_cat],b.positions[0]+Vector2(-80,100),18))
                    if not b.enemies.any(func(e):return e.kind=="thorn"):tactical_done=true
                    if b.hp[0]<=0:tactical_done=true
                else:
                    if single:driver.step_slot(lobby.arena.solo.human_slot)
                    else:driver.step_slot(0);driver.step_slot(1)
                if b.guarding:guard_samples+=1
                for event in b.feedback_since(cursor):
                    counts[event.kind]=counts.get(event.kind,0)+1
                cursor=b.feedback_id
                if first_death.is_empty() and not b.fallen.is_empty():first_death=b.fallen[0].kind
                await frames(1)
            drive(0,Vector2.ZERO)
            if not single:drive(1,Vector2.ZERO)
            key_event(KEY_G,false)
            check(b.phase=="clear" and b.wave==2,"choice remains clearable using ordinary input "+choice+" solo="+str(single))
            if choice=="lower_flank":check(lane_samples>0 and marked_weaver,"side route actually reaches and marks caster before fallback")
            else:check(guard_samples>0,"front route actually guards live pressure")
            var record={"solo":single,"choice":choice,"phase":b.phase,"retries":b.retries,"hp":b.hp.duplicate(),"frames":input_frames,"guard_samples":guard_samples,"side_lane_samples":lane_samples,"marked_weaver":marked_weaver,"first_defeat":first_death,"feedback":counts}
            records.append(record);print("N4_CHOICE ",JSON.stringify(record))
            driver.host=null;driver.b=null;driver=null
            tap_key(KEY_ESCAPE);await frames(2)
    var file=FileAccess.open("res://n4-choices.json",FileAccess.WRITE);file.store_string(JSON.stringify(records,"  "));file.close()
    lobby.queue_free();b=null;lobby=null;await frames(4)
    var deadline:=Time.get_ticks_msec()+100
    while Time.get_ticks_msec()<deadline:await process_frame
    print("M27_BATTLE_CHOICES: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
