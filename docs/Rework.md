# Gameplay rework: final report (branch `b/gameplay-rework`)

This branch implements "KICK AN EGG — complete bug fixes, gameplay rework & polish".

**Status legend**
- **FIXED**: the code changed and was verified, either by an automated test or by a live Studio Play session (`tools/playtest`).
- **NEEDS STUDIO TESTING**: implemented, but a part can't be verified from here: a real device, several players, or feel.
- **BLOCKED**: needs an ID or asset from you (listed at the end).

## How it was verified

| Suite | Command | Result |
|---|---|---|
| Server logic | `sh tools/run-tests.sh` | **250 passed, 0 failed** |
| UI smoke (every screen built headless) | `sh tools/run-tests.sh tools/tests/UiSmoke.server.lua` | **32 passed, 0 failed, 0 runtime errors, 0 images missing** |
| Progression report | `sh tools/run-tests.sh tools/tests/Progression.server.lua` | **0 failures** (table below) |
| Live Play session (server + real client) | `sh tools/playtest/playtest.sh` | **79 passed, 0 failed** |
| Sack VFX parity, showroom vs gameplay | `tools/perf/SackParity.server.lua` | identical for all 20 tiers |

What the live playtest does:
- **HUD:** TRADE sits under REBIRTH, no Training button, the quickslot is there, and the meter has a fill and no indicator.
- **Map:** 6 pens, no stands, and your owner card shows your headshot and `@username`.
- **Kick line:** the mystery egg is in your hands on the pad, goes when you step off, and leaves your hands at the kick.
- **Kick and flight:** the kick and its `KickAt` cutscene stamp, then the zone bar.
- **Chase:** steering the egg home through the real ControlModule. It checks that:
  - your character is hidden and the camera follows the egg;
  - `EggSecured`, then `ChaseEnded` 0.01 s later;
  - the egg model is gone and the egg is in the inventory exactly once;
  - the character and the camera come back.
- **Egg to pet:**
  - hold the egg as a Tool and see the ghost;
  - placing outside the pen is refused, placing inside works, and a repeated request creates no duplicate;
  - the egg hatches and the pet model loads;
  - the pet roams and earns by itself;
  - the Pick Up prompt stores it, a stored pet earns nothing, and PLACE puts it back.
- **Tutorial:** steps 1 > 2 > 4 > 6 > 7 > 8 > done.
- **Shop and merchants:** the shop prompt opens the existing sack screen, and the merchants are Humanoid avatars.
- **Quickslot:** out/away and its glow.
- **Shift Lock:** the camera probe.
- **Sack VFX LOD:** Full up close and Disabled far away.

## Status per item

### Phase 1 — critical gameplay bugs

