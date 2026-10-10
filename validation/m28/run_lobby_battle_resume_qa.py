from pathlib import Path
import json
import shutil
import subprocess
import sys

BASE = Path(__file__).resolve().parents[2]
SOURCE = BASE / "outputs/duoduo-game"
QA = BASE / "work/m28/lobby-battle-resume-qa"
LOGS = BASE / "work/m28/lobby-battle-resume-logs"
NAMESPACE = "DuoduoCatsCourtyard-qa-m28-lobby-battle-resume"
ENGINE = BASE / "work/runtime/Godot.app/Contents/MacOS/Godot"
QA.mkdir(parents=True, exist_ok=True)
LOGS.mkdir(parents=True, exist_ok=True)
for path in SOURCE.iterdir():
    if path.name.startswith(".") or path.name == "override.cfg":
        continue
    target = QA / path.name
    if path.is_dir():
        shutil.copytree(path, target, dirs_exist_ok=True)
    else:
        shutil.copy2(path, target)
(QA / "override.cfg").write_text('[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="' + NAMESPACE + '"\n')

def run(name, arguments, timeout=150):
    command = [str(ENGINE), "--headless", "--path", str(QA), "--log-file", str(LOGS / (name + ".engine.log"))] + arguments
    try:
        result = subprocess.run(command, capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired as error:
        output = (error.stdout or b"").decode(errors="replace") + (error.stderr or b"").decode(errors="replace")
        (LOGS / (name + ".timeout.log")).write_text(output)
        raise SystemExit(name + " timed out; partial log retained")
    output = result.stdout + result.stderr
    (LOGS / (name + ".log")).write_text(output)
    print(name, "exit", result.returncode, output[-1200:] if name == "import" else output[-6500:], flush=True)
    if result.returncode or "SCRIPT ERROR:" in output or "ERROR:" in output:
        raise SystemExit(1)
    if name != "import" and ("M28_LOBBY_RESUME_EXIT_BUTTON" not in output or NAMESPACE not in output or "0 failed" not in output):
        raise SystemExit(name + " lacks successful real menu exit and namespace evidence")
    return output

run("import", ["--editor", "--import", "--quit"])
for mode in ["solo", "dual"]:
    for phase in ["prepare", "segment", "resume"]:
        run(mode + "-" + phase, ["--fixed-fps", "60", "--script", "res://tests/m28_lobby_battle_resume_test.gd", "--", phase, mode])
print("M28_LOBBY_BATTLE_RESUME_ALL: six independent OS processes passed", flush=True)
