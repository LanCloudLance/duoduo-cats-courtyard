extends RefCounted
## Read-only scoring policy. Durable game facts remain owned by chapter states.
## This observes edges, never grants rewards or writes saves.
var sources:Dictionary={}
var witnessed:Dictionary={}
var battle_key:=""
var battle_phase:=""

func sample(stage:String,state,run_id:String,battle=null)->Dictionary:
    var result:={"profile":"home","mood":"flow","accent":""}
    if stage in ["combat","chapter-combat","story-combat"] and battle!=null:
        var phase:String=battle.phase
        result.profile="boss" if battle.story_encounter=="reserve" else "battle"
        result.mood="pressure" if phase=="combat" else "reflect"
        if phase in ["briefing","intermission","failed"]:result.profile="rest"
        if phase in ["clear","complete"]:result.profile="rest";result.mood="resolved"
        var key:String=run_id+":"+stage+":"+str(state.get_instance_id() if state!=null else 0)+":"+battle.story_encounter
        if key==battle_key and battle_phase in ["combat","intermission"] and phase in ["clear","complete"]:result.accent="resolved"
        battle_key=key;battle_phase=phase
        return result
    if stage in ["bridge","light","gate","rest"]:
        result.profile={"bridge":"explore","light":"puzzle","gate":"puzzle","rest":"rest"}[stage]
        return result
    if state==null:return result
    var chapter:int=0 if stage=="prologue" else 1 if stage=="chapter-one" else int(state.chapter) if stage=="story-chapter" else -1
    if chapter<0:
        result.profile={"bridge":"explore","light":"puzzle","gate":"puzzle","rest":"rest"}.get(stage,"home")
        return result
    var phase:String=state.phase
    match chapter:
        0:
            result.profile="home"
            if phase=="jam":result.mood="reflect"
        1:
            result.profile="rest" if state.lit else "puzzle" if phase=="station" else "explore"
            if state.lit:result.mood="resolved"
        2:
            result.profile="chapter2"
            result.mood="flow" if state.locked_a else "reflect"
        3:
            result.profile="chapter3"
            result.mood="reflect" if phase in ["door","walkway"] else "flow"
        4:
            result.profile="chapter4"
            result.mood="reflect" if phase in ["investigate","test"] else "flow"
            if not state.visit_room.is_empty():result.mood="flow"
            if phase=="rest":result.profile="rest";result.mood="resolved"
        5:
            result.profile="chapter5"
            result.mood="pressure" if phase=="shield" else "reflect" if phase in ["lure","unjam","withdraw","test"] else "flow"
            if phase in ["network","farewell"]:result.profile="rest";result.mood="resolved"
            if phase in ["home","complete"]:result.profile="home";result.mood="resolved"
    if state.finished and chapter<5:result.mood="resolved"
    if state.has_method("dialogue_active") and state.dialogue_active():result.mood="reflect"
    var key:String=run_id+":"+str(chapter)
    var id:int=state.get_instance_id()
    var now:Dictionary=facts(chapter,state)
    # Loading / replacing a state primes it. Old discoveries must not sound new.
    if sources.get(key,-1)==id:
        var before:Dictionary=witnessed.get(key,{})
        for fact in now:
            if now[fact] and not before.get(fact,false):
                var cue:String="reunion" if fact=="joined" else "discovery" if fact in ["ball_found","map_discovered","stall_seen","view_seen","cart_open"] else "resolved"
                if result.accent.is_empty() or cue=="reunion":result.accent=cue
    sources[key]=id;witnessed[key]=now
    return result

func facts(chapter:int,state)->Dictionary:
    var keys:Array=[]
    match chapter:
        0:keys=["ball_found","wedged","finished"]
        1:keys=["lit","finished"]
        2:keys=["locked_a","locked_b","outer_locked","cart_open","finished"]
        3:keys=["joined","bridge_locked","map_discovered","finished"]
        4:keys=["shell_fixed","reserve_hold_seen","stall_seen","view_seen","finished"]
        5:keys=["arm_locked","machine_stopped","tested","network_lit","finished"]
    var value:Dictionary={}
    for key in keys:value[key]=state.get(key)==true
    return value
