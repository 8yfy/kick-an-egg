# Pen upgrade feedback

The local player's confirmed `DataChanged.penLevel` increase triggers one short reward sequence for all existing purchase entry points. The current revision moves the title out of the HUD and into the world above the actual upgraded pen. The first profile snapshot, repeated/stale levels, insufficient funds and a maxed pen remain silent. No purchase, ownership, price, capacity, progression or server code was changed.

## Presentation
- A world-space BillboardGui floats 10–11.8 studs above PenArea, below the existing owner portrait. Bold cream/gold Fredoka One `UPGRADED!`, dark outline, rotating star accents and a green `PEN LEVEL N` subtitle pop in (0.55 → 1.06 → 1), gently rise and fade at 0.88–1.12 s. It scales with world distance; MaxDistance is 200 studs. No notice is created in PlayerGui.
- The visible gate/fence posts and rails now rise in a travelling wave. Two fronts start at the gate, travel around both sides and meet at the rear. Each copied model lifts 1.05 studs over 0.18 s and settles over 0.3 s, with phase offsets spanning 0.55 s. Gate posts scale to 107%; other fence models to 102.5%. Real parts keep their Size/CFrame/collision state and are hidden only locally during the effect. Every temporary part is anchored and cannot collide, touch or participate in queries. Floors, collision proxies and pets stay in place.
- Two gold ribbons sweep from the gate around the new footprint. A cream light ring expands across the floor, four corner rays rise, gold fragments float outward, and the two posts flash with short warm lights and fading Highlights.
- Reused approved sparkle/star/ring textures. Normal mode emits 34 short sparkles plus eight tiny gold fragments; Low Detail emits 14 sparkles plus four fragments and waves posts only. Particle lifetimes are 0.35–0.65 s. Reduced Motion uses the static world title/fade and post glow, without moving parts, ribbons, ripple, particles or fragments.
- All world effects, tweens and temporary connections are bounded; cleanup occurs 1.6 s after the rebuilt pen is ready. A newer purchase cancels/restores the prior sequence. Pen removal, ownership loss or UI destruction also cleans up. The replicated `PenBuiltLevel` and two gate posts are checked before decorating. No camera movement or input capture.

## Creator Store audio
Only audio IDs were used; no Store scripts or models were imported.
- [cartoon_pop — Schnogrind](https://create.roblox.com/store/asset/6586979979), free search result; Studio loaded length 0.191 s.
- [bling_diamond_pickup_2 — thienbao2109](https://create.roblox.com/store/asset/4612374393), free search result; Studio loaded length 1.508 s; the mix uses only a short fading segment.
- Alternate [bling_diamond_pickup_3](https://create.roblox.com/store/asset/4612374495) also loaded (1.505 s); not used.

`SoundBank.PenUpgrade` uses a quiet pop followed by the chime 90 ms later, with short fade envelopes. It plays through the existing Audio UI group under Master, respecting SFX/category settings and existing voice cleanup. Typed Sound objects are preloaded in the background. The old drawer-specific success sound/toast was removed to avoid duplicates. All other sound events keep their existing definitions.

## Verification — 2026-10-18
Tested in an isolated unpublished Studio place using the actual map, authoritative UpgradePen remote and a placed Sprout Pup.
- Current wave revision: 17 single-player checks passed. The new wave check measured 47 moving models on the level-2 pen and a rear-versus-front crest delay of 0.444 s. Low Detail moved 27 post models with a 0.440 s crest delay. All existing confirmation, failure, duplication, pet, collision, audio/settings, title/owner-portrait and cleanup checks passed. A desktop wave preview was inspected on the actual pen.
- The previous world-space revision passed a real two-client session. Multiplayer was not started again for this revision, following the user's request to turn it off. Studio was returned to Edit mode with NumberOfPlayers=0 and no QA scripts left in the edit tree.
- Desktop and iPhone 17 Pro landscape previews inspected with the actual upgraded pen. The world title is readable below the owner portrait, with a clear view of the expanding floor ripple. Screen-toast safe-area measurements from the earlier revision no longer apply because the title now occupies world space.
- Real W input moved the player 11.47 studs during the purchase presentation. AutoRotate/WalkSpeed remained intact. A script-only movement probe was inconclusive because normal player controls overwrote its input; the keyboard test is the movement evidence.
- Pop and chime were loaded and produced nonzero playback loudness in the actual client. Master mute and normal playback were checked; no manual asset authorization was required in the test place.
- StyLua parsing/format checks and Rojo builds passed. No pen-feedback runtime errors after the typed audio-preload fix. Existing unrelated logs included unpublished DataStore fallback and asset `203785492` type warnings.

The world effect is intentionally owner-local; remote clients receive no success notification. Physical mobile devices and published-server asset permissions remain unverified. No new uploads are required.

## Reproduction
In a fresh **unpublished** Studio Play session after player data/HUD have loaded, insert `tools/tests/PenUpgrade.server.lua` as a server Script and `PenUpgrade.client.lua` as a LocalScript in PlayerScripts. These tools are excluded from the Rojo tree; they refuse a published place. Results are JSON in `LocalPlayer:GetAttribute("PenQASuite")`.

Studio MCP's command context can have a separate ModuleScript cache. Run integration probes as actual Script/LocalScript instances rather than assuming a direct tool `require` shares the game's loaded service state. Stop the session to discard the in-memory test currency, pet, other-pen changes and QA remote. Restore the default Device Simulator viewport after mobile checks.

For multiplayer, temporarily insert `PenUpgradeMulti.server.lua` as a server Script and `PenUpgradeMulti.client.lua` under StarterPlayerScripts in Edit mode, then call `StudioTestService:ExecuteMultiplayerTestAsync(2, {test = "PenUpgrade"})` from a plugin/tool context. The test ends itself and returns per-client evidence. Remove these two temporary scripts afterward. They are also excluded from the Rojo tree.
