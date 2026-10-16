# World remodel: classic-brick hub and 20 zones (2026-10-16)

**Branch:** `a/world-remodel` (from `b/spin-wheel` ac600b0), Partner A.

**Decisions** (the user, 2026-10-15/16):
- Keep 5 pens.
- Open valley instead of the 50-stud canyon walls.
- Classic studded bricks rather than smooth meshes, after a side-by-side test in Studio:
  - Studs on tops and sides, inlets underneath. Smooth only for glass, water, neon, ice, signs.
  - Round shapes are voxel crosses or stepped layers.
- Bright modern palette.
- Balanced budget.
- Huge landmarks.
- Bright midday lighting.
- Gradual zone blends.
- Lively but tasteful motion.
- Hub: a town feel, terraces with stairs, denser greenery and a bigger centrepiece.

## What changed

| Area | Result |
|---|---|
| **Hub** (`World/Hub.luau`) | **Paths:** studded stone paths with borders, an octagonal plaza and the **Golden Egg centrepiece** (a two-tier fountain with jets, ripples and glints).<br>**Village:** four brick terraces with stairs carry town houses (red, blue, green and purple roofs), a gazebo and wells. A row of houses lines the back wall.<br>**Edges:** one plain, closed, studded sandstone **hub wall** along both sides and the back. It rises from the sea to 46 studs above the lawn, has a cream cap and a footing, and has no gaps, so players can't see out. It collides and stops the camera. The valley side stays open, with a low balustrade and lanterns.<br>**Greenery:** tree groves (some on knolls, swaying), hedges along the spine, flower planters, benches and lamps.<br>**Ambience:** pollen, butterflies and fireflies. |
| **Boxing Sack Shop** (`World/Shops.luau`) | **Building:** a barrel-vault roof in red and white stripes with gold ribs and a glowing round gable window, a giant boxing glove turning on a gold plinth, a striped awning, stone pillars and arched side windows.<br>**Props:** dumbbells, a speed bag and tyres.<br>**Unchanged:** the counter prompt, `Sign`, `Approach`, the Coach spot and the six display sacks. |
| **Pet Selling Stand** | **Building:** a teal and cream striped canopy on carved posts, with a paw board on the ridge.<br>**Props:** bunting, lanterns, egg crates on shelves, pet beds, a carrier and a price board.<br>**Unchanged:** the counter prompt, the SELL PETS sign with the approved icon, `Approach` and the merchant spot. |
| **Pens** (`MapBuilder.buildPen`) | **Same** sizes, centres, `PenArea` and `Floor` tiles.<br>**New:** chunky brick fences in three level styles (wood, white/blue, dark/gold), gate posts, a stone border, lanterns, planters, banners and gold crowns at max level.<br>**Collision:** one collision proxy per fence run. |
| **Launch** | Egg monuments by the pad, banners at the plaza corners. Kick pad, ramp, safe line and barrier are unchanged. |
| **20 zones** (`World/Zones/Z01..Z20`) | Open valleys built from stepped banks, plateaus, ground patches, landmarks, clustered vegetation and props, far silhouettes, ambience and blends into the neighbouring zones (see the table below). |
| **Finale** | The **Heaven Gate** colonnade with the **Golden Egg trophy** on top, on the old end-wall plane. |
| **Lighting** | Bloom softened (Intensity 0.6→0.38, Threshold 1.3→1.6), so only bright neon glows and studded colours stay crisp. Atmosphere, SunRays and ColorCorrection are unchanged.<br>The place file keeps ClockTime 13.5 and GlobalShadows off. |
| **Motion** (`VFX/Ambient.luau` + `Controllers/WorldLifeController.luau`, both new) | One shared client loop handles all of it:<br>• trees sway;<br>• islands, ghosts, cubes, meteors and the temple bob;<br>• windmill sails, gears, the lighthouse beam, the roof glove, the planet and the hologram spin;<br>• water textures scroll;<br>• particles are culled by distance and scaled by graphics quality.<br>Sway runs in budgeted slices (60 models per frame, each move a single `BulkMoveTo`); spinners update every frame. |
| **VFX** (`World/Fx.luau`, `VFX/WorldSprites.luau`) | 20 original sprites (`assets/world-vfx`, made by `tools/world/sprites.py`, uploaded as Images) and 40 presets.<br>Every emitter is tagged `WorldFx` with `BaseRate` / `CullDist`.<br>Beams are used for the aurora ribbons. |

