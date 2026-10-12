# Boxing Sack VFX performance

Source: `message (3).txt`, "Boxing Sack VFX performance optimization".

All 20 Kick Sacks keep their effects, colours and animations. Up close they show the same number of particles as
before. The difference is in who does the work:
- Particles that used to be pushed by Lua every frame are now launched once and moved by Roblox's particle engine.
- Far-away and off-screen sacks thin out, slow down, or stop.
- Nothing is destroyed and rebuilt as you walk around any more.

Renders are in `docs/art/perf/`. The benchmark is `tools/perf/SackVfxBench.server.lua`.

## 1. Audit: what was actually expensive (measured before any change)

The sack VFX are 100% client-side. Each sack effect is built by `VFX/SackAura`, a port of the remodel's web preview.
The server only sets attributes (SackAt / SackTier / SackHits) and builds the map's sack models.

| # | Finding | Evidence (before) |
|---|---|---|
| 1 | **Hand-simulated "swarm" particles.** 2,624 particles, each one a ParticleEmitter on its own Attachment. Lua moved every one of them every frame. Each frame it wrote the position, then allocated a new `NumberSequence` for size and another for transparency, and wrote both (plus a `ColorSequence` for colour-over-life swarms). That is about 8,000 property writes and 5,000 allocations per frame with all 20 sacks running. | Step cost for all 20 sacks at full detail: **5.88 ms/frame**. Galaxy Void (510 swarm particles): 0.876 ms. Rainbow God (300): 0.975 ms. |
| 2 | **Spinning stand / shop sacks.** `MapLife` called `model:PivotTo` every frame for every map sack, near or far, on screen or not. | `PivotTo`: 0.08–0.89 ms per sack. Dragon Hide (239 parts): 0.892 ms. All 20: **5.59 ms/frame**. |
| 3 | **Destroy / rebuild by distance.** Stand sack effects were destroyed past 110 studs and rebuilt inside 90, every time. | Build cost: Galaxy Void 12.0 ms, Rainbow God 8.4 ms. All 20: 72 ms. Each rebuild is a hitch. |
| 4 | **No culling and no quality levels.** Full detail at 89 studs, no view culling, and a blanket "touch device = 60% particles" cut (`SackController`) that also thinned the glows. | Code |
| 5 | **Lightning** (Thunder Cell). 8 bolts = 128 Beams. Every frame it wrote `Transparency` (a new sequence) and `Enabled` on every beam, whatever happened. | 0.178 ms/frame on its own |
| 6 | **Rings and orbiters.** Rings are 32–36 neon segments, plus orbiting shards, planets, cubes and candies. Each part's `CFrame` was set on its own every frame. | Gold Champion: 64 segments. Robo Bag: 72. |
| 7 | **Impact effects of other players' kicks** played in full however far away or off screen. Comic words are BillboardGuis with `MaxDistance` 70 but still ran a RenderStepped loop and a tween. Ring waves are Lua-moved neon pieces. | Code (`VFX/Sack`) |

Already fine, kept as is:
- Impact parts and anchors are pooled (`VFX/Pool`, bounded).
- Decorative parts are anchored, with CanCollide / CanQuery / CanTouch off, so there is no physics cost.
- Nothing about the effects is replicated: no remotes and no network traffic.

## 2. What changed

### Engine-moved particles (`VFX/SackAura`, `Ctx:swarm`)
- **Straight / falling / dragged paths (most swarms).** Each particle's spawn is still chosen by the tier's own
  `spawn` function: spot, velocity, colour, size and life. Lua then launches **one real particle** with that velocity,
  gravity and drag, and bakes the particle's own size growth, fades, twinkle and colour-over-life into its
  sequences. The engine moves it, and Lua only respawns it.
  - Two engine behaviours were checked in Studio with a test render before relying on them:
    - for a locked particle, Acceleration is applied in the attachment's space, so it is un-rotated per particle;
    - `Drag` is a half-life per second, so it is converted from the preview's linear drag.
  - Long or twinkling lives are re-launched every few twinkle periods, exactly where they were, so there are no seams.
