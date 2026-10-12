--!strict
-- Kick Sacks (Partner B): the 20 training sacks of Config/Upgrades.Sack.tiers as BlockBuilder data.
-- The models are the "Kick Sacks VFX Remodel" (web/sacks.js), converted part by part into blocks,
-- cylinders and balls (Tier01..Tier20, generated: do not edit by hand). 1 m of the remodel = SCALE studs.
--
-- Conventions:
--   * Origin = the hub where the four straps meet. The sack hangs below it and its front faces -Z (the
--     kicker); a short chain (or rope) rises to CHAIN_TOP, and the client continues it into the sky.
--     HANG = how high the hub sits above the ground, so the bag clears the floor.
--   * Part names are the remodel's mesh names: VFX/SackAura finds glowing parts and wings by them.
--   * vfxRoot(tier) is the bag bottom turned to the remodel's own axes (its +Z front), where the
--     tier's idle VFX are placed (VFX/SackAura).
local Builder = require(script.Parent.Parent.BlockBuilder)

type PartSpec = Builder.PartSpec
type Spec = Builder.Spec

export type Look = {
	chain: Color3, -- chain / rope colour (the client draws the rest of it up to the sky)
	rope: boolean, -- a rope instead of chain links
	fx: { Color3 }, -- VFX palette for hit bursts, main colour first
	theme: string, -- VFX/Sack extra per hit: dust, chalk, sweat, stars, rubber, sparks, glint, sparkle,
	-- coins, frost, crystal, sprinkles, embers, lightning, goo, robo, fire, cosmic, holy, rainbow
}

local rgb = Color3.fromRGB
local SCALE = 6.5
local HUB = 1.16 -- the remodel's hub height above the bag bottom (metres; the Tire Stack's is lower)

local Sacks = {}
Sacks.SCALE = SCALE
Sacks.RADIUS = 0.2 * SCALE -- bag radius in studs
Sacks.HANG = HUB * SCALE + 0.5 -- hub height above the ground: the bag bottom clears the floor by 0.5
Sacks.CENTER = (0.48 - HUB) * SCALE -- middle of the bag body, below the hub
Sacks.CHAIN_TOP = 0.49 * SCALE -- top of the model's own chain / rope above the hub
Sacks.KICK_DIST = Sacks.RADIUS + 2.05 -- player root to the sack axis: the kicking sole meets the bag