### Zones

| # | Zone | Landmark | Signature pieces | Ambience |
|---|---|---|---|---|
| 1 | Meadow | Red-roofed windmill on a stepped hill (sails turn) | fenced farm (hay, scarecrow, sunflowers), beehives, cart, stream + plank bridge, groves | pollen, butterflies, blossoms |
| 2 | Sandy Beach | Striped lighthouse on a rocky islet (beam sweeps) | open sea with rippling water, dock, palms, beach huts, umbrellas, shells, starfish | sea mist, sparkles, sand gusts |
| 3 | Autumn Forest | The Hollow Oak with a glowing door and treehouse | maples, evergreens, log cabin (chimney smoke), pumpkin patch, lantern posts | falling leaves |
| 4 | Mushroom Grove | The Mushroom Tower (spiral stair, glowing windows) | giant mushrooms in 4 cap colours, mushroom houses, root arches, glow shrooms | spores, ground mist, fireflies |
| 5 | Desert Dunes | The stepped Sun Pyramid with a golden sun disc | rock arch, palm oasis, ruins, pottery, saguaros, obelisks, dunes | sand swirls, heat glints |
| 6 | Snowy Peaks | The Summit Lodge (red A-frame, chimney plume) | snowy pines, frozen pond, sled, snowmen, snow cabin, massifs | snow, icy wind |
| 7 | Candy Land | The Gingerbread Castle (candy towers, gumdrops) | lollipop groves, candy-cane fences, giant donut, ice creams, cupcakes | sprinkles, star sparkles |
| 8 | Coral Reef | The Sunken Galleon (masts, sails, treasure) | lagoon water sheet, giant clam with a pearl, coral gardens, kelp | bubbles, surface sparkles |
| 9 | Volcano | The stepped volcano with lava lake + rivers | lava channels, basalt, lava rocks, charred trees, steam vents, obsidian | embers, ash, steam |
| 10 | Crystal Caves | The Crystal Spire with a floating shard halo | cave-rock rims, crystal arches, clusters in blue / pink, geodes | glimmers, spores, mist |
| 11 | Jungle Ruins | The stepped Jungle Temple with a glowing shrine | stone head, ruin walls, river, vines on the banks, dense jungle | jungle mist, fireflies, leaves |
| 12 | Neon City | The stepped Neon Tower with billboard ring | streets with lane dashes, storefronts, city blocks, neon lamps, hologram egg | neon pixels |
| 13 | Haunted Graveyard | The crooked Haunted Manor | fenced graveyards, crypt, friendly bobbing ghosts, jack-o'-lanterns, moon | ghost mist, wisps |
| 14 | Sky Islands | The Sky Temple island (waterfall off its edge) | sky road, cloud sea, floating islands + rope bridges, floating rocks | cloud drift, sparkles |
| 15 | Toxic Swamp | The giant Bog Cauldron (bubbling brew, ladle) | murky pools, stilt hut, boardwalks, twisted trees, pitcher plants, barrels | toxic bubbles, mist |
| 16 | Clockwork Factory | The Clock Tower factory (giant clock) | turning brass gears, pipes, boilers, conveyors, pistons | steam, sparks |
| 17 | Frozen Aurora | The Ice Palace with crystal spires | ice arches, snowflake sculpture, igloos, frozen trees, aurora ribbons | snow, aurora sparkles |
| 18 | Lava Core | The Molten Core (cube in crossed rings) | crack-grid slabs, magma pillars, heat obelisks, floating obsidian cubes | embers, ash |
| 19 | Galaxy Void | Ringed planet + moon in the sky, cosmic portal | star lamps, floating void platforms, meteors, celestial crystals, far planets | stars, cosmic dust |
| 20 | Rainbow Heaven | Rainbow Palace + a great rainbow | cloud pavilions, gold lamps, blossom gardens, floating clouds, the Heaven Gate | rainbow sparkles |

