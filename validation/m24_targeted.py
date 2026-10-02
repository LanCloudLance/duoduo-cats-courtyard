from pathlib import Path
import subprocess,re,json
from concurrent.futures import ThreadPoolExecutor
base=Path('/Users/wangyuanlong/Documents/Codex/2026-09-05/ya')
names=['m24_chapter_state_test','m24_chapter_test','m24_playthrough_test','journey_modes_test','prologue_scene_test','prologue_gamepad_test','m21_music_scene_test']
def run(name):
 r=subprocess.run([str(base/'work/runtime/Godot.app/Contents/MacOS/Godot'),'--headless','--path',str(base/'outputs/duoduo-game'),'--script','res://tests/'+name+'.gd'],capture_output=True,text=True,timeout=300)
 out=r.stdout+r.stderr;(base/'work/logs'/('m24-final-'+name+'.log')).write_text(out)
 m=re.search(r': (\d+) checks, (\d+) failed',out)
 errors=[x for x in out.splitlines() if ('ERROR' in x or 'FAIL:' in x) and 'Error loading system CA certificates' not in x]
 result={'suite':name,'passed':r.returncode==0 and m is not None and m[2]=='0' and not errors,'checks':int(m[1]) if m else 0,'details':errors}
 print(json.dumps(result,ensure_ascii=False),flush=True);return result
with ThreadPoolExecutor(max_workers=4) as pool:results=list(pool.map(run,names))
(base/'work/qa/m24-final-targeted.json').write_text(json.dumps(results,ensure_ascii=False,indent=2))
raise SystemExit(0 if all(r['passed'] for r in results) else 1)
