# Development handoff

## Current checkpoint
- **Top-tier remodel: Heaven Lion, Clockwork Titan, Prism Seraph (2026-10-31, Partner A, branch `a/top-tier-pets`,
  stacked on `a/frost-serpent-rename`).**
  - Rebuilt to the user's three reference images and approved by the user.
  - Block specs: `Builders/Models/Premium/{HeavenLion,ClockworkTitan,PrismSeraph}.luau` (444 / 332 / 445 parts). The lion
    is new: Zone 20 now loads it from Premium instead of `Creatures`.
  - Eggs are in the same files. Effects go in `PetFx/Recipes/{ClockworkFactory,RainbowHeaven}.luau`. The lion's recipe is
    new; it had none before.
  - Generators: `tools/blender/pets/` (the Frost Serpent kit generalised into `kit/` + `v3/`; `v3build.py ... dest=premium`).
  - Shared code:
    - `Anim/Pet` sets idle tempo and flourishes by rarity, and syncs PetFx specials through the `PetFxSpecial`
      attribute;
    - PetFx layers take a `bright` field (ParticleEmitter.Brightness);
    - `PetFx/Sprites` registers the `v3_*` and `meadow_*` sprites.
  - Rule 3 is kept: in-game pets are still block data. The user also commissioned mesh versions of the three pets
    (beveled, rigged, animated, FBX + GLB, `KickAnEgg_PremiumPets/README.md`). Using them in the game needs a Partner A +
    B decision. `RobloxIntegration/AnimationNotes` recommends one MeshPart per joint on the existing Motor6Ds.
  - **Sprites uploaded (2026-10-31):** the 14 `assets/pet-vfx/vfx_v3_*.png` and 3 `vfx_meadow_*.png` sprites. Decal ids
    are in `tools/world/ids/pet-vfx.json`, and the resolved Image ids in `PetFx/Sprites`. All 17 load in Studio, and the
    top tier's effects draw the uploaded art.
  - **Verified this session in Studio (single-player Play):**
    - the `ServerTests` hero section re-run by hand plus the new Heaven Lion pair: 57/57. The ladder is SproutPup 37 <
      MeadowStag 70 < TideSpirit 85 < FrostSerpent 170 < QuetzalPhoenix 175 < ClockworkTitan 332 < PrismSeraph 445;
    - all three idles animate (`Anim/Pet`), and the effects attach and clean up;
    - no new script errors.
  - **Not run:** the full `tools/run-tests.sh` (no run-in-roblox here), Roblox's 3D Importer on the mesh exports, and a
    multiplayer test.

- **Signature motion and effects for the top tier (2026-11-01, Partner A, same branch `a/top-tier-pets`, PR #59).**
  - The user asked for unique effects and animations per pet, not the shared stack with new colours. They picked one
    concept per pet and approved the result in recorded pen clips:
    - Heaven Lion: Judgement Light;
    - Clockwork Titan: Overcharged Engine;
    - Prism Seraph: Aurora Veil.
  - The tables are in `docs/EggPetPlan.md` ("Signature motion", "Signature effects").
  - **Motion:** `Anim/PetProfiles.luau` gives each pet its own idle, roam and special, keyed by model key. `Anim/Pet`
    uses a profile when the pet has one and falls back to the rarity tempo when it doesn't. The `Anim.play` API is
    unchanged. New joints: `Mane` on the lion, `HeartHands` and `Gear1-7` on the titan (re-baked Premium specs).
  - **Effects:**
    - `VFX/PetFx/Signature.luau` adds the layer kinds `arc`, `blades`, `strike`, `dial`, `ribbon`, `trail` and
      `curtain`.
    - `emit` takes `part`, `cue`, `on`, `beat` and `delay`.
    - `beam` takes `top`, `pulse`, `curve` and `bright`.
    - `light` takes `flicker` and `cycle`.
    - Handles get `Fire(sync)`.
  - **New sprites:** `assets/pet-vfx/vfx_v3_{shaft,arc,clock_dial,veil}.png` (`tools/blender/pets/v3/sprites_signature.py`).
    Uploaded 2026-11-01: Decal ids are in `tools/world/ids/pet-vfx.json` and Image ids in `PetFx/Sprites`. All 10
    textures the three pets' effects use load from uploaded ids in Studio.
  - **Verified in Studio (single-player Play):** the `ServerTests` hero and premium-pair checks pass 57/57, and the
    ladder still rises (titan 340 < seraph 445). Each pet was recorded idling, firing its special and roaming in a pen.
    No new script errors.
  - **Mesh deliverables rebuilt (2026-11-01):** `KickAnEgg_PremiumPets` for the new joints: the lion's Mane bone (9
    bones, 16 meshes); the titan's HeartHands and Gear1-7 now come from the model's own joints. This also fixes a UV
    bug that rendered the titan's brass arms as dark iron. All three re-imports validate, with 0 texture/colour
    mismatches.
  - **Not done:**
    - unique motion and effects for the remaining pets.

