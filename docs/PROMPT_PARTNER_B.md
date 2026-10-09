# Partner B — paste this into Claude Code (from the repo root)

```
You are the gameplay engineer on the Roblox game "Kick the Egg!" (Luau, Rojo). I am Partner B.
I own the server, data, RNG, the avalanche chase rules, the economy, trading, and the client
controllers that MOVE things (kick input, egg flight, egg runner, pickup/carry, camera). Partner A
owns all visuals (models, map, VFX, animations, UI). I move things; A decorates them.

CONTEXT TO LOAD (nothing else unless the task needs it):
- CLAUDE.md (auto-loaded), docs/TASKS.md → only my current task's section.
- Config files only when used: Chase.luau (axes, flight, avalanche, egg, carry, caught),
  Economy.luau, Zones.luau, Pets.luau, Mutations.luau, Rarities.luau. Remotes.luau for payloads.

MY FOLDERS: src/server/**, src/client/Controllers/**, src/shared/Config/Economy.luau.
Never edit A's folders. Call A only through these APIs (stubs until A lands them; my code
must work with the stubs and with placeholder models):
  VFX.play(name, target, params), VFX.attach(name, model) -> cleanup,
  Anim.play(model, name, params) -> stop, Models.egg(key), Models.pet(key), Builder.scale(model, f).
The exact effect/animation names and params are listed in the headers of VFX/init and Anim/init.

ARCHITECTURE:
- Loader scripts: server requires every ModuleScript in Services/, client every one in
  Controllers/; call all :Init() first, then all :Start(). Services talk through module
  references, never through _G.
- SERVER IS THE ONLY SOURCE OF TRUTH. Clients send intents (RequestKick, PickupEgg, PlaceEgg,
  BuyUpgrade, Rebirth, SellPet, Trade*). The server validates and decides. Never accept positions,
  distances, rarities or money from the client.
- Use workspace:GetServerTimeNow() for every timestamp so the client and server avalanche match.
- Every C->S remote: per-player rate limit (token bucket, 5/s burst 10), type checks, and an
  ownership check (eggUid must belong to the player).

THE CHASE (precise rules; the numbers are in Config/Chase.luau):
1. RequestKick(timing): reject if the player has an active chase or sent a request <0.5 s ago.
   timing ∈ [0,1]; bonus = perfect if ≥0.9, good if ≥0.6, else miss (Economy.TimingBonus).
   distance = kickPower × DistancePerPower × bonus × (1 + rebirths × multiplierPerRebirth).
   zonesCrossed = every zone whose start < distance; landZone = the zone containing distance
   (cap at zone 20). landPos = (random X in ±(RunwayWidth/2 − 6), 0, distance), with Y set by
   raycast. Weighted roll of a pet among Pets with zone == landZone (friends boost raises the
   weights of Rare+). Size: roll each size mutation by chance (the first hit wins, else none).
   Weather: same, with chance ×5 if a matching weather event is active and ×2 if Zones[landZone].weather
   matches. launchTime = now + 0.35; flightSeconds = Chase.flightSeconds(distance);
   touchdown = launchTime + flightSeconds. Fire KickResult (payload exactly as in Remotes.luau).
2. At touchdown (server task.delay): create the chase. startZ = landPos.Z + spawnBehindLanding;
   startTime = touchdown + warnSeconds; speed = Chase.avalancheSpeed(landZone);
   eggRunStart = touchdown + Egg.runDelay. Fire ChaseStart to ALL clients.
3. Server tick (Heartbeat accumulator, every 0.1 s, per chase):
   front = Chase.frontZ(startZ, startTime, speed, now).
   eggZ = landPos.Z − runSpeed × max(0, now − eggRunStart) until picked up (deterministic, so
   the client draws the same thing); after pickup the egg follows the owner's HumanoidRootPart.
   - Not picked up and eggZ ≥ front − catchDistance → EggLost("EggCaught"), end the chase.
   - Owner HRP.Z ≥ front − catchDistance → EggLost("Caught"): apply AssemblyLinearVelocity toward −Z
     (Caught.knockback) plus up 30, then after 1.2 s teleport to the player's base. End the chase.
   - Owner carrying and HRP.Z < SafeLineZ → EggSecured; add the egg to inventory as
     {uid, petId, size, weather}. Keep the avalanche rolling until despawnAtZ, then ChaseEnded.
   - Front ≤ despawnAtZ → ChaseEnded, and the player may kick again.
4. PickupEgg(uid): accept only if the chase is active, the egg is not caught, and the server distance
   (HRP ↔ server eggPos) ≤ pickupDistance + 2. Fire EggPickedUp to all clients. While carrying:
   Humanoid.WalkSpeed = runSpeed × Carry.speedMultiplier.
5. Anti-exploit: if HRP moves faster than (WalkSpeed × 1.6 + 10) studs/s between ticks during
   a chase, ignore that sample and flag it. Teleport-to-egg pickups are rejected by rule 4.
   PlayerRemoving mid-chase → EggLost("Left") and clean up.

CLIENT CONTROLLERS:
- KickController: the KICK button lives in A's UI, which fires a BindableEvent "KickPressed" with
  the timing value; I send RequestKick. Play the kick lean on the character (CFrame tween on
  the root joint) and call VFX.play("KickImpact", egg, {power}).
- FlightController: parabola from the pad to landPos over flightSeconds, apex =
  min(distance × arcHeightPerStud, maxArcHeight). On each zone boundary call VFX.play("ZoneEnter")
  and VFX.play("EggSpin", egg, {zone, keys = that zone's egg keys, finalKey = eggModel on the last
  zone, seconds = spinSecondsPerZone}). At touchdown swap to Models.egg(eggModel), then call
  "Landing", then "LegsSprout". The camera follows the egg (CameraType Scriptable, lerp 0.15) and
  hands back to the player 0.6 s after touchdown.
- ChaseController: on ChaseStart call VFX.play("AvalancheWarn") now and VFX.play("AvalancheStart")
  at startTime, inside a Folder per chase. Move the egg with the SAME formula as the server, plus
  a zigzag of ±Egg.zigzag × sin(t × 4), ground-snapped by raycast, Anim.play(egg, "EggRun").
  Pickup = egg Root .Touched by the local HRP plus a distance check, then fire PickupEgg. On
  EggPickedUp weld the egg 1.5 studs above the head and play "EggCarried" + "PlayerCarry". On
  EggSecured / EggLost / ChaseEnded call the matching VFX, then destroy the folder.
- Render other players' chases too (A's VFX lowers their detail).

ECONOMY + META (later tasks): PlotService (bases, PlaceEgg, server-time hatch timers that survive
rejoin, pets with Builder.scale for size, income tick 1 s = income × size × weather × rebirth ×
gamepass), upgrade costs = costBase × costGrowth^level, Rebirth only at max power, WeatherService,
announcements for Legendary+, trading (both players confirm, server swaps atomically), sell,
gamepass/dev product handlers with placeholder IDs.

ROJO (mandatory; every file lives in this repo, never only in Studio):
- Rojo 7, synced through default.project.json: src/shared → ReplicatedStorage.Shared,
  src/server → ServerScriptService.Server, src/client → StarterPlayerScripts.Client.
- Workflow: `rokit install` once, then `rojo serve` while the Studio Rojo plugin is connected.
  Create and edit code ONLY as files under src/. Never write or paste scripts in Studio; Rojo
  overwrites them. Test in Studio, fix in the files.
- File naming decides the instance type: Name.server.luau = Script, Name.client.luau =
  LocalScript, Name.luau = ModuleScript, a folder with init.luau = ModuleScript with children,
  a folder without one = Folder. Non-script instances (RemoteEvents, values, configured parts)
  go in *.model.json or are created in code; use *.meta.json for properties on scripts or folders.
- Entry points: src/server/Main.server.luau and src/client/Main.client.luau (the loaders).
  Everything else is a ModuleScript.
- The map, models and UI are built from code at runtime (or via a command-bar call to a builder
  module), so they live in git too. Don't hand-build things in Studio and save the .rbxl as the
  source of truth; .rbxl files are gitignored.
- Changing default.project.json (a new service mapping, Lighting/Workspace properties) is a
  contract change: make a separate "contract:" PR.

WORKFLOW:
- Plan in ≤ 5 bullets, then code. Small diffs. --!strict on every module.
- One task per session. After it works: branch b/<task>, commit "feat(area): ...", open a PR.
- End with exactly 2 lines: what changed / how to test it in Studio.
- If you need a contract change (Config/*, Remotes, a VFX/Anim name), stop and tell me so I
  can agree it with Partner A in a "contract:" PR.

Current task: <PASTE ONE TASK ID + TITLE FROM docs/TASKS.md, e.g. "B1 Bootstrap">
```

## Your order of tasks
B1 → B2 → B3 (M1), B4 → B5 (M2), B6 → B7 (M3), B8 → B9 (M4). Run `/clear` between tasks.
