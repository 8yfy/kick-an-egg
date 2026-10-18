# Development handoff

## Current checkpoint
- Task: configure Codex to continue Claude's work; no gameplay changes requested or made.
- Branch: `codex/environment-setup`, based on `origin/a/full-build` at `2f59bee` (character-animation merge, PR #49).
- Working directory: `C:/Users/kerem/Documents/Codex/2026-10-13/ca/work/kte-setup`.
- Existing Claude worktrees remain intact. `kick-an-egg` has untracked `tools/icons/icons2d.py`; `kte-anim` has untracked `build/`. Do not discard them.

## Completed and changed
- Added `AGENTS.md`, this handoff, and `docs/CODEX_SETUP.md`.
- Reused 22 installed Claude skills in Codex; installed the missing `blender-director` from its verified upstream.
- Registered Blender MCP 2.1.9 with telemetry disabled; retained the installed protocol-13 add-on. Existing Studio MCP and Rojo reused.

## Verification this session
- Studio MCP: open `KickTheEgg-full-2026-10-18.rbxl` in Edit mode; read hierarchy/services and server Main source successfully without mutations.
- Blender MCP: initialization and tool listing passed; installed add-on protocol matches. Blender socket connection refused because no Blender GUI is running. Scene/object inspection remains unverified.
- Rojo 7.7.1 built the current combined checkout successfully to a scratch file outside the repository. StyLua 2.0.2 and Selene 0.28.0 executables verified. No gameplay tests run during setup.
- Git fetch and public API PR reads succeeded (#47 is the combined build PR). GitHub CLI has no authenticated account; push/PR creation capability is unverified.

## Known issues inherited from prior work
See `docs/CharacterAnimation.md`: flying egg starts at pad center instead of kicker's foot; shift-lock can turn the body toward the camera after sack alignment. The Pet Merchant folded-arms pose is an intentional decision.
That document reports 365 passing and 3 existing failing server tests; these are historical results, not rerun here. Multiplayer, real mobile and live-server checks are still listed as untested.

## Pending / next steps
1. Open Blender and connect the installed MCP add-on; reload Codex MCP connections if the new server is not exposed. Perform read-only scene/object checks before modeling.
2. Choose the actual unfinished feature with the user; inspect its current branch/diff and relevant documentation.
3. Authenticate GitHub CLI only when needed for PR work. Setup documentation is local; no remote push or merge was performed.
4. Pending asset uploads: not audited during setup; inspect the selected feature's manifest before uploading anything.
