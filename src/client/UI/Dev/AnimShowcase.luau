--!strict
-- Partner A. DEV ONLY (Studio): the character-animation showcase. Press ";" (or set the LocalPlayer attribute
-- "AnimShowcase") to open a local stage far above the map, built from copies of real rigs, with a replayable demo of
-- every character animation, using the same modules the game uses:
--   KICK (gameplay camera)  hold -> brace -> kick on a copy of your avatar, egg toss, impact VFX, recovery
--   PERFECT KICK            the same with the cinematic camera (Anim/KickCamera) and the perfect impact
--   SACK: ONE KICK / x6     the training stance, chained kicks (push / snap / roundhouse super), the bag reacting
--   WALK <-> STANCE         walking away and back: the stance blends out and in, no snaps
--   SHOPKEEPER              a copy of the Boxing Sack Coach leaning on a counter, following the camera, GREET
--   R6                      an R6 dummy doing the kick and the stance (no IK on R6: joints only)
-- Nothing here touches the server, data or the real map; closing destroys the stage and gives the camera back.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Anim = Shared:WaitForChild("Anim")
local EggKick = require(Anim:WaitForChild("EggKick"))
local KickCamera = require(Anim:WaitForChild("KickCamera"))
local Sack = require(Anim:WaitForChild("Sack"))
local Merchant = require(Anim:WaitForChild("Merchant"))
local Mixer = require(Anim:WaitForChild("Mixer"))
local MysteryEgg = require(Shared:WaitForChild("Builders"):WaitForChild("Models"):WaitForChild("MysteryEgg"))
local Sacks = require(Shared:WaitForChild("Builders"):WaitForChild("Models"):WaitForChild("Sacks"))
local SackGeometry = require(Shared:WaitForChild("Builders"):WaitForChild("SackGeometry"))
local VFX = require(Shared:WaitForChild("VFX")) :: any

local AnimShowcase = {}

local ORIGIN = CFrame.new(0, 900, 0)
local player = Players.LocalPlayer

type Actor = { model: Model, idle: AnimationTrack?, walk: AnimationTrack?, busy: boolean, n: number }
type Stage = {
	folder: Folder,
	gui: ScreenGui,
	conns: { RBXScriptConnection },
	kicker: Actor?,
	r6: Actor?,
	trainer: Actor?,
	bag: Model?,
	bagHang: CFrame?,
	merchant: Merchant.Live?,
	status: TextLabel,
	view: string,
}
local stage: Stage? = nil

-- Rigs ------------------------------------------------------------------------------------------------------------

local function animIds(model: Model): { [string]: string }
	local out = {}
	local animate = model:FindFirstChild("Animate")
	for _, kind in { "idle", "walk" } do
		local folder = animate and animate:FindFirstChild(kind)
		local first = folder and folder:FindFirstChildOfClass("Animation")
		if first then
			out[kind] = first.AnimationId
		end
	end
	return out
end

-- A still copy of `source` on the stage at `at` (no scripts, no tools, rooted), playing its own idle.
local function actor(source: Model, at: CFrame, folder: Folder): Actor?
	local ids = animIds(source)
	local was = source.Archivable
	source.Archivable = true
	local model = source:Clone()
	source.Archivable = was
	if not model then
		return nil
	end
	for _, d in model:GetDescendants() do
		if d:IsA("LuaSourceContainer") or d:IsA("Tool") or d.Name == "MysteryEgg" or d:IsA("BillboardGui") then
			d:Destroy()
		end
	end
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		model:Destroy()
		return nil
	end
	root.Anchored = true
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	model:PivotTo(at)
	model.Parent = folder
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	local function load(kind: string, priority: Enum.AnimationPriority): AnimationTrack?
		local id = ids[kind]
		if not id then
			return nil
		end
		local a = Instance.new("Animation")
		a.AnimationId = id
		local ok, track = pcall(animator.LoadAnimation, animator, a)
		if ok and track then
			track.Priority = priority
			track.Looped = true
			return track
		end
		return nil
	end
	local idle = load("idle", Enum.AnimationPriority.Idle)
	if idle then
		idle:Play(0.2)
	else
		Mixer.rest(model) -- nothing animates it: layers start from the rest pose
	end
	return { model = model, idle = idle, walk = load("walk", Enum.AnimationPriority.Movement), busy = false, n = 0 }
