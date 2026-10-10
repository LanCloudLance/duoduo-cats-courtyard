extends "res://tests/keyboard_scene_test.gd"
const Driver = preload("res://tests/battle_driver.gd")
var c
var s
var b
var single := true
func go(role:int,target:Vector2)->bool:
    if single and s.controlled!=role:tap_key(KEY_TAB)
    var device:=9 if single or role==0 else 18
    for i in range(750):
        var delta:Vector2=target-s.positions[role]
        if delta.length()<8:axes(device,Vector2.ZERO);return true
        axes(device,Vector2(0 if absf(delta.x)<4 else signf(delta.x),0 if absf(delta.y)<4 else signf(delta.y)))
        await frames(1)
    axes(device,Vector2.ZERO);print("CHAPTER_GO_STUCK ",role," to ",target," current ",s.positions);return false
func touch(role:int)->void:
    if single and s.controlled!=role:tap_key(KEY_TAB)
    tap_key(KEY_E if single or role==0 else KEY_SPACE)
    await frames(36)
func drive(slot:int,direction:Vector2)->void:axes(9 if single or slot==0 else 18,direction)
func tap_key(code:int)->void:
    var mapped:int={KEY_J:KEY_F,KEY_K:KEY_Q,KEY_SPACE:KEY_E}.get(code,code) if single and lobby.stage=="chapter-combat" else code
    key_event(mapped,true);key_event(mapped,false)
func gate(v:bool,label:String)->bool:
    check(v,label)
    if not v:print("M24_PLAYTHROUGH: %d checks, %d failed"%[checks,failed]);quit(1)
    return v
func run()->void:
    Engine.time_scale = 3
    lobby=load("res://main.tscn").instantiate();root.add_child(lobby);await frames(3);lobby.session.set_focus(true)
    c=lobby.chapter_one;c.record_prefix="qa-chapter-one-"+str(Time.get_ticks_usec())
    for mode in [true,false]:
        single=mode;lobby.session.pause_all();lobby.start_chapter_one(single);await frames(3);s=c.state
        if not gate(await go(0,Vector2(330,405)),"walk to granny through real inputs"):return
        await touch(0)
        if not gate(s.equipment and s.phase=="road","granny sends party toward station and lends equipment"):return
        if not gate(await go(0,s.LIFT),"girl reaches branch handle"):return
        await touch(0)
        if not gate(s.bracing,"girl visibly keeps branch lifted"):return
        if not gate(await go(1,s.FORK),"cat reaches physical support"):return
        await touch(1)
        if not gate(await go(1,Vector2(575,570)),"cat carries support to notch"):return
        await touch(1)
        if not gate(s.supported,"support locks real cat path for single-player switching"):return
        if not gate(await go(1,Vector2(705,570)),"cat walks under lifted frame"):return
        if not gate(await go(1,s.KNOT),"cat reaches far rope"):return
        await touch(1)
        if not gate(s.branch_clear,"rope input permanently clears path"):return
        if not gate(await go(0,Vector2(1050,565)),"girl follows through open path"):return
        if not gate(await go(1,Vector2(1100,565)),"cat gathers by next road"):return
        await touch(0)
        if not gate(lobby.stage=="chapter-combat","story enters its combat without sample shortcut"):return
        b=lobby.arena.battle
        tap_key(KEY_E)
        if not single:tap_key(KEY_SPACE)
        var driver=Driver.new(self,b)
        for i in range(9000):
            if b.phase=="clear":break
            driver.step_slot(lobby.arena.solo.human_slot if single else 0)
            if not single:driver.step_slot(1)
            await frames(1)
        drive(0,Vector2.ZERO);drive(1,Vector2.ZERO);key_event(KEY_G,false)
        if not gate(b.phase=="clear" and b.wave==2,"normal attacks and real AI clear two story encounters"):print(b.enemies,b.hp);return
        for i in range(1600):
            if b.hp[0]>0 and b.hp[1]>0:break
            driver.step_slot(lobby.arena.solo.human_slot if single else 0)
            if not single:driver.step_slot(1)
            await frames(1)
        for i in range(1500):
            if b.positions[0].distance_to(b.EXIT)<80 and b.positions[1].distance_to(b.EXIT)<80:break
            for slot in range(2):
                if single and slot!=lobby.arena.solo.human_slot:continue
                var point:Vector2=b.positions[b.actor(slot)]
                drive(slot,b.Space.direction(point,b.EXIT,b.Space.ACTOR_RADIUS) if point.distance_to(b.EXIT)>20 else Vector2.ZERO)
            await frames(1)
        drive(0,Vector2.ZERO);drive(1,Vector2.ZERO)
        tap_key(KEY_E)
        if not single:tap_key(KEY_SPACE)
        await frames(3)
        if not gate(b.phase=="complete","both actual combat actors reach exit alive"):return
        tap_key(KEY_E);await frames(4)
        if not gate(lobby.stage=="chapter-one" and s.phase=="station","battle returns to same story chapter"):return
        if not gate(await go(1,s.BENCH),"cat investigates low cabinet"):return
        await touch(1)
        if not gate(await go(1,s.LAMP+Vector2(18,10)),"cat carries missing wick to lamp"):return
        await touch(1)
        if not gate(await go(0,s.LAMP+Vector2(-15,20)),"girl reaches lamp assembly"):return
        await touch(0)
        if not gate(s.core_installed and not s.lit,"delivered wick alone does not solve draft puzzle"):return
        if not gate(await go(0,s.HOOD+Vector2(25,0)),"girl reaches wind cover"):return
        await touch(0);await touch(0)
        if not gate(await go(1,s.VENT+Vector2(-25,0)),"cat reaches lower air slats"):return
        await touch(1);await frames(100)
        if not gate(s.lit,"matching visible draft direction and small vent lights station"):return
        if not gate(await go(0,s.PILLOW+Vector2(-20,0)),"girl finds flattened pillow"):return
        await touch(0)
        if not gate(s.clue_seen,"white fur gives next story destination"):return
        if not gate(await go(0,s.SEAT),"girl reaches rest bench"):return
        if not gate(await go(1,s.SEAT+Vector2(45,0)),"cat joins rest without being teleported"):return
        await touch(0);await frames(100)
        if not gate(s.finished and c.recorded,"chapter completes through inputs and writes isolated record"):return
        check(not c.read_record().is_empty(),"chapter record reads back")
        c.reset(single,true);check(c.state.finished,"solo and dual chapter records independently resume")
        print("M24_NORMAL_INPUT_COMPLETE solo=",single," retries=",b.retries)
    print("M24_PLAYTHROUGH: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
