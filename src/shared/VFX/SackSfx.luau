--!strict
-- Kick Sack sound design (client). Every sack has its own sounds for five moments:
--   equip    the sack slams down on its chain (drop)       impact   one kick lands
--   special  super hits / signature effects                upgrade  a new sack is bought
--   idle     a soft ambient loop (only the premium sacks: Lava Core, Galaxy Void, Sun Guardian, Rainbow God)
-- A sound is a stack of LAYERS played together ({sound, pitch, volume, delay}). Each sack's stack follows its theme
-- (Builders/Models/Sacks look.theme) and FX step: bigger sacks layer more and heavier sounds.
--
-- ASSETS: until custom audio is uploaded, the layers use the sounds that ship with Roblox (rbxasset://sounds/*:
-- permitted, never missing), pitched and stacked per theme. To use custom audio, put its uploaded Sound asset id
-- in CUSTOM[tier][moment] ("rbxassetid://<id>"): it then replaces that moment's stack. docs/Rework.md lists the
-- exact sounds still wanted. Never invent ids.
--
-- Playback: every sound goes through SoundService.Master (the HUD sound toggle mutes it), is spatial (rolls off by
-- ROLL_MAX studs), skipped when out of earshot, never more than MAX_LIVE at once, and the same sound isn't
-- restarted within REPEAT_GAP (no machine-gun stacking). Other players' sacks play quieter than your own.
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local Sacks = require(script.Parent.Parent.Builders.Models.Sacks)
local Pool = require(script.Parent.Pool)

local SackSfx = {}

local BUILTIN = {
	thud = "rbxasset://sounds/action_jump_land.mp3",
	boom = "rbxasset://sounds/impact_explosion_03.mp3",
	splash = "rbxasset://sounds/impact_water.mp3",
	whoosh = "rbxasset://sounds/action_jump.mp3",
	wind = "rbxasset://sounds/action_falling.ogg",
	bubble = "rbxasset://sounds/action_swim.mp3",
	tick = "rbxasset://sounds/volume_slider.ogg",
	step = "rbxasset://sounds/action_footsteps_plastic.mp3",
	rise = "rbxasset://sounds/action_get_up.mp3",
}

export type Layer = { sound: string, pitch: number, volume: number, delay: number? }
export type Moment = "equip" | "impact" | "special" | "upgrade" | "idle"

local function L(sound: string, pitch: number, volume: number, delay: number?): Layer
	return { sound = sound, pitch = pitch, volume = volume, delay = delay }
end

