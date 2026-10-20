#!/bin/sh
# DEV ONLY. Renders every sound recipe in Audio/SoundBank to WAVs you can listen to (tools/audio/previews/, not
# committed): events/, sacks/ (all 20 x equip / impact / special / upgrade / idle), landings/ (every surface soft /
# hard / bounce + mutations), scenarios/ (the 10 required ones) + scenarios_1_to_10.wav, before_after/ (the old
# thunder kick and sack punches vs the new ones) and report.json (length, peak, sub-bass share of each).
# Needs Studio + run-in-roblox (to read the recipes from the game) and Blender (its audio decoder).
#   sh tools/audio/render.sh
set -e
root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"
blender="${BLENDER:-/c/Program Files/Blender Foundation/Blender 4.5/blender.exe}"
tmp="${TMPDIR:-/tmp}/kte-audio"; mkdir -p "$tmp"
rojo build default.project.json -o "$tmp/place.rbxl" > /dev/null
run-in-roblox --place "$tmp/place.rbxl" --script tools/audio/Export.server.lua > "$tmp/export.log" 2>&1
grep -q "AUDIOJSON_END" "$tmp/export.log" || { tail -20 "$tmp/export.log"; exit 1; }
"$blender" -b --factory-startup --python tools/audio/render.py -- "$tmp/export.log" "$root/tools/audio/previews" 2>&1 | grep -E "^(RENDERED|COMPARE|SCENARIO)|Error"
