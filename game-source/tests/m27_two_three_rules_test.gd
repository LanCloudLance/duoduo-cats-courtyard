extends SceneTree
const Two=preload("res://game/chapter_two_state.gd")
const Three=preload("res://game/chapter_three_state.gd")
var checks:=0
var failed:=0
func check(ok:bool,label:String)->void:
    checks+=1
    if not ok:failed+=1;print("FAIL: ",label)
func use(s,role:int,p:Vector2,tool:=false)->void:
    s.positions[role]=p;s.action_time[role]=0
    if tool:s.tool(role)
    else:s.interact(role)
func tick(s,n:=30)->void:
    for i in range(n):s.step(0.05,Vector2.ZERO,Vector2.ZERO,true)
func lit_three():
    var s=Three.new();s.door_open=true;s.joined=true;s.light_equipped=true;s.phase="walkway"
    s.positions[2]=s.LIGHT_STAND;s.facing[2]=Vector2.RIGHT;s.interact(2)
    return s
func _initialize()->void:
    var t=Two.new();t.locked_a=true
    use(t,0,t.WINCH_B)
    check(not t.lifted_b,"second winch cannot lift without reusing the unique support")
    check(t.get("support_site")!=null,"one physical support tracks its current site")
    if t.get("support_site")!=null:
        use(t,0,t.WINCH_A,true)
        check(t.support_site=="carried" and t.locked_a,"permanent first lock unloads reusable support")
        t.positions[0]=t.WINCH_B;use(t,1,t.WINCH_B);use(t,1,t.WINCH_B);use(t,0,t.WINCH_B)
        check(t.support_site=="b" and t.lifted_b,"same support enables second winch")
        use(t,0,t.WINCH_B,true)
        check(t.support_site=="b","bridge weight prevents pulling a loaded support")
        use(t,0,t.LAMP_B);use(t,0,t.LAMP_B);use(t,0,t.BRACE_B);use(t,1,t.WINCH_B);use(t,1,t.LATCH_B)
        check(t.locked_b,"light plus reused support permanently locks second bridge")
        use(t,0,t.WINCH_B,true)
        check(t.support_site=="far" and t.walkable(Vector2(700,420),0),"permanent far prop remains unique and bridge stays fixed after revisiting winch")
        var fresh=Two.new();use(fresh,0,fresh.WINCH_A)
        use(fresh,0,fresh.WINCH_A,true)
        check(fresh.support_site=="a","initial bridge load blocks premature recovery")
    var s=lit_three();use(s,0,s.BOARD);use(s,1,s.LOCK)
    check(s.cat_lock and not s.bridge_locked,"direct right-facing light cannot also power high receiver")
    check(s.has_method("reflected_lock_lit"),"separate direct and reflected optical routes")
    if s.has_method("reflected_lock_lit"):
        use(s,2,s.LIGHT_STAND,true);s.facing[2]=Vector2.UP;use(s,2,s.LIGHT_STAND)
        check(s.bridge_locked and s.reflected_lock_lit(),"same lamp redirected upward through right-facing board locks bridge")
        use(s,2,s.LIGHT_STAND,true)
        check(s.light_released and not s.beam_held and s.bridge_locked,"explicit tool release preserves repaired bridge")
        var wrong=lit_three();use(wrong,1,wrong.LOCK);use(wrong,2,wrong.LIGHT_STAND,true)
        wrong.facing[2]=Vector2.UP;use(wrong,2,wrong.LIGHT_STAND);tick(wrong)
        check(not wrong.bridge_locked and wrong.positions[1].x<700,"wrong mirror has an actual miss and safely returns cat")
        use(wrong,0,wrong.BOARD)
        check(wrong.bridge_locked,"correcting the visible mirror miss locks retained mechanism")
        var search=lit_three();search.bridge_locked=true;search.light_released=true;search.narrow_open=true;search.beam_held=false;search.actions[2]=""
        use(search,0,search.RIG);search.facing[2]=Vector2.UP;use(search,2,search.SEARCH_STAND)
        check(not search.exit_revealed,"aiming up alone cannot skip exit mirror choice")
        use(search,2,search.SEARCH_STAND,true);search.facing[2]=Vector2.RIGHT;use(search,2,search.SEARCH_STAND)
        use(search,0,search.SEARCH_STAND);use(search,2,search.SEARCH_STAND)
        use(search,0,search.RIG);use(search,1,search.HIGH_RING)
        check(search.exit_revealed and search.exit_low_latched and search.exit_high_latched,"two height layouts reflect into both physical receiver fronts")
        use(search,2,search.SEARCH_STAND,true)
        check(search.exit_revealed and not search.beam_held,"permanent exit survives canceling search light")
    var hints=Three.new();var old_hints:int=hints.hints;hints.tool(0)
    check(hints.hints==old_hints,"tool without target never spends a hint")
    for i in range(4):hints.request_hint()
    check(hints.message.contains("3 / 3"),"requested guidance caps at third level")
    check(not Three.new().objective().contains("检修槽找回灯芯"),"constant objective describes problem rather than action sequence")
    var pause=lit_three();pause.positions[1]=Vector2(755,425)
    var before=pause.positions.duplicate();var before_clock:float=pause.clock
    pause.step(0.05,Vector2.RIGHT,Vector2.RIGHT,false)
    check(pause.positions==before and pause.clock==before_clock and pause.beam_held,"pause freezes direct-light crossing and actors")
    pause.controlled=2;pause.step(0.05,Vector2.LEFT,Vector2.ZERO,true)
    check(not pause.beam_held and pause.positions[1].x<700,"movement withdraws source and safely recovers traveler")
    var contact=Three.new();contact.door_open=true;contact.positions[0]=contact.REUNION;contact.positions[1]=contact.REUNION+Vector2(25,15)
    contact.interact(0)
    check(contact.joined and contact.actions[0]=="pet" and contact.actions[2]=="pet" and contact.actions[1]=="paw","reunion triggers girl and distinct cat body responses together")
    check(contact.positions[0].distance_to(contact.positions[2])<40,"reunion response happens within actual hand reach")
    print("M27_TWO_THREE_RULES: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
