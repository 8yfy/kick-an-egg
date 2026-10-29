--!strict
-- The hatch reveal (client, cosmetic). The pet already exists on the server when the show starts; nothing here
-- grants, moves or duplicates anything, and every path out puts the camera, the pet's look and its size back.
--   * HatchCinematicController.request(egg): your hold on a READY egg finished. A local copy of the egg starts its
--     anticipation at once and HatchEgg goes to the server, which decides. EggHatched for that egg continues the
--     show; no answer (a refusal: the server's reason arrives as a toast) puts the real egg back.
--   * EggHatched for someone else's egg near you, or for yours hatched elsewhere: the short world version (no
--     anticipation, no camera, a quicker growth).
-- The show (Presentation/HatchStyle: the rarity tier, plus a signature for some pets):
--   anticipation (wobble speeding up, cracks, a rarity glow, crack sounds) -> the shell bursts -> the REAL pet model
--   appears as a tiny solid silhouette (a Highlight fill: its own shape, wings and horns included) -> it grows to
--   its real size (its size mutation, set by the server) with a shockwave, orbiting motes, an aura and a pillar by
--   rarity -> the silhouette fades into its own materials with a flash and sparkles -> a landing that suits its rig
--   (hop, unfolding wings, a serpent rising, a heavy settle) -> its nameplate appears (PetNameplateController) and
--   it walks its pen again (the server holds it still for HatchStyle.HOLD_SECONDS).
-- A freshly hatched pet is hidden on this client the moment it arrives, so it never flashes at full size before
-- its show. The hatching player gets a gentle camera framing (not with Reduced Motion). A click, tap, E or Space
-- skips to the reveal. Low Detail effects halves the effect budget.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Rarities = require(Shared.Config.Rarities)
local Remotes = require(Shared.Remotes)
local Anim = require(Shared.Anim)
local Rig = require(Shared.Anim.Rig)
local VFX = require(Shared.VFX)
local Audio = require(Shared.Audio)
local Burst = require(Shared.VFX.Burst)
local Fx = require(Shared.VFX.Fx)
local Shake = require(Shared.VFX.Shake)
local HatchStyle = require(Shared.Presentation.HatchStyle)

local HatchCinematicController = {}

local REFUSAL_WAIT = 4 -- seconds without an answer = the server said no
local PET_WAIT = 3 -- seconds to wait for the pet model to replicate
local FRESH = 2 -- a pet whose HatchedAt is this recent is hidden on arrival until its show takes it
local WATCH_RANGE = 160 -- studs: other players' hatches are shown this close
local MAX_WATCHED = 3 -- other players' reveals at once (effect budget)
local TINY = 0.08 -- the silhouette's starting size (fraction of its real size)

local player = Players.LocalPlayer

type Show = {
	own: boolean,
	style: HatchStyle.Tier,
	sig: HatchStyle.Signature?,
	rarity: string,
	color: Color3,
	skip: boolean,
	low: boolean,
	reduced: boolean,
}
type Pending = { egg: Model, double: Model, stopWobble: () -> (), show: Show, anticipationEnds: number }

local pending: { [string]: Pending } = {}
local hidden: { [string]: { model: Model, restore: () -> () } } = {} -- petUid -> a fresh pet waiting for its show
local watching = 0

local function reduced(): boolean
	return player:GetAttribute("ReducedMotion") == true
end

local function lowDetail(): boolean
	return player:GetAttribute("LowDetail") == true
end

local function rainbow(t: number): Color3
	return Color3.fromHSV((t * 0.35) % 1, 0.55, 1)
end

local function newShow(rarity: string?, key: any, own: boolean, short: boolean): Show
	local r = if typeof(rarity) == "string" and Rarities[rarity] then rarity else "Common"
	local sig = if typeof(key) == "string" then HatchStyle.Signatures[key] else nil
	return {
		own = own,
		style = HatchStyle.tier(r),
		sig = sig,
		rarity = r,
		color = if sig and sig.tint then sig.tint else Rarities[r].color,
		skip = false,
		low = lowDetail(),
		reduced = short or reduced(),
	}
