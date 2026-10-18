# Shift Lock camera handoff — 2026-10-18

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
