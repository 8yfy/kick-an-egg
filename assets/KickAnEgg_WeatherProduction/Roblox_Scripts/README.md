# Weather scripts (they live in the game source, not here)

| File | Role |
|---|---|
| `src/client/Controllers/WeatherVisualController.luau` | Starts WeatherFx on the client. |
| `src/shared/VFX/WeatherFx/init.luau` | The visual controller: layers, the crossfade mixer and the RenderStep loop (only while something is live). Also quality and Reduced Motion. |
| `src/shared/VFX/WeatherFx/State.luau` | The one weather affecting this player: global from `WeatherChanged`, local storms by position. Handles revisions, join / start / enter / leave / end / extend, and duplicates. |
| `src/shared/VFX/WeatherFx/Layer.luau` | One live look: its elements, bed and weight (eased, reversible fades, linger then destroy). |
| `src/shared/VFX/WeatherFx/Elements.luau` | Building blocks: `volume` (camera / ground / region emitters), `shafts` (Beams), `bolts` (lightning), `comets` (Trails), `sky` (props). |
| `src/shared/VFX/WeatherFx/Sky.luau` | Brick centrepieces (see Blender_Source/README.md). |
| `src/shared/VFX/WeatherFx/LightingStack.luau` | The ONLY writer of weather lighting. It captures the baseline, blends weighted layers and restores. |
| `src/shared/VFX/WeatherFx/Registry.luau` | Looks per exact server id: 6 real weathers plus 6 inactive concepts. |
| `src/shared/VFX/WeatherFx/Sprites.luau` | Uploaded custom particle and beam textures. |
| `src/shared/VFX/WeatherFx/Sound.luau` | Rain beds and thunder (Pro Sound Effects). |
| `src/client/UI/Hud/WeatherWidget.luau` | The ONE bottom-right widget: name, MM:SS above the unframed icon. |
| `src/client/UI/Hud/WeatherToast.luau` | Start / CURRENT WEATHER / ENTERED notice, once per revision, in the game's toast lane. |
| `src/client/UI/Dev/WeatherPreview.luau` | Studio-only dev panel and test bridge. |
| `src/client/UI/init.luau`, `src/client/UI/System/Modal.luau` | Mounts the widget, toast and dev panel. `Modal.toastLane()` accessor. |

Generators:

- `tools/weather/sprites.py`: the particle textures.
- `tools/weather/defringe.py`: the icon alpha cleanup.
- `tools/weather/sheet.py`: review sheets.

Uploads go through `tools/world/upload.py`.
