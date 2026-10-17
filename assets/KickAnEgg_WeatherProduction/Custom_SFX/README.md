# Weather sounds

## Decision (2026-10-17)

You listened to the generated set and decided:

- Only the **rainy weathers** make sound: Rainy and Stormy.
- No start cues, no beds and no accents for the other weathers.
- No generated rain or thunder. Instead, use good existing recordings from search.

## What the game uses

`src/shared/VFX/WeatherFx/Sound.luau` holds the sounds. Every one comes from the Creator Store: Roblox's licensed
**Pro Sound Effects** library (creator `ProSoundEffects`, free to use in experiences).

Each was verified in Studio to load (ContentProvider Success, IsLoaded, real length).

| Key | Asset | Recording | Use |
|---|---|---|---|
| `Rain_Light` | `rbxassetid://9112793875` | Heavy Rain 3: steady, outdoor, no thunder, 67 s loop | Rainy bed, volume 0.6 |
| `Rain_Storm` | `rbxassetid://9112853422` | Rain Heavy Rainfall Grass Wooden Roof 1: heavy, low rolling thunder, 46 s loop | Stormy bed, volume 0.4 |
| `Thunder_Far` | `9120018172`, `9120018216`, `9120018050` | Thunder Distant Boom Thud 20 / 21 / 15: far booms, no sharp crack | Stormy strikes, 3D |

## How they play

- Beds crossfade with the visuals: the volume is the bed volume × the layer weight. Each starts at a random point in
  its loop.
- They play through the game's `Ambience` SoundGroup, so the Settings volume and the Sound toggle apply.
- Thunder plays at the strike position. It arrives 0.25 s + distance/420 s after the flash.

## Volume levels

Levels were set with `PlaybackLoudness` against the game's avalanche loop. That loop measures about 57 at volume 0.5.
The rain beds sit below gameplay sounds.

## Generated candidates (declined, kept outside the repo)

These sounds are in `C:\Users\kerem\Kick an Egg SFX\` and stay out of the game:

- `sounds/weather_v1`: 20 procedural sounds from `weather.py`.
- `sounds/weather_stormy_rain_sa` and `sounds/weather_thunder_far_sa`: 3 + 3 Stable Audio 3 Small-SFX renders.

You can still listen to them in the gallery (`sfx.cmd --gallery --open`).
