extends Node
# Real renderer cadence; no fixed-fps or time scaling allowed for this meter.
var frame_ms:Array[float]=[]
var physics_ms:Array[float]=[]
var process_ms:Array[float]=[]
var physics_dt_ms:Array[float]=[]
var process_dt_ms:Array[float]=[]
var first:=0
var last:=0
func _ready()->void:
    first=Time.get_ticks_usec();last=first
    RenderingServer.frame_post_draw.connect(rendered)
func rendered()->void:
    var now:=Time.get_ticks_usec();frame_ms.append((now-last)/1000.0);last=now
    physics_ms.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000)
    process_ms.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
func _physics_process(delta:float)->void:physics_dt_ms.append(delta*1000)
func _process(delta:float)->void:process_dt_ms.append(delta*1000)
func describe(values:Array[float])->Dictionary:
    if values.is_empty():return {}
    var ordered:=values.duplicate();ordered.sort()
    return {"count":values.size(),"median_ms":ordered[ordered.size()/2],"p95_ms":ordered[int(ordered.size()*0.95)],"p99_ms":ordered[int(ordered.size()*0.99)],"max_ms":ordered.back(),"over_25ms":values.filter(func(v):return v>25).size(),"over_33ms":values.filter(func(v):return v>33.333).size(),"over_50ms":values.filter(func(v):return v>50).size()}
func report()->Dictionary:
    return {"seconds":(Time.get_ticks_usec()-first)/1000000.0,"render_interval":describe(frame_ms),"physics_cost":describe(physics_ms),"process_cost":describe(process_ms),"physics_delta":describe(physics_dt_ms),"process_delta":describe(process_dt_ms),"raw_render_ms":frame_ms,"raw_physics_ms":physics_ms,"raw_process_ms":process_ms}
