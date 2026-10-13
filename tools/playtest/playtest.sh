#!/bin/sh
# DEV ONLY. A real Studio Play session (server + a client with a LocalPlayer) that walks the player through the
# whole loop (HUD, pad, kick, steering home, egg -> pen -> pet, tutorial, pens, shop, quickslot, Shift Lock,
# sack VFX LOD; PlayTestClient), then prints the
# results. Needs Studio + run-in-roblox. FRAMES=dir also saves a Studio-window capture every 3 s (PrintWindow:
# only that window's pixels).
#   sh tools/playtest/playtest.sh
#   FRAMES=/tmp/frames sh tools/playtest/playtest.sh
#   CLIENT=path/to/Probe.client.lua sh tools/playtest/playtest.sh   (another client script; must send DONE)
set -e
root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="${TMPDIR:-/tmp}/kte-playtest"; mkdir -p "$tmp"
cd "$root"
python_bin="${PYTHON:-/c/Program Files/Blender Foundation/Blender 4.5/4.5/python/bin/python.exe}" # any Python 3
"$python_bin" -I - "$root/default.project.json" "$root/playtest.project.json" "${CLIENT:-tools/playtest/PlayTestClient.client.lua}" <<'PY'
import json, sys
p = json.load(open(sys.argv[1], encoding="utf-8"))
tree = p["tree"]
tree["ServerScriptService"]["KTE_PlayTest"] = {"$path": "tools/playtest/PlayTestServer.server.lua"}
tree["StarterPlayer"]["StarterPlayerScripts"]["KTE_PlayTest"] = {"$path": sys.argv[3]}
json.dump(p, open(sys.argv[2], "w", encoding="utf-8"), indent=2)
PY
rojo build playtest.project.json -o "$tmp/KickTheEgg-playtest.rbxl" > /dev/null
rm -f playtest.project.json
if [ -n "$FRAMES" ]; then
	mkdir -p "$FRAMES"
	powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "$root/tools/playtest/frames.ps1")" -Dir "$(cygpath -w "$FRAMES")" -Every 3 -Seconds 400 > "$tmp/frames.log" 2>&1 &
fi
timeout 480 run-in-roblox --place "$tmp/KickTheEgg-playtest.rbxl" --script tools/playtest/Run.server.lua > "$tmp/run.log" 2>&1 || true
grep -E "^PLAYTEST" "$tmp/run.log" || tail -30 "$tmp/run.log"
wait
