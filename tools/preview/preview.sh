#!/bin/sh
# DEV ONLY: render one screen (or the 3D sack previews) in Studio and save a cropped screenshot of the window.
#   sh tools/preview/preview.sh Training desktop out.png
#   STANDIN=1 sh tools/preview/preview.sh Showcase desktop out.png 6   # sacks 6..10 from GLB stand-ins
#   PROFILE=LOW sh tools/preview/preview.sh GameSacks desktop out.png 16 # sack VFX quality profile (default HIGH)
# Needs Studio + run-in-roblox; stage the art first (tools/preview/stage-art.sh). STANDIN=1 bundles the GLB
# stand-in data (tools/sacks/standin, from tools/sacks/glb2luau.py) into a dev-only place (preview.project.json).
set -e
screen="${1:-Training}"; stage="${2:-desktop}"; out="${3:-preview.png}"; from="${4:-1}"
dir="$(cd "$(dirname "$0")" && pwd)"; root="$dir/../.."
tmp="${TMPDIR:-/tmp}/kte-preview"; mkdir -p "$tmp"
project="$root/default.project.json"; standin=false
if [ "$STANDIN" = "1" ]; then
	standin=true; project="$root/preview.project.json"
	sed 's|    "Workspace":|    "ServerStorage": { "KTE_Dev": { "$className": "Folder", "StandIn": { "$path": "tools/sacks/StandIn.luau" }, "Data": { "$path": "tools/sacks/standin" } } },\n    "Workspace":|' "$root/default.project.json" > "$project"
fi
sed -e "s/^local SCREEN = .*/local SCREEN = \"$screen\"/" -e "s/^local STAGE = .*/local STAGE = \"$stage\"/" \
	-e "s/^local FROM = .*/local FROM = $from/" -e "s/^local STANDIN = .*/local STANDIN = $standin/" \
	-e "s/^local PROFILE = .*/local PROFILE = \"${PROFILE:-HIGH}\"/" \
	"$dir/UiPreview.server.lua" > "$tmp/run.server.lua"
[ -f "$tmp/place.rbxl" ] && [ "$KEEP_PLACE" = "1" ] || rojo build "$project" -o "$tmp/place.rbxl" > /dev/null
if [ "$stage" = "phone" ]; then w=844; h=390; elif [ "$stage" = "tablet" ]; then w=1024; h=768; else w=1600; h=900; fi
timeout 200 run-in-roblox --place "$tmp/place.rbxl" --script "$tmp/run.server.lua" > "$tmp/run.log" 2>&1 &
run=$!
sleep 1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "$dir/capture.ps1")" -Out "$(cygpath -w "$out")" -W $w -H $h -WaitSeconds "${WAIT:-18}"
wait $run || true
grep -v "^debug.profileEnd\|^Script 'MaterialManager\|^Stack Begin\|^Stack End" "$tmp/run.log" | tail -25
