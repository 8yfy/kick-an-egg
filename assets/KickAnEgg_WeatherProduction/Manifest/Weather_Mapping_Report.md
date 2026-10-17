# Weather mapping report (audit of `a/full-build` @ 00dac8d, 2026-10-17)

Read-only audit of the real code before any visual work. Base: `a/full-build`, which contains `b/spin-wheel`
(PR #41, "weather tools"). No newer `b/*` branch adds weather.

## 1. Real weather IDs (case-sensitive)

The game's weathers are the keys of `Config/Mutations.Weather` (contract file). They're all **global** events.

| Real ID | Scope | Schedule pick weight | Share of events | Pet mutation (existing, untouched) |
|---|---|---|---|---|
| `Sunny` | global | 0.03 | 31.6 % | income x1.5, vfx `SunRays` |
| `Rainy` | global | 0.03 | 31.6 % | income x1.5, vfx `RainDrops` |
| `Snowy` | global | 0.02 | 21.1 % | income x2, vfx `Frost` |
| `Stormy` | global | 0.01 | 10.5 % | income x3, vfx `Lightning` |
| `Starfall` | global | 0.004 | 4.2 % | income x5, vfx `Stardust` |
| `Rainbow` | global | 0.001 | 1.05 % | income x10, vfx `RainbowShift` |

None of the ten concept names (Golden Rain, Rainbow Storm, Void Eclipse, Frozen Aurora, Meteor Shower, Divine
Ascension, Void Rift, Thunder Surge, Toxic Bloom, Thunderstorm) exist in code. **No local or regional weather
exists.** `Config/Zones[*].weather` is only a zone's default mutation (x2 roll chance at kick time). It isn't a
weather event, it has no region state and it isn't replicated as weather.

Note: the spec says mutations aren't implemented. In this code base weather **mutations do exist** (pet income
multipliers, x5 roll chance during the matching event in `KickService.rollWeather`). This work doesn't touch them.

## 2. Server state, timing and APIs

- `src/server/Services/WeatherService.luau` (Partner B):
  - The schedule loop runs `task.wait(WeatherEvent.everySeconds = 600)`, then `StartEvent(pickWeather(), durationSeconds = 180)`.
    So there's one 3-minute event every 10 minutes, with clear sky in between.
  - `StartEvent(weather, seconds)` sets `active` and `endsAt = workspace:GetServerTimeNow() + seconds`, then
    `FireAllClients(active, endsAt)`. A `task.delay` (guarded by `eventToken`) clears it and fires `(nil, nil)`.
  - `StopEvent()` fires `(nil, nil)`. `GetActive()` is read by KickService.
  - `PlayerAdded`: if an event is active, `FireClient(player, active, endsAt)` (the late-join path).
  - Studio-only `/weather [name|random|off] [seconds]` chat command (TextChatCommand `KTE_weather`).
  - No MessagingService, no cross-server state, no pause or extension API. A second `StartEvent` replaces the
    running event (same or another weather, new `endsAt`).
- Remote: `S->C WeatherChanged(weather: string?, endsAt: number?)` (`Shared/Remotes.luau`). It's the **only**
  authoritative client read point. `endsAt` is in `workspace:GetServerTimeNow()` time.
- Not on the wire: the start time, a revision number, or whether the message is a late-join catch-up. The client
  derives these itself (see section 6). No server change is needed.

## 3. Active and clear semantics

- `weather ~= nil` means an event is active until `endsAt`. `nil` means clear: no event, no calm phase, no default weather.
- The same weather sent again with a new `endsAt` is a restart or extension (only `/weather` does this).
- If `endsAt` passes without the `nil` message, the HUD holds 0:00 for a short grace period, then hides.

## 4. Existing weather UI, look and audio

