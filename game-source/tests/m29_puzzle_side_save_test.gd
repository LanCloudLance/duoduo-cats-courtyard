extends SceneTree
# State fixtures model all legal post-extraction stages; ordinary InputEvent
# completion remains covered separately by m29_mainline_playthrough_test.
const Five=preload("res://game/chapter_five_state.gd")
var checks:=0
var failed:=0
func check(ok:bool,label:String)->void:
    checks+=1
    if not ok:failed+=1;print("FAIL ",label)
func _init()->void:
    if OS.get_user_data_dir().get_file()!="DuoduoCatsCourtyard-qa-m29-puzzle":quit(2);return
    for solo in [true,false]:
        for side in ["left","right"]:
            for phase in ["withdraw","test","release","network","farewell","home","complete"]:
                var source=Five.new();source.single=solo;source.restore_complete()
                # Explicit, dependency-valid current-schema fixture: remove later facts.
                # M31 distinguishes support extraction from historical restored provenance.
                source.phase=phase;source.finished=phase=="complete"
                source.extraction_side=side;source.support_site=side;source.extraction_method="support"
                source.tested=phase not in ["withdraw","test"]
                source.pilot_open=source.tested;source.plate_aligned=source.tested;source.pilot_charged=source.tested
                source.charged_route="tower" if source.tested else "none"
                source.network_lit=phase in ["network","farewell","home","complete"]
                source.tag_inserted=phase in ["home","complete"]
                source.gear_stored=source.finished;source.paws_clean=source.finished
                source.cat_one_clean=source.finished;source.cat_two_clean=source.finished
                var record:Dictionary=source.checkpoint()
                var live=Five.new();live.single=solo
                check(live.restore_checkpoint(record),"matching support remains legal "+phase+" "+side)
                var before:Dictionary=live.checkpoint()
                for impossible in ["right" if side=="left" else "left","rack","carried"]:
                    var bad:Dictionary=record.duplicate(true);bad.facts.support_site=impossible
                    check(not live.restore_checkpoint(bad) and live.checkpoint()==before,"reject impossible extracted support without mutation "+phase+" "+side+" "+impossible)
                # Historical migration does not invent which entrance was used.
                var restored:Dictionary=record.duplicate(true)
                restored.facts.extraction_side="restored";restored.facts.support_site="rack";restored.facts.extraction_method="restored"
                check(live.restore_checkpoint(restored),"historical restored exception remains legal "+phase)
    print("M29_PUZZLE_SIDE_SAVE: %d checks, %d failures"%[checks,failed]);quit(1 if failed else 0)
