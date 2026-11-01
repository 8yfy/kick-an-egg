--!strict
-- Plays the Model Lab's server-set state on this admin's client with the game's own modules: Anim.play (one
-- animator per model, stopped before the next starts and when the model leaves), PetFx idle recipes, VFX.attach
-- weather overlays, VFX.play one-shots, signature bursts, the hatch sequence, the demo spot and the test pen's
-- roaming (the same PathFrom/PathTo/PathStart/PathEnd protocol PlotController uses for real pens).
-- Only names in this file's allowlists are ever played, whatever an attribute says.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Anim = require(Shared:WaitForChild("Anim")) :: any
local VFX = require(Shared:WaitForChild("VFX")) :: any
local PetFx = require(Shared.VFX:WaitForChild("PetFx")) :: any
local Pets = require(Shared.Config:WaitForChild("Pets")) :: any
local Models = require(Shared.Builders:WaitForChild("Models")) :: any

local LabView = {}

local ANIMS = { Idle = true, Waddle = true, Hop = true, Sleep = true, EggWobble = true }
local OVERLAYS =
	{ SunRays = true, RainDrops = true, Frost = true, Lightning = true, Stardust = true, RainbowShift = true }
local ONE_SHOTS = {
	PetReveal = true,
	MoneyPop = true,
	TrainHit = true,
	Landing = true,
	KickImpact = true,
	HatchCrack = true,
	HatchBurst = true,
	EggSpin = true,
	EggSecured = true,
	ZoneEnter = true,
}
local MAX_BURST = 40 -- particles per emitter for a signature special
local ANIM_RANGE = 160

type View = {
	model: Model,
	kind: string,
	stopAnim: (() -> ())?,
	animName: string?,
	fxStop: (() -> ())?,
	conns: { RBXScriptConnection },
	lastShot: number,
	pen: boolean,
	yOffset: number,
	moving: boolean?,
}

local views: { [Model]: View } = {}

local function now(): number
	return workspace:GetServerTimeNow()
end

local function kindOf(model: Model): string
	local k = model:GetAttribute("LabKind")
	return if typeof(k) == "string" then k else "asset"
end

local function stopAnim(v: View)
	if v.stopAnim then
		local stop = v.stopAnim
		v.stopAnim = nil
		v.animName = nil
		pcall(stop)
	end
end

local function playAnim(v: View, name: string, speed: number)
	stopAnim(v)
	if not ANIMS[name] or v.model:GetAttribute("Rigged") ~= true then
		return
	end
	v.stopAnim = Anim.play(v.model, name, { speed = speed })
	v.animName = name
end

local function idleName(v: View): string?
	return if v.kind == "egg" then "EggWobble" elseif v.kind == "sack" then nil else "Idle"
end

local function applyAnim(v: View)
	local m = v.model
	local name = m:GetAttribute("LabAnim")
	local speed = tonumber(m:GetAttribute("LabAnimSpeed")) or 1
	if typeof(name) ~= "string" or name == "" then
		stopAnim(v)
		return
	end
	playAnim(v, name, speed)
	local untilAt = tonumber(m:GetAttribute("LabAnimUntil")) or 0
	if untilAt > 0 then
		local rev = m:GetAttribute("LabAnimRev")
		task.delay(math.max(0, untilAt - now()), function()
			if views[m] == v and m:GetAttribute("LabAnimRev") == rev then
				local idle = idleName(v)
				if idle then
					playAnim(v, idle, 1) -- a single play returns to idle
				else
					stopAnim(v)
				end
			end
		end)
	end
end

local function stopFx(v: View)
	if v.fxStop then
		local stop = v.fxStop
		v.fxStop = nil
		pcall(stop)
	end
end

local function attachIdle(v: View, quality: number): (() -> ())?
	local key = v.model:GetAttribute("ModelKey")
	if typeof(key) ~= "string" then
		return nil
	end
	local handle = PetFx.attach(v.model, if v.kind == "egg" then "egg" else "pet", key, { Quality = quality })
	return if handle then handle.Destroy else nil
end

