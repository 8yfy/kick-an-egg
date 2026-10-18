# Pen upgrade feedback

The local player's confirmed `DataChanged.penLevel` increase triggers one short reward sequence for all existing purchase entry points. The first profile snapshot, repeated/stale levels, insufficient funds and a maxed pen remain silent. No purchase, ownership, price, capacity, progression or server code was changed.

## Presentation
- Two decorative gate-post copies pulse to 104.5% over 0.14 s and settle over 0.24 s. The real posts retain their Size/CFrame/collision state and are hidden locally during the effect. Copies are anchored and cannot collide, touch or participate in queries.
- Each gate post emits seven warm gold/cream sparkles (three on Low Detail), lifetime 0.35–0.6 s, using the approved `WorldSprites.sparkle` asset. An occluded Highlight fades over 0.48 s. Reduced Motion uses the glow and UI fade without post scaling or particles.
- White Fredoka One `UPGRADED!`, dark outline and two gold sparkle accents share the existing top-center toast lane below the quest/zone bar. Scale 0.9 → 1.035 → 1, fade out at 0.76–0.98 s, cleanup at 0.99 s. No background panel or input capture.
- All world effects, UI, tweens and temporary connections are bounded. A newer purchase cancels/restores the prior sequence. Pen removal, ownership loss or UI destruction also cleans up. The replicated `PenBuiltLevel` and two gate posts are checked before decorating the rebuilt pen.

## Creator Store audio
Only audio IDs were used; no Store scripts or models were imported.
- [cartoon_pop — Schnogrind](https://create.roblox.com/store/asset/6586979979), free search result; Studio loaded length 0.191 s.
- [bling_diamond_pickup_2 — thienbao2109](https://create.roblox.com/store/asset/4612374393), free search result; Studio loaded length 1.508 s; the mix uses only a short fading segment.
- Alternate [bling_diamond_pickup_3](https://create.roblox.com/store/asset/4612374495) also loaded (1.505 s); not used.

`SoundBank.PenUpgrade` uses a quiet pop followed by the chime 90 ms later, with short fade envelopes. It plays through the existing Audio UI group under Master, respecting SFX/category settings and existing voice cleanup. Typed Sound objects are preloaded in the background. The old drawer-specific success sound/toast was removed to avoid duplicates. All other sound events keep their existing definitions.

## Verification — 2026-10-18
Tested in an isolated unpublished Studio place using the actual map, authoritative UpgradePen remote and a placed Sprout Pup.
- 14 focused checks passed: initial snapshot, level guards, insufficient funds, confirmed purchase/cleanup, collision/original geometry preservation, placed pet survival, loaded/audible audio, duplicate/stale messages, another pen's isolated update, Low Detail/master mute, Reduced Motion, rapid purchases, pen removal and max-level rejection.
- A real two-client StudioTestService session also passed: simultaneous purchases took both pens from level 1 to 2, with one notice/audio event per owner, effects restricted to each owner's pen, matching ownership and complete cleanup on both clients. The multiplayer harness measures cleanup after confirmed replication, so request latency is excluded. Production code needed no changes for this check.
- Desktop and iPhone 17 Pro landscape previews inspected. At a 750×381 phone viewport, notice bounds were about (273,71), 205×35 px; quest bottom was 51.6 px. With zone progress visible, notice top was 126 px versus zone bottom 106.3 px.
- Real W input moved the player 11.47 studs during the purchase presentation. AutoRotate/WalkSpeed remained intact. A script-only movement probe was inconclusive because normal player controls overwrote its input; the keyboard test is the movement evidence.
- Pop and chime were loaded and produced nonzero playback loudness in the actual client. Master mute and normal playback were checked; no manual asset authorization was required in the test place.
- StyLua parsing/format checks and Rojo builds passed. No pen-feedback runtime errors after the typed audio-preload fix. Existing unrelated logs included unpublished DataStore fallback and asset `203785492` type warnings.

The world effect is intentionally owner-local; remote clients receive no success notification. Physical mobile devices and published-server asset permissions remain unverified. No new uploads are required.

## Reproduction
In a fresh **unpublished** Studio Play session after player data/HUD have loaded, insert `tools/tests/PenUpgrade.server.lua` as a server Script and `PenUpgrade.client.lua` as a LocalScript in PlayerScripts. These tools are excluded from the Rojo tree; they refuse a published place. Results are JSON in `LocalPlayer:GetAttribute("PenQASuite")`.

Studio MCP's command context can have a separate ModuleScript cache. Run integration probes as actual Script/LocalScript instances rather than assuming a direct tool `require` shares the game's loaded service state. Stop the session to discard the in-memory test currency, pet, other-pen changes and QA remote. Restore the default Device Simulator viewport after mobile checks.

For multiplayer, temporarily insert `PenUpgradeMulti.server.lua` as a server Script and `PenUpgradeMulti.client.lua` under StarterPlayerScripts in Edit mode, then call `StudioTestService:ExecuteMultiplayerTestAsync(2, {test = "PenUpgrade"})` from a plugin/tool context. The test ends itself and returns per-client evidence. Remove these two temporary scripts afterward. They are also excluded from the Rojo tree.
