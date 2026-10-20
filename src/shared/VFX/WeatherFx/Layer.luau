--!strict
-- Partner A. One live weather look (client only): its elements, ambience bed and accents, faded by one weight.
-- kind: "global" (the server's event: camera + sky pieces), "local" (the camera pieces of a local storm, only while
-- you stand in it), "region" (a local storm's own area pieces, visible to anyone near it).
-- The weight moves toward `target` at 1/fadeIn or 1/fadeOut per second and is eased (smoothstep), so a reversal mid
-- fade is continuous: no snapping, ever. Once it is back at 0 with target 0, the layer waits for its particles to
-- finish (linger) and reports done; the mixer then destroys it.
local Elements = require(script.Parent.Elements)
local Registry = require(script.Parent.Registry)
local WeatherSound = require(script.Parent.Sound)

local Layer = {}

export type Layer = {
	key: string,
	kind: string,
	entry: Registry.Entry,
	seq: number,
	p: number, -- linear progress 0..1
	w: number, -- eased weight 0..1
	target: number,
	fadeIn: number,
	fadeOut: number,
	elements: { Elements.Element },
	folder: Folder,
	bed: Sound?,
	nextAccent: number,
	linger: number,
	idleSince: number?,
	shownW: number,
	shownQ: number,
}

local rng = Random.new()
local count = 0

function Layer.new(key: string, entry: Registry.Entry, kind: string, ctx: Elements.Ctx, region: Elements.Region?): Layer
	count += 1
	local folder = Instance.new("Folder")
	folder.Name = "Weather_" .. (key:gsub("[^%w_]", "_"))
	folder.Parent = ctx.folder
	local sub = table.clone(ctx) :: any
	sub.folder = folder
	local elements: { Elements.Element } = {}
	local linger = 0
	for _, spec in entry.elements do
		local isRegion = spec.where == "region"
		if (kind == "region") == isRegion then
			local ok, el = pcall(Elements.build, spec, sub, region)
			if ok and el then
				table.insert(elements, el)
				linger = math.max(linger, el.linger)
			elseif not ok then
				warn(`[WeatherFx] {entry.id} {spec.kind}: {el}`)
			end
		end
	end
	local fadeIn, fadeOut = entry.fadeIn, entry.fadeOut
	if kind ~= "global" then
		fadeIn, fadeOut = entry.localFade, entry.localFade
	end
	local layer: Layer = {
		key = key,
		kind = kind,
		entry = entry,
		seq = count,
		p = 0,
		w = 0,
		target = 1,
		fadeIn = fadeIn,
		fadeOut = fadeOut,
		elements = elements,
		folder = folder,
		bed = if kind ~= "region" then WeatherSound.bed(entry.sounds.bed, folder) else nil,
		nextAccent = ctx.t + rng:NextNumber(3, 6),
		linger = linger,
		idleSince = nil,
		shownW = -1,
		shownQ = -1,
	};
	-- the elements keep the mixer's live ctx table (camera, quality ...) via `sub`, which shares no state: refresh it
	(layer :: any).ctx = sub
	return layer
end

-- Advance one frame. Returns true when the layer has fully faded out and its particles are gone.
function Layer.update(layer: Layer, ctx: Elements.Ctx): boolean
	local sub = (layer :: any).ctx
	for k, v in ctx :: any do
		if k ~= "folder" then
			sub[k] = v
		end
	end
	local dt = ctx.dt
	if layer.p < layer.target then
		layer.p = math.min(layer.target, layer.p + dt / math.max(layer.fadeIn, 0.05))
	elseif layer.p > layer.target then
		layer.p = math.max(layer.target, layer.p - dt / math.max(layer.fadeOut, 0.05))
	end
	local p = layer.p
	layer.w = p * p * (3 - 2 * p)
	-- re-apply on a weight change, and when the quality level changes (LowDetail / graphics level)
	if math.abs(layer.w - layer.shownW) > 0.0015 or (layer.w == 0 and layer.shownW ~= 0) or layer.shownQ ~= ctx.q then
		layer.shownQ = ctx.q
		layer.shownW = layer.w
		for _, el in layer.elements do
			el.apply(layer.w)
		end
		if layer.bed then
			layer.bed.Volume = WeatherSound.bedVolume(layer.entry.sounds.bed) * layer.w
		end
	end
	for _, el in layer.elements do
		local step = el.step
		if step then
			step(sub)
		end
	end
	-- occasional world accents near you (only while clearly present)
	local accents = layer.entry.sounds.accents
	if accents and layer.kind ~= "region" and layer.w > 0.6 and ctx.t >= layer.nextAccent then
		local a = accents[rng:NextInteger(1, #accents)]
		layer.nextAccent = ctx.t + rng:NextNumber(a.every[1], a.every[2])
		local ang = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(a.near * 0.4, a.near)
		WeatherSound.play(
			a.key,
			Vector3.new(ctx.cam.X + math.cos(ang) * r, ctx.ground + 2, ctx.cam.Z + math.sin(ang) * r)
		)
	end
	if layer.p <= 0 and layer.target <= 0 then
		layer.idleSince = layer.idleSince or ctx.t
		return ctx.t - (layer.idleSince :: number) >= layer.linger
	end
	layer.idleSince = nil
	return false
end

function Layer.destroy(layer: Layer)
	for _, el in layer.elements do
		pcall(el.destroy)
	end
	table.clear(layer.elements)
	layer.folder:Destroy()
end

return Layer
