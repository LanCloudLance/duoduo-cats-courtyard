extends SceneTree
const State=preload("res://game/chapter_five_state.gd")
var checks:=0
var failed:=0
func check(value:bool,label:String)->void:
    checks+=1
    if not value:failed+=1;push_error(label)
func tick(s,seconds:float,enabled:=true)->void:
    for i in range(ceili(seconds/0.05)):s.step(0.05,Vector2.ZERO,Vector2.ZERO,enabled)
func at(s,role:int,p:Vector2)->void:
    s.positions[role]=p;s.action_time[role]=0
func stage(name:String):
    var s=State.new();s.phase=name;s.bridge_locked=true
    s.positions.assign([Vector2(590,565),Vector2(740,620),Vector2(575,620)])
    if name in ["lure","unjam","test"]:s.arm_locked=true;s.stage_checkpoint=1
    if name in ["unjam","test"]:s.lid_open=true;s.stage_checkpoint=2
    return s
func light(s,direction:Vector2)->void:
    at(s,2,s.AIM_STAND);s.facing[2]=direction;s.beam_held=false;s.actions[2]="";s.interact(2)
func wheel(s,count:=1)->void:
    for i in range(count):at(s,0,s.WHEEL);s.interact(0);tick(s,0.6)
func pull(s)->void:
    at(s,1,s.REPAIR_SLOT);s.interact(1);tick(s,0.6)
