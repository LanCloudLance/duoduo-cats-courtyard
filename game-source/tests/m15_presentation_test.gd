extends "res://tests/keyboard_scene_test.gd"
## Controlled UI fixtures; these do not claim a naturally earned completion.
func run() -> void:
    lobby = load("res://main.tscn").instantiate()
    root.add_child(lobby)
    await frames(2)
    lobby.session.set_focus(true)
    tap_key(KEY_ENTER)
    lobby.enter_light()
    var corridor = lobby.light_corridor
    var s = corridor.puzzle
    s.lit = true
    s.source = "near"
    s.operator_slot = 0
    s.positions[0] = s.Map.GUIDE_NEAR
    corridor._physics_process(0)
    check(corridor.actors[0].painted.social_sprite.visible and not corridor.actors[0].painted.sprite.visible,"operating pose replaces the walking image")
    var points: Array = s.positions.duplicate()
    corridor._update_art()
    check(s.positions == points,"updating artwork cannot move actors")
    var frozen: float = corridor.presentation_clock
    tap_key(KEY_ESCAPE)
    corridor._physics_process(1.0)
    check(corridor.presentation_clock == frozen,"pause freezes social animation time")
    lobby.get_node("RestPreview").pressed.emit()
    await frames(2)
    var rest = lobby.rest_area
    rest.state.positions[0] = Vector2(610,460)
    rest.state.positions[1] = Vector2(685,480)
    rest.state.positions[2] = Vector2(595,535)
    rest.state.interact(0)
    rest.state.interact(1)
    rest._physics_process(0)
    rest._physics_process(0)
    check(rest.actors[0].social_kind == "rest" and rest.actors[2].social_kind == "rest","rest uses seated girl and curled white cat")
    rest.state.pet_cooldown = 1.0
    rest.state.reaction_cat = 2
    rest._physics_process(0)
    check(rest.actors[0].social_kind == "pet" and rest.actors[2].social_kind == "pet" and rest.actors[1].social_kind != "pet","petting the white cat only activates the intended pair")
    rest.state.finished = true
    rest._refresh()
    check(rest.ending_card.visible and not rest.ending_body.text.contains("林间战斗  ✓"),"preview ending does not claim a complete journey")
    rest.state.progress = {"bridge":true,"combat":true,"light":true}
    rest._refresh()
    check(rest.ending_body.text.contains("林间战斗  ✓"),"full journey ending uses actual progress flags")
    tap_key(KEY_E)
    check(not lobby.session.running() and rest.state.finished,"ending interaction opens menu without erasing completion")
    lobby.free()
    print("M15_PRESENTATION: %d checks, %d failed" % [checks,failed])
    quit(1 if failed else 0)
