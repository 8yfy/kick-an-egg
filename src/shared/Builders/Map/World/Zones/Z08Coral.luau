--!strict
-- Partner A. Zone 8, Coral Reef (z 700..800): a shallow turquoise lagoon over pale sea sand on both sides of the
-- track (a translucent water sheet with a rippling surface above the reef), the Sunken Galleon run aground on the
-- right with its masts and sails above the water, a giant clam with a glowing pearl, coral gardens in four colour
-- sets (brain, branch, fan), swaying kelp, anemones, a treasure chest, reef rocks. Ambience: rising bubbles.
local CollectionService = game:GetService("CollectionService")

local Kit = require(script.Parent.Parent.Kit)
local Valley = require(script.Parent.Parent.Valley)
local Palettes = require(script.Parent.Parent.Palettes)
local Parts = require(script.Parent.Parent.Parts)

local rgb = Color3.fromRGB

local CORALS = {
	{ "BrainCoral", 2, 1.6, 2.4 },
	{ "BranchCoral", 3, 1.6, 2.3 },
	{ "FanCoral", 2, 1.6, 2.2 },
	{ "Anemone", 2, 1.8, 2.4 },
}
local COVER =
	{ { "Shell", 3, 1.0, 1.4 }, { "Starfish", 2, 1.0, 1.4 }, { "Anemone", 1, 0.6, 0.8 }, { "BrainCoral", 1, 0.4, 0.6 } }

return function(zone: any, parent: Instance)
	local PAL = Palettes.zones[8]
	local ctx = Valley.new(zone, parent, PAL)
	local function coral(): any
		return Palettes.corals[ctx.rng:NextInteger(1, #Palettes.corals)]
	end
	local H = 2
	local SURFACE = 6.2
	for _, side in { -1, 1 } do
		Valley.plateau(ctx, side, H, PAL.Ground :: Color3, PAL.StoneDark :: Color3)
		Valley.banks(ctx, side, { "BankB", "BankD" }, 5, { depth = 14 })
		-- the lagoon water over the reef, rippling
		local len = ctx.z1 - ctx.z0
		local sheet = Parts.block(
			ctx.terrain,
			"Lagoon",
			Vector3.new(Valley.FAR_X - 56, 0.4, len),
			CFrame.new(side * (56 + Valley.FAR_X) / 2, SURFACE, ctx.zm),
			rgb(40, 190, 230),
			{
				smooth = true,
				collide = false,
				query = false,
				transparency = 0.62,
				material = Enum.Material.Glass,
				shadow = false,
			}
		)
		local tex = Instance.new("Texture")
		tex.Texture = "rbxassetid://90860129869797" -- VFX/WorldSprites.streak: ripple lines
		tex.Face = Enum.NormalId.Top
		tex.StudsPerTileU, tex.StudsPerTileV = 16, 6
		tex.Transparency = 0.6
		tex:SetAttribute("SpeedU", side * 1.2)
		CollectionService:AddTag(tex, "WorldScroll")
		tex.Parent = sheet
	end

	-- the Sunken Galleon (right), aground on reef rocks
	local sx, sz = 120, 752
	Valley.keepOut(ctx, sx, sz, 34)
	Kit.place(ctx.props, "SunkenShip", Kit.at(sx, H, sz, 30), 1.55, PAL)
	Parts.light(
		Parts.anchor(ctx.props, "ShipGlow", Vector3.one, Vector3.new(sx, H + 12, sz + 24)),
		rgb(255, 210, 140),
		24,
		0.9
	)
	-- the giant clam (left) with its glowing pearl, and a treasure chest
	Valley.keepOut(ctx, -92, 742, 14)
	Kit.place(ctx.props, "GiantClam", Kit.at(-92, H, 742, -70), 2.4, coral())
	Parts.light(
		Parts.anchor(ctx.props, "PearlGlow", Vector3.one, Vector3.new(-92, H + 8, 742)),
		rgb(140, 240, 255),
		20,
		1.2
	)
	Kit.place(ctx.props, "TreasureChest", Kit.at(84, H, 712, 60), 1.2, PAL)

	-- coral gardens and kelp forests
	for _, c in
		{
			{ -66, 712, 4 },
			{ -140, 712, 5 },
			{ -170, 770, 4 },
			{ -70, 790, 3 },
			{ 70, 790, 3 },
			{ 180, 712, 4 },
			{ 220, 780, 5 },
		}
	do
		for _ = 1, c[3] do
			Valley.cluster(
				ctx,
				ctx.nature,
				c[1] + ctx.rng:NextNumber(-7, 7),
				c[2] + ctx.rng:NextNumber(-7, 7),
				CORALS,
				1,
				1,
				coral()
			)
		end
	end
	for _, side in { -1, 1 } do
		Valley.scatter(
			ctx,
			ctx.nature,
			side,
			{ { "Kelp", 1, 0.9, 1.3 } },
			12,
			{ Valley.INNER + 10, 200 },
			8,
			PAL,
			nil,
			true
		)
		Valley.scatter(
			ctx,
			ctx.nature,
			side,
			{ { "RockB", 1, 0.8, 1.2 }, { "RockA", 1, 0.8, 1.1 } },
			4,
			{ Valley.INNER + 10, 200 },
			14,
			PAL
		)
	end
	Valley.shoulders(ctx, COVER, 18, PAL)

	-- far: a reef rock ridge and clouds over open water
	for _, side in { -1, 1 } do
		Valley.farRow(ctx, side, { { "SlabB", 300, 720, 3 }, { "RockD", 360, 780, 3 } }, PAL)
	end
	for i, c in { { -300, 760, "CloudB" }, { 320, 730, "CloudA" } } do
		Kit.place(
			ctx.far,
			c[3] :: string,
			Kit.at(c[1] :: number, 70 + i * 10, c[2] :: number, i * 50),
			1.4,
			PAL,
			{ shadow = false }
		)
	end

	-- ambience: bubbles rising through the lagoon, sparkles on its surface
	Valley.fx(ctx, "Bubbles", -1, 110, 150, H + 2, 4, nil, 1.4)
	Valley.fx(ctx, "Bubbles", 1, 110, 150, H + 2, 4, nil, 1.4)
	Valley.fx(ctx, "Bubbles", 0, 0, 70, 1, 1, nil, 0.8)
	Valley.fx(ctx, "Sparkle", -1, 120, 160, SURFACE + 0.6, 1, { rgb(230, 250, 255) }, 2, 220)
	Valley.fx(ctx, "Sparkle", 1, 120, 160, SURFACE + 0.6, 1, { rgb(230, 250, 255) }, 2, 220)

	-- hand-over: candy at the start, volcano at the end
	Valley.blend(ctx, { { "Gumdrop", 2, 0.9, 1.1 }, { "LollipopTree", 1, 0.7, 0.9 } }, Palettes.zones[7], true, 3)
	Valley.blend(ctx, { { "LavaRock", 1, 0.7, 0.9 }, { "BasaltColumns", 1, 0.7, 0.9 } }, Palettes.zones[9], false, 3)
end
