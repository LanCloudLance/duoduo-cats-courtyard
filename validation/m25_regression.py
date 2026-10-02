from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
import json, subprocess, re

base = Path(__file__).resolve().parents[2]
engine = base/'work/runtime/Godot.app/Contents/MacOS/Godot'
names = sorted(p.stem for p in (base/'outputs/duoduo-game/tests').glob('*_test.gd') if '_render_' not in p.stem)
def run(name):
    log = base/'work/logs'/('m25-'+name+'.log')
    try:
        result = subprocess.run([str(engine),'--headless','--path',str(base/'outputs/duoduo-game'),'--script','res://tests/'+name+'.gd'],capture_output=True,text=True,timeout=600)
        output = result.stdout+result.stderr
        log.write_text(output)
        counts = re.search(r': (\d+) checks, (\d+) fail(?:ed|ures)',output)
        if counts is None:counts = re.search(r': (\d+)/(?:\d+) checks passed',output)
        # This known host CA-store warning is unrelated to the offline game.
        unexpected = '\n'.join(line for line in output.splitlines() if re.search(r'ERROR|SCRIPT ERROR|Parse Error|FAIL:',line) and 'Error loading system CA certificates' not in line)
        ok = result.returncode == 0 and counts is not None and (counts.lastindex == 1 or counts[2] == '0') and not unexpected
        return {'suite':name,'passed':bool(ok),'checks':int(counts[1]) if counts else 0,'details':unexpected[-2000:]}
    except subprocess.TimeoutExpired:
        return {'suite':name,'passed':False,'checks':0,'details':'timeout after 600 seconds'}
results = []
with ThreadPoolExecutor(max_workers=4) as pool:
    for future in as_completed([pool.submit(run,name) for name in names]):
        result = future.result()
        results.append(result)
        print(json.dumps(result,ensure_ascii=False),flush=True)
summary = {'suites':len(results),'checks':sum(r['checks'] for r in results),'failed_suites':sum(not r['passed'] for r in results),'results':sorted(results,key=lambda r:r['suite'])}
(base/'work/qa/m25-validation-summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2))
print('M25_REGRESSION:',summary['suites'],'suites,',summary['checks'],'checks,',summary['failed_suites'],'failed suites',flush=True)
raise SystemExit(1 if summary['failed_suites'] else 0)
