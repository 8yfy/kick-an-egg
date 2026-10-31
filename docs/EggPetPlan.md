# Kick the Egg: art plan for all 79 eggs and pets

Source: the "79 Eggs / 79 Pets" art package (concept boards, design CSV/JSON, zone art direction, 45 VFX sprites).
The package's 79 pairs match `Config/Pets` exactly (names, zones, rarities), so no contract change is needed.

**Status (2026-10-12):** the 7 hero pairs are built, rendered in Studio and waiting for approval. The other 72
follow the same language after that, as the brief requires.

| Hero | Rarity | Egg parts | Pet parts | Egg FX layers | Pet FX layers |
|---|---|---|---|---|---|
| 01 Sprout Pup | Common | 30 | 36 | 3 | 4 |
| 03 Meadow Stag | Rare | 32 | 69 | 4 | 5 |
| 07 Tide Spirit | Epic | 55 | 84 | 5 | 6 |
| 23 Frost Serpent | Legendary | 56 | 169 | 5 | 9 |
| 43 Quetzal Phoenix | Mythic | 81 | 174 | 5 | 7 |
| 63 Clockwork Titan | Divine | 119 | 212 | 5 | 7 |
| 79 Prism Seraph | Secret | 135 | 227 | 6 | 9 |

Renders (Roblox Studio): `docs/art/heroes/`: one close-up per pair, both lineups, and the old models for
comparison (`before_*`). Re-render with `sh tools/preview/preview.sh Heroes desktop out.png 1` (eggs), `... 2`
(pets), `... 11`..`17` (one pair close up). Server tests check the progression (each hero pet more detailed than the rarity below), that every
egg shell fits the chase, every recipe is valid and unique, and effects attach and clean up.

## How it is built (Roblox-friendly notes)

- **Models are block data** (CLAUDE.md rule 3): one file per pair, `Builders/Models/Premium/<Key>.luau`, returning
  `{ egg = Spec, pet = Spec }` for BlockBuilder. The zone files point their entry at it, one line each.
  `Builders/Models/Sculpt.luau` holds the helpers:
  - `eggShell`: the classic blocky egg: stepped square layers with studs (about one layer per 0.55 studs of
    height, 7 for a 3.7-stud egg);
  - `eggBand`, `eggRing`, `plate` and `onEgg`: put bands, trims and plates flush on the square faces;
  - `shard`: crystals;
  - `fan`: wings, feathers, crests;
  - `ring` and `gear`: halos, collars, gear rings;
  - `both`/`mirror`: left/right symmetry.
- **Eggs:**
  - Keep the core egg readable.
  - The shell parts are named `Shell<n>` in the `Body` joint (legs sprout under it).
  - The chase hitbox and the sprouted legs follow the shell (`Sculpt.shellBounds`), so floating decorations
    never widen the collider.
  - Keep the shell at or under 4.2 wide and 6 tall. Decorations may float beyond that.
- **Rig:**
  - Pets use the standard joint groups: Body, Head, ArmL/R, LegL/R, WingL/R and Tail.
  - Floating rings use `Orbit`, `Orbit2` or `Halo` (spun by Anim/Spin), each starting with an invisible hub part.
  - Floaters, such as Tide Spirit, simply have no part at y = 0, so they hover over the pedestal.
- **Effects are data too:** `VFX/PetFx/Recipes/<Zone>.luau`, one `egg` and one `pet` recipe per pair.
  - Layer kinds:
    - `emit`: ParticleEmitter;
    - `orbit`: sprites or parts circling the model, optional trails;
    - `disc`: flat unlit sprite such as a halo, sigil or ground ring;
    - `board`: camera-facing glow or rays behind the model;
    - `light`;
    - `beam`.
  - Clients attach them to plot eggs and pets (`PlotController`, keyed by the `ModelKey` attribute).
  - Effects sleep beyond 160 studs; `Quality` scales emitter rates.
- **Lights:** models carry no PointLights of their own (they splash on the pedestal floor); lights live in
  the recipe, at most two per pet.