-- Theme layers added on top of the shared body for each moment.
local THEME: { [string]: { impact: { Layer }, special: { Layer } } } = {
	dust = { impact = { L("step", 0.7, 0.4) }, special = { L("whoosh", 0.6, 0.3) } },
	chalk = { impact = { L("whoosh", 1.6, 0.25) }, special = { L("whoosh", 1.2, 0.35) } },
	sweat = { impact = { L("splash", 1.8, 0.25) }, special = { L("splash", 1.4, 0.35) } },
	stars = { impact = { L("tick", 1.6, 0.35), L("tick", 2.1, 0.25, 0.05) }, special = { L("tick", 2.4, 0.4) } },
	rubber = { impact = { L("thud", 1.6, 0.35) }, special = { L("rise", 1.5, 0.4) } },
	sparks = { impact = { L("boom", 3.4, 0.18) }, special = { L("boom", 4, 0.22) } },
	glint = { impact = { L("tick", 2.6, 0.3) }, special = { L("boom", 0.55, 0.25) } },
	sparkle = { impact = { L("tick", 3, 0.3), L("tick", 2.2, 0.2, 0.06) }, special = { L("tick", 3.4, 0.4) } },
	coins = { impact = { L("tick", 2, 0.35), L("tick", 2.5, 0.3, 0.07) }, special = { L("tick", 2.8, 0.45) } },
	frost = { impact = { L("splash", 1.5, 0.35), L("tick", 3.2, 0.2) }, special = { L("splash", 1.2, 0.45) } },
	crystal = { impact = { L("tick", 2.8, 0.35), L("boom", 3.6, 0.15) }, special = { L("tick", 3.6, 0.45) } },
	sprinkles = { impact = { L("bubble", 1.8, 0.3), L("tick", 2.4, 0.25) }, special = { L("bubble", 2.2, 0.4) } },
	embers = { impact = { L("boom", 1.4, 0.35), L("wind", 1.8, 0.15) }, special = { L("boom", 0.9, 0.45) } },
	lightning = {
		impact = { L("boom", 4.5, 0.22), L("tick", 4, 0.25) },
		special = { L("boom", 5, 0.35), L("tick", 4.5, 0.3, 0.04) },
	},
	goo = { impact = { L("splash", 0.9, 0.4), L("bubble", 1.2, 0.25) }, special = { L("bubble", 0.8, 0.45) } },
	robo = {
		impact = { L("tick", 1.3, 0.35), L("boom", 3.8, 0.18) },
		special = { L("tick", 0.9, 0.45), L("tick", 1.4, 0.35, 0.08) },
	},
	fire = {
		impact = { L("boom", 0.9, 0.4), L("wind", 1.4, 0.25) },
		special = { L("wind", 0.8, 0.5), L("boom", 0.7, 0.4) },
	},
	-- premium: Galaxy Void (deep cosmic, distorted), Sun Guardian (warm, radiant), Rainbow God (bright, layered)
	cosmic = {
		impact = { L("boom", 0.42, 0.55), L("wind", 0.35, 0.35), L("tick", 0.5, 0.2, 0.05) },
		special = { L("boom", 0.32, 0.6), L("wind", 0.25, 0.45, 0.04) },
	},
	holy = {
		impact = { L("boom", 0.6, 0.45), L("wind", 0.9, 0.3), L("tick", 1.8, 0.25, 0.06) },
		special = { L("boom", 0.5, 0.5), L("wind", 0.7, 0.45), L("tick", 2.2, 0.3, 0.1) },
	},
	rainbow = {
		impact = { L("boom", 0.8, 0.45), L("tick", 1.6, 0.3), L("tick", 2, 0.28, 0.05), L("tick", 2.4, 0.26, 0.1) },
		special = {
			L("tick", 1.5, 0.35),
			L("tick", 1.9, 0.33, 0.06),
			L("tick", 2.25, 0.31, 0.12),
			L("tick", 3, 0.3, 0.18),
			L("boom", 0.7, 0.4),
		},
	},
}

-- Ambient loops (premium sacks only), quiet and short-range.
local IDLE: { [number]: { Layer } } = {
	[13] = { L("wind", 0.32, 0.18) }, -- Lava Core: low magma rumble
	[18] = { L("wind", 0.22, 0.22), L("bubble", 0.35, 0.08) }, -- Galaxy Void: deep cosmic hum
	[19] = { L("wind", 0.55, 0.16) }, -- Sun Guardian: warm solar hum
	[20] = { L("wind", 0.75, 0.12), L("bubble", 1.9, 0.08) }, -- Rainbow God: airy shimmer
}

-- Custom uploaded audio per sack and moment (empty = the built-in stacks above). See the header.
SackSfx.CUSTOM = {} :: { [number]: { [Moment]: string } }

local ROLL_MIN, ROLL_MAX = 10, 90
local MAX_LIVE = 14
local REPEAT_GAP = 0.06
local OTHERS = 0.6 -- volume of other players' sacks

local live = 0
local lastPlayed: { [string]: number } = {}

local function master(): SoundGroup?
	local g = SoundService:FindFirstChild("Master")
	return if g and g:IsA("SoundGroup") then g else nil
end

local function stepOf(tier: number): number
	if tier >= 20 then
		return 6
	elseif tier >= 15 then
		return 5
	elseif tier >= 10 then
		return 4
	elseif tier >= 7 then
		return 3
	elseif tier >= 4 then
		return 2
	end
	return 1
end

