#!/bin/sh
# DEV ONLY: copy the UI handoff PNGs (assets/ui-upload/<key>.png) and the sack VFX sprites (assets/sack-vfx) into
# Studio's local content folder so
# Studio can show them before they are uploaded (rbxasset://textures/KickTheEggUI/<key>.png). Re-run after a
# Studio update (each Studio version has its own content folder).
set -e
root="$(cd "$(dirname "$0")/../.." && pwd)"
ver="$(ls -td "$LOCALAPPDATA"/Roblox/Versions/version-*/ 2>/dev/null | while read d; do [ -f "$d/RobloxStudioBeta.exe" ] && echo "$d" && break; done)"
[ -n "$ver" ] || { echo "Roblox Studio not found"; exit 1; }
mkdir -p "$ver/content/textures/KickTheEggUI"
cp "$root"/assets/ui-upload/*.png "$ver/content/textures/KickTheEggUI/" 2>/dev/null || echo "no UI pngs in assets/ui-upload (gitignored: copy them from the UI handoff)"
cp "$root"/assets/sack-vfx/*.png "$ver/content/textures/KickTheEggUI/"
echo "staged UI art + sack VFX sprites into $ver"