func _initialize()->void:
    # Catch hidden guard-age failure, invisible damage radius, and geometry drift.
    var s=stage("shield")
    at(s,0,s.SHIELD_SLOT);s.facing[0]=s.SHIELD_SLOT.direction_to(s.MACHINE)
    s.guard(0,true);tick(s,1.9)
    check(s.arm_arrest>0 and s.failed_sweeps==0,"held forward shield arrests visible arm without an unseen age cutoff")
    var held:float=s.arm_arrest;tick(s,2,false)
    check(s.arm_arrest==held,"paused shield cooperation window never expires")
    tick(s,6);check(not s.arm_locked and s.arm_arrest==0,"missed hook window safely reopens the same repair opportunity")
    s=stage("shield");at(s,0,s.SHIELD_SLOT+Vector2(-105,0));s.facing[0]=Vector2.LEFT;tick(s,1.9)
    check(s.failed_sweeps==0,"standing beyond the displayed warning circle never causes an invisible hit")
    s=stage("shield");at(s,0,s.SHIELD_SLOT);s.facing[0]=Vector2.LEFT;s.guard(0,true);tick(s,1.9)
    check(s.failed_sweeps==1 and s.arm_arrest==0 and s.walkable(s.positions[0],0),"backward shield produces a recoverable contact setback")
    check(s.has_method("arm_tip"),"rendered arm exposes the same contact trajectory used by the shield phase")
    if s.has_method("arm_tip"):
        s.boss_clock=1.8
        check(s.arm_tip().distance_to(Vector2(700,505))<0.01,"arm reaches the marked repair socket at the exact impact instant")
    s=stage("shield");at(s,0,Vector2(520,610));at(s,1,s.SHIELD_SLOT)
    var safe_girl:Vector2=s.positions[0];tick(s,1.9)
    check(s.positions[0]==safe_girl and s.positions[1].distance_to(s.SHIELD_SLOT)>62,"cat contact cannot move a girl outside the warning")
    s=stage("shield");at(s,2,s.SHIELD_SLOT);tick(s,1.9)
    check(s.failed_sweeps==1 and s.positions[2].distance_to(s.SHIELD_SLOT)>62,"white cat uses the same visible danger circle and safe recovery")
    # Catch old timer-only lid opening: one light choice cannot release both pins.
    s=stage("lure");light(s,Vector2.RIGHT);wheel(s);tick(s,12)
    check(not s.lid_open and s.phase=="lure","one configured beam and wheel cannot automatically complete the lid stage")
    light(s,Vector2.UP);wheel(s)
    check(s.lid_open and s.phase=="unjam" and s.stage_checkpoint==2,"changing the light route and operating the second pin actively opens the lid")
    s=stage("lure");light(s,Vector2.UP);wheel(s);tick(s,4)
    check(not s.lid_open,"wrong buffer route cannot silently turn into the right repair")
    light(s,Vector2.RIGHT);wheel(s,2);light(s,Vector2.UP);wheel(s)
    check(s.lid_open and s.arm_locked,"incorrect route can be corrected without losing the stopped arm")
    # Catch autonomous ratcheting: every branch bend needs a new player pull.
    s=stage("unjam");s.fixed_light=true
    at(s,0,s.WHEEL);s.interact(0);at(s,1,s.REPAIR_SLOT);s.interact(1);tick(s,12)
    check(s.cleared_segments==1 and not s.machine_stopped,"one unloading choice and one hook stroke extract only one branch segment")
    var count:int=s.cleared_segments;pull(s)
    check(s.cleared_segments==count,"repeating a pull under the old load direction cannot extract the next bend")
    wheel(s,2);pull(s)
    check(s.cleared_segments==2 and not s.machine_stopped,"reversed middle bend requires a different unloading path")
    wheel(s,2);pull(s)
    check(s.cleared_segments==3 and s.machine_stopped and s.phase=="withdraw","all three deliberate unloading and hook strokes stop the machine")
    at(s,2,s.CRADLE);s.interact(2)
    check(s.fixed_light and s.phase=="withdraw","cat inside the mechanism prevents releasing its safety light")
    at(s,1,Vector2(875,610));at(s,2,s.CRADLE);s.interact(2)
    check(not s.fixed_light and s.phase=="test","cat safely withdraws before shared safety light is released")
    s=stage("unjam");s.fixed_light=true;wheel(s,2);pull(s)
    check(s.cleared_segments==0 and s.lid_open,"wrong load direction springs back while permanent lid progress remains")
    s=stage("unjam");at(s,2,s.CRADLE);s.interact(2);tick(s,0.6)
    s.tool(2)
    check(not s.fixed_light,"safe idle cradle releases through the same tool interaction before finishing repair")
    tick(s,0.6);s.interact(2);at(s,1,s.REPAIR_SLOT);tick(s,0.6);s.tool(2)
    check(s.fixed_light and s.walkable(s.positions[1],1),"tool cannot remove the light from a cat still in the slot")
    s=stage("lure");var hints:int=s.hints;s.tool(0);s.tool(1);at(s,2,Vector2(600,640));s.tool(2)
    check(s.hints==hints and not s.lid_open,"tool away from a valid object never leaks puzzle hints or operates a distant mechanism")
    # Correct light is evidence, not an automatic story-advance countdown.
    s=stage("test");s.machine_stopped=true
    at(s,0,s.TEST_PLATE);s.facing[0]=Vector2.RIGHT;s.interact(0)
    at(s,2,s.TEST_SOURCE);s.facing[2]=Vector2.RIGHT;s.interact(2);tick(s,10)
    check(s.outward_light and not s.tested and s.phase=="test","an outward beam remains inspectable until the player confirms the result")
    at(s,0,s.TEST_END);s.interact(0)
    check(s.tested and s.phase=="release","observing the lit far receiver confirms the successful test without waiting")
    s=stage("test");s.machine_stopped=true
    at(s,0,s.TEST_PLATE);s.facing[0]=Vector2.RIGHT;s.interact(0)
    at(s,2,s.TEST_SOURCE);s.facing[2]=Vector2.RIGHT;s.interact(2);tick(s,1)
    s.tool(2);at(s,0,s.TEST_END);s.interact(0)
    check(not s.tested,"same-frame light cancellation cannot confirm stale outward evidence")
    s=stage("shield");at(s,0,s.WHEEL);s.interact(0)
    check(not s.message.is_empty() and s.target(0)!="","visible later-stage wheel still explains why it is blocked")
    s=State.new();s.restore_complete()
    check(s.lid_pins==2 and s.cleared_segments==3,"completed save restores permanent repair facts consistently")
    print("M27_FIVE_STATE: %d checks, %d failed"%[checks,failed])
    quit(1 if failed else 0)