local function applyFx(v: View)
	stopFx(v)
	local m = v.model
	local fx = m:GetAttribute("LabFx")
	if typeof(fx) ~= "string" or fx == "" then
		return
	end
	local quality = math.clamp(tonumber(m:GetAttribute("LabFxQuality")) or 0.65, 0.2, 1)
	if fx == "Idle" then
		v.fxStop = attachIdle(v, quality)
	elseif OVERLAYS[fx] then
		v.fxStop = VFX.attach(fx, m)
	end
	local untilAt = tonumber(m:GetAttribute("LabFxUntil")) or 0
	local rev = m:GetAttribute("LabFxRev")
	if untilAt > 0 then
		task.delay(math.max(0, untilAt - now()), function()
			if views[m] == v and m:GetAttribute("LabFxRev") == rev then
				stopFx(v)
			end
		end)
	end
end

local function shotParams(v: View, name: string): { [string]: any }
	local m = v.model
	local rarity = m:GetAttribute("Rarity") or "Common"
	local zone = tonumber(m:GetAttribute("LabZone")) or 1
	local params: { [string]: any } = {
		rarity = rarity,
		zone = math.clamp(zone, 1, 20),
		name = m:GetAttribute("PetName"),
		amount = 1250,
		gain = 100,
		progress = 0.6,
		power = 25,
	}
	if name == "EggSpin" then
		local key = m:GetAttribute("ModelKey")
		params.keys = Models.eggKeysForZone(Pets, params.zone)
		params.finalKey = key
		params.seconds = 0.45
	end
	return params
end

local function oneShot(v: View)
	local m = v.model
	local name = m:GetAttribute("LabOneShot")
	if typeof(name) ~= "string" or not ONE_SHOTS[name] then
		return
	end
	if os.clock() - v.lastShot < 0.3 then
		return -- client-side throttle on top of the server cooldown
	end
	v.lastShot = os.clock()
	VFX.play(name, m, shotParams(v, name))
end

-- Signature special: fire the recipe's timed bursts (PetFx emitters with Rate 0) once, capped.
local function special(v: View)
	local m = v.model
	local temp: (() -> ())? = nil
	local folder = m:FindFirstChild("PetFx", true)
	if not folder then
		temp = attachIdle(v, math.clamp(tonumber(m:GetAttribute("LabFxQuality")) or 0.65, 0.2, 1))
		folder = m:FindFirstChild("PetFx", true)
	end
	local fired = 0
	if folder then
		for _, d in folder:GetDescendants() do
			if d:IsA("ParticleEmitter") and d.Rate == 0 then
				d.Enabled = true
				d:Emit(math.min(MAX_BURST, 24))
				fired += 1
			end
		end
	end
	if fired == 0 then
		warn(`[Admin] {m:GetAttribute("LabName")}: no signature bursts in its recipe`)
	end
	if temp then
		task.delay(4, temp)
	end
end

local function hatch(v: View)
	local m = v.model
	local at = tonumber(m:GetAttribute("LabHatchAt"))
	if not at then
		return
	end
	local start = now()
	local total = math.max(0.5, at - start)
	stopAnim(v)
	task.spawn(function()
		local step = -1
		local wobble = Anim.play(m, "EggWobble", { speed = 2.2 })
		while views[m] == v and now() < at do
			local progress = math.clamp((now() - start) / total, 0, 1)
			local s = math.floor(progress * 10)
			if s ~= step then
				step = s
				VFX.play("HatchCrack", m, { progress = progress })
			end
			task.wait(0.05)
		end
		pcall(wobble)
		if views[m] == v then
			VFX.play("HatchBurst", m, { rarity = m:GetAttribute("Rarity") or "Common" })
		end
	end)
end

local function untrack(m: Model)
	local v = views[m]
	if not v then
		return
	end
	views[m] = nil
	stopAnim(v)
	stopFx(v)
	for _, c in v.conns do
		c:Disconnect()
	end
end

