# Zone 1 Meadow: 8 pets and 8 eggs

Block models (Roblox primitives for `BlockBuilder`, studs on top faces only), built to the user's reference images.
The user approved them on 2026-11-01. They are **not wired into the game yet**: no `Config` or `Pets/` entry points
at them.

| Key | Pet | Rarity | Pet parts | Egg parts | Joints |
|---|---|---|---|---|---|
| Piproot | Piproot | Common | 124 | 88 | Body, Head, Jaw, Throat, ArmL/R, LegL/R |
| HoneybackBeetle | Honeyback Beetle | Uncommon | 217 | 138 | Body, Head, AntennaL/R, ShellL/R, WingL/R, LegL1-3, LegR1-3 |
| Crownstag | Crownstag | Rare | 203 | 150 | Body, Neck, Head, ArmL/R, LegL/R, Tail |
| ThistlebackHedgehog | Thistleback Hedgehog | Epic | 246 | 103 | Body, Quills, Head, ArmL/R, LegL/R |
| BloomcrestCrane | Bloomcrest Crane | Legendary | 276 | 77 | Body, Neck, Head, WingL/R, Tail, LegL/R |
| BurrowMonarch | The Burrow Monarch | Mythic | 246 | 79 | Body, Head, EarL/R, ArmL/R, LegL/R, Tail, Rocks |
| WalkingOrchard | The Walking Orchard | Divine | 486 | 151 | Body, Neck, Head, AntlerL/R, ArmL/R, LegL/R, Tail |
| FirstSeed | The First Seed | Secret | 447 | 201 | Body, Core, Head, Halo, PlateL/R, ArmL/R, RootL/R, LegL/R |

Each folder holds `<Key>.luau` (returns `{ egg = Spec, pet = Spec }`), `<Key>.meta.json` and `Source/<Key>_blocks.blend`.
Eggs keep the classic stepped shell (`Shell<n>` in the Body joint), so the sprouted chase legs, incubation growth and
hold-E hatching work unchanged. Parts that open on hatching are named `Plate*`, `Petal*`, `Arch*` or `Shard*`.

The written roster wins over the rarity labels printed on the reference images (Orchard = Divine, First Seed = Secret).

## Rebuild

The source of truth is the Python in `tools/blender/pets/zone1/` (one module per pet, plus `eggs.py`). Edit it there
and re-export rather than editing the `.luau` by hand. Blender must be running with the MCP add-on.

```
cd tools/blender/pets
python -I bmcp.py code z1build.py -- what=Piproot kind=both export=1 views=front34,front,side,back34 res=480
```

Renders go to `tools/blender/pets/out/z1/` (ignored by git).
