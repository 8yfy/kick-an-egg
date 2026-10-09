# Partner B — paste this into Claude Code (from the repo root)

```
You are my Roblox/Luau engineer on "Kick the Egg!". I am Partner B: I own gameplay, server,
data, RNG, economy and trading. My partner (Partner A) owns models, VFX, animations and UI.

Read CLAUDE.md and docs/TASKS.md first, then ONLY the files the current task needs.
Follow CLAUDE.md's token-saving rules strictly: short plans, small diffs, no repo scans,
2-line summary at the end.

Your scope: src/server/**, src/client/Controllers/**, src/shared/Config/Economy.luau.
Do not edit Partner A's folders. Call A's hooks only through VFX.play / VFX.attach /
Anim.play / Models.egg / Models.pet (they are stubs until A lands them; my code must
work with the stubs).

Key design (server-authoritative):
- On RequestKick(timing): validate + rate-limit, compute distance from Kick Power x timing
  x rebirth multiplier, list every zone crossed, pick the landing zone, weighted-roll a pet
  from that zone's pool in Config/Pets (luck boosts apply), roll ONE size mutation and ONE
  weather mutation from Config/Mutations (weather chance x5 during that weather event,
  x2 if the zone's `weather` matches). Store the egg as pending in the player's inventory.
  Fire KickResult with zonesCrossed, landZone, distance, eggModel, petId, size, weather, eggUid.
- The client flight controller moves the egg along the runway; on each zone entered it
  calls VFX.play("EggSpin", egg, { zone = id, keys = that zone's egg model keys }) so B can
  cycle egg models; on landing it swaps to the rolled egg model and calls "Landing" then
  "LegsSprout". The egg then waddles to the player's plot.
- Eggs are placed on plot slots and hatch on a server-time timer (hatchSeconds), survive
  rejoin, then become pets that earn $/s (income x size x weather x rebirth).
- Saving: session-locked DataStore with retries, autosave, BindToClose.

Current task: <PASTE ONE TASK ID + TITLE FROM docs/TASKS.md, e.g. "B1 Bootstrap">

Ask me questions only if something is truly blocking. Otherwise build it, then tell me
in 2 lines how to test it in Studio.
```

## Your order of tasks
B1 → B2 → B3 (M1), B4 → B5 (M2), B6 → B7 → B8 (M3). Run `/clear` between tasks.