## No z-fighting, no see-through gaps

**Z-fighting:** `World/Coplanar.luau` finds faces that lie in one plane, face the same way and overlap, and pushes them apart:
- the smaller face (the detail) moves out by `eps`;
- when that part is protected, the larger face moves back instead.

It runs at two levels:
- **Inside every Kit template**, once per recipe, with `eps` 0.12 (scaled with the asset).
- **On the whole built map** in `MapBuilder.build` with `eps` 0.1, plus on a pen after each upgrade rebuild. It never touches gameplay parts:
  - parts with the LandingSurface tag (lanes and the ramp), shoulders, pen `Floor` / `PenArea`;
  - anything that collides in the kick pad / drop / safe line;
  - counters, signs and the ground;
  - anything with a prompt, SurfaceGui or click detector;
  - merchants and the Prize Wheel.

**Scan result** (Studio, a coplanar scanner that also checks whether the overlap can be seen): **3,076 visible z-fights → 1**. The one left is a 0.2 stud² same-colour overlap inside the Prize Wheel, which stays untouched because its rotor pivots from its rest pose.

**See-through gaps:** a ray-grid scan over each building found slits between the Boxing Sack Shop's stepped gable infill and its barrel roof, at both ends of the vault. The gables are now filled exactly under each roof segment. The town-house ridges sit into the apex.

What stays open is open by design:
- the shop counter and the Pet Stand stall;
- the well and gazebo;
- the lighthouse gallery;
- ship masts and the Hollow Oak treehouse.

**Hub wall:** from every lawn point at eye heights of 5 / 14 / 30 studs, rays toward the sides and the back reach nothing outside the hub through the wall.
- **0.04% / 0.07% / 0.39%** of rays leave over the wall top. All of them land on the game's own far mountains and clouds.
- None reach the ocean or the void.

## Gameplay contract (kept)

| Item | What stayed the same |
|---|---|
| Kick, ramp and safe line | `Map.KickPad` (`Top`), `Drop.Ramp` (LandingSurface), `Drop.PlayerBarrier` + collision groups, the safe line, and the attributes PlazaY / RampStart / RampEnd / CanyonWidth. |
| Lanes | Every `Zone<i>.Lane` keeps the same size and position and the LandingSurface tag. Shoulders still run to x = ±40. |
| Canyon walls | Replaced by **invisible collision walls on exactly the old planes** (`Zone<i>.Wall`, x = ±40, 50 tall, CanQuery off). |
| End wall | The same plane (`Finale.EndWall`). |
| Pens | `Bases.Base<i>`: attributes, `PenArea` (centre fixed, size by level), `Pen.Floor` tiles, `SpawnPoint` / `OwnerAnchor` / `PenSign` (UpgradePen prompt). |
| Shop | `BoxingSackShop`: `Counter` prompt OpenMenu:Store, `Sign`, `Approach`, the Coach spot. |
| Stand | `PetSellingStand`: `Counter` prompt OpenMenu:Inventory, `Approach`, the PetSeller spot. |
| Hub fixtures | Wheel, boards, `SafeZone.Spawn`, `EdgeBarrier`.<br>The side boundary is now the solid hub wall: inner faces at x = ±195 and z = −390, where the old invisible `CliffWall` proxies were. |
| Decoration | Never collides, never takes touches and never blocks raycasts.<br>Walkable terraces and stairs collide.<br>Trees, lamps, houses, hedges, fountain, benches and fences get invisible proxies.<br>The hub wall is solid: it collides and blocks the camera. |

## Asset manifest

All models are **Luau brick recipes** in `src/shared/Builders/Map/World/Recipes/`, cloned through `World/Kit` and coloured by role from `World/Palettes`. 227 recipes:

