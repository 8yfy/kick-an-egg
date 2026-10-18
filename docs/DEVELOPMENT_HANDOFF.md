# Development handoff

## Current checkpoint
- Task: upgraded the pen celebration again at the user's request: world-space UPGRADED! title, level subtitle, boundary sweep, expanding floor ripple, corner flares, gold fragments and stronger post pop/glow.
- Branch: `codex/pen-upgrade-feedback`, based on setup commit `4aa9292` and combined game `origin/a/full-build` at `2f59bee` (character-animation merge, PR #49).
- Working directory: `C:/Users/kerem/Documents/Codex/2026-10-13/ca/work/kte-setup`.
- Existing Claude worktrees remain intact. `kick-an-egg` has untracked `tools/icons/icons2d.py`; `kte-anim` has untracked `build/`. Do not discard them.

## Completed and changed
- Added `src/client/UI/Hud/PenUpgradeFeedback.luau`, wired it into `UI/init.luau`, and removed the drawer's duplicate success feedback. Confirmed level increases use the existing DataChanged flow; server gameplay code is untouched.
- Latest revision changes that module and its tests: the title lives above PenArea, below the owner portrait, and no success notice is placed in the HUD. The richer sequence cleans itself up at 1.6 s; Low Detail and Reduced Motion remain supported. Existing avatar/name code is unchanged and its preservation is tested.
- Changed only `Audio/SoundBank.PenUpgrade` to a verified free Creator Store pop/chime mix. Existing UI/Master volume routing is reused.
- Added focused `tools/tests/PenUpgrade.{server,client}.lua` and `docs/PenUpgradeFeedback.md` with timing, asset provenance, tests and reproduction instructions.
- Added `AGENTS.md`, this handoff, and `docs/CODEX_SETUP.md`.
- Reused 22 installed Claude skills in Codex; installed the missing `blender-director` from its verified upstream.
- Registered Blender MCP 2.1.9 with telemetry disabled; retained the installed protocol-13 add-on. Existing Studio MCP and Rojo reused.

## Verification this session
- Current revision: 16 Studio integration checks passed, including world anchoring/no HUD notice, owner portrait preservation, failures, duplicates, pet survival, collision safety, audio/settings, rapid purchases and cleanup. Desktop/iPhone landscape previews inspected. Real simultaneous two-client testing passed again: one world title/audio per owner, correct pen isolation and complete cleanup on both clients. The prior revision's W-input probe recorded 11.47 studs; this revision also contains no control/camera changes.
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
3. Prior implementation commits: `a127074`, `9c43b00`; world-space revision follows these on the same local feature branch. The GitHub push remains blocked pending explicit user approval to export source to `8yfy/kick-an-egg`. Do not work around that block. No remote branch or PR has been created.
4. Blender is configured but not needed for this feature. Before future modeling, connect the existing add-on and inspect the live scene.
5. Preserve inherited animation follow-ups above; they are outside this feature's scope.
