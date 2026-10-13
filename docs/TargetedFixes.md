# Targeted fixes & premium kicking polish: report (branch `b/kick-polish`)

The checkpoint before any change is git tag **`checkpoint/before-targeted-fixes`** (pushed).

**How everything was verified**

| Suite | Result |
|---|---|
| Server logic (`sh tools/run-tests.sh`) | **311 / 311** |
| UI smoke, every screen built headless (`… UiSmoke.server.lua`) | **33 / 33**, 0 images missing |
| Progression report (`… Progression.server.lua`) | **0 failures** |
| Live Studio Play session, real engine (`sh tools/playtest/playtest.sh`) | **136 / 136** |
| Visual renders: Settings, Speed tab, kick UI, rail (desktop + phone) | checked by eye |

**Status words:**
- **Verified**: tested by the suites above.
- **Needs Studio check**: works in tests, but feel, look or a manual Studio step remains.

## Phase 1: functional bug fixes

| Item | Status | What / why |
|---|---|---|
| Pet invisible after hatching | **Verified** | **Root cause:** the client played `HatchBurst` (an effect meant for the egg) on the new pet model. That effect hides its target with `LocalTransparencyModifier = 1`, so every fresh pet was invisible until a pickup + place rebuilt it. **Fix:** it now only hides egg models. Live: hatched pet, 25–40 visible parts, 0 hidden. The server path (save first, then the model, one path for hatched and placed pets) was already shared. |
| Eggs / pets in the Roblox Backpack | **Verified** (mouse) / **Needs Studio check** (touch, gamepad) | **Tools:** `PlotService.syncTools` keeps one Tool per inventory egg and per stored pet in the Backpack. The server creates and removes them from the save (`DataService:OnChanged`, respawns), so there are no duplicates. The held model is built only while the Tool is equipped.<br>**Placing:** hold a pet like an egg, see the green/red ghost, place exactly there (the server checks the held pet, your reach and your pen).<br>**Hotbar:** Roblox's hotbar is back on. The Kick Sack lives outside it (`Player.SackGear`, server `EquipSack`) on its own quickslot, now on **Q** (gamepad Y).<br>Live: the egg and the stored pet show in the Backpack, placing at a chosen spot works, the Tool goes once placed, and after a respawn every item comes back once. |
| Settings overlap / scrolling | **Verified** | The options are a padded `ScrollingFrame` (mouse wheel, touch, scroll bar inset). The title bar and X stay fixed and the last row is fully inside the window. A gamepad starts on the first option. All options are kept: Sound, the volume rows (UI / Gameplay / Ambience / Music / Special effects), Camera shake, Low detail, Sack effects, Reduced motion. Rendered on desktop and on phone (scrolled to the bottom). |
| Pen owner display | **Verified** | Only the avatar headshot and the username, high above the pen centre (22 studs), sized in studs so neighbouring pens don't pile up, with a distance limit. Free pens show nothing (no FREE PEN). |

## Phase 2: balancing (all numbers in `Config/*`, contract commit `d19360d`)

| Item | Status | What |
|---|---|---|
| Unlimited Speed | **Verified** | `speed = 16 + 8·ln(1 + level/20)` with no level cap: every level adds speed, a little less each time. A safety ceiling of 120 studs/s is only reached around level 10 million. The price is `25·(level+1)²`, finite and whole. **Shown on the Speed tab:** current → next speed (with enough decimals that they always differ), level, price, and a bar of your cash toward the price; no MAX / TOP SPEED, and the phone layout no longer overlaps. Live: bought level 121 → 122 (exactly 372,100) and 10,000 → 10,001, both faster. |
| Avalanche speed by zone | **Verified** | 12 studs/s in zone 1 → 23.7 in zone 10 → **44** in zone 20 (was 36), independent of your Speed. The progression report lists the Speed level each zone needs: zones 1–6 need none, zone 15 needs level 124, zone 20 needs 533. Each zone is faster than the one before and none is impossible. |
| Integer Kicking Power into the trillions | **Verified** | **Sacks:** gains are whole numbers from +1 (Burlap) to +20B (Rainbow God), ×(1 + rebirths). No caps; only the exact-integer ceiling of 9 quadrillion (2^53−1) stops it, so trillions are exact.<br>**Distance:** follows the **log** of power, 160 studs per ×10. About 10 Power reaches zone 2, 1M zone 10, and 1T zone 20. A Perfect kick adds 12% distance.<br>**Training:** about 60 kicks per zone with that zone's sack.<br>**Rebirth:** needs 1M, 10M, 100M… Power.<br>**Display:** the HUD shows whole abbreviated numbers ("POWER 2.5T", verified live), and a real sack kick adds exactly its whole gain (verified live). |
| Existing saves (v3 migration) | **Verified** (unit) | Your choice: every player's Power is converted so their Perfect kick lands where it did before. Their Speed level is converted so they keep their speed. Nothing is lost. |
| Upgrade UI text | **Verified** | The sack cards read "+N Kick Power per kick" (no "up to"), and the older Store / Rebirth windows no longer mention a cap. |

## Phase 3: the kick

