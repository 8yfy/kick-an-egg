# Map overhaul: five-pen hub and 20 themed zones (2026-10-14)

**Source package:** `Kick-an-Egg-Map-Overhaul` (CLAUDE_MAP_PROMPT.md, specs 01–05).

**Branch:** `b/spin-wheel`, together with the Prize Wheel and boards work. Nothing is committed, pushed or published yet.

**Baseline before any change:** `git diff` plus the untracked files, saved outside the repo. The last commit, `df86c03`, is the clean map before this work.

## What changed

### The hub (`src/shared/Builders/Map/MapBuilder.luau`)

| Spec item | Result |
|---|---|
| Exactly **5** pens | `Bases.Base1..Base5`, BaseIndex 1–5. `MapBuilder.PenCount = #PENS = 5`; there is no Base6. Two pens sit each side of the central path, gates facing it (Base1/3 left, Base2/4 right), and Base5 is at the end, facing the pad. |
| Larger, upgradeable pens | **Size:** a pen is **64×56 at level 1** (was 52×44) and grows each level to **76×72** at the last level (7, from Config/Upgrades.Pen + Economy.PlotSlots). See `MapBuilder.penSize(level)`.<br>**Growth:** `PenArea.Size` changes around a **fixed centre**, so saved pen-local positions stay valid. Floor, fence and dressing are rebuilt on `PenLevel` (folder `Base<i>.Pen`).<br>**Reserve:** each pen sits on a darker "lot" with a stone curb showing the space it will grow into.<br>**Looks by level:**<br>• level 1: wood fence;<br>• level 2: stepping stones;<br>• level 3+: white/blue fence, gate lamps, corner planters;<br>• level 5+: dark/gold fence, banners;<br>• last level: a small gold gate arch.<br>**Fixed pieces:** SpawnPoint, OwnerAnchor and PenSign sit outside the largest pen, so upgrades never move them. |
| Open launch platform, no arch | The launch arch and its 20 banners are removed. A side-mounted "KICK THE EGG!" sign stands on the deck, angled toward the arrival point. The two egg monuments, braziers and pad lights are kept. The pad itself (`Map.KickPad`), the ramp, the safe line and the player barrier are unchanged. |
| Physical Boxing Sack Shop | The same `BoxingSackShop` model and `OpenMenu:Store` prompt, now near the pad on the left. A new `Approach` anchor is the tutorial's target. |
| Physical **Pet Selling Stand** | New `PetSellingStand` model:<br>• four posts and a striped canopy;<br>• a "SELL PETS" sign with the approved paw icon (`hud_pets`, a real uploaded id);<br>• an open counter, crates of eggs and lanterns;<br>• the new "PetSeller" merchant (Merchants.luau and `Data/MerchantConfig.PetSellerMerchant`, UserId 0 so it wears a default avatar until you set one).<br>The prompt `OpenMenu:Inventory` opens the existing **Sell Pets** screen. Nothing is sold by walking up or opening it. |
| No Index / Rebirth / Training stands | The Index stall and its `stall()` builder are removed. The Index, Rebirth, Shop and Trade HUD buttons are unchanged, as is the sack quickslot. No sack stands. |
| Central plaza + focal point | **Egg fountain:** the existing fountain plus a spinning block egg, moved off the central path to (-30, -150).<br>**Paths:** pale stone paths (a 24-wide spine, 16-wide side paths, the shop walk).<br>**Planting:** lamps, flower beds and 10 garden islands. The walls become stepped, planted terraces. |
| Prize Wheel + boards | Moved with the hub. The wheel is on the right wall between pens 2 and 4. The two boards and the DONATE podium are on the left wall, facing it. |

### The 20 zones (new `src/shared/Builders/Map/Scenery.luau`)

