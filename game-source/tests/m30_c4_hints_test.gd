extends SceneTree
const Four=preload("res://game/chapter_four_state.gd")
var checks:=0
var failed:=0
func check(ok:bool,label:String)->void:
    checks+=1
    if not ok:failed+=1;print("FAIL ",label)
func _init()->void:
    if OS.get_user_data_dir().get_file()!="DuoduoCatsCourtyard-qa-m30-puzzle":quit(2);return
    var s=Four.new();s.cloth=true;s.cover_hooked=true;s.phase="investigate";s.visit_room="exterior";s.positions[0]=s.PATCH
    s.request_hint();check(s.message.contains("补片") and not s.message.contains("暗槽"),"early exterior hints describe actual repair, not remote lab")
    s.positions[0]=s.TREE_ENTRY;s.request_hint()
    check(s.message.contains("藤") and not s.message.contains("暗槽"),"gate can be investigated before diagnosis")
    s.battle_requested=true;s.phase="battle_one";s.after_battle()
    check(s.objective().contains("已清开"),"gate-first objective acknowledges permanent route")
    s.positions[0]=s.PATCH;s.request_hint();check(s.message.contains("补片"),"gate-first hint stays at actual remaining exterior work")
    s.shell_fixed=true;s.latch_fixed=true;s.seam_seen=true;s.shell_examined=true;s.reconcile_progress();s.request_hint()
    check(s.message.contains("回流") or s.message.contains("留光"),"finished repair hint directs remaining causal comparison")
    print("M30_C4_HINTS: %d checks, %d failures"%[checks,failed]);quit(1 if failed else 0)