| Item | Status | What |
|---|---|---|
| New kick UI art | **Verified** | The 5 supplied PNGs were resized to Roblox's 1024 px limit and uploaded to Krono808 (Image ids, asset type 1):<br>• `kick_auto` 133970296249456<br>• `hud_trade` 103666995924889<br>• `kick_meter_track` 114311291241712<br>• `kick_meter_fill` 133073599038746<br>• `kick_meter_frame` 109486048637563<br>No other icons were changed. |
| One-bar meter | **Verified** | The track sits behind; the single tintable fill is clipped over the art's own span and coloured by the real timing bands (Miss → Perfect, the server's thresholds); the frame sits on top. No second bar. A flash plays when you lock it. |
| Auto Kick | **Verified** | The supplied art with no added outline. OFF is dimmed; ON is full colour with a gentle pulse. A small ON/OFF chip sits beside it, not over its lettering. |
| Tap / click anywhere | **Verified** (wiring) / **Needs Studio check** (by hand) | **Window:** a global listener exists only while the meter waits; it disconnects the moment timing ends. **Ignored:** GUI-consumed input (Settings, close buttons, menus) and any open window or the Roblox menu. One lock per attempt, with a 0.15 s guard against the KICK click itself. **Other inputs:** E / Enter, gamepad R2 / X. |
| Mystery egg remodel | **Verified** | A full egg size (3.4 studs + gem), black, with a big raised gold "?" on dark plates on both faces, a neon band with gold rivets, and a gold cap with a gem. It is held between both hands (live: 1.57 studs from each hand) with the hold animation, and removed or restored when you step on or off the pad. |
| Cinematic kick (animation + camera + VFX) | **Verified** (animation, camera, VFX fire at contact) / **Needs Studio check** (feel) + **one publishing step** | **Animation:** `Anim/EggKick` is an original keyframed full-body clip on 13 R15 joints: toss, wind-up twist, coil, strike, hit-stop, follow-through, recover. The contact frame is the server's launch (`LAUNCH_DELAY` 1.0 s), and the egg is tossed onto the foot. Live: the hip reaches 128° at contact.<br>**Camera:** your camera goes low-angle → side → impact close-up, then blends into the flight camera. Reduced Motion or Auto Kick keep one steady camera. It is restored if interrupted.<br>**VFX:** burst, ground shockwave, speed streaks, flash and a small shake, all sized by Weak / Good / Perfect (Perfect adds a second ring). |

## Phase 4: tutorial

| Item | Status | What |
|---|---|---|
| Show-don't-tell tutorial | **Verified** (flow, guidance objects) / **Needs Studio check** (feel on phone / gamepad) | **Guidance:** a ground trail of dots and a small arrow to where to go, a soft Highlight on the real thing (pad, held egg, placed egg, pet), a glow on the one HUD element that matters, and a brief "More POWER = farther kicks" during the first flight.<br>**Text:** one short prompt chip (e.g. "Go to the kick line") replaces the big banner.<br>**Hidden** during your kick cinematic.<br>**Progression** comes from real server-side actions (saved, skippable, survives reconnecting, no softlock). Live: steps 1 > 2 > 4 > 6 > 7 > 8 > done. |
| Trade artwork | **Verified** | The supplied art is the whole TRADE button (under REBIRTH) with no typed label over its lettering. On phones it's a readable pill. |

## Remaining Studio work / missing IDs

1. **Publish the two animations** to play them as Animator tracks on live servers. Until then, live servers play the identical keyframes directly on the joints, and Studio already uses real Animator tracks (registered KeyframeSequence).
   1. In Studio's command bar, run `require(game.ReplicatedStorage.Shared.Anim.EggKick).buildKeyframeSequence().Parent = workspace`.
   2. Right-click the new `EggKick` → **Save to Roblox**.
   3. Do the same with `buildHoldSequence()`.
   4. Put the two ids in `EggKick.PUBLISHED = { kick = "rbxassetid://…", hold = "rbxassetid://…" }` in `src/shared/Anim/EggKick.luau`.
2. **Play it by hand once:**
   - the feel of the kick cinematic;
   - tap-anywhere on a real phone and a controller;
   - the Backpack hotbar on touch and gamepad.
3. **Image ids:** none missing (all 5 uploaded and wired).

## Files

**New:**
- `src/shared/Anim/EggKick.luau`
- `docs/TargetedFixes.md`

**Changed:**
- **Server:** `DataService`, `PlotService`, `SackService`, `KickService`, `UpgradeService`.
- **Contract:** `Config/Economy`, `Config/Upgrades`, `Config/Chase`, `Remotes` (`EquipSack`).
- **Client controllers:** `KickLine`, `Flight`, `Placement`, `PenOwner`, `Tutorial`, `Sack`.
- **UI:** `KickPanel`, `Rail`, `Drawers`, `SackSlot`, `SackGear`, `SettingsMenu`, `TrainingShop`, `StoreMenu`, `RebirthMenu`, `Rebirth`, `Data`, `AssetIds`.
- **Shared:** `VFX/{Egg, Hatch, Shake}`, `Builders/Models/MysteryEgg`, `Audio/SoundBank`.
- **Tools:** tests, the playtest and the preview.

## Performance

- Backpack Tools carry only a handle; the held model is built on equip.
- The tap listener exists only during timing.
- The tutorial trail is 12 reused parts, hidden when not needed.
- The kick cinematic uses one render binding, removed right after.
