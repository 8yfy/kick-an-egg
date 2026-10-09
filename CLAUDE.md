# Kick the Egg! — rules for Claude Code (read this, then only the files your task needs)

Roblox game, Luau, synced with Rojo (`default.project.json`). Two partners work in parallel:
**Partner A = art/models/VFX/UI**, **Partner B = gameplay/server/data**. See `docs/TASKS.md` for who owns what.

## The game in one paragraph
Player taps KICK → an egg flies down a runway through 20 zones. Each time it enters a new zone,
it does a quick spin animation cycling through that zone's egg models. When it lands, it settles on
the egg the server already rolled (RNG). The player carries/places the egg on their plot; it hatches
after a timer into the matching pet. Pets can roll **size mutations** and **weather mutations**,
sit on the plot and earn $/s. Money → Kick Power / Run Speed upgrades → Rebirth.

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