- `UI/Hud/WeatherHud.luau` + `UI/System/WeatherLook.luau` (Partner B, PR #41): a framed top-right card with a
  header plate, timer and icon tile. **It isn't mounted** (its commit says "awaiting approval"). Its `weather_*`
  icons were never uploaded (`AssetIds` has no weather keys). It's left in place, unused.
- `VFX/Weather.luau`: **pet** mutation overlays only (SunRays, RainDrops, Frost, Lightning, Stardust, RainbowShift).
  Unrelated to the world event. Untouched.
- World visuals for the event: **none**. Lighting never reacts. This is the gap the overhaul fills.
- Audio: there are no weather sounds. `Shared/Audio` provides SoundGroups `Master > UI / Gameplay / Ambience / Music /
  SpecialEffects`, whose volumes come from Settings. The approved premium library lives in `PremiumSfx` sheets and stays untouched.

## 5. Lighting, post effects and settings baseline

- `default.project.json` sets Lighting to Future, Brightness 2.5, OutdoorAmbient (0.55, 0.55, 0.6) and ClockTime 13.5.
  There's no day/night cycle.
- `MapBuilder.applyLighting` (server, at map build) adds `MapAtmosphere`, `MapBloom`, `MapSunRays` and `MapColor`.
- `VFX/Avalanche.luau` adds its own temporary `ColorCorrectionEffect` during a chase, and `UI/Fx` adds `UIBlur`.
- Settings: LocalPlayer attributes `LowDetail`, `ReducedMotion` (`Motion.reduced()`, which defaults to the OS
  setting), `ShakeOff` and `Volume<Category>`, plus `UserGameSettings.SavedQualityLevel`. There's no notification setting.

## 6. What the overhaul adds, and how it avoids conflicts

- One client weather state (`VFX/WeatherFx/State`) merges the server's global event with any local regions and the
  player's position into **the one weather affecting this player**. A local storm wins over the global event.
  Several local storms resolve deterministically by registry `priority`, then by id.
  - Late join: the first `WeatherChanged` within the join window means "joined mid-event" (CURRENT WEATHER), not a start.
  - Duplicate `(weather, endsAt)` messages are ignored. Every real change gets a client revision number.
- Lighting has a single writer (`VFX/WeatherFx/LightingStack`). It captures the live baseline, blends weighted layers
  (global first, then local accent) and only runs while a weight is moving. It uses its own `WeatherGrade`
  ColorCorrection, so it never fights `MapColor` or the avalanche tint. When the weather clears, everything returns to
  the captured baseline.
- Local storm support is ready for data, but nothing feeds it from the server, because no local weather exists. The
  three local concepts are inactive configs. Only the Studio-only dev preview can simulate a region to exercise
  "ENTERED" and the local HUD priority.

## 7. Icon mapping (decided by the user, 2026-10-17)

The icons are the NEW package `Kick_An_Egg_NEW_Weather_Icons_and_Claude_Handoff.zip`, folder
`01_Weather_Icons_Transparent_PNG` (512 px voxel art). It replaces the first clean-icon package, whose uploads are
listed in `superseded_icons_package1.json` and are unused. Its README points to a `05_Claude_Weather_Overhaul_Prompt.md`
that isn't in the zip, so the original spec file is still the brief.

The extracted PNGs carry a grey fringe from the dark source sheet. At the user's request they got an **alpha-only
defringe**: `tools/weather/defringe.py` lowers only the alpha of dark semi-transparent edge pixels and leaves RGB
untouched. The as-delivered files are in `UI_Icons/originals_as_delivered/`. Seven icons are cut flat at the bottom
edge in the source extraction. That's left as is, because the art isn't redrawn.

| Real ID | Icon | Uploaded image id |
|---|---|---|
| `Stormy` | `Thunderstorm.png` | see `uploaded_icons.json` |
| `Rainbow` | `Rainbow_Storm.png` | see `uploaded_icons.json` |
| `Snowy` | `Frozen_Aurora.png` | see `uploaded_icons.json` |
| `Starfall` | `Meteor_Shower.png` | see `uploaded_icons.json` |
| `Sunny` | **placeholder** (no sun icon supplied) | none |
| `Rainy` | **placeholder** (no rain icon supplied) | none |

The placeholder is a visible MISSING ICON marker plus a logged warning, never a borrowed picture. The registry's
`icon` field per weather is a one-line change once art exists.

The six concept icons not mapped to real weathers (Golden Rain, Void Eclipse, Divine Ascension, Void Rift, Thunder
Surge, Toxic Bloom) are uploaded and kept on their inactive registry entries (`active = false`, preview only).

## 8. Reusable assets

- `VFX/WorldSprites` has 20 uploaded original sprites (softdot, sparkle, star, glint, snowflake, streak, mist, puff,
  ring, spore, ember, curtain…), reused where they fit.
- `VFX/Pool`, the `VFX/Ambient` quality and culling patterns, `Audio.group` SoundGroups, `Motion.reduced()` and `Kit.autoScale`.
- `tools/world/upload.py` (Open Cloud image upload; the key comes from the environment and is never printed).

## 9. Decisions made after the audit (2026-10-17)

- **Icons:** the user's new package (section 7).
- **Sound:** only the rainy weathers (Rainy, Stormy) make sound. The sounds are licensed Pro Sound Effects rain and
  distant thunder from the Creator Store, not generated. See `Custom_SFX/README.md`.
- **Results:** see `QA_Report.md`.
