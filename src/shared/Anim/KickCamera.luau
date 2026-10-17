--!strict
-- Partner A. YOUR egg kick's camera: one continuous, motivated shot timed to the kick clip (Anim/EggKick), instead
-- of cuts. Clip time t (CONTACT = the foot meets the egg):
--   start    eases out of the gameplay camera (0.45 s) to a profile from the kicking side, chest high and level
--            with the egg (out of its flight path), so the toss, the planted step and the leg read in silhouette
--   0.44     slow push in through the wind-up, field of view closing (tension), still accelerating at the hit
--   CONTACT  the shot holds on the foot; a short field-of-view punch (+7, settling over 0.35 s) is the impact; the
--            VFX shake stays small on top of it
--   +0.45 s  cranes up and swings round behind the kicker on an arc (never through the body) while it turns to
--            follow the launched egg, ending close to where FlightController wants its camera, which then takes
--            over (EggKick.cameraBusyUntil): no swing through the player, no snap
-- Every move is a smoothstep blend between key framings; a ray from the subject keeps walls and props out of the
-- lens. Interrupted (respawn, a new kick) it hands the normal camera straight back.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local EggKick = require(script.Parent.EggKick)

local KickCamera = {}

local NAME = "KTE_KickCinematic"
local BLEND_IN = 0.45
local FOLLOW = 0.45 -- seconds after contact the camera keeps the shot (crane to the egg)

type Shot = { eye: Vector3, at: Vector3, fov: number } -- eye / at in the kicker's frame (x right, y up, z back)

local KEYS: { { t: number, shot: Shot } } = {
	-- a profile from the kicking side, level with the egg (never in front of it), framing the toss above the body
	{ t = 0.12, shot = { eye = Vector3.new(9.6, 1.4, -1.3), at = Vector3.new(0, 0.9, -1.3), fov = 46 } },
	{ t = 0.44, shot = { eye = Vector3.new(9.2, 1.0, -1.3), at = Vector3.new(0, 0.5, -1.4), fov = 44 } },
	{ t = EggKick.WINDUP, shot = { eye = Vector3.new(8.6, 0.7, -1.3), at = Vector3.new(0, 0.15, -1.4), fov = 42 } },
	{ t = EggKick.CONTACT, shot = { eye = Vector3.new(8.2, 0.5, -1.4), at = Vector3.new(0.2, -0.25, -1.7), fov = 40 } },
}

local function smooth(a: number): number
	a = math.clamp(a, 0, 1)
	return a * a * (3 - 2 * a)
end

-- The framing at clip time t (monotone between keys: eased in and out of each, carried through the middle).
local function framing(t: number): Shot
	if t <= KEYS[1].t then
		return KEYS[1].shot
	end
	for i = 2, #KEYS do
		local a, b = KEYS[i - 1], KEYS[i]
		if t <= b.t then
			local k = (t - a.t) / (b.t - a.t)
			-- ease the push: slow out of each hold, but keep accelerating into the contact
			local e = if i == #KEYS then k * k else smooth(k)
			return {
				eye = a.shot.eye:Lerp(b.shot.eye, e),
				at = a.shot.at:Lerp(b.shot.at, e),
				fov = a.shot.fov + (b.shot.fov - a.shot.fov) * e,
			}
		end
	end
	return KEYS[#KEYS].shot
end

-- Keeps solid scenery out of the lens: pulls the eye in front of the first collidable thing between it and the
-- subject (the kicker, the eggs and see-through decor are ignored).
local function unblocked(subject: Vector3, eye: Vector3, ignore: { Instance }): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	params.IgnoreWater = true
	local dir = eye - subject
	local hit = workspace:Raycast(subject, dir, params)
	if hit and hit.Instance.CanCollide and hit.Instance.Transparency < 0.6 then
		return subject + dir.Unit * math.max(hit.Distance - 0.4, 1.5)
	end
	return eye
end

local active: number = 0

-- Plays the shot for `character`'s kick (contact at server time `contactAt`); `clipTime` reports the kick clip's
-- own time (it may run faster when the kick started late). `egg` returns the launched egg's position once it flies
-- (nil before). Returns stop().
function KickCamera.play(
	character: Model,
	contactAt: number,
	clipTime: () -> number,
	egg: () -> Vector3?,
	fovRest: number
): () -> ()
	active += 1
	local token = active
	local cam = workspace.CurrentCamera
	local root = character:FindFirstChild("HumanoidRootPart")
	if not cam or not root or not root:IsA("BasePart") then
		return function() end
	end
	EggKick.cameraBusyUntil = contactAt + FOLLOW
	local look = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	local frame = CFrame.lookAt(root.Position, root.Position + (if look.Magnitude > 0.1 then look else Vector3.zAxis))
	local fromCF, fromFov = cam.CFrame, cam.FieldOfView
	local fromType = cam.CameraType
	local started = os.clock()
	local ignore: { Instance } = { character }
	local eggs = workspace:FindFirstChild("ClientEggs")
	if eggs then
		table.insert(ignore, eggs)
	end
	local done = false

	local function finish(handBack: boolean)
		if done then
			return
		end
		done = true
		RunService:UnbindFromRenderStep(NAME)
		if handBack then -- interrupted: the normal camera comes back
			cam.CameraType = if fromType == Enum.CameraType.Scriptable then Enum.CameraType.Custom else fromType
		end
		TweenService:Create(cam, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			FieldOfView = fovRest,
		}):Play()
	end

	cam.CameraType = Enum.CameraType.Scriptable
	RunService:BindToRenderStep(NAME, Enum.RenderPriority.Camera.Value, function()
		if token ~= active or not root.Parent then
			finish(true)
			return
		end
		local now = workspace:GetServerTimeNow()
		local after = now - contactAt -- seconds since contact (negative before)
		if after > FOLLOW then
			finish(false) -- FlightController has the camera from here
			return
		end
		local t = clipTime()
		local shot = framing(t)
		local eye = frame * shot.eye
		local at = frame * shot.at
		local fov = shot.fov
		if after > 0 then
			-- the impact punch, then the crane: an arc round the kicker's right side to behind and above it
			fov += 7 * math.exp(-after / 0.12) * math.min(after / 0.03, 1)
			local k = smooth(after / FOLLOW)
			local a0 = math.atan2(shot.eye.X, -shot.eye.Z)
			local angle = a0 + (math.pi - a0) * k
			local radius = Vector3.new(shot.eye.X, 0, shot.eye.Z).Magnitude * (1 - k) + 15 * k
			local height = shot.eye.Y * (1 - k) + 8.5 * k
			eye = frame * Vector3.new(math.sin(angle) * radius, height, -math.cos(angle) * radius)
			local launched = egg()
			local follow = launched or (frame * Vector3.new(0, 3 * k, -10 * k))
			at = at:Lerp(follow, smooth(after / 0.3))
			fov += (58 - fov) * k
		end
		eye = unblocked(at, eye, ignore)
		-- out of the gameplay camera, eased
		local b = smooth((os.clock() - started) / BLEND_IN)
		if b < 1 then
			eye = fromCF.Position:Lerp(eye, b)
			at = (fromCF.Position + fromCF.LookVector * (at - fromCF.Position).Magnitude):Lerp(at, b)
			fov = fromFov + (fov - fromFov) * b
		end
		cam.CFrame = CFrame.lookAt(eye, at)
		cam.FieldOfView = fov
	end)
	return function()
		if token == active then
			finish(true)
		end
	end
end

return KickCamera
