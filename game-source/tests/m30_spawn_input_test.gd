extends SceneTree
const Arena=preload("res://game/arena.gd")
const Session=preload("res://input/session_state.gd")
const Router=preload("res://input/event_router.gd")
const Keys=preload("res://tests/m30_keyboard_combat_test.gd")
var checks:=0
var failed:=0
func check(value:bool,label:String)->void:
    checks+=1
    if not value:failed+=1;print("FAIL ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
    if OS.get_user_data_dir().get_file()!="DuoduoCatsCourtyard-qa-m30-combat":quit(2);return
    var s=Session.new();s.single_player=false;s.keyboard_mode=true;s.ready_flags.assign([true,true]);var router=Router.new(s)
    var host=Control.new();host.theme=Theme.new();host.theme.default_font=ThemeDB.fallback_font;root.add_child(host)
    var arena=Arena.new(s);host.add_child(arena);arena.set_physics_process(false)
    var pilot=Keys.KeyboardPilot.new();pilot.router=router;pilot.arena=arena;root.add_child(pilot)
    router.action_pressed.connect(arena.handle_action);router.action_released.connect(arena.release_action);router.actions_cancelled.connect(arena.cancel_inputs)
    for p in [Vector2(880,555),Vector2(900,550),Vector2(860,560)]:
        for q in [Vector2(790,300),Vector2(770,330),Vector2(800,310)]:
            pilot.reset();router.clear_keyboard();arena.configure({"id":"shell","encounter_revision":2,"mode":"dual","available_role_ids":[0,1,2],"selected_role_id":0,"current_cat":1});arena.set_active(true)
            var b=arena.battle;var goals=[p,q];var ticks:=0
            for i in range(1800):
                ticks+=1
                var near_all:=true
                for slot in [0,1]:
                    var point:Vector2=b.positions[b.actor(slot)]
                    var reached:bool=point.distance_to(goals[slot])<7
                    near_all=near_all and reached
                    pilot.axis(slot,Vector2.ZERO if reached else b.Space.direction(point,goals[slot],18))
                b.step(1.0/60,s.movement(0),s.movement(1),true)
                if near_all:break
            check(b.phase=="briefing" and b.positions[0].distance_to(p)<7 and b.positions[1].distance_to(q)<7,"ordinary preparation movements reach adversarial positions")
            pilot.axis(0,Vector2.ZERO);pilot.axis(1,Vector2.ZERO);pilot.tap(0,JOY_BUTTON_A);pilot.tap(1,JOY_BUTTON_A)
            var source=b.enemies.filter(func(e):return e.kind=="weaver")[0]
            check(source.pos.x<b.Space.GATE.x-b.Space.ROUTE_RADIUS-b.Space.ENEMY_RADIUS,"actual protected source stays in accessible side")
            print("SPAWN_INPUT p=",p," q=",q," actual=",b.positions," source=",source.pos," preparation_ticks=",ticks)
            for i in range(7200):
                pilot.frame()
                if b.phase=="complete" or b.retries>2:break
            check(b.phase=="complete","relocated source remains beatable by actual inputs")
    print("M30_SPAWN_INPUT: ",checks," checks, ",failed," failed");quit(1 if failed else 0)
