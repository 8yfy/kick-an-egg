# Admin panel

A secure in-game admin panel for Kick the Egg: dashboard, players, Model Lab, pets & eggs QA, animations, VFX,
weather & events, an approved-command runner, game controls, audit logs and settings. Branch `a/admin-panel`.

The panel is **not** the security boundary. Every request goes through one server pipeline that checks the real
UserId against a server-only allowlist, the role's permissions, the parameters, scope, limits and rate, then runs a
registered handler and writes an audit entry. No system is unhackable; this one is built so every attack we could
think of fails closed, and those attacks are tested (see "Threat model and tests").

## Layout (no game-wide reorganisation)

| Where | What |
|---|---|
| `src/server/Services/AdminService.luau` | Entry point (picked up by the existing service loader): builds the pipeline, delivers the client, applies global state on start. |
| `src/server/Admin/Allowlist.luau` | **The only source of access**: numeric UserId → `Owner` / `Developer` / `Tester`. |
| `src/server/Admin/Config.luau` | Roles → permissions, limits, environments (staging/production universes), cross-server settings. |
| `src/server/Admin/Authorization.luau` · `Schema.luau` · `Limiter.luau` · `Audit.luau` · `Envelope.luau` · `Pipeline.luau` | Pure modules (no Roblox services): allowlist lookup, parameter schemas, rate limits, audit ring buffer, cross-server envelope checks, the central pipeline. Unit-tested with Lune. |
| `src/server/Admin/Commands/*.luau` | The command registry, by area: `Core`, `Players`, `Lab`, `World`, `Controls`. |
| `src/server/Admin/ModelLab.luau` · `Catalog.luau` | Model Lab server (platform, spawning, transforms, measurements, QA checks, test pen) and the registry of spawnable models / animations / effects. |
| `src/server/Admin/CrossServer.luau` · `Environment.luau` · `Flags.luau` · `Diagnostics.luau` | MessagingService + MemoryStore, studio/staging/production, registered feature flags, dashboard numbers. |
| `src/server/Admin/Client/` | The admin client (window, widgets, 11 tabs, lab renderer). It lives in ServerScriptService and is **only cloned into an allowlisted player's PlayerGui**. |
| `ServerStorage.AdminPreviewAssets` | Created at start if missing. Drop Models here in Studio (e.g. `IceDragon_V1`) to compare them with live models. Not mapped by Rojo, so Studio content isn't overwritten. |
| `workspace.AdminLab` | The Model Lab platform, built only the first time an admin uses the lab (X −900, Y 260: far west of the runway, high up). |

Nothing admin-related is put in ReplicatedStorage, `Remotes.luau` and `Config/*` are untouched.

**Partner B call-outs (server area):** a new service file `Services/AdminService.luau`, the new folder
`src/server/Admin/`, and two read-only accessors: `DataService:IsPersistent(player)` and
`WeatherService:GetEndsAt()`. No gameplay code paths changed. Partner A area: `Anim/Pet.luau` reads an optional
model attribute `AnimSpeed` (time scale, default 1; the Model Lab's speed slider).

## How access works

1. When a player joins, the server looks up `player.UserId` in `Admin/Allowlist`. No entry → nothing happens:
   the player receives no admin code, no remote and no metadata.
2. An allowlisted player gets a ScreenGui `KTE_Admin` in **their own PlayerGui** containing a RemoteFunction
   `Bridge` and a copy of `Admin/Client`. PlayerGui contents replicate only to that player. The Bridge also
   refuses any caller that isn't its owner.
3. Every Bridge call runs `Pipeline.execute(player, commandId, params)`:
   real `Player.UserId` → allowlist role → still connected → request rate (token bucket) → registered command id →
   role permission → environment → parameter schema → scope (+ its own permission) → confirmation → limits and
   target scope (precheck) → cooldown → concurrency cap → handler (pcall) → cross-server broadcast (global scope
   only) → audit entry → safe result `{ ok, code, message, data, delivery, correlation, at }`.
4. Errors return a category and a correlation id that matches the audit entry; stack traces stay in the server log.

Roles are read once at start and frozen; there is no command that grants, edits or escalates a role. A missing or
unknown role means zero privileges. Names, display names, groups, game passes, Premium, friends, account age,
passwords and client flags are never consulted. In Studio only, negative test ids (`-1` = Owner) let a local
multi-client test server exercise the panel; those ids can't exist on a live server.

**Adding an admin:** put their numeric UserId in `src/server/Admin/Allowlist.luau`, review it in a PR, ship.

### Roles and permissions (`Admin/Config.luau`)

| Permission | Tester | Developer | Owner |
|---|:-:|:-:|:-:|
| `panel.open`, `dashboard.view`, `settings.view`, `players.view`, `players.teleport.self`, `lab.use`, `anim.play`, `vfx.play`, `commands.run` | ✅ | ✅ | ✅ |
| `players.teleport.others`, `players.progression`, `lab.manageAll`, `weather.server`, `events.server`, `announce.server`, `flags.server`, `logs.view`, `diagnostics.refresh`, `scenario.reset` | | ✅ | ✅ |
| `weather.global`, `events.global`, `announce.global`, `flags.global`, `players.moderate`, `logs.global` | | | ✅ |

Moderation and moving other players only work on players of a **lower** rank (non-admins are rank 0).

### Environments (`Admin/Environment.luau`)

- `studio`: `RunService:IsStudio()`.
- `staging`: `game.GameId` is listed in `Config.StagingUniverseIds` (a separate experience = separate DataStores).
- `production`: everything else, including private servers (they share the live DataStores).

Progression test edits (money, Kick Power, Run Speed level, rebirths, pen level, test eggs/pets) run only in
`studio`/`staging`, and in Studio only while the target's data is **in-memory** (`DataService:IsPersistent` is
false). A Studio session with API access on may be writing to the live DataStore, so edits are refused there.
There are no DataStore wipes or other destructive data tools.