end

local function floorAt(folder: Folder, cf: CFrame, size: Vector3, color: Color3)
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Studs
	p.Parent = folder
	return p
end

-- How far the root sits above the ground for this rig (R15 and R6 alike: its lowest part, not HipHeight).
local function groundY(model: Model): number
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
	local low = math.huge
	for _, d in model:GetChildren() do
		if d:IsA("BasePart") and d ~= root then
			local cf, half = d.CFrame, d.Size / 2
			for _, x in { -1, 1 } do
				for _, y in { -1, 1 } do
					for _, z in { -1, 1 } do
						low = math.min(low, (cf * Vector3.new(x * half.X, y * half.Y, z * half.Z)).Y)
					end
				end
			end
		end
	end
	return if low < math.huge then root.Position.Y - low else 3
end

-- Camera ------------------------------------------------------------------------------------------------------------

local function look(eye: Vector3, at: Vector3, fov: number?)
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	TweenService:Create(cam, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
		CFrame = CFrame.lookAt(eye, at),
		FieldOfView = fov or 50,
	}):Play()
end

local function lookAtActor(a: Actor, eye: Vector3, fov: number?)
	local root = a.model:GetPivot()
	look(root * eye, root.Position, fov)
end

-- Demos -------------------------------------------------------------------------------------------------------------

local function freshEgg(a: Actor): Model?
	local egg = MysteryEgg.build()
	for _, d in egg:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide, d.CanQuery, d.CanTouch, d.Massless = false, false, false, true
		end
	end
	egg.Name = "MysteryEgg"
	if not EggKick.attach(a.model, egg) then
		egg:Destroy()
		return nil
	end
	egg.Parent = a.model
	return egg
end

-- hold -> brace -> kick (contact a server-like 0.95 s after the "press"), toss, impact, the egg flying off, re-arm
local function kickDemo(a: Actor, cinematic: boolean)
	if a.busy then
		return
	end
	a.busy = true
	task.spawn(function()
		local model = a.model
		local egg = model:FindFirstChild("MysteryEgg") :: Model? or freshEgg(a)
		EggKick.hold(model)
		task.wait(0.9)
		EggKick.brace(model, true)
		task.wait(1.0)
		EggKick.brace(model, false)
		local contactAt = workspace:GetServerTimeNow() + 0.95
		local p = EggKick.play(model, contactAt)
		local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
		local contact = root.CFrame * (p.contact or Vector3.new(0.5, -1.6, -2))
		local flying: Model? = nil
		local stopCam = if cinematic
			then KickCamera.play(model, contactAt, p.handle.time, function()
				return if flying then flying:GetPivot().Position + Vector3.new(0, 1.7, 0) else nil
			end, 70)
			else nil
		local toss: ((number) -> ())? = nil
		local conn: RBXScriptConnection
		conn = RunService.Heartbeat:Connect(function()
			local now = workspace:GetServerTimeNow()
			if egg and egg.Parent and now >= p.releaseAt and now < contactAt then
				toss = toss or EggKick.toss(egg, root, contact, contactAt, now, 2.2);
				(toss :: (number) -> ())(now)
			elseif now >= contactAt then
				conn:Disconnect()
				local band = if cinematic then "perfect" else "good"
				local anchor = Instance.new("Part")
				anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.Transparency = true, false, false, 1
				anchor.CFrame = CFrame.new(contact)
				anchor.Parent = model.Parent
				task.delay(2, anchor.Destroy, anchor)
				VFX.play(
					"KickImpact",
					anchor,
					{ power = if cinematic then 24 else 12, cutscene = true, own = true, band = band }
				)
				if egg then -- the launch: forward and up, turning over (the game's flying egg does this for real)
					flying = egg
					local from = egg:GetPivot()
					local fwd = root.CFrame.LookVector
					local t0 = os.clock()
					local fly: RBXScriptConnection
					fly = RunService.Heartbeat:Connect(function()
						local t = os.clock() - t0
						if t > 1.4 or not egg.Parent then
							fly:Disconnect()
							egg:Destroy()
							flying = nil
							return
						end
						local pos = from.Position + fwd * 38 * t + Vector3.new(0, 26 * t - 14 * t * t, 0)
						egg:PivotTo(CFrame.new(pos) * from.Rotation * CFrame.Angles(-t * 9, 0, 0))
					end)
				end
			end
		end)
		task.wait(EggKick.LENGTH + 0.6)
		if stopCam then
			stopCam()
			lookAtActor(a, Vector3.new(7, 2.5, 9), 50)
		end
		freshEgg(a) -- re-armed: the hold comes back (blended in) for the next run
		EggKick.hold(model)
		a.busy = false
	end)
end

local function swingBag(s: Stage, power: number)
	local bag, hang = s.bag, s.bagHang
	if not bag or not hang then
		return
	end
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		if t > 1.6 or not bag.Parent then
			conn:Disconnect()
			if bag.Parent then
				bag:PivotTo(hang)
			end
			return
		end
		local angle = -0.32 * power * math.exp(-2.6 * t) * math.sin(7 * t) -- swings away from the kicker
		bag:PivotTo(hang * CFrame.Angles(angle, 0, 0))
	end)
