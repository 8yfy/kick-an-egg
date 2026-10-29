--!strict
-- The game's sound design, as DATA (Audio plays it; tests and tools/audio/render.py read it).
--
-- SOURCES: only the sounds that ship inside every Roblox client (rbxasset://sounds: never missing, nothing to
-- license). Measured with tools/audio (decoded, not guessed from file names):
--   thump  action_jump_land        0.17 s soft low-mid thud, 45 ms attack  -> every physical contact
--   tap1-4 action_footsteps_plastic one heel tap each (PlaybackRegion), 0.11 s, crisp -> clicks, knocks, cracks
--   tone   volume_slider           a clean pitched blip, fundamental ~393 Hz (G4) -> tuned chimes / sparkles
--   hop    action_jump             0.18 s tonal swish -> pops, boings
--   rumble action_get_up           95% sub-bass, 0.46 s -> ground rumble (avalanche), weight
--   wind   action_falling          a steady wind bed: a short slice with a fade = a whoosh; the loop = a roar
--   splash impact_water / bubble action_swim -> water, goo, mud
--   boom   impact_explosion_03     2.3 s, 68% sub-bass, 0 dBFS peak: THUNDER. Only storms / electricity
--                                  (Stormy mutation, Thunder Cell). Never an ordinary hit, kick or landing.
-- `gain` levels every source to the same peak (-10 dBFS) so a layer's `volume` means the same loudness for all.
--
-- TIERS (SoundBank.Tiers): 1 routine (clicks, contacts, ordinary punches) short + subtle, 2 satisfying (kicks,
-- placement, common hatches, upgrades), 3 exciting (perfect kicks, rare hatches, big upgrades), 4 spectacular
-- (Secret hatches, rebirths). Tests keep every recipe inside its tier's caps.
-- CATEGORIES = SoundGroups under SoundService.Master: UI (2D), Gameplay, Ambience, Music, SpecialEffects. A
-- layer with fx = true (magic on top of a physical sound) plays in SpecialEffects, so it can be turned down alone.
-- CUSTOM: SoundBank.CUSTOM[event] = { id = "rbxassetid://<uploaded, licensed sound>", volume = 0.5 } replaces
-- that event's layers (sack events are "Sack<tier>.<moment>"; docs/Audio.md lists the recordings still worth
-- getting). Never invent ids.

local SoundBank = {}

export type Category = "UI" | "Gameplay" | "Ambience" | "Music" | "SpecialEffects"
export type Layer = {
	src: string,
	pitch: number,
	volume: number,
	delay: number?,
	fx: boolean?, -- magical layer: SpecialEffects group
	eq: { number }?, -- {low, mid, high} dB (EqualizerSoundEffect)
	fade: { number }?, -- {in, out} seconds: volume swells in, fades out at the end
	length: number?, -- heard seconds before it fades out (for long sources)
	reverb: boolean?,
	tune: boolean?, -- transposed by opts.transpose semitones (zone ticks)
}
export type Event = {
	category: Category,
	tier: number,
	spatial: boolean, -- 3D (rolls off with distance) or 2D (UI)
	cooldown: number, -- seconds before the same event (and key) can play again
	voices: number, -- most copies playing at once
	jitter: number?, -- random pitch +- (variation for repeated sounds)
	rolloff: { number }?, -- {min, max} studs
	masked: boolean?, -- skipped right after a tier 3+ sound (a toast chime under a big fanfare)
	loop: boolean?,
	variants: { { Layer } },
}
export type Source = { id: string, gain: number, region: { number }?, length: number?, loop: boolean?, storm: boolean? }

local FOOT = "rbxasset://sounds/action_footsteps_plastic.mp3"
local FALL = "rbxasset://sounds/action_falling.ogg"
local SWIM = "rbxasset://sounds/action_swim.mp3"

SoundBank.Sources = {
	thump = { id = "rbxasset://sounds/action_jump_land.mp3", gain = 3.16, length = 0.26 },
	tap1 = { id = FOOT, gain = 2.4, region = { 0.044, 0.16 } },
	tap2 = { id = FOOT, gain = 3.98, region = { 0.637, 0.753 } },
	tap3 = { id = FOOT, gain = 1.33, region = { 1.233, 1.349 } },
	tap4 = { id = FOOT, gain = 2.95, region = { 1.834, 1.95 } },
	tone = { id = "rbxasset://sounds/volume_slider.ogg", gain = 0.56, region = { 0, 0.34 } },
	hop = { id = "rbxasset://sounds/action_jump.mp3", gain = 2.4, length = 0.34 },
	rumble = { id = "rbxasset://sounds/action_get_up.mp3", gain = 4.9, length = 0.57 },
	wind = { id = FALL, gain = 11.35, region = { 3, 4.5 } },
	windLoop = { id = FALL, gain = 11.35, loop = true },
	splash = { id = "rbxasset://sounds/impact_water.mp3", gain = 0.39, length = 2.38 },
	bubble = { id = SWIM, gain = 5.56, region = { 0.4, 1.4 } },
	bubbleLoop = { id = SWIM, gain = 5.56, loop = true },
	boom = { id = "rbxasset://sounds/impact_explosion_03.mp3", gain = 0.32, length = 2.59, storm = true },
} :: { [string]: Source }

-- Tier caps: loudest single layer, layers, length (s), summed layer volume.
SoundBank.Tiers = {
	{ maxVolume = 0.6, maxLayers = 3, maxSeconds = 0.6, maxSum = 1 },
	{ maxVolume = 0.85, maxLayers = 5, maxSeconds = 0.9, maxSum = 1.8 },
	{ maxVolume = 1, maxLayers = 9, maxSeconds = 1.6, maxSum = 3 },
	{ maxVolume = 1.2, maxLayers = 16, maxSeconds = 3.2, maxSum = 4.5 },
}
SoundBank.Categories = { "UI", "Gameplay", "Ambience", "Music", "SpecialEffects" } :: { Category }
-- id = the first (or only) asset; ids = variants (a different one each play); regions = per variant, the slice of
-- that asset to play (a sound sheet); tune = transposed like a tune layer; seconds = the sound's length (cleanup
-- and voice counting).
export type Custom = {
	id: string,
	ids: { string }?,
	regions: { { number } }?,
	volume: number?,
	tune: boolean?,
	seconds: number?,
}
SoundBank.CUSTOM = {} :: { [string]: Custom }

