# Reactive tutorial

Completed on `codex/reactive-tutorial`, based on `164cb63`. High complexity: audit/decision rules, native training/meter prototype, integrated walkthrough, recovery/layout checks, clean preview and binary verification. Other worktrees and gameplay/config/remote contracts were preserved.

## Behavior and presentation

New players and Settings replay now begin with a centered welcome panel: "Welcome to kick the egg!" and "Press to continue with the tutorial!". Continue explicitly starts guidance; Skip dismisses it. No objective, spotlight or world trail appears before that choice. The subsequent instructions follow real actions one at a time, with a numbered stage heading. Egg/Pet inventory controls are shown before pen navigation, while already held items still go directly to the pen.

The server observes real sack hits, current kick/chase state, inventory, placed eggs/pets, owned pen and income. Existing accomplishments take priority. Early eggs go straight to Eggs/HOLD or the pen when already held; arriving inside the pen switches guidance to placement on the grass. Existing eggs and pets skip earlier lessons. There is no spawn detour.

The free starter sack already exists in SackGear/Hotbar.Slot0, so its real control is highlighted without a shop detour. Three real hits introduce training. Training and pen facts persist through profile serialization; respawn preserves training while resetting the character counter baseline. Replay from Settings observes current progress without resetting saved completion/skip, inventory or rewards. Local replay tracks replicated sack hits even if the server tutorial was skipped.

Main guidance ends at the first placed pet and a brief income introduction: at least two seconds with income observed, or a five-second explanation fallback if the income tick is delayed. Affordable pen/speed upgrades are optional dismissible tips. No purchase, reward, camera takeover or movement restriction is introduced.

`UI/Tutorial` contains reusable welcome/objective cards, real-control spotlight and world guide. Four inactive masks leave the actual control clickable; rectangles account for visibility, scrolling clips and safe-area offsets. World guidance resolves BaseIndex plus OwnerUserId, then uses a highlight, small arrow, floor ring and offscreen pointer. The complete walking route is sampled by distance from the current player position every frame, beginning ahead of the feet and ending at the target. Front-facing image planes align each PNG's up axis with the route; exponential interpolation removes waypoint jumps. Up to 40 chevrons (24 touch / 18 Low Detail) and a thin connector use fixed pools. Walking-only navigation, torso-width corridor tests and bidirectional segment validation reject fence-crossing paths; asynchronous results are discarded after target changes. Guidance clears over Settings/Trade/modals and during the existing cinematic. Reduced Motion disables pulses, bobbing and completion sparkles. Existing UISuccess audio/volume routing is reused.

## Actual assets

Six original 512px RGBA PNGs extend the existing SVG icon language: Pointer, WorldArrow, Checkmark, Sparkle, TargetRing, PathMarker. PNGs and editable SVGs are in `assets/tutorial`; `tools/tutorial/make_assets.py` reproduces them using the repo icon helper and headless Chrome. Uploaded under verified creator **1340874349**. Actual returned decal and resolved image IDs are in `assets/tutorial/roblox-assets.json`; runtime Assets uses resolved images. No credentials are stored.

## Verification performed

