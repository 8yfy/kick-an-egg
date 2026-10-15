#!/bin/sh
# DEV ONLY: builds the real map in Studio and saves a labelled screenshot per shot (hub + every zone, outward and on
# the way home; UiPreview SCREEN = MapTour). Needs Studio + run-in-roblox.
#   sh tools/preview/maptour.sh out_dir [seconds_per_shot]
set -e
out="${1:-maptour}"; shot="${2:-3}"
dir="$(cd "$(dirname "$0")" && pwd)"; root="$dir/../.."
tmp="${TMPDIR:-/tmp}/kte-maptour"; mkdir -p "$tmp" "$out"
sed -e 's/^local SCREEN = .*/local SCREEN = "MapTour"/' -e 's/^local STAGE = .*/local STAGE = "desktop"/' \
	-e "s/^local FROM = .*/local FROM = $shot/" -e 's/^local STANDIN = .*/local STANDIN = false/' \
	"$dir/UiPreview.server.lua" > "$tmp/run.server.lua"
rojo build "$root/default.project.json" -o "$tmp/place.rbxl" > /dev/null
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "$root/tools/playtest/frames.ps1")" -Dir "$(cygpath -w "$out")" -Every 2 -Seconds 400 > "$tmp/frames.log" 2>&1 &
cap=$!
timeout 420 run-in-roblox --place "$tmp/place.rbxl" --script "$tmp/run.server.lua" > "$tmp/run.log" 2>&1 || true
wait $cap || true
grep -E "MAP_BUILT|SHOT|rror" "$tmp/run.log" | head -80; cp "$tmp/run.log" "$out/run.log"