-- Musical notes for the `tone` source (fundamental ~393 Hz): PlaybackSpeed that plays that note.
local BASE_HZ = 393
local function note(hz: number): number
	return hz / BASE_HZ
end
local C5, E5, G5 = note(523.25), note(659.26), note(783.99)
local C6, E6, G6, A6 = note(1046.5), note(1318.51), note(1567.98), note(1760)
local C7, E7, G7 = note(2093), note(2637.02), note(3135.96)
SoundBank.Notes = { C5 = C5, E5 = E5, G5 = G5, C6 = C6, E6 = E6, G6 = G6, A6 = A6, C7 = C7, E7 = E7, G7 = G7 }

type Extra = {
	delay: number?,
	fx: boolean?,
	eq: { number }?,
	fade: { number }?,
	length: number?,
	reverb: boolean?,
	tune: boolean?,
}
local function L(src: string, pitch: number, volume: number, extra: Extra?): Layer
	local e: Extra = extra or {}
	return {
		src = src,
		pitch = pitch,
		volume = volume,
		delay = e.delay,
		fx = e.fx,
		eq = e.eq,
		fade = e.fade,
		length = e.length,
		reverb = e.reverb,
		tune = e.tune,
	}
end
-- a magic chime note (SpecialEffects)
local function chime(pitch: number, volume: number, delay: number?, reverb: boolean?): Layer
	return L("tone", pitch, volume, { delay = delay, fx = true, reverb = reverb })
end
local function whoosh(pitch: number, volume: number, seconds: number, delay: number?): Layer
	return L("wind", pitch, volume, { fade = { 0.02, seconds * 0.7 }, length = seconds, delay = delay })
end
SoundBank.L = L

-- Events ------------------------------------------------------------------------------------------------------
type EventExtra = { jitter: number?, rolloff: { number }?, masked: boolean?, loop: boolean? }
local function ev(
	category: Category,
	tier: number,
	spatial: boolean,
	cooldown: number,
	voices: number,
	variants: { { Layer } },
	extra: EventExtra?
): Event
	local e: EventExtra = extra or {}
	return {
		category = category,
		tier = tier,
		spatial = spatial,
		cooldown = cooldown,
		voices = voices,
		variants = variants,
		jitter = e.jitter or 0.04,
		rolloff = e.rolloff,
		masked = e.masked,
		loop = e.loop,
	}
end

local CRACK = { L("tap3", 2, 0.3), L("tap1", 2.6, 0.22, { delay = 0.03 }) }
local function with(base: { Layer }, more: { Layer }): { Layer }
	local out = table.clone(base)
	for _, l in more do
		table.insert(out, l)
	end
	return out
end

