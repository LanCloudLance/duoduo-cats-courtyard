extends RefCounted
## Retain only cleared segments and selected roster. An unfinished segment restarts safely.
const Checkpoint=preload("res://game/story_checkpoint.gd")
const Journey=preload("res://game/story_journey.gd")
var last_error:=""
func valid(value:Dictionary)->bool:
    for key in ["encounter_id","mode","story_run_id","return_phase"]:
        if not value.get(key) is String:return false
    if not Checkpoint.integer(value.get("version"),1,1) or not Checkpoint.integer(value.get("completed_segments"),0,2):return false
    if value.get("encounter_id") not in ["first","shell","reserve"] or value.get("mode") not in ["solo","dual"]:return false
    var revision=value.get("encounter_revision",1)
    if not Checkpoint.integer(revision,1,2):return false
    var opened=value.get("route_open",false)
    if not opened is bool:return false
    if revision==2 and not value.has("route_open"):return false
    if revision==2 and (value.encounter_id not in ["shell","reserve"] or (value.get("completed_segments")!=0 and value.get("completed_segments")!=2) or opened!=(value.get("completed_segments")==2)):return false
    if revision==1 and opened:return false
    var single:bool=value.mode=="solo"
    var chapter=value.get("return_chapter")
    if not Journey.new().valid({"version":1,"mode":value.mode,"run_id":value.get("story_run_id"),"chapter":chapter},single):return false
    var expected:Dictionary={"first":[1,"battle"],"shell":[4,"battle_one"],"reserve":[4,"battle_two"]}
    if chapter!=expected[value.encounter_id][0] or value.get("return_phase")!=expected[value.encounter_id][1]:return false
    if not Checkpoint.integer(value.get("completed_segments"),0,2) or not Checkpoint.integer(value.get("selected_role_id"),0,1 if value.encounter_id=="first" else 2) or not Checkpoint.integer(value.get("current_cat"),1,1 if value.encounter_id=="first" else 2):return false
    return true
func path(context:Dictionary)->String:
    return "user://"+str(context.get("story_run_id"))+"-battle-"+str(context.get("encounter_id",context.get("id")))+"-"+str(context.get("mode"))+"-v1.json"
func save(result:Dictionary)->bool:
    last_error=""
    var value:Dictionary=result.duplicate(true);value["version"]=1;value.erase("outcome")
    if not valid(value):last_error="战斗段记录不完整，已有记录保留。";return false
    var name:=path(value);var f:=FileAccess.open(name+".tmp",FileAccess.WRITE)
    if not f:last_error="这一段暂未记录，退出后将从上次安全段继续。";return false
    f.store_string(JSON.stringify(value));f.flush();var error:=f.get_error();f.close()
    if error!=OK or DirAccess.rename_absolute(ProjectSettings.globalize_path(name+".tmp"),ProjectSettings.globalize_path(name))!=OK:
        last_error="这一段暂未记录，退出后将从上次安全段继续。";return false
    return true
func read(context:Dictionary)->Dictionary:
    var f:=FileAccess.open(path(context),FileAccess.READ)
    if not f:return {}
    if f.get_length()>4096:f.close();return {}
    var value=JSON.parse_string(f.get_as_text());f.close()
    if not value is Dictionary or not valid(value):return {}
    for key in ["mode","story_run_id","return_chapter","return_phase"]:
        if value.get(key)!=context.get(key):return {}
    if value.encounter_id!=context.get("id"):return {}
    # JSON numbers are floats; the live encounter boundary requires exact ints.
    return {"encounter_revision":int(value.get("encounter_revision",1)),"route_open":bool(value.get("route_open",false)),"cleared_segments":int(value.completed_segments),"selected_role_id":int(value.selected_role_id),"current_cat":int(value.current_cat)}
