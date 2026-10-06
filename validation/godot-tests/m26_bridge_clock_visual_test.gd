extends SceneTree
## Frozen, explicitly labelled visual fixtures. These are NOT gameplay/input evidence.
var lobby
var fixture_label:Label
var capture_dir:String
var manifest:Array[String]=[]
func frames(n:int)->void:
    for i in range(n):await physics_frame;await process_frame
func _initialize()->void:call_deferred("run")
func capture(name:String,inspection:String)->void:
    lobby.session.set_focus(true);lobby.router.start_keyboard();lobby._process(.016)
    fixture_label.text="视觉固定样本 · "+inspection
    lobby.story_chapter.state.message_time=0
    lobby.story_chapter._refresh(0)
    await frames(3);await RenderingServer.frame_post_draw
    var path:=capture_dir+"/m26-"+name+".png"
    var error:=root.get_texture().get_image().save_png(path)
    manifest.append(name+": "+inspection+" | save="+str(error))
    print("M26_VISUAL_FIXTURE ",path," status=",error," | ",inspection)
func chapter(number:int)->void:
    lobby.session.pause_all();lobby.start_story_chapter(number,true)
    lobby.story_chapter.set_physics_process(false)
    lobby.story_chapter.state.clock=1.4
    await frames(2)
func run()->void:
    var args:=OS.get_cmdline_user_args()
    if args.is_empty():push_error("Pass an existing output folder after --");quit(2);return
    capture_dir=args[0]
    lobby=load("res://main.tscn").instantiate();root.add_child(lobby)
    await frames(3)
    if not is_instance_valid(lobby.story_chapter):push_error("Story view failed to initialize; aborting fixture");quit(2);return
    lobby.session.set_focus(true);lobby.router.start_keyboard();lobby.set_process(false)
    lobby.story_chapter.record_prefix="qa-m26-visual-"+str(Time.get_ticks_usec())
    var overlay:=CanvasLayer.new();overlay.layer=30;root.add_child(overlay)
    fixture_label=Label.new();fixture_label.position=Vector2(26,83);fixture_label.size=Vector2(1220,28)
    fixture_label.add_theme_font_override("font",lobby.theme.default_font)
    fixture_label.add_theme_font_size_override("font_size",16)
    fixture_label.add_theme_color_override("font_color",Color("fff4cf"))
    fixture_label.add_theme_color_override("font_outline_color",Color("364c46"))
    fixture_label.add_theme_constant_override("outline_size",5);overlay.add_child(fixture_label)
    await chapter(2)
    var s=lobby.story_chapter.state
    await capture("bridge-unloaded","初始桥叶未锁定；河岸与下层检修道边界")
    s.lamp_a=1;s.lifted_a=true;s.positions[0]=s.WINCH_A;s.positions[1]=Vector2(485,555)
    await capture("bridge-raised","第一绞盘抬桥；右向灯光接铜片；团团处于可走检修道")
    s.locked_a=true;s.lifted_b=true;s.lamp_b=2;s.positions[0]=s.LAMP_B;s.positions[1]=s.LATCH_B
    await capture("bridge-second-latch","前桥永久固定；第二灯朝下；后桥仍抬起卸重")
    s.restore_complete();s.finished=false
    await capture("bridge-window","双桥与短桥固定；检修箱、练习车、栏窗中的圆圆")
    await chapter(3);s=lobby.story_chapter.state
    await capture("clock-closed","关闭门洞、外墙检修槽、低窗与室内圆圆")
    s.wick_found=true;s.positions[1]=Vector2(369,462)
    await capture("clock-wick-carried","灯芯随团团携带；外部灯座仍未装好")
    s.wick_ready=true;s.wick_fitted=true;s.door_angle=1;s.npc_called=true;s.npc_elapsed=.9
    s.positions[2]=Vector2(535,355)
    await capture("clock-npc-walk","灯已照准门锁；圆圆正在走向室内踏板；门尚未打开")
    s.door_open=true;s.positions[0]=Vector2(504,435);s.positions[1]=Vector2(510,474);s.positions[2]=s.INDOOR_PLATE
    await capture("clock-reunion-aperture","真实门洞开启；三位能够在门内重逢")
    s.joined=true;s.light_equipped=true;s.beam_held=true;s.beam_direction=Vector2.RIGHT
    s.positions[2]=s.LIGHT_STAND;s.actions[2]="light";s.positions[1]=s.LOCK
    await capture("clock-temporary-walkway","圆圆向右保持；暗廊临时可走；卡扣尚未锁定")
    s.cat_lock=true;s.board_angle=1;s.bridge_locked=true;s.beam_held=false;s.actions[2]="";s.light_released=true
    s.narrow_open=true;s.rig_ready=true;s.exit_revealed=true
    s.positions[0]=Vector2(1090,470);s.positions[1]=Vector2(1190,435);s.positions[2]=Vector2(1050,560)
    await capture("clock-map","永久桥、低检修门和上方出口均开启；真实地图汇入灯树")
    var file:=FileAccess.open(capture_dir+"/m26-bridge-clock-fixtures.txt",FileAccess.WRITE)
    if file:file.store_string("Frozen visual fixtures only; no continuous-input claim.\n"+"\n".join(manifest))
    lobby.queue_free();overlay.queue_free();await frames(2);quit()