SoundBank.Events = {
	-- UI (2D) ---------------------------------------------------------------------------------------------------
	UIClick = ev("UI", 1, false, 0.035, 3, {
		{ L("tap1", 2.7, 0.2, { eq = { -8, 0, 0 } }) },
		{ L("tap3", 2.8, 0.18, { eq = { -8, 0, 0 } }) },
		{ L("tap4", 2.6, 0.2, { eq = { -8, 0, 0 } }) },
	}, { jitter = 0.05 }),
	UISuccess = ev("UI", 2, false, 0.25, 1, {
		{ chime(E6, 0.22), chime(G6, 0.24, 0.07), chime(C7, 0.24, 0.14) },
	}, { masked = true }),
	UIError = ev("UI", 1, false, 0.3, 1, { { L("tone", 0.92, 0.2), L("tone", 0.82, 0.18, { delay = 0.09 }) } }),
	MilestoneClaim = ev("UI", 3, false, 0.5, 1, {
		{
			chime(C6, 0.24),
			chime(E6, 0.25, 0.07),
			chime(G6, 0.26, 0.14),
			chime(C7, 0.3, 0.21),
			L("thump", 1, 0.2, { delay = 0.21 }),
		},
	}),
	Rebirth = ev("UI", 4, false, 2, 1, {
		{
			L("rumble", 0.8, 0.25, { fade = { 0.2, 0.5 } }),
			whoosh(1.3, 0.12, 0.8),
			chime(C5, 0.2, 0.1),
			chime(E5, 0.2, 0.2),
			chime(G5, 0.22, 0.3),
			chime(C6, 0.24, 0.4),
			chime(E6, 0.24, 0.5),
			chime(G6, 0.26, 0.6),
			chime(C7, 0.3, 0.7),
			L("thump", 0.7, 0.3, { delay = 0.7 }),
			chime(C7, 0.08, 1, true),
			chime(G7, 0.06, 1.1, true),
		},
	}),
	-- Kicks (3D at the foot) -------------------------------------------------------------------------------------
	KickWeak = ev("Gameplay", 1, true, 0.2, 2, {
		{ whoosh(1.5, 0.1, 0.15), L("thump", 0.82, 0.5), L("tap3", 0.95, 0.25) },
	}),
	KickGood = ev("Gameplay", 2, true, 0.2, 2, {
		{ whoosh(1.8, 0.16, 0.18), L("thump", 0.66, 0.7), L("tap3", 0.8, 0.42), L("thump", 1.15, 0.2) },
	}),
	KickPerfect = ev("Gameplay", 3, true, 0.2, 2, {
		{
			whoosh(2.1, 0.24, 0.2),
			L("thump", 0.62, 0.92),
			L("tap3", 0.76, 0.56),
			L("tap1", 1.5, 0.22, { delay = 0.005 }),
			chime(C6, 0.2, 0.05),
			chime(E6, 0.21, 0.1),
			chime(G6, 0.22, 0.15),
			chime(C7, 0.24, 0.2),
		},
	}),
	-- Flight + egg -----------------------------------------------------------------------------------------------
	ZoneEnter = ev("Gameplay", 1, true, 0.15, 2, {
		{ whoosh(2, 0.08, 0.2), L("tone", C6, 0.1, { tune = true, fx = true }) },
	}, { rolloff = { 20, 160 } }),
	SpinStop = ev("Gameplay", 2, true, 0.3, 1, {
		{ L("tap3", 1.7, 0.2), chime(G6, 0.14, 0.03) },
	}, { rolloff = { 20, 160 } }),
	LegsSprout = ev("Gameplay", 1, true, 0.3, 2, {
		{ L("hop", 1.7, 0.12), L("tap1", 2.5, 0.1, { delay = 0.07 }), L("tap3", 2.7, 0.08, { delay = 0.13 }) },
	}),
	EggStep = ev("Gameplay", 1, true, 0.08, 2, {
		{ L("tap1", 2, 0.07, { eq = { -4, 0, -6 } }) },
		{ L("tap2", 1.9, 0.07, { eq = { -4, 0, -6 } }) },
		{ L("tap3", 2.1, 0.06, { eq = { -4, 0, -6 } }) },
		{ L("tap4", 2, 0.07, { eq = { -4, 0, -6 } }) },
	}, { jitter = 0.06, rolloff = { 6, 50 } }),
	EggHold = ev("Gameplay", 1, true, 0.3, 1, { { L("tap2", 1.4, 0.14), L("hop", 1.3, 0.06) } }),
	EggPlace = ev("Gameplay", 2, true, 0.3, 2, { { L("tap3", 1.05, 0.3), L("thump", 1.15, 0.25) } }),
	EggSecured = ev("Gameplay", 3, true, 0.5, 1, {
		{ L("thump", 1, 0.3), chime(C6, 0.24), chime(E6, 0.25, 0.08), chime(G6, 0.26, 0.16), chime(C7, 0.28, 0.24) },
	}, { rolloff = { 20, 160 } }),
	EggCaught = ev("Gameplay", 2, true, 0.5, 1, {
		{
			L("tap1", 1.8, 0.36),
			L("tap3", 2.3, 0.28, { delay = 0.03 }),
			L("tap4", 1.5, 0.24, { delay = 0.07 }),
			L("thump", 0.8, 0.32),
		},
	}, { rolloff = { 20, 160 } }),
	-- Hatching + pets (3D at the pen) ----------------------------------------------------------------------------
	HatchCrack = ev("Gameplay", 1, true, 0.35, 3, {
		{ L("tap1", 2.3, 0.1), L("tap4", 2.9, 0.07, { delay = 0.04 }) },
		{ L("tap2", 2.5, 0.12), L("tap3", 3, 0.06, { delay = 0.05 }) },
	}, { jitter = 0.06, rolloff = { 8, 70 } }),
	HatchCommon = ev("Gameplay", 2, true, 0.3, 2, {
		with(
			CRACK,
			{ L("thump", 1.6, 0.38, { delay = 0.09 }), L("hop", 1.9, 0.12, { delay = 0.09 }), chime(G6, 0.1, 0.14) }
		),
	}, { rolloff = { 10, 90 } }),
	HatchRare = ev("Gameplay", 3, true, 0.3, 2, {
		with(CRACK, {
			L("thump", 1.5, 0.42, { delay = 0.09 }),
			L("hop", 1.8, 0.14, { delay = 0.09 }),
			chime(C6, 0.2, 0.14),
			chime(E6, 0.21, 0.21),
			chime(G6, 0.23, 0.28),
		}),
	}, { rolloff = { 10, 110 } }),
	HatchLegendary = ev("Gameplay", 3, true, 0.3, 2, {
		with(CRACK, {
			L("thump", 1.4, 0.45, { delay = 0.09 }),
			chime(C6, 0.22, 0.14),
			chime(E6, 0.23, 0.21),
			chime(G6, 0.24, 0.28),
			chime(C7, 0.26, 0.35),
			chime(E7, 0.1, 0.45, true),
			chime(G7, 0.08, 0.55, true),
		}),
	}, { rolloff = { 10, 140 } }),
	HatchSecret = ev("Gameplay", 4, true, 0.3, 1, {
		with(CRACK, {
			L("tap4", 1.7, 0.3, { delay = 0.07 }),
			L("rumble", 0.6, 0.3, { fade = { 0.15, 0.5 }, reverb = true }),
			L("thump", 1.4, 0.6, { delay = 0.12 }), -- the big pop: heavier than any common hatch
			L("thump", 0.95, 0.35, { delay = 0.12 }),
			L("hop", 1.6, 0.2, { delay = 0.12 }),
			chime(C6, 0.22, 0.2),
			chime(E6, 0.23, 0.3),
			chime(G6, 0.24, 0.4),
			chime(C7, 0.26, 0.5),
			chime(E7, 0.24, 0.6),
			chime(G7, 0.24, 0.7),
			chime(C7, 0.08, 1, true),
			chime(G7, 0.06, 1.15, true),
		}),
	}, { rolloff = { 10, 200 } }),
	PetPickup = ev(
		"Gameplay",
		1,
		true,
		0.25,
		2,
		{ { L("hop", 1.5, 0.12), chime(E6, 0.12, 0.02), chime(A6, 0.13, 0.08) } }
	),
	PetPlace = ev(
		"Gameplay",
		2,
		true,
		0.25,
		2,
		{ { L("tap3", 1.1, 0.28), L("thump", 1.2, 0.22), chime(C6, 0.08, 0.05) } }
	),
	MoneyChime = ev("Gameplay", 1, true, 2.5, 1, {
		{ L("tone", A6, 0.1), L("tone", E7, 0.11, { delay = 0.06 }) },
		{ L("tone", G6, 0.1), L("tone", note(2349.32), 0.1, { delay = 0.06 }) },
	}, { rolloff = { 8, 70 } }),
	-- Avalanche --------------------------------------------------------------------------------------------------
	AvalancheWarn = ev("Gameplay", 3, true, 1, 1, {
		{
			L("rumble", 0.55, 0.45, { fade = { 0.25, 0.5 } }),
			L("rumble", 0.45, 0.3, { delay = 0.3 }),
			whoosh(0.45, 0.14, 1.2),
		},
	}, { rolloff = { 30, 220 } }),
	AvalancheStart = ev("Gameplay", 3, true, 1, 1, {
		{ -- rocky (rock, lava, crystal, neon ...): the ground breaks
			L("rumble", 0.6, 0.55),
			L("tap3", 0.6, 0.38, { delay = 0.05 }),
			L("tap1", 0.7, 0.3, { delay = 0.12 }),
			L("tap4", 0.55, 0.28, { delay = 0.2 }),
			whoosh(0.6, 0.18, 0.8),
		},
		{ -- soft (snow, sand, coral, candy): a heavy whump and a rushing slide, no rock cracks
			L("rumble", 0.6, 0.55),
			L("thump", 0.55, 0.35, { delay = 0.04, eq = { 0, -2, -12 } }),
			whoosh(0.7, 0.24, 1),
		},
	}, { rolloff = { 30, 220 } }),
	AvalancheRoll = ev(
		"Ambience",
		2,
		true,
		0,
		2,
		{ { L("windLoop", 0.35, 0.22) } },
		{ rolloff = { 20, 140 }, loop = true }
	),
	AvalancheStop = ev("Gameplay", 2, true, 0.5, 1, {
		{
			L("rumble", 0.7, 0.3, { fade = { 0.02, 0.4 } }),
			L("tap3", 0.8, 0.2, { delay = 0.02 }),
			L("tap1", 0.9, 0.16, { delay = 0.09 }),
			L("tap4", 0.75, 0.14, { delay = 0.16 }),
		},
	}, { rolloff = { 20, 160 } }),
	-- Added with the Premium SFX set (PremiumSfx.luau). These built-in recipes are the fallbacks until the
	-- uploaded sounds are configured. --------------------------------------------------------------------------
	EggThrow = ev("Gameplay", 1, true, 0.2, 2, { { whoosh(2.4, 0.12, 0.25) } }, { rolloff = { 12, 120 } }),
	SpinTick = ev("Gameplay", 1, true, 0.03, 3, {
		{ L("tap1", 3.1, 0.05, { eq = { -8, 0, 0 } }) },
	}, { jitter = 0.04, rolloff = { 20, 160 } }),
	Toast = ev("UI", 1, false, 0.25, 1, { { chime(G6, 0.16), chime(C7, 0.14, 0.05) } }, { masked = true }),
	-- admin announcement line (UI/Hud/ServerMessage): a soft whoosh in, then a rising C-G-C chime
	Announcement = ev("UI", 2, false, 1, 1, {
		{ whoosh(1.5, 0.12, 0.3), chime(C6, 0.13, 0.08), chime(G6, 0.13, 0.15), chime(C7, 0.12, 0.23, true) },
	}),
	InventoryOpen = ev("UI", 1, false, 0.15, 1, { { L("hop", 1.8, 0.12), chime(C6, 0.1, 0.04) } }),
	InventoryClose = ev("UI", 1, false, 0.15, 1, { { L("hop", 1.35, 0.1) } }),
	Equip = ev("UI", 1, false, 0.08, 2, { { chime(C6, 0.14), chime(G6, 0.14, 0.045) } }),
	Unequip = ev("UI", 1, false, 0.08, 2, { { chime(G6, 0.12), chime(C6, 0.12, 0.045) } }),
	ShopPurchase = ev("UI", 3, false, 0.3, 1, {
		{ L("tone", A6, 0.18), L("tone", E7, 0.18, { delay = 0.055 }), chime(C7, 0.2, 0.11), L("thump", 1.2, 0.2) },
	}),
	SpeedUpgrade = ev("UI", 3, false, 0.3, 1, {
		{
			whoosh(2.2, 0.14, 0.3),
			chime(C6, 0.2, 0.14),
			chime(E6, 0.21, 0.18),
			chime(G6, 0.22, 0.22),
			chime(C7, 0.24, 0.26),
		},
	}),
	TreadmillUpgrade = ev("UI", 3, false, 0.3, 1, {
		{
			L("thump", 1, 0.25),
			L("hop", 1.4, 0.12),
			chime(G5, 0.2, 0.07),
			chime(C6, 0.21, 0.11),
			chime(E6, 0.22, 0.15),
		},
	}),
	PenUpgrade = ev("UI", 3, false, 0.3, 1, {
		{
			L("tap3", 1.1, 0.3),
			L("thump", 1.15, 0.25),
			L("tap3", 1.2, 0.3, { delay = 0.09 }),
			chime(C6, 0.2, 0.17),
			chime(G6, 0.22, 0.22),
			chime(C7, 0.24, 0.27),
		},
	}),
	TrainTick = ev("Gameplay", 1, true, 0.05, 2, { { L("tap1", 2.6, 0.06) } }, { jitter = 0.06, rolloff = { 6, 50 } }),
	StrengthMax = ev("UI", 3, false, 1, 1, {
		{
			whoosh(2, 0.12, 0.3),
			chime(C6, 0.2, 0.15),
			chime(E6, 0.21, 0.2),
			chime(G6, 0.22, 0.25),
			chime(C7, 0.24, 0.3),
			chime(E7, 0.1, 0.35, true),
		},
	}),
	TradeRequest = ev("UI", 2, false, 0.5, 1, { { chime(G6, 0.2), chime(C6, 0.2, 0.14) } }),
	TradeComplete = ev("UI", 2, false, 0.5, 1, {
		{
			chime(C6, 0.18),
			chime(E6, 0.19, 0.045),
			chime(G6, 0.2, 0.09),
			chime(C7, 0.22, 0.135),
			L("tone", A6, 0.12, { delay = 0.2 }),
		},
	}),
	MoneyCollect = ev("Gameplay", 2, true, 0.5, 1, {
		{
			L("tone", A6, 0.14),
			L("tone", E7, 0.14, { delay = 0.05 }),
			L("tone", A6 * 2, 0.12, { delay = 0.1 }),
			chime(C7, 0.14, 0.2),
		},
	}, { rolloff = { 8, 70 } }),
	WheelSpinStart = ev("UI", 2, false, 0.5, 1, { { whoosh(1.8, 0.14, 0.3), L("tap3", 1.4, 0.2) } }),
	WheelTick = ev("UI", 1, false, 0.02, 4, { { L("tap1", 2.9, 0.14, { eq = { -8, 0, 0 } }) } }, { jitter = 0.03 }),
	WheelWin = ev("UI", 3, false, 0.5, 1, {
		{
			chime(C6, 0.24),
			chime(E6, 0.25, 0.06),
			chime(G6, 0.26, 0.12),
			chime(C7, 0.28, 0.18),
			L("tone", A6, 0.14, { delay = 0.26 }),
		},
	}),
} :: { [string]: Event }

