# Task split

Rule of thumb: **A makes it work, B makes it look amazing.** Each of you stays in your own folders,
so you can work at the same time without merge conflicts.

## Ownership

| Area | Owner | Folders |
|---|---|---|
| Server logic, data, RNG, economy, trading | **A** | `src/server/**`, `src/shared/Config/Economy.luau` |
| Client gameplay controllers (kick input, camera, egg flight driver, placing) | **A** | `src/client/Controllers/**` |
| Models: eggs, pets, props, map | **B** | `src/shared/Builders/Models/**`, `src/shared/Builders/Map/**` |
| VFX + procedural animations | **B** | `src/shared/VFX/**`, `src/shared/Anim/**` |
| UI (all screens, HUD, popups) | **B** | `src/client/UI/**` |
| Pet list + content | **B** | `src/shared/Config/Pets.luau` (entries only) |
| Shared contracts | **both, via `contract:` PR** | `Config/Zones`, `Config/Rarities`, `Config/Mutations`, `Remotes.luau`, `Builders/BlockBuilder.luau` |

## Hand-off points (the only places your code touches each other)
- A calls `VFX.play(name, target, params)` and `Anim.play(model, name)` — B implements them.
  Until B lands them, A uses the no-op stubs in `src/shared/VFX/init.luau` and `src/shared/Anim/init.luau`.
- A calls `Models.egg(modelKey)` and `Models.pet(modelKey)` → returns a Model from BlockBuilder.
  Until B lands real models, those return a placeholder colored block.
- B's UI reads player data from the `DataChanged` remote and fires the C->S remotes in `Remotes.luau`.

## Milestones (play-test together after each one)

### M1 — Playable loop (target: day 1–2)
- **A1** Bootstrap: service/controller loader, Remotes, ProfileStore-style saving with session lock.
- **A2** KickService: rate-limited `RequestKick`, roll distance → zones crossed → land zone → egg/pet
  (weighted by zone) → size + weather mutation. Fire `KickResult`.
- **A3** EggFlightController: drive the egg along the runway from `KickResult`, camera follow,
  call `VFX`/`Anim` hooks on zone enter and on landing.
- **B1** Models scaffold: `Models.egg/pet` with 3 finished Meadow eggs + pets (the quality bar).
- **B2** MapBuilder: kick pad, long runway, all 20 zone strips with ground, signs and 3–5 props each.
- **B3** HUD: KICK button + timing meter, money, kick power, quest bar.

### M2 — Eggs, hatching, pets earn money (day 3–4)
- **A4** PlotService: plots per player, place egg on slot, hatch timer (server time), spawn pet, income tick.
- **A5** Upgrades + Rebirth.
- **B4** Zone-roll spin: on each zone enter, the egg spins and cycles that zone's egg models,
  then settles on the rolled egg at landing. Landing: dust, rarity pillar, legs sprout, waddle.
- **B5** Hatch sequence: wobble → cracks → burst of cubes → pet reveal with rarity banner.
- **B6** Pet idle/walk animations + mutation VFX overlays (size, all 6 weather mutations).

### M3 — Content + polish (day 5–7)
- **B7** Fill all 20 zones: 3–5 eggs + pets each (60–100 total). Rarer = more parts, glow, particles.
- **B8** Index, Store, Rebirth, Trade and Settings screens (mock up in Claude Design first).
- **A6** WeatherService (global events that boost weather mutations), announcements, friends boost.
- **A7** TradeService + SellPet + gamepass/dev product handling (placeholder IDs).
- **A8** Anti-exploit pass, analytics events, mobile performance check (part counts, streaming).

## Definition of done for every task
Runs in Studio with no errors in Output, works on the mobile emulator, and is merged to `main`
with a 2-line test note in the PR.