end

-- Waits (yields) for `seconds`, cut short when the show is skipped.
local function hold(show: Show, seconds: number)
	local t0 = os.clock()
	while os.clock() - t0 < seconds and not show.skip do
		task.wait()
	end
end

-- Turns off the pet's particles, beams, trails, lights and billboards (its idle and weather effects, which can
-- arrive while the show runs) until the returned function puts them back.
local function quietEffects(model: Model): () -> ()
	local saved: { [Instance]: boolean } = {}
	local function quiet(d: Instance)
		if d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail") or d:IsA("Light") or d:IsA("BillboardGui") then
			if saved[d] == nil then
				saved[d] = (d :: any).Enabled
			end
			(d :: any).Enabled = false
		end
	end
	for _, d in model:GetDescendants() do
		quiet(d)
	end
	local conn = model.DescendantAdded:Connect(quiet)
	return function()
		conn:Disconnect()
		for d, was in saved do
			if d.Parent then
				(d :: any).Enabled = was
			end
		end
	end
end

-- Hides a fresh pet (parts and effects) on this client; returns how to show it again.
local function conceal(model: Model): () -> ()
	local loud = quietEffects(model)
	Fx.hideLocally(model, true)
	local conn = model.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = 1
		end
	end)
	local done = false
	return function()
		if done then
			return
		end
		done = true
		conn:Disconnect()
		if model.Parent then
			Fx.hideLocally(model, false)
		end
		loud()
	end
end

-- The pet model for `petUid` (waits up to `timeout` for it to replicate).
local function findPet(petUid: string, timeout: number): Model?
	local t0 = os.clock()
	repeat
		local h = hidden[petUid]
		if h and h.model.Parent then
			return h.model
		end
		local map = workspace:FindFirstChild("Map")
		local zone = map and map:FindFirstChild("SafeZone")
		local bases = zone and zone:FindFirstChild("Bases")
		if bases then
			for _, base in bases:GetChildren() do
				local plots = base:FindFirstChild("Plots")
				if plots then
					for _, m in plots:GetChildren() do
						if m:IsA("Model") and m:GetAttribute("PetUid") == petUid and m.PrimaryPart then
							return m
						end
					end
				end
			end
		end
		task.wait(0.05)
	until os.clock() - t0 > timeout
	return nil
end

-- Effects ------------------------------------------------------------------------------------------------------

local function localPart(name: string, shape: Enum.PartType): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = shape
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Material = Enum.Material.Neon
	return p
end

-- A flat ring on the ground that widens and fades.
local function shockwave(at: Vector3, color: Color3, radius: number, seconds: number)
	local ring = localPart("HatchRing", Enum.PartType.Cylinder)
	ring.Color = color
	ring.Transparency = 0.25
	ring.Size = Vector3.new(0.12, 0.6, 0.6)
	ring.CFrame = CFrame.new(at + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = workspace
	local info = TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(ring, info, { Size = Vector3.new(0.12, radius * 2, radius * 2), Transparency = 1 }):Play()
	task.delay(seconds + 0.05, function()
		ring:Destroy()
	end)
end

-- Motes orbiting the growing silhouette; returns a stop function.
local function orbit(ground: Vector3, count: number, color: () -> Color3, radius: () -> number): () -> ()
	if count <= 0 then
		return function() end
	end
	local motes: { BasePart } = {}
	for i = 1, count do
		local m = localPart("HatchMote", Enum.PartType.Ball)
		m.Size = Vector3.one * (0.35 + 0.15 * (i % 3))
		m.Parent = workspace
		motes[i] = m
	end
	local t0 = os.clock()
	local conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local r = radius()
		local c = color()
		for i, m in motes do
			local a = t * (1.6 + (i % 4) * 0.25) + i * (2 * math.pi / count)
			local y = (math.sin(t * 2 + i) * 0.5 + 0.5) * r * 0.9 + 0.5
			m.CFrame = CFrame.new(ground + Vector3.new(math.cos(a) * r, y, math.sin(a) * r))
			m.Color = c
		end
	end)
	return function()
		conn:Disconnect()
		for _, m in motes do
			TweenService:Create(m, TweenInfo.new(0.25), { Transparency = 1, Size = Vector3.one * 0.05 }):Play()
			task.delay(0.3, function()
				m:Destroy()
			end)
		end
	end
