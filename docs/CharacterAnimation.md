# Character animation rework

Partner A, branch `a/character-anims`. This rework covers:

- the egg kick and its cutscene camera;
- Kick Sack training;
- the shopkeepers;
- the idles and transitions around them.

Gameplay is unchanged: the same server events, timings, kick power, sack stats and launch.

## How the game played animations before

| What | Before | Problem |
|---|---|---|
| Egg kick, hold, brace | `Anim/EggKick` keys. Studio played them as registered KeyframeSequences. Live servers had no published id, so the same keys were written straight onto the joints. | Live had no blending: it snapped at the start and end of the hold, brace and kick. Every key used a per-key Cubic ease, so motion stopped at each key (robotic). The planted feet slid 2–3 studs. The hands floated off the egg. The egg dropped on a sine arc to a fixed point, not to the foot. |
| Kick cutscene | Three hard cuts in 0.9 s | The blend passed through the player's head. The giant egg covered the body. The impact close-up sat inside the leg, with a white-out flash. |
| Sack training | Guard and kick poses written every frame | Starting or stopping to walk snapped the arms up to 90° in one frame (11 snaps in 6 s). The stance was stiff, and there was only one kick. |
| Shopkeepers | The whole model bobbed 0.15 studs and turned toward you | They had no pose (arms hanging) and stood far behind the counters. The Pet Merchant's counter hid everything but its head. |

No animation asset ids exist in the project; nothing had been published.

## How they play now

Everything is data in `src/shared/Anim`, played by one small runtime layered on top of each character's own Animator:

| Module | What it does |
|---|---|
| `Clip` | Keys on monotone cubic curves (Fritsch–Butland), so motion accelerates and decelerates without overshoot. It also handles overlap and drag on secondary channels, `impact` keys (in fast, out heavy), `hold` keys, seamless loops, and markers. |
| `Body` | Measures the real rig (R15 or R6, Motor6D or AnimationConstraint) and provides forward kinematics plus two-bone IK. Feet stay planted and hands stay on things for every avatar's proportions. |
| `Mixer` | Plays clips as layers over the Animator in `Stepped`. Each layer has a priority, a smoothstep fade in and out, speed, exact-time markers, masks (upper body or legs), and procedural layers. There is one connection for all characters, layers are dropped when a character leaves, and far NPCs can be paused. |
| `EggKick` | The hold, the brace and the kick, with the egg fitted to the body, the egg toss arc, and the contact point. |
| `KickCamera` | One continuous, eased cutscene shot. |
| `Sack` | The training stance and three chainable kicks. |
| `Merchant` | Shopkeepers fitted to their real counters (the Coach leans on his; the Pet Merchant lounges in a chair built to fit him). |
| `Bake` | Exports any clip as a KeyframeSequence with markers, for the Animation Editor or publishing. |

Roblox's default Animate (your avatar's idle, walk and jump) keeps running underneath. Every layer crossfades in and out of it, so cutscenes always win while they play and hand movement back afterwards.

Why not published AnimationTracks? The fitted parts can't be one baked asset: feet planted by IK, hands on an egg whose size is fixed but on bodies that aren't, and shopkeepers fitted to counters of different heights. Studio and live also run exactly the same code, with no asset-ownership dependency. `Bake` can still turn any clip into a KeyframeSequence if you want one in the Animation Editor or published.

### Stage 1: egg kick and cutscene

| Time (s) | Beat |
|---|---|
| 0.00 | Hug the egg |
| 0.11 | Gather (anticipation dip) |
| 0.21 | **Release**: the legs drive up and the arms toss the egg |
| 0.33 | The support foot lifts |
| 0.44 | **Plant**: the step lands beside the falling egg |
| 0.65 | **WindUp**: the draw-back accelerates into its top |
| 0.745 | The hips fire, the thigh leads and the shin trails |
| 0.80 | **Contact**: the shin snaps straight, laces on the egg, `impact` key |
| 0.98 | Follow-through onto the support toes, leaning back |
| 1.27 | **Land** |
| 1.50 | **Recover**: the support foot steps back |
| 1.80 | Settled, blended into the Animator |