## Commands

`[Runner]` = listed in the Server Scripts runner under that name. Scopes: S = this server, G = all live servers.

| Command | Permission (global) | Notes |
|---|---|---|
| `session.hello`, `session.players` | `panel.open` | Own role/permissions, client-safe command metadata, registries. |
| `dashboard.get`, `crossserver.status`, `weather.status`, `events.list` | `dashboard.view` | Read-only. |
| `diagnostics.refresh` [RefreshApprovedDiagnosticState] | `diagnostics.refresh` | Re-reads diagnostics, probes MemoryStore, optional error-counter reset. |
| `logs.query` / `logs.global` | `logs.view` / `logs.global` | Filtered, paginated audit; global = MemoryStore copy of global actions. |
| `players.list`, `players.inspect` | `players.view` | Search by name/UserId; read-only data. |
| `players.teleportToPlayer` | `players.teleport.self` | Not during your own egg chase. |
| `players.teleportPlayer` | `players.teleport.others` | Approved spots only (`KickPad`, `TheirPen`); lower rank; not mid-chase. |
| `players.teleportToLab` | `lab.use` | |
| `players.setStat`, `players.giveEgg`, `players.givePet` | `players.progression` | Studio in-memory / staging only; confirmed; bounded. |
| `players.kick` | `players.moderate` | Confirmed, reason 3–120 chars (logged), lower rank only. |
| `lab.catalog`, `lab.list`, `lab.inspect` | `lab.use` | Registry browser; measurements + QA checks from the real model. |
| `lab.spawn` [SpawnRegisteredTestModel], `lab.pair`, `lab.compare` | `lab.use` | Registered sources only; 8 per admin, 24 per server. |
| `lab.transform`, `lab.delete`, `lab.clearMine` | `lab.use` | Own models (any with `lab.manageAll`); scale 0.25–4, move ±30 / lift 0–16 studs. |
| `lab.clearAll` [ClearAdminTestModels] | `lab.manageAll` | Confirmed. |
| `lab.anim` [PlayRegisteredAnimation] | `anim.play` | play/stop/restart/idle/reset, speed 0.1–3, loop; rigged models only. |
| `lab.vfx` | `vfx.play` | enable/disable/oneshot/special/reset; 1–120 s; max 10 models with effects; 0.5 s cooldown. |
| `vfx.demo` [RunRegisteredVFXDemo] | `vfx.play` | A registered one-shot at the lab's demo spot. |
| `lab.hatch`, `lab.pen.add`, `lab.pen.clear`, `lab.pen.check` | `lab.use` | Hatch sequence; isolated test pen (≤ 12 pets). |
| `weather.start` [StartRegisteredWeather], `weather.stop`, `weather.reset` [ResetWeather] | `weather.server` (`weather.global`) | Through `WeatherService`, 10–1800 s; S/G. |
| `events.start`, `events.stop` [StopRegisteredEvent] | `events.server` (`events.global`) | The weather event (the only timed event the game has); Random is resolved once on the sender. |
| `announce.send` | `announce.server` (`announce.global`) | One line at the top of every player's screen: `[headshot] USERNAME: message`. Confirmed; filtered with `TextService`; ≤ 120 chars; kill switch flag. |
| `flags.list` / `flags.set` | `panel.open` / `flags.server` (`flags.global`) | Registered flags only; staging-only experiments refused in production. |
| `scenario.reset` [ResetApprovedTestScenario] | `scenario.reset` | Clears lab + test pen, resets this server's flags, stops weather. Confirmed. |

