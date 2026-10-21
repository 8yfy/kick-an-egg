# KickAnEgg_WeatherProduction

These are the assets and records for the weather visual overhaul (branch `a/weather-overhaul`). The code is in
`src/shared/VFX/WeatherFx` and `src/client/UI/Hud/Weather*` (see `Roblox_Scripts/README.md`).

| Folder or file | Contents |
|---|---|
| `QA_Report.md` | The spec's 14 Studio tests with real results, plus what wasn't testable. |
| `Manifest/Weather_Mapping_Report.md` | The audit: real weather ids, scheduler, replication, baseline, icon mapping. |
| `Manifest/weather_registry.json` | A snapshot of every weather look: id, active, icon, sounds, plus all texture ids. |
| `Manifest/uploaded_icons.json`, `uploaded_textures.json` | Upload records: Decal id and the resolved, verified **Image** id. |
| `Manifest/superseded_icons_package1.json` | Uploads of the first icon package. Replaced by your new package and unused. |
| `UI_Icons/` | The 10 icons from your NEW package after an alpha-only defringe (`tools/weather/defringe.py`). The as-delivered files are in `originals_as_delivered/`. |
| `Custom_VFX_Textures/`, `Custom_VFX_Flipbooks/` | 16 original particle / beam textures and the 2×2 splash flipbook (`tools/weather/sprites.py`). |
| `Custom_SFX/README.md` | The sound decision and the licensed rain / thunder assets used. |
| `Blender_Source/`, `Exported_Models/` | Empty on purpose (READMEs explain why: no Blender MCP was connected, and the art style is brick recipes). |
| `Studio_Test_Videos_Or_Screenshots/` | 18 Studio captures: clear → Stormy → clear, local storm entry, phone layout, the chase during weather, and every real weather's look. |

## How to preview in Studio

Play opens a **WEATHER DEV** button at the top left (Studio only). It has three groups:

- **SERVER** starts real events through the game's own `/weather` command.
- **PREVIEW** shows any look on this client only, including the inactive concepts and local storms.
- **TESTS** has the rapid A → B → C switch, late join, and stepping into / out of a local storm.
