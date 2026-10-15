--!strict
-- The black MYSTERY EGG players hold at the kick line (a kick-line visual only: it is NOT an inventory egg and
-- never becomes one). Classic blocky egg (Sculpt.eggShell: stepped square layers, studded), glossy black with a
-- dark-violet neon band with gold rivets, a gold cap + violet gem, and a big glowing raised gold "?" on a dark
-- plate on BOTH faces, plus a soft glow. Full egg size (3.4 studs, like the game's eggs).
-- MysteryEgg.build() -> Model (BlockBuilder rig, feet at y = 0, PrimaryPart = Root).
local Builder = require(script.Parent.Parent.BlockBuilder)
local Sculpt = require(script.Parent.Sculpt)

local MysteryEgg = {}

local H, W = 3.4, 2.6 -- full egg size (ordinary eggs are this scale), held in both hands
local BLACK = Color3.fromRGB(28, 28, 34)
local BLACK_HI = Color3.fromRGB(44, 44, 54)
local BAND = Color3.fromRGB(120, 60, 200)
local GOLD = Color3.fromRGB(255, 205, 60)

-- 5 x 7 pixel "?" (top row first)
local GLYPH = {
	".###.",
	"#...#",
	"....#",
	"...#.",
	"..#..",
	".....",
	"..#..",
}

function MysteryEgg.spec(): Builder.Spec
	local parts: { Builder.PartSpec } = {} -- (BlockBuilder adds the Root at the feet)
	for _, p in
		Sculpt.eggShell(H, W, function(i: number)
			return if i % 2 == 0 then BLACK_HI else BLACK
		end, { joint = "Body" } :: any)
	do
		table.insert(parts, p)
	end
	table.insert(
		parts,
		Sculpt.eggBand("Band", H, W, H * 0.3, 0.22, 0.06, BAND, { material = "Neon", joint = "Body" } :: any)
	)
	-- gold rivets around the band
	for i = 0, 7 do
		local a = i * math.pi / 4
		local y = H * 0.3
		local r = Sculpt.eggRadius(H, W, y) + 0.08
		table.insert(
			parts,
			Sculpt.at(
				"Rivet",
				{ 0.22, 0.22, 0.22 },
				CFrame.new(math.sin(a) * r, y, math.cos(a) * r),
				GOLD,
				{ joint = "Body", studs = false } :: any
			)
		)
	end
	-- a gold cap with a violet gem on top
	table.insert(
		parts,
		Sculpt.at("Cap", { 0.7, 0.18, 0.7 }, CFrame.new(0, H - 0.05, 0), GOLD, { joint = "Body", studs = false } :: any)
	)
	table.insert(
		parts,
		Sculpt.at(
			"Gem",
			{ 0.36, 0.36, 0.36 },
			CFrame.new(0, H + 0.18, 0) * CFrame.Angles(0, math.rad(45), math.rad(45)),
			BAND,
			{ material = "Neon", joint = "Body", studs = false } :: any
		)
	)
	-- the big "?" on both faces: pixel 0.3, raised 0.2, on a dark backing plate, centred at 60% of the height
	local px = 0.3
	local top = H * 0.6 + px * 3
	for _, side in { -1, 1 } do
		local rMid = Sculpt.eggRadius(H, W, H * 0.6)
		table.insert(
			parts,
			Sculpt.at(
				"Plate",
				{ px * 6.2, px * 8.2, 0.1 },
				CFrame.new(0, H * 0.6, side * (rMid + 0.02)),
				Color3.fromRGB(12, 12, 16),
				{ joint = "Body", studs = false } :: any
			)
		)
		for row, line in GLYPH do
			local y = top - (row - 1) * px
			local r = Sculpt.eggRadius(H, W, y)
			for col = 1, 5 do
				if string.sub(line, col, col) == "#" then
					local x = (col - 3) * px * -side
					table.insert(
						parts,
						Sculpt.at(
							"Mark",
							{ px, px, 0.2 },
							CFrame.new(x, y, side * (math.max(r, rMid) + 0.1)),
							GOLD,
							{ material = "Neon", joint = "Body", studs = false } :: any
						)
					)
				end
			end
		end
	end
	return { parts = parts }
end

function MysteryEgg.build(): Model
	local model = Builder.build(MysteryEgg.spec(), "MysteryEgg")
	local root = model.PrimaryPart
	if root then
		local glow = Instance.new("PointLight")
		glow.Color = Color3.fromRGB(170, 110, 255)
		glow.Range = 7
		glow.Brightness = 1.2
		glow.Shadows = false
		glow.Parent = root
	end
	return model
end

return MysteryEgg