-- Hit-VFX looks (VFX/Sack): palette and theme per tier. The chain colour comes from the model.
local LOOKS: { Look } = {
	{ chain = rgb(160, 122, 69), rope = true, fx = { rgb(232, 224, 210), rgb(201, 164, 106) }, theme = "dust" },
	{ chain = rgb(154, 160, 170), rope = false, fx = { rgb(255, 255, 255), rgb(200, 57, 47) }, theme = "chalk" },
	{ chain = rgb(140, 143, 153), rope = false, fx = { rgb(150, 210, 255), rgb(216, 180, 90) }, theme = "sweat" },
	{ chain = rgb(200, 204, 212), rope = false, fx = { rgb(255, 225, 77), rgb(214, 47, 58) }, theme = "stars" },
	{ chain = rgb(160, 122, 69), rope = true, fx = { rgb(240, 196, 25), rgb(42, 42, 46) }, theme = "rubber" },
	{ chain = rgb(184, 190, 200), rope = false, fx = { rgb(255, 170, 60), rgb(255, 230, 120) }, theme = "sparks" },
	{ chain = rgb(217, 160, 102), rope = false, fx = { rgb(224, 163, 94), rgb(255, 210, 150) }, theme = "glint" },
	{ chain = rgb(230, 235, 242), rope = false, fx = { rgb(220, 235, 255), rgb(58, 111, 214) }, theme = "sparkle" },
	{ chain = rgb(255, 224, 138), rope = false, fx = { rgb(255, 216, 77), rgb(255, 241, 176) }, theme = "coins" },
	{ chain = rgb(207, 233, 255), rope = false, fx = { rgb(168, 220, 255), rgb(255, 255, 255) }, theme = "frost" },
	{ chain = rgb(201, 168, 255), rope = false, fx = { rgb(210, 155, 255), rgb(143, 230, 255) }, theme = "crystal" },
	{
		chain = rgb(255, 90, 160),
		rope = false,
		fx = { rgb(255, 138, 196), rgb(125, 255, 138), rgb(255, 225, 77), rgb(72, 216, 255) },
		theme = "sprinkles",
	},
	{
		chain = rgb(90, 58, 48),
		rope = false,
		fx = { rgb(255, 122, 30), rgb(255, 176, 46), rgb(60, 30, 20) },
		theme = "embers",
	},
	{ chain = rgb(127, 216, 255), rope = false, fx = { rgb(72, 216, 255), rgb(255, 243, 107) }, theme = "lightning" },
	{ chain = rgb(154, 160, 170), rope = false, fx = { rgb(182, 255, 46), rgb(90, 160, 30) }, theme = "goo" },
	{ chain = rgb(230, 235, 242), rope = false, fx = { rgb(72, 255, 210), rgb(255, 74, 90) }, theme = "robo" },
	{
		chain = rgb(217, 160, 102),
		rope = false,
		fx = { rgb(255, 120, 30), rgb(255, 210, 80), rgb(179, 38, 30) },
		theme = "fire",
	},
	{
		chain = rgb(185, 140, 255),
		rope = false,
		fx = { rgb(185, 140, 255), rgb(208, 74, 160), rgb(72, 216, 255) },
		theme = "cosmic",
	},
	{
		chain = rgb(255, 224, 138),
		rope = false,
		fx = { rgb(255, 241, 176), rgb(255, 216, 77), rgb(255, 255, 255) },
		theme = "holy",
	},
	{
		chain = rgb(255, 216, 77),
		rope = false,
		fx = {
			rgb(255, 90, 90),
			rgb(255, 155, 61),
			rgb(255, 225, 77),
			rgb(98, 224, 107),
			rgb(72, 200, 255),
			rgb(107, 125, 255),
			rgb(180, 107, 255),
		},
		theme = "rainbow",
	},
}

local SHAPES: { [string]: string } = { C = "Cylinder", S = "Ball" }
local data: { [number]: any } = {}
local specs: { [number]: Spec } = {}
local looks: { [number]: Look } = {}

local function tierData(tier: number): any
	local t = math.clamp(tier, 1, #LOOKS)
	local d = data[t]
	if not d then
		d = require(script:FindFirstChild(string.format("Tier%02d", t)) :: ModuleScript) :: any
		data[t] = d
	end
	return d
end

Sacks.count = #LOOKS

function Sacks.spec(tier: number): Spec
	local t = math.clamp(tier, 1, #LOOKS)
	local cached = specs[t]
	if cached then
		return cached
	end
	local parts: { PartSpec } = {}
	for _, row in tierData(t).parts do
		table.insert(parts, {
			name = row[1],
			shape = SHAPES[row[2]],
			size = row[3],
			pos = row[4],
			rot = row[5],
			color = Color3.fromHex(row[6]),
			material = row[7],
			transparency = if row[8] > 0 then row[8] else nil,
			studs = false,
		})
	end
	local spec: Spec = { parts = parts }
	specs[t] = spec
	return spec
end

function Sacks.look(tier: number): Look
	local t = math.clamp(tier, 1, #LOOKS)
	local cached = looks[t]
	if cached then
		return cached
	end
	local look = table.clone(LOOKS[t])
	for _, row in tierData(t).parts do
		if row[1] == "chain_link_0" or row[1] == "rope" then
			look.chain = Color3.fromHex(row[6])
			break
		end
	end
	looks[t] = look
	return look
end

-- Bag bottom in model space, turned so the remodel's front (+Z) faces the sack's front (-Z).
function Sacks.vfxRoot(tier: number): CFrame
	return CFrame.new(0, -tierData(tier).hub * SCALE, 0) * CFrame.Angles(0, math.pi, 0)
end

return Sacks