- **Sprites:**
  - The 45 package PNGs are in `assets/pet-vfx/`; their ids go in `VFX/PetFx/Sprites.luau` (`UPLOADED`).
  - They are mostly empty canvas: soft glows peak at 74% opacity, and halo/ray sprites at 47–56%. So glows and
    halos are drawn 2–3x their visual size, with brightness 2–3.
  - Recolouring a coloured sprite multiplies its colours: a teal tint on the beige ray sprite turns green, so
    tint the white sprites instead.
- **Rarity ladder** (measured on the heroes; use it as the budget for the other 72):

| Rarity | Pet parts | Egg parts | Pet FX layers | Must have |
|---|---|---|---|---|
| Common | 25–40 | 20–30 | 3–4 | cute readable shape, one soft particle family, soft glow |
| Uncommon | 35–55 | 25–35 | 3–4 | one extra accessory or silhouette hint |
| Rare | 55–75 | 30–45 | 4–5 | iconic accessory, coloured eyes, a clear signature effect, rarity band on the egg |
| Epic | 75–110 | 45–60 | 5–6 | transformed silhouette, floating parts (Orbit), layered particles |
| Legendary | 120–160 | 55–70 | 6–7 | hero silhouette (wings/horns/spikes), one major ring, an accent light |
| Mythic | 160–190 | 70–90 | 7 | several effect families, Halo + Orbit groups, rays or trails, two lights |
| Divine | 320–450 | 100–135 | 7 | ceremonial framing: sigil disc, rays, crown/halo, gear or sun framing |
| Secret | 340+ | 90+ | 8–9 | the showcase stack: rainbow trails, prism rings, rays, holy glow, three orbit layers |

Divine and Secret were raised on 2026-10-31, when the top tier was rebuilt to the user's reference images and approved:
- Clockwork Titan 332 / 131;
- Heaven Lion 444 / 103;
- Prism Seraph 445 / 96.

The hero ladder test still needs the hero part counts to rise strictly in hero order.

- **Effects and motion by rarity** (decided 2026-10-29 for the Frost Serpent–style remodel; applies to every pair):
  - Effects grow with rarity, and motion calms down and gets prouder.
  - **A ground glyph (sigil) is a Legendary+ privilege.** Lower rarities get at most a soft aura, and a Rare egg
    gets a thin pulse ring.
  - Motion lives in `Anim/Pet` and is driven by the pet's `Rarity` attribute.
  - Hovering pets (no part near the feet) float, lean into their walk and let their legs dangle; insects also
    buzz their wings.
  - A named PetFx special (`sync`) also cues the pet's flourish, so the effect and the gesture land together.

