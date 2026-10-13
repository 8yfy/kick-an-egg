--!strict
-- The black MYSTERY EGG players hold at the kick line (a kick-line visual only: it is NOT an inventory egg and
-- never becomes one). Classic blocky egg (Sculpt.eggShell: stepped square layers, studded), glossy black with a
-- dark-violet band, and a big glowing gold "?" made of blocks on its front (-Z) face, plus a soft glow.
-- MysteryEgg.build() -> Model (BlockBuilder rig, feet at y = 0, PrimaryPart = Root).
local Builder = require(script.Parent.Parent.BlockBuilder)
local Sculpt = require(script.Parent.Sculpt)

local MysteryEgg = {}

local H, W = 2.6, 2
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
	-- the "?" on the front face: pixel size 0.2, centred around 58% of the height
	local px = 0.2
	local top = H * 0.58 + px * 3
	for row, line in GLYPH do
		local y = top - (row - 1) * px
		local r = Sculpt.eggRadius(H, W, y)
		for col = 1, 5 do
			if string.sub(line, col, col) == "#" then
				local x = (col - 3) * px
				table.insert(
					parts,
					Sculpt.at(
						"Mark",
						{ px, px, 0.12 },
						CFrame.new(x, y, -(r + 0.05)),
						GOLD,
						{ material = "Neon", joint = "Body", studs = false } :: any
					)
				)
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
