# Task split

**Partner A makes it look amazing (models, map, VFX, animations, UI). Partner B makes it work
(server, data, RNG, chase logic, controllers).** Each of you stays in your own folders, so you
can work at the same time without merge conflicts.

## Ownership

| Area | Owner | Folders |
|---|---|---|
| Server logic, data, RNG, chase rules, economy, trading | **B** | `src/server/**`, `src/shared/Config/Economy.luau` |
| Client gameplay controllers (kick input, flight driver, egg runner, pickup/carry, camera) | **B** | `src/client/Controllers/**` |
| Models: eggs, pets, avalanche pieces, props, map | **A** | `src/shared/Builders/Models/**`, `src/shared/Builders/Map/**` |
| VFX + procedural animations | **A** | `src/shared/VFX/**`, `src/shared/Anim/**` |
| UI (HUD, chase overlay, menus, popups) | **A** | `src/client/UI/**` |
| Pet list + content | **A** | `src/shared/Config/Pets.luau` (entries only) |
| Shared contracts | **both, via `contract:` PR** | `Config/Zones`, `Config/Rarities`, `Config/Mutations`, `Config/Chase`, `Remotes.luau`, `Builders/BlockBuilder.luau`, the APIs of `VFX/init`, `Anim/init`, `Builders/Models/init` |

## Hand-off points (the only places your code touches each other)
- B **moves** things (egg position, carry weld, camera); A **decorates** them (`VFX.play`, `VFX.attach`,
  `Anim.play`). B never builds particles; A never moves the egg or decides outcomes.
- B calls `Models.egg(key)` / `Models.pet(key)`. Until A lands real specs they return placeholder blocks.
- The avalanche: B owns its position (`Chase.frontZ`) and the catch check on the server; A's
  `VFX.play("AvalancheStart", folder, params)` draws it on the client from the same formula.
- A's UI only reads `DataChanged` / chase remotes and fires C->S remotes. It never computes rewards.
- The KICK button (A) fires a client BindableEvent `ReplicatedStorage.Shared.KickPressed(timing)`;
  B's KickController listens to it and sends `RequestKick`. B creates the BindableEvent on the client.

## Milestones (play-test together after each one)

### M1 — Kick and flight (day 1–2)
- **B1 Bootstrap.** Loader that requires every ModuleScript in `Services/` (server) and `Controllers/`
  (client), calls all `:Init()` then all `:Start()`. `DataService`: session-locked DataStore, 3 retries
  with backoff, autosave every `Economy.AutosaveSeconds`, `BindToClose`, `DataChanged` sends partial updates.
  *Done when:* rejoining keeps money; two Studio test servers can't both load one profile.
- **B2 KickService.** `RequestKick(timing)`: reject if the chase is active or <0.5 s since the last request;
  clamp timing; distance = power × `DistancePerPower` × timing bonus × rebirth mult; build `zonesCrossed`,
  `landZone`, `landPos` (X random within ±(RunwayWidth/2 − 6)); weighted pet roll in that zone; one size and
  one weather roll per `Config/Mutations` rules; `launchTime = now + 0.35` (kick animation);
  `flightSeconds = Chase.flightSeconds(distance)`. Store a pending chase. Fire `KickResult`.
  *Done when:* 1,000 simulated kicks print sensible zone/rarity distributions.
- **B3 Flight controller.** Clone `Models.egg(firstZoneKey)`, move it on a parabola from the pad to `landPos`
  over `flightSeconds` (apex = min(distance × arcHeightPerStud, maxArcHeight)), call `VFX.play("ZoneEnter")`
  and `VFX.play("EggSpin")` on each zone boundary (the last one with `finalKey = eggModel`), swap the model
  to the rolled egg at touchdown, then call `Landing` and `LegsSprout`. The camera follows the egg, then
  snaps back to the player 0.6 s after touchdown.
  *Done when:* it looks right with stub VFX and placeholder models.
- **A1 Models scaffold + quality bar.** Meadow: 3 eggs + 3 pets (`SproutPup`, `BumbleBloc`, `MeadowStag`),
  fully rigged (joint groups), in `Models/Eggs/Zone01.luau` and `Models/Pets/Zone01.luau`.
  *Done when:* a showcase script spawns all 6 side by side and they look shop-worthy.