local function track(m: Instance, pen: boolean)
	if not m:IsA("Model") or views[m] then
		return
	end
	local model = m :: Model
	local v: View = {
		model = model,
		kind = kindOf(model),
		conns = {},
		lastShot = 0,
		pen = pen,
		yOffset = 0,
	}
	views[model] = v
	local function on(attr: string, fn: () -> ())
		table.insert(v.conns, model:GetAttributeChangedSignal(attr):Connect(fn))
	end
	on("LabAnimRev", function()
		applyAnim(v)
	end)
	on("LabTransformRev", function()
		if v.animName then
			applyAnim(v) -- re-pose from the new scale's rest pose
		end
	end)
	on("LabFxRev", function()
		applyFx(v)
	end)
	on("LabFxResetRev", function()
		stopFx(v)
		stopAnim(v)
	end)
	on("LabOneShotRev", function()
		oneShot(v)
	end)
	on("LabSpecialRev", function()
		special(v)
	end)
	on("LabHatchAt", function()
		hatch(v)
	end)
	table.insert(
		v.conns,
		model.AncestryChanged:Connect(function()
			if not model:IsDescendantOf(workspace) then
				untrack(model)
			end
		end)
	)
	applyAnim(v)
	applyFx(v)
	local reveal = tonumber(model:GetAttribute("LabReveal"))
	if reveal and now() - reveal < 3 then
		VFX.play(
			"PetReveal",
			model,
			{ rarity = model:GetAttribute("Rarity") or "Common", name = model:GetAttribute("PetName") }
		)
	end
	if pen then
		local from = model:GetAttribute("PathFrom")
		v.yOffset = if typeof(from) == "Vector3" then model:GetPivot().Position.Y - from.Y else 0
		v.fxStop = attachIdle(v, 0.65)
		playAnim(v, "Idle", 1)
	end
end

-- Test pen pets walk their server paths (anchored root, one PivotTo per frame, only near the camera).
local function movePen()
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local t = now()
	for model, v in views do
		if not v.pen then
			continue
		end
		local from, to = model:GetAttribute("PathFrom"), model:GetAttribute("PathTo")
		local t0, t1 = model:GetAttribute("PathStart"), model:GetAttribute("PathEnd")
		if typeof(from) ~= "Vector3" or typeof(to) ~= "Vector3" or typeof(t0) ~= "number" or typeof(t1) ~= "number" then
			continue
		end
		local a = if t1 > t0 then math.clamp((t - t0) / (t1 - t0), 0, 1) else 1
		local pos = from:Lerp(to, a)
		if (pos - cam.CFrame.Position).Magnitude > ANIM_RANGE then
			continue
		end
		local moving = a < 1 and (to - from).Magnitude > 0.05
		local dir = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
		local look = if dir.Magnitude > 0.05 then dir.Unit else model:GetPivot().LookVector
		local at = pos + Vector3.new(0, v.yOffset, 0)
		model:PivotTo(CFrame.lookAt(at, at + Vector3.new(look.X, 0, look.Z)))
		if moving ~= v.moving then
			v.moving = moving
			playAnim(v, if moving then "Waddle" else "Idle", 1)
		end
	end
end

local function watchDemo(platform: Instance)
	local anchor = platform:WaitForChild("DemoAnchor", 10)
	if not anchor then
		return
	end
	anchor:GetAttributeChangedSignal("LabDemoRev"):Connect(function()
		local name = anchor:GetAttribute("LabDemo")
		if typeof(name) == "string" and ONE_SHOTS[name] then
			VFX.play(name, anchor, { rarity = "Legendary", zone = 6, amount = 1250, power = 25, name = "Demo" })
		end
	end)
end

local function watchLab(lab: Instance)
	for _, name in { "Models", "Pen" } do
		task.spawn(function()
			local folder = lab:WaitForChild(name, 10)
			if not folder then
				return
			end
			for _, c in folder:GetChildren() do
				track(c, name == "Pen")
			end
			folder.ChildAdded:Connect(function(c)
				task.defer(track, c, name == "Pen") -- attributes and parts arrive with the model
			end)
		end)
	end
	task.spawn(function()
		local platform = lab:WaitForChild("Platform", 10)
		if platform then
			watchDemo(platform)
		end
	end)
end

function LabView.start()
	local lab = workspace:FindFirstChild("AdminLab")
	if lab then
		watchLab(lab)
	end
	workspace.ChildAdded:Connect(function(c)
		if c.Name == "AdminLab" then
			watchLab(c)
		end
	end)
	RunService.RenderStepped:Connect(movePen)
end

return LabView
