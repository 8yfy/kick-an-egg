--!strict
-- Egg / pet idle effects built from DATA (VFX/PetFx/Recipes/*): every egg and every pet has its own effect
-- identity, scaled by rarity (docs/EggPetPlan.md). Client only; returns nil for keys without a recipe yet.
--
--   local handle = PetFx.attach(model, "egg" | "pet", modelKey, { Quality = 1 })
--   handle.SetEnabled(false); handle.Destroy()      -- also cleaned up when the model leaves the workspace
--
-- A recipe is { layers = { Layer, ... } }. Lengths are studs at model scale 1 (multiplied by the model's scale,
-- so Size mutations stay right); y = height above the feet; x/z in the model's frame (-Z = its front).
--   emit   ParticleEmitter: sprite, rate, life {a,b}, size n|{a,b}|{a,b,c}, speed n|{a,b}, color C3|{C3,...},
--          alpha (transparency) n|{a,b}|{a,b,c}, glow (LightEmission 0..1), y | at {x,y,z}, area {x,y,z} +
--          shape (Box|Sphere|Cylinder|Disc) + surface, spread, accel {x,y,z}, drag, spin {a,b} (deg/s),
--          rot {a,b}, face (camera|up|vel|flat), locked, zoff, dir (emission NormalId in the model frame, e.g.
--          "Front"); every {a,b} + count makes it a timed burst ("special") of `count` particles every a..b s,
--          and bursts sharing a `sync` name fire together
--   orbit  `count` items circling the model: radius, y, speed (rad/s, sign = direction), bob, tilt (deg),
--          phase; item = sprite + size (camera-facing) or part {shape, size, color, material, alpha, spinAxis};
--          trail {color, life, width, alpha, glow, sprite?} on each item
--   disc   flat sprite facing up (halo, sigil, ground ring): sprite, y, size, color, alpha, spin (deg/s),
--          tilt (deg about X), pulse {min, max, period}, glow (unlit brightness)
--   board  camera-facing sprite (glow, rays): sprite, y, size, color, alpha, spin, pulse, glow, back (studs
--          behind the model, so the body stays in front)
--   light  PointLight: color, y, range, brightness, pulse {min, max, period}
--   beam   vertical Beam: sprite, y0, y1, width, color, alpha, glow, scroll
local RunService = game:GetService("RunService")

local Sprites = require(script.Sprites)

export type Layer = { [string]: any }
export type Recipe = { layers: { Layer } }
export type Handle = { SetEnabled: (on: boolean) -> (), Destroy: () -> () }

local PetFx = {}
PetFx.Sprites = Sprites

local CULL = 160 -- studs: beyond this the effect sleeps (emitters off, nothing updated)

local recipes: { [string]: { egg: Recipe?, pet: Recipe? } }? = nil
local function allRecipes(): { [string]: { egg: Recipe?, pet: Recipe? } }
	local r = recipes
	if r then
		return r
	end
	local all = {}
	local folder = script:FindFirstChild("Recipes")
	for _, m in if folder then folder:GetChildren() else {} do
		if m:IsA("ModuleScript") then
			for key, entry in require(m) :: any do
				assert(all[key] == nil, `[PetFx] recipe {key} defined twice`)
				all[key] = entry
			end
		end
	end
	recipes = all
	return all
end

function PetFx.recipe(kind: string, key: string): Recipe?
	local entry = allRecipes()[key]
	return if entry then (entry :: any)[kind] else nil
end

function PetFx.keys(): { string }
	local out = {}
	for key in allRecipes() do
		table.insert(out, key)
	end
	table.sort(out)
	return out
end

local function num(v: any, s: number): NumberRange
	if type(v) == "table" then
		return NumberRange.new(v[1] * s, (v[2] or v[1]) * s)
	end
	return NumberRange.new((v or 0) * s)
end

local function seq(v: any, s: number): NumberSequence
	if type(v) ~= "table" then
		return NumberSequence.new((v or 0) * s)
	end
	local keys = {}
	for i, x in v do
		table.insert(keys, NumberSequenceKeypoint.new((i - 1) / math.max(1, #v - 1), x * s))
	end
	if #keys == 1 then
		return NumberSequence.new(v[1] * s)
	end
	return NumberSequence.new(keys)
end

local function colors(v: any): ColorSequence
	if typeof(v) == "Color3" then
		return ColorSequence.new(v)
	elseif type(v) == "table" and #v > 1 then
		local keys = {}
		for i, c in v do
			table.insert(keys, ColorSequenceKeypoint.new((i - 1) / (#v - 1), c))
		end
		return ColorSequence.new(keys)
	elseif type(v) == "table" and #v == 1 then
		return ColorSequence.new(v[1])
	end
	return ColorSequence.new(Color3.new(1, 1, 1))
end

local function vec(v: any, s: number): Vector3
	return if type(v) == "table" then Vector3.new(v[1] * s, v[2] * s, v[3] * s) else Vector3.zero
end

local function pulse(p: any, t: number): number
	if type(p) ~= "table" then
		return 1
	end
	local k = 0.5 + 0.5 * math.sin(t * 2 * math.pi / (p[3] or 2))
	return p[1] + (p[2] - p[1]) * k
end

local FACE: { [string]: Enum.ParticleOrientation } = {
	camera = Enum.ParticleOrientation.FacingCamera,
	up = Enum.ParticleOrientation.FacingCameraWorldUp,
	vel = Enum.ParticleOrientation.VelocityParallel,
	flat = Enum.ParticleOrientation.VelocityPerpendicular,
}

local function fxPart(name: string, size: Vector3, parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Transparency = 1
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Massless = true
	p.Parent = parent
	return p
end

local function sprite(parent: Instance, layer: Layer, s: number): ImageLabel
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.Size = UDim2.fromScale(1, 1)
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	img.Position = UDim2.fromScale(0.5, 0.5)
	img.Image = Sprites.get(layer.sprite)
	img.ImageColor3 = layer.color or Color3.new(1, 1, 1)
	img.ImageTransparency = layer.alpha or 0
	img.Parent = parent
	return img
end

type Mover = (t: number, root: CFrame) -> ()

type State = {
	model: Model,
	root: BasePart,
	enabled: boolean,
	asleep: boolean,
	emitters: { ParticleEmitter },
	toggles: { Instance }, -- BillboardGui / SurfaceGui / Light / Beam / Trail (.Enabled)
	parts: { BasePart },
	movers: { Mover },
	made: { Instance },
	lastRoot: CFrame?,
	conn: RBXScriptConnection?,
}

local active: { [State]: boolean } = {}

local function build(state: State, layers: { Layer }, quality: number)
	local model, root = state.model, state.root
	local s = model:GetScale()
	local folder = Instance.new("Folder")
	folder.Name = "PetFx"
	folder.Parent = model
	table.insert(state.made, folder)

	local timers: { [string]: { next: number, fired: number } } = {}
	local rng = Random.new()

	local function attachment(name: string, pos: Vector3): Attachment
		local a = Instance.new("Attachment")
		a.Name = name
		a.Position = pos
		a.Parent = root
		table.insert(state.made, a)
		return a
	end

	for i, layer in layers do
		local kind = layer.kind
		local at = if layer.at then vec(layer.at, s) else Vector3.new(0, (layer.y or 0) * s, 0)
		if kind == "emit" then
			local e = Instance.new("ParticleEmitter")
			e.Name = `Emit{i}_{layer.sprite}`
			e.Texture = Sprites.get(layer.sprite)
			e.Rate = (layer.rate or 4) * quality
			e.Lifetime = num(layer.life or { 1, 2 }, 1)
			e.Size = seq(layer.size or 0.5, s)
			e.Speed = num(layer.speed or 0, s)
			e.Color = colors(layer.color)
			e.Transparency = seq(layer.alpha or { 0, 1 }, 1)
			e.LightEmission = layer.glow or 0
			e.LightInfluence = if layer.glow then 0 else 1
			e.SpreadAngle = Vector2.new(layer.spread or 180, layer.spread or 180)
			e.Acceleration = vec(layer.accel, s)
			e.Drag = layer.drag or 0
			e.RotSpeed = num(layer.spin or 0, 1)
			e.Rotation = num(layer.rot or { 0, 360 }, 1)
			e.Orientation = FACE[layer.face or "camera"] or Enum.ParticleOrientation.FacingCamera
			e.LockedToPart = layer.locked == true
			e.ZOffset = layer.zoff or 0
			e.EmissionDirection = if layer.dir then (Enum.NormalId :: any)[layer.dir] else Enum.NormalId.Top
			local every = layer.every
			if type(every) == "table" then
				e.Rate = 0
				local key = layer.sync or `burst{i}`
				local timer = timers[key]
				if not timer then
					timer = { next = os.clock() + rng:NextNumber(2, every[1]), fired = -1 }
					timers[key] = timer
				end
				local count = math.max(1, math.floor((layer.count or 10) * quality + 0.5))
				table.insert(state.movers, function(t)
					if t >= timer.next then
						timer.fired = t
						timer.next = t + rng:NextNumber(every[1], every[2] or every[1])
					end
					if timer.fired == t and e.Enabled then
						e:Emit(count)
					end
				end)
			end
			if layer.area then
				local host = fxPart(`Area{i}`, vec(layer.area, s), folder)
				e.Shape = (Enum.ParticleEmitterShape :: any)[layer.shape or "Box"]
				e.ShapeStyle = if layer.surface
					then Enum.ParticleEmitterShapeStyle.Surface
					else Enum.ParticleEmitterShapeStyle.Volume
				e.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
				e.Parent = host
				local offset = CFrame.new(at)
				table.insert(state.parts, host)
				table.insert(state.movers, function(_, r)
					host.CFrame = r * offset
				end)
			else
				e.Parent = attachment(`Emit{i}`, at)
			end
			table.insert(state.emitters, e)
		elseif kind == "orbit" then
			local count = layer.count or 3
			local radius, speed, bob = (layer.radius or 3) * s, layer.speed or 1, (layer.bob or 0) * s
			local tilt = CFrame.Angles(math.rad(layer.tilt or 0), 0, 0)
			local base = (layer.y or 2) * s
			local phase0 = layer.phase or 0
			local items: { { a0: Attachment?, a1: Attachment?, part: BasePart?, att: Attachment? } } = {}
			for k = 1, count do
				local item: { a0: Attachment?, a1: Attachment?, part: BasePart?, att: Attachment? } = {}
				if layer.part then
					local spec = layer.part
					local p = fxPart(`Orbit{i}_{k}`, vec(spec.size or { 0.4, 0.4, 0.4 }, s), folder)
					p.Transparency = spec.alpha or 0
					p.Color = spec.color or Color3.new(1, 1, 1)
					p.Material = (Enum.Material :: any)[spec.material or "Neon"]
					if spec.shape == "Ball" then
						p.Shape = Enum.PartType.Ball
					elseif spec.shape == "Cylinder" then
						p.Shape = Enum.PartType.Cylinder
					end
					item.part = p
					table.insert(state.parts, p)
				else
					local a = attachment(`Orbit{i}_{k}`, Vector3.zero)
					local gui = Instance.new("BillboardGui")
					gui.Size = UDim2.fromScale((layer.size or 0.8) * s, (layer.size or 0.8) * s)
					gui.LightInfluence = 0
					gui.Brightness = layer.glow or 1
					gui.Adornee = a
					gui.Parent = a
					sprite(gui, layer, s)
					table.insert(state.toggles, gui)
					item.att = a
				end
				if layer.trail then
					local tr = layer.trail
					local w = (tr.width or 0.3) * s / 2
					local a0, a1
					if item.part then
						a0 = Instance.new("Attachment")
						a0.Position = Vector3.new(0, w, 0)
						a0.Parent = item.part
						a1 = Instance.new("Attachment")
						a1.Position = Vector3.new(0, -w, 0)
						a1.Parent = item.part
					else
						a0 = attachment(`Trail{i}_{k}a`, Vector3.zero)
						a1 = attachment(`Trail{i}_{k}b`, Vector3.zero)
						item.a0, item.a1 = a0, a1
					end
					local trail = Instance.new("Trail")
					trail.Attachment0, trail.Attachment1 = a0, a1
					trail.Lifetime = tr.life or 0.5
					trail.Color = colors(tr.color)
					trail.Transparency = seq(tr.alpha or { 0.2, 1 }, 1)
					trail.LightEmission = tr.glow or 1
					trail.LightInfluence = 0
					trail.FaceCamera = true
					if tr.sprite then
						trail.Texture = Sprites.get(tr.sprite)
						trail.TextureMode = Enum.TextureMode.Stretch
					end
					trail.Parent = item.part or root
					table.insert(state.made, trail)
					table.insert(state.toggles, trail)
				end
				table.insert(items, item)
			end
			local spinAxis = layer.part and layer.part.spinAxis
			local hw = if layer.trail then (layer.trail.width or 0.3) * s / 2 else 0
			table.insert(state.movers, function(t, r)
				for k, item in items do
					local a = phase0 + t * speed + (k - 1) * 2 * math.pi / count
					local local_ = tilt * Vector3.new(math.cos(a) * radius, 0, math.sin(a) * radius)
					local pos = at * Vector3.new(1, 0, 1)
						+ Vector3.new(0, base, 0)
						+ local_
						+ Vector3.new(0, math.sin(t * 2 + k) * bob, 0)
					if item.part then
						local spin = if spinAxis then CFrame.Angles(t * 2, t * 1.3, 0) else CFrame.Angles(0, -a, 0)
						item.part.CFrame = r * CFrame.new(pos) * spin
					elseif item.att then
						item.att.Position = pos
					end
					if item.a0 and item.a1 then
						item.a0.Position = pos + Vector3.new(0, hw, 0)
						item.a1.Position = pos - Vector3.new(0, hw, 0)
					end
				end
			end)
		elseif kind == "disc" then
			local size = (layer.size or 4) * s
			local p = fxPart(`Disc{i}_{layer.sprite}`, Vector3.new(size, 0.05, size), folder)
			for _, face in { Enum.NormalId.Top, Enum.NormalId.Bottom } do
				local g = Instance.new("SurfaceGui")
				g.Face = face
				g.LightInfluence = 0
				g.Brightness = layer.glow or 2.5
				g.CanvasSize = Vector2.new(256, 256)
				g.Parent = p
				sprite(g, layer, s)
				table.insert(state.toggles, g)
			end
			table.insert(state.parts, p)
			local tilt = CFrame.Angles(math.rad(layer.tilt or 0), 0, 0)
			local spin = math.rad(layer.spin or 0)
			local pulseSpec = layer.pulse
			local offset = CFrame.new(at)
			table.insert(state.movers, function(t, r)
				local k = pulse(pulseSpec, t)
				if pulseSpec then
					p.Size = Vector3.new(size * k, 0.05, size * k)
				end
				p.CFrame = r * offset * tilt * CFrame.Angles(0, t * spin, 0)
			end)
		elseif kind == "board" then
			local back = (layer.back or 0) * s
			local a = attachment(`Board{i}`, at + Vector3.new(0, 0, back))
			local gui = Instance.new("BillboardGui")
			local size = (layer.size or 4) * s
			gui.Size = UDim2.fromScale(size, size)
			gui.LightInfluence = 0
			gui.Brightness = layer.glow or 2
			gui.Adornee = a
			gui.Parent = a
			local img = sprite(gui, layer, s)
			table.insert(state.toggles, gui)
			local spin = layer.spin or 0
			local pulseSpec = layer.pulse
			if spin ~= 0 or pulseSpec then
				table.insert(state.movers, function(t)
					img.Rotation = (t * spin) % 360
					if pulseSpec then
						local k = pulse(pulseSpec, t)
						img.Size = UDim2.fromScale(k, k)
					end
				end)
			end
		elseif kind == "light" then
			local l = Instance.new("PointLight")
			l.Color = layer.color or Color3.new(1, 1, 1)
			l.Range = (layer.range or 10) * s
			l.Brightness = layer.brightness or 1
			l.Shadows = false
			l.Parent = attachment(`Light{i}`, at)
			table.insert(state.toggles, l)
			local pulseSpec = layer.pulse
			local b = l.Brightness
			if pulseSpec then
				table.insert(state.movers, function(t)
					l.Brightness = b * pulse(pulseSpec, t)
				end)
			end
		elseif kind == "beam" then
			local a0 = attachment(`Beam{i}a`, Vector3.new(at.X, (layer.y0 or 0) * s, at.Z))
			local a1 = attachment(`Beam{i}b`, Vector3.new(at.X, (layer.y1 or 6) * s, at.Z))
			local b = Instance.new("Beam")
			b.Attachment0, b.Attachment1 = a0, a1
			b.Texture = Sprites.get(layer.sprite)
			b.TextureMode = Enum.TextureMode.Stretch
			b.TextureSpeed = layer.scroll or 0
			b.Width0 = (layer.width or 2) * s
			b.Width1 = (layer.width1 or layer.width or 2) * s
			b.Color = colors(layer.color)
			b.Transparency = seq(layer.alpha or { 0.3, 0.3 }, 1)
			b.LightEmission = layer.glow or 1
			b.LightInfluence = 0
			b.FaceCamera = true
			b.Segments = 1
			b.Parent = root
			table.insert(state.made, b)
			table.insert(state.toggles, b)
		else
			warn(`[PetFx] unknown layer kind "{kind}"`)
		end
	end
end

local function setVisible(state: State, on: boolean)
	for _, e in state.emitters do
		e.Enabled = on
	end
	for _, inst in state.toggles do
		(inst :: any).Enabled = on
	end
	for _, p in state.parts do
		p.LocalTransparencyModifier = if on then 0 else 1
	end
end

local updater: RBXScriptConnection? = nil
local function ensureUpdater()
	if updater then
		return
	end
	updater = RunService.Heartbeat:Connect(function()
		local t = os.clock()
		local cam = workspace.CurrentCamera
		local eye = if cam then cam.CFrame.Position else Vector3.zero
		for state in active do
			if not state.enabled then
				continue
			end
			local r = state.root.CFrame
			local far = (r.Position - eye).Magnitude > CULL
			if far ~= state.asleep then
				state.asleep = far
				setVisible(state, not far)
			end
			if far then
				continue
			end
			for _, move in state.movers do
				move(t, r)
			end
		end
	end)
end

-- Attach the egg or pet effect of `key` to a built egg/pet model. nil when there is no recipe for it.
function PetFx.attach(model: Model, kind: string, key: string, opts: { Quality: number? }?): Handle?
	local recipe = PetFx.recipe(kind, key)
	local root = model.PrimaryPart
	if not recipe or not root then
		return nil
	end
	local state: State = {
		model = model,
		root = root,
		enabled = true,
		asleep = false,
		emitters = {},
		toggles = {},
		parts = {},
		movers = {},
		made = {},
	}
	build(state, recipe.layers, (opts and opts.Quality) or 1)
	for _, move in state.movers do
		move(os.clock(), root.CFrame)
	end
	active[state] = true
	ensureUpdater()

	local function destroy()
		if not active[state] then
			return
		end
		active[state] = nil
		if state.conn then
			state.conn:Disconnect()
		end
		for _, inst in state.made do
			inst:Destroy()
		end
		table.clear(state.made)
	end
	state.conn = model.AncestryChanged:Connect(function()
		if not model:IsDescendantOf(game) then
			destroy()
		end
	end)
	return {
		SetEnabled = function(on: boolean)
			state.enabled = on
			state.asleep = false
			setVisible(state, on)
		end,
		Destroy = destroy,
	}
end

return PetFx
