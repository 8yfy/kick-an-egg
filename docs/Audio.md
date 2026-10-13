# Sound design: thunder removed, every action gets a fitting sound

All recipes live in `src/shared/Audio/SoundBank.luau` (data). `src/shared/Audio/init.luau` plays them, and `VFX.play` forwards every effect to `Audio.vfx`, so a sound stays in sync with its visual.

## 1. Audit: what was wrong

Roblox ships exactly **11 sounds** with every client (`rbxasset://sounds`). I decoded and measured each one with `tools/audio`; nothing was judged by its file name.

| Source | Measured | Use now |
|---|---|---|
| `impact_explosion_03` | 2.3 s, **68% sub-bass**, peak **0 dBFS**, 1 s tail: a thunder boom | storms / electricity only |
| `action_jump_land` | 0.17 s soft low-mid thud, 45 ms attack, peak −20 dBFS | every physical contact (`thump`) |
| `action_footsteps_plastic` | 8 crisp taps, 0.11 s each | sliced into `tap1`–`tap4` (clicks, knocks, cracks) |
| `volume_slider` | a clean tonal blip, fundamental ≈ 393 Hz | tuned chimes, coins, sparkles (`tone`) |
| `action_jump` | 0.18 s tonal swish | pops, boings (`hop`) |
| `action_get_up` | 0.46 s, 95% sub-bass | ground rumble (`rumble`) |
| `action_falling` | steady wind bed | whooshes (a faded slice), the avalanche roar (loop) |
| `impact_water`, `action_swim` | splash, water strokes | mud, goo, sweat, rain |

**Why everything sounded like thunder:**
- **It was layered into ordinary sounds:**
  - the kick, at every timing;
  - every Kick Sack punch from tier 4 up;
  - every sack drop from tier 7 up;
  - every super hit and every sack upgrade;
  - 10 sack themes (sparks, glint, crystal, embers, lightning, robo, fire, cosmic, holy, rainbow).
- **It drowned everything else:** the explosion peaks about 20 dB above the soft thud, and the old code played every file at its raw level.
- **The pitch trick didn't hide it:** shifted 3–5× up it was still a boom with a tail.
- **Separately, the basic Burlap punch played the entire 2.5-second footsteps file on every hit.**
- **Many actions had no sound at all:** landing, bouncing, running, hatching, placing, pickup, money, UI and the avalanche.

## 2. Assignments changed

