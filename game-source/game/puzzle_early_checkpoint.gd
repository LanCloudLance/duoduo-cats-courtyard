extends RefCounted
const Prologue=preload("res://game/prologue_checkpoint.gd")
const One=preload("res://game/chapter_one_checkpoint.gd")
const KEYS={0:["ball_found"],1:["cloth_found","night_shade","night_vent","night_lit","nightlight_taken"]}
static func capture(s,chapter:int)->Dictionary:
    var data:Dictionary=Prologue.capture(s) if chapter==0 else One.capture(s)
    data["puzzle_revision"]=1
    var discoveries:Dictionary={}
    for key in KEYS[chapter]:discoveries[key]=s.get(key)
    data["puzzle_facts"]=discoveries
    return data
static func restore(s,data:Dictionary,chapter:int)->bool:
    var facts:Dictionary={}
    if data.has("puzzle_revision"):
        if data.get("puzzle_revision")!=1 or not data.get("puzzle_facts") is Dictionary:return false
        facts=data.puzzle_facts
        if facts.size()!=KEYS[chapter].size():return false
        for key in KEYS[chapter]:
            if typeof(facts.get(key))!=TYPE_BOOL:return false
        if chapter==1:
            if not data.get("facts") is Dictionary:return false
            if facts.cloth_found and not data.facts.get("clue_seen",false):return false
            if facts.night_shade and not facts.cloth_found:return false
            if facts.night_vent and not facts.cloth_found:return false
            if facts.night_lit and not (facts.night_shade and facts.night_vent and data.get("facts",{}).get("lit",false)):return false
            if facts.nightlight_taken and not facts.night_lit:return false
    var valid:bool=Prologue.restore(s,data) if chapter==0 else One.restore(s,data)
    if not valid:return false
    for key in KEYS[chapter]:s.set(key,facts.get(key,false))
    if chapter==1:s.social_goals.clear();s.social_lines.clear();s.social_gesture.clear();s.night_gift_pending=false
    s.dialogue.clear();s.dialogue_index=0;s.social.clear();s.social_remaining=0
    return true
