# Animation notes

## Rigs

The bones sit at the BlockBuilder joint pivots and use the same names as the game's Motor6D joints (`Body`, `Head`,
`ArmL`...). Skinning is rigid: every mesh is weighted 100% to one bone, so nothing stretches.

- **Bone axes.** Bones point up, so each bone's X axis is the pet's side axis, Y is up and Z is backwards.
  - +X rotation lifts the front or swings a foot forward.
  - Y rotation turns.
  - Z rotation rolls.
- **Heavenly Lion (quadruped).** Root → Body → Head and Tail. Root → ArmL, ArmR (front legs), LegL, LegR. The legs
  hang off Root so the paws stay planted while the body breathes and bobs.
- **Prism Seraph (floating).** Root → Body → Head, ArmL/R, WingL/R, Halo, Orbit. Orbit carries the floating diamond
  crystals and gold stars. Halo carries the small spinning ring.
- **Clockwork Titan (rigid mechanical).** Root → Body → Head, ArmL/R, HeartHands, Gear1-7. Root → LegL, LegR.
  HeartHands is the chest clock's hands, pivoting on the clock centre. Gear1-7 are the chest gears, each on its own
  axle.

## Clips (30 fps)

| Pet | Clip | Frames (s) | Loop | What it does |
|---|---|---|---|---|
| Lion | `HeavenlyLion_Idle` | 72 (2.4) | yes | breathing body bob, head nod and turn, tail sway |
| Lion | `HeavenlyLion_Walk` | 32 (1.07) | yes | diagonal-pair stride ±18°, body bob twice per cycle, roll, head counter-nod, tail sway |
| Lion | `HeavenlyLion_Special` | 60 (2.0) | no | majestic head raise (22°), the body rises and rears slightly, the tail lifts, then settles |
| Seraph | `PrismSeraph_Idle` | 72 (2.4) | yes | hover bob 0.25, slow wing flap ±10°, Orbit turns once, the halo counter-turns, arms and head drift |
| Seraph | `PrismSeraph_Float` | 48 (1.6) | yes | leans 8° into travel, faster flap ±18°, bank roll, Orbit and halo turn once |
| Seraph | `PrismSeraph_Special` | 60 (2.0) | no | wings spread 26°, arms open, head lifts, rises 0.4, Orbit spins twice |
| Titan | `ClockworkTitan_Idle` | 72 (2.4) | yes | mechanical breathing, arm sway, head scan, clock hands turn once, gears turn a quarter (alternating) |
| Titan | `ClockworkTitan_Walk` | 40 (1.33) | yes | heavy alternating stride ±14°, arms counter-swing ±10°, the body drops on each footfall, the clock runs |
| Titan | `ClockworkTitan_Special` | 60 (2.0) | no | fists raised 55°, leans back, the clock hands spin four times, gears make a full turn |

The 4-frame strips (`Animations/*_strip.png`) show each clip from the hero angle.

## Bringing them into Roblox

1. **Import the model.** File > Import 3D with `<Name>.fbx` (or `.glb`) as a rigged model. Roblox creates MeshParts
   with Bone instances under the root part. Check that the size matches the README table.
2. **Import each clip.** Put an AnimationController with an Animator on the model. In the Animation Editor, use
   Import > From FBX Animation with `Animations/<Name>_<Clip>.fbx`, one take per file. Publish the clips and play them
   with `Animator:LoadAnimation`.
3. **Pair the effects.** Line up the Special clip with the pet's flourish. The PetFx specials already listen for the
   `PetFxSpecial` attribute (see VFXSpecifications).

## How this relates to the game today

The game animates pets procedurally (`src/shared/Anim/Pet.luau`): it moves the Motor6D joints of BlockBuilder models,
with tempo and flourish by rarity. The mesh pets can join the game in either of two ways. This is a decision for
Partners A and B (CLAUDE.md rule 3):

- **Option A: rigid MeshParts on Motor6Ds.** Import each bone's meshes as separate MeshParts, joined to a Root part by
  Motor6Ds named after the bones. The existing `Anim/Pet`, PetFx, size mutations (`Model:ScaleTo`) and pen roaming work
  unchanged. The clips here are then reference motion.
- **Option B: skinned model plus Animator.** Use the imported rig and play these clips. `Anim/Pet` would need an
  Animator path for these three pets.

Option A needs the least code change, because the pivots and joint names already match.
