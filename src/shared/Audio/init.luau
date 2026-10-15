--!strict
-- Plays the game's sounds (client only; on the server every call is a no-op). The sounds themselves are data in
-- Audio/SoundBank. One place decides, for every sound:
--   * group: SoundService.Master (the HUD sound button) > UI / Gameplay / Ambience / Music / SpecialEffects
--     (Settings sets each category's volume; magic layers go to SpecialEffects)
--   * 3D (pooled anchor or the moving part, rolls off with distance, skipped out of earshot) or 2D (UI)
--   * cooldown per event (+ opts.key), max voices per event and in total (fewer on phones; tier 3+ may exceed),
--     a toast chime is masked right after a big fanfare
--   * variation: a different variant than last time + a little random pitch
--   * cleanup: every Sound is destroyed when it ends (fallback timer); anchors go back to the pool
-- Entry points: Audio.play(event, at, opts) for SoundBank.Events, Audio.playStack for composed stacks (sacks),
-- Audio.landing for egg contacts (surface + speed + bounce + mutation), Audio.loop for looping beds (avalanche
-- roar, premium sacks), Audio.vfx (VFX.play forwards every effect here; the matching sound plays).
-- Audio.history keeps the last plays (event, tier, category, layers, volume; with Audio.measure on, the loudest
-- PlaybackLoudness each reached) for the tests and the play-test.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local SoundBank = require(script.SoundBank)
local Shared = script.Parent
local Chase = require(Shared.Config.Chase)
local Zones = require(Shared.Config.Zones)

local Audio = {}
Audio.Bank = SoundBank

type Layer = SoundBank.Layer
export type Opts = {
	key: string?, -- cooldown scope (an egg uid, a sack): the same event elsewhere still plays
	own: boolean?, -- false = someone else's (quieter); nil = yours
	intensity: number?, -- 0..1: volume 45%..100%
	volume: number?,
	transpose: number?, -- semitones for layers marked tune
	variant: number?,
	follow: boolean?, -- 3D: parent to the target part so the sound moves with it
}
export type Played = {
	event: string,
	tier: number,
	category: string,
	layers: { string },
	volume: number,
	at: Vector3?,
	t: number,
	loudness: number, -- (Audio.measure) loudest sum over the layers of PlaybackLoudness x Volume in one frame
	-- (PlaybackLoudness alone ignores Volume, SoundGroups and distance: measured; so it is weighted by Volume)
	audible: number, -- (Audio.measure) seconds it was audible (sum > 1)
	loaded: boolean,
}

local HISTORY = 400
local OTHERS = 0.55 -- other players' sounds
local MAX_VOICES = 28
local MAX_VOICES_MOBILE = 16
local MASK_SECONDS = 0.45

Audio.history = {} :: { Played }
Audio.measure = false -- play-test: sample each sound's PlaybackLoudness
Audio.muted = false -- tests

local lastAt: { [string]: number } = {}
local lastVariant: { [string]: number } = {}
local liveByEvent: { [string]: number } = {}
local liveTotal = 0
local lastBig = -math.huge
local rng = Random.new()
local Pool: any = nil
local clickQuietUntil = -math.huge

local function isClient(): boolean
	return RunService:IsClient()
end

-- Groups ------------------------------------------------------------------------------------------------------
local function master(): SoundGroup
	local g = SoundService:FindFirstChild("Master")
	if g and g:IsA("SoundGroup") then
		return g
	end
	local group = Instance.new("SoundGroup")
	group.Name = "Master"
	group.Volume = 0.5
	group.Parent = SoundService
	return group
end

-- The category's SoundGroup (a child of Master; its volume = the player's setting, attribute Volume<Category>).
function Audio.group(category: string): SoundGroup
	local m = master()
	local g = m:FindFirstChild(category)
	if g and g:IsA("SoundGroup") then
		return g
	end
	local group = Instance.new("SoundGroup")
	group.Name = category
	local me = Players.LocalPlayer
	local v = me and me:GetAttribute("Volume" .. category)
	group.Volume = if typeof(v) == "number" then math.clamp(v, 0, 1) else 1
	group.Parent = m
	return group