| # | Item | Status | What changed / root cause |
|---|---|---|---|
| BUG 2 | Pets don't load after hatching | **FIXED** | **Root cause:** one shared hatch/income loop with no protection, so an error for one player (a failed model build) stopped hatching for everyone. **Fix:** the pet is saved first and its model built second; the build is in a `pcall` and retried; each player runs in their own `pcall`/`xpcall`. Tested: all 79 pets build, and live, hatch → the model loads at once. |
| BUG 9 | Character visible in egg mode | **FIXED** | `ChaseController.hideCharacter/showCharacter` sets local `Transparency` on every client for parts, decals, accessories, the name tag and trails. It restores the saved values and is safe across respawns. Live-tested both ways. |
| BUG 10 | Running animation while the egg stands still | **NEEDS STUDIO TESTING** | `Anim/Egg` EggRun is now driven by the hitbox's planar speed: start above 1.2 studs/s, stop below 0.5, smoothed and blended. Idle plays otherwise. The playtest doesn't assert on the animation. |
| BUG 8 | Eggs land on walls or between zones | **FIXED** | `KickService.landingPoint` raycasts only against surfaces tagged `LandingSurface` (lanes and the ramp; `MapBuilder` tags them). The distance is clamped to `trackEnd − Chase.Landing.endMargin`, and X is kept `edgeMargin` inside the runway. Covered by unit tests; live landing in zone 5. |
| BUG 7 | Avalanche spawns outside its zone | **FIXED** | `Chase.avalancheStartZ(landZ, landZone)` keeps the start inside the landing zone and the map (`endMargin`) and at least `spawnMinBehind` behind the egg. Unit tests cover every zone, including the last. |
| BUG 11 | Avalanche lingers at the finish | **FIXED** | `ChaseService.secure` fires `EggSecured`, then `ChaseEnded` at once. `finish` is idempotent and `lose` is guarded by `resolved`. Live: `ChaseEnded` arrived 0.01 s after `EggSecured`. |
| BUG 12 | Egg model disappears too late | **FIXED** | The egg is released immediately on secure, and the burst plays at the secure position. Live: the model was gone within the check window. |
| — | Found by the playtest: the steered egg stalls in front of the kick pad | **FIXED** | **Root cause:** the kicker waits on the pad (hidden but still solid), right on the egg's path home, so the egg stopped at the top of the ramp until the avalanche caught it. **Fix:** collision group `Eggs` no longer collides with `Players` (`MapBuilder.setupCollisionGroups`). Covered by a unit test; live, the egg ran home at 48 studs/s with no stall. |
| BUG 6 | Shift Lock snaps the camera onto the sack | **NEEDS STUDIO TESTING** | No script sets `CameraSubject` or `CFrame` onto a sack. **Root cause found:** `VFX/Shake` left its rotation in the camera's CFrame, so the next camera update built on the shaken CFrame and the camera drifted or snapped under Shift Lock. **Fix:** the shake is now undone at `RenderPriority.Camera − 1`. The playtest probe (with the sack out and during a shake: 0.0° snap, 0.00° drift, subject stays the Humanoid) reproduces what Shift Lock does to the character (`RotationType = CameraRelative`). Real Shift Lock can't be switched on from a script (RobloxScript only), so press Shift once by hand with the sack out. |

### Phase 2 — pets and inventory

