# Egg & pet experience (Partner B, 2026-10-29, branch `b/egg-experience`)

The "premium egg & pet experience" pass: eggs show what they hold and how long is left, they grow while they incubate,
the owner hatches them by holding a key, the hatch is a silhouette reveal, carrying is posed by egg size, and pets wear a
nameplate with their real income. Nothing about odds, sizes, weather, income math, ownership, saves, roaming rules,
kicking, training, progression, approved models / icons or map geometry changed.

## What the player sees
1. **Egg display** (`EggDisplayController`). Above every placed egg: the pet's name (rarity gradient), a clock and the
   real countdown (`MM:SS`, `h:mm:ss`, `Xd YYh`; `Format.clock`) and a progress bar. Ends on **READY TO HATCH!**
   (green-gold, the approved `icon_check`, a pop, sparkles, `UISuccess` for your own egg, a soft glow). Hidden beyond 75
   studs (your eggs) / 45 studs (others). Width 5 studs, a little wider over bigger eggs, so neighbours at the minimum
   4-stud spacing don't overlap.
2. **Growth.** An egg starts at 55% of its final size and grows to it on its timer (from the saved timestamps, so a
   rejoin shows the right size). Only eggs within 170 studs of you or your camera are re-scaled.
3. **Hold to hatch.** A READY egg gets a hold prompt: **E** (keyboard), the controller's own button image (gamepad),
   **HOLD** (touch; the panel itself is the button). 1 s hold, the bar empties smoothly if you let go. The panel sits
   beside the egg at half its height, its left edge just outside the shell at any distance. Nothing hatches by itself;
   eggs that finished while you were offline come back READY.
4. **Hatch cinematic** (`HatchCinematicController`, tuned per rarity in `Presentation/HatchStyle`). The egg wobbles,
   cracks and glows (anticipation), bursts, the pet appears as a tiny silhouette (dark; light for Divine / Secret), grows
   to its real size with a slight overshoot, then the real materials are revealed with a flash, shockwave, sparkles,
   rarity pillar, aura and an accent sound. The camera frames the pet from its measured height and comes back.
   Click / tap / E / Space / A skips. Frost Serpent and Prism Seraph have signature motifs. Watchers within 160 studs
   see up to 3 shows at once.
