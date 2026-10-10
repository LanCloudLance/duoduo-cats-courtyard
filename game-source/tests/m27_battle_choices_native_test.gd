extends "res://tests/m27_battle_choices_test.gd"
# Bounded native active capture, ordinary practice entry; no seeded combat state.
var timeline:Array=[]
func capture(name:String)->void:
    if DisplayServer.get_name()=="headless":return
    await RenderingServer.frame_post_draw
    check(root.get_texture().get_image().save_png("res://n4-native-"+name+".png")==OK,"native capture "+name)
func run()->void:
    Engine.max_fps=60;Engine.time_scale=1
    root.size=Vector2i(1280,800);root.position=Vector2i(45,55);root.grab_focus()
    lobby=load("res://main.tscn").instantiate();root.add_child(lobby);await frames(3)
    lobby.session.set_focus(true);single=false
    for choice in ["front_guard","lower_flank"]:
        await click_button("CombatPreview")
        b=lobby.arena.battle;b.story_encounter="shell"
        check(lobby.session.focused and lobby.arena.visible,"native focused "+choice)
        var start:Vector2=b.positions[0];drive(0,Vector2.RIGHT);await frames(8);drive(0,Vector2.ZERO)
        check(b.positions[0].x>start.x+10,"native movement accepted before action "+choice)
        tap_key(KEY_E);tap_key(KEY_SPACE);await frames(2)
        var driver=Driver.new(self,b)
        var waypoint:=0
        var marked:=false
        var switched:=false
        var heavy_started:=false
        var heavy_released:=false
        var guard_seen:=false
        var attack_seen:=false
        var combo_seen:=false
        var cursor:=0
        var capture_frames:Array=[]
        for frame in range(660):
            driver.step_slot(0)
            if b.guarding and not guard_seen:
                guard_seen=true
                if choice=="front_guard":capture_frames.append_array([frame,frame+1,frame+2])
            if choice=="lower_flank" and not marked and b.wave==1 and b.phase=="combat":
                waypoint=flank_step(waypoint)
                for enemy in b.enemies:
                    if enemy.kind=="weaver" and enemy.get("mark_time",0.0)>0:
                        marked=true;capture_frames.append_array([frame,frame+1,frame+2])
            elif marked and (not heavy_released or b.attack_flash[1]>0.02):
                drive(1,Vector2.ZERO)
                if not switched:
                    tap_key(KEY_TAB);switched=true
                elif not heavy_started and b.attacks.available(b,1):
                    key_event(KEY_J,true);heavy_started=true
                elif not heavy_released and b.attacks.charging and b.attacks.charge_time>=b.attacks.CHARGE_SECONDS-0.00001:
                    key_event(KEY_J,false);heavy_released=true
            else:driver.step_slot(1)
            var feedback:Array=[]
            for event in b.feedback_since(cursor):
                feedback.append(event.kind)
                if event.kind in ["hit","heavy"]:attack_seen=true
                if event.kind=="combo":
                    combo_seen=true;capture_frames.append_array([frame,frame+1,frame+2])
            cursor=b.feedback_id
            var enemies:Array=[]
            for enemy in b.enemies:enemies.append({"kind":enemy.kind,"at":str(enemy.pos),"mode":enemy.mode,"mark":enemy.get("mark_time",0),"hp":enemy.hp})
            timeline.append({"choice":choice,"frame":frame,"tick_ms":Time.get_ticks_msec(),"focused":lobby.session.focused,"phase":b.phase,"wave":b.wave,"hp":b.hp.duplicate(),"cat":b.current_cat,"positions":str(b.positions),"guard":b.guarding,"spare_goal":str(b.spare_goal()),"spare_over_warning":b.spare_obstructs_warning(b.positions[3-b.current_cat]),"spare_alpha":lobby.arena.actors[3-b.current_cat].modulate.a,"labels_overlap":lobby.arena.label_metrics.get("overlaps",-1),"enemies":enemies,"feedback":feedback})
            if frame in [1,330] or frame in capture_frames:await capture(choice+"-%03d"%frame)
            await frames(1)
        check(attack_seen,"native ordinary attacks land "+choice)
        check(guard_seen,"native ordinary shield faces threat "+choice)
        if choice=="lower_flank":check(marked and heavy_started and heavy_released and combo_seen,"native route marks then switches and lands real heavy handoff")
        drive(0,Vector2.ZERO);drive(1,Vector2.ZERO);key_event(KEY_G,false);key_event(KEY_J,false)
        driver.host=null;driver.b=null;driver=null
        tap_key(KEY_ESCAPE);await frames(2)
    var file=FileAccess.open("res://n4-native-timeline.json",FileAccess.WRITE);file.store_string(JSON.stringify(timeline,"  "));file.close()
    lobby.queue_free();b=null;lobby=null;await frames(4)
    var end:=Time.get_ticks_msec()+100
    while Time.get_ticks_msec()<end:await process_frame
    print("M27_BATTLE_CHOICES_NATIVE: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