Every zone keeps its Config bounds, order and lane, plus its existing landmark (Landmarks.luau) and props. New for each zone:
- **Themed canyon walls:** a per-zone face colour instead of the shared dirt blend.
- **Ledges:** 2–3 broken rows of themed ledges.
- **Rim lip:** a themed treatment along the top edge (snow, frosting, neon, lava cracks, crystals, coral, graves, rivets, grass or vines).
- **Background silhouettes:** two large shapes per side beyond the rims, slightly faded for depth. They are hills, dunes, forest, giant mushrooms, peaks with aurora, candy hills, coral spires, a volcano, crystal spires, jungle, a skyline, a spooky set with a moon, floating islands, swamp, a factory with smoke and a turning gear, forge spires, a planet with orbiting moon and asteroids, and cloud towers with a rainbow.
- **Boundary blends:** props of the next zone in the last ~10 studs of each shoulder, and of the previous zone in the first ~10 studs. Logical bounds don't move.
- **Motion:** a few slow spinning features (factory gear, meadow windmill, drifting sky islands, orbiting moon) run through the existing MapLifeController (distance LOD). One MapFx emitter per themed backdrop handles smoke, embers, spores and the like.

The **48-stud lane is clear**. The old low lane-edge props were at x 15–20, *inside* the lane. They moved to the shoulders (x 29–32), and the larger shoulder props moved 2 studs out. Only the 20 lanes and the ramp carry `LandingSurface`, as before.

### Other integration
- **UI:** `UI/init.luau` routes `OpenMenu:Inventory` to the Sell Pets modal.
- **Sell Pets screen:** new **RARITY** filter (cycles all rarities) and **SELECT DUPLICATES** (keeps your most valuable copy of each pet). The existing confirmation, cancel, protected-pet rules and server prices are unchanged.
- **Tutorial (`TutorialController`):** the pen step aims at your pen's **gate** from outside and at its middle once you're inside, so the trail never crosses a fence. The shop step aims at the shop's `Approach`, not its roof.
- **`PlotService`:** the "no free pen" message no longer says 6. Queueing is unchanged: it hands out any free `Bases` child, so a 6th player waits and gets a pen when one frees up.
- **Egg-hold sound (`PlacementController`):** it now plays at the character. Before, it played at the egg's handle, which on the equip frame is still at the tool's spawn spot. With the larger hub that spot is out of hearing range, so the sound was being culled. The playtest caught this.

## Five-pen capacity notes
- **No save-data changes.** Saved pets and eggs use pen-local coordinates around `PenArea`'s centre. Every pen is bigger than before at every level, and pens only grow around a fixed centre, so all previously valid positions stay valid at every level and in every orientation.
- **Capacity:** the slot count, upgrade costs and levels come from Config, unchanged.
- **Base assignment** is runtime only (not saved), as before. Five players get pens and a sixth waits.
- **Set Max Players = 5** in Studio (Game Settings > Places). This was not changed for you.

## Verification

| Check | Result |
|---|---|
| Server tests (`sh tools/run-tests.sh`) | **359 / 359**.<br>**Map overhaul section:**<br>• exactly Base1–5;<br>• pen size grows monotonically up to the reserve;<br>• a real pen resized through all 7 levels stays inside its reserve with a fixed centre, and shrinks back on release;<br>• no overlap between reserves, the spine and the shops;<br>• the Pet Selling Stand prompt and both shops' approach anchors exist;<br>• no Index/Rebirth stands and no arch;<br>• the fountain is off the path;<br>• 20 zones in canonical order, contiguous, each with landmark, ledges, backdrop and blend;<br>• **no part inside the lane** above the floor;<br>• part budget;<br>• the **tutorial trail** from the arrival point and from the pad reaches every pen gate and both shops without crossing a pen, the fountain or a shop. |
| Live Studio play session (`sh tools/playtest/playtest.sh`) | **143 / 143**.<br>**Same as before:** the whole loop (pad, mystery egg, kick cinematic, flight, steering home, avalanche, secure, egg to pen to pet, pick up and place, income), audio scenarios, Shift Lock and sack VFX.<br>**Tutorial:** steps 1 > 2 > 4 > 6 > 7 > 8 > done.<br>**New:** 5 pens on the map; the stand's counter opens the Sell Pets screen and sells nothing. |
| Real Studio screenshots (`sh tools/preview/maptour.sh`) | Saved to `Downloads/Kick-an-Egg-Map-Overhaul-Screenshots/`:<br>• 12 hub shots: spawn view, top-down overview, launch side, both shops, starter and max pen, pen 5 + fountain, wheel, boards, launch pad, return ramp;<br>• a contact sheet of all 20 zones outward;<br>• a contact sheet of all 20 zones on the way home. |
| Map profile (same script and machine, 3 builds) | Build time 0.145 s → 0.226 s.<br>Parts 5,554 → 8,529.<br>Lights 40 → 53.<br>Particle emitters 48 → 84.<br>(The "after" figures include the wheel and boards.) |

