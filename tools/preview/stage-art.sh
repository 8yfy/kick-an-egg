#!/bin/sh
# DEV ONLY: copy the staged UI handoff PNGs (assets/ui-upload/<key>.png) into Studio's local content folder so
# Studio can show them before they are uploaded (rbxasset://textures/KickTheEggUI/<key>.png). Re-run after a
# Studio update (each Studio version has its own content folder).
set -e
root="$(cd "$(dirname "$0")/../.." && pwd)"
ver="$(ls -td "$LOCALAPPDATA"/Roblox/Versions/version-*/ 2>/dev/null | while read d; do [ -f "$d/RobloxStudioBeta.exe" ] && echo "$d" && break; done)"
[ -n "$ver" ] || { echo "Roblox Studio not found"; exit 1; }
mkdir -p "$ver/content/textures/KickTheEggUI"
cp "$root"/assets/ui-upload/*.png "$ver/content/textures/KickTheEggUI/"
echo "staged $(ls "$root"/assets/ui-upload/*.png | wc -l) images into $ver"
