import shutil,subprocess,pathlib,sys,json
root=pathlib.Path.cwd();src=root/'outputs/duoduo-game';qa=root/'work/m28/portable-qa';qa.mkdir(parents=True,exist_ok=True)
for name in ['game','tests','input','ui','assets']:
    shutil.copytree(src/name,qa/name,dirs_exist_ok=True)
for item in src.iterdir():
    if item.is_file() and item.suffix in ['.godot','.tscn','.gd'] and item.name!='override.cfg':shutil.copy2(item,qa/item.name)
(qa/'override.cfg').write_text('[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="DuoduoCatsCourtyard-qa-m28-portable"\n')
args=[str(root/'work/runtime/Godot.app/Contents/MacOS/Godot'),'--headless','--path',str(qa)]+sys.argv[1:]
try:
    out=subprocess.run(args,capture_output=True,text=True,timeout=100)
    log=out.stdout+out.stderr
    label='import' if '--import' in args else pathlib.Path(args[-1]).stem
    (root/'work/m28'/('portable-'+label+'.log')).write_text(log)
    print(log[-14000:]);sys.exit(out.returncode or (1 if 'SCRIPT ERROR' in log or 'ERROR:' in log or 'FAIL:' in log else 0))
except subprocess.TimeoutExpired as e:
    print('TIMEOUT',e.stdout,e.stderr);sys.exit(124)
