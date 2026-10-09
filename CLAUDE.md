# Kick the Egg! — rules for Claude Code (read this, then only the files your task needs)

Roblox game, Luau, synced with Rojo (`default.project.json`). Two partners work in parallel:
**Partner A = art/models/VFX/UI**, **Partner B = gameplay/server/data**. See `docs/TASKS.md` for who owns what.

## The core loop (exact order; numbers live in `Config/Chase.luau`)
1. **Kick.** Player stands on the kick pad (0,0,0) and taps KICK; a timing meter sets `timing` 0..1.
   The server rolls distance, landing zone, egg/pet (weighted per zone), size and weather mutation,
   and fires `KickResult`. The player cannot kick again until this chase ends.
2. **Flight.** The egg flies along +Z in an arc for `Chase.flightSeconds(distance)`. Every time it
   enters a new zone it plays `EggSpin`: a fast spin that cycles through that zone's egg models like a
   slot machine. The last spin slows down and stops on the rolled egg.
3. **Touchdown.** Dust burst, a light pillar in the rarity color, and stubby blocky legs sprout out
   (`LegsSprout`, squash and stretch).
4. **Avalanche.** The ground shakes and a "RUN!" banner appears for `warnSeconds`. Then a themed
   avalanche (rock, snow, lava, candy… per zone) bursts out of the ground 60 studs behind the egg and
   rolls toward the bases (-Z) at `Chase.avalancheSpeed(landZone)`, chasing everything in its path.
5. **Steer the egg.** Once its legs have sprouted (`Egg.runDelay`), the kicker takes control of the
   egg: their movement input (keyboard / thumbstick, camera-relative) steers the legged egg, the
   camera follows it, and their character waits where it is. The egg is a server model at
   `workspace.Chases[eggUid]` that the owner's client drives physically; the server validates it.
6. **Race home.** Steer the egg back toward the bases ahead of the avalanche. Egg speed = the
   player's Run Speed, bought in the shop. Faster eggs survive farther zones.
7. **Outcome.** The egg crosses the safe line (Z < -6) → `EggSecured`, and the egg goes into the
   inventory. If the avalanche front reaches the egg → `EggLost` ("EggCaught"): the egg shatters.
8. **Hatch and earn.** The secured egg is placed on a plot pedestal, wobbles and cracks over
   `hatchSeconds`, and bursts into its pet. Pets keep their size/weather mutation and earn $/s,
   which piles up on their pedestal until the owner steps onto it to collect it.
9. **Shop and strength.** Money buys more Run Speed or a better training tool. Strength (kick power,
   how far you kick) is trained by clicking with the tool; better tools add more per click. At max
   strength the player can Rebirth.

The avalanche only hurts its owner. Other players see it but are never caught by it.

## Hard rules
1. **Server decides everything.** Distance, landing zone, egg roll and mutations are rolled on the
   server at kick time and sent to the client. The client only animates. Never trust client values.
2. **Data-driven.** Zones, eggs, pets, rarities and mutations live in `src/shared/Config/*`.
   Do not hardcode balance numbers anywhere else.
3. **Models are data, not meshes.** Every egg and pet is a Luau table of blocks consumed by
   `src/shared/Builders/BlockBuilder.luau`. No imported meshes, no Toolbox assets.
4. **Contracts are frozen.** `Config/*`, `Shared/Remotes.luau` and the `BlockBuilder` API are shared.
   To change them, make a small separate PR titled `contract: ...` and tell your partner.
5. Stay inside your own folders (see TASKS.md) to avoid merge conflicts.

## Art style (applies to every visual)
- Classic Roblox brick look: chunky blocks, bright saturated colors, `SmoothPlastic`
  with a stud texture, WedgeParts for slopes, `Neon` only for accents and glow.
- **Visually stunning but bricky:** layered silhouettes, 2–3 tone palettes per pet, glowing
  eyes, horns, wings, crystals, armor plates, floating orbiting cubes, auras and trails.
  Rarer = bigger, more parts, more glow and more particles.
- Animations are procedural (Motor6D + TweenService/RunService): squash and stretch, bob,
  waddle, blink, hop. Everything should feel bouncy.
- Claude Design may be used for UI mockups, egg/pet concept sheets and palettes before coding.

## Token-saving rules (important; both partners are on Claude Pro)
- Read only the files you need. Don't re-read files you just wrote. Don't scan the whole repo.
- One task per session. Run `/clear` between tasks and `/compact` when a session gets long.
- Plan in at most 5 bullet points, then write code. No long explanations in replies.
- Prefer `Edit` with small diffs over rewriting whole files.
- Don't spawn subagents unless asked.
- Pets and eggs are DATA: add a new one by adding a table entry, not new code.
- Put routine work (renames, config tweaks, adding entries) on a cheaper model (`/model sonnet`).
- Finish with a 2-line summary: what changed and how to test it in Studio.

## Conventions
- Files `.luau`, `--!strict` on every module, StyLua formatting, PascalCase modules.
- Services on the server (`src/server/Services`), controllers on the client
  (`src/client/Controllers`), each exposes `:Init()` and `:Start()`.
- Commit messages: `feat(area): ...`, `fix(area): ...`, `contract: ...`.
- Branches: `b/<feature>` for Partner B, `a/<feature>` for Partner A. PR into `main`.
