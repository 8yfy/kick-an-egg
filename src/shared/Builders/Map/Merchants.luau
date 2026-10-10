--!strict
-- Market merchants: blocky NPCs that stand behind the shop counters. Merchants.build(kind, parent, feet)
-- puts the merchant's feet at `feet`, facing its LookVector (toward customers). The model carries
-- attributes for the client (MapLifeController): Merchant (name), Greeting (speech bubble text).
-- PrimaryPart "Root" (invisible, at the feet) is what the client bobs and turns.
local Bricks = require(script.Parent.Bricks)

local P, cyl, ball = Bricks.part, Bricks.cyl, Bricks.ball
local rgb = Color3.fromRGB
local SKIN = rgb(255, 205, 150)
local NO = { collide = false }

local Merchants = {}

type Kind = "Coach" | "Professor"

local function body(m: Model, at: (number, number, number) -> CFrame, pants: Color3, shirt: Color3, shoes: Color3)
	for _, x in { -0.75, 0.75 } do
		P(m, "Leg", Vector3.new(1.3, 3, 1.3), at(x, 1.9, 0), pants, NO)
		P(m, "Shoe", Vector3.new(1.4, 0.8, 1.9), at(x, 0.4, -0.25), shoes, NO)
	end
	P(m, "Torso", Vector3.new(3, 3.2, 1.6), at(0, 5, 0), shirt, NO)
	for _, x in { -2.1, 2.1 } do
		P(m, "Arm", Vector3.new(1.1, 3, 1.2), at(x, 5, 0), shirt, NO)
		P(m, "Hand", Vector3.new(1, 0.9, 1), at(x, 3.1, 0), SKIN, NO)
	end
end

local BUILD: { [Kind]: (Model, (number, number, number) -> CFrame) -> () } = {
	Coach = function(m, at)
		local red, white = rgb(230, 50, 50), rgb(250, 250, 250)
		body(m, at, red, red, white)
		P(m, "Stripe", Vector3.new(3.05, 0.4, 1.65), at(0, 5.6, 0), white, NO)
		P(m, "Head", Vector3.new(2.2, 2.2, 2.2), at(0, 7.7, 0), SKIN, NO)
		P(m, "Headband", Vector3.new(2.3, 0.5, 2.3), at(0, 8.3, 0), white, NO)
		P(m, "Hair", Vector3.new(2.3, 0.6, 2.3), at(0, 9.05, 0.1), rgb(70, 45, 30), NO)
		P(m, "Mustache", Vector3.new(1.6, 0.35, 0.3), at(0, 7.35, -1.15), rgb(70, 45, 30), NO)
		for _, x in { -0.5, 0.5 } do
			P(m, "Eye", Vector3.new(0.3, 0.4, 0.1), at(x, 7.95, -1.12), rgb(25, 25, 35), NO)
		end
		P(m, "Lanyard", Vector3.new(0.15, 1.6, 0.15), at(0, 5.8, -0.85), white, NO)
		local whistle = P(
			m,
			"Whistle",
			Vector3.new(0.6, 0.4, 0.6),
			at(0, 4.9, -0.95),
			rgb(255, 210, 60),
			{ collide = false, material = Enum.Material.Neon }
		)
		Bricks.light(whistle, rgb(255, 220, 120), 6, 0.5)
	end,
	Professor = function(m, at)
		local robe = rgb(110, 70, 170)
		body(m, at, robe, robe, rgb(60, 40, 90))
		P(m, "Robe", Vector3.new(3.4, 3.4, 2), at(0, 2.3, 0), robe, NO)
		P(m, "Trim", Vector3.new(3.45, 0.4, 2.05), at(0, 0.8, 0), rgb(255, 210, 60), NO)
		ball(m, "Head", 3, at(0, 8.2, 0), rgb(255, 245, 215), NO)
		cyl(m, "HeadTop", 1.6, 2.4, at(0, 9.3, 0), rgb(255, 245, 215), NO)
		for _, x in { -0.65, 0.65 } do
			cyl(m, "Lens", 0.15, 1, at(x, 8.4, -1.42) * CFrame.Angles(math.rad(90), 0, 0), rgb(30, 30, 40), NO)
			P(m, "Eye", Vector3.new(0.3, 0.3, 0.1), at(x, 8.4, -1.5), rgb(25, 25, 35), NO)
		end
		P(m, "Bridge", Vector3.new(0.4, 0.12, 0.12), at(0, 8.45, -1.45), rgb(30, 30, 40), NO)
		P(m, "Beard", Vector3.new(1.6, 1, 0.6), at(0, 7.2, -1.2), rgb(245, 245, 245), NO)
		P(m, "Cap", Vector3.new(3, 0.4, 3), at(0, 10.2, 0), rgb(40, 40, 50), NO)
		P(m, "Tassel", Vector3.new(0.2, 1.2, 0.2), at(1.3, 9.6, -1.3), rgb(255, 210, 60), NO)
		P(m, "Book", Vector3.new(1.8, 2.4, 0.6), at(2.1, 3.6, -0.9), rgb(220, 50, 60), NO)
	end,
}

local GREETING: { [Kind]: string } = {
	Coach = "Need more speed? Step right up!",
	Professor = "Every egg you find goes in my Index!",
}
local NAME: { [Kind]: string } = { Coach = "Coach Kicks", Professor = "Professor Yolk" }

function Merchants.build(kind: Kind, parent: Instance, feet: CFrame): Model
	local m = Bricks.model(parent, NAME[kind])
	local root = P(m, "Root", Vector3.new(1, 1, 1), feet, Color3.new(1, 1, 1), { transparency = 1, collide = false })
	m.PrimaryPart = root
	BUILD[kind](m, function(x: number, y: number, z: number): CFrame
		return feet * CFrame.new(x, y, z)
	end)
	m:SetAttribute("Merchant", NAME[kind])
	m:SetAttribute("Greeting", GREETING[kind])
	return m
end

return Merchants
