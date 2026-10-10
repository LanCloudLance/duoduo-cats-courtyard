from pathlib import Path
import os,shutil,subprocess,gzip,re,json
site=Path(__file__).resolve().parent
stage=site/'.build/godot';stage.parent.mkdir(exist_ok=True)
# Reuse imported resources, but never retain removed product files from an old build.
if stage.exists():
 for item in stage.iterdir():
  if item.name=='.godot':continue
  if item.is_dir():shutil.rmtree(item)
  else:item.unlink()
shutil.copytree(site/'game-source',stage,dirs_exist_ok=True,ignore=shutil.ignore_patterns('.godot','override.cfg','addons'))
if os.environ.get('WEB_STORAGE_PROBE'):
 p=stage/'ui/lobby.gd';text=p.read_text();marker='        print("WEB_READY solo=",web_solo," persistent=",OS.is_userfs_persistent()," userdir=",OS.get_user_data_dir())'
 text=text.replace(marker,marker+'\n'+Path(os.environ['WEB_STORAGE_PROBE']).read_text());p.write_text(text)
engine=Path(os.environ['GODOT_BIN']).resolve();templates=Path(os.environ['GODOT_WEB_TEMPLATES']).resolve()
preset=stage/'export_presets.cfg';s=preset.read_text()
for variant in ['debug','release']:
 s=re.sub(r'custom_template/'+variant+r'="[^"]*"',f'custom_template/{variant}="{templates}/web_nothreads_{variant}.zip"',s)
preset.write_text(s)
out=site/'dist/game';out.mkdir(parents=True,exist_ok=True)
subprocess.run([str(engine),'--headless','--path',str(stage),'--editor','--import','--quit'],check=True)
subprocess.run([str(engine),'--headless','--path',str(stage),'--export-debug' if os.environ.get('WEB_DEBUG') else '--export-release','Web',str(out/'index.html')],check=True)
wasm=out/'index.wasm';data=wasm.read_bytes();compressed=gzip.compress(data,compresslevel=9,mtime=0)
(out/'engine.bin').write_bytes(compressed)
assert gzip.decompress(compressed)==data
wasm.unlink()
html=out/'index.html';text=html.read_text();text=text.replace('<html lang="en">','<html lang="zh-CN">')
text=text.replace('<script src="index.js"></script>','<script src="web-loader.js"></script>\n<script src="index.js"></script>')
text=text.replace("const engine = new Engine(GODOT_CONFIG);","const engine = new Engine(GODOT_CONFIG);\nwindow.addEventListener('keydown',e=>{if(['Tab','ArrowUp','ArrowDown','ArrowLeft','ArrowRight',' '].includes(e.key))e.preventDefault();});")
text=text.replace("setStatusMode('hidden');","setStatusMode('hidden');\n            parent.postMessage({type:'duoduo-ready'}, location.origin);",1)
text=text.replace("function displayFailureNotice(err) {","function displayFailureNotice(err) {\n        parent.postMessage({type:'duoduo-error',message:String(err)}, location.origin);")
text=text.replace('const missingMsg = \'Error\\nThe following features required to run Godot projects on the Web are missing:\\n\';',"const missingMsg = '浏览器缺少运行条件，请使用更新的桌面浏览器：\\n';")
html.write_text(text)
shutil.copyfile(site/'web-loader.js',out/'web-loader.js')
print('WEB BUILD',json.dumps({'engine_download_bytes':len(compressed),'engine_raw_bytes':len(data),'game_bytes':(out/'index.pck').stat().st_size}))