- **60 pure checks**: fresh/partial training, duplicate/late counters, respawn accumulation, early eggs, assigned/waiting pen, stored/placed pets, chase precedence, loss/retry, late events, completion/skip/replay, unique short objectives. Run `lune run tools/tests/ReactiveTutorial.spec.luau`.
- **Native single-player walkthrough**: training hits by 4.68s (power 1 to 4), kick controls reached by 12.48s, real kick/flight/chase, secured egg at 67.05s, owned pen found at 79.38s, placed egg at 79.96s, native hatch at 100.24s, rendered roaming pet plus $27 real income at completion **102.28s**. No upgrade or tutorial reward. Inputs included native MCP mouse/keyboard and ordinary live gameplay. The optional QA walking actor uses actual humanoid movement on navigation waypoints, never teleports.
- Read-only recorder and walking actor are under `tools/tests`, outside production mappings. Raw trace: `C:/Users/kerem/Documents/Codex/2026-10-13/ca/outputs/ReactiveTutorial-Walkthrough.json`.
- **Recovery**: two real hits survived LoadCharacter; the next real hit finished training. Native SKIP saved skipped=true and hid guidance. Native Settings replay of that skipped fresh profile advanced after three further real hits while skipped remained true. Existing-pet replay went straight to income. Settings cleared screen/world guidance.
- **Guarded unpublished in-memory fixtures**: zero-kick early egg immediately selected placement; native Eggs/HOLD worked through the spotlight; walking into the real owned pen switched to grass placement. A client ownership fixture targeted Base2, then restored Base1; unavailable ownership cleared the arrow/highlight. This is target-resolution QA, not a live second-player assignment. Reduced Motion kept the target stationary. Five sanitization/JSON checks preserved facts and clamped malformed training counts.
- **Assets**: all six images reported IsLoaded=true; ContentProvider returned no fetch failures.
- **45 responsive component checks**: definitions and completion heading fit 844x390, 390x844 and 320x568 frames. Two narrow-screen clipping cases were repaired before the successful rerun. These are component previews, not physical touch-device tests.
- **Final clean Play**: 18 services/19 controllers loaded, one tutorial guide, no QA scripts; native sack click/hit updated TRAINING 1/3. No tutorial runtime errors. Inherited unpublished DataStore, avatar asset 203785492 and Roblox UIBlox warnings remain.
- Targeted StyLua parsing/format, diff checks and Rojo 7.7.1 build passed. Lune deserialization verified **294 source scripts**, all nine tutorial sources current/compilable and no QA/probe scripts packaged. The full legacy server suite was not rerun; its tutorial expectations were updated.

## Delivery and validation limits

Welcome/route revision (after `6dcf70a`): 36 route geometry checks and the existing 60 decision checks pass. Native welcome stayed visible without auto-advancing; Continue revealed the sack control, then three actual hits revealed the route. Native welcome Skip and Settings replay/Continue passed, including training while the saved tutorial remained skipped. Twelve settled welcome/header/touch-size checks passed in 844x390, 390x844 and 320x568 component frames.

The final motion test recorded 599 frames over ten seconds: 442 moving frames, zero stale arrow frames, at least 2.76 studs of forward lead, and a maximum 0.60-stud frame movement / 0.60-stud final-marker gap. The final native obstacle fixture had a blocked direct line to the pen, but its 35 markers followed three walking segments with zero collision crossings in either direction. An earlier jump-enabled route crossing was found and fixed by walking-only navigation and segment validation. Raw metrics: `outputs/ReactiveTutorial-Route-QA.json` outside the repo. `tools/tests/TutorialRoute.client.lua` reproduces read-only motion measurements alongside native walking or the test actor. The full first-pet walkthrough above belongs to the initial revision, not a rerun of this intro/route change.

Current binary verification: **296 source scripts**, all 13 relevant UI/tutorial sources current and compilable, no QA scripts. Targeted StyLua, diff checks and Rojo build passed. Final clean Studio preview starts at the welcome panel.

Top-slot follow-up: the redundant Quest/Eggs secured banner is no longer mounted or updated by UI. The tutorial card now uses its former top-center slot (24px desktop / 4px compact, inside the safe area). Toast placement accounts for the visible tutorial and zone bar. Fresh Studio verified the absent Quest, working native sack input/data updates, the new card positions and 20px notification clearance. The binary was rebuilt and checked; the full gameplay walkthrough above was not repeated for this layout-only change.

Studio has current sources and a clean single-player preview. TestService.NumberOfPlayers remains **0**; no multiplayer session was started. Deliverable: `C:/Users/kerem/Documents/Codex/2026-10-13/ca/outputs/KickTheEgg-ReactiveTutorial.rbxl`.

Physical phone/gamepad input, simultaneous multiplayer isolation, published DataStore reconnect and published-server asset permissions remain unverified. Fixtures do not replace those live checks. No automatic merge or publishing.