- **A2 MapBuilder.** `Builders/Map/MapBuilder.luau` with `build()`: safe zone with up to 8 player bases
  (pedestal rows, name sign, mailbox) at Z < −6, kick pad at origin, a clearly painted safe line at Z = −6,
  then all 20 zone strips along +Z (`RunwayWidth` wide) with low side walls, zone sign arches at each
  boundary, 3–5 themed props per zone (kept out of the middle 24 studs so runners aren't blocked).
  *Done when:* running the builder in the command bar generates the whole map in <3 s, <6,000 parts.
- **A3 HUD.** KICK button (bottom centre, 180×80 at 1080p, bouncy press), timing meter (needle swings
  0→1→0 at 1.2 Hz, green sweet spot 0.8–1), money with count-up, kick power, quest bar, sound toggle.

### M2 — The chase (day 3–4) ← the heart of the game
- **B4 ChaseService (server).** At touchdown: `startZ = landPos.Z + spawnBehindLanding`,
  `startTime = touchdown + warnSeconds`, `speed = Chase.avalancheSpeed(landZone)`, and `eggRunStart = touchdown
  + Egg.runDelay`. Fire `ChaseStart` to all clients. Every 0.1 s (Heartbeat accumulator): compute
  `front = Chase.frontZ(...)`; egg Z (server-simulated: runs −Z at `Egg.runSpeed` until picked up, then
  follows the player's HumanoidRootPart). If not picked up and `egg.Z >= front - catchDistance` → `EggLost`
  ("EggCaught"). If the owner's HRP `Z >= front - catchDistance` → `EggLost` ("Caught"), fling the player
  toward −Z, respawn at base after 1.2 s. `PickupEgg`: accept if distance ≤ `pickupDistance` + 2 (latency
  slack). Owner crosses `SafeLineZ` carrying it → `EggSecured`, egg added to inventory. When the front
  reaches `despawnAtZ` → `ChaseEnded`. Player leaves → clean up, `EggLost` ("Left").
  *Done when:* every outcome triggers correctly, including exploits (teleporting to the egg is rejected).
- **B5 Egg runner + carry (client).** On `ChaseStart`, the egg model runs toward −Z at `Egg.runSpeed` with a
  ±`zigzag` sine wobble, plays `Anim.play(egg, "EggRun")`, auto-faces its direction and stays on the
  ground (raycast). Pickup by touch (ProximityPrompt-free: a `.Touched` on the egg's Root plus a
  distance check, then fire `PickupEgg`). While carried: weld the egg above the head, `EggCarried` +
  `PlayerCarry` anims, walk speed × `Carry.speedMultiplier`. Show other players' eggs too.
- **A4 Avalanche.** `VFX.play("AvalancheWarn")`: camera shake (rising 0→0.6 over warnSeconds), dust
  geysers along the runway width at `startZ`, a red pulsing edge vignette and a big "RUN!" banner.
  `VFX.play("AvalancheStart")`: a rolling wall `RunwayWidth` wide and `height` tall, made of ~40 pooled
  chunky boulders (2–7 stud blocks/wedges in the theme's 3-colour palette) that tumble (random spin)
  while the wall advances using `Chase.frontZ`. Boulders recycle from the back to the front. Plus a thick
  dust/particle wall in front, flying debris cubes, a ground crack decal trail and a distance-based
  camera shake. 13 themes from `Config/Chase.Themes` (Lava glows + embers, Snow puffs, Crystal is Glass +
  Neon shards, Void is dark with purple Neon cracks, Rainbow cycles hue…). The chase overlay UI is a
  "distance to avalanche" bar plus an arrow to the egg. `AvalancheStop`: the wall slams into the safe-line
  barrier, crumbles into cubes and fades out in 1.2 s. `EggCaught`: the egg is swallowed, a shell-shard
  burst, a red "LOST!" popup. `EggSecured`: a confetti burst in the rarity colour and a "SECURED!" popup.
  *Done when:* it runs at 60 fps on the mobile emulator with ≤ 60 avalanche parts on screen.
- **A5 Egg animations.** `EggSpin` (slot-machine cycle: the egg spins on Y with the model swapped every
  0.07 s, slowing to 0.18 s, ending on `finalKey`), `Landing`, `LegsSprout`, `EggRun` (fast leg cycle,
  body tilt forward, sweat-drop particles), `EggCarried`, `PlayerCarry`.

### M3 — Hatch and earn (day 5)
- **B6 PlotService.** Assign a base on join; `PlaceEgg` onto a free slot; hatch on a server-time timer
  (survives rejoin); spawn the pet (size mutation via `Builder.scale`); income tick every 1 s, with the
  multipliers income × size × weather × rebirth × gamepass.
- **B7 Upgrades + Rebirth.** Cost = costBase × costGrowth^level; Rebirth only at max Kick Power.
- **A6 Hatch sequence.** `EggWobble` (gets faster near the end), `HatchCrack` (progress 0..1 adds cracks),
  `HatchBurst`, `PetReveal` (pet pops up with a squash bounce, rarity banner, beam for Legendary+).
- **A7 Pets alive.** `Idle`, `Waddle`, `Hop`, `Sleep`, a floating "$X/s" label, and looping overlays for
  all 6 weather mutations via `VFX.attach`.

### M4 — Content + polish (day 6–7)
- **A8 All 20 zones.** 3–5 eggs + pets each (60–100 total), one zone per session.
- **A9 Menus.** Index, Store, Rebirth, Trade, Settings (mock up in Claude Design first).
- **B8 Meta.** Weather events (`WeatherChanged`), announcements, friends boost, Trade/Sell, dev
  products and gamepasses (placeholder IDs).
- **B9 Hardening.** Rate limits on every remote, sanity checks, analytics events, StreamingEnabled tuning.

## Definition of done for every task
Runs in Studio with no errors in Output, works on the mobile emulator (iPhone 14 preset), is merged
to `main`, and the PR includes a 2-line test note.
