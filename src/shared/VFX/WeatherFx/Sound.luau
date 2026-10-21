--!strict
-- Partner A. Weather sounds (client only). User decision 2026-10-17: ONLY the rainy weathers make sound (Rainy, Stormy);
-- no start cues, no beds or accents for the others, and no generated sounds: real recordings found in the Creator Store.
-- All of them come from Roblox's licensed Pro Sound Effects library (creator "ProSoundEffects", free, "Courtesy of Pro
-- Sound Effects"), each verified in Studio to load (ContentProvider Success, IsLoaded, length below). Never invent ids.
--   beds: looping rain (2D, Ambience group), crossfaded by the visual mixer (Volume = bed volume x layer weight),
--         started at a random point so it never sounds like the same loop restarting.
--   oneShots: distant thunder, played 3D at the lightning strike with a distance delay (WeatherFx/Elements bolts).
-- Volumes were set against the game's own avalanche loop (PlaybackLoudness: rain beds sit well below gameplay).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local WeatherSound = {}

export type Bed = { id: string, volume: number, source: string }
export type OneShot = { ids: { string }, volume: number, source: string }

WeatherSound.beds = {
	-- Rainy: steady outdoor rain, no thunder ("Heavy Rain, On Concrete, Medium and CU Plops ... Loop", 67 s)
	Rain_Light = { id = "rbxassetid://9112793875", volume = 0.6, source = "ProSoundEffects: Heavy Rain 3 (SFX)" },
	-- Stormy: heavy rainfall on grass and a wooden roof with low rolling thunder (46 s loop)
	Rain_Storm = {
		id = "rbxassetid://9112853422",
		volume = 0.4,
		source = "ProSoundEffects: Rain Heavy Rainfall Grass Wooden Roof 1 (SFX)",
	},
} :: { [string]: Bed }

WeatherSound.oneShots = {
	-- "Thunder, Distant Boom or Thud, Rapid Hits, Long Decay, Deep Rumble" (4.5 / 5.9 / 4.3 s): far, never a sharp crack
	Thunder_Far = {
		ids = { "rbxassetid://9120018172", "rbxassetid://9120018216", "rbxassetid://9120018050" },
		volume = 0.8,
		source = "ProSoundEffects: Thunder Distant Boom Thud Rapid Hits 20 / 21 / 15 (SFX)",
	},
} :: { [string]: OneShot }

local rng = Random.new()
local Audio: any = nil
local function audio(): any
	if not Audio then
		Audio = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Audio"))
	end
	return Audio
end

-- A looping bed at volume 0 (the mixer sets Volume = WeatherSound.bedVolume(key) * weight), or nil for no sound.
function WeatherSound.bed(key: string?, parent: Instance): Sound?
	local bed = if key then WeatherSound.beds[key] else nil
	if not bed then
		return nil
	end
	local s = Instance.new("Sound")
	s.Name = key :: string
	s.SoundId = bed.id
	s.Looped = true
	s.Volume = 0
	s.SoundGroup = audio().group("Ambience")
	s.Parent = parent
	task.spawn(function()
		if not s.IsLoaded then
			s.Loaded:Wait()
		end
		if s.Parent then
			s.TimePosition = rng:NextNumber(0, math.max(s.TimeLength - 1, 0))
			s:Play()
		end
	end)
	return s
end

function WeatherSound.bedVolume(key: string?): number
	local bed = if key then WeatherSound.beds[key] else nil
	return if bed then bed.volume else 0
end

-- A one-shot: 2D when `at` is nil, else 3D at that point (after `delay` seconds). Unknown keys are silent.
export type PlayOpts = { delay: number?, category: string?, volume: number?, far: number? }

function WeatherSound.play(key: string, at: Vector3?, opts: PlayOpts?)
	if not RunService:IsClient() then
		return
	end
	local shot = WeatherSound.oneShots[key]
	if not shot or #shot.ids == 0 then
		return
	end
	local o: PlayOpts = opts or {}
	local function go()
		local s = Instance.new("Sound")
		s.Name = key
		s.SoundId = shot.ids[rng:NextInteger(1, #shot.ids)]
		s.Volume = o.volume or shot.volume
		s.PlaybackSpeed = 1 + rng:NextNumber(-0.04, 0.04)
		s.SoundGroup = audio().group(o.category or "Ambience")
		local holder: Instance
		if at then
			local a = Instance.new("Attachment")
			a.Name = "WeatherSound"
			a.WorldPosition = at
			a.Parent = workspace.Terrain
			s.RollOffMode = Enum.RollOffMode.InverseTapered
			s.RollOffMinDistance = if o.far then o.far * 0.25 else 30
			s.RollOffMaxDistance = o.far or 260
			holder = a
		else
			holder = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui") or workspace
		end
		s.Parent = holder
		s.Ended:Once(function()
			if at then
				holder:Destroy()
			else
				s:Destroy()
			end
		end)
		s:Play()
		task.delay(15, function() -- fallback if Ended never fires (sound failed to load)
			if s.Parent then
				if at then
					holder:Destroy()
				else
					s:Destroy()
				end
			end
		end)
	end
	if o.delay and o.delay > 0 then
		task.delay(o.delay, go)
	else
		go()
	end
end

return WeatherSound