**Adding a command:** add an entry to a `Commands/*.luau` list: `id`, `name`, `description`, `category`,
`permission`, `kind`, `params` (schema with bounds), optional `scopes`/`globalPermission`/`crossServer`,
`environments`, `cooldown`, `confirm`, `runner`/`runnerName`, `audit`, `target`, `precheck`, `handler`. The
registry is checked at start (unique ids, known permissions, bounded schemas); a broken registry keeps the whole
admin system off while the game runs normally. There is no free-form Lua: no `loadstring`, no client-supplied source,
module paths, asset ids or function names anywhere.

## Model Lab, animations, VFX

- Sources: `pet:<petId>` / `egg:<petId>` (block-data builders from `Config/Pets`), `sack:<1..20>` (Kick Sacks), and
  `asset:<Name>` (Models in `ServerStorage.AdminPreviewAssets`). Copies keep only visual instances (scripts, prompts,
  click detectors, seats, tools, sounds, movers are removed) and every part is CanCollide/CanTouch/CanQuery off.
- The platform has 8 numbered pads, two compare pads with identical spotlights, a demo spot and a fenced test pen.
- Measurements are read from the spawned model: bounding box, parts, MeshParts, SpecialMeshes, unions, decals,
  Motor6Ds, welds, bones, attachments, emitters, lights. QA checks: invisible, broken joints, detached parts
  (would fall/float apart), unrigged, source collisions, stripped instances, floor clipping, huge/tiny, pen overlaps.
- Animation and effect state is set by the server as attributes; each admin's `Client/LabView` plays it with the
  game's own `Anim.play`, `PetFx.attach`, `VFX.attach` and `VFX.play` (one animator per model, stopped on delete).
  Unrigged models show a disabled state. "Signature special" fires a recipe's timed bursts (PetFx emitters with
  `Rate = 0`); the Frost Serpent's frost breath appears there once PR #54 is merged.
- Test pen pets roam with `PlotService.pickSpot` and the same `Path*` attribute protocol as real pens; they have no
  owner, earn nothing and are never saved.