- **`spin` swarms (orbit the sack's axis).** Tiers 8, 19 and 20 had a velocity field that only orbited the axis.
  It is now written as `spin = ω`: the particles ride one invisible part turned once per frame. The motion is the
  same, and actually exact (the Lua version drifted outwards by up to about 5% over a particle's life).
- **`frame` swarm (Galaxy Void's 450-star disk).** The stars ride one tilted, turning part: 1 CFrame write per frame
  instead of 450 × 3.
- **Free-form `field` swarms** stay Lua-moved, but write a property only when its quantised value changes:
  - transparency in 1/64 steps;
  - size in 1/400 stud;
  - colour in 6 bits per channel;
  - all of them shared cached sequences, so there are no allocations.

  These are 760 particles in tiers 10, 11, 12, 13, 15, 17 and 18.
- **New effects fill in over a few frames.** At most 64 particles are brought in per frame, so a sack appearing
  never makes a spike.
- **One BulkMoveTo per step** for rings, orbiters, wings, arms and turning frames.
- **Animated glow sprites** (`setAlpha`) use cached sequences and are written only on change.
- **Lightning:** beams are written only when a bolt's quantised alpha changes, and `Enabled` only when it flips.

### Level of detail and quality (`VFX/SackLod`, new)
One driver (a single RenderStepped, connected only while any sack effect exists) handles every sack effect: stand
sacks, shop sacks, every player's gear sack and the dev showcases.

**Distance bands**

| Band | Distance (× profile reach) | Particles (HIGH) | Lua animation | Lights | Lightning bolts |
|---|---|---|---|---|---|
| Full | < 45 studs | 100% | every frame | on | all |
| Reduced | 45–100 | 60% | every 2nd frame, interleaved | on | half |
| Minimal | 100–180 | 30% | every 4th frame | off | a quarter |
| Disabled | > 180 | hidden, not destroyed | none | off | none |

- Bands are checked every 0.2 s, with 8 studs of hysteresis.
- The particles kept are an even, random share, so each swarm keeps its shape and just gets sparser.
- Streaming emitters (fire, sparks, star fields, motes) follow the share, with a 30% floor.
- **Kept at every visible level:** glows, sunbursts, pulse rings and the galaxy disk. They're cheap and carry each
  sack's identity.
- **Galaxy Void, Sun Guardian and Rainbow God** get ×1.3 particles at Reduced and Minimal (78% / 39%).

**Viewport culling (conservative, every frame)**
- If a sack's bounding sphere × 1.5 is outside the view, its Lua animation pauses.
- Its engine particles keep living, so it looks right the moment it's back on screen.
- Nothing is culled within 25 studs.

**Quality profiles**

| Profile | Band reach | Particles at Full / Reduced / Minimal | Animation stride | Lights | Bolts at Full |
|---|---|---|---|---|---|
| HIGH | 1.0 | 100 / 60 / 30% | 1 / 2 / 4 | up to Reduced | all |
| MEDIUM | 0.85 | 80 / 45 / 20% | 1 / 2 / 4 | up to Reduced | all |
| LOW | 0.7 | 55 / 30 / 12% | 1 / 3 / 6 | Full only | half |
| MINIMAL | 0.55 | 35 / 15 / 0% | 2 / 4 / 8 | Full only | a quarter |

How the profile is picked:
- **AUTO (default)** follows Roblox's graphics quality (Esc > Settings > Graphics):
  - levels 8–10 or Automatic → HIGH;
  - 5–7 → MEDIUM;
  - 3–4 → LOW;
  - 1–2 → MINIMAL.
- **With Automatic graphics, it adapts to the device's real frame rate:**
  - below 40 FPS for 4 s → one step down;
  - above 55 FPS for 20 s → one step back up, with a 30 s cooldown.
- **"Low detail effects"** caps it at LOW.
- **Settings > "Sack effects"** (new row: AUTO / HIGH / MEDIUM / LOW / MINIMAL) overrides it.
- Touch alone never lowers quality. The old blanket phone cut is gone, so a fast phone keeps HIGH.

### Callers
- **`MapLifeController`:**
  - Stand and shop sack effects are built once, when the camera first comes within the farthest band (nearest
    first, one every 0.25 s), and then kept. There is no more destroy / rebuild.
  - Spinning follows the same bands and view test: every frame / 2nd / 4th (interleaved), and none far away or off
    screen.
  - A turn is now one `BulkMoveTo` of cached parts instead of `PivotTo`.
- **`SackController`:**
  - Gear sacks step their effect every frame, and the level of detail decides the cost (the old 140-stud cut-off is
    gone).
  - Effect-placed parts are left to the effect.
  - The touch-based quality cut is removed.
- **`VFX/Sack` (impacts):**
  - Other players' hits and drops beyond 160 studs or off screen play only the thud.
  - Comic words start only on screen within 70 studs (their MaxDistance).
  - Ring waves start only on screen within 140.
  - Sounds start only within 120 (their roll-off).
  - Your own sack always plays in full.
- **Pooling:** no new pools. Impact effects were already pooled, and the measured allocation problem was the
  per-frame sequences, which are now cached. There was no per-hit allocation problem to justify more pooling.

### Cleanup and leaks
- `SackAura.Remove` (or the sack being destroyed) unregisters the effect, disconnects everything and destroys the
  folder. `ctx:destroy` is idempotent.
- **StreamingEnabled:** a sack whose model leaves the world is Disabled at once. If it stays gone for 10 s, its
  effect is freed. MapLife forgets freed effects and rebuilds when the sack streams back in.
- A broken effect is stopped and freed (pcall in the driver) instead of breaking every other sack.
- The tests check, for all 20 tiers:
  - cycling Full → Reduced → Minimal → Disabled → Full creates no instances;
  - Remove leaves nothing behind;
  - the LOD registry returns to empty.

## 3. Measurements

Measured with `tools/perf/SackVfxBench.server.lua`:
- **Same PC, same Studio session type, back to back.**
  - "Before" ran on a build of the commit before this work (`0d23618`).
  - "After" ran on this branch.
- **What it measures:** CPU script time with `os.clock` over 240 frames per case (after 10 warm-up frames), for
  each of the 20 sacks built from the real game models.
  - **What it is:** script time; comparable before and after.
  - **What it isn't:** FPS.
- **Live particles:** the shown swarm particles, plus each engine emitter's rate × lifetime, an estimate.

| # | Sack | Before: step at full detail | After: Full / Reduced / Minimal | Live particles: Full / Reduced / Minimal | Spin: before (PivotTo) → after (BulkMoveTo) | Build: before → after |
|---|---|---|---|---|---|---|
| 1 | Burlap Sack | 0.105 ms | **0.003** / 0.002 / 0.001 ms | 58 / 35 / 17 | 0.190 → **0.051** ms | 1.5 → 2.6 ms |
| 2 | Gym Canvas | 0.122 ms | **0.003** / 0.002 / 0.001 ms | 66 / 40 / 20 | 0.171 → **0.054** ms | 1.5 → 2.1 ms |
| 3 | Leather Classic | 0.035 ms | **0.003** / 0.002 / 0.001 ms | 31 / 19 / 10 | 0.208 → **0.073** ms | 0.8 → 1.1 ms |
| 4 | Pro Red | 0.071 ms | **0.004** / 0.003 / 0.002 ms | 56 / 34 / 17 | 0.079 → **0.028** ms | 1.4 → 1.8 ms |
| 5 | Tire Stack | 0.108 ms | **0.003** / 0.002 / 0.001 ms | 62 / 38 / 19 | 0.420 → **0.143** ms | 1.5 → 2.1 ms |
| 6 | Iron Plate | 0.224 ms | **0.021** / 0.015 / 0.008 ms | 108 / 66 / 35 | 0.353 → **0.111** ms | 2.5 → 2.9 ms |
| 7 | Bronze Statue | 0.103 ms | **0.005** / 0.004 / 0.002 ms | 63 / 38 / 20 | 0.258 → **0.093** ms | 1.5 → 2.1 ms |
| 8 | Silver Knight | 0.125 ms | **0.010** / 0.006 / 0.003 ms | 93 / 56 / 29 | 0.187 → **0.063** ms | 2.2 → 2.9 ms |
| 9 | Gold Champion | 0.331 ms | **0.085** / 0.037 / 0.025 ms | 118 / 72 / 38 | 0.245 → **0.063** ms | 3.5 → 5.0 ms |
| 10 | Ice Block | 0.234 ms | **0.095** / 0.034 / 0.010 ms | 138 / 84 / 44 | 0.254 → **0.090** ms | 3.1 → 3.4 ms |
| 11 | Crystal Geode | 0.322 ms | **0.196** / 0.071 / 0.023 ms | 226 / 158 / 107 | 0.198 → **0.059** ms | 4.1 → 4.8 ms |
| 12 | Candy Smash | 0.254 ms | **0.125** / 0.041 / 0.013 ms | 160 / 96 / 48 | 0.478 → **0.114** ms | 3.9 → 4.1 ms |
| 13 | Lava Core | 0.599 ms | **0.344** / 0.131 / 0.047 ms | 232 / 142 / 75 | 0.193 → **0.068** ms | 5.1 → 5.3 ms |
| 14 | Thunder Cell | 0.178 ms | **0.066** / 0.026 / 0.012 ms | 83 / 55 / 34 | 0.160 → **0.057** ms | 3.9 → 4.4 ms |
| 15 | Toxic Barrel | 0.224 ms | **0.101** / 0.038 / 0.013 ms | 134 / 82 / 43 | 0.200 → **0.055** ms | 3.2 → 3.6 ms |
| 16 | Robo Bag | 0.344 ms | **0.121** / 0.060 / 0.027 ms | 84 / 52 / 28 | 0.270 → **0.056** ms | 3.8 → 4.2 ms |
| 17 | Dragon Hide | 0.461 ms | **0.365** / 0.118 / 0.035 ms | 290 / 175 / 89 | 0.892 → **0.217** ms | 4.6 → 5.8 ms |
| 18 | Galaxy Void | 0.876 ms | **0.100** / 0.059 / 0.018 ms | 620 / 489 / 255 | 0.271 → **0.081** ms | 12.0 → 10.8 ms |
| 19 | Sun Guardian | 0.188 ms | **0.042** / 0.029 / 0.012 ms | 190 / 152 / 84 | 0.331 → **0.083** ms | 3.5 → 2.5 ms |
| 20 | Rainbow God | 0.975 ms | **0.181** / 0.101 / 0.053 ms | 349 / 283 / 166 | 0.236 → **0.051** ms | 8.4 → 9.3 ms |

**All 20 sacks together**

| Metric | Before | After |
|---|---|---|
| Lua step, all 20 at Full (script time / frame) | 5.88 ms | **1.87 ms** |
| ... at Reduced / Minimal / Disabled / Full but off screen | (no levels: Full up to 110 studs, then destroyed) | 0.78 / 0.31 / 0.00 / 0.16 ms |
| Spin, all 20 (script time / frame) | 5.59 ms (`PivotTo`, every frame, every distance) | **1.61 ms** (`BulkMoveTo`, and only near and on screen) |
| Live particles at Full | ~3163 | ~3163 (the same up close) |
| Live particles at Reduced / Minimal distances | all at Full up to 90-110 studs (stands) / 140 (gear sacks), then none | ~2168 / ~1180 |
| Lua-moved particles | 2624 (every swarm particle, every frame) | 760 (the 7 field swarms; the rest are engine-moved) |
| Sequence allocations, all 20 at Full | about 6,000 per frame (a new size and transparency sequence per particle per frame, plus colour for 724 colour-over-life particles) | none per frame for moving particles (cached); sequences are built only when a particle launches, and plain fades are cached |
| Emitters / beams / lights (instances, all 20) | 2683 / 128 / 20 | 2683 / 128 / 20 (same, now thinned and disabled by level) |
| Effect builds | every time a stand sack came back within 90 studs | once per sack (kept) |
| Build time, all 20 (one-off now) | 72 ms | 81 ms (+ particles brought in 64 per frame) |
| Cosmetic RenderStepped connections | MapLife 1 + SackController 1 + 1 per self-running effect (showcases) + 1 per live ring wave / comic word | MapLife 1 + SackController 1 + SackLod 1 (only while any sack effect exists) + ring waves / words only when on screen |
| VFX network traffic | none | none |

Raw output: `docs/art/perf/bench_before.txt`, `docs/art/perf/bench_after.txt`.

**Test cases**

These are worked out from the per-sack numbers above. Only the sacks in each scene are counted.

| Case | Scene | Before (step + spin) | After, all at Full and on screen (step + spin) | Change |
|---|---|---|---|---|
| A: low-end sack | one Burlap Sack (1) up close, spinning | 0.295 ms | 0.054 ms | -82% |
| B: premium sack | Galaxy Void (18) up close | 1.147 ms | 0.181 ms | -84% |
| B: premium sack | Sun Guardian (19) up close | 0.519 ms | 0.125 ms | -76% |
| B: premium sack | Rainbow God (20) up close | 1.211 ms | 0.232 ms | -81% |
| C: multiple sacks | the Boxing Sack Shop's 6 display sacks (1, 5, 9, 14, 18, 20), all spinning | 4.095 ms | 0.884 ms | -78% |
| C: all 20 | every sack at Full at once (worst case, not a real scene) | 11.473 ms | 3.483 ms | -70% |
| D: nobody near | all 20 sacks > 180 studs away | 5.59 ms (effects off past 110 studs, but every map sack still `PivotTo`'d every frame) | 0.00 ms (Disabled: no step, no spin; measured 0.000 ms per sack) | -100% |

Off screen at Full: all 20 together 0.16 ms (vs 1.87 on screen): only engine-particle respawns run.

**E: mobile / quality profiles** (all 20 sacks at Full, step only, after):

| Profile | Step | Live particles |
|---|---|---|
| HIGH | 1.86 ms | 3163 |
| MEDIUM | 1.60 ms | 2784 |
| LOW | 1.27 ms | 1996 |
| MINIMAL | 0.58 ms | 1337 |

The old phone rule (`Quality = 0.6` on touch-only devices) applied at build time to every touch device. It is replaced by these profiles, chosen from the graphics level and the measured frame rate.

**Live Play session** (`sh tools/playtest/playtest.sh`, real server + client) reports the managed effects' levels:

```
PLAYTEST [  28.7s] NOTE sack effects at the shop counter: Full 6, Reduced 3, Minimal 3, Disabled 2, off screen 0
PLAYTEST [  28.7s] PASS sack vfx: the shop's sacks run at Full up close (Full 6, Reduced 3, Minimal 3, Disabled 2, off screen 0)
PLAYTEST [  30.2s] NOTE sack effects far away: Full 0, Reduced 0, Minimal 0, Disabled 14, off screen 0
PLAYTEST [  30.2s] PASS sack vfx: far away every sack effect is Disabled (Full 0, Reduced 0, Minimal 0, Disabled 14, off screen 0)
PLAYTEST [  31.7s] NOTE sack effects back on the kick pad: Full 0, Reduced 3, Minimal 11, Disabled 0, off screen 14
PLAYTEST [  31.7s] PASS sack vfx: the Settings override picks the profile
PLAYTEST [  31.7s] NOTE sack vfx profile (AUTO): HIGH
```
(all checks PASS; full log `docs/art/perf/playtest.txt`)

**Not measured, and why:**
- **Client frame time / FPS.** Studio on this PC runs at the 60 FPS cap with or without sacks, so FPS can't show
  the difference. Script time is the measured metric instead.
- **GPU cost.** No GPU profiler is available headless. Particle counts up close are unchanged, and far away they
  drop with the bands.
- **Memory.** Instance counts are the same per sack: the same emitters, attachments and beams, plus one invisible
  part per turning frame. They are now kept instead of rebuilt, bounded by the 14 map sacks plus the gear sacks.
  Lua heap allocations per frame were cut from about 5,000 sequences to near zero, but Luau can't isolate a VFX
  share of the heap, so there's no "MB" number.
- **Network.** None. The effects create no remotes and replicate nothing, before or after.
- **Real phones.** Not tested. The profiles were measured on PC (above). On a phone, use the MicroProfiler (steps
  below).

## 4. All 20 sacks

"Engine" = the particles are now engine-moved. "Lua" = still Lua-moved, with cached writes. Every sack also gets
the bands, culling and profiles above.

| # | Sack | Signature effects (kept) | What changed |
|---|---|---|---|
| 1 | Burlap Sack | drifting dust, falling fibres | dust 40 + fibres 18 → engine |
| 2 | Gym Canvas | chalk puffs every 3 s, sweat sparkles | puffs 36 (the 3 s timing is kept at spawn) + sparkles 30 → engine |
| 3 | Leather Classic | sweat drips, gold glint up the seam | drips 30 → engine; glint sweep → engine with its sine fade baked in |
| 4 | Pro Red | star glints on the bands, warm motes | glints 26 + motes 30 → engine |
| 5 | Tire Stack | rubber smoke, flying rubber bits | smoke 46 + bits 16 (spin, gravity) → engine |
| 6 | Iron Plate | welding spark bursts, flicker light, smoke | sparks 90 → engine (arc, gravity, colour over life, burst timing); smoke 14 → engine; glow flicker cached |
| 7 | Bronze Statue | light sweep, twinkling motes, glints | sweep, motes 50 (twinkle baked), glints 12 → engine |
| 8 | Silver Knight | glints, blue spiral aura, ground pulse | spiral 70 → `spin` (exact orbit on one part); glints → engine; pulse kept |
| 9 | Gold Champion | floating halo, gem glow, rising gold, glints | halo 64 segments → one BulkMoveTo; gold 90 (twinkle) + glints 24 → engine |
| 10 | Ice Block | frost mist, falling snow, drips, core glow | mist 50 + drips 14 → engine; snow 70 stays Lua (sideways drift field) |
| 11 | Crystal Geode | pulsing core, orbiting shards, energy pulled in | shards → BulkMoveTo; glints 30 → engine; inflow 140 stays Lua (vortex field); core pulse cached |
| 12 | Candy Smash | confetti pop, sparkles, orbiting candies | sparkles 50 → engine; candies → BulkMoveTo; confetti 110 stays Lua (flutter field) |
| 13 | Lava Core | magma cracks, swirling embers, smoke, drops | smoke 40 + drops 24 (colour over life) → engine; embers 160 stay Lua (swirl field); glow cached |
| 14 | Thunder Cell | arcs, coil sparks, sky strikes, pulse | 8 bolts / 128 beams written only on change, thinned by band; sparks 70 → engine |
| 15 | Toxic Barrel | glowing ooze, bubbles, fumes, drips | fumes 40 + drips 20 → engine; bubbles 70 stay Lua (wobble field) |
| 16 | Robo Bag | scan rings, data bits, blinking LEDs, moving arms | rings 72 segments + arms → BulkMoveTo; data bits 80 (twinkle) → engine |
| 17 | Dragon Hide | crown fire, embers, smoke, flicker light, wings | fire 150 stays Lua (pull-to-axis field); engine fire / sparks / smoke streams thinned by band; wings → BulkMoveTo |
| 18 | **Galaxy Void** | spinning galaxy disk + rings, planets, cubes, inflowing matter | 450 disk stars → one turning, tilted part (engine, twinkle baked); galaxy disk, rings and glows kept at every level; 3 moons + 8 cubes → BulkMoveTo; star field thinned; inflow 60 stays Lua; ×1.3 density far out |
| 19 | **Sun Guardian** | sunbursts, solar motes, sparkles, pulse ring, wings | sparkles 50 → `spin` (engine, twinkle); both sunbursts, the glow and the pulse ring kept at every level; motes stream thinned; wings → BulkMoveTo; ×1.3 density |
| 20 | **Rainbow God** | hue-cycling bands / wings / lights, rainbow sunburst, helix aura, ring waves, prisms | helix 220 → `spin` (engine, hue cycle baked per particle); prism stars 80 → engine (twinkle + hue); halo → BulkMoveTo, colour written on change; sunburst and both ring waves kept at every level; 9 prisms → BulkMoveTo; ×1.3 density |

**Visible differences, and why:**
- Up close: none intended. The same particles, spawns, colours and timing are used.
  - **Twinkle** is now baked as about 6 samples per twinkle period, instead of a per-frame sine. It is slightly
    softer, but there is no per-frame Lua.
  - **Particle colours** are rounded to 6 bits per channel.
  - **Spin swarms** orbit at an exact radius; the old per-frame steps drifted out by about 5% over a particle's life.
- Further out: fewer particles (bands), lights off from Minimal, and fewer bolts.
- On LOW / MINIMAL: fewer particles up close too. That is the point of those profiles, and only on slow devices or
  when chosen.

Renders from the same camera, close up (Full, HIGH):
- `before_sacks_{1,6,11,16}.jpg` vs `after_sacks_{1,6,11,16}.jpg`;
- the premium row on lower profiles: `after_sacks_16_LOW.jpg`, `after_sacks_16_MINIMAL.jpg`.

## 5. Remaining bottlenecks
1. **Seven field swarms (760 particles) are still Lua-moved:** Lava Core embers, Dragon Hide fire, Crystal Geode
   inflow, Candy Smash confetti, Ice Block snow, Toxic Barrel bubbles, and the Galaxy inflow.
   - Their paths depend on position (vortex, pull-to-axis, swirl), which the particle engine can't do.
   - They cost 0.10–0.36 ms per sack at Full. Lava Core and Dragon Hide are the most expensive sacks now.
2. **Building an effect** is instance creation: Galaxy Void about 12 ms, Rainbow God about 9 ms on this PC.
   - It now happens once per sack, not on every approach.
   - Another player equipping a top sack nearby still pays it in one frame. It could be spread over frames.
3. **One emitter + attachment per swarm particle** (2,624 instances for all 20 sacks). Roblox has no API to place
   particles of one shared emitter, so memory and per-emitter engine overhead stay.
4. **Neon colour loops** (Lava Core magma, Thunder Cell rings, Rainbow God bands) write part colours every update at
   Full.
5. **Impact ring waves** are still Lua-moved pieces while they live (0.3–0.6 s, on-screen ones only).
6. **No real-phone profiling yet.**

## 6. Testing in Studio
1. `sh tools/run-tests.sh`: the server tests include the new LOD / leak checks for all 20 tiers.
2. `sh tools/run-tests.sh tools/perf/SackVfxBench.server.lua`: the per-sack benchmark. Run it on an older build to
   compare (header of the script).
3. `sh tools/playtest/playtest.sh`: the live Play session, including the shop / far-away / Settings LOD checks.
4. **By hand, in Play:**
   - **Walk into the Boxing Sack Shop:** the 6 display sacks run full effects.
   - **Walk away to about 60, 120 and 200 studs:** they thin out, then hide. Walk back: they return with no hitch.
   - **Turn the camera away and back:** they keep their look.
   - **Settings > "Sack effects":** cycle HIGH / MEDIUM / LOW / MINIMAL at the shop and compare. AUTO is the default.
   - **Esc > Settings > Graphics Quality:** set it manually (1–10) with AUTO on, and the profile follows.
   - **Train at your stand** to take the gear sack out and kick it: full impacts. Another player kicking far away
     costs nothing.
5. **MicroProfiler** (Ctrl+F6, also on a phone with the Studio device emulator / Developer Console):
   - Compare `RenderStepped` (MapLife, SackController, SackLod) at the shop and at your base.
   - Check that `SackLod` takes almost no time away from sacks.
6. **On a real phone:** Developer Console > Memory / MicroProfiler at the shop. Check AUTO picks a sensible profile
   (`SackLod.profile()`).
