# Kick the Egg!

Kick an egg down a runway through 20 zones and watch it spin through each zone's eggs until it lands
on a random one. It sprouts legs and runs for its life from a themed avalanche, so sprint out, grab it
and get back to safety before you're crushed. Then hatch it on your plot and collect cool bricky
pets with size and weather mutations.

## Setup (both partners)
1. Install [Rokit](https://github.com/rojo-rbx/rokit), then run `rokit install` in this folder.
2. Install the Rojo plugin in Roblox Studio.
3. `rojo serve`, then press **Connect** in the Studio Rojo plugin.
4. Open Claude Code in this folder and paste your prompt from `docs/PROMPT_PARTNER_A.md` or
   `docs/PROMPT_PARTNER_B.md`, filling in the current task from `docs/TASKS.md`.

## Workflow
- Branch per task: `b/<feature>` or `a/<feature>`, PR into `main`, the other partner merges.
- Contract files (see `CLAUDE.md`) only change through a `contract: ...` PR.
- Play-test together at the end of each milestone.