- Non-admins can see lab models (they're server models in `workspace.AdminLab`) but don't play their animations.

## Cross-server (`Admin/CrossServer.luau`)

- Envelope: `{ v, id, at, exp, src, uid, name, cmd, p }`, ≤ 900 bytes, TTL 60 s.
- Receivers reject malformed, oversized, wrong-version, expired, future-dated (> 30 s skew), duplicate (bounded
  seen-cache) and self-sent messages, then run `Pipeline.executeRemote`: their own allowlist, the command must be
  marked `crossServer` and global, the sender's role needs the global permission, params are re-validated, limits
  apply, the same handler runs, an audit entry records the origin server.
- The sender runs the command locally first, then publishes in the background with 3 bounded attempts (4 s timeout
  each). Status is honest: `sending` → `published` / `failed`, or `unavailable` (unpublished place). Receivers send
  acknowledgements; the panel shows how many servers applied or refused it. Missing acks may mean lost messages.
- Global weather and flag changes are also stored in an expiring MemoryStore hash map so servers that start later
  pick them up. DataStores are never used as a broadcast channel.

## Announcements

The game's own `Announce` remote has no client listener in `main`, so nothing it sends is ever shown. Admin
announcements therefore use their own channel: the server writes the filtered text, the sender's UserId and
username as attributes on `ReplicatedStorage.ServerMessage` (`Admin/Messages.luau`), and every player's
`UI/Hud/ServerMessage.luau` shows one plain line at the top centre:

    [HEADSHOT] USERNAME: Hello I love kick the egg!

The headshot is Roblox's rendered avatar thumbnail (`rbxthumb://type=AvatarHeadShot`), 76 px, with the username
in gold and the message in white at 30 px (scaled down on small screens). In: the line drops in with a bouncy pop,
the headshot spins up, the name pops, the message types itself out and the `Announcement` chime plays (a new
`Audio/SoundBank` UI event built from Roblox's own sounds: a soft whoosh and a rising C–G–C chime). While it shows
it bobs gently; out: it lifts, shrinks and fades. Reduced Motion: fades only. The sender is always taken
from the real Player (a client can't set it); receiving servers use the username carried by the checked broadcast.
Attributes only replicate server → client, so there is no new remote for clients to fire. Messages queue and show
one at a time (5–10 s each); someone who joins within 8 s of a message still sees it.

## Audit log

Per server: a 500-entry ring buffer (time, admin, role, command, target, scope, params summary, outcome, error
category, message, server, origin, correlation id). Successful reads aren't logged; failures always are;
unauthorized and spam entries are throttled. Global-scope actions are mirrored to an expiring MemoryStore sorted map
(one day). No DataStore writes. Viewer: Logs tab (filters: outcome, time, text, command, server, admin; 25 per page).

## Opening the panel

Allowlisted players see a small 🛡 button at the top right (under the sound toggle) and can press **F2**
(changeable in Settings to F4, F6, F7, F8, `]`, `` ` `` or Insert for the session). Desktop: a 1180 × 720 window
scaled to fit. Screens under 980 × 600: full screen with an icon-only sidebar (and 80 % scale under 420 px tall).

## Threat model and tests

| Attack | Defence | Tested |
|---|---|---|
| Non-admin fires the admin remote | No remote or code is ever sent to them; pipeline denies unlisted UserIds; Bridge refuses other callers | Lune + Studio |
| Spoofed UserId / role in params | Identity only from the Player object; undeclared params rejected | Lune + Studio |
| String / NaN / fractional UserId on the player object | Rejected as malformed | Lune |
| Unknown, path-like, huge or non-string command ids | Registry lookup with a strict pattern | Lune + Studio |
| Malformed params, NaN/inf, out of range, nested tables, metatables, control chars, too many keys | Schema validation, values rejected (not clamped) | Lune + Studio |
| Client asset ids, module paths, script source | Only server enum lists; no loadstring anywhere | Lune + Studio |
| Privilege escalation (Tester → Developer command, Developer → global scope) | Permission + global permission checks | Lune |
| Live role editing / self-granting | Frozen allowlist and roles; no such command | Lune (frozen object) |
| Spam / floods | Token bucket, cooldowns, global cooldown, concurrency cap, throttled audit | Lune + Studio |
| Calls after disconnect | `player.Parent == Players` check | Lune |
| Duplicate / expired / future / malformed / self / oversized broadcasts | Envelope validation, seen-cache | Lune + Studio |
| Broadcast from non-admin, unknown or non-global command, bad params | `executeRemote` re-checks everything on the receiver | Lune + Studio |
| Unauthorized global scope | `globalPermission` required, confirmation, longer cooldown | Lune + Studio |
| Bad targets (missing player, other admin's lab model, higher-rank player) | Precheck: not_found / forbidden | Studio (missing player, self-kick); the other-admin and rank paths are code-reviewed |
| VFX over-limit (count, duration, quality, one-shot rate) | Server caps + client throttle | Studio (duration bound, wrong-kind one-shot, cooldown); the 10-model cap is code-reviewed |
| Progression edits reaching production data | Environment + in-memory check | Studio (in-memory path) |
| Log access by lower roles | `logs.view` / `logs.global` permissions | Lune (permission model) |
| Unfiltered player-visible text | TextService filtering before broadcast | Studio |

### Results (this session, 2026-10-28)

- `lune run tools/tests/AdminSecurity.spec.luau`: **128 checks passed** (Authorization, Schema, Limiter, Audit,
  Envelope, Pipeline incl. the remote path).
- `tools/tests/AdminStudio.server.lua` in single-player Studio Play (unpublished place, in-memory data):
  **99 / 99 passed** on the final build, incl. announcements (earlier builds: 86/1, 87/0, 92/0; the one failure was the test ignoring a 1 s
  cooldown).
- Existing `tools/tests/ServerTests.server.lua` (plugin context): **364 passed, 4 failed**, the same 4 outdated
  rules listed as the baseline in `DEVELOPMENT_HANDOFF.md`.
- Gameplay smoke in Studio Play: kick → chase → egg caught, sack training (Kick Power 1 → 6), a test egg placed →
  hatched → pet roaming and earning $1/s, pen upgrade 1 → 2, weather start/stop with the HUD timer agreeing.
- UI: every tab built without errors at 1297 × 701; the compact layout was checked at about 600 × 353 by shrinking
  the Studio window. An announcement sent from the Game Controls tab showed as `[headshot] 8yf_y: I LOVE` at the top.

### Not run (needs a published place, more players or devices)

- MessagingService / MemoryStore delivery, acknowledgements, the global audit log and new-server pickup (the
  unpublished place correctly reports "unavailable"; the receiver path was driven directly).
- A real two-client session (Tester role UI, a non-admin client), real phones/tablets, a staging universe, Studio
  with API access on (the refusal path is code-reviewed, not executed), the Frost Serpent special (PR #54).