- **Nature** (44): 7 broadleaf trees, 2 poplars, 5 pines (2 snowy), 4 bushes, 5 rocks, 3 slab stacks, 4 terrain banks, 3 hills, 3 mountains, flowers, grass, stump, log, small mushrooms.
- **Hub** (37): shop roof, glove, awning, pillar, window, gym props, stand canopy, paw sign, posts, egg crates, pet props, bunting, the Golden Egg centrepiece, egg monument, fence / gate posts and rails, lamp, bench, crate, barrel, lantern, signpost, planter, flag pole, plank bridge, 2 town houses, gazebo, well, hedge.
- **Zones1** (37), **Zones2** (34), **Zones3** (36), **Zones4** (27), **Zones5** (12): landmarks and props per zone (tables above).

**Sprites:** `assets/world-vfx/wfx_*.png` (20 files), ids in `src/shared/VFX/WorldSprites.luau`, uploaded by user 1340874349.

The Blender mesh pipeline (`tools/world/blender`, `upload.py`, `lune/assemble.luau`) was built and verified first: low-poly meshes were uploaded through Open Cloud and imported as MeshParts. It was **retired for in-game use** after the classic-brick decision; nothing in the game references those meshes. It stays in `tools/world` for future mesh work (see `tools/world/README.md`).

## Performance

| Measure | Value |
|---|---|
| Map build (Studio, server) | ~1.7–2.4 s, including the z-fight pass (below) |
| Map parts | **~16.8k** (old map 8.5k):<br>• zones ~12.3k (~450–1,200 each);<br>• hub ~4.2k, of which the six Kick Sack display meshes in the shop are ~0.6k.<br>Over the ~15k Balanced target; the density knob `Valley.DENSITY` (0.42) and `Valley.patches` counts trade parts for density. |
| Lights | 87 lights, none of them cast shadows. |
| Emitters | 114 in total.<br>The 110 new ones are tagged `WorldFx`: distance-culled (default 200 studs) and rate-scaled by graphics quality. |
| Collision | Decoration has CanCollide / CanTouch / CanQuery off.<br>Small props and far silhouettes have CastShadow off. |
| Motion budget | 60 sway / bob models per frame, near the camera only (220 studs).<br>No motion at graphics quality 1–2. |

## Testing (Studio, 2026-10-16)

**Full-loop playtest** (`tools/playtest`, ~105 s) covers HUD, the tutorial, a Perfect kick to zone 5, flight, the zone bar, steering home over the ramp, EggSecured, placing and hatching in a pen, pet pick up and place, the shop and stand prompts, sounds and respawn. It was run in the open place:

| Run | Result |
|---|---|
| Remodel, run 1 | 1 FAIL: `sound plays and loads: PetPlace (nothing played)`. |
| Base `b/spin-wheel` code, same place | 0 FAIL. |
| Remodel, run 2 | **0 FAIL**: PetPlace played, and the perfect kick (466 studs, zone 5), steering home and EggSecured all passed. |

PetPlace is played by `PlotController` only when the pet model arrives within 2 s of `PlacedAt`; this branch does not touch that code. Treat it as a timing flake, but keep an eye on it.

**Client checks in Play:**
- No client errors.
- Sway, spin, bob and water scrolling all move (sampled parts at the hub and zone 14).
- Emitters are culled by distance: 19 of 110 run near the hub.
- The Zone 17 aurora beams render in the sky.

**Map build:** 1.04 s and 17,463 parts at first. With the hub wall and the z-fight pass it is 1.7–2.4 s and 16,783 parts.

**Screenshots:** before / after sets from the same camera positions, kept in the side-session notes.

## Not done / needs follow-up

- **Part budget.** ~16.8k parts against the ~15k Balanced target. Lower `Valley.DENSITY` or the patch counts if mobile frame time suffers. Not yet profiled on a real phone.
- **Global shadows.** `Lighting.GlobalShadows` is off in the place file and left as is. Turning it on grounds trees and houses a little more but costs frame time on mobile. That is a taste and performance call.
- **Partner B's folder.** `src/client/Controllers/WorldLifeController.luau` is a new file there. It only starts `VFX/Ambient`.
- **Retired mesh pipeline.** Its uploaded meshes and models are unused. They can be archived on Roblox.
- **Mobile.** Not tested on a phone or the Studio device emulator. Only Studio desktop at quality level 10.
