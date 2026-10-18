# Leaderboard podiums

Both global boards now have three physical podiums: gold #1 in the center, silver #2 on the left and bronze #3 on the right. Each displays the same winner as its corresponding leaderboard row, including players who are offline. Existing ranking stores, score rules and the 60-second refresh remain unchanged. Boards sit six studs higher to leave room for the avatars; the existing Donate prompt sits in front of the donation podiums.

## Avatar and emote behavior

`Services/LeaderboardService` passes its resolved top three entries to `Util/LeaderboardPodiums`. Native Roblox avatars assemble in a private ServerStorage WorldModel before measuring, preserving the user's body proportions and accessories. This matters: an unassembled accessory can initially sit hundreds of studs from the body and produce an incorrectly tiny display when fitted. Oversized avatars uniformly fit a 6.2 by 6.8 by 5.6 stud envelope. This envelope measures the standing avatar; emotes can move its limbs outside that volume.

Avatar templates cache for five minutes, with at most 12 cached users and one simultaneous request per user. Rank changes clear the previous winner immediately. Revision checks reject late requests for old winners or destroyed boards. Failed requests retry on the next leaderboard refresh. Empty ranks remain unclaimed; invalid Studio guest IDs do not get invented avatars. Display rigs have no executable scripts, tools, movement, sensors or targeting collisions. A dedicated collision group protects against Roblox's client Humanoid initialization resetting torso CanCollide.

`Util/PodiumEmotes` randomly chooses from `HumanoidDescription:GetEquippedEmotes()`, intersected with `GetEmotes()`. Owning an unequipped emote does not make it eligible. The catalog emote container is loaded privately with AssetService, only its AnimationId is read, and the container is destroyed without entering the workspace. The resolved animation loops through the NPC's server Animator with a short blend. Catalog IDs and animation IDs differ; directly loading the catalog ID produces an empty track. Humanoid:PlayEmoteAsync only supports LocalPlayer, so it cannot drive these NPCs.

Animation resolution caches at most 64 catalog IDs and shares simultaneous requests. If an equipped asset is unavailable, another equipped emote is tried. A player with no equipped emotes remains standing. Roblox asset permissions still apply; no settings or permissions are changed. Tracks stop and are destroyed when the avatar is removed. Random selection repeats when the avatar is rebuilt, not on every leaderboard refresh.

## Nearby rank badges

`Controllers/LeaderboardDisplayController` adds gold, silver and bronze medal badges above the animated heads. They show #1/#2/#3 and the placement caption. Both player and camera must be nearby: opacity falls across 70–80 studs, then the badge hides. Badges also fade out of view and respect world occlusion. Discovery runs twice per second over the six named podium slots; removed or streamed-out avatars clean up their local badges. Existing shop labels and camera controllers are unchanged.

## Verification, 2026-10-18

- 24 isolated single-player server checks passed: layout, Donate access, appearance safety/fitting, shared requests, rank swaps, delayed loads, empty slots, failures/retry, invalid IDs, board removal, equipped-only selection and native avatar assembly.
- Seven client checks passed with six real-avatar fixtures: nearby badge visibility/style, equipped-only loop playback, visible replicated joint movement, player distance, camera distance and out-of-view hiding.
- Native production fallback correctly showed the local player's avatar and matching leaderboard name. Six-avatar preview used playtest-only sample rankings for users 1340874349, 3953001499 and 1; these sample rankings are not saved or shipped. The first two profiles played randomly selected equipped emotes; user 1 had none equipped and stood normally.
- StyLua, whitespace checks and Rojo binary/XML packaging passed. All 289 source scripts match the XML package; no QA/probe/candidate scripts ship. Deliverable: `outputs/KickTheEgg-LeaderboardPodiums.rbxl`, outside the repository.
- Studio returned to Edit with NumberOfPlayers=0. No multiplayer test or live DataStore write was performed. Published global rankings and published-server asset permissions remain unverified; the unpublished Studio place uses the existing local fallback.

To repeat: start a single-player playtest, run `tools/tests/LeaderboardPodiums.server.lua` as a temporary server Script, then populate the six podium slots with test rankings and run `LeaderboardPodiums.client.lua` as a temporary LocalScript. The client test restores its camera and character and does not restart production controllers. Stop Play to remove all fixtures.

API references: [HumanoidDescription](https://create.roblox.com/docs/reference/engine/classes/HumanoidDescription), [Animator](https://create.roblox.com/docs/reference/engine/classes/Animator), [AssetService](https://create.roblox.com/docs/reference/engine/classes/AssetService).
