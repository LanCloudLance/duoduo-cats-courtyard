extends SceneTree
const Five=preload("res://game/chapter_five_state.gd")
const Checkpoint=preload("res://game/story_checkpoint.gd")
var checks:=0
var failed:=0
func check(value:bool,label:String)->void:
    checks+=1
    if not value:failed+=1;push_error(label)
func hints_for(s)->void:
    var before:Dictionary=Checkpoint.capture(s)
    s.request_hint();var observation:String=s.message
    check(not observation.contains("圆圆") and not observation.contains("朵朵") and not observation.contains("团团"),"first tier observes the current problem without assigning the full role chain")
    s.request_hint();var rule:String=s.message
    s.request_hint();var method:String=s.message
    check(observation!=rule and rule!=method,"three requests reveal observation, rule and local method separately")
    s.request_hint();check(s.message==method,"further requests retain a useful final tier")
    var after:Dictionary=Checkpoint.capture(s)
    check(after.facts==before.facts and after.phase==before.phase and after.positions==before.positions,"asking for help never operates a puzzle or changes permanent progress")
func _initialize()->void:
    var s=Five.new();hints_for(s)
    s.positions[1]=s.LOW_LOCK;s.interact(1);s.request_hint()
    check(s.message.contains("提示 1 / 3") and not s.message.contains("爪钩"),"real low-latch progress resets to observing the newly exposed support")
    s=Five.new();s.phase="lure";s.lid_pins=1;hints_for(s)
    check(s.message.contains("上") and not s.message.contains("下销先"),"remaining-pin final hint solves only the current upper route")
    s=Five.new();s.phase="unjam";s.fixed_light=true;s.cleared_segments=1;s.wheel_notch=1;hints_for(s)
    check(s.message.contains("左") and s.message.contains("两次"),"middle-bend method explains the actual remaining wheel choices")
    s=Five.new();s.phase="test";s.plate_aligned=true;s.beam_held=true;s.positions[2]=s.TEST_SOURCE;s.facing[2]=Vector2.RIGHT;s.actions[2]="light";hints_for(s)
    check(s.message.contains("远灯") and s.message.contains("互动") and not s.message.contains("三秒"),"last test hint requests manual far-receiver observation")
    s=Five.new();s.phase="home";s.gear_stored=true;s.paws_clean=true;hints_for(s)
    check(s.message.contains("沙发") and not s.message.contains("装备架"),"home final hint focuses on voluntary ending after chores are done")
    for phase_name in ["shield","withdraw","release","network","farewell","complete"]:
        s=Five.new();s.phase=phase_name;hints_for(s)
    s=Five.new();s.phase="lure";s.positions[2]=s.AIM_STAND;s.facing[2]=Vector2.RIGHT;s.interact(2)
    s.request_hint();s.request_hint();s.request_hint()
    s.positions[0]=s.WHEEL;s.interact(0);s.request_hint()
    check(s.lid_pins==1 and s.hint_level==1 and s.message.contains("上销"),"real first pin resets the hint level for the other pin")
    s=Five.new();s.phase="lure";s.lid_pins=1;s.positions[2]=s.AIM_STAND;s.beam_held=true;s.beam_route=2;s.actions[2]="light"
    s.request_hint();s.request_hint();s.request_hint()
    check(s.message.contains("维护轮") and not s.message.contains("重新接光"),"already-correct buffer final hint never tells player to toggle that beam off")
    print("M27_FIVE_HINT: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