-- The layers for `tier`'s `moment` (exposed for the tests / the report).
function SackSfx.layers(tier: number, moment: Moment): { Layer }
	local custom = SackSfx.CUSTOM[tier]
	if custom and custom[moment] and custom[moment] ~= "" then
		return { L(custom[moment], 1, 0.8) }
	end
	local look = Sacks.look(tier)
	local theme = THEME[look.theme] or THEME.dust
	local step = stepOf(tier)
	local out: { Layer } = {}
	local function add(list: { Layer })
		for _, layer in list do
			table.insert(out, layer)
		end
	end
	if moment == "equip" then
		add({ L("thud", 0.85 - step * 0.05, 0.55 + step * 0.04), L("whoosh", 0.75, 0.3, 0.02) })
		if step >= 3 then
			add({ L("boom", 1.6 - step * 0.15, 0.2 + step * 0.04, 0.03) })
		end
		add({ theme.special[1] })
	elseif moment == "impact" then
		add({ L("thud", 0.95 - step * 0.06, 0.55 + step * 0.03) })
		if step >= 2 then
			add({ L("boom", 2.8 - step * 0.25, 0.16 + step * 0.03) })
		end
		add(theme.impact)
	elseif moment == "special" then
		add({ L("boom", 1 - step * 0.08, 0.4 + step * 0.03) })
		add(theme.special)
	elseif moment == "upgrade" then
		add({ L("boom", 0.55, 0.3), L("tick", 1.6, 0.35, 0.05), L("tick", 2, 0.35, 0.12), L("tick", 2.4, 0.4, 0.2) })
		add({ theme.special[1] })
	elseif moment == "idle" then
		add(IDLE[tier] or {})
	end
	return out
end

local function soundId(layer: Layer): string
	return (BUILTIN :: any)[layer.sound] or layer.sound
end

local function earshot(pos: Vector3): number?
	local cam = workspace.CurrentCamera
	if not cam then
		return 0
	end
	local d = (pos - cam.CFrame.Position).Magnitude
	return if d <= ROLL_MAX then d else nil
end

-- Plays `tier`'s `moment` at `at` (position or part). opts.own = your own sack (full volume), opts.volume scales it.
function SackSfx.play(tier: number, moment: Moment, at: Vector3 | Instance, opts: { own: boolean?, volume: number? }?)
	local pos = if typeof(at) == "Vector3"
		then at
		elseif typeof(at) == "Instance" and at:IsA("BasePart") then at.Position
		elseif typeof(at) == "Instance" and at:IsA("Model") then at:GetPivot().Position
		else nil
	if not pos or not earshot(pos) then
		return
	end
	local scale = (opts and opts.volume or 1) * (if opts and opts.own then 1 else OTHERS)
	local now = os.clock()
	for _, layer in SackSfx.layers(tier, moment) do
		local id = soundId(layer)
		local key = id .. string.format("%.2f", layer.pitch)
		if live >= MAX_LIVE or now - (lastPlayed[key] or 0) < REPEAT_GAP then
			continue
		end
		lastPlayed[key] = now
		live += 1
		task.delay(layer.delay or 0, function()
			local anchor = Pool.anchor(CFrame.new(pos))
			local s = Instance.new("Sound")
			s.SoundId = id
			s.PlaybackSpeed = layer.pitch * (1 + (math.random() - 0.5) * 0.06)
			s.Volume = layer.volume * scale
			s.RollOffMode = Enum.RollOffMode.InverseTapered
			s.RollOffMinDistance = ROLL_MIN
			s.RollOffMaxDistance = ROLL_MAX
			s.SoundGroup = master()
			s.Parent = anchor
			s:Play()
			task.delay(3, function()
				live -= 1
				s:Destroy()
				Pool.release(anchor)
			end)
		end)
	end
end

-- Starts `tier`'s ambient loop on `part` (premium sacks only). Returns a stop function (no-op if none) and a
-- setter that pauses it (e.g. while the sack's effect is hidden far away).
function SackSfx.idle(tier: number, part: BasePart): (() -> (), (on: boolean) -> ())
	local layers = SackSfx.layers(tier, "idle")
	if #layers == 0 then
		return function() end, function(_on: boolean) end
	end
	local sounds: { Sound } = {}
	for _, layer in layers do
		local s = Instance.new("Sound")
		s.Name = "SackIdle"
		s.SoundId = soundId(layer)
		s.PlaybackSpeed = layer.pitch
		s.Volume = layer.volume
		s.Looped = true
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = 6
		s.RollOffMaxDistance = 45
		s.SoundGroup = master()
		s.Parent = part
		s:Play()
		table.insert(sounds, s)
	end
	local playing = true
	return function()
		for _, s in sounds do
			s:Stop()
			Debris:AddItem(s, 0)
		end
		table.clear(sounds)
	end, function(on: boolean)
		if on == playing then
			return
		end
		playing = on
		for _, s in sounds do
			if on then
				s:Resume()
			else
				s:Pause()
			end
		end
	end
end

return SackSfx
