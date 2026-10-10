from pathlib import Path
import shutil
BASE=Path(__file__).resolve().parents[2]
SOURCE=BASE/'outputs/duoduo-game'
QA=BASE/'work/m28/root-qa'
QA.mkdir(parents=True,exist_ok=True)
for item in SOURCE.iterdir():
    if item.name in ('.godot','override.cfg','addons','.DS_Store') or item.suffix=='.png':
        continue
    destination=QA/item.name
    if item.is_dir():
        shutil.copytree(item,destination,dirs_exist_ok=True)
    else:
        shutil.copy2(item,destination)
cache=BASE/'work/m27/root-qa/.godot'
if cache.exists():shutil.copytree(cache,QA/'.godot',dirs_exist_ok=True)
(QA/'override.cfg').write_text('[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="DuoduoCatsCourtyard-qa-m28-root"\n')
print(QA)