## Not tested
- **More than one real player:** the 6th-player queue, reconnecting, reassignment, other players' owner cards.
- **Pen orientations live:** only the test player's pen was played. The other four pens' trails and gates were checked geometrically.
- **Old saves:** no old save was loaded into each new pen. This is covered by reasoning plus the growth test.
- **Devices and settings:** touch and gamepad prompts, client frame time and memory on desktop and mobile, the low-detail effects mode, and StreamingEnabled (the place's own setting was not changed).
- **Avatar merchants:** they appear only on a live server with a configured UserId. In edit-mode screenshots you see the block placeholder.

## Studio check (5 minutes)
1. Open the built place and set **Max Players = 5**.
2. Press **Play**. You should spawn at your pen gate, looking toward the pad. Follow the tutorial trail to the pad, kick, steer home, and put the egg in your pen.
3. Press **E** at the Pet Selling Stand. The Sell Pets screen opens; try the RARITY filter, SELECT DUPLICATES, and CANCEL.
4. Use **Test → Clients and Servers** with 6 players. Five get pens and the sixth gets the "All pens are taken" message.
5. Upgrade a pen a few times: the fence and floor grow inside the curb.

## Rollback
- **Map only:** restore `src/shared/Builders/Map/MapBuilder.luau` and `Merchants.luau` from `df86c03`, and delete `Scenery.luau`. That version has six pens, so also restore the PlotService wording and the two test files.
- **Everything:** `git checkout -- .` and remove the new untracked files. This also removes the uncommitted Prize Wheel and boards work, so back that up first.

## Follow-up: Boxing Sack Shop remodel (2026-10-14)

**The building** is now an open gym storefront instead of a closed box with a small door:
- a stone plinth, red and white walls with stripes, and chunky front pillars under a header beam;
- a striped awning, and a flat roof with the sign standing on its front edge (nothing overlaps it);
- a mini boxing ring at the back, gloves and a poster;
- the counter at the front, with the Coach on a raised step behind it.

The model is still `BoxingSackShop`, with the same `OpenMenu:Store` prompt and its `Approach` anchor.

**Display sacks:** the six sacks inside (four on a gantry in the ring, two on wall brackets) are props, marked `Display = true`. MapLifeController builds no effects, lights or sounds for them; they only turn slowly. The sacks players own and use are untouched.

**Lighting:** the per-sack spotlights are gone. The shop now has 2 soft lanterns, a ceiling light and a sign light (4 lights in total, all brightness ≤ 1).

**Merchant:** the Coach is the owner's own avatar (`Data/MerchantConfig.BoxingSackMerchant.UserId = 3953001499`, Krono808).
- `MerchantService` loads that avatar fresh on every server start, in the account's own rig type (R6/R15).
- It re-applies the avatar every 5 minutes while the server runs (`ApplyDescriptionReset`, or a rebuild if the rig type changed).

**Verified:**
- Unit tests: 362/362, including "shop sacks are display props, ≤ 4 soft lights" and "the Coach stands behind its counter".
- Live play session: 143/143, including "the shop's display sacks run no effects".
- In a Play session the NPC wore Krono808's avatar (R15) and showed 5 studs above the counter.

## Fix: eggs couldn't be placed in the pens (2026-10-14)
- **Cause:** the overhaul moved each pen's floor tiles into `Base<i>.Pen` (rebuilt on upgrades). `PlacementController` only raycast against `Floor` parts directly under the base, so the aim never hit a floor and the hint always said "Walk to your pen and aim at its floor". The playtest missed this because it fired `PlaceEgg` directly.
- **Fix:** the aim now also looks in the `Pen` folder. `PlacementController.preview(screenPoint)` lets the playtest place through the real aim path.
- **Verified:** unit tests 363/363 (new check: the aim ray hits a floor tile across the usable area of every pen at every level); live play session 144/144 (new check: aiming at your pen's floor shows a valid spot, and the egg is placed there).
