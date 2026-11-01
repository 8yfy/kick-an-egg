#!/bin/sh
# DEV ONLY: like tools/world/deploy.sh (this worktree's Shared / Server / Client into the open Studio place without
# the Rojo plugin) but with its own file prefix, so it never deletes another session's deploy. Prints the
# rbxasset:// path for tools/world/deploy.luau (MCP execute_luau, Edit, with PATH set to it).
set -e
dir="$(cd "$(dirname "$0")" && pwd)"
rojo="$HOME/.rokit/tool-storage/rojo-rbx/rojo/7.7.1/rojo.exe"
# the newest installed Studio (rbxasset:// resolves inside the running Studio's own version folder)
studio="$(ls -td "$LOCALAPPDATA"/Roblox/Versions/*/RobloxStudioBeta.exe 2>/dev/null | head -1 | xargs -0 dirname)"
name="anim_$(date +%s).rbxm"
mkdir -p "$dir/out"
"$rojo" build "$dir/../world/deploy.project.json" -o "$dir/out/deploy.rbxm" > /dev/null
mkdir -p "$studio/content/kte"
rm -f "$studio"/content/kte/anim_*.rbxm
cp "$dir/out/deploy.rbxm" "$studio/content/kte/$name"
echo "rbxasset://kte/$name"
