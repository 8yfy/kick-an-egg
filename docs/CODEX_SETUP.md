# Codex setup manifest — 2026-10-18

## Repository
- Origin: `https://github.com/8yfy/kick-an-egg.git`.
- Canonical local repository: `C:/Users/kerem/Projects/kick-an-egg` (branch `b/map-v3`, older than the combined game).
- Current combined checkpoint: `a/full-build`, `2f59bee`; Claude's clean checkout is `C:/Users/kerem/Projects/kte-build`.
- Setup uses a separate `codex/environment-setup` worktree. No source, Rojo mapping, open Studio game, Claude settings or existing branches changed.
- Git fetch works. Public GitHub API PR reads work (including open #47 for `a/full-build`). `gh pr list` requires CLI login; push authentication has not been tested.

## Installed tools reused
- Roblox Studio: running, MCP read-only checks passed.
- Blender 5.2: `C:/Program Files/Blender Foundation/Blender 5.2/blender.exe`; installed `addon.py` reports MCP for Blender 1.8 / protocol 13.
- Rojo 7.7.1, StyLua 2.0.2, Selene 0.28.0: installed under `~/.rokit/tool-storage`; direct binaries verified. Rojo build passed.
- Node 24.19.0, npm 11.17.0, Python 3.11.5, Git 2.55.0.windows.5; uv/uvx and GitHub CLI available.

## Skills
Copied existing compatible skill directories (including references/scripts) from `~/.claude/skills` to `~/.codex/skills`; existing Codex skills were not overwritten:
- `animate-roblox-characters` (verified upstream `dillydog580/animate-roblox-characters`).
- Blender: `animation`, `rigging`, `camera-cinematography`, `lighting`, `environment-artist`, `prop-artist`, `vegetation-artist`, `set-dressing`, `stylized-style`, `lowpoly-style`, `geometry-nodes`, `asset-optimization`, `export-pipeline`, `vfx-fx` (verified upstream `arjun988/blender-skills`).
- Roblox: `roblox`, `roblox-mcp`, `roblox-rojo`, `roblox-testing`, `roblox-animation`, `roblox-vfx`, `roblox-audio` (verified upstream `nonlooped/roblox-suite`).
- Installed missing `blender-director` using the Codex skill-installer from `arjun988/blender-skills/.claude/skills/blender-director`.
- Total: 23 skills; load only those relevant to each task. New skills should be available on the next turn.

## MCP configuration and checks
- Existing `Roblox_Studio` registration retained. Studio listing, mode inspection, hierarchy/services and Luau source reads passed. Screenshot, playtest and input tools are exposed; no playtest or screenshot was needed for setup.
- Added `blender` to `~/.codex/config.toml` through `codex mcp add`, using the existing absolute uvx executable and pinned `mcp-for-blender==2.1.9`.
- Server environment: `DISABLE_TELEMETRY=true`, `BLENDER_HOST=127.0.0.1`, `BLENDER_PORT=9876`.
- MCP initialization and tool listing succeeded: `get_scene_info`, `execute_blender_code`, `look` and add-on status are available. Modeling, rigging and animation can use Python execution once connected.
- The server confirmed the installed add-on matches protocol 13. No replacement add-on or second Blender installation created.
- Live Blender connection failed with connection refused; Blender is not running. No scene modified. Open Blender, use View3D sidebar → MCP for Blender → connect, then retry read-only inspection. If Codex does not expose the new server, reload its MCP connection or restart the app.
- Simultaneous Claude/Codex access has not been tested. Use one writer at a time: finish the active operation, save the scene, then let the other client inspect before editing. Do not run two add-on listeners on the same port.

## Boundaries
No account-wide model/reasoning changes, credentials copied, external asset generation, uploads, remote pushes or merges. No exact token-budget claims. Local setup can support code work now; Blender scene operations await connection, and remote PR work awaits authentication.
