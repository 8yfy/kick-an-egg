# Weather overhaul: QA report (2026-10-17)

## Setup

- **Branch:** `a/weather-overhaul`, taken from `a/full-build` @ 00dac8d.
- **Test place:** `build/KTE-weather-test.rbxl`, built with `rojo build` from this branch. The code was deployed with
  `tools/world/deploy.sh`. Your own Studio places were never opened or modified.
- **Where:** Studio Play, single client, desktop viewport 1297×682.
- **How the tests were driven:** through the Studio-only dev bridge (`UI/Dev/WeatherPreview`).
  - "Real event" means the server's own `/weather` command, so the full path runs: WeatherService → `WeatherChanged`
    → client.
  - "Preview" means a client-only stand-in.
- **Evidence:** screenshots in `Studio_Test_Videos_Or_Screenshots/`. I captured still sequences, not video.

## Scope recap

- **Real weathers** (exact ids from `Config/Mutations.Weather`): Sunny, Rainy, Snowy, Stormy, Starfall, Rainbow. All
  six have full looks.
- **Concepts not in the code:** Golden Rain, Void Eclipse, Divine Ascension, Void Rift, Thunder Surge, Toxic Bloom.
  They're kept as inactive registry configs, preview only.
- **Untouched:**
  - Server code: `src/server` has no changes.
  - `Config/*` and `Remotes`.
  - The map.
  - Mutations, odds, schedule and rewards.
  - The approved HUD icons and premium SFX.
- **Changed existing files** (2, +14 lines):
  - `UI/init.luau`: mounts the widget, the toast and the dev panel.
  - `UI/System/Modal.luau`: a `toastLane()` accessor.

## Results: the spec's 14 tests

| # | Test | Result | What was observed |
|---|---|---|---|
| 1 | Fade-in over several seconds | **PASS** | Real Stormy event. The visuals start 0.13 s after the command. Lighting.Brightness goes 2.50 → 2.18 at 1.6 s → 1.35 at about 5 s, a smooth eased ramp sampled every 0.5 s with no jumps. Particles fade in through Rate, props and beams through transparency. Shots 01–03. |
| 2 | Start banner exactly once | **PASS** | Snowy started, then got re-sent twice as extensions (`/weather Snowy 50` ×2). Exactly 1 toast: "SNOWY HAS STARTED!". Duplicate or extend messages never re-announce. |
| 3 | One bottom-right icon, matches the weather, timer above it and counting | **PASS** | After rapid switches, exactly 1 visible icon ImageLabel. The icon matches the registry (Stormy shows Thunderstorm.png). The timer counts down (59 → 48 → 43 …) as MM:SS from the server `endsAt`. Shots 02–03, 14–18. |
| 4 | Wrong or missing asset id shows visibly in dev | **PASS** | No icon (Sunny, Rainy) and an unknown id ("HeatWave") show the MISSING ICON marker and log a warning. An invalid id (`rbxassetid://1`, injected into the test place only) fails to load and switches to the marker, with `Icon = FAILED` and a warning. A wrong picture is never shown. |
| 5 | Graceful end back to the baseline | **PASS** | Real `/weather off`. Before and after, Lighting is identical: Brightness 2.5, Exposure 0, OutdoorAmbient, Atmosphere Density 0.3 / Haze 1.4 / Color, ClockTime 13.5. `WeatherGrade` is removed, no `Clouds` are left behind, the `workspace.WeatherFx` folder is empty, and the rain bed fades 0.40 → 0.21 → removed. Shots 04–05. |
| 6 | A → B → C quickly, nothing stuck | **PASS** | Sunny → Starfall → Rainbow, 0.6 s apart. The weights cross-fade, the stale layers fade to 0 and are destroyed. 24 s after the end: 0 weather instances and baseline lighting. |
| 7 | Join mid-event | **PASS (simulated)** | `State.simulateJoin()` replays the running event as a fresh join. The reason is `join`, the toast says "CURRENT WEATHER: SNOWY" (not "has started"), and the widget's 40 s equals `endsAt − GetServerTimeNow()`. A real second player joining was not tested (see test 9). |
| 8 | Local storm only in range; HUD only for the player inside | **PASS (preview)** | The game has **no** local weather, so a client-only preview storm was used. Outside: the rift portal shows in the world and the HUD stays on the global SUNNY. Walking in: "ENTERED VOID RIFT", the HUD shows VOID RIFT (scope local), the global look dims to 40 % and the local grade blends on. Walking out: the HUD goes back to SUNNY with no extra toast. A storm starting on the player gives "THUNDER SURGE HAS STARTED!". Shots 06–08. |
| 9 | Two-client test (local plus global) | **NOT RUN** | Studio MCP only starts single-client Play. Also, no real local storm exists on the server. By design, local storms are per-client state (`WeatherFx.State`), and nothing local is ever broadcast. |
| 10 | Camera, zone HUD and upper-right icons unobstructed | **PASS** | The widget sits bottom right, clear of KICK / AUTO KICK / hotbar / rail / zone bar. The toast uses the game's toast lane under the quest bar. Everything is `Interactable = false`. Shots 11–13. |
| 11 | Mobile bottom right, legible, safe areas | **PASS after a fix** | Studio's phone preview (`HudPreview = "phone"`, 844×390). The first run **FAILED**: the widget overlapped the sound and settings buttons. Fixed: on phones it now sits left of the jump button and right of the hotbar (x 659–740, y 284–380), 25 % larger, with no name, and the timer text is 23 px. Shot 10. Not tried on a real device. The tablet placement is computed but untested. |
| 12 | Low Detail, Reduced Motion and volume | **PASS / PARTIAL** | LowDetail ON: 934 → 327 particles/s (quality 0.35); OFF restores. Reduced Motion: the lightning exposure lift goes 0.16 EV → 0, bolts become one soft fade, and the HUD and toast use fades only. Volume: every weather sound plays through the game's `Ambience` SoundGroup (verified), so the Settings volume and the Sound toggle apply. I can't hear Studio audio, so levels were set by PlaybackLoudness, not by ear. |
| 13 | Frame time, memory, particles in dense zones | **PASS** | Volcano (zone 9), Galaxy Void (19) and Rainbow Heaven (20), with Stormy and with Rainbow: 16.7 ms average (60 fps cap), worst 18.5 ms. Weather adds ≤ 9 emitters and ≤ 953 particles/s, alongside 25–37 map emitters. Memory moved by about 1 MB for a weather at the hub. One sample read 0 particles/s; it did not reproduce in 2 reruns. Not profiled on mobile hardware. |
| 14 | No unrelated gameplay changes | **PASS** | `ServerTests`: 362 pass / 3 fail. **The same 3 fail on the untouched base**: the shop-sack light count, the map overhaul (`SafeZone.Decor`) and one pen check whose name varies between runs. `UiSmoke`: 31 / 2, identical on the base. A real kick during Stormy: kick accepted → flight → RUN! → steer-home camera → chase ended → camera back → KICK back. Not tested: steering an egg home to secure it (needs live input), and the pen and shop UIs beyond the unit tests. |

