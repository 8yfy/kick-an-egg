# VFX specifications

The effects are Roblox PetFx recipes. They live in `KICK_AN_EGG_PET_REMODEL_V3/07_VFX/TopTierV3.luau`, use sprites
from `assets/pet-vfx/vfx_v3_*.png`, and follow the LihFolk vault's VFX notes:
- one dark contrast layer under the bright stack;
- one floor sigil per pet (Legendary and up);
- brightness by screen area;
- specials start with a short hot frame and sync to the flourish through the `PetFxSpecial` attribute.

The mesh pets share the block pets' origin (feet centre at 0, front -Z) and proportions, so the same recipes fit both.
All the effects can be switched off, and the pets still read without them (`KICK_AN_EGG_PET_REMODEL_V3/08_ROBLOX_PREVIEWS/14`).

## Heavenly Lion (Divine, 7 layers)

The brief asks for a subtle celestial aura, gold light accents, occasional radiant sparkles and glowing mane highlights.

| Layer | Kind | Sprite | Where (studs) | Notes |
|---|---|---|---|---|
| dark | disc | v3_shadow | ground, 11 wide | warm dark contrast |
| floor | disc | v3_sun_sigil | ground, 13 wide | turning sun sigil, pulse |
| rays | board | v3_rays | behind the mane (0, 5.6, 0.4) | warm, size 15, pulse |
| motes | emit | v3_sparkle | sphere round the mane (0, 5.5, -1.3) | rising white and gold motes, brightness 4 |
| flash | emit | v3_sparkle | the face (0, 5.3, -4.4) | roar special: hot frame, brightness 25 |
| burst | emit | v3_sparkle | the mane (0, 5.5, -1.5) | roar special: 22 sparks outward |
| light | point | gold | (0, 5.5, -2.6) | range 10 |

The mesh adds its own glow: the Neon star crests, the crown star, the eyes, the halo and the chest star.

## Prism Seraph (Secret, 9 layers)

The brief asks for rainbow refraction particles, rotating crystal ornaments, prismatic sparkle trails and a soft
rainbow glow round the chest.

| Layer | Kind | Sprite | Where | Notes |
|---|---|---|---|---|
| dark | disc | v3_shadow | ground, 8 wide | dusk violet |
| floor | disc | v3_prism_sigil | ground, 12 wide | turning, pulse |
| rays | board | v3_rays | behind the wings (0, 8.4, 2.6) | white, size 18 |
| drift | emit | v3_feather | above the wings, y 10.5 | falling feathers in the six prism colours |
| twinkle | emit | v3_sparkle | sphere round the body, y 7 | prism-colour sparkles, brightness 8 |
| comets | orbit | v3_sparkle | radius 5, y 5.5 | 3 comets with prism trails |
| flash | emit | v3_sparkle | the star heart (0, 7.07, -0.9) | bless special: hot frame |
| burst | emit | v3_sparkle | the star heart | bless special: 24 prism sparks |
| light | point | white | y 7 | range 11 |

The orbiting crystals and the halo are mesh parts on their own bones (Orbit, Halo), animated by the clips.

## Clockwork Titan (Divine, 7 layers)

The brief asks for subtle mechanical steam, a glowing clockwork core, clock-hand and gear movement, and occasional
amber pulses.

| Layer | Kind | Sprite | Where | Notes |
|---|---|---|---|---|
| dark | disc | v3_shadow | ground, 10 wide | iron |
| floor | disc | v3_gear_sigil | ground, 12 wide | turning gear sigil |
| rays | board | v3_rays | behind the body (0, 5.6, 2.4) | amber, size 14 |
| steam | emit | v3_steam | over the shoulders (0, 7.6, 0.7) | soft puffs |
| flash | emit | v3_sparkle | the clock heart (0, 5.17, -1.4) | vent special: hot frame |
| burst | emit | v3_steam | the chest vents (0, 2.8, -1.5) | vent special: 16 steam puffs |
| light | point | amber | (0, 5.17, -1.7) | range 10 |

The clock hands (HeartHands) and the seven chest gears (Gear1-7) are separate bones, so the movement comes from the
clips, not from particles.

## Budgets

- Divine pets use 7 layers and the Secret pet 9, the most in the game.
- Bursts are short and capped at 16-24 particles.
- Glows come from Neon mesh parts rather than lights wherever possible. Each pet has one PointLight.
