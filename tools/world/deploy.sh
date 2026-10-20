#!/bin/sh
# DEV ONLY: pushes this worktree's code + WorldAssets into the open Studio place without the Rojo plugin.
# Builds tools/world/deploy.project.json to an rbxm, copies it to Studio's content/kte/ folder under a fresh name and
# prints the rbxasset:// path; then run tools/world/deploy.luau in Studio (MCP execute_luau, Edit) with that path.
set -e
dir="$(cd "$(dirname "$0")" && pwd)"
rojo="$HOME/.rokit/tool-storage/rojo-rbx/rojo/7.7.1/rojo.exe"
studio="$(for d in "$LOCALAPPDATA"/Roblox/Versions/*/; do [ -f "$d/RobloxStudioBeta.exe" ] && echo "$d"; done | head -1)"
name="deploy_$(date +%s).rbxm"
"$rojo" build "$dir/deploy.project.json" -o "$dir/out/deploy.rbxm" > /dev/null
mkdir -p "$studio/content/kte"
rm -f "$studio"/content/kte/deploy_*.rbxm
cp "$dir/out/deploy.rbxm" "$studio/content/kte/$name"
echo "rbxasset://kte/$name"
