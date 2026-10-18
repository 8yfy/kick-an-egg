# Shift Lock camera handoff — 2026-10-18

## Off-centre cursor fix (current revision)
The exact trigger is moving the unlocked cursor away from the viewport centre, then pressing Shift. A native desktop-input trace captured a delayed relative mouse packet `(−2, −42)` arriving 0.031 s after the toggle, on the third rendered frame. The default camera consumed it as a 16.170-degree upward rotation. The previous two-frame pitch guard had already expired. Synthetic MCP keys did not reproduce this packet; the earlier lateral-only checks missed the real symptom.

`ShiftLockController` now uses the public `UserInputService.MouseDeltaSensitivity` property to zero relative mouse input for 0.12 s on the default camera's rotation-mode handoff. This filters recentering before Roblox performs its normal look and collision calculation. The property scales movement deltas without changing cursor movement or the user's selected sensitivity ([Roblox API](https://create.roblox.com/docs/reference/engine/classes/UserInputService#MouseDeltaSensitivity)). Ordinary mouse look resumes after the handoff; keyboard movement continues throughout.

The previous sensitivity is restored exactly, including custom values. Repeated toggles retain that original value, timers cannot outlive Destroy, and restoration respects a newer input owner's nonzero setting. First-person, dead/absent characters, other subjects, scripted cameras and VR bypass this protection. Camera ownership changes restore input on the next render step. No default PlayerModule internals are changed.

The rejected two-frame pitch correction is removed. VFX shake uses its original render priority; the existing 0.25 s shoulder-offset easing remains. The controller never sets MouseBehavior, RotationType, CameraType, CameraSubject, Humanoid.CameraOffset or character transforms.

Validation of this revision:
- Fresh single-player Studio session, production source: eight controlled native Shift toggles, entering/exiting from lower-right, lower-left, upper-left and upper-right cursor positions. Each captured 73 frames (about 1.2 s) with **0 degrees of pitch change and 0 degrees of yaw change**. Final sensitivity returned to 1. Visual previews inspected. Cursor coordinates and results: `outputs/ShiftLock-Cursor-Test.json` outside the repo.
- Walking through two toggles: 20.80 studs travelled, WalkSpeed 16, AutoRotate true, own Humanoid still followed, sensitivity restored to 1.
- Switching to a fixed Scriptable camera during handoff: 0 studs of unwanted movement, Scriptable retained, sensitivity restored.
- Lune 0.10.5: **27 offline regression checks passed**, including a third-frame native-style warp, entering/exiting lock, exact sensitivity restoration, rapid toggles, Destroy/timer cleanup, external input ownership, camera ownership, bypass cases and shake drift. The previous two-frame controller fails the new third-frame regression.
- Studio returned to Edit, TestService.NumberOfPlayers=0, no QA/probe scripts in Edit. No multiplayer session was started. Pen-wave tests were not rerun for this camera-only follow-up.

`tools/tests/ShiftLock.spec.luau` is the offline fixture. `tools/tests/ShiftLock.client.lua` measures pitch/height without excluding rotating frames and includes scripted-camera handoff mode. `tools/tests/ShiftLockNative.client.lua` records real cursor/input/default-camera timing for 180 s, then restores its temporary instrumentation; firing its `Finish` BindableEvent ends it early. Insert diagnostics only at runtime in an unpublished Studio test; they are not mapped into deliverable builds.

Current deliverable: `outputs/KickTheEgg-ShiftLockFixed.rbxl` outside the repo. Previous `ShiftLockPitch` builds contain the superseded two-frame guard. Published servers, physical mobile/VR, first-person transitions and seated/vehicle cameras were not separately tested this revision.

## Previous shoulder-offset revision (historical)

The user reported snapping during normal walking with nothing equipped. In a stationary Studio probe, toggling Shift Lock produced an immediate 1.75-stud lateral camera step and zero camera rotation. The shipped PlayerModule's MouseLockController/BaseCamera sources confirmed the normal shoulder-offset/CameraRelative path. No pen-target camera script was found in this reproduction; the known sack square-up behavior is a separate, unchanged case.

## Change
`src/client/Controllers/ShiftLockController.luau` eases the default camera's lateral offset change over 0.25 s. It reads the default camera's CameraRelative rotation state rather than cursor lock alone, so right-mouse dragging/menu cursor changes do not masquerade as Shift Lock.

It never sets MouseBehavior, RotationType, CameraType, CameraSubject, character CFrame, Humanoid.CameraOffset, speed or AutoRotate. It preserves raw mouse look, zoom and forward movement. It operates only on the normal third-person camera following the local Humanoid; first-person, other subjects and scripted cameras are excluded.

A temporary lateral correction is applied after the default camera and VFX shake, and removed before their next update. Undo checks camera identity, subject, type and the last written frame. If a cinematic has taken ownership, it keeps the presented frame intact instead of subtracting an old shoulder correction. This prevents drift and avoids changing a newly started cutscene's first frame.

## Tests performed
- Actual Shift-key input, two toggles per comparison: baseline max stationary lateral step 1.750 studs/frame; smoothed max 0.178 studs/frame; camera rotation 0 degrees in both measurements.
- Six repeated toggles: final camera drift 0 studs, rotation drift 0 degrees, correct local Humanoid subject and Custom mode.
- Walking while toggling: player travelled 13.90 studs, WalkSpeed 16, AutoRotate true, correct subject.
- Switching to a fixed Scriptable camera mid-transition: 0 studs of unwanted motion, Scriptable retained. An initial test caught an undo offset at that boundary; the ownership/type guard fixed it and the regression retest passed.
- StyLua/Rojo checks passed; no controller runtime errors during these probes.

`tools/tests/ShiftLock.client.lua` provides an unpublished, single-player diagnostic. Set `LocalPlayer.ShiftLockQAMode` to `baseline` or `smooth`, insert the file as a LocalScript in PlayerScripts, then press Shift twice. Results are in `ShiftLockQA_<mode>`. Baseline temporarily disables the controller; the diagnostic restores it afterward. Mode `handoff` checks the scripted-camera boundary on the next Shift press. Input tools can recenter the mouse themselves, so the stationary metric excludes frames with significant mouse-look rotation.

Real hardware input feel, first-person zoom and seated/vehicle cameras were not separately playtested. They remain under Roblox's default controls; this controller explicitly excludes the latter camera paths where applicable.