- **Frost Serpent replaces the Ice Dragon (2026-10-27, Partner A, branch `a/frost-serpent`).**
  - Pair 23 (Legendary, Snowy Peaks): new pet and egg, modelled in Blender from Roblox primitives only and baked to block data
    (`Builders/Models/Premium/FrostSerpent.luau`, source `assets/blender/FrostSerpent.blend` + `tools/blender/frost_serpent`).
    Rule 3 holds: no meshes. The old `Premium/IceDragon.luau` is removed.
  - `a/frost-serpent` ships it under the model key `IceDragon` without touching `Config`. The stacked `contract:` PR
    (`a/frost-serpent-rename`) renames it to "Frost Serpent" / `FrostSerpent` in `Config/Pets`, the zone files, the recipe
    and the hero test lists. The pet id stays `ice_dragon`, so saves are untouched.
  - VFX (`VFX/PetFx`): six original sprites (`assets/pet-vfx/vfx_frost_*.png`, uploaded; Image ids in `PetFx/Sprites`). PetFx
    `emit` layers can now be timed bursts (`every`, `count`, `sync`) and aim with `dir` (the pet's frost-breath special).
  - Animation: `Anim/Pet` serpent poses for rigs with a `Coil` joint, `Rig.poseAbout`, and pupils blink with the eyes.
  - Verified this session in Studio: the hero-ladder/shell/recipe checks of `ServerTests` re-run by hand (57/57, pet 170 parts
    between Tide Spirit 85 and Quetzal 175). Single-player Play: a placed pet roams the pen with its effects and serpent idle, and
    a plot egg hatched into the pet. No new script errors. Full `tools/run-tests.sh` was not run (no run-in-roblox on this machine).

- **`main` is the assembled game (2026-10-20, Partner B).**
  - `codex/reactive-tutorial` @ `7930391` was merged into `main` in #50 (merge commit `dc07045`, no conflicts). `main` now contains:
    - Partner A's `a/full-build` (#42–#49);
    - all of Partner B's game code (#37–#41);
    - the Codex tutorial, pen feedback, Shift Lock, shop label and podium work.
  - Start new work on feature branches from `main`. The older entries below that say "continue from `codex/reactive-tutorial`" are history.
  - **Verified on `7930391` by Partner B:**
    - the fresh-clone Rojo build matches the accepted SHA-256 `c6b677aa…0cf6`;
    - in single-player Studio Play the map builds in 0.90 s, with 18 services, 19 controllers and no game script errors;
    - tutorial welcome → objective → dimming → hotbar arrow and the REPLAY row work;
    - 6 podiums, Shift Lock, shop labels and pen feedback are present.
  - **Unit tests:** 364 pass and 4 fail. The failures are outdated test rules, not game errors. Partner B will update them next:
    - three pre-remodel map checks (shop lights ≤ 4, pen reserve margin, `SafeZone.Decor`);
    - an audio check that only allows built-in Roblox sounds, while the pen-upgrade SFX is a verified Creator Store sound.
  - **Asset permissions:** Partner B's account can't load premium SFX sheets `78931796757748` (UI) and `117199061714759` (Sacks) in Studio ("not authorized"). Share them with the experience or Partner B.
  - **Not in `main`:**
    - `b/spin-wheel`'s last commit (`e379c0b`), an older duplicate of this handoff file;
    - closed `a/merchant-ids`;
    - old experiments `b/launch`, `b/training`, `contract/player-launch`, `contract/streaming`.
  - **Partner B workstation (Claude Code):**
    - 44 user skills (same upstream repos as `docs/CODEX_SETUP.md`);
    - Blender MCP `mcp-for-blender==2.2.2`, add-on protocol 14, telemetry off;
    - Studio's built-in MCP server;
    - Rojo 7.7.1 and `run-in-roblox` for `tools/run-tests.sh` and `tools/playtest/playtest.sh`.
- Partner rebuild investigation (2026-10-20): GitHub branch `codex/reactive-tutorial` was verified at `1a250b2`; GitHub's default `main` remained `5dac080` and does not select this assembled checkpoint. A fresh single-branch clone rebuilt successfully with pinned Rojo 7.7.1. Added reproducible standalone build and saved-tutorial replay instructions to README. Partner supplied no error/log or branch, so their screenshot's specific cause remains unconfirmed. No gameplay/source changes or automatic merge.
- Merchant animation rework canceled and discarded at the user's request on 2026-10-20. Restored the original merchant and MapLife sources; removed the experimental seated module, menu nod hook and its test suite. No merchant rework was committed or pushed, and no finished Blender animation was produced. Continue from `codex/reactive-tutorial`; the accepted tutorial and earlier completed features remain intact.
- Task complete: polished the tutorial arrow to match the approved red menu buttons, using the same red gradient, a 22% inset highlight and subtle lower shading. Preserved the exact alpha silhouette, tip alignment, bounce, thinner panels and Skip spacing. Uploaded the replacement image, rebuilt `outputs/KickTheEgg-ReactiveTutorial.rbxl`, and restored the clean single-player welcome preview. See `docs/ReactiveTutorial.md`.
- Branch: `codex/reactive-tutorial`, based on podium relocation `164cb63` on `codex/pen-upgrade-feedback`, itself based on setup commit `4aa9292` and combined game `origin/a/full-build` at `2f59bee` (character-animation merge, PR #49).
- Working directory: `C:/Users/kerem/Documents/Codex/2026-10-13/ca/work/kte-setup`.
- GitHub: current tutorial uses `codex/reactive-tutorial`; prior pen feedback, Shift Lock, shop labels and podium work remain on `origin/codex/pen-upgrade-feedback` at `164cb63`. Use the tutorial branch tip for the assembled revision. No PR or automatic merge is created.
- Existing Claude worktrees remain intact. `kick-an-egg` has untracked `tools/icons/icons2d.py`; `kte-anim` has untracked `build/`. Do not discard them.

## Completed and changed
- Reactive tutorial: shared pure Rules, authoritative TutorialService observers, persisted training/pen facts, rewritten contextual client controller, reusable real-control spotlight/world guide/objective modules, six actual SVG/transparent PNG assets uploaded under existing verified creator, and local replay from Settings. Main completion requires the first placed pet and brief income explanation; upgrades are optional. Existing gameplay and shared remote/config contracts are unchanged.
- Added six podiums in `Builders/Map/Boards`, adjusted board height and moved Donate beside the bronze podium with a 2.6-stud gap. `Services/LeaderboardService` now feeds its same top-three entries into `Util/LeaderboardPodiums`. Native appearances use private WorldModel assembly, bounded caching and stale-request rejection. `Util/PodiumEmotes` loops only actually equipped emotes via their resolved catalog Animation assets. `Controllers/LeaderboardDisplayController` adds locally faded nearby medal badges. See `docs/LeaderboardPodiums.md`.
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
- Fresh GitHub checkout rebuild (2026-10-20): `1a250b2` cloned into `work/kte-github-rebuild-1a250b2`; `rojo build default.project.json --output outputs/KickTheEgg-GitHub-Rebuild.rbxl` succeeded (output is outside the repo). Its SHA-256 matches the accepted `outputs/KickTheEgg-ReactiveTutorial.rbxl` exactly: `c6b677aae5db271a7b16e77fe04b30a6d442f9d5a9da730dd3f8c7a836fb0cf6`. Deserialization against the fresh clone confirmed 298 scripts, 2369 models, all 17 relevant sources current/compilable and no QA probes. Source inspection confirms completed/skipped accounts can use Settings → Tutorial → REPLAY. No new Studio playtest was performed; earlier runtime evidence below is inherited.
- Cancellation cleanup (2026-10-20): merchant/MapLife sources match the accepted checkpoint; experimental module/hooks/probes are absent. Removed a saved temporary `PetMerchantBlenderExport` model by rebuilding the accepted `outputs/KickTheEgg-ReactiveTutorial.rbxl` from the unchanged game source. Binary verification passed: 298 scripts, 2369 imported models, 17 relevant sources current/compilable, original merchant/MapLife sources, no experimental module or export helper. Studio is not connected. No gameplay tests rerun for this restoration/documentation-only update; reports below are inherited. `outputs/KickTheEgg-SeatedMerchant.rbxl` was a rejected prototype, not a deliverable.
- Menu arrow finish after `27589c0`: 512px RGBA export has a pixel-identical alpha channel to the preceding arrow (bounds 62,102–430,410), preserving the measured tip extent. Decal 75841806699966 resolves to image 113118779959499; actual client IsLoaded and native hotbar rendering passed. A temporary production WorldGuide/Objective preview visually confirmed the world arrow beside the same red Skip button. Preview discarded; clean single-player welcome restored. Targeted StyLua/diff and rebuilt binary verification passed (298 scripts, 2369 models, 17 relevant sources current/compilable, no probes). No gameplay, responsive-suite or route retest for this artwork-only change; reports below are inherited.
- Destination alignment: 126 native presentation checks passed, including both inset modes, near/far tip alignment, all edges and stable bounce orientation. Native training reached kick-line guidance; the corrected marker was visually reviewed. Moving-camera trace: 132 frames, 0.9997px maximum sideways error, 8.18–16.97px tip gap; camera restored afterward. 60 decision / 36 route checks and targeted formatting/diff/binary verification passed (298 scripts, 17 relevant sources, no probes). No full-loop or physical-device/multiplayer retest for this fix; older reports below are inherited.
- Small visual refinement: 111 native presentation checks passed across desktop/phone component sizes, including nine real hovered-button clearance checks. Representative visible gap: 5.21px at 1.035 hover scale; 48px tap height preserved. Panels 4px / buttons 3px, objective +8px height with bottom-anchored progress. Simpler arrow decal 128419627869618 resolves to image 82798776261686, loaded and visually reviewed in Studio. Targeted formatting/diff and rebuilt binary verification passed (298 scripts, 17 relevant sources, no probes). No route/gameplay/full-loop retest for these art/layout-only changes; older results below are inherited.
- Arrow/dimming follow-up: 102 native presentation checks passed, including mask coverage/click-through geometry, safe-area projection, UI/world bounce, Reduced Motion and cleanup. Uploaded FocusArrow under verified user 1340874349; decal 130821505800543 resolves to image 97161043303033 and loads/renders in Studio. Native hotbar selection through dimming, transition to unmasked world guidance and a hatching-egg world-arrow preview passed. 60 decision / 36 geometry checks, targeted formatting/diff and rebuilt binary verification passed (298 scripts, 17 relevant sources, no probes). No full-loop, physical-device, multiplayer or published permission retest this follow-up; older results below are inherited.
- Current focused UI fixes: 81 native presentation/layout/masking checks passed at 844x390, 390x844 and 320x568; no tutorial ImageLabels/ImageButtons. Native Continue and three real training hits passed. An in-memory early Sprout Pup egg fixture used real tool sync; its real hotbar click led to pen guidance, real-speed walking, native placement, normal hatching, pet rendering/income and automatic HUD restoration. Replay welcome Skip restored exact HUD roots and preserved saved completion. Red route trace: 600 frames / 68 moving / zero stale frames, 2.95-stud minimum forward lead. Fresh launch/cinematic masking recovery passed. 60 decision and 36 geometry checks, targeted StyLua/diff and binary verification passed: 298 scripts, 17 relevant sources current/compilable, no probes. No full kick/chase loop, physical-device or published persistence retest this revision; older full-loop evidence below is inherited.
- Approved-menu restyle: Welcome/Objective use shared Ui/Theme studded dark panels, striped cyan headers, outlined white text, lime Continue and gray Skip/Later buttons, approved icons and progress bar. Real Shop reference and new panels visually inspected. All 177 desktop/phone component layout checks passed, plus native Continue/training/Skip/replay. ZoneProgress measured 16px below the objective and y24 without it. Current binary: 296 scripts, 14 relevant UI/tutorial sources current/compilable, no probes. No route/full-loop retest for this presentation change; those results below are inherited. Same Studio file updated; single-player welcome preview ready.
- Welcome/route revision: 36 new geometry checks and 60 existing decision checks pass; native welcome/Continue, welcome Skip, Settings replay and three real training hits verified. Twelve responsive welcome/header/touch-size checks pass. Ten-second walking trace: 599 frames, 442 moving, no stale arrow frames, minimum 2.76-stud forward lead. Blocked direct pen route used three validated walking segments / 35 markers with zero fence crossings. Current binary has 296 source scripts, all 13 relevant sources current/compilable, no QA scripts. The first-pet walkthrough and 294-script build below belong to the earlier tutorial revision. Same Studio deliverable updated; no multiplayer session. Details/metrics/reproduction: `docs/ReactiveTutorial.md`.
- Top-slot follow-up: removed the unused Quest/Eggs secured banner from UI construction/updates; tutorial moved to 24px desktop / 4px compact within the safe area. Fresh single-player Studio verified banner absence, tutorial position, native training/data updates and 20px toast clearance. Targeted StyLua/diff and rebuilt binary verification passed; no full walkthrough rerun for this layout-only change. Same Studio deliverable updated, no QA probes packaged.
- Tutorial: 60 decision/counter, 45 responsive component layout and five saved-fact sanitization checks passed. Native walkthrough reached a rendered pet and real income in 102.28s without a purchase/reward. Native skip/replay, partial-training respawn and early-egg HOLD/pen guidance verified. Six PNGs load. Final clean Play has 18 services/19 controllers and no tutorial errors. Rojo binary: 294 source scripts, nine tutorial sources current/compilable, no QA scripts. Studio has a clean single-player preview; NumberOfPlayers remains 0. Physical device, multiplayer and published reconnect/permission tests remain pending. Details: `docs/ReactiveTutorial.md`.
- Entries below are inherited results from the preceding podium/shop/pen revisions, not fresh reruns for the tutorial.
- Donate relocation: all 24 server checks passed again with the updated lateral-clearance assertion. Measured 2.6 studs between the Donate trim and bronze cap, zero forward offset and no nearby collidable scenery blocking the stand. Six populated podiums visually reviewed with Donate on their right. Rebuilt the same Studio deliverable; no multiplayer test. The seven client emote/badge checks below are inherited from the preceding podium commit and were not repeated for this placement-only change.
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
1. Review `codex/reactive-tutorial` and `outputs/KickTheEgg-ReactiveTutorial.rbxl`. Do not merge automatically.
2. Validate on physical mobile/gamepad and a published test server, including reconnect and simultaneous players. This tutorial used single-player Studio, component phone-size previews and recovery fixtures; no multiplayer or native iPhone simulation was run.
3. Prior checkpoints: `a127074`, `9c43b00`, `ca7f62f`, `c02e28c`, `1ffaf24`, `f372b4c`. The user authorized committing the changes to the repository; the feature branch was pushed successfully to `8yfy/kick-an-egg`. Review that branch before merging. No PR or automatic merge was created.
4. Blender is configured but not needed for this feature. Before future modeling, connect the existing add-on and inspect the live scene.
5. Preserve inherited animation follow-ups above; they are outside this feature's scope.
