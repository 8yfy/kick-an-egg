#!/bin/sh
# DEV ONLY: render one UI screen in Studio and save a cropped screenshot of the preview window.
#   sh tools/preview/preview.sh Training desktop out.png
# Needs Studio + run-in-roblox; the supplied PNGs must be staged locally first (tools/preview/stage-art.sh).
set -e
screen="${1:-Training}"; stage="${2:-desktop}"; out="${3:-preview.png}"
dir="$(cd "$(dirname "$0")" && pwd)"; root="$dir/../.."
tmp="${TMPDIR:-/tmp}/kte-preview"; mkdir -p "$tmp"
sed -e "s/^local SCREEN = .*/local SCREEN = \"$screen\"/" -e "s/^local STAGE = .*/local STAGE = \"$stage\"/" "$dir/UiPreview.server.lua" > "$tmp/run.server.lua"
[ -f "$tmp/place.rbxl" ] && [ "$KEEP_PLACE" = "1" ] || rojo build "$root/default.project.json" -o "$tmp/place.rbxl" > /dev/null
if [ "$stage" = "phone" ]; then w=844; h=390; else w=1600; h=900; fi
timeout 160 run-in-roblox --place "$tmp/place.rbxl" --script "$tmp/run.server.lua" > "$tmp/run.log" 2>&1 &
run=$!
sleep 1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "$dir/capture.ps1")" -Out "$(cygpath -w "$out")" -W $w -H $h -WaitSeconds "${WAIT:-18}"
wait $run || true
grep -v "^debug.profileEnd\|^Script 'MaterialManager\|^Stack Begin\|^Stack End" "$tmp/run.log" | tail -15
