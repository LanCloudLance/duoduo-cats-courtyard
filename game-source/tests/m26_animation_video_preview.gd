extends SceneTree
const Actor = preload("res://game/actor_view.gd")
const Home = preload("res://game/home_sprite.gd")
var adventure: Array = []
var homes: Array = []
var elapsed := 0.0
var ready_to_record := false
var normal_speed := "--normal-speed" in OS.get_cmdline_user_args()
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var background := ColorRect.new()
    background.color = Color("6c8678")
    background.size = Vector2(1600,1000)
    root.add_child(background)
    for role in range(3):
        var actor := Actor.new()
        actor.role = role
        actor.storybook = true
        root.add_child(actor)
        adventure.append(actor)
        actor.update_pose(Vector2(180,230+role*210),false,false,0)
        var home := Home.new()
        home.role = role
        root.add_child(home)
        home.update_motion(Vector2(790,230+role*210),0)
        homes.append(home)
    ready_to_record = true
func _process(_delta: float) -> bool:
    if not ready_to_record: return false
    var delta := 1.0 / 60.0
    elapsed += delta
    var offset := Vector2.ZERO
    if elapsed < 2: offset = Vector2(elapsed*100,0)
    elif elapsed < 3: offset = Vector2(200,-(elapsed-2)*70)
    elif elapsed < 3.5: offset = Vector2(200,-70)
    elif elapsed < 5.5: offset = Vector2(200-(elapsed-3.5)*100,-70)
    else: offset = Vector2(0,-70)
    if normal_speed:
        if elapsed < 1: offset = Vector2(elapsed*200,0)
        elif elapsed < 2: offset = Vector2(200,-(elapsed-1)*70)
        elif elapsed < 2.5: offset = Vector2(200,-70)
        elif elapsed < 3.5: offset = Vector2(200-(elapsed-2.5)*200,-70)
        elif elapsed < 4.5: offset = Vector2(0,-70+(elapsed-3.5)*70)
        elif elapsed < 5: offset = Vector2.ZERO
        else: offset = Vector2((elapsed-5)*200,0)
    for role in range(3):
        adventure[role].update_pose(Vector2(180,230+role*210)+offset,false,false,delta)
        homes[role].update_motion(Vector2(790,230+role*210)+offset,delta)
        homes[role].show_action("",elapsed,homes[role].walk_facing)
    if elapsed >= 6: quit()
    return false