| Action | Before | After (tier) |
|---|---|---|
| Kick | explosion + jump + land, the same for every kick | by the server's timing band (`KickBand`):<br>• weak: light whoosh + thump (T1)<br>• normal: whoosh + controlled thump + smack (T2)<br>• Perfect: whoosh + punchy impact + C-E-G-C flourish (T3) |
| Kick Sack punch | thud + explosion (tier 4+) + theme stack | the sack's **material body** + a quiet accent where the look calls for magic (T1, T2 with an accent). Bodies:<br>• canvas: dry fabric thud<br>• leather: thud + slap<br>• rubber: thud + boing<br>• metal: clank<br>• ice / crystal: crisp tap<br>• candy: soft squish<br>• rock: hard tap |
| Premium sack punch (Galaxy Void, Sun Guardian, Rainbow God) | explosion at 0.4–0.8 pitch (a 2.8 s thunder) | physical hit + short sparkle / cosmic resonance / warm shimmer (T2) |
| Sack super hit | explosion + theme | heavier body + weight + the theme's flourish (T2–T3). **Thunder Cell only** adds a short crack, because it is electric |
| Sack drop onto its chain | thud + whoosh + explosion (tier 7+) | bag thud + chain clinks, plus a clank for metal sacks (T1) |
| Sack bought | explosion + ticks | soft thump + C-E-G-C chime (T3) |
| Premium sack idle loop | wind / bubble loops | the same, quieter, in the Ambience group |
| Egg landing (flight touchdown) | — | the zone's **surface**, scaled by the arc's real impact speed; hard landings get a weight layer, never a boom. A weather-mutated egg adds a quiet accent. Surfaces:<br>• grass: hollow thump<br>• sand: muted<br>• stone: short tap<br>• snow: soft crunch<br>• ice / crystal / metal / mud / candy / cloud / dirt: their own |
| Egg bounce / drop while steering | — | contact detection from the egg's vertical velocity, with a minimum speed of 6 studs/s and a 0.12 s cooldown (never `Touched`). If it rebounds it's a short pop (T1); otherwise it's the landing |
| Egg running | — | very quiet light steps whose pace follows its speed (T1) |
| Legs sprout / zone crossed / slot spin stops | — | pop-pop (T1) / soft whoosh + a tone rising with each zone (T1) / clack-ding (T2) |
| Egg secured / caught | — | bright success chime (T3) / crunchy crack, no boom (T2) |
| Avalanche | — | warning rumble (T3), then a ground break (rocky) or a whump + slide (snow / sand / coral / candy) (T3), a looping roar that follows the front (Ambience), and a crumble at the safe line (T2) |
| Hatching | — | small shell cracks while it wobbles (T1), then by rarity:<br>• Common / Uncommon: crack + pop (T2)<br>• Rare / Epic: + C-E-G chime (T3)<br>• Legendary / Mythic / Divine: + 4 notes and a shimmer (T3)<br>• Secret: crack, rumble swell, pop, a 6-note flourish and a sparkle tail (T4) |
| Egg held / placed, pet placed / picked up | — | soft pick-up / gentle knock (T2) / knock + tiny tone (T2) / friendly bloop-ding (T1) |
| Money earned | — | a subtle 2-note coin chime at your pen, at most every 2.5 s (T1) |
| UI | — | a light click on every button (one hook on PlayerGui), plus:<br>• success: E-G-C (T2), muted right after a bigger fanfare<br>• error: two soft low blips (T1)<br>• Index milestone: T3<br>• all 79 pets / rebirth: T4 |

**Thunder now appears in only two places:**
- a Stormy-mutated egg's landing gets a quiet, distant crack;
- Thunder Cell's super hit gets a short crack.

## 3. Rules the system enforces

- **Groups:** `SoundService.Master` (the HUD sound button) contains `UI` (2D), `Gameplay`, `Ambience`, `Music` and `SpecialEffects`. Settings has a volume row for each (100 / 75 / 50 / 25 / OFF). Magic layers on top of physical hits play in SpecialEffects, so you can turn them down on their own.
- **Tiers:** each tier caps layer count, loudest layer, summed volume and length. Tier 1 is short and subtle (≤ 0.6 s); tier 4 is reserved for Secret hatches, rebirth and the all-79 reward. A composed stack (a landing, a sack hit) is only as big as what it actually layers (`SoundBank.tierFor`).
- **Spam control:**
  - a cooldown per event and per key (egg, sack);
  - a voice cap per event, plus a total cap (28 voices, 16 on phones; tier 3+ may exceed it);
  - sounds out of earshot are skipped;
  - a toast chime is muted right after a fanfare.
- **Variation:** often-repeated sounds (clicks, steps, cracks, coins) have 2–4 variants, never the same one twice in a row, plus a little random pitch.
- **Levelling:** every source is levelled to the same peak, so a recipe's `volume` means the same for all sources.
- **3D vs 2D:** world sounds are 3D, with inverse-tapered roll-off and per-event distances. UI is 2D.
- **Cleanup:** every Sound is destroyed when it ends (with a fallback timer), and anchors go back to the shared pool.

## 4. Verification

I can't listen to audio, so each sound was verified three other ways.

1. **Unit tests** (`sh tools/run-tests.sh`, section "Audio"): **289 / 289 passed**. They check:
   - only built-in sources;
   - no thunder in any event, landing (every surface, speed, bounce, mutation except Stormy) or sack punch, drop or upgrade;
   - only Thunder Cell's super hit cracks;
   - every recipe fits its tier, and tiers 1 < 2 < 3 < 4 in length and loudness;
   - variations exist;
   - landings get louder with speed, bounces are shorter, and surfaces follow the zone;
   - the contact detector: one landing per fall, no stacking from contact chatter, no sounds on slopes, bounce vs landing;
   - the kick band;
   - all 10 scenarios.
