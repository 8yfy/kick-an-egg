# Final HUD, kick UI and Boxing Sack Shop

Sources:
- `message (2).txt`, the final UI and Boxing Sack Shop spec;
- `Kick_An_Egg_Final_Approved_Icons_NoToolUI.zip`, the approved icons, which take priority;
- `Kick_An_Egg_MASTER_Claude_Handoff_v2.zip`, for the kick UI art, rating art, zone bar frames and zone labels.

Renders from Roblox Studio are in `docs/art/hud/`.

## What changed (existing systems reused, nothing duplicated)

| Area | Where | What |
|---|---|---|
| Approved icons | `UI/System/AssetIds` (`hud_*`) | Shop (egg basket), Index (open egg book), Rebirth, Eggs, Pets, Settings, Sound, Money, Power, used unchanged in the existing buttons |
| Left rail | `UI/Hud/Rail` | SHOP / INDEX / REBIRTH only; **no TRAINING button** |
| Tool UI | `UI/Hud/SackButton` deleted, `UI/SackGear` | **No SACK / Tool slot.** The sack is taken out with the new "Train" prompt on every base's sack stand (E/F, tap, gamepad) or key 1, and the Roblox hotbar stays hidden. The sack gear itself is unchanged. |
| Kick controls | `UI/Hud/KickPanel` | Contextual state machine (below) |
| Kick validation | `Shared/KickPad`, `KickService` | The server now rejects kicks from off the pad, using the same pad part as the HUD |
| Zone progress | `UI/Hud/ZoneProgress` (replaces `ZoneBar`) | Bar frames + zone label under the quest bar, reset per confirmed zone (below) |
| 2D animation | `UI/System/IconMotion` | Shop bob + shine, Index tilt, Rebirth sway (spin on click), Eggs rock, Pets hop, Settings slow turn (fast on click), Sound toggle pulse, Money pop on gains, Power impact on gains |
| 2D VFX | `UI/System/UiVfx` | Sparkle bursts, click impacts, shine sweeps, glow pulses, gradient flashes and celebrations (perfect kick, power up, zone change), from the supplied textures |
| Boxing Sack Shop | `MapBuilder` `sackShop` (replaces the Coach "Shop" stall by the spawn) | See the shop section below |

All animation respects Reduced Motion and only runs for elements on screen. Idle loops share one Heartbeat.
Effects use pooled or short-lived ImageLabels, with no RenderStepped decoration loops.

### Kick state machine (`KickPanel`)

- **hidden:** you're off the kick pad, in flight or in a chase, or have no character. No KICK, meter, hints or ratings.
- **idle:** inside `KickPad.SHOW_RADIUS`. KICK and AUTO KICK pop in with "Press KICK!", and KICK shimmers.
- **timing:** after KICK. The vertical strength meter appears with its supplied art (one frame per fill level) and a
  moving indicator frame, plus "Tap to Kick!". Locking the timing works with a tap or click on KICK or the meter,
  E or Enter, or gamepad R2 or X. After 6 s with no input it returns to idle.
- **result:** the supplied rating art plays (scale pop, colour sweep and VFX; Perfect gets a celebration and a
  flash). The kick goes to `Shared.KickPressed`, then `RequestKick`. The controls hide during the chase and come
  back only when you're on the pad and free.
- **Server bands unchanged** (`KickService.timingBonus`: perfect ≥ 0.9, good ≥ 0.6, otherwise weak). The six ratings
  only split those bands for display:

| Rating | Timing | Server band |
|---|---|---|
| Perfect | ≥ 0.9 | perfect |
| Excellent | 0.8–0.9 | good |
| Great | 0.7–0.8 | good |
| Good | 0.6–0.7 | good |
| Okay | 0.3–0.6 | weak |
| Miss | < 0.3 | weak |

- **AUTO KICK** is a session toggle with ON/OFF states. When on and idle on the pad, it starts the meter and releases
  at a random moment, so it never gives free perfect kicks. The game has no auto-kick product, so nothing is gated.
- On respawn or reset, the controls hide at once, with no half-finished meter left behind.

### Zone progress (`ZoneProgress`)

- **What it follows:**
  - your egg in flight, using the server's KickResult, the same path FlightController draws;
  - your chase egg (`workspace.Chases[eggUid]`) while you steer it;
  - otherwise your character.
- **Base:** hidden, so no stale zone text.
- **Confirmed zone change:** the new zone must hold for 0.1 s. A confirmed change bumps the revision, sets frame 1 /
  0%, pops the zone's label in, and plays a glow, sparkle and shine.