end

local function sackKicks(s: Stage, a: Actor, count: number)
	if a.busy then
		return
	end
	a.busy = true
	task.spawn(function()
		Sack.stance(a.model, true)
		task.wait(0.4)
		for i = 1, count do
			a.n += 1
			local super = count > 1 and i == count
			local h = Sack.kick(a.model, a.n, super)
			h.on("Contact", function()
				swingBag(s, if super then 1.5 else 1)
				local bag = s.bag
				if bag then
					local hang = s.bagHang :: CFrame
					VFX.play("SackHit", bag, {
						tier = 1,
						at = (hang * CFrame.new(0, 2.4 - Sacks.HANG, -Sacks.RADIUS)).Position,
						dir = -hang.LookVector,
						floor = hang.Position - Vector3.new(0, Sacks.HANG, 0),
						own = false,
						super = super,
					})
				end
			end)
			task.wait(Sack.LENGTH) -- the game's fixed interval: the next kick starts on the stance
		end
		a.busy = false
	end)
end

-- walk away along the stage and back: the stance blends out into the walk and back in when it stops
local function walkDemo(a: Actor)
	if a.busy then
		return
	end
	a.busy = true
	task.spawn(function()
		local start = a.model:GetPivot()
		Sack.stance(a.model, true)
		task.wait(1)
		for _, leg in { { 1, 0 }, { -1, math.pi } } do
			local dir, yaw = leg[1], leg[2]
			Sack.stance(a.model, false)
			if a.walk then
				a.walk:Play(0.25, 1, 1)
			end
			local from = a.model:GetPivot().Position
			local face = CFrame.Angles(0, math.rad(-90) + yaw, 0)
			local t0 = os.clock()
			while os.clock() - t0 < 1.2 do
				local k = os.clock() - t0
				a.model:PivotTo(CFrame.new(from + start.RightVector * dir * 9 * k) * start.Rotation * face)
				RunService.RenderStepped:Wait()
			end
			if a.walk then
				a.walk:Stop(0.25)
			end
			-- turn back to face the bag (eased, a quarter turn in 0.3 s), then the stance
			local pos = a.model:GetPivot().Position
			local turnFrom = a.model:GetPivot().Rotation
			local t1 = os.clock()
			while os.clock() - t1 < 0.3 do
				local k = (os.clock() - t1) / 0.3
				a.model:PivotTo(CFrame.new(pos) * turnFrom:Lerp(start.Rotation, k * k * (3 - 2 * k)))
				RunService.RenderStepped:Wait()
			end
			a.model:PivotTo(CFrame.new(pos) * start.Rotation)
			Sack.stance(a.model, true)
			task.wait(1.1)
		end
		a.model:PivotTo(start)
		a.busy = false
	end)
end

-- Stage -------------------------------------------------------------------------------------------------------------

local actions: { [string]: () -> () } = {}

local function button(parent: Frame, text: string, order: number, fn: () -> ())
	actions[text] = fn
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, 34)
	b.LayoutOrder = order
	b.BackgroundColor3 = Color3.fromRGB(40, 46, 66)
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.FredokaOne
	b.TextSize = 17
	b.Text = text
	b.AutoButtonColor = true
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = b
	b.Activated:Connect(fn)
	b.Parent = parent