2. **Live Studio playtest** (`sh tools/playtest/playtest.sh`, real engine): **108 passed, 0 failed**.
   - How loudness is measured: Roblox's `PlaybackLoudness` ignores `Volume`, SoundGroups and distance (I checked: a sound read 56 whether its Volume was 0.25 or 2). So each layer's `PlaybackLoudness` is weighted by its Volume and summed per frame. The table shows the loudest frame and how long the sound was audible.

   | Scenario | Played | Loudness / audible |
   |---|---|---|
   | 1 gentle drop on grass (real physics) | one `EggLand_grass`, T1 | 66 / 0.24 s |
   | 2 drop on stone (real physics) | stone tap + thump, T1 | 29 / 0.14 s |
   | 3 bouncing egg (real physics) | 7 pops, never stacked, each softer | 61 → 30 |
   | 4 steered egg | 28 light steps | — |
   | 5 normal kick | `KickGood` | 183 / 0.34 s |
   | 6 Perfect Kick | `KickPerfect` (whoosh, impact, flourish) | 186 / 0.34 s (weak kick: 89) |
   | 7 basic sack punch | thump + tap, no magic | 85 / 0.27 s |
   | 8 Rainbow God punch | thump + tap + 3 chimes | 99 / 0.26 s |
   | 9 Common hatch | `HatchCommon` T2 | 70 / 0.24 s |
   | 10 Secret hatch | `HatchSecret` T4 | 181 / **1.18 s** |

   The same run also confirmed:
   - no thunder in the whole session;
   - every sound loaded its asset;
   - mean loudness by tier: **T1 18 < T2 65 < T3 107 < T4 181**;
   - the rest of the loop plays (zone, legs, avalanche, secured, hold / place, pickup, money, UI).
3. **Offline renders** (`sh tools/audio/render.sh`): every recipe (170) is mixed from Roblox's own files into WAVs under `tools/audio/previews/`. The renders are not committed.
   - **To listen:**
     - `scenarios_1_to_10.wav`: the 10 scenarios back to back;
     - `before_after/`: the old vs new kick and sack punches;
     - `sacks/`, `landings/`, `events/`: everything else.
   - **Before → after, measured:**
     - kick: 1.73 s, 61% sub-bass → **0.32 s, 29%**;
     - Rainbow God punch: 2.84 s, −8.8 dB, 72% sub-bass → **0.26 s, −20.7 dB, 27%**;
     - Burlap punch: 3.14 s → **0.27 s**.

## 5. What would sound better still (for your review; I invented no IDs)

The built-in set has no real coin, shell or leather recording. The recipes approximate these with levelled, tuned and sliced built-ins. If you find licensed Creator Store sounds (or record your own), put each ID in `SoundBank.CUSTOM["<event>"] = { id = "rbxassetid://…", volume = 0.5 }` and it replaces that event. Listen before you pick.

| Event key | Wanted | Length |
|---|---|---|
| `MoneyChime` | small coin clink (one coin, bright) | ≤ 0.3 s |
| `HatchCommon` | eggshell crack + soft pop | ≤ 0.4 s |
| `Sack1.impact` … `Sack4.impact` | dry punch on a canvas / leather heavy bag | ≤ 0.3 s |
| `Sack6.impact` (and the other metal sacks) | glove on a metal plate, short | ≤ 0.3 s |
| `KickGood` | foot on a ball/egg: a firm, short "thwack" | ≤ 0.35 s |
| `UIClick` | soft UI tick | ≤ 0.08 s |
| `AvalancheRoll` | low rolling rumble loop (rocks / snow) | loop |
| `EggSecured`, `HatchRare` | short magical success sparkle | ≤ 0.8 s |

The game needs no animation, music or sound IDs to work as it is. All of the above are optional upgrades.