- **Same zone:** re-entering it or receiving duplicate updates never resets the bar.
- **Progress:** measured through the zone in the direction you entered it, and tagged with zone and revision.
  Reports for another zone or an old revision are ignored. There is no zone 21.
- **Frames:** Empty, Quarter, Half, Three-Quarter, Full; Rainbow fills the last zone. A % label sits on the bar.
- **Toasts:** they sit below the zone bar while it shows, and below the quest bar otherwise. The quest objective is
  untouched.

### Boxing Sack Shop

- **Building:** a studded red-and-white hall by the spawn, with a big "BOXING SACK SHOP" sign over an open entrance,
  gold lantern posts, a flat crenellated roof, boxing gloves on the walls and a blue mat floor.
- **Displays:** 6 of the 20 Kick Sacks hang on a display rack. They use their real imported models, each with a
  nameplate and a spot light. Clients add their idle VFX automatically (MapLife → SackAura).
- **Counter:** the Coach stands behind it. Its prompt ("Browse sacks", E, a tap or the gamepad button) opens the
  **existing** sack purchasing screen (`UI/Screens/TrainingShop`). Prices, requirements, ownership and buying logic
  are untouched, and closing the screen leaves you at the shop.
- **Alert:** a red "!" bounces over the shop sign when you can afford the next sack. It replaces the old Training
  button badge.
- **Kicking Power "+":** the button in the counters still opens that same screen. It's the power upgrade button the
  spec keeps; tell me if it should only point people to the shop instead.

## Test report

### Run here (headless Studio via run-in-roblox, plus Studio renders)

- **Server tests: 157/157.** New checks:
  - kick pad: on-pad accepted, 30 studs off rejected, no character rejected, HUD radius inside the server radius;
  - the shop exists, shows 6 sack models and opens the existing screen;
  - all 8 sack stands have the Train prompt.
- **UI smoke: 32/32, 0 runtime errors.** New checks:
  - no Training button and no SACK slot; the rail uses the approved icons;
  - the kick panel starts hidden off the pad, and every rating maps inside the server bands;
  - zone progress: a new zone resets to frame 1 / 0%, a same-zone duplicate doesn't reset, a late report from the
    old zone is ignored, there is no zone past 20, inbound progress works, and the Rainbow frame is used.
- **Studio renders** (`docs/art/hud/`):
  - the desktop and phone HUD on the kick pad;
  - the timing meter and the Perfect and Miss ratings;
  - the shop from outside and at the counter.
- **Tooling:** StyLua and luau-lsp are clean on all new and changed code; the Rojo build succeeds.

### Live Studio Play session (automated, `sh tools/playtest/playtest.sh`): 26/26

A real Play session with a server, a client and a LocalPlayer (`StudioTestService:ExecutePlayModeAsync`). It
drives the player, then reports back. Frames: `docs/art/hud/playtest_*.jpg`.

- **HUD:** SHOP / INDEX / REBIRTH; no TRAINING; no SACK / Tool slot; Roblox hotbar hidden; all 9 approved icons
  on screen.
- **Spawn:** KICK hidden.
- **On the pad:** KICK + AUTO KICK appear; the meter stays hidden until pressed; no zone bar.
- **Leaving the pad:** KICK hides.
- **Kick sent from off the pad:** rejected by the server.
- **Perfect kick from the pad** (test Kick Power 12): accepted, 432 studs, lands in zone 5. KICK hides in flight.
- **Zone bar in flight:** Meadow > Sandy Beach > Autumn Forest > Mushroom Grove > Desert Dunes, in order. It restarts
  near 0% at all 5 zone changes and ends on the landing zone.
- **Chase:** it ends (nobody steers, so the avalanche takes the egg), and KICK comes back on the pad.
- **Boxing Sack Shop:** it's in the world. Its counter prompt "Browse sacks" opens the existing sack screen
  ("Training"), and closing returns to the world.
- **Your base's sack stand:** has the Train prompt. Train takes the Kick Sack out, and Train again puts it away.

### Not covered yet
- A real phone or tablet (touch).
- A human steering the egg home to secure it (the test lets the avalanche win).

## Manual / account steps left

1. ~~Upload the 50 new images~~ **Done (2026-10-13):** all 50 are uploaded to Krono808 and their Image IDs are in
   `UI/System/AssetIds`. All 109 UI images now load from Roblox everywhere: Studio, live servers and phones. A Studio
   fetch gives 109/109 Success, and the thumbnails API reports all 109 as moderation "Completed".
2. **Developer products** for the Shop's cash packs (need the game published).
3. **Partner A review:** this touches A's UI, VFX and map folders.
