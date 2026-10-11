extends SceneTree
const Five=preload("res://game/chapter_five_state.gd")
const M30=preload("res://game/puzzle_m30_checkpoint.gd")
var checks:=0
var failed:=0
func check(ok:bool,label:String)->void:
    checks+=1
    if not ok:failed+=1;print("FAIL ",label)
func reject(s,record:Dictionary,label:String)->void:
    var before:Dictionary=s.checkpoint()
    check(not s.restore_checkpoint(record) and s.checkpoint()==before,label)
func _init()->void:
    if OS.get_user_data_dir().get_file()!="DuoduoCatsCourtyard-qa-m31-puzzle":quit(2);return
    # Declared durable stage fixtures. Ordinary paths remain a separate suite.
    for solo in [true,false]:
        for plan in ["left","right","held","restored"]:
            for phase in ["withdraw","test","release","network","farewell","home","complete"]:
                var source=Five.new();source.single=solo;source.restore_complete()
                source.phase=phase;source.finished=phase=="complete"
                source.extraction_side=plan if plan in ["left","right"] else "right" if plan=="held" else "restored"
                source.extraction_method="support" if plan in ["left","right"] else "held" if plan=="held" else "restored"
                source.support_site=plan if plan in ["left","right"] else "rack"
                source.isolation_open=true
                source.tested=phase not in ["withdraw","test"]
                source.pilot_open=source.tested;source.plate_aligned=source.tested;source.pilot_charged=source.tested
                source.charged_route="tower" if source.tested else "none"
                source.network_lit=phase in ["network","farewell","home","complete"]
                source.tag_inserted=phase in ["home","complete"]
                source.gear_stored=source.finished;source.paws_clean=source.finished
                source.cat_one_clean=source.finished;source.cat_two_clean=source.finished
                var record:Dictionary=source.checkpoint()
                var live=Five.new();live.single=solo
                check(live.restore_checkpoint(record),"legal method and permanent stage "+plan+phase)
                var missing:Dictionary=record.duplicate(true);missing.facts.erase("extraction_method")
                reject(live,missing,"current schema needs exact extraction method "+plan+phase)
                for poison in [[],true,42,"imagined"]:
                    var bad:Dictionary=record.duplicate(true);bad.facts.extraction_method=poison
                    reject(live,bad,"invalid method rejects without mutation "+plan+phase)
                var wrong:Dictionary=record.duplicate(true);wrong.facts.extraction_method="none"
                reject(live,wrong,"stopped mechanism cannot claim no extraction "+plan+phase)
                if plan in ["left","right"]:
                    for impossible in ["right" if plan=="left" else "left","rack","carried"]:
                        var bad:Dictionary=record.duplicate(true);bad.facts.support_site=impossible
                        reject(live,bad,"stable extraction keeps exact pin provenance "+plan+phase)
                elif plan=="held":
                    for impossible in ["left","right","carried"]:
                        var bad:Dictionary=record.duplicate(true);bad.facts.support_site=impossible
                        reject(live,bad,"manual plan cannot invent moved support "+phase)
                    wrong=record.duplicate(true);wrong.facts.extraction_side="left"
                    reject(live,wrong,"manual plan cannot invent left route "+phase)
                    wrong=record.duplicate(true);wrong.facts.isolation_open=false
                    reject(live,wrong,"manual plan needs actual isolated worklight source "+phase)
                wrong=record.duplicate(true);wrong.facts.extraction_method="restored";wrong.facts.extraction_side="restored";wrong.facts.support_site="rack"
                check(live.restore_checkpoint(wrong),"historical unknown provenance stays explicitly restored "+phase)
                if plan!="held":
                    var old:Dictionary=M30.capture(source)
                    check(old.puzzle_revision==2 and live.restore_checkpoint(old),"frozen M30 record stays readable "+plan+phase)
                    check(live.extraction_method==("restored" if plan=="restored" else "support"),"migration never grants manual shortcut provenance "+plan+phase)
                    old.facts.extraction_method="held"
                    reject(live,old,"old schema extra manual fact strictly rejects "+plan+phase)
    print("M31_C5_SIDE_SAVE: %d checks, %d failures"%[checks,failed]);quit(1 if failed else 0)
