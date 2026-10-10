extends SceneTree
const Arena=preload("res://game/arena.gd")
const Session=preload("res://input/session_state.gd")
const Labels=preload("res://game/story_labels.gd")
var checks:=0
var failed:=0
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:failed+=1;print("FAIL ",label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
    print("QA_USER_DIR ",OS.get_user_data_dir())
    if not OS.get_user_data_dir().ends_with("DuoduoCatsCourtyard-qa-m28-combat"):quit(2);return
    var s=Session.new();s.keyboard_mode=true;s.ready_flags.assign([true,true])
    var host=Control.new();host.theme=Theme.new();host.theme.default_font=ThemeDB.fallback_font;root.add_child(host)
    var arena=Arena.new(s);host.add_child(arena);arena.set_physics_process(false)
    for id in ["first","shell","reserve","practice"]:
        for solo in [true,false]:
            s.single_player=solo
            for selected in ([0,1] if id=="first" else [0,1,2]):
                arena.configure({"id":id,"mode":"solo" if solo else "dual","selected_role_id":selected,"current_cat":1 if selected==0 else selected,"available_role_ids":[0,1] if id=="first" else [0,1,2]})
                arena._sync_actors(0);arena._refresh()
                for slot in arena.battle.deployed_slots():check(arena.battle.positions[arena.battle.actor(slot)]==arena.battle.Space.STARTS[slot],"deployed start unchanged "+id)
                for role in arena.battle.roster.reserves():
                    var actor=arena.actors[role]
                    var body: Rect2=Labels.world_rect(actor,actor.body_rect())
                    var caption: Rect2=Labels.world_rect(actor,actor.caption_rect())
                    var projected:=Rect2((body.position-arena.camera.position)*arena.camera.zoom+Vector2(640,400),body.size*arena.camera.zoom)
                    var projected_caption:=Rect2((caption.position-arena.camera.position)*arena.camera.zoom+Vector2(640,400),caption.size*arena.camera.zoom)
                    check(not body.intersects(arena.battle.FIELD) and not caption.intersects(arena.battle.FIELD),"reserve body/caption outside combat geometry "+id)
                    check(projected.position.x>=8 and projected.position.y>=128 and projected.end.x<=1258 and projected.end.y<=700,"full reserve silhouette clear of HUD "+id)
                    check(projected_caption.position.x>=8 and projected_caption.position.y>=128 and projected_caption.end.y<=700,"reserve label clear of HUD "+id)
    print("M28_COMBAT_RESERVE_LAYOUT: ",checks," checks, ",failed," failed")
    quit(1 if failed else 0)
