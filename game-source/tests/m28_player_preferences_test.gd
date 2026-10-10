extends SceneTree
const Preferences=preload("res://ui/game_settings.gd")
const Journey=preload("res://game/story_journey.gd")
const Menu=preload("res://ui/journey_menu.gd")
var checks:=0
var failed:=0
func _init()->void:call_deferred("run")
func check(value:bool,label:String)->void:
    checks+=1
    if not value:failed+=1;printerr("FAIL: "+label)
func run()->void:
    check(OS.get_user_data_dir().get_file()=="DuoduoCatsCourtyard-qa-m28-root","actual QA namespace isolated before writes")
    if failed:quit(1);return
    var prefs=Preferences.new();prefs.path="user://m28-preferences-"+str(Time.get_ticks_usec())+".cfg"
    prefs.music_level=2;prefs.effects=false;prefs.camera_shake=false;prefs.rumble=true
    check(prefs.save(),"preferences atomic write")
    var restored=Preferences.new();restored.path=prefs.path;restored.read()
    check(restored.music_level==2 and not restored.effects and not restored.camera_shake and restored.rumble,"independent settings survive disk read")
    var malformed:=ConfigFile.new();malformed.set_value("audio","music",99);malformed.set_value("play","effects","false");malformed.save(prefs.path)
    var safe=Preferences.new();safe.path=prefs.path;safe.read()
    check(safe.music_level==1 and safe.effects,"malformed settings never coerce strings or invalid enum")
    var journey=Journey.new();journey.prefix="qa-m28-manifest-"+str(Time.get_ticks_usec())
    check(journey.save(true,"story-run-123-456",3,["prologue_ball","three_map"]),"actual discoveries stored with journey")
    var loaded:Dictionary=journey.read(true)
    check(loaded.get("discoveries")==["prologue_ball","three_map"] and journey.read(false).is_empty(),"discovery collection belongs to mode and run")
    check(not journey.save(true,"story-run-123-456",3,["three_map","three_map"]),"duplicate discovery rejected")
    check(not journey.save(true,"story-run-123-456",3,["unearned-secret"]),"unknown discovery rejected")
    check(journey.read(true)==loaded,"rejected manifests leave previous record intact")
    check(journey.valid({"version":1,"mode":"solo","run_id":"story-run-123-456","chapter":5},true),"old manifests without collection readable without fabricated finds")
    var parent:=Control.new();var theme:=Theme.new();theme.default_font=load("res://assets/fonts/CourtyardSans.ttf");parent.theme=theme;root.add_child(parent)
    var menu=Menu.new(restored);parent.add_child(menu);await process_frame;await process_frame
    menu.update_state(false,false,false,"",true)
    var visible=menu.available_buttons()
    check(visible.size()==5 and visible[0].text=="新旅程 · 一个人","fresh release menu starts at full journeys, no trial list")
    menu.update_state(true,true,false,"已暂停",true)
    check(menu.available_buttons()[0].text=="回到冒险" and menu.status.text=="已暂停","pause returns current live journey rather than replaying saves")
    menu.settings_panel.visible=true
    check(menu.available_buttons().size()==6 and menu.available_buttons()[0]==menu.music_button,"modal navigation confined to settings")
    menu.close_settings();check(not menu.settings_panel.visible,"settings return preserves adventure")
    menu.update_chapters({"solo":[0,1,2],"dual":[]});menu.chapters_panel.visible=true
    check(menu.available_buttons().size()==5 and menu.chapter_buttons[3].disabled,"chapter revisit only enables reached journey chapters")
    menu.visit_mode=false;menu._refresh_chapters();check(menu.available_buttons().size()==2,"revisit mode does not inherit the other player's progress")
    parent.queue_free();await process_frame
    print("M28_PLAYER_PREFERENCES: %d checks, %d failed"%[checks,failed]);quit(1 if failed else 0)