end

-- An aura disc under the pet while it grows (Epic and up); returns a stop function.
local function aura(at: Vector3, color: Color3, radius: number): () -> ()
	local disc = localPart("HatchAura", Enum.PartType.Cylinder)
	disc.Color = color
	disc.Transparency = 0.55
	disc.Size = Vector3.new(0.08, radius * 2, radius * 2)
	disc.CFrame = CFrame.new(at + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
	disc.Parent = workspace
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = radius * 3
	light.Brightness = 1.5
	light.Parent = disc
	local t0 = os.clock()
	local conn = RunService.RenderStepped:Connect(function()
		disc.Transparency = 0.55 + math.sin((os.clock() - t0) * 6) * 0.12
	end)
	return function()
		conn:Disconnect()
		TweenService:Create(disc, TweenInfo.new(0.35), { Transparency = 1 }):Play()
		TweenService:Create(light, TweenInfo.new(0.35), { Brightness = 0 }):Play()
		task.delay(0.4, function()
			disc:Destroy()
		end)
	end
end

-- Camera ------------------------------------------------------------------------------------------------------

type CameraState = { restore: (instant: boolean?) -> () }

-- Frames the hatch spot for the hatching player; returns how to give the camera back.
local function frameCamera(ground: Vector3, petHeight: number): CameraState?
	local cam = workspace.CurrentCamera
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not cam or not hrp or not hrp:IsA("BasePart") or cam.CameraType ~= Enum.CameraType.Custom then
		return nil
	end
	local start = cam.CFrame
	local fov = cam.FieldOfView
	local rel = hrp.CFrame:ToObjectSpace(start) -- where the normal camera sits relative to the player
	local aim = ground + Vector3.new(0, math.clamp(petHeight * 0.45, 1.5, 9), 0)
	local flat = (start.Position - aim) * Vector3.new(1, 0, 1)
	local dir = if flat.Magnitude > 0.1 then flat.Unit else Vector3.zAxis
	local dist = math.clamp(10 + petHeight * 1.15, 13, 36)
	local goal = CFrame.lookAt(aim + dir * dist + Vector3.new(0, dist * 0.32, 0), aim)
	cam.CameraType = Enum.CameraType.Scriptable
	local info = TweenInfo.new(0.65, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	TweenService:Create(cam, info, { CFrame = goal, FieldOfView = fov - 6 }):Play()
	local done = false
	return {
		restore = function(instant: boolean?)
			if done then
				return
			end
			done = true
			local back = if hrp.Parent then hrp.CFrame * rel else start
			local function finish()
				if cam.CameraType == Enum.CameraType.Scriptable then
					cam.CameraType = Enum.CameraType.Custom
				end
				cam.FieldOfView = fov
			end
			if instant then
				cam.CFrame = back
				finish()
				return
			end
			local t = TweenService:Create(
				cam,
				TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{ CFrame = back, FieldOfView = fov }
			)
			t.Completed:Once(finish)
			t:Play()
			task.delay(0.7, finish) -- (whatever happens to the tween)
		end,
	}
end

-- Landing ------------------------------------------------------------------------------------------------------

local function landingOf(pet: Model, height: number): string
	local key = pet:GetAttribute("ModelKey")
	local override = if typeof(key) == "string" then HatchStyle.Landing[key] else nil
	if override then
		return override
	end
	local motors = Rig.motors(pet)
	if motors.Coil then
		return "Rise"
	elseif motors.WingL or motors.WingR then
		return "Unfold"
	elseif height >= HatchStyle.HEAVY_HEIGHT then
		return "Heavy"
	end
	return "Hop"
end
HatchCinematicController.landingOf = landingOf

-- Plays the landing (yields for its length).
local function land(pet: Model, kind: string, show: Show, ground: Vector3)
	local motors = Rig.motors(pet)
	local function curve(length: number, step: (k: number) -> ())
		local t0 = os.clock()
		while os.clock() - t0 < length and pet.Parent do
			step((os.clock() - t0) / length)
			task.wait()
		end
		for _, m in motors do
			Rig.reset(m)
		end
	end
	if kind == "Hop" then
		local stop = Anim.play(pet, "Hop")
		task.wait(if show.reduced then 0.6 else 1.15)
		stop()
	elseif kind == "Unfold" then
		curve(if show.reduced then 0.5 else 1.1, function(k)
			local spread = math.sin(k * math.pi) * math.rad(42)
			local rise = math.sin(k * math.pi) * 0.25
			Rig.pose(motors.WingL, CFrame.new(0, rise, 0) * CFrame.Angles(0, 0, -spread))
			Rig.pose(motors.WingR, CFrame.new(0, rise, 0) * CFrame.Angles(0, 0, spread))
			Rig.pose(motors.Body, CFrame.new(0, rise, 0))
			Rig.pose(motors.Head, CFrame.new(0, rise, 0) * CFrame.Angles(math.rad(-8) * math.sin(k * math.pi), 0, 0))
		end)
	elseif kind == "Rise" then
		curve(if show.reduced then 0.5 else 1, function(k)
			local up = math.sin(k * math.pi) * 0.6
			local sway = math.sin(k * math.pi * 2) * math.rad(6)
			Rig.pose(motors.Body, CFrame.new(0, up, 0) * CFrame.Angles(0, 0, sway))
			Rig.pose(
				motors.Head,
				CFrame.new(0, up * 1.3, 0) * CFrame.Angles(math.rad(-10) * math.sin(k * math.pi), 0, 0)
			)
		end)
	else -- Heavy: a restrained settle, a puff of dust, a little thud for the hatching player
		local thudded = false
		curve(if show.reduced then 0.35 else 0.6, function(k)
			local dip = -math.sin(k * math.pi) * 0.45
			for _, m in motors do
				Rig.pose(m, CFrame.new(0, dip, 0))
			end
			if not thudded and k > 0.45 then
				thudded = true
				Burst.play(ground + Vector3.new(0, 0.5, 0), if show.low then 6 else 12, {
					Color3.fromRGB(196, 170, 128),
					Color3.fromRGB(222, 205, 170),
				}, NumberRange.new(0.3, 0.7), 12, 0.8, true)
				if show.own and not show.reduced then
					Shake.impulse("Hatch", 0.15, 0.2)
				end
			end
		end)
	end
end

-- Anticipation --------------------------------------------------------------------------------------------------

-- The egg double's build-up: wobble speeding up, cracks and their sound, a rarity glow, a quickening pulse. Runs
-- until `show.skip` or its length; returns a stop function (the wobble and the glow).
local function anticipate(double: Model, show: Show): () -> ()
	local stopWobble = Anim.play(double, "EggWobble", { speed = 2.2 })
	local root = double.PrimaryPart
	local light = Instance.new("PointLight")
	light.Color = show.color
	light.Range = 10
	light.Brightness = 0
	light.Parent = root
	local length = if show.reduced then show.style.anticipation * 0.5 else show.style.anticipation
	local cracks = if show.low then 2 else 3
	local baseScale = double:GetScale()
	task.spawn(function()
		local t0 = os.clock()
		local made = 0
		while double.Parent and not show.skip do
			local k = math.clamp((os.clock() - t0) / length, 0, 1)
			light.Brightness = 3 * k
			if made < cracks and k >= made / cracks then
				made += 1
				VFX.play("HatchCrack", double, { progress = 0.55 + 0.45 * (made / cracks) })
			end
			if not show.reduced then -- a pulse that quickens toward the burst
				double:ScaleTo(baseScale * (1 + 0.045 * math.abs(math.sin(k * k * math.pi * 6))))
			end
			task.wait()
		end
		if double.Parent then
			double:ScaleTo(baseScale)
		end
	end)
	return function()
		stopWobble()
		light:Destroy()
	end
end

-- The show -----------------------------------------------------------------------------------------------------

local function playShow(info: { [string]: any }, entry: Pending?)
	local own = info.ownerUserId == player.UserId
	local show = if entry then entry.show else newShow(info.rarity, nil, own, true)
	local style = show.style
	local ground: Vector3 = if typeof(info.position) == "Vector3" then info.position else Vector3.zero
	local double = entry and entry.double
	local camera: CameraState? = nil
	local reveal: (() -> ())? = nil -- shows the concealed pet again
	local pet: Model? = nil
	local finalScale = 1
	local highlight: Highlight? = nil
	local stops: { () -> () } = {}
	local skipConn: RBXScriptConnection? = nil
	if entry then
		skipConn = UserInputService.InputBegan:Connect(function(input, processed)
			if processed then
				return
			end
			local t = input.UserInputType
			if
				t == Enum.UserInputType.MouseButton1
				or t == Enum.UserInputType.Touch
				or input.KeyCode == Enum.KeyCode.E
				or input.KeyCode == Enum.KeyCode.Space
				or input.KeyCode == Enum.KeyCode.ButtonA
			then
				show.skip = true
			end
		end)
	end

	local err: any = nil
	local ok = xpcall(function(): ()
		-- the pet (hidden since it arrived): its real size frames the camera
		pet = findPet(info.petUid, PET_WAIT)
		local p = pet
		local h0 = hidden[info.petUid]
		if h0 then
			hidden[info.petUid] = nil
			reveal = h0.restore
		elseif p then
			reveal = conceal(p)
		end
		if p and not show.sig then
			local sig = HatchStyle.Signatures[p:GetAttribute("ModelKey") :: any]
			if sig then
				show.sig = sig
				show.color = sig.tint or show.color
			end
		end
		local height, width = 4, 4
		if p then
			p:SetAttribute("RevealUntil", os.clock() + 30) -- PlotController leaves its pose alone until we're done
			local _, size = p:GetBoundingBox()
			height, width = size.Y, math.max(size.X, size.Z)
		end
		if entry and own and style.camera and not show.reduced then
			camera = frameCamera(ground, height)
		end

		-- 1. the rest of the anticipation, then the shell bursts (VFX HatchBurst: shell cubes, rarity flash, the
		-- rarity's hatch sound, a pillar for Legendary and up)
		if entry and double then
			local left = entry.anticipationEnds - os.clock()
			hold(show, math.max(left, if show.reduced then 0.1 else 0.35))
			entry.stopWobble()
			VFX.play("HatchBurst", double, { rarity = show.rarity })
			task.delay(0.6, function()
				double:Destroy()
			end)
		else
			local stand = Instance.new("Part")
			stand.Anchored, stand.CanCollide, stand.CanQuery, stand.CanTouch = true, false, false, false
			stand.Transparency = 1
			stand.Size = Vector3.one
			stand.CFrame = CFrame.new(ground + Vector3.new(0, 1, 0))
			stand.Parent = workspace
			VFX.play("HatchBurst", stand, { rarity = show.rarity })
			task.delay(1, function()
				stand:Destroy()
			end)
		end
		if show.sig and show.sig.motif == "Frost" then
			Burst.play(ground + Vector3.new(0, 2, 0), if show.low then 6 else 14, {
				Color3.fromRGB(205, 242, 255),
				Color3.fromRGB(150, 220, 255),
			}, NumberRange.new(0.2, 0.6), 26, 0.9, false, true)
		end
		if not p or not p.PrimaryPart or not p.Parent then
			return
		end

		-- 2. the real pet appears as a tiny silhouette
		finalScale = p:GetScale()
		local h = Instance.new("Highlight")
		h.Name = "HatchSilhouette"
		h.DepthMode = Enum.HighlightDepthMode.Occluded
		local silhouette = (show.sig and show.sig.silhouette) or style.silhouette
		h.FillColor = if silhouette == "Light" then Color3.fromRGB(255, 252, 240) else Color3.fromRGB(10, 10, 16)
		h.FillTransparency = 0
		h.OutlineColor = show.color
		h.OutlineTransparency = 0.05
		h.Adornee = p
		h.Parent = p
		highlight = h
		p:ScaleTo(finalScale * TINY)
		Fx.hideLocally(p, false) -- (its effects stay quiet until the reveal)

		-- 3. it grows to its real size
		shockwave(ground, show.color, math.max(4, width * 0.9), 0.7)
		local prism = (show.sig and show.sig.motif == "Prism") or show.rarity == "Secret"
		local grown = TINY
		local motes = if show.low then math.floor(style.orbit / 2) else style.orbit
		table.insert(
			stops,
			orbit(ground, motes, function()
				return if prism then rainbow(os.clock()) else show.color
			end, function()
				return math.max(2, width * 0.55 * math.max(grown, 0.3))
			end)
		)
		if style.aura and not show.low then
			table.insert(stops, aura(ground, show.color, math.max(3, width * 0.6)))
		end
		local growTime = if show.reduced then style.grow * 0.5 else style.grow
		local t0 = os.clock()
		while not show.skip and p.Parent do
			local k = math.clamp((os.clock() - t0) / growTime, 0, 1)
			-- ease out, with a soft 4% swell before it settles (no rubbery squash on detailed models)
			local e = 1 - (1 - k) ^ 3
			local swell = math.sin(math.clamp((k - 0.7) / 0.3, 0, 1) * math.pi) * 0.04
			grown = TINY + (1 - TINY) * e + swell
			p:ScaleTo(finalScale * grown)
			if prism then
				h.OutlineColor = rainbow(os.clock())
			end
			if k >= 1 then
				break
			end
			task.wait()
		end
		p:ScaleTo(finalScale)

		-- 4. the silhouette fades into its own materials
		local revealTime = if show.skip then 0.15 else style.reveal
		local center = p:GetPivot().Position + Vector3.new(0, height * 0.5, 0)
		Fx.flash(center, show.color, math.max(6, width * 0.9), 0.35)
		shockwave(ground, Color3.new(1, 1, 1), math.max(5, width * 1.1), 0.5)
		local sparkles = if show.low then math.floor(style.sparkles / 2) else style.sparkles
		Burst.play(center, sparkles, {
			show.color,
			show.color:Lerp(Color3.new(1, 1, 1), 0.6),
			if prism then rainbow(os.clock() + 1.5) else Color3.new(1, 1, 1),
		}, NumberRange.new(0.2, 0.5), 24, 1, false, true)
		if style.pillar and not show.low and show.rarity ~= "Legendary" then -- (Legendary got HatchBurst's pillar)
			Fx.pillar(Vector3.new(ground.X, ground.Y + 0.3, ground.Z), show.color, 40 + height * 2, 1.6)
		end
		local fade = TweenInfo.new(revealTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(h, fade, { FillTransparency = 1, OutlineTransparency = 1 }):Play()
		if show.own and entry then
			Audio.play(style.accent)
		end
		for _, stop in stops do
			stop()
		end
		table.clear(stops)
		task.wait(revealTime)
		h:Destroy()
		highlight = nil
		if reveal then
			reveal()
			reveal = nil
		end

		-- 5. the landing, while the camera comes back
		if camera then
			local c = camera
			camera = nil
			task.delay(0.3, c.restore, false)
		end
		land(p, landingOf(p, height), show, ground)
	end, function(e)
		err = e
	end)

	-- every path out: the pet's look and size, the camera, the effects
	if not ok then
		warn(`[HatchCinematic] {err}`)
	end
	if skipConn then
		skipConn:Disconnect()
	end
	for _, stop in stops do
		stop()
	end
	if highlight then
		highlight:Destroy()
	end
	if reveal then
		reveal()
	end
	local p = pet
	if p and p.Parent then
		if math.abs(p:GetScale() - finalScale) > 1e-3 then
			p:ScaleTo(finalScale)
		end
		p:SetAttribute("RevealUntil", os.clock())
	end
	if camera then
		camera.restore(not ok)
	end
	if double and double.Parent then
		task.delay(0.6, function()
			double:Destroy()
		end)
	end
end

-- Your hold on a READY egg finished: start its anticipation now and ask the server.
function HatchCinematicController.request(egg: Model)
	local uid = egg:GetAttribute("EggUid")
	if typeof(uid) ~= "string" or pending[uid] or not egg.PrimaryPart then
		return
	end
	local double = egg:Clone()
	for _, d in double:GetDescendants() do
		if d:IsA("BillboardGui") or d:IsA("ProximityPrompt") or d:IsA("Highlight") then
			d:Destroy()
		end
	end
	double.Name = "HatchDouble"
	double:SetAttribute("Kind", nil)
	double.Parent = workspace
	Fx.hideLocally(egg, true)
	local show = newShow(egg:GetAttribute("Rarity") :: any, egg:GetAttribute("ModelKey"), true, false)
	local entry: Pending = {
		egg = egg,
		double = double,
		stopWobble = anticipate(double, show),
		show = show,
		anticipationEnds = os.clock()
			+ (if show.reduced then show.style.anticipation * 0.5 else show.style.anticipation),
	}
	pending[uid] = entry
	Remotes.get("HatchEgg"):FireServer(uid)
	task.delay(REFUSAL_WAIT, function()
		if pending[uid] == entry then -- no hatch came back: the egg is still yours, put it back
			pending[uid] = nil
			show.skip = true
			entry.stopWobble()
			double:Destroy()
			if egg.Parent then
				Fx.hideLocally(egg, false)
			end
		end
	end)
end

-- True while this client is waiting on the server for the hatch of `eggUid`.
function HatchCinematicController.busy(eggUid: string): boolean
	return pending[eggUid] ~= nil
end

-- Hides freshly hatched pets the moment they arrive (until their show takes them, or briefly if none does).
local function watchPlots(plots: Instance)
	plots.ChildAdded:Connect(function(child)
		if not child:IsA("Model") then
			return
		end
		local at = child:GetAttribute("HatchedAt")
		local uid = child:GetAttribute("PetUid")
		if typeof(at) ~= "number" or typeof(uid) ~= "string" or workspace:GetServerTimeNow() - at > FRESH then
			return
		end
		local restore = conceal(child)
		hidden[uid] = { model = child, restore = restore }
		task.delay(FRESH + PET_WAIT, function()
			local h = hidden[uid]
			if h and h.model == child then -- no show came for it (too far away, too many at once)
				hidden[uid] = nil
				restore()
			end
		end)
	end)
end

function HatchCinematicController:Start()
	task.spawn(function()
		local map = workspace:WaitForChild("Map", 60)
		local zone = map and map:WaitForChild("SafeZone", 30)
		local bases = zone and zone:WaitForChild("Bases", 30)
		if not bases then
			return
		end
		local function watchBase(base: Instance)
			task.spawn(function()
				local plots = base:WaitForChild("Plots", math.huge)
				if plots then
					watchPlots(plots)
				end
			end)
		end
		for _, base in bases:GetChildren() do
			watchBase(base)
		end
		bases.ChildAdded:Connect(watchBase)
	end)
	Remotes.get("EggHatched").OnClientEvent:Connect(function(info: { [string]: any })
		if typeof(info) ~= "table" or typeof(info.petUid) ~= "string" then
			return
		end
		local mine = if typeof(info.eggUid) == "string" then pending[info.eggUid] else nil
		if mine then
			pending[info.eggUid] = nil
			task.spawn(playShow, info, mine)
			return
		end
		local cam = workspace.CurrentCamera
		local at = info.position
		if typeof(at) ~= "Vector3" or not cam or (cam.CFrame.Position - at).Magnitude > WATCH_RANGE then
			return
		end
		if watching >= MAX_WATCHED and info.ownerUserId ~= player.UserId then
			return
		end
		watching += 1
		task.spawn(function()
			playShow(info, nil)
			watching -= 1
		end)
	end)
end

return HatchCinematicController
