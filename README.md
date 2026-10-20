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

## Build the current assembled Studio file

As of 2026-10-20, the completed tutorial, pen feedback, Shift Lock fixes, shop labels and podiums
are on **`codex/reactive-tutorial`**. They have not been merged into `main`. See
[`docs/DEVELOPMENT_HANDOFF.md`](docs/DEVELOPMENT_HANDOFF.md) for the current checkpoint.

To build in a fresh folder without changing an existing checkout:

```sh
git clone --branch codex/reactive-tutorial --single-branch https://github.com/8yfy/kick-an-egg.git kick-an-egg-tutorial
cd kick-an-egg-tutorial
rokit install
rojo build default.project.json --output KickTheEgg.rbxl
```

Open the newly built `KickTheEgg.rbxl` in Studio and press **Play**. The map is generated when
the server starts, so an empty Workspace in Edit mode is expected. A standalone build does not
require Blender, MCP or a running Rojo server.

The tutorial remembers completion and skipping. On an existing account, use
**Settings → Tutorial → REPLAY** to show its welcome panel again; replay preserves saved progress.
The current version has a red welcome panel, contextual steps, dimming and a bouncing red arrow.
If the Tutorial/REPLAY row is missing, verify the branch and that Studio opened the new output file.
If Rojo live sync is connected, make sure it serves this same checkout; stop and restart Play
after changing branches or syncing scripts.

## Workflow
- Branch per task: `b/<feature>` or `a/<feature>`, PR into `main`, the other partner merges.
- Contract files (see `CLAUDE.md`) only change through a `contract: ...` PR.
- Play-test together at the end of each milestone.
