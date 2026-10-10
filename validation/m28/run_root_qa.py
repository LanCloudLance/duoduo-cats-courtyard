from pathlib import Path
import subprocess,json,argparse,time,re
BASE=Path(__file__).resolve().parents[2]
QA=BASE/'work/m28/root-qa'
ENGINE=BASE/'work/runtime/Godot.app/Contents/MacOS/Godot'
OUT=BASE/'work/m28/root-evidence'
OUT.mkdir(parents=True,exist_ok=True)
parser=argparse.ArgumentParser();parser.add_argument('suite');parser.add_argument('--timeout',type=int,default=120);parser.add_argument('--render',action='store_true');args=parser.parse_args()
if args.suite!='import' and (not args.suite.isidentifier() or not (QA/'tests'/(args.suite+'.gd')).is_file()):raise SystemExit('Unknown QA suite')
namespace='DuoduoCatsCourtyard-qa-m28-root'
if namespace not in (QA/'override.cfg').read_text():raise SystemExit('Missing root QA override')
probe=QA/'m28_namespace.gd'
probe.write_text('extends SceneTree\nfunc _init()->void:\n    print("ACTUAL_QA_NAMESPACE:",OS.get_user_data_dir().get_file())\n    quit(0 if OS.get_user_data_dir().get_file()=="'+namespace+'" else 1)\n')
r=subprocess.run([str(ENGINE),'--headless','--path',str(QA),'--script','res://m28_namespace.gd'],capture_output=True,text=True,timeout=30)
if r.returncode or ('ACTUAL_QA_NAMESPACE:'+namespace) not in r.stdout:raise SystemExit('Actual namespace verification failed')
command=[str(ENGINE),'--path',str(QA)]
if not args.render:command+=['--headless']
if args.suite=='import':command+=['--editor','--import','--quit']
else:command+=['--fixed-fps','60','--script','res://tests/'+args.suite+'.gd']
start=time.monotonic()
try:
    r=subprocess.run(command,capture_output=True,text=True,timeout=args.timeout)
    output=r.stdout+r.stderr;code=r.returncode
except subprocess.TimeoutExpired as error:
    output=(error.stdout or b'').decode(errors='replace')+(error.stderr or b'').decode(errors='replace')+'\nPROCESS_TIMEOUT';code=124
archive=OUT/'attempts';archive.mkdir(exist_ok=True)
for extension in ['log','json']:
    previous=OUT/(args.suite+'.'+extension)
    if previous.exists():
        (archive/(args.suite+'-'+str(time.time_ns())+'.'+extension)).write_bytes(previous.read_bytes())
(OUT/(args.suite+'.log')).write_text(output)
issues=[line for line in output.splitlines() if re.search(r'ERROR|SCRIPT ERROR|Parse Error|FAIL(?:[: ]|$)|PROCESS_TIMEOUT',line) and 'Error loading system CA certificates' not in line]
counts=re.findall(r': (\d+) checks, (\d+) fail(?:ed|ures)',output)
receipt={'suite':args.suite,'exit':code,'passed':code==0 and not issues and (args.suite=='import' or args.render or bool(counts) and counts[-1][1]=='0'),'checks':int(counts[-1][0]) if counts else None,'namespace':namespace,'seconds':round(time.monotonic()-start,2),'issues':issues[:16],'warnings':[line for line in output.splitlines() if 'WARNING:' in line]}
(OUT/(args.suite+'.json')).write_text(json.dumps(receipt,ensure_ascii=False,indent=2))
print(json.dumps(receipt,ensure_ascii=False));raise SystemExit(0 if receipt['passed'] else 1)
