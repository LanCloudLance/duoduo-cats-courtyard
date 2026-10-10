extends "res://tests/keyboard_scene_test.gd"
const BattleDriver=preload("res://tests/battle_driver.gd")
var c
var s
var b
var single:=true
func select(role:int)->void:
    for i in range(4):
        if (s.controlled if single else (0 if role==0 else s.current_cat))==role:return
        tap_key(KEY_TAB);await frames(1)
func go(role:int,target:Vector2)->bool:
    await select(role)
    var device:=9 if single or role==0 else 18
    for i in range(1300):
        var delta:Vector2=target-s.positions[role]
        if delta.length()<7:axes(device,Vector2.ZERO);return true
        axes(device,Vector2(0 if absf(delta.x)<3 else signf(delta.x),0 if absf(delta.y)<3 else signf(delta.y)));await frames(1)
    axes(device,Vector2.ZERO);print("STORY_GO_STUCK chapter=",s.chapter," phase=",s.phase," role=",role," to=",target," actual=",s.positions," message=",s.message);return false
func aim(role:int,direction:Vector2)->void:
    await select(role);var device:=9 if single or role==0 else 18
    axes(device,direction);await frames(1);axes(device,Vector2.ZERO);await frames(1)
func touch(role:int)->void:
    await select(role);tap_key(KEY_E if single or role==0 else KEY_SPACE);await frames(40)
func drive(slot:int,direction:Vector2)->void:axes(9 if single or slot==0 else 18,direction)
func tap_key(code:int)->void:
    var mapped:int={KEY_J:KEY_F,KEY_K:KEY_Q,KEY_SPACE:KEY_E}.get(code,code) if single and lobby.stage=="story-combat" else code
    key_event(mapped,true);key_event(mapped,false)
func gate(value:bool,label:String)->bool:
    check(value,label)
    if not value:print("M25_NORMAL_INPUT: %d checks, %d failed"%[checks,failed]);quit(1)
    return value
func start(chapter:int,mode:bool)->void:
    single=mode
    lobby.session.pause_all();lobby.start_story_chapter(chapter,single);await frames(3);c=lobby.story_chapter;s=c.state
func combat()->bool:
    if not gate(lobby.stage=="story-combat","story puzzle causally enters combat"):return false
    b=lobby.arena.battle;tap_key(KEY_E)
    if not single:tap_key(KEY_SPACE)
    var driver=BattleDriver.new(self,b)
    for i in range(14000):
        if b.phase=="clear":break
        driver.step_slot(lobby.arena.solo.human_slot if single else 0)
        if not single:driver.step_slot(1)
        await frames(1)
    drive(0,Vector2.ZERO);drive(1,Vector2.ZERO);key_event(KEY_G,false)
    if not gate(b.phase=="clear","actual attacks, shields, dodge and AI clear chapter encounter"):return false
    for i in range(1800):
        if b.hp[0]>0 and b.hp[1]>0:break
        driver.step_slot(lobby.arena.solo.human_slot if single else 0)
        if not single:driver.step_slot(1)
        await frames(1)
    for i in range(1800):
        if b.positions[0].distance_to(b.EXIT)<80 and b.positions[b.current_cat].distance_to(b.EXIT)<80:break
        for slot in range(2):
            if single and slot!=lobby.arena.solo.human_slot:continue
            var point:Vector2=b.positions[b.actor(slot)]
            drive(slot,b.Space.direction(point,b.EXIT,b.Space.ACTOR_RADIUS) if point.distance_to(b.EXIT)>20 else Vector2.ZERO)
        await frames(1)
    drive(0,Vector2.ZERO);drive(1,Vector2.ZERO);tap_key(KEY_E)
    if not single:tap_key(KEY_SPACE)
    await frames(3);tap_key(KEY_E);await frames(4)
    return gate(lobby.stage=="story-chapter" and not s.battle_requested,"actual combat gathers companions and returns to the same chapter")
func gather(p:Vector2)->bool:
    for role in s.available_roles():
        if not gate(await go(role,p+Vector2(role*25,role*10)),"all unlocked companions physically gather"):return false
    return true
func saved()->void:
    gate(s.finished and c.recorded,"normal chapter completion writes isolated record")
    check(not c.read_record().is_empty(),"saved chapter reads back")
    var n:int=s.chapter;c.reset(n,single,true);check(c.state.finished,"matching completed chapter resumes")
