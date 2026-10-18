# Development handoff

## Current checkpoint
- Task: three ranked avatar podiums for each global leaderboard, random equipped emotes, and nearby gold/silver/bronze placement badges. Shop labels, Shift Lock and pen-wave fixes are preserved.
- Branch: `codex/pen-upgrade-feedback`, based on setup commit `4aa9292` and combined game `origin/a/full-build` at `2f59bee` (character-animation merge, PR #49).
- Working directory: `C:/Users/kerem/Documents/Codex/2026-10-13/ca/work/kte-setup`.
- GitHub: pen feedback, Shift Lock fixes, shop labels and the leaderboard podium/emote/badge revision use `origin/codex/pen-upgrade-feedback`. Source and handoff notes are committed and pushed at the user's request. Prior shop-label checkpoint: `f372b4c`; use the branch tip for the podium revision. No PR or merge was created.
- Existing Claude worktrees remain intact. `kick-an-egg` has untracked `tools/icons/icons2d.py`; `kte-anim` has untracked `build/`. Do not discard them.

## Completed and changed
- Added six podiums in `Builders/Map/Boards`, adjusted board height and moved Donate forward. `Services/LeaderboardService` now feeds its same top-three entries into `Util/LeaderboardPodiums`. Native appearances use private WorldModel assembly, bounded caching and stale-request rejection. `Util/PodiumEmotes` loops only actually equipped emotes via their resolved catalog Animation assets. `Controllers/LeaderboardDisplayController` adds locally faded nearby medal badges. See `docs/LeaderboardPodiums.md`.
- Added `Controllers/ShopLabelController.luau`: outlined, world-sized shop labels above the roof decorations, player/camera distance gates and per-frame viewport visibility. Local UI only; physical signs, prompts and gameplay are unchanged. See `docs/ShopLabels.md`.
- Added `src/client/UI/Hud/PenUpgradeFeedback.luau`, wired it into `UI/init.luau`, and removed the drawer's duplicate success feedback. Confirmed level increases use the existing DataChanged flow; server gameplay code is untouched.
- Latest revision changes that module and its tests: the title lives above PenArea, below the owner portrait, and no success notice is placed in the HUD. The richer sequence cleans itself up at 1.6 s; Low Detail and Reduced Motion remain supported. Existing avatar/name code is unchanged and its preservation is tested.
- Newest revision waves visible fence/gate posts and rails from the gate around both sides. Only local cosmetic copies move. Added `Controllers/ShiftLockController.luau`, `tools/tests/ShiftLock.client.lua` and `docs/ShiftLock.md` for the measured default shoulder-offset jump; normal gameplay/character controls remain Roblox-owned.
- Changed only `Audio/SoundBank.PenUpgrade` to a verified free Creator Store pop/chime mix. Existing UI/Master volume routing is reused.
- Added focused `tools/tests/PenUpgrade.{server,client}.lua` and `docs/PenUpgradeFeedback.md` with timing, asset provenance, tests and reproduction instructions.
- Added `AGENTS.md`, this handoff, and `docs/CODEX_SETUP.md`.
- Reused 22 installed Claude skills in Codex; installed the missing `blender-director` from its verified upstream.
- Registered Blender MCP 2.1.9 with telemetry disabled; retained the installed protocol-13 add-on. Existing Studio MCP and Rojo reused.

## Verification this session
- Leaderboard addition: 24 server checks and seven client checks passed in single-player Studio, including native avatar appearance, equipped-only emotes, replicated joint motion, nearby badges, rank changes and asynchronous failure cleanup. Six actual-avatar slots visually reviewed. No live DataStore writes or multiplayer tests; NumberOfPlayers remains 0. Updated deliverable: `outputs/KickTheEgg-LeaderboardPodiums.rbxl`, all 289 source scripts packaged, no diagnostic scripts. Source applied to the open Studio. Published global rankings/asset permissions remain unverified.
- All entries below are inherited results from the preceding shop-label/camera/pen revisions, not fresh reruns for the podium addition.
- Current label addition: 14 visibility/text/depth checks passed in a fresh single-player Studio session. Both labels visually reviewed together. Rojo binary/XML build includes all 286 source scripts with no QA/probe scripts. Current deliverable: `outputs/KickTheEgg-ShopLabels.rbxl`; source applied to open Studio, returned to Edit with NumberOfPlayers=0. No multiplayer tests started.
- The following Shift Lock/pen measurements are historical results from the preceding revisions; those suites were not rerun for this label-only addition.
- Latest fix: native cursor trace reproduced the off-centre trigger. A `(−2, −42)` mouse packet arrived on frame three (0.031 s), producing a 16.170-degree upward pitch change after the two-frame guard expired. Replaced that guard with 0.12 s of relative-input suppression via the public MouseDeltaSensitivity property. Exact prior sensitivity is restored, rapid toggles/Destroy are safe, and the original shake priority is restored. No default camera internals are patched.
- Fresh Studio production-source checks: eight controlled native toggles across four off-centre cursor positions, 0 degrees of pitch/yaw change each; sensitivity restored to 1. Walking during toggles travelled 20.80 studs with normal speed/AutoRotate/subject. Scriptable-camera handoff: 0 unwanted displacement and input restored. 27 offline regression checks pass; the two-frame controller fails the new delayed-packet test. See `docs/ShiftLock.md` and `tools/tests/ShiftLockNative.client.lua`.
- Current source is applied in the open Studio Edit session. TestService.NumberOfPlayers=0, QA scripts absent. Current deliverable: `outputs/KickTheEgg-ShiftLockFixed.rbxl`. Older ShiftLockPitch builds are superseded. No multiplayer test was started.
- The prior Studio MCP approval blocker is resolved under the user's current permissions. Last turn, the user explicitly authorized adding `approval_policy = "on-request"` to the user Codex config; this turn did not change permissions/configuration.
- The following wave/shoulder measurements are from the previous completed revision, not fresh pen tests for this cursor fix:
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
1. Review the feature branch and updated leaderboard-podium Studio deliverable. Do not merge automatically.
2. Physical mobile and published-server asset permissions remain unverified. Studio multiplayer and iPhone simulation passed.
3. Prior checkpoints: `a127074`, `9c43b00`, `ca7f62f`, `c02e28c`, `1ffaf24`, `f372b4c`. The user authorized committing the changes to the repository; the feature branch was pushed successfully to `8yfy/kick-an-egg`. Review that branch before merging. No PR or automatic merge was created.
4. Blender is configured but not needed for this feature. Before future modeling, connect the existing add-on and inspect the live scene.
5. Preserve inherited animation follow-ups above; they are outside this feature's scope.