SoundBank.Events.GrandReward = SoundBank.Events.Rebirth -- every pet discovered: the same spectacular flourish
SoundBank.Events.WheelJackpot = ev("UI", 4, false, 1, 1, SoundBank.Events.Rebirth.variants)
SoundBank.SoftAvalanche = { Snow = true, Sand = true, Coral = true, Candy = true } :: { [string]: boolean }

function SoundBank.kickEvent(band: string?): string
	return if band == "perfect" then "KickPerfect" elseif band == "weak" then "KickWeak" else "KickGood"
end

function SoundBank.hatchEvent(rarity: string?): string
	if rarity == "Secret" then
		return "HatchSecret"
	elseif rarity == "Legendary" or rarity == "Mythic" or rarity == "Divine" then
		return "HatchLegendary"
	elseif rarity == "Rare" or rarity == "Epic" then
		return "HatchRare"
	end
	return "HatchCommon"
end

-- Egg landings ------------------------------------------------------------------------------------------------
-- Surface per zone (Config/Zones order); the plaza is grass. The map is plastic bricks, so the zone's theme
-- (not the part's Material) decides how the ground sounds.
SoundBank.ZoneSurface = {
	"grass", -- Meadow
	"sand", -- Sandy Beach
	"grass", -- Autumn Forest (leaf litter)
	"grass", -- Mushroom Grove (moss)
	"sand", -- Desert Dunes
	"snow", -- Snowy Peaks
	"candy", -- Candy Land
	"sand", -- Coral Reef
	"stone", -- Volcano
	"crystal", -- Crystal Caves
	"stone", -- Jungle Ruins
	"metal", -- Neon City
	"dirt", -- Haunted Graveyard
	"cloud", -- Sky Islands
	"mud", -- Toxic Swamp
	"metal", -- Clockwork Factory
	"ice", -- Frozen Aurora
	"stone", -- Lava Core
	"stone", -- Galaxy Void
	"cloud", -- Rainbow Heaven
}
SoundBank.Landing = { minSpeed = 6, hardSpeed = 70, cooldown = 0.12, reboundSpeed = 2 }

local SURFACE: { [string]: { land: { Layer }, bounce: { Layer } } } = {
	grass = { -- soft hollow thump
		land = { L("thump", 0.86, 0.55, { eq = { 0, 0, -10 } }), L("thump", 1.3, 0.15, { delay = 0.01 }) },
		bounce = { L("thump", 1.25, 0.32, { eq = { 0, 0, -8 } }), L("hop", 1.6, 0.08, { delay = 0.01 }) },
	},
	dirt = {
		land = { L("thump", 0.8, 0.5, { eq = { 0, -1, -12 } }), L("tap2", 0.6, 0.12, { eq = { 0, 0, -10 } }) },
		bounce = { L("thump", 1.2, 0.3, { eq = { 0, -1, -10 } }) },
	},
	sand = { -- muted
		land = { L("thump", 0.7, 0.5, { eq = { -2, -4, -18 } }), whoosh(3.2, 0.05, 0.15) },
		bounce = { L("thump", 1.05, 0.28, { eq = { -2, -4, -16 } }) },
	},
	snow = {
		land = {
			L("thump", 0.78, 0.45, { eq = { 0, -2, -12 } }),
			L("tap1", 1.5, 0.12, { eq = { -6, 0, -8 }, delay = 0.01 }),
		},
		bounce = { L("thump", 1.15, 0.28, { eq = { 0, -2, -12 } }), L("tap1", 1.9, 0.07) },
	},
	stone = { -- short solid contact
		land = { L("tap3", 0.92, 0.55), L("thump", 1.05, 0.42, { eq = { -4, 0, 0 } }) },
		bounce = { L("tap3", 1.35, 0.38), L("thump", 1.4, 0.18), L("hop", 1.7, 0.05) },
	},
	crystal = {
		land = { L("tap1", 1.6, 0.45), L("thump", 1.05, 0.35), chime(E7, 0.05, 0.01) },
		bounce = { L("tap1", 2, 0.32), L("thump", 1.4, 0.15), chime(G7, 0.04) },
	},
	ice = {
		land = { L("tap1", 1.75, 0.45), L("thump", 1.1, 0.35) },
		bounce = { L("tap1", 2.2, 0.32), L("thump", 1.45, 0.15) },
	},
	metal = {
		land = { L("tap3", 1.3, 0.5), L("thump", 1, 0.35), L("tone", 0.62, 0.06, { delay = 0.005 }) },
		bounce = { L("tap3", 1.7, 0.36), L("thump", 1.4, 0.15), L("tone", 0.8, 0.04) },
	},
	mud = {
		land = {
			L("thump", 0.7, 0.42, { eq = { 0, -2, -14 } }),
			L("splash", 1.4, 0.1, { length = 0.25, fade = { 0, 0.15 } }),
		},
		bounce = {
			L("thump", 1, 0.25, { eq = { 0, -2, -12 } }),
			L("splash", 1.8, 0.06, { length = 0.18, fade = { 0, 0.1 } }),
		},
	},
	candy = { -- soft and springy
		land = { L("thump", 0.95, 0.48, { eq = { 0, 0, -8 } }), L("hop", 1.45, 0.1, { delay = 0.01 }) },
		bounce = { L("thump", 1.35, 0.3), L("hop", 1.8, 0.1) },
	},
	cloud = {
		land = { L("thump", 0.9, 0.38, { eq = { 0, -3, -14 } }), whoosh(2.2, 0.06, 0.22) },
		bounce = { L("thump", 1.3, 0.22, { eq = { 0, -3, -12 } }), L("hop", 1.7, 0.06) },
	},
}
SoundBank.Surfaces = SURFACE

-- A quiet accent on top of the physical landing for weather-mutated eggs (SpecialEffects).
SoundBank.MutationAccent = {
	Sunny = { chime(G6, 0.07, 0.02), chime(C7, 0.05, 0.07) },
	Rainy = { L("splash", 1.9, 0.07, { length = 0.2, fade = { 0, 0.12 }, delay = 0.02, fx = true }) },
	Snowy = { L("tap1", 2.3, 0.07, { delay = 0.02, fx = true }), chime(E7, 0.04, 0.04) },
	-- storm: a short far-off thunder crack is the one place thunder belongs on an egg
	Stormy = {
		L("tap4", 3.2, 0.1, { delay = 0.02, fx = true }),
		L("boom", 3.4, 0.05, { delay = 0.05, length = 0.5, fade = { 0, 0.3 }, fx = true }),
	},
	Starfall = { chime(0.5, 0.1, 0.03, true), chime(C7, 0.04, 0.08) }, -- quiet cosmic resonance
	Rainbow = { chime(C7, 0.05, 0.02), chime(E7, 0.05, 0.06), chime(G7, 0.05, 0.1) },
} :: { [string]: { Layer } }

-- 0..1 from an impact speed (studs/s); nil = too soft to make a sound.
function SoundBank.landingIntensity(speed: number): number?
	local cfg = SoundBank.Landing
	if speed ~= speed or speed < cfg.minSpeed then
		return nil
	end
	return math.clamp((speed - cfg.minSpeed) / (cfg.hardSpeed - cfg.minSpeed), 0, 1)
end

-- The layers (and tier) of an egg touching `surface` at `intensity` 0..1. bounce = a short hop, not the final
-- landing. A hard landing gets punchier (lower, a weight layer), never a boom.
function SoundBank.landing(surface: string, intensity: number, bounce: boolean, mutation: string?): ({ Layer }, number)
	local set = SURFACE[surface] or SURFACE.grass
	local i = math.clamp(intensity, 0, 1)
	local volume = 0.45 + 0.55 * i
	local pitch = 1 - 0.06 * i
	local out: { Layer } = {}
	local source: { Layer } = if bounce then set.bounce else set.land
	for _, layer in source do
		local l: Layer = table.clone(layer)
		l.volume *= if bounce then volume * 1.15 else volume -- (bounce recipes are lighter: speed decides loudness)
		l.pitch *= pitch
		table.insert(out, l)
	end
	local minTier = 1
	if not bounce and i > 0.65 then
		table.insert(out, L("thump", 0.66, 0.28 * i, { eq = { 0, 0, -8 } }))
		minTier = 2
	end
	local accent = mutation and SoundBank.MutationAccent[mutation]
	if accent then
		for _, layer in accent do
			table.insert(out, layer)
		end
		minTier = math.max(minTier, 2)
	end
	return out, SoundBank.tierFor(out, minTier)
end

-- The ground under `pos`: the plaza (Z below the safe line + a margin) is grass, else the zone's surface.
function SoundBank.surfaceAt(pos: Vector3, zones: { { start: number, length: number } }, safeLineZ: number): string
	if pos.Z < safeLineZ + 6 then
		return "grass"
	end
	for id, zone in zones do
		if pos.Z >= zone.start and pos.Z < zone.start + zone.length then
			return SoundBank.ZoneSurface[id] or "grass"
		end
	end
	return SoundBank.ZoneSurface[#SoundBank.ZoneSurface] or "grass"
end

-- Contact detection for a physical egg from its vertical velocity (never from Touched): a contact is when it
-- was falling faster than Landing.minSpeed and the fall stops sharply. If it is already going up again right
-- after (faster than reboundSpeed) it bounced; otherwise that was the landing. Within `cooldown` of the last
-- contact nothing plays (contact chatter can't stack sounds).
export type ContactState = { vy: number, last: number }
function SoundBank.newContact(): ContactState
	return { vy = 0, last = -math.huge }
end
function SoundBank.contactStep(s: ContactState, _dt: number, vy: number, now: number): (string?, number)
	local cfg = SoundBank.Landing
	local kind: string? = nil
	local speed = -s.vy
	if s.vy < -cfg.minSpeed and vy > s.vy * 0.35 and now - s.last >= cfg.cooldown then
		kind = if vy > cfg.reboundSpeed then "bounce" else "land"
		s.last = now
	end
	s.vy = vy
	return kind, speed
end

-- Kick Sacks -------------------------------------------------------------------------------------------------
-- The physical body of each sack (Config/Upgrades.Sack.tiers order), then a theme accent where the sack's look
-- calls for magic. Ordinary punches: a dry fabric / leather thud. Never thunder (Thunder Cell excepted: it is
-- an electric sack, and only its super hit cracks).
SoundBank.SackMaterial = {
	"canvas", -- Burlap Sack
	"canvas", -- Gym Canvas
	"leather", -- Leather Classic
	"leather", -- Pro Red
	"rubber", -- Tire Stack
	"metal", -- Iron Plate
	"metal", -- Bronze Statue
	"metal", -- Silver Knight
	"leather", -- Gold Champion
	"ice", -- Ice Block
	"crystal", -- Crystal Geode
	"candy", -- Candy Smash
	"rock", -- Lava Core
	"metal", -- Thunder Cell
	"metal", -- Toxic Barrel
	"metal", -- Robo Bag
	"leather", -- Dragon Hide
	"leather", -- Galaxy Void
	"leather", -- Sun Guardian
	"leather", -- Rainbow God
}
local BODY: { [string]: { Layer } } = {
	canvas = { L("thump", 0.78, 0.55, { eq = { 0, -2, -6 } }), L("tap2", 0.7, 0.18) },
	leather = { L("thump", 0.82, 0.58), L("tap3", 0.85, 0.3) },
	rubber = { L("thump", 0.9, 0.55), L("hop", 1.3, 0.12) },
	metal = { L("tap3", 1.25, 0.45), L("thump", 0.9, 0.35), L("tone", 0.62, 0.07, { delay = 0.005 }) },
	ice = { L("tap1", 1.6, 0.4), L("thump", 1, 0.3) },
	crystal = { L("tap1", 1.8, 0.38), L("thump", 1, 0.28), chime(C7, 0.06, 0.01) },
	candy = { L("thump", 0.95, 0.5, { eq = { 0, 0, -8 } }), L("hop", 1.5, 0.12) },
	rock = { L("tap4", 0.75, 0.45), L("thump", 0.75, 0.45) },
}
SoundBank.SackBody = BODY
local function fxL(src: string, pitch: number, volume: number, extra: Extra?): Layer
	local l = L(src, pitch, volume, extra)
	l.fx = true
	return l
end
local ACCENT: { [string]: { hit: { Layer }, special: { Layer } } } = {
	chalk = { hit = {}, special = { fxL("wind", 2, 0.09, { fade = { 0.01, 0.2 }, length = 0.25 }) } },
	sweat = { hit = {}, special = { fxL("splash", 1.8, 0.08, { length = 0.3, fade = { 0, 0.2 } }) } },
	stars = { hit = { chime(G7, 0.04) }, special = { chime(C7, 0.06), chime(G7, 0.05, 0.05) } },
	sparks = {
		hit = { fxL("tap4", 3.4, 0.08), fxL("tap1", 3.9, 0.05, { delay = 0.03 }) },
		special = {
			fxL("tap4", 3.4, 0.1),
			fxL("tap1", 3.9, 0.08, { delay = 0.03 }),
			fxL("tap3", 3.6, 0.07, { delay = 0.06 }),
		},
	},
	glint = { hit = { chime(C7, 0.05) }, special = { chime(E7, 0.06), chime(C7, 0.05, 0.04) } },
	sparkle = {
		hit = { chime(E7, 0.04), chime(G7, 0.035, 0.04) },
		special = { chime(C7, 0.06), chime(E7, 0.06, 0.04), chime(G7, 0.06, 0.08) },
	},
	coins = {
		hit = { chime(A6, 0.06), chime(E7, 0.06, 0.05) },
		special = { chime(A6, 0.08), chime(E7, 0.08, 0.05), chime(A6 * 2, 0.06, 0.1) },
	},
	frost = { hit = { fxL("tap1", 2.6, 0.07) }, special = { fxL("tap1", 2.8, 0.1), chime(E7, 0.05, 0.03) } },
	crystal = { hit = {}, special = { chime(C7, 0.07), chime(G7, 0.06, 0.04), chime(E7, 0.05, 0.08) } },
	sprinkles = {
		hit = { fxL("tap2", 2.8, 0.06), fxL("tap3", 3.1, 0.05, { delay = 0.04 }) },
		special = {
			fxL("tap2", 2.8, 0.08),
			fxL("tap3", 3.1, 0.07, { delay = 0.04 }),
			fxL("tap1", 3.3, 0.06, { delay = 0.08 }),
		},
	},
	embers = {
		hit = { fxL("tap4", 3.6, 0.07) },
		special = {
			fxL("wind", 1.6, 0.08, { fade = { 0.01, 0.2 }, length = 0.3 }),
			fxL("tap4", 3.4, 0.08, { delay = 0.05 }),
		},
	},
	lightning = { -- electric: crackles; the super hit gets a short thunder crack (the one sack that may)
		hit = { fxL("tap1", 4, 0.08), fxL("tap4", 4.4, 0.06, { delay = 0.02 }) },
		special = {
			fxL("tap1", 4, 0.1),
			fxL("tap4", 4.6, 0.08, { delay = 0.03 }),
			fxL("boom", 3.2, 0.12, { length = 0.6, fade = { 0, 0.4 }, delay = 0.02 }),
		},
	},
	goo = {
		hit = { fxL("splash", 0.9, 0.06, { length = 0.2, fade = { 0, 0.12 } }) },
		special = { fxL("splash", 0.8, 0.1, { length = 0.35, fade = { 0, 0.2 } }) },
	},
	robo = {
		hit = { fxL("tone", 0.9, 0.05), fxL("tap2", 1.9, 0.06, { delay = 0.04 }) },
		special = {
			fxL("tone", 0.9, 0.07),
			fxL("tone", 1.2, 0.06, { delay = 0.06 }),
			fxL("tap2", 2, 0.07, { delay = 0.1 }),
		},
	},
	fire = {
		hit = { fxL("wind", 1.3, 0.07, { fade = { 0.01, 0.15 }, length = 0.2 }) },
		special = {
			fxL("wind", 1, 0.12, { fade = { 0.01, 0.3 }, length = 0.4 }),
			fxL("tap4", 3.4, 0.07, { delay = 0.06 }),
		},
	},
	cosmic = { -- Galaxy Void: a quiet cosmic resonance under the hit
		hit = { chime(0.5, 0.07, 0.01, true) },
		special = { chime(0.5, 0.12, 0.01, true), fxL("rumble", 0.9, 0.12), chime(C7, 0.04, 0.1) },
	},
	holy = { -- Sun Guardian: a warm, bright shimmer
		hit = { chime(C7, 0.05), chime(G7, 0.04, 0.03) },
		special = { chime(C6, 0.1), chime(G6, 0.1, 0.04), chime(C7, 0.1, 0.08) },
	},
	rainbow = { -- Rainbow God: physical hit + a short magical sparkle
		hit = { chime(C7, 0.05), chime(E7, 0.045, 0.04), chime(G7, 0.04, 0.08) },
		special = {
			chime(C6, 0.08),
			chime(E6, 0.08, 0.05),
			chime(G6, 0.08, 0.1),
			chime(C7, 0.09, 0.15),
			chime(E7, 0.07, 0.2),
		},
	},
}
SoundBank.SackAccent = ACCENT

-- Ambient loops of the premium sacks (Ambience, quiet, short range).
SoundBank.SackIdle = {
	[13] = { L("windLoop", 0.32, 0.12) }, -- Lava Core: low magma rumble
	[18] = { L("windLoop", 0.22, 0.14), L("bubbleLoop", 0.35, 0.05) }, -- Galaxy Void: deep cosmic hum
	[19] = { L("windLoop", 0.55, 0.1) }, -- Sun Guardian: warm solar hum
	[20] = { L("windLoop", 0.75, 0.08), L("bubbleLoop", 1.9, 0.05) }, -- Rainbow God: airy shimmer
} :: { [number]: { Layer } }

-- The layers and tier of `sackTier`'s `moment` ("equip" | "impact" | "special" | "upgrade" | "idle").
function SoundBank.sack(sackTier: number, moment: string, theme: string?): ({ Layer }, number)
	local material = SoundBank.SackMaterial[math.clamp(sackTier, 1, #SoundBank.SackMaterial)]
	local body = BODY[material] or BODY.canvas
	local accent = ACCENT[theme or ""]
	local out: { Layer } = {}
	local function add(list: { Layer }, scale: number?)
		for _, layer in list do
			local l = table.clone(layer)
			l.volume *= scale or 1
			table.insert(out, l)
		end
	end
	if moment == "impact" then -- an ordinary punch: tier 1, a little magic only where the look has it
		add(body)
		if accent then
			add(accent.hit)
		end
		return out, SoundBank.tierFor(out, 1)
	elseif moment == "special" then -- a super hit: heavier body + the theme's flourish
		add(body, 1.25)
		table.insert(out, L("thump", 0.62, 0.32, { eq = { 0, 0, -6 } }))
		if accent then
			add(accent.special)
		end
		return out, SoundBank.tierFor(out, 2)
	elseif moment == "equip" then -- the bag drops onto its chain
		add({ L("thump", 0.72, 0.42), L("tap2", 2.4, 0.07, { delay = 0.02 }), L("tap4", 2.8, 0.05, { delay = 0.07 }) })
		if material == "metal" then
			table.insert(out, L("tap3", 1.2, 0.18))
		end
		return out, 1
	elseif moment == "upgrade" then -- a new sack bought: a bright, satisfying flourish
		add({
			L("thump", 0.85, 0.3),
			chime(C6, 0.24),
			chime(E6, 0.25, 0.07),
			chime(G6, 0.26, 0.14),
			chime(C7, 0.28, 0.21),
		})
		if accent and accent.special[1] then
			add({ accent.special[1] })
		end
		return out, 3
	elseif moment == "idle" then
		add(SoundBank.SackIdle[sackTier] or {})
		return out, 1
	end
	return out, 1
end

-- Estimated heard length of a stack (seconds) and its loudest / summed layer volume.
function SoundBank.measure(layers: { Layer }): (number, number, number)
	local length, loudest, sum = 0, 0, 0
	for _, l in layers do
		local src = SoundBank.Sources[l.src]
		local raw = if l.length
			then l.length * l.pitch
			elseif src and src.region then src.region[2] - src.region[1]
			elseif src and src.length then src.length
			else 0.3
		length = math.max(length, (l.delay or 0) + raw / l.pitch)
		loudest = math.max(loudest, l.volume)
		sum += l.volume
	end
	return length, loudest, sum
end

-- The lowest tier (>= minTier) whose caps the stack fits: a composed stack (landing, sack hit) is only as big
-- as what it actually layers.
function SoundBank.tierFor(layers: { Layer }, minTier: number): number
	local length, loudest, sum = SoundBank.measure(layers)
	for t = math.max(1, minTier), #SoundBank.Tiers do
		local cap = SoundBank.Tiers[t]
		if #layers <= cap.maxLayers and loudest <= cap.maxVolume and length <= cap.maxSeconds and sum <= cap.maxSum then
			return t
		end
	end
	return #SoundBank.Tiers
end

-- The uploaded Premium SFX (Audio/PremiumSfx) replace their events: one-shots are regions of a sound sheet, loops
-- are their own files. An event whose file has no id yet keeps the recipe above.
local Premium = require(script.Parent.PremiumSfx)
local function premium(event: string, ids: { string }, regions: { { number } }?, seconds: number?)
	SoundBank.CUSTOM[event] = {
		id = ids[1],
		ids = ids,
		regions = regions,
		volume = Premium.volume * (Premium.gain[event] or 1),
		tune = Premium.tune[event],
		seconds = seconds,
	}
end
for event, list in Premium.regions do
	local ids, regions, seconds = {}, {}, 0
	for _, r in list do
		local sheet = Premium.sheets[r.sheet]
		if not sheet or sheet == "" then
			break
		end
		table.insert(ids, sheet)
		table.insert(regions, { r.from, r.to })
		seconds = math.max(seconds, r.to - r.from)
	end
	if #ids > 0 and #ids == #list then
		premium(event, ids, regions, seconds)
	end
end
for event, id in Premium.loops do
	if id ~= "" then
		premium(event, { id }, nil, nil)
	end
end

-- Pen feedback: short free Creator Store pop + pickup chime; isolated from the premium sound sheet.
-- Source/Studio playback verification: docs/PenUpgradeFeedback.md.
SoundBank.Sources.penPop = { id = "rbxassetid://6586979979", gain = 1, length = 0.24 }
SoundBank.Sources.penDing = { id = "rbxassetid://4612374393", gain = 1, length = 0.6 }
SoundBank.CUSTOM.PenUpgrade = nil
SoundBank.Events.PenUpgrade = ev("UI", 2, false, 0.05, 2, {
	{
		L("penPop", 1.05, 0.32, { length = 0.2, fade = { 0.005, 0.04 } }),
		L("penDing", 1.15, 0.22, { delay = 0.09, length = 0.55, fade = { 0.005, 0.12 } }),
	},
})

return SoundBank
