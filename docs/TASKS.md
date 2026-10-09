# Task split

Rule of thumb: **A makes it look amazing, B makes it work.** Each of you stays in your own folders,
so you can work at the same time without merge conflicts.

## Ownership

| Area | Owner | Folders |
|---|---|---|
| Server logic, data, RNG, economy, trading | **B** | `src/server/**`, `src/shared/Config/Economy.luau` |
| Client gameplay controllers (kick input, camera, egg flight driver, placing) | **B** | `src/client/Controllers/**` |
| Models: eggs, pets, props, map | **A** | `src/shared/Builders/Models/**`, `src/shared/Builders/Map/**` |
| VFX + procedural animations | **A** | `src/shared/VFX/**`, `src/shared/Anim/**` |
| UI (all screens, HUD, popups) | **A** | `src/client/UI/**` |
| Pet list + content | **A** | `src/shared/Config/Pets.luau` (entries only) |
| Shared contracts | **both, via `contract:` PR** | `Config/Zones`, `Config/Rarities`, `Config/Mutations`, `Remotes.luau`, `Builders/BlockBuilder.luau` |

## Hand-off points (the only places your code touches each other)
- B calls `VFX.play(name, target, params)` and `Anim.play(model, name)` — A implements them.
  Until A lands them, B uses the no-op stubs in `src/shared/VFX/init.luau` and `src/shared/Anim/init.luau`.
- B calls `Models.egg(modelKey)` and `Models.pet(modelKey)` → returns a Model from BlockBuilder.
  Until A lands real models, those return a placeholder colored block.
- A's UI reads player data from the `DataChanged` remote and fires the C->S remotes in `Remotes.luau`.

## Milestones (play-test together after each one)

### M1 — Playable loop (target: day 1–2)
- **B1** Bootstrap: service/controller loader, Remotes, ProfileStore-style saving with session lock.
- **B2** KickService: rate-limited `RequestKick`, roll distance → zones crossed → land zone → egg/pet
  (weighted by zone) → size + weather mutation. Fire `KickResult`.
- **B3** EggFlightController: drive the egg along the runway from `KickResult`, camera follow,
  call `VFX`/`Anim` hooks on zone enter and on landing.
- **A1** Models scaffold: `Models.egg/pet` with 3 finished Meadow eggs + pets (the quality bar).
- **A2** MapBuilder: kick pad, long runway, all 20 zone strips with ground, signs and 3–5 props each.
- **A3** HUD: KICK button + timing meter, money, kick power, quest bar.

### M2 — Eggs, hatching, pets earn money (day 3–4)
- **B4** PlotService: plots per player, place egg on slot, hatch timer (server time), spawn pet, income tick.
- **B5** Upgrades + Rebirth.
- **A4** Zone-roll spin: on each zone enter, the egg spins and cycles that zone's egg models,
  then settles on the rolled egg at landing. Landing: dust, rarity pillar, legs sprout, waddle.
- **A5** Hatch sequence: wobble → cracks → burst of cubes → pet reveal with rarity banner.
- **A6** Pet idle/walk animations + mutation VFX overlays (size, all 6 weather mutations).

### M3 — Content + polish (day 5–7)
- **A7** Fill all 20 zones: 3–5 eggs + pets each (60–100 total). Rarer = more parts, glow, particles.
- **A8** Index, Store, Rebirth, Trade and Settings screens (mock up in Claude Design first).
- **B6** WeatherService (global events that boost weather mutations), announcements, friends boost.
- **B7** TradeService + SellPet + gamepass/dev product handling (placeholder IDs).
- **B8** Anti-exploit pass, analytics events, mobile performance check (part counts, streaming).

## Definition of done for every task
Runs in Studio with no errors in Output, works on the mobile emulator, and is merged to `main`
with a 2-line test note in the PR.