end

local function close()
	local s = stage
	if not s then
		return
	end
	stage = nil
	for _, c in s.conns do
		c:Disconnect()
	end
	s.folder:Destroy()
	s.gui:Destroy()
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Custom
	cam.FieldOfView = 70
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		cam.CameraSubject = humanoid
	end
end

local function open()
	local character = player.Character
	if stage or not character then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "AnimShowcase"
	folder.Parent = workspace
	floorAt(folder, ORIGIN * CFrame.new(0, -0.5, 0), Vector3.new(110, 1, 60), Color3.fromRGB(226, 230, 238))

	local s: Stage = {
		folder = folder,
		gui = Instance.new("ScreenGui"),
		conns = {},
		kicker = nil,
		r6 = nil,
		trainer = nil,
		bag = nil,
		bagHang = nil,
		merchant = nil,
		status = Instance.new("TextLabel"),
		view = "overview",
	}
	stage = s

	local h = groundY(character)
	s.kicker = actor(character, ORIGIN * CFrame.new(-34, h, 8) * CFrame.Angles(0, math.pi, 0), folder)
	s.trainer = actor(character, ORIGIN * CFrame.new(2, h, 10), folder)
	-- the trainer's bag in front of it, hanging at the gear's distance (Sacks.KICK_DIST)
	if s.trainer then
		local root = s.trainer.model:GetPivot()
		local hang = CFrame.lookAt(
			root.Position + root.LookVector * Sacks.KICK_DIST + Vector3.new(0, Sacks.HANG - h, 0),
			root.Position + Vector3.new(0, Sacks.HANG - h, 0)
		)
		local ok, bag = pcall(SackGeometry.build, 1)
		if ok and bag then
			for _, d in bag:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored = true
					d.CanCollide = false
				elseif d:IsA("WeldConstraint") or d:IsA("Motor6D") then
					d:Destroy()
				end
			end
			bag:PivotTo(hang)
			bag.Parent = folder
			s.bag, s.bagHang = bag, hang
		end
	end
	-- an R6 dummy (the game's code paths for R6 rigs: joints only, no IK)
	local okR6, r6 = pcall(function()
		return Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R6)
	end)
	if okR6 and r6 then
		r6.Parent = folder
		s.r6 = actor(r6, ORIGIN * CFrame.new(-22, groundY(r6), 8) * CFrame.Angles(0, math.pi, 0), folder)
		r6:Destroy()
	end
	-- the shopkeeper: a copy of the real Coach (or your avatar) behind a counter the size of the shop's
	local coach = workspace:FindFirstChild("Map")
		and (workspace :: any).Map:FindFirstChild("BoxingSackShop", true)
		and (workspace :: any).Map:FindFirstChild("Boxing Sack Merchant", true)
	local source = if coach and coach:IsA("Model") then coach else character
	local mh = groundY(source)
	local merchantAt = ORIGIN * CFrame.new(30, mh, 14)
	local shop = actor(source, merchantAt, folder)
	floorAt(
		folder,
		merchantAt * CFrame.new(0, -mh + 0.5 + 1.03, -3.3),
		Vector3.new(14, 2.06, 2.6),
		Color3.fromRGB(150, 95, 60)
	)
	floorAt(
		folder,
		merchantAt * CFrame.new(0, -mh + 2.06 + 0.3, -3.3),
		Vector3.new(14.6, 0.4, 3.2),
		Color3.fromRGB(245, 245, 250)
	)
	if shop then
		if shop.idle then
			shop.idle:Stop(0) -- merchants have no running Animate in the game either
		end
		Mixer.rest(shop.model)
		s.merchant = Merchant.attach(shop.model)
	end

	-- the panel
	local gui = s.gui
	gui.Name = "AnimShowcaseGui"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 50
	gui.Parent = player:WaitForChild("PlayerGui")
	local panel = Instance.new("Frame")
	panel.Size = UDim2.fromOffset(250, 440)
	panel.Position = UDim2.fromOffset(16, 90)
	panel.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
	panel.BackgroundTransparency = 0.15
	panel.Parent = gui
	local pad = Instance.new("UIPadding")
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 10), UDim.new(0, 10)
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 10), UDim.new(0, 10)
	pad.Parent = panel
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 6)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = panel
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 24)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 220, 90)
	title.Font = Enum.Font.FredokaOne
	title.TextSize = 20
	title.Text = "ANIMATION SHOWCASE"
	title.LayoutOrder = 0
	title.Parent = panel

	button(panel, "Overview", 1, function()
		look((ORIGIN * CFrame.new(0, 14, -46)).Position, (ORIGIN * CFrame.new(0, 2, 8)).Position, 60)
	end)
	button(panel, "Kick (gameplay camera)", 2, function()
		local a = s.kicker
		if a then
			lookAtActor(a, Vector3.new(4, 6, 11), 55)
			kickDemo(a, false)
		end
	end)
	button(panel, "Perfect kick (cinematic)", 3, function()
		local a = s.kicker
		if a then
			kickDemo(a, true)
		end
	end)
	button(panel, "Sack: one kick", 4, function()
		local a = s.trainer
		if a then
			lookAtActor(a, Vector3.new(-9, 1.5, -2.5), 50)
			sackKicks(s, a, 1)
		end
	end)
	button(panel, "Sack: training x6", 5, function()
		local a = s.trainer
		if a then
			lookAtActor(a, Vector3.new(-9, 1.5, -2.5), 50)
			sackKicks(s, a, 6)
		end
	end)
	button(panel, "Walk <-> stance", 6, function()
		local a = s.trainer
		if a then
			lookAtActor(a, Vector3.new(0, 3, 16), 58)
			walkDemo(a)
		end
	end)
	button(panel, "Shopkeeper: greet", 7, function()
		look((merchantAt * CFrame.new(5.5, 1.5, -11)).Position, (merchantAt * CFrame.new(0, 0, -1.5)).Position, 45)
		local live = s.merchant
		if live then
			task.delay(0.8, live.greet)
		end
	end)
	button(panel, "R6: kick + stance", 8, function()
		local a = s.r6
		if a then
			lookAtActor(a, Vector3.new(6, 2.5, 9), 55)
			kickDemo(a, false)
			task.delay(4.6, function()
				if stage == s then
					sackKicks(s, a, 3)
				end
			end)
		end
	end)
	button(panel, "Close", 9, close)
	local status = s.status
	status.Size = UDim2.new(1, 0, 0, 40)
	status.BackgroundTransparency = 1
	status.TextColor3 = Color3.fromRGB(190, 200, 220)
	status.Font = Enum.Font.Gotham
	status.TextSize = 13
	status.TextWrapped = true
	status.LayoutOrder = 10
	status.Parent = panel

	-- the kicker holds its egg; the shopkeeper lives; the status shows the Mixer's live layers (leak check)
	if s.kicker then
		freshEgg(s.kicker)
		EggKick.hold(s.kicker.model)
	end
	if s.r6 then
		freshEgg(s.r6)
		EggKick.hold(s.r6.model)
	end
	table.insert(
		s.conns,
		RunService.RenderStepped:Connect(function(dt)
			local cam = workspace.CurrentCamera
			local live = s.merchant
			if live then
				live.update(dt, cam.CFrame.Position, cam)
			end
			local chars, layers = Mixer.stats()
			status.Text = string.format("Mixer: %d rigs, %d layers", chars, layers)
		end)
	)
	look((ORIGIN * CFrame.new(0, 14, -46)).Position, (ORIGIN * CFrame.new(0, 2, 8)).Position, 60)
end

function AnimShowcase.start()
	if not RunService:IsStudio() then
		return
	end
	local function toggle()
		if stage then
			close()
		else
			open()
		end
	end
	player:GetAttributeChangedSignal("AnimShowcase"):Connect(toggle)
	-- (recording: the attribute "AnimShowcaseDemo" = a button's text runs that demo)
	player:GetAttributeChangedSignal("AnimShowcaseDemo"):Connect(function()
		local name = player:GetAttribute("AnimShowcaseDemo")
		local fn = if typeof(name) == "string" and stage then actions[name] else nil
		if fn then
			fn()
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.Semicolon then
			toggle()
		end
	end)
end

return AnimShowcase