## Other checks

- **Assets:** the 17 custom textures and 10 icons are Decal uploads. Their **image** ids were resolved and each one
  verified to load (`ContentProvider` Success). The 3 rain/thunder sounds load with their real lengths.
- **Leaks:** after every end, `workspace.WeatherFx` was empty. No stray thunder attachments, no Sounds left, and the
  RenderStep loop unbinds when idle.
- **Console:** no WeatherFx errors in any run. The only weather warnings are the intended MISSING ICON ones for Sunny
  and Rainy, which don't have icons yet. The `rbxassetid://203785492 … Asset type does not match` error predates this
  branch.
- **Static check:** StyLua is clean. `luau-lsp analyze` (no Roblox definitions available offline) shows no real errors
  in the new files after the fixes. What remains is unknown-Roblox-global noise.

## Known gaps and open items

1. **Icons for Sunny and Rainy:** not supplied, so they show the marker (your decision). Adding one is a one-line
   `icon =` change in `Registry.luau`.
2. **Sound:** only Rainy and Stormy have sound, from licensed Pro Sound Effects (your decision). Nothing was generated
   into the game. Listen in game and tell me if a volume should move.
3. **No Blender props:** no Blender MCP was connected, and the art style rules out shipped meshes. All centrepieces are
   brick recipes (`WeatherFx/Sky.luau`).
4. **Local storms:** not in the game. Void Rift, Thunder Surge and Toxic Bloom are ready configs plus a client path
   (`State.setLocal`). A server-side local weather would be Partner B's change, through a `contract:` PR for its remote.
5. **Not run:** the two-client test (9), a real-device mobile check (11), and steering an egg home under weather (14).
6. `Controllers/WeatherVisualController.luau` sits in the Controllers folder. It's a 3-line starter, the same as the
   remodel's `WorldLifeController`, and touches no gameplay.
7. Partner B's earlier, unmounted `UI/Hud/WeatherHud` + `WeatherLook` stay in place and unmounted. They aren't deleted.