end

function Audio.setVolume(category: string, volume: number)
	local v = math.clamp(volume, 0, 1)
	Audio.group(category).Volume = v
	local me = Players.LocalPlayer
	if me then
		me:SetAttribute("Volume" .. category, v)
	end
end

function Audio.volume(category: string): number
	return Audio.group(category).Volume
end

-- Position / parent -------------------------------------------------------------------------------------------
local function posOf(at: (Vector3 | Instance)?): Vector3?
	if typeof(at) == "Vector3" then
		return at
	elseif typeof(at) == "Instance" then
		if at:IsA("BasePart") then
			return at.Position
		elseif at:IsA("Model") then
			return at:GetPivot().Position
		elseif at:IsA("Attachment") then
			return at.WorldPosition
		end
	end
	return nil
end

local function partOf(at: (Vector3 | Instance)?): BasePart?
	if typeof(at) == "Instance" then
		if at:IsA("BasePart") then
			return at
		elseif at:IsA("Model") then
			return at.PrimaryPart
		end
	end
	return nil
end

local function maxVoices(): number
	return if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
		then MAX_VOICES_MOBILE
		else MAX_VOICES
end

local function heard(layer: Layer): number
	local length = SoundBank.measure({ layer })
	return length
end

-- One Sound for one layer. Returns it (already scheduled to play and to clean itself up).
local function makeSound(
	layer: Layer,
	category: string,
	parent: Instance,
	spatial: boolean,
	rolloff: { number }?,
	volumeScale: number,
	pitchScale: number,
	transpose: number?
): Sound?
	local src: SoundBank.Source? = SoundBank.Sources[layer.src]
	local custom, index = string.match(layer.src, "^custom:(.+)#(%d+)$")
	local c = if custom then SoundBank.CUSTOM[custom] else nil
	if c then
		local ids = c.ids or { c.id }
		src = { id = ids[math.clamp(tonumber(index) or 1, 1, #ids)], gain = 1 }
	end
	if not src then
		return nil
	end
	local s = Instance.new("Sound")
	s.Name = "Sfx_" .. layer.src
	s.SoundId = src.id
	if src.region then
		s.PlaybackRegionsEnabled = true
		s.PlaybackRegion = NumberRange.new(src.region[1], src.region[2])
	end
	local pitch = layer.pitch * pitchScale
	if layer.tune and transpose then
		pitch *= 2 ^ (transpose / 12)
	end
	s.PlaybackSpeed = pitch
	local volume = math.clamp(src.gain * layer.volume * volumeScale, 0, 10)
	s.Volume = if layer.fade then 0 else volume
	s.Looped = src.loop == true
	if spatial then
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = if rolloff then rolloff[1] else 10
		s.RollOffMaxDistance = if rolloff then rolloff[2] else 90
	end
	s.SoundGroup = Audio.group(if layer.fx then "SpecialEffects" else category)
	if layer.eq then
		local eq = Instance.new("EqualizerSoundEffect")
		eq.LowGain, eq.MidGain, eq.HighGain = layer.eq[1], layer.eq[2], layer.eq[3]
		eq.Parent = s
	end
	if layer.reverb then
		local rv = Instance.new("ReverbSoundEffect")
		rv.DecayTime, rv.WetLevel, rv.DryLevel = 1.6, -6, 0
		rv.Parent = s
	end
	s.Parent = parent
	if layer.fade then
		TweenService:Create(s, TweenInfo.new(math.max(layer.fade[1], 0.005)), { Volume = volume }):Play()
	end
	if layer.length and not s.Looped then
		local out = if layer.fade then layer.fade[2] else 0.06
		task.delay(math.max(0, layer.length - out), function()
			if s.Parent then
				TweenService:Create(s, TweenInfo.new(math.max(out, 0.01)), { Volume = 0 }):Play()
			end
		end)
	end
	return s
end

-- Plays a stack of layers as one sound event. `meta` = the event's rules.
local function emit(
	name: string,
	layers: { Layer },
	meta: {
		category: string,
		tier: number,
		spatial: boolean,
		cooldown: number,
		voices: number,
		jitter: number?,
		rolloff: { number }?,
		masked: boolean?,
	},
	at: (Vector3 | Instance)?,
	opts: Opts?
): boolean
	if not isClient() or Audio.muted or #layers == 0 then
		return false
	end
	local custom = SoundBank.CUSTOM[name]
	if custom then -- an uploaded recording replaces the built-in layers (a different variant each play)
		local count = if custom.ids then #custom.ids else 1
		local i = 1
		if count > 1 then
			i = if opts and opts.variant then math.clamp(opts.variant, 1, count) else rng:NextInteger(1, count)
			if not (opts and opts.variant) and i == lastVariant["custom:" .. name] then
				i = i % count + 1
			end
			lastVariant["custom:" .. name] = i
		end
		layers = { SoundBank.L(`custom:{name}#{i}`, 1, custom.volume or 0.5, { tune = custom.tune }) }
	end
	local o: Opts = opts or {}
	local now = os.clock()
	local key = name .. "|" .. (o.key or "")
	if now - (lastAt[key] or -math.huge) < meta.cooldown then
		return false
	end
	if meta.masked and now - lastBig < MASK_SECONDS then
		return false
	end
	if (liveByEvent[name] or 0) >= meta.voices then
		return false
	end
	if liveTotal >= maxVoices() and meta.tier < 3 then
		return false
	end
	local pos = posOf(at)
	local parent: Instance = SoundService
	local anchor: BasePart? = nil
	if meta.spatial then
		if not pos then
			return false
		end
		local cam = workspace.CurrentCamera
		local reach = (if meta.rolloff then meta.rolloff[2] else 90) + 10
		if cam and (pos - cam.CFrame.Position).Magnitude > reach then
			return false
		end
		local part = partOf(at)
		if o.follow and part then
			parent = part
		else
			Pool = Pool or require(Shared.VFX.Pool) :: any
			anchor = Pool.anchor(CFrame.new(pos))
			parent = anchor :: BasePart
		end
	end
	lastAt[key] = now
	if meta.tier >= 3 then
		lastBig = now
	end
	local volumeScale = (o.volume or 1) * (if o.own == false then OTHERS else 1)
	if o.intensity then
		volumeScale *= 0.45 + 0.55 * math.clamp(o.intensity, 0, 1)
	end
	local pitchScale = 1 + (rng:NextNumber() - 0.5) * 2 * (meta.jitter or 0)
	local record: Played = {
		event = name,
		tier = meta.tier,
		category = meta.category,
		layers = {},
		volume = volumeScale,
		at = pos,
		t = now,
		loudness = 0,
		audible = 0,
		loaded = false,
	}
	table.insert(Audio.history, record)
	if #Audio.history > HISTORY then
		table.remove(Audio.history, 1)
	end
	liveByEvent[name] = (liveByEvent[name] or 0) + 1
	liveTotal += 1
	local longest = if custom then custom.seconds or 3 else 0 -- (an uploaded file's length isn't in Sources)
	local sounds: { Sound } = {}
	for _, layer in layers do
		table.insert(record.layers, layer.src)
		longest = math.max(longest, (layer.delay or 0) + heard(layer))
		local function start()
			local s = makeSound(
				layer,
				meta.category,
				parent,
				meta.spatial,
				meta.rolloff,
				volumeScale,
				pitchScale,
				o.transpose
			)
			if s then
				table.insert(sounds, s)
				s:Play()
				s.Ended:Once(function()
					s:Destroy()
				end)
			end
		end
		if (layer.delay or 0) > 0 then
			task.delay(layer.delay :: number, start)
		else
			start()
		end
	end
	if Audio.measure then
		local conn: RBXScriptConnection
		conn = RunService.RenderStepped:Connect(function()
			local sum = 0
			for _, s in sounds do
				if s.Parent then
					sum += s.PlaybackLoudness * s.Volume
					record.loaded = record.loaded or s.IsLoaded
				end
			end
			record.loudness = math.max(record.loudness, sum)
			if sum > 1 then
				record.audible = os.clock() - now
			end
		end)
		task.delay(longest + 0.3, function()
			conn:Disconnect()
		end)
	end
	task.delay(longest + 0.5, function()
		for _, s in sounds do
			if s.Parent then
				s:Destroy()
			end
		end
		liveByEvent[name] = math.max(0, (liveByEvent[name] or 1) - 1)
		liveTotal = math.max(0, liveTotal - 1)
		if anchor and Pool then
			Pool.release(anchor)
		end
	end)
	return true
end

-- Plays SoundBank.Events[name] at `at` (a position or an instance; nil for UI). Returns whether it played.
function Audio.play(name: string, at: (Vector3 | Instance)?, opts: Opts?): boolean
	local def = SoundBank.Events[name]
	if not def or def.loop then
		return false
	end
	local count = #def.variants
	local index = if opts and opts.variant then math.clamp(opts.variant, 1, count) else rng:NextInteger(1, count)
	if count > 1 and not (opts and opts.variant) and index == lastVariant[name] then
		index = index % count + 1 -- never the same variant twice in a row
	end
	lastVariant[name] = index
	return emit(name, def.variants[index], {
		category = def.category,
		tier = def.tier,
		spatial = def.spatial,
		cooldown = def.cooldown,
		voices = def.voices,
		jitter = def.jitter,
		rolloff = def.rolloff,
		masked = def.masked,
	}, at, opts)
end

-- A composed stack (sack hits) with its tier; spatial Gameplay sound.
function Audio.playStack(name: string, layers: { Layer }, tier: number, at: (Vector3 | Instance)?, opts: Opts?): boolean
	return emit(name, layers, {
		category = "Gameplay",
		tier = tier,
		spatial = true,
		cooldown = 0.05,
		voices = 6,
		jitter = 0.03,
		rolloff = { 10, 90 },
	}, at, opts)
end

-- An egg touching the ground at `speed` studs/s: the zone's surface, louder + punchier when faster, a bounce or
-- the final landing, the mutation's accent. Too soft (< Landing.minSpeed) = silent. opts.key = the egg (cooldown).
function Audio.landing(at: Vector3 | Instance, speed: number, bounce: boolean, mutation: string?, opts: Opts?): boolean
	local intensity = SoundBank.landingIntensity(speed)
	local pos = posOf(at)
	if not intensity or not pos then
		return false
	end
	local surface = SoundBank.surfaceAt(pos, Zones :: any, Chase.SafeLineZ)
	local layers, tier = SoundBank.landing(surface, intensity, bounce, mutation)
	local name = (if bounce then "EggBounce_" else "EggLand_") .. surface
	local meta = {
		category = "Gameplay",
		tier = tier,
		spatial = true,
		cooldown = SoundBank.Landing.cooldown,
		voices = 3,
		jitter = 0.05,
		rolloff = { 12, 120 },
	}
	if not SoundBank.CUSTOM[name] then
		return emit(name, layers, meta, at, opts)
	end
	-- An uploaded landing is one file: the impact speed sets its volume, and a weather mutation's accent plays on
	-- top as its own sound (MutationAccent_<mutation>, or the built-in accent layers until that one is uploaded).
	local o: Opts = table.clone(opts or {})
	o.intensity = o.intensity or intensity
	local played = emit(name, layers, meta, at, o)
	local accent = if mutation then SoundBank.MutationAccent[mutation] else nil
	if played and accent and mutation then
		emit("MutationAccent_" .. mutation, accent, meta, at, opts)
	end
	return played
end

-- Loops ---------------------------------------------------------------------------------------------------------
export type LoopHandle = { stop: () -> (), setPaused: (paused: boolean) -> (), setPosition: (pos: Vector3) -> () }
local function loopLayers(
	name: string,
	layers: { Layer },
	category: string,
	at: Vector3 | Instance,
	rolloff: { number }?,
	opts: Opts?
): LoopHandle
	local none: LoopHandle = {
		stop = function() end,
		setPaused = function(_p: boolean) end,
		setPosition = function(_v: Vector3) end,
	}
	if not isClient() or Audio.muted then
		return none
	end
	local custom = SoundBank.CUSTOM[name]
	if custom then -- an uploaded seamless loop replaces the built-in bed
		layers = { SoundBank.L(`custom:{name}#1`, 1, custom.volume or 0.5) }
	end
	local part = partOf(at)
	local anchor: BasePart? = nil
	local parent: Instance
	if part and typeof(at) == "Instance" then
		parent = part
	else
		Pool = Pool or require(Shared.VFX.Pool) :: any
		anchor = Pool.anchor(CFrame.new(posOf(at) or Vector3.zero))
		parent = anchor :: BasePart
	end
	local scale = (opts and opts.volume or 1) * (if opts and opts.own == false then OTHERS else 1)
	local sounds: { Sound } = {}
	for _, layer in layers do
		local s = makeSound(layer, category, parent, true, rolloff, scale, 1, nil)
		if s then
			s.Looped = true
			s:Play()
			table.insert(sounds, s)
		end
	end
	table.insert(Audio.history, {
		event = name,
		tier = 1,
		category = category,
		layers = {},
		volume = scale,
		at = posOf(at),
		t = os.clock(),
		loudness = 0,
		audible = 0,
		loaded = false,
	})
	local stopped = false
	return {
		stop = function()
			if stopped then
				return
			end
			stopped = true
			for _, s in sounds do
				TweenService:Create(s, TweenInfo.new(0.4), { Volume = 0 }):Play()
			end
			task.delay(0.45, function()
				for _, s in sounds do
					s:Destroy()
				end
				if anchor and Pool then
					Pool.release(anchor)
				end
			end)
		end,
		setPaused = function(paused: boolean)
			for _, s in sounds do
				if paused and s.IsPlaying then
					s:Pause()
				elseif not paused and s.IsPaused then
					s:Resume()
				end
			end
		end,
		setPosition = function(pos: Vector3)
			if anchor then
				anchor.CFrame = CFrame.new(pos)
			end
		end,
	}
end

-- A looping SoundBank event (AvalancheRoll) at `at`; move it with handle.setPosition.
function Audio.loop(name: string, at: Vector3 | Instance, opts: Opts?): LoopHandle
	local def = SoundBank.Events[name]
	if not def or not def.loop then
		return loopLayers(name, {}, "Ambience", at, nil, opts)
	end
	return loopLayers(name, def.variants[1], def.category, at, def.rolloff, opts)
end

-- A looping stack on a part (premium sacks' ambience).
function Audio.loopStack(name: string, layers: { Layer }, part: BasePart, opts: Opts?): LoopHandle
	return loopLayers(name, layers, "Ambience", part, { 6, 45 }, opts)
end

-- VFX hook: the sound of a visual effect (VFX.play forwards every effect here) --------------------------------
local avalancheLoops: { [Instance]: { handle: LoopHandle, conn: RBXScriptConnection } } = {}

local function mine(params: { [string]: any }): boolean?
	local owner = params.ownerUserId
	if typeof(owner) ~= "number" then
		return nil -- (yours)
	end
	local me = Players.LocalPlayer
	return me ~= nil and owner == me.UserId
end

local function ownFlag(params: { [string]: any }): boolean?
	local m = mine(params)
	return if m == false then false else nil
end

function Audio.vfx(name: string, target: Instance?, params: { [string]: any })
	if not isClient() then
		return
	end
	if name == "KickImpact" and params.cutscene then
		local o: Opts = { own = if params.own == true then nil else false }
		Audio.play(SoundBank.kickEvent(params.band), target, o)
		task.delay(0.06, function() -- the egg flies off the foot
			Audio.play("EggThrow", target, o)
		end)
	elseif name == "ZoneEnter" then
		Audio.play("ZoneEnter", target, { transpose = math.min(19, (tonumber(params.zone) or 1) - 1) })
	elseif name == "Landing" then
		local speed = if typeof(params.speed) == "number" then params.speed else 40
		Audio.landing(
			target :: Instance,
			speed,
			false,
			if typeof(params.weather) == "string" then params.weather else nil,
			{ own = ownFlag(params), key = if target then target:GetFullName() else nil }
		)
	elseif name == "LegsSprout" then
		Audio.play("LegsSprout", target, { own = ownFlag(params) })
	elseif name == "AvalancheWarn" then
		if mine(params) ~= false then
			Audio.play(
				"AvalancheWarn",
				posOf(target) or (if typeof(params.startZ) == "number" then Vector3.new(0, 4, params.startZ) else nil)
			)
		end
	elseif name == "AvalancheStart" and target then
		local startZ: number = tonumber(params.startZ) or 0
		local theme = if typeof(params.theme) == "string" then params.theme else "Rock"
		local at = Vector3.new(0, 4, startZ)
		Audio.play(
			"AvalancheStart",
			at,
			{ variant = if SoundBank.SoftAvalanche[theme] then 2 else 1, own = ownFlag(params) }
		)
		local old = avalancheLoops[target]
		if old then
			old.handle.stop()
			old.conn:Disconnect()
		end
		local handle = Audio.loop("AvalancheRoll", at, { own = ownFlag(params) })
		local speed: number = tonumber(params.speed) or 20
		local startTime: number = tonumber(params.startTime) or workspace:GetServerTimeNow()
		local conn = RunService.Heartbeat:Connect(function()
			local z = Chase.frontZ(startZ, startTime, speed, workspace:GetServerTimeNow())
			handle.setPosition(Vector3.new(0, 4, math.max(z, Chase.SafeLineZ)))
		end)
		avalancheLoops[target] = { handle = handle, conn = conn }
		target.AncestryChanged:Connect(function()
			if not target:IsDescendantOf(game) then
				Audio.vfx("AvalancheStop", target, { silent = true })
			end
		end)
	elseif name == "AvalancheStop" and target then
		local loop = avalancheLoops[target]
		avalancheLoops[target] = nil
		local at: Vector3? = nil
		if loop then
			loop.conn:Disconnect()
			loop.handle.stop()
		end
		if not params.silent then
			local cam = workspace.CurrentCamera
			at = posOf(target) or (if cam then cam.CFrame.Position else nil)
			if at then
				Audio.play("AvalancheStop", at, { own = ownFlag(params) })
			end
		end
	elseif name == "EggSecured" then
		Audio.play("EggSecured", target, { own = ownFlag(params) })
	elseif name == "EggCaught" then
		Audio.play("EggCaught", target, { own = ownFlag(params) })
	elseif name == "HatchCrack" then
		Audio.play("HatchCrack", target, {
			key = if target then target:GetFullName() else nil,
			intensity = math.clamp(tonumber(params.progress) or 0.5, 0.2, 1),
		})
	elseif name == "HatchBurst" then
		Audio.play(SoundBank.hatchEvent(params.rarity), target)
	elseif name == "MoneyPop" then
		Audio.play("MoneyChime", target)
	end
end

-- UI -------------------------------------------------------------------------------------------------------------
-- A UI action with its own sound (a menu opening) takes the place of the button click for `seconds`.
function Audio.quietClick(seconds: number?)
	clickQuietUntil = os.clock() + (seconds or 0.1)
end

-- A light click on every button under `root` (now and later). Buttons with attribute NoClickSound stay silent.
function Audio.hookButtons(root: Instance)
	local function hook(d: Instance)
		if d:IsA("GuiButton") then
			d.Activated:Connect(function()
				if d:GetAttribute("NoClickSound") ~= true and os.clock() >= clickQuietUntil then
					Audio.play("UIClick")
				end
			end)
		end
	end
	for _, d in root:GetDescendants() do
		hook(d)
	end
	root.DescendantAdded:Connect(hook)
end

-- The last played entry of `event` (tests / play-test), or nil.
function Audio.last(event: string): Played?
	for i = #Audio.history, 1, -1 do
		if Audio.history[i].event == event then
			return Audio.history[i]
		end
	end
	return nil
end

return Audio