- **Lead time.** Contact (0.80 s) fits inside the server's 1.0 s lead. If the server's answer arrives late, the run-up speeds up by up to 1.4× instead of skipping frames, so contact still lands exactly at `KickAt`.
- **Egg.** The hold hugs the egg: its back sits against the chest, and both hands are placed by IK on its sides. The height is the lowest the arms can reach on that avatar. The egg rides a weld whose offset the clip animates. At Release it leaves on a ballistic arc that ends on the foot's laces at contact (`EggKick.toss`, computed from this avatar's leg).
- **Hold while walking.** The hold and the brace are split: the upper body always holds the egg, and the legs fade in only when you stand still. Walking across the pad with the egg keeps the normal walk instead of gliding.
- **Camera (`Anim/KickCamera`).** It eases out of the gameplay camera in 0.45 s into a profile from the kicking side, level with the egg and out of its path. It pushes in slowly through the wind-up as the FOV closes from 46 to 40. Contact gets a short FOV punch (+7, settling in 0.35 s) with a lighter shake. Then it cranes on an arc behind and above the kicker, following the launched egg, and ends where FlightController picks up (`EggKick.cameraBusyUntil`). A ray keeps scenery out of the lens. Reduced Motion and AUTO KICK still keep the steady camera.
- **VFX.** The cutscene's flash and shake were made smaller in `VFX/Egg.luau` for the close camera; the impact itself is unchanged.

### Stage 2: sack training

The timing is unchanged: 0.6 s per kick with contact at 0.26 s (`Anim/Player.KICK_IMPACT` / `KICK_LENGTH` = `Config/Upgrades.Sack.interval`), and `Remotes.Train` still fires at impact. Damage, cooldowns, hit detection and rewards are untouched.

- **Stance.** Lead foot forward, rear foot turned out, hips bladed, guard up, and a light bounce. The feet are planted by IK. It fades in when you stand still and out when you walk, with hysteresis.
- **Kicks.** A rear push kick and a lead snap kick alternate, and the existing super kick (every 10th, top tiers) is a rear roundhouse whose hips turn through about 85° while the support foot pivots. Each kick runs anticipation, chamber, hip-driven extension, contact with a short sticky hold, re-chamber, landing in its spot, then settles. All three start and end exactly on the stance, so they chain back to back.
- **Contact check.** Measured on your avatar, the sole meets the bag face at 2.05 studs, about 0.08 below the hit point.

### Stage 3: shopkeepers

