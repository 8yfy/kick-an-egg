# Development handoff

The shared "where are we" file for both developers. Update it at every meaningful checkpoint, in the same commit
as the work. Keep it short: details belong in the PRs and the feature docs (`docs/*.md`). Ownership rules:
`CLAUDE.md` and `docs/TASKS.md`.

_Last updated: 2026-10-20 by Partner B (kkronos287-ux)._

## Branches and PRs in flight
`main` is behind: nothing since the early Partner A merges (#4–#15) is merged. All work below is in open PRs, and
each Partner A branch is built on top of `b/spin-wheel`.

| PR | Branch | Owner | What | Status |
|---|---|---|---|---|
| #41 | `b/spin-wheel` | B | Five-pen hub, Prize Wheel, leaderboards, Boxing Sack Shop remodel, egg-placement fix, `/weather` command, Weather HUD card (not mounted) | Open; base for all of A's branches |
| #45 | `a/world-remodel` | A | Classic-brick world remodel: hub village, 20 zones, ambient life | Open |
| #46 | `a/premium-sfx` | A | Premium SFX (sound sheets + loops), wheel/throw/menu events | Open |
| #43 | `a/custom-inventory` | A | Bag with equip, one hotbar incl. the Boxing Sack, live 3D models | Open |
| #44 | `a/pet-merchant-id` | A | Pet Merchant avatar UserId | Open |
| #42 | `a/hud-trade-pets-icons` | A | Trade HUD button in the approved icon set | Open |
| #37–#39 | `b/hud-final`, `b/sack-vfx-perf`, `b/gameplay-rework` | B | Older stacked B work, already contained in `b/spin-wheel` | Open; close once #41 merges |

**Suggested merge order:** #41 → #45 → #46 → #43 → #44 → #42.

**Combined check (2026-10-17):** all five A branches merge together cleanly on top of #41. `sh tools/run-tests.sh` gave
362/365. The 3 failures are Partner B's map-overhaul tests, which describe the pre-remodel map and need updating
for #45:
- 5 shop lights, where the test allows at most 4;
- pen dressing up to 2.4 studs outside the reserve;
- no `SafeZone.Decor` folder.

## Tests
- **#41:** 373/373 unit tests, live playtest 144/144, and every Studio chat command tested through real chat
  (`docs/MapOverhaul.md`).
- **#46:** the Studio suite was not run on A's machine (no `run-in-roblox` there). It ran in the combined check above.

## Known issues / waiting on someone
- **Weather HUD card** (`UI/Hud/WeatherHud.luau`): built, not mounted. Waiting for the owner's design approval
  (Studio renders and review page in #41). After approval:
  - upload the 6 weather icons (`tools/weather-icons/render_icons.py`; the PNGs live outside git);
  - add their ids to `AssetIds`;
  - mount the card in `UI/init.luau`.
- **Before going live:**
  - set Max Players = 5;
  - fill in the dev product ids for wheel spins and donations (currently 0, which shows "Not on sale").
- **KICK button shimmer** is not clipped to the button and is briefly visible beside it on phones
  (`UI/Hud/KickPanel.luau`). Not fixed.

## Next steps
1. Partner B: update the 3 map tests for #45's world, then merge in the order above.
2. Weather: approve the card, then mount it. Optional extras: world weather effects and a live owner-only `/weather`.

## Tooling on Partner B's workstation (2026-10-20)
- **Claude Code skills (user level, `~/.claude/skills`, outside git):**
  - `animate-roblox-characters`;
  - 32 skills from `arjun988/blender-skills`;
  - 11 `roblox-*` skills from `nonlooped/roblox-suite`.
  - Source commits are in `~/.claude/skills/SOURCES.txt`.
- **MCP servers (user level):**
  - `blender` (`uvx mcp-for-blender`, telemetry off; add-on 1.30 enabled in Blender 4.5);
  - `roblox-studio` (Studio's built-in server via `%LOCALAPPDATA%\Roblox\mcp.bat`).
- **Repo tools (rokit):** Rojo 7.7.1, StyLua 2.0.2, Selene 0.28.0, plus luau-lsp 1.70.1 and `run-in-roblox` for
  `tools/run-tests.sh` and `tools/playtest/playtest.sh`.