| Item | Status | Notes |
|---|---|---|
| Free-roaming pets (Idle / Wandering / Returning / Stored) | **FIXED** | **Server:** one scheduler (every 0.25 s) picks spots and writes `PathFrom`, `PathTo`, `PathStart` and `PathEnd` on the model. **Clients:** one `RenderStepped` moves every pet (no per-pet loops), with distance and view LOD and Waddle/Idle animations. A pet stops and idles while its owner stands within 10 studs, so it can't walk out of its Pick Up prompt mid-hold (found by the playtest). Live: it moves, and it idles when you are close. |
| Passive income | **FIXED** | Credited by the server every 1 s straight into money, carrying fractions. No collecting, and stored pets earn nothing (live-tested). The Index milestone bonus applies. |
| Pick up + inventory | **FIXED** | **Pick up:** an owner-only `ProximityPrompt`. The server checks ownership and reach (16 studs from its server position), then saves the pet as stored. **Inventory:** the drawer lists every pet with name, image, rarity, earnings, mutation, IN PEN / STORED and a PLACE button. Live: pick up, then PLACE. |
| Finished eggs as placeable Tools | **FIXED** (mouse) / **NEEDS STUDIO TESTING** (touch, controller) | **Holding:** HOLD in the Eggs drawer → `EquipEgg` → an "Egg" Tool with the egg welded to it. **Placing:** a green/red ghost (`PlacementController`); `PlaceEgg(uid, pos)` is validated (you hold it, it's yours, within reach, inside your pen, not too close, room left). **Safety:** unique ids and no duplicates on repeated requests (live-tested). |
| 6 pens | **FIXED** (map) / **NEEDS STUDIO TESTING** (7th player) | **Map:** `MapBuilder` builds 6 pens (`MapBuilder.PenCount`). **Full server:** a 7th player waits (`PenWaiting` + an announcement) and gets the next free pen. **Saves:** pen-local x/z, so any pen works. **To do:** set **Max Players = 6** in Game Settings. |
| Pen owner display | **FIXED** | `PenOwnerController`: a BillboardGui card with an `rbxthumb://type=AvatarHeadShot` photo, display name and `@username`, plus FREE PEN and an initial fallback. The owner shields and signs are removed. Live: `@Krono808` and the headshot showed. |

### Phase 3 — economy and progression

| Item | Status | Notes |
|---|---|---|
| Kicking Power rebalance | **FIXED** (formulas, tests) / **NEEDS STUDIO TESTING** (feel) | **Root cause:** every sack trained toward the global cap, and rebirths multiplied both income and distance by 1.5 each, so one rebirth skipped most zones. **Fix:** each sack now trains only up to its own `cap` (`Economy.sackCap`, which scales with rebirths), and gains go 0.07 → 0.30. Rebirths add +10% distance (`distancePerRebirth`). Saved power is never lowered (`SackService.trained`). All in `Config/Economy` and `Config/Upgrades`. |
| Unlimited Speed levels | **FIXED** | **Speed:** `runSpeedAt(L) = 16 + 32·(1 − 2^(−L/30))` approaches 48 studs/s and never passes it. **Price:** `speedCost(L) = 100·1.35^min(L,120)·(1 + 0.05·max(0, L−120))`, capped at 1e300, so it's never inf or NaN. **Saves:** the level is saved (`speedLevel`) and the server validates purchases. |
| Avalanche speed by zone | **FIXED** | `Chase.Avalanche.speedCurve` goes 12 → 36 studs/s (exponent 1.2). It always stays below the speed cap, so no zone is impossible; Progression checks every zone. |
| Index completion rewards | **FIXED** | **Rewards:** at 10 / 25 / 40 / 60 / 79 pets: $2.5K, $75K, $1M, $50M, then $1B plus a permanent +10% pet income. **Server:** `IndexService.ClaimMilestone` grants it, saves it in `indexMilestones` and refuses a double claim. **UI:** the Index has a COMPLETION REWARDS panel and the rail badge counts them. Existing players qualify from their `discovered` list. |

**Progression** (`Progression.server.lua`; landing mid-zone, perfect kick, 0 rebirths):

| Zone | Power | First sack that reaches it | Training kicks (min) | Sack prices | Avalanche (studs/s) | Run Speed level (speed) | Level prices |
|---|---|---|---|---|---|---|---|
| 1 | 1.4 | Burlap (1) | 6 (0.1) | 0 | 12.0 | 0 (16.0) | 0 |
| 5 | 12.5 | Pro Red (4) | 142 (1.4) | 1.6K | 15.7 | 0 (16.0) | 0 |
| 10 | 26.4 | Silver Knight (8) | 263 (2.6) | 65K | 21.8 | 7 (20.8) | 2.0K |
| 15 | 40.3 | Crystal Geode (11) | 354 (3.5) | 1.02M | 28.6 | 20 (27.8) | 115K |
| 20 | 54.2 | Toxic Barrel (15) | 428 (4.3) | 41.5M | 36.0 | 39 (35.0) | 34.6M |

How to read the table:
- Money, not kicking, is the gate.
- A *missed* kick (×0.85) needs about 96 power to reach zone 20, so the last sacks (up to Rainbow God, cap 100) buy consistency.
- Speed levels 50 / 75 / 100 give 37.9 / 42.3 / 44.8 studs/s.
- Rebirths raise every cap by 25%.

### Phase 4 — Kick Sack system

| Item | Status | Notes |
|---|---|---|
| Sack VFX: showroom vs gameplay | **FIXED** | **Root cause:** `SackVFX.Attach` changed the shared `SackAura.Quality`, so the last sack attached lowered every other sack's effects. Streamed-in map sacks were also never re-registered. **Fix:** a per-sack profile, and `MapLifeController` tracks `DescendantAdded`. Parity test: the same effects for all 20 tiers; LOD is unchanged (Full up close, Disabled far away, live). |
| Bottom Kick Sack quickslot | **FIXED** (mouse/keyboard) / **NEEDS STUDIO TESTING** (touch, controller) | `UI/Hud/SackSlot`: the current sack's own art for all 20 sacks, key [1] or (Y), tap on touch, a gold glow when out, a pop on upgrade, and it moves beside KICK on the pad. Survives respawn. Live: out/away and the glow. |
| Remove obsolete sack stands | **FIXED** | `SackStand`, `RackSign` and the rack refresh are removed from `MapBuilder`. Live: 0 stands. |
| Merchants as real Roblox avatars | **BLOCKED** (UserIds) | **Built:** `MerchantService` replaces each merchant with `Players:CreateHumanoidModelFromDescription(GetHumanoidDescriptionFromUserId(id))`. A failed fetch falls back to a default HumanoidDescription, so the shop never breaks. **Missing:** `src/server/Data/MerchantConfig.luau` has `UserId = 0` for both merchants (no IDs were invented). Live: 2 Humanoid merchants. |
| SFX overhaul | **REPLACED** by the sound design rework (see `docs/Audio.md`) | The first version still layered the built-in explosion (thunder) into kicks and sack punches. That is fixed: all sounds now come from `Audio/SoundBank`, are verified by unit tests, a live playtest and offline renders, and thunder is used only for storms / electricity. |

### Phase 5 — UI and polish

| Item | Status | Notes |
|---|---|---|
| TRADE HUD button under REBIRTH | **FIXED** | **Button:** a rail button that opens the existing Trade window (same backend), with drawn arrows as its icon. **Removed:** the Trade button in the Pets drawer. Verified by the UI smoke test and live. |
| Single kick meter | **FIXED** | The separate indicator is removed. The meter art's fill is clipped and tinted by strength (`METER_COLORS`). Live: there is a Fill and no Indicator. |
| Show-don't-tell tutorial | **FIXED** (flow) / **NEEDS STUDIO TESTING** (phone layout) | **Server:** `TutorialService` works out the step from real data, so it can't softlock and it persists; a SKIP button is included. **Client:** `TutorialController` shows a banner, a world arrow and a glow on the HUD element to use. **Order:** UPGRADE comes after the first income, because a new player can't afford anything before that. Live: 1 > 2 > 4 > 6 > 7 > 8 > done. |
| Mystery "?" egg at the kick line | **FIXED** | `Builders/Models/MysteryEgg`: a black shell, a neon band, a gold 9-block "?" and a light. `KickLineController` shows it in your hands only on the pad and never in a chase. Live: shown on the pad, gone off the pad, gone at the kick. |
| Custom kick cutscene + impact VFX | **NEEDS STUDIO TESTING** (visual) | **Sequence:** a hold pose, the toss, then the front kick (`PlayerAnim.kickPose`), timed so the foot lands at the server's launch time (`KickAt`). **Impact:** burst, shockwave, sparks and the kick sound, plus a flash and a small shake for your own kick. **Options:** Reduced Motion skips the toss and the shockwave. Animations are procedural, so **no animation IDs are needed**. |

### Phase 6 — regression testing

**FIXED**: see the suites above. The new or extended tests cover:
- the v1→v2 save migration;
- the 6-pen map geometry and tags;
- landing and avalanche bounds;
- speed and price finiteness at levels up to 10⁶;
- sack caps;
- Index milestones, including a double claim;
- tutorial steps;
- the sounds;
- the mystery egg;
- merchants;
- all 79 pets building.

The live playtest covers the whole loop.

## Save data (migration v1 → v2)

`DataService.migrate` runs when a profile loads, before reconcile and sanitize. Nothing is deleted:
- **Pets:** `pets[*].slot` becomes `placed = true` plus pen-local `x, z`, using the old slot grid's position. Old `stored` cash moves into `money`.
- **Eggs:** placed eggs are re-keyed by uid and get `x, z`.
- **Speed:** `runSpeed` becomes `speedLevel = Economy.speedLevelFor(runSpeed)`, the lowest level at or above the old speed, so nobody gets slower.
- **New fields:** `tutorial` and `indexMilestones`, both empty by default. The tutorial step is worked out from the player's data, so an existing player starts at the step their progress implies: usually done at once, or UPGRADE if they have never upgraded. With no milestones claimed yet, existing players can claim every milestone they already qualify for.

Unit tests cover all of it, including a second migration run (no double payout).

## Performance

- Pets:
  - one server scheduler (0.25 s) and one client `RenderStepped` for every pet;
  - anchored roots moved by CFrame;
  - LOD by distance and view.
- Income runs on one 1 s server tick for all players.
- The kick line uses one `Stepped` connection for every character, and the pad check runs every 0.15 s.
- Sack VFX:
  - the LOD is kept;
  - map spinners use `BulkMoveTo`;
  - the shared-quality bug (every sack re-rendering at the wrong level) is gone.
- Sounds are pooled and idle loops stop on unequip.

## Files

**New:**
- **Client:** `src/client/Controllers/{KickLineController, PenOwnerController, PlacementController, TutorialController}.luau`, `src/client/UI/Hud/SackSlot.luau`.
- **Server:** `src/server/Services/{MerchantService, TutorialService}.luau`, `src/server/Data/MerchantConfig.luau`.
- **Shared:** `src/shared/Builders/Models/MysteryEgg.luau`, `src/shared/VFX/SackSfx.luau`.
- **Tools:** `tools/perf/SackParity.server.lua`, `tools/tests/Progression.server.lua` (replaces `Balance.server.lua`).

**Contract changes** (commit `contract: ...`):
- `Config/Chase`: avalanche bounds and speed curve, `Landing`.
- `Config/Economy`: Run Speed levels, sack caps, Index milestones.
- `Config/Upgrades`: sack `cap`, new gains.
- `Remotes`: `EquipEgg`, `PickupPet`, `PlacePet`, `ClaimIndexMilestone`, `SkipTutorial`; `PlaceEgg` now takes a position.

**Changed:**
- **Server services:** Chase, Data, Index, Kick, Plot (rewritten), Rack, Sack, Trade, Upgrade.
- **Client controllers:** Chase, Kick, MapLife, Plot (rewritten), Sack.
- **UI:** Drawers, KickPanel, Rail, StoreMenu, SackGear, PetIndex, TrainingShop, Data, Theme, `UI/init`.
- **Shared:** `Anim/Egg`, `MapBuilder`, `Merchants`, `VFX/{Egg, Sack, SackAura, Shake}`, `sackmodules/SackVFX`.
- **Tools:** the test and playtest scripts.

## Missing assets and IDs (what I need from you)

1. **Merchant UserIds.** Two Roblox UserIds, set in `src/server/Data/MerchantConfig.luau`:
   - `BoxingSackMerchant.UserId` (Boxing Sack Shop, "Coach");
   - `IndexMerchant.UserId` (Index, "Professor").

   Until then both use a default avatar.
2. **Custom sack sounds (optional; built-in sounds work now).** Uploaded audio asset IDs you own or that are free, set in `SackSfx.CUSTOM[tier]`:
   - per theme or per sack: equip, impact, special and upgrade;
   - for the premium sacks 13 / 18 / 19 / 20: an idle loop.
3. **Trade icon (optional).** A `hud_trade` PNG in the HUD art style. The button uses drawn arrows until then.
4. **Animation IDs:** none needed. All animations are procedural (Motor6D + CFrame).

## Remaining blockers and manual checks

- Set **Max Players = 6** in Game Settings → Places (the server also queues a 7th player).
- Press Shift by hand once with the sack out and kick (real Shift Lock can't be scripted).
- Test on a real phone and a controller: egg placement ghost, quickslot, tutorial layout.
- Check with 2+ players: pens and owner cards, others' hidden characters during a chase, the avalanche only catching its owner.
