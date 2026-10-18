# Development handoff

## Current checkpoint
- Task: smooth the Shift Lock camera snap while walking with nothing equipped, and animate the decorative pen fence/posts in a travelling upgrade wave.
- Branch: `codex/pen-upgrade-feedback`, based on setup commit `4aa9292` and combined game `origin/a/full-build` at `2f59bee` (character-animation merge, PR #49).
- Working directory: `C:/Users/kerem/Documents/Codex/2026-10-13/ca/work/kte-setup`.
- Existing Claude worktrees remain intact. `kick-an-egg` has untracked `tools/icons/icons2d.py`; `kte-anim` has untracked `build/`. Do not discard them.

## Completed and changed
- Added `src/client/UI/Hud/PenUpgradeFeedback.luau`, wired it into `UI/init.luau`, and removed the drawer's duplicate success feedback. Confirmed level increases use the existing DataChanged flow; server gameplay code is untouched.
- Latest revision changes that module and its tests: the title lives above PenArea, below the owner portrait, and no success notice is placed in the HUD. The richer sequence cleans itself up at 1.6 s; Low Detail and Reduced Motion remain supported. Existing avatar/name code is unchanged and its preservation is tested.
- Newest revision waves visible fence/gate posts and rails from the gate around both sides. Only local cosmetic copies move. Added `Controllers/ShiftLockController.luau`, `tools/tests/ShiftLock.client.lua` and `docs/ShiftLock.md` for the measured default shoulder-offset jump; normal gameplay/character controls remain Roblox-owned.
- Changed only `Audio/SoundBank.PenUpgrade` to a verified free Creator Store pop/chime mix. Existing UI/Master volume routing is reused.
- Added focused `tools/tests/PenUpgrade.{server,client}.lua` and `docs/PenUpgradeFeedback.md` with timing, asset provenance, tests and reproduction instructions.
- Added `AGENTS.md`, this handoff, and `docs/CODEX_SETUP.md`.
- Reused 22 installed Claude skills in Codex; installed the missing `blender-director` from its verified upstream.
- Registered Blender MCP 2.1.9 with telemetry disabled; retained the installed protocol-13 add-on. Existing Studio MCP and Rojo reused.

## Verification this session
- Current revision: 17 single-player upgrade checks passed; 47 models moved with a 0.444 s travelling crest delay, originals/collisions and placed pet preserved. Low Detail/Reduced Motion, failure/duplicate cases and cleanup passed. Desktop wave preview inspected. No multiplayer session was started at the user's request; Studio restored to Edit, NumberOfPlayers=0, QA scripts absent.
- Shift Lock: max stationary lateral step reduced from 1.750 to 0.178 studs/frame, no added rotation; six toggles produced zero drift; walking remained functional (13.90 studs). Scriptable handoff regression passed with zero camera displacement. See `docs/ShiftLock.md`.
- Final deliverable: `outputs/KickTheEgg-WaveUpgrade.rbxl` outside the repository. Rojo binary/XML builds passed, all 285 source files matched the packaged scripts, no QA/probe scripts were packaged, and targeted StyLua/diff checks passed.
- Both selected Creator Store clips loaded and played with measured nonzero loudness. No uploads needed. Rojo and StyLua checks passed. Detailed evidence and limitations: `docs/PenUpgradeFeedback.md`.
- Studio MCP: open `KickTheEgg-full-2026-10-18.rbxl` in Edit mode; read hierarchy/services and server Main source successfully without mutations.
- Blender MCP: initialization and tool listing passed; installed add-on protocol matches. Blender socket connection refused because no Blender GUI is running. Scene/object inspection remains unverified.
- Rojo 7.7.1 built the current combined checkout successfully to a scratch file outside the repository. StyLua 2.0.2 and Selene 0.28.0 executables verified. No gameplay tests run during setup.
- Git fetch and public API PR reads succeeded (#47 is the combined build PR). GitHub CLI has no authenticated account; push/PR creation capability is unverified.

## Known issues inherited from prior work
See `docs/CharacterAnimation.md`: flying egg starts at pad center instead of kicker's foot; shift-lock can turn the body toward the camera after sack alignment. The Pet Merchant folded-arms pose is an intentional decision.
That document reports 365 passing and 3 existing failing server tests; these are historical results, not rerun here. Multiplayer, real mobile and live-server checks are still listed as untested.

## Pending / next steps
1. Review the pen-upgrade feature branch and built Studio deliverable. Do not merge automatically.
2. Physical mobile and published-server asset permissions remain unverified. Studio multiplayer and iPhone simulation passed.
3. Prior checkpoints: `a127074`, `9c43b00`, `ca7f62f`; wave/Shift Lock work follows on the same local feature branch. GitHub push remains blocked pending explicit approval to export source to `8yfy/kick-an-egg`. Do not work around it. No remote branch or PR has been created.
4. Blender is configured but not needed for this feature. Before future modeling, connect the existing add-on and inspect the live scene.
5. Preserve inherited animation follow-ups above; they are outside this feature's scope.