5. **Pet nameplate** (`PetNameplateController`). Name (rarity gradient), the real $/s (`Income` attribute, i.e. the
   server's `petIncome`: `$0.8/s`, `$990/s`, `$12.5K/s`), and a weather line only when the pet has a weather mutation.
   Size is never shown. Hidden during the reveal, pops in after.
6. **Carry poses by size** (`Anim/Carry` + `CarryController`, on every character you see):
   | Tier | Hold |
   |---|---|
   | Small | one hand under the egg at the right of the chest; the left arm keeps its walk swing |
   | Medium | both hands on its sides in front of the chest |
   | Large | hugged higher, torso leaning back |
   | Giant | overhead on both palms, its bottom clear of the head, slower heavier bob |
   Hands are placed by arm IK on the egg's real shell (R15); R6 gets the same poses from joint keys. Walking speeds the
   bob up; picking up lifts the egg from the hip, putting it away lowers it.
7. **Tutorial.** The HATCH step says "Your egg is growing! Watch its timer." and, once READY, "Hold E at your egg to
   hatch it!" (touch / gamepad wording differs).

## Visual size policy (`Presentation/EggSize`)
| Size mutation | Multiplier (unchanged) | Egg visual scale | Carry tier |
|---|---|---|---|
| Tiny | 0.6 | 0.76 | Small |
| (none) | 1 | 1.00 | Medium |
| Big | 1.5 | 1.25 | Large |
| Huge | 2.2 | 1.60 | Giant |
| Colossal | 3.2 | 2.10 | Giant |

`visual = 1 + (m - 1) * 0.5` above 1, `1 - (1 - m) * 0.6` below, clamped to 0.5 .. 2.2 so the biggest egg still fits a
pen. Tiers: visual < 0.9 Small, < 1.15 Medium, < 1.45 Large, else Giant. Held eggs are `0.55 * visual`. Placement
uses radius `2 * max(1, visual)`: bigger eggs keep further from fences and from each other (server `eggSpotProblem`,
mirrored by the client ghost).

## Architecture
- **Contract change** (needs the `contract:` sign-off from Partner A): `Remotes` gains `HatchEgg` (C->S, `eggUid`), and
  `EggHatched` now carries `{eggUid, petUid, position, petId?, ownerUserId?, rarity?, size?, weather?}`.
- **Server** `PlotService`: `hatchProblem` (pure: not yours / not ready / too far, reach 12 studs), `hatchEgg` (per-egg
  lock, one `DataService:Set` for plots + pets + discovered, then the models and `EggHatched`), `markReady` (the `Ready`
  model attribute, on the income tick), size-aware spot rules, egg model attributes (`PetName`, `Size`, `Weather`,
  `VisualScale`, `Ready`), held-egg scale + `CarryTier` on the Tool. Freshly hatched pets wait
  `HatchStyle.HOLD_SECONDS` (6 s) before their first roam step, so the reveal happens where the egg was. `SackService`
  `/hatch` (Studio) now makes placed eggs READY instead of hatching them.
- **Shared**: `Presentation/EggSize`, `Presentation/Format`, `Presentation/HatchStyle`, `Anim/Carry`.
- **Client**: the four controllers above, `UI/World/WorldText` (world-space text, bars, clock in the HUD style), and
  small edits to `PlacementController` (ghost scaled to the egg, same spot rules), `PlotController` (faster wobble when
  READY), `TutorialController`, `UI/Hud/Drawers`.
- **Assets**: none new. Sounds are existing SoundBank events (`HatchCrack`, `HatchCommon/Rare/Legendary/Secret`,
  `UISuccess`, `MilestoneClaim`); the only image is the approved `icon_check`.

## Edge cases handled
Early, repeated, simultaneous and far-away hatch requests are refused by the server (one pet, never two); bogus ids do
nothing; a refused request puts the egg back on the client; a pet that arrives without a show is unhidden after a short
timeout; the egg display follows every size change and model rebuild; a held egg's blocks are only measured once they
have settled (a just-replicated held model can be tens of studs off for a frame, which used to leave the egg floating
far away); the giant hold never lowers the egg into the head; switching eggs quickly blends between tiers; death,
respawn and dropping release the pose and weld.

## Tests
- `tools/run-tests.sh`: **379 passed, 4 failed**. The 4 are the known stale checks (shop lights, pen reserve,
  `SafeZone.Decor`, audio ids) and fail identically on the untouched branch base (364 / 4). New checks: size-aware egg
  spots, `hatchProblem`, `EggSize` (monotonic visual, growth, progress, tiers, multipliers untouched), `Format`.
- `tools/playtest/playtest.sh` (real Play session): every egg / hatch / nameplate check passes: name + countdown on the
  placed egg, early request refused, READY waits, holding E hatches it, no second pet, silhouette first, nameplate name
  and real $/s, no size on the nameplate, pet visible after the reveal, Common and Secret hatches play their sounds. The
  remaining failures (engine loudness 0 for every sound, the mystery-egg arm angle, the sack quickslot glow, and
  start-of-session HUD / tutorial timing) also fail on the untouched base.
- Studio MCP, by hand (Play, single player): growth sizes (Colossal half-grown 1.647 vs expected 1.651), labels 0.2
  studs above every egg, Frost Serpent Big + Snowy hatch from a real held E (1.0 s hold, server answer 0.07 s, silhouette
  0.22 -> 1.55 -> 1.50, nameplate "Frost Serpent / $990/s / SNOWY", no part left hidden), Tiny pet "$0.8/s" with no
  weather line and no flash before its reveal, 12 rapid equips across all four tiers with every egg in the hands.

## Known limits / not verified
- Not tested with two clients (watchers' cinematic and other players' carry poses), on a real phone, or with a gamepad.
- R6 avatars get the carry poses from joint keys only (no hand IK).
- Tall hats can poke into a Giant egg held overhead.
- Studio's MCP screen capture does not draw always-on-top billboards, so the hold-prompt screenshot was taken with that
  flag briefly off; in the game it stays on top (it is hidden behind your character otherwise).
- Not run on a published server (DataStore saves of `Ready` eggs across a real rejoin are covered by the timestamp
  design and the unit tests, not by a live rejoin).