| Rarity | Under the pet | Pet effects | Egg effects | Motion |
|---|---|---|---|---|
| Common | nothing (soft glow behind it) | soft glow + one themed particle family (+ small light) | faint aura + one family | bouncy: quick bob, big waddle roll, a random hop every 3–6 s |
| Uncommon | nothing | Common + one accent (small orbit or a popping burst) | + one accent | bouncy, hops every 5–9 s |
| Rare | nothing | signature effect (themed swirl / orbit) + one family + a timed special + light | signature orbit + pulse ring + light | calmer, small roll; flourish (head toss, tail flick, wings spread, paw lift) every 7–11 s or on its special |
| Epic | soft ring at most | floating Orbit parts + layered particles + special | + orbit | calmer, flourish every 8–12 s |
| Legendary | its own glyph (like the Frost Serpent's sigil) | hero ring/glyph + accent light + special | its egg glyph | slow and majestic, flourish on its special |
| Mythic | glyph + Halo/Orbit groups | several families, rays or trails, two lights | glyph + orbit | slow, flourish |
| Divine | ceremonial sigil disc + rays | crown/halo, gear or sun framing | sigil | slowest, flourish |
| Secret | showcase stack | 8–9 layers | showcase | slowest, flourish |

**Build approach:** every pair is planned as **procedural blocks** (BlockBuilder + Sculpt). Four organic
pairs would benefit from **hybrid** blocks + a few MeshPart accents (31 Tide Leviathan, 55 Celestial Whale,
59 Plague Wyrm, 73 Nebula Jelly). That needs Partner A and B to agree first (CLAUDE.md rule 3); until then
they are built from blocks too. No pair needs a fully custom mesh.

## All 79 pairs

Legend: **P** = procedural blocks, **H** = hybrid candidate (blocks unless agreed). Built = ✅. Every egg and
pet effect uses a different layer stack (checked by the server tests for the built ones).

### 1 Meadow: greens, cream, soft tan; leaves, sprouts, flowers, bark
| # | Pair | Rarity | Egg design | Pet design (hero feature) | Egg VFX | Pet VFX | Build |
|---|---|---|---|---|---|---|---|
| 1 | Sprout Pup ✅ | Common | cream egg wearing a leafy cap with a pinked leaf edge, paw prints, sprout | chibi leaf puppy: floppy leaf ears, sprout, paw pads, leaf pendant | leaf motes rising, pollen, faint green ground aura | leaves falling around it, pollen sparkles, green body glow | P |
| 2 | Bumble Bloc | Uncommon | honey-striped egg, wax honeycomb band, glass wing nubs, antennae | chubby cube bee: glass wings, fuzzy collar, honey-dipper stinger | slow honey-gold drips, two buzzing glints | pollen orbit with a short trail, flower petals popping | P |
| 3 | Meadow Stag ✅ | Rare | fawn egg, cream dapples, blossom crown band, branch antler nubs, Rare band | forest stag: wide blossoming branch antlers, moss mantle, glowing eyes | petals circling the crown, pollen, green pulse ring | leaf-wind swirl through the antlers, blossoms drifting, glints | P |

### 2 Sandy Beach: sand, aqua, sea blue, white; shells, waves, driftwood, foam, gulls
| # | Pair | Rarity | Egg design | Pet design (hero feature) | Egg VFX | Pet VFX | Build |
|---|---|---|---|---|---|---|---|
| 4 | Shelly Turtle | Common | sand egg with a hex-plated shell cap and teal rim | little turtle, hex shell with a sand-dollar emblem | sand trickle, sea-foam sparkle at the base | tiny bubbles from shell vents, sand puffs | P |
| 5 | Gull Bloc | Uncommon | white egg with grey feather bands, beak nub, sailor-scarf ribbon | gull with a sailor scarf, big orange feet | sea-breeze feather motes swirling | feather drift, white wind ring pulse | P |
| 6 | Surf Otter | Rare | aqua egg with a surfboard fin, wave stripe, driftwood band | otter on a mini surfboard, sunglasses, shell in paw | spray droplets arcing over the fin | surf spray behind the board, foam ring under it | P |
| 7 | Tide Spirit ✅ | Epic | sea egg: foam crest, seashell fan, starfish, floating water ring, bubbles | floating water spirit: fin ears, foam mane, pearls, curling tail, glass halo | bubble trails, foam specks, tide pulse ring, droplet orbit | water mist, bubble stream from the tail, tide halo, foam glints | P |

### 3 Autumn Forest: orange, red, brown, gold; maple, acorns, bark, harvest
| # | Pair | Rarity | Egg design | Pet design (hero feature) | Egg VFX | Pet VFX | Build |
|---|---|---|---|---|---|---|---|
| 8 | Acorn Squirrel | Common | acorn egg: cross-hatched brown cap and stem | squirrel with a huge curled tail hugging an acorn | single autumn leaves drifting off the cap | acorn sparkle pops, leaf drift | P |
| 9 | Maple Fox | Uncommon | orange egg with maple-leaf plates and white ear tips | fox with a maple-leaf tail tip and leaf scarf | warm amber glow, three-leaf orbit | maple leaves trailing from the tail | P |
| 10 | Bark Owl | Rare | bark egg with knot-hole eyes and a mossy brow | owl in bark armour plates, amber eyes, leaf tufts | blinking firefly motes | firefly orbit, amber eye glow, falling leaves | P |
| 11 | Harvest Bear | Epic | wheat-gold egg with a woven basket band, apple and pumpkin charms | big bear in a harvest cloak with a produce basket and wheat crown | grain motes rising, warm ring | autumn-leaf whirl with trails, basket sparkles, warm pulse light | P |

### 4 Mushroom Grove: cream, moss, magenta, violet; caps, spores, moss
| # | Pair | Rarity | Egg design | Pet design (hero feature) | Egg VFX | Pet VFX | Build |
|---|---|---|---|---|---|---|---|
| 12 | Spore Slime | Common | violet glassy egg with a tiny mushroom top | jelly slime with a mushroom sprout | magenta spore puffs | wobbling spores, soft violet glow | P |
| 13 | Cap Bunny | Uncommon | cream egg under a red-dotted toadstool cap, ear nubs | bunny wearing a toadstool hat, moss tail | bobbing mushroom motes | spore ring pulse, two tiny orbiting mushrooms | P |
| 14 | Toad Knight | Rare | moss egg with a knight-visor band and mushroom plume | toad in mushroom-cap armour with twig sword and shield | spore bloom bursts, mist ring | sword glints, spore drift, glowing ground ring | P |
| 15 | Fungal Dragon | Epic | violet egg with glowing mushroom clusters growing out, moss band | dragon with mushroom-cap wings, glowing spots, moss mane | layered spore bloom and mist rings | spore clouds from the wing caps, pulsing spots, orbiting spores | P |

### 5 Desert Dunes: sand, gold, turquoise, brown; dunes, runes, scarabs, cactus
| # | Pair | Rarity | Egg design | Pet design (hero feature) | Egg VFX | Pet VFX | Build |
|---|---|---|---|---|---|---|---|
| 16 | Dune Lizard | Common | sand egg with turquoise diamond scales | lizard with a neck frill | dust puffs | sand trail, faint heat glow | P |
| 17 | Cactus Pup | Uncommon | ribbed cactus egg with spines and a pink flower | cactus-skinned pup with flower ears | dry dust aura, petal pop | small sand swirl, drifting petals | P |
| 18 | Scarab Golem | Rare | gold scarab-shell egg with a turquoise relic band | stone golem with a scarab back shell and turquoise runes | rune sparks circling | rune glyph orbit, golden dust | P |
| 19 | Sand Djinn | Epic | lamp-shaped egg: gold spout, lid, turquoise gem | djinn rising from a sand-tornado tail, gold bracers, turban gem | sand spiral rising from the lid | sand-tornado orbit with trails, rune ring, gold dust | P |

### 6 Snowy Peaks: snow white, icy blue, deep blue, silver; shards, snow, fur, horns
| # | Pair | Rarity | Egg design | Pet design (hero feature) | Egg VFX | Pet VFX | Build |
|---|---|---|---|---|---|---|---|
| 20 | Snow Bunny | Uncommon | snowball egg with a fluffy fur band and frosty ear nubs | bunny in earmuffs and a knitted scarf | gentle snowfall | breath puffs, snow sparkle | P |
| 21 | Frost Penguin | Rare | tuxedo egg with an ice-blue bow tie and frost crown | penguin on ice skates, scarf, ice-shard crest | frost sparkle ring | sliding ice-glow ring, light snow | P |
| 22 | Yeti Brute | Epic | shaggy fur egg with ice horn stubs and claw marks | huge yeti, ice horns, crystal knuckles | blizzard puffs, cold breath | snowstorm swirl, knuckle glints, frost burst ring | P |
| 23 | Frost Serpent ✅ (replaces the Ice Dragon) | Legendary | blue egg under a frost cap that drips down the shell, a serpent coil spiralling up it, snow line, antlers + crown crystal | glacier-blue serpent coiled on the ground and rising in an S: studded head with antlers, crystal mane, almond eyes, two-tone glass wings | frost rune-ring glyph, falling pixel snowflakes, glints, cold mist, light | snowflake sigil, glass ice-brick orbit with trails, pixel snowflakes, antler glints, coil mist, frost-breath special, core light | P (Blender-built block data: tools/blender/pets) |

### 7 Candy Land: pink, pastel blue, mint, yellow; swirls, sprinkles, frosting, gummies
| # | Pair | Rarity | Egg design | Pet design (hero feature) | Egg VFX | Pet VFX | Build |
|---|---|---|---|---|---|---|---|
| 24 | Gummy Bear | Uncommon | translucent jelly egg with a gummy bear inside | glassy gummy bear, two-tone | sugar sparkle | candy-heart pops, jelly glow | P |
| 25 | Lolli Pup | Rare | swirl lollipop egg on a stick base | pup with a lollipop tail and sprinkle fur | sprinkle confetti | spinning swirl disc, sprinkle rain | P |
| 26 | Cotton Sheep | Epic | cotton-candy cloud egg (pink/blue fluff) | sheep with cotton-candy wool and cone horns | pastel halo, sugar mist | candy cloud puffs, glitter, pastel halo | P |
| 27 | Sugar Unicorn | Legendary | frosted cake egg with sprinkles and a candy-cane horn | unicorn: candy-cane horn, frosting mane, sugar wings | rainbow sugar glitter, frosting drip | glitter halo, heart trail, sugar sparkle orbit | P |

### 8 Coral Reef: coral, ocean blue, teal, white; coral, fins, shells, bubbles
| # | Pair | Rarity | Egg design | Pet design (hero feature) | Egg VFX | Pet VFX | Build |
|---|---|---|---|---|---|---|---|
| 28 | Clown Fish | Uncommon | orange/white striped egg with fin nubs | floating clownfish wearing an anemone hat | small bubbles | bubble stream, swaying anemone glow | P |
| 29 | Puffer Bloc | Rare | round spiky egg with yellow spines | cube pufferfish with spines | bubble pops | inflate pulse ring, bubbles | P |
| 30 | Coral Turtle | Epic | egg with coral branches growing on it | turtle carrying a living reef, fish orbiting | reef shimmer, water halo | tiny fish orbit, bubble streams, wave ring | P |
| 31 | Tide Leviathan | Legendary | deep-blue egg with a fin crest and whirlpool band | coiled sea serpent with fins and glowing runes | whirlpool ring, bubbles | water spiral around the coils, wave rings, deep glow | H |

### 9 Volcano: obsidian, lava orange, ember red, ash grey; cracks, spikes, smoke
| # | Pair | Rarity | Egg design | Pet design (hero feature) | Egg VFX | Pet VFX | Build |
|---|---|---|---|---|---|---|---|
| 32 | Ember Pup | Uncommon | black egg with glowing lava cracks | pup with a flame tail tip | ember drift | ember sparks off the tail, smoke wisp | P |
| 33 | Magma Golem | Rare | rock egg with magma seams and a smoke vent | rock golem with a molten core and lava drips | smoke wisps, crack glow | molten sparks, heat glow, smoke | P |
| 34 | Ash Bat | Epic | ash egg with bat-wing flaps and ember eyes | bat with ember-veined wings in an ash cloud | ash flakes, ember-eye glow | ash trails off the wings, falling embers, red rim light | P |
| 35 | Inferno Dragon | Legendary | obsidian egg erupting with lava horn spires | dragon: flame wings, obsidian armour, magma core | ember eruption, lava glow ring | flame wings, smoke, fire halo ring, heat pulse | P |

### 10 Crystal Caves: quartz, cyan, violet, prism blue; crystals, facets, minerals
| # | Pair | Rarity | Egg design | Pet design (hero feature) | Egg VFX | Pet VFX | Build |
|---|---|---|---|---|---|---|---|
| 36 | Gem Mole | Uncommon | rocky egg studded with gems | mole in a mining helmet with a gem lamp | gem twinkles | helmet lamp beam, crystal glints | P |
| 37 | Quartz Golem | Rare | egg crowned with a quartz cluster | golem of quartz blocks with a prism core | refracted shimmer | shard orbit, prism sparkle | P |
| 38 | Prism Owl | Epic | faceted glass-panel egg | owl with crystal feathers and prism eyes | prism refraction flashes | prism sparkle bursts, shard orbit with trails | P |
| 39 | Crystal Drake | Legendary | amethyst geode egg cracked open | drake with crystal spikes, violet-cyan glow | geode glow, shard orbit | crystal-shard storm, star glints, prism ring | P |

### 11 Jungle Ruins: jungle green, jade, stone, gold; vines, temples, feathers, relics
| # | Pair | Rarity | Egg design | Pet design (hero feature) | Egg VFX | Pet VFX | Build |
|---|---|---|---|---|---|---|---|
| 40 | Vine Monkey | Rare | vine-wrapped stone egg with a banana leaf | monkey with a swinging vine tail and jade earrings | vine particles | leaf swirl, jade sparkle | P |
| 41 | Jade Jaguar | Epic | jade egg with jaguar rosettes and a gold collar | jade-spotted jaguar in gold relic armour | jade sparkle, ruin dust | jade glow, relic motes, leaf whirl | P |
| 42 | Temple Guardian | Legendary | temple-stone egg with a carved face and gold eyes | stone guardian with glowing glyphs and a shield | glyph ring glow | rune circle underneath, dust, gold eye beams | P |
| 43 | Quetzal Phoenix ✅ | Mythic | jade relic egg: temple band, vine spiral, plume crown, relic halo | quetzal phoenix: radiant layered wings, tail streamers, relic halo | vine orbit, ruin dust, jade glints, gold relic ring | leaf swirl with trails, feather flames, rune orbit, sun rays | P |

### 12 Neon City: cyan, magenta, electric blue, black, chrome; holograms, circuits
| # | Pair | Rarity | Egg design | Pet design (hero feature) | Egg VFX | Pet VFX | Build |
|---|---|---|---|---|---|---|---|
| 44 | Neon Cat | Rare | black egg traced with neon circuit lines | cat with neon stripes and a visor | pixel sparks | neon streak trail, scan line | P |
| 45 | Cyber Pup | Epic | chrome egg with an LED face screen | robot pup with holo ears and rocket boots | holo halo, light trails | boot thrusters, hologram flicker, data orbit | P |
| 46 | Mech Titan | Legendary | armoured egg with panel seams and a cockpit window | mech with shoulder cannons and a glowing visor | scan lines, electric arcs | energy arcs, neon streaks, hologram ring | P |
| 47 | Holo Dragon | Mythic | wireframe hologram egg (glass + neon edges) | dragon of holographic panels that glitch | glitch flicker, holo halo | shimmering holo wings, data streams, blue comet orbit | P |

### 13 Haunted Graveyard: ghost white, purple, black, pumpkin, bone; spirits, graves
| # | Pair | Rarity | Egg design | Pet design (hero feature) | Egg VFX | Pet VFX | Build |
|---|---|---|---|---|---|---|---|
| 48 | Ghost Pup | Rare | pale glowing egg with a stitched bandage | floating ghost pup with a chain collar | haunted mist | ghost wisps, purple flame tip | P |
| 49 | Pumpkin Golem | Epic | carved jack-o'-lantern egg with candle glow | pumpkin-headed golem with vine arms | candle flicker, bone sparks | purple eye flames, cursed fog, bat orbit | P |
| 50 | Bone Dragon | Legendary | bone-ribbed egg with a skull crest | skeletal dragon with a purple soulfire core | eerie aura ring, bone sparks | soulfire flames, cursed fog, wisp orbit | P |
| 51 | Reaper Spirit | Mythic | hooded egg with a scythe-blade fin and lantern | hooded reaper: scythe, lantern, tattered cloak | lantern glow, fog | soul-wisp orbit, cursed fog, void sigil underneath, purple flame | P |

### 14 Sky Islands: sky blue, white, gold, grey; clouds, feathers, lightning, halos
| # | Pair | Rarity | Egg design | Pet design (hero feature) | Egg VFX | Pet VFX | Build |
|---|---|---|---|---|---|---|---|
| 52 | Cloud Sheep | Rare | cloud-puff egg with a gold sun charm | sheep with cloud wool and tiny wings | cloud motes | cloud puffs, sky sparkle | P |
| 53 | Sky Griffin | Epic | feathered egg with a gold beak crest | griffin with great feathered wings | feather drift, airy halo | wind rings, feather swirl | P |
| 54 | Storm Eagle | Legendary | storm-grey egg with lightning-bolt cracks | eagle crackling with lightning, storm crest | lightning glints, thunder ring | lightning bursts, wind rings, storm cloud | P |
| 55 | Celestial Whale | Mythic | sky-blue egg with a whale tail and starry belly | flying whale with cloud sails and a gold halo | cloud motes, halo | cloud trail, star glints, halo, rays | H |

### 15 Toxic Swamp: acid green, murky brown, sickly yellow, black; slime, toxins
| # | Pair | Rarity | Egg design | Pet design (hero feature) | Egg VFX | Pet VFX | Build |
|---|---|---|---|---|---|---|---|
| 56 | Sludge Slime | Rare | acid egg dripping slime | slime full of toxic bubbles | acid haze | poison bubbles, slime drips | P |
| 57 | Bog Toad | Epic | warty egg wearing a lily-pad hat | toad with toxic throat sacs and a lily pad | sludge splashes | toxic fumes, bubbles, croak pulse ring | P |
| 58 | Toxic Hydra | Legendary | three-horned egg with acid-green veins | three-headed hydra | toxic sparkles, haze ring | poison mist from each head, bubbles, acid drips | P |
| 59 | Plague Wyrm | Mythic | cracked black egg oozing green | serpentine wyrm with spore vents | toxic haze, sludge bubbles | toxic cloud, spores, slime-drop orbit, green void ring | H |

### 16 Clockwork Factory: brass, copper, steel, steam, teal; gears, pipes, rivets
| # | Pair | Rarity | Egg design | Pet design (hero feature) | Egg VFX | Pet VFX | Build |
|---|---|---|---|---|---|---|---|
| 60 | Gear Pup | Epic | copper egg with a wind-up key and gear ears | wind-up pup with a turning key | steam puffs, cog sparkle | key-turn steam, spark pops, small gear halo | P |
| 61 | Steam Golem | Legendary | boiler egg with a pressure gauge and valve wheel | boiler golem with pipes and a gauge chest | steam jets, gauge glow | steam bursts, sparks, pressure ring | P |
| 62 | Brass Owl | Mythic | brass egg with a clock face and moving hands | clockwork owl with gear wings and lens eyes | spinning clock-hand disc, cog sparks | gear halos, spark trails, lens glints, steam | P |
| 63 | Clockwork Titan ✅ | Divine | brass reactor egg: teal porthole, pipes, stacks, gear ring and halo | brass golem: pauldrons, reactor core, sun-gear frame, gear crown, gear ring | steam, cog sparkles, teal glow, divine sigil | giant sigil behind, steam, forge sparks, teal rays, reactor light | P |

### 17 Frozen Aurora: aurora cyan, mint, violet, white; ribbons, frost, glaciers
| # | Pair | Rarity | Egg design | Pet design (hero feature) | Egg VFX | Pet VFX | Build |
|---|---|---|---|---|---|---|---|
| 64 | Aurora Fox | Epic | ice egg with an aurora ribbon band | fox with aurora-ribbon tails | aurora shimmer | aurora ribbons trailing the tails, snow mist | P |
| 65 | Frost Wolf | Legendary | glacier egg with a wolf-fang crest | wolf in glacier armour with a frost mane | cold sparkles, frost halo | frost breath, aurora glow, ice-shard orbit | P |
| 66 | Glacier Mammoth | Mythic | glacier-block egg with tusk arcs | mammoth with glacier tusks and aurora fur | frost halo, snow mist | aurora ribbon arcs, snowstorm, glacial glow | P |
| 67 | Aurora Seraph | Divine | crystal egg with aurora wings and a halo | ice seraph with aurora wings | aurora halo, frost sigil | aurora ribbons, white halo, frost sigil, prism glints | P |

### 18 Lava Core: lava orange, magma red, black, molten yellow; fissures, obsidian, flares
| # | Pair | Rarity | Egg design | Pet design (hero feature) | Egg VFX | Pet VFX | Build |
|---|---|---|---|---|---|---|---|
| 68 | Cinder Hound | Epic | cinder-block egg with an ember collar | hound with lava paws and an ember mane | core glow, ember orbit | ember rain, glowing lava paw prints | P |
| 69 | Obsidian Golem | Legendary | faceted obsidian egg with a magma core window | obsidian golem with magma fissures | molten smoke, core glow | magma bursts, heat haze, molten ring | P |
| 70 | Phoenix Lord | Mythic | flame-feather egg with a crown | fire phoenix king: flame wings and a crown | ember orbit, flame-crown glow | flame-wing embers, sun rays, fire halo, gold comet orbit | P |
| 71 | Magma Titan | Divine | volcanic core egg with obsidian plates and a sigil | magma titan with an obsidian crown | core flare, fire sigil | magma eruptions, ember rain, heat haze, sigil, rays | P |

### 19 Galaxy Void: midnight blue, purple, cyan, star white; stars, nebulas, void rings
| # | Pair | Rarity | Egg design | Pet design (hero feature) | Egg VFX | Pet VFX | Build |
|---|---|---|---|---|---|---|---|
| 72 | Star Cat | Epic | midnight egg with star sprinkles and a moon | cat with constellation markings | star sparkle, galaxy ring | stardust trail, star glints | P |
| 73 | Nebula Jelly | Legendary | nebula glass egg | jellyfish of nebula with star tentacles | nebula fog | nebula fog, tentacle glints, cosmic orbs | H |
| 74 | Cosmic Dragon | Mythic | galaxy-swirl egg with a planet ring | starfield dragon with an orbiting planet ring | planet orbit ring, nebula | cosmic orbiters, nebula, star crosses, void rings | P |
| 75 | Void Emperor | Divine | black void egg with a void sigil and crown | void emperor: star cape, crown, void orbs | void spiral, void sigil | void spiral, cosmic orbs, galaxy nebula, void sigil, star crosses | P |

### 20 Rainbow Heaven: rainbow, gold, white, prism light; wings, halos, prisms, clouds
| # | Pair | Rarity | Egg design | Pet design (hero feature) | Egg VFX | Pet VFX | Build |
|---|---|---|---|---|---|---|---|
| 76 | Rainbow Pony | Legendary | pastel egg with a rainbow-mane band on a cloud base | pony with a rainbow mane and cloud hooves | rainbow glitter | rainbow trail, cloud puffs, prism sparkles | P |
| 77 | Prism Phoenix | Mythic | prism-feathered egg | phoenix with prism-glass wings | prism aura, rainbow glitter | rainbow ribbon trails, prism ring, prismatic bursts | P |
| 78 | Heaven Lion | Divine | gold-white egg with sun-mane rays and a halo | lion with a sun mane, wings and halo | holy glow, gold halo, rays | sun rays, halo, divine sigil, light feathers | P |
| 79 | Prism Seraph ✅ | Secret | pearl egg: rainbow prism belt, gold ribs, prism crown, wings, halo, prism orbit | seraph on a cloud: three pairs of prism wings, rainbow aureole, jewelled halo | holy glow, rainbow pulse ring, glitter, feather motes, prismatic glints | rainbow comet trails, ribbon, rays, sparkles, light feathers, pulse rings | P |

## Build priority

1. **Hero examples (done, awaiting approval):** 1, 3, 7, 23, 43, 63, 79. They set the style and the ladder.
2. **Quick wins (fastest; every new player sees them first):** the Commons and Uncommons:
   2, 4, 5, 8, 9, 12, 13, 16, 17, 20, 24, 28, 32, 36.
3. **Marquee showcase (the pets players chase):** the Divines and Mythics:
   78 Heaven Lion, 75 Void Emperor, 67 Aurora Seraph, 71 Magma Titan, 77 Prism Phoenix, 74 Cosmic Dragon,
   70 Phoenix Lord, 47 Holo Dragon, 51 Reaper Spirit, 62 Brass Owl, 66 Glacier Mammoth, 55 Celestial Whale,
   59 Plague Wyrm.
4. **Legendaries:** 35 Inferno Dragon, 39 Crystal Drake (both have concept art), 27, 31, 42, 46, 50, 54, 58, 61, 65,
   69, 73, 76.
5. **Epics:** 15 Fungal Dragon, 19 Sand Djinn (concept art), 11, 22, 26, 30, 34, 38, 41, 45, 49, 53, 57, 60, 64, 68, 72.
6. **Rares:** 6, 10, 14, 18, 21, 25, 29, 33, 37, 40, 44, 48, 52, 56.

Each pair is one `Premium/<Key>.luau` file, one recipe entry in its zone's recipe file and one line in each
zone model file. Render it with a close-up (`Heroes` preview), and the tests pick it up when it joins the hero list.