- **Fitting.** Rays find each counter's real top and back edge. A small search over torso lean and standing distance puts the forearms flat on the top with the upper arms hanging naturally. The NPC is slid only along its own facing, on this client, so it stands right behind its counter and its torso never enters the counter.
- **Coach.** Its counter is hip high, so it gets a real lean of about 42°.
- **Pet Merchant (lazy style, `Merchant.STYLE`).** He lounges in a tall reclining chair behind the stand, leaning back about 38°, hands clasped behind his head with the elbows out, both feet up on the counter.
  - **Feet.** Both shoes stand on their heels on the counter's back edge, toes up and turned out (leg IK, knees bending up). They stay 0.015 studs above the top through the whole loop.
  - **Hips.** They sit back along the legs; the model only slides back and up into the chair, never into the counter.
  - **Chair (`Builders/Models/LazyChair`, classic studded bricks in the stand's wood, teal and gold).** It is built around his pose, not the other way round. The seat tilts up under his thighs and the back lies along his spine. He sinks a little into both cushions, so he never floats on them. A headrest sits right behind his clasped hands, and they rest on it. The chair has armrests, splayed legs with an X brace on each side, brass feet and a gold foot rest. It is a client-side prop with no collision, queries or touches, and it goes away with the NPC.
  - **Arms.** The hands follow the head part of the way, so the head turns and nods inside them. The arm IK runs in Body's new `exact` mode: on this avatar the shoulder pivot sits 0.35 studs inside the arm part, which otherwise left the wrist 0.36 studs off target.
- **Life.**
  - It breathes every 4.3 s and its weight drifts from leg to leg (feet planted).
  - It takes unhurried glances, and a hand sometimes slides along the counter.
  - Its head turns toward a nearby player (eased, ±70°) while its body stays on the counter.
- **Pet Merchant life.**
  - He breathes every 4.8 s.
  - He takes bored glances and the odd head tilt.
  - He settles in the chair every 9–15 s (a small yaw and roll).
  - One foot rocks on its heel every 6–12 s.
  - His head turns toward a nearby player.
- **Greeting.** On the existing speech-bubble proximity, the Coach looks up, straightens about 35% and gives a small wave, then goes back to leaning. The Pet Merchant lifts his head toward the player and gives a tiny nod, staying seated with his feet up.
- **Blinks.** Not possible: these avatars have no FaceControls.
- **Runtime.** It runs as its own Mixer layer from the rest pose, and pauses when far away or off screen. MapLifeController no longer bobs or turns the avatar NPCs; a placeholder merchant without a rig still does.

### Stage 4: idle and transitions

Every hand-over is a crossfade:

- hold to brace to kick;
- kick to recovery to the Animator;
- stance to walk;
- kick to kick;
- lean to greet.

There are no hard stops. Your avatar's own idle and walk (its animation pack) are kept as they are. The new idle life lives in the egg hold, the training stance and the shopkeepers. Respawns, deaths, characters leaving and streaming are handled: layers are dropped, and the cutscene gives the normal camera back.

## Showcase (Studio only)

Press `;` in Play to open a local stage far above the map, with:

- the kick (gameplay camera) and the perfect-kick cinematic;
- one sack kick and training ×6;
- walk to stance;
- the shopkeeper greeting;
- R6.

Everything runs on copies of real rigs through the game's own modules. The panel shows the live layer count, for leak checks. The attribute `AnimShowcaseDemo` = a button's text runs that demo, for recording.

## QA report

All of this was played in Studio (`build/KTE-anim-after.rbxl`, built from this branch).

| Check | Result |
|---|---|
| Kick, joint probe on your avatar (single-frame jumps, 60 fps) | 0 snaps. Live before had unblended joint writes. |
| Kick, planted feet (IK, measured) | Hold and brace loops: 0.000 studs. Landing and recovery: 0.000. Support foot during the strike: only its intended toe rise. Before: 2–3 studs of slide. |
| Kick, contact | The egg arrives at the laces exactly at `KickAt`, and the contact point is computed from the avatar's leg. |
| Cutscene camera | One continuous shot with no cuts. It never passes through the body or the egg's path, and hands off to FlightController smoothly (`after/kick_cutscene.mp4`). |
| Sack training in game, chained clicks plus walking away and back | 0 snaps (before: 11). The server counted 7 kicks in the same click test as before (7), so the timing is unchanged. |
| Sack, 7-kick chain with all 3 variations (clone) | 0 snaps. The hip and knee peak at about 2,300–2,400°/s at the strike. |
| Shift-lock (CameraRelative steering) | 0 snaps, and the server counted 5 kicks. |
| Shopkeepers | The forearms rest on the counter top (0.00–0.04 studs). Only forearm-to-top surface contact; no torso overlap. The greeting plays (`after/shopkeeper_coach_greet.mp4`). |
| Pet Merchant, lazy (20 s loop plus 16 s with a customer at 4 spots) | **Shoes:** on the counter top, 0.013–0.015 studs above it. **Seat and back:** he sinks 0.06–0.10 studs into the cushions (always touching, never floating). **Hands on the headrest:** −0.02 to +0.09 studs. **Clipping:** only shins resting 0.01 on the top's back edge; the chair touches nothing in the stand. **Motion:** largest joint step 0.4° per frame, no snaps. **Nod:** plays on the greeting. **Selling:** the Counter prompt still fires and opens the inventory. **Views:** `after/pet_merchant_lazy_*.jpg` (front, side, back-side, three-quarter, player distance). |
| Respawn mid-cutscene | The normal camera comes back with its subject on the new character. One error was found (`Body.luau`: a dying rig losing joints) and fixed. |
| R6 rig | The kick, hold and stance play on R6 joints (no IK on R6), with no errors (`after/r6_kick_and_stance.mp4`). |
| Server tests (Studio edit context, as run-in-roblox would) | 365 passed, 3 failed. The same 3 map/shop tests also fail on the untouched a/full-build (362 passed, 3 failed). All the new animation checks pass. |
| Environment | No map, zone, weather, lighting or environment code changed. Only MapLifeController's merchant part was edited. |

Evidence is in `docs/anim`, which has three folders: `before/`, `after/` and `review/`. The videos play at real speed. `review/` holds key-pose sheets from side, front and back.

## Known limits and follow-ups

- **Pet Merchant.** The folded-arms pose (`before/pet_merchant_folded_arms.jpg`) was replaced by the lazy chair pose. The counter and stand are unchanged.
- **Arm IK on offset shoulders (`Body.solve`).** On avatars whose shoulder pivot sits inside the arm part, the default solve leaves the wrist up to about 0.36 studs off target. The new `exact` mode fixes that, but only the Pet Merchant uses it, so the egg hold and the Coach keep the poses they were tuned with. Turning it on everywhere means re-checking those hand contacts.
- **Flying egg start (FlightController, Partner B).** The flying egg starts at the pad centre, not at the kicker's foot, so a big egg can pop up beside the kicker at contact. It is cosmetic, but it's B's launch code, so it wasn't touched here.
- **Shift-lock (SackController, Partner B).** With shift-lock, the body turns back toward the camera right after the kick squares you up to the bag, so the kick goes where the camera looks. The animation blends correctly either way.
- **Not tested:** a two-player session (watching someone else's kick or training), a real mobile device, and a live server.
