--!strict
-- 23 Ice Dragon (Snowy Peaks, Legendary). Hero example 4/7 (docs/EggPetPlan.md): hero model, iconic silhouette.
-- Egg: navy-to-snow egg with frost fur trim, ice crystal clusters bursting out, crystal horns, glowing frost
--      cracks and a core window; three ice shards orbit it.
-- Pet: armoured navy/white dragon: crystal-pane wings, swept crystal horns, a ridge of ice spikes, glowing chest
--      core and eyes, clawed legs, a crystal-tipped tail; four ice shards orbit it.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local S = require(script.Parent.Parent.Sculpt)

local P, rgb = S.part, Color3.fromRGB
local NAVY, NAVY_DK, WHITE = rgb(32, 56, 128), rgb(20, 34, 84), rgb(232, 240, 252)
local ICE, ICE_LT, CYAN, SILVER = rgb(140, 210, 255), rgb(205, 240, 255), rgb(110, 232, 255), rgb(190, 200, 216)

local function cf(pos: { number }, rot: { number }?): CFrame
	return S.cf(pos, rot)
end
local GLASS = { material = "Glass", transparency = 0.15 }
local function o(joint: string, extra: S.Opts?): S.Opts
	local t: S.Opts = table.clone(extra or {})
	t.joint = joint
	return t
end
local function core(joint: string, y: number): Builder.PartSpec
	return P(joint .. "Core", { 0.2, 0.2, 0.2 }, { 0, y, 0 }, WHITE, { joint = joint, transparency = 1, studs = false })
end

-- Egg -------------------------------------------------------------------------------------------------------
local H, W = 4.8, 3.6
local eggParts = S.join(
	S.eggShell(H, W, function(i, n)
		return if i <= 2 then NAVY_DK elseif i <= 5 then NAVY elseif i <= 7 then ICE elseif i < n then ICE_LT else WHITE
	end),
	{
		S.eggBand("SilverBand", H, W, 2.35, 0.14, 0.05, SILVER, { studs = false }),
		S.plate("CoreWindow", H, W, 0, 1.75, { 0.7, 0.7, 0.16 }, CYAN, { material = "Neon" }),
		S.plate("CoreFrame", H, W, 0, 1.75, { 0.95, 0.95, 0.12 }, SILVER),
	},
	-- frost fur trim around the base
	S.eggRing("Fur", H, W, 0.62, 3, { 0.62, 0.5, 0.4 }, WHITE, {
		joint = "Body",
		rot = { 0, 0, 20 },
	}),
	-- crystal horns
	S.shard("HornL", cf({ -0.75, H - 0.55, 0.1 }, { 15, 0, 38 }), 1.5, 0.42, ICE, o("Body", GLASS), ICE_LT),
	S.shard("HornR", cf({ 0.75, H - 0.55, 0.1 }, { 15, 0, -38 }), 1.5, 0.42, ICE, o("Body", GLASS), ICE_LT)
)
-- ice crystal clusters bursting out of the upper shell
for k, c in
	{
		{ 40, 3.2, 1.25 },
		{ 110, 2.7, 1.0 },
		{ 165, 3.5, 1.35 },
		{ 225, 2.8, 1.05 },
		{ 290, 3.35, 1.2 },
		{ 330, 2.6, 0.85 },
	}
do
	local base = S.onEgg(H, W, c[1], c[2], -0.1) * CFrame.Angles(math.rad(-58), 0, 0)
	for _, p in S.shard("Cluster" .. k, base, c[3], 0.4, ICE, o("Body", GLASS), ICE_LT) do
		table.insert(eggParts, p)
	end
end
-- glowing frost cracks (zigzag) on the front
for k, c in { { -14, 2.65, 30 }, { -6, 3.0, -35 }, { 4, 3.3, 30 }, { 12, 3.6, -30 } } do
	table.insert(
		eggParts,
		S.at(
			"Crack" .. k,
			{ 0.1, 0.48, 0.1 },
			S.onEgg(H, W, c[1], c[2], 0.02) * CFrame.Angles(0, 0, math.rad(c[3])),
			CYAN,
			{
				joint = "Body",
				material = "Neon",
			}
		)
	)
end
table.insert(eggParts, core("Orbit", 2.6))
for k = 1, 3 do
	local a = math.rad(k * 120)
	local base = cf({ math.sin(a) * 2.9, 2.2 + k * 0.35, -math.cos(a) * 2.9 }, { 0, 0, 15 })
	for _, p in S.shard("Floater" .. k, base, 0.9, 0.32, ICE_LT, o("Orbit", { material = "Neon" })) do
		table.insert(eggParts, p)
	end
end
local egg: Builder.Spec = { parts = eggParts }

-- Pet -------------------------------------------------------------------------------------------------------
local petParts: { Builder.PartSpec } = {
	-- body (hinge first)
	P("Torso", { 2.6, 2.1, 3.8 }, { 0, 3.0, 0.2 }, NAVY, { joint = "Body" }),
	P("ChestPlate", { 2.0, 1.6, 0.22 }, { 0, 2.9, -1.72 }, WHITE, { joint = "Body" }),
	P(
		"ChestCore",
		{ 0.62, 0.62, 0.14 },
		{ 0, 3.0, -1.86 },
		CYAN,
		{ joint = "Body", material = "Neon", rot = { 0, 0, 45 } }
	),
	P("BellyPlate", { 1.9, 0.2, 3.0 }, { 0, 1.92, 0.25 }, WHITE, { joint = "Body" }),
	P("BackPlate", { 1.6, 0.25, 3.2 }, { 0, 4.1, 0.25 }, NAVY_DK, { joint = "Body" }),
	-- neck + head
	P("Neck1", { 1.25, 1.35, 1.25 }, { 0, 4.1, -1.95 }, NAVY, { joint = "Head", rot = { -30, 0, 0 } }),
	P("Neck2", { 1.08, 1.15, 1.08 }, { 0, 4.85, -2.45 }, NAVY, { joint = "Head", rot = { -18, 0, 0 } }),
	P("NeckPlate", { 0.75, 1.8, 0.18 }, { 0, 4.35, -2.62 }, WHITE, { joint = "Head", rot = { -25, 0, 0 } }),
	P("Head", { 1.65, 1.25, 1.85 }, { 0, 5.6, -2.95 }, NAVY, { joint = "Head" }),
	P("Snout", { 1.25, 0.75, 1.35 }, { 0, 5.38, -4.25 }, NAVY, { joint = "Head" }),
	P("Jaw", { 1.12, 0.36, 1.25 }, { 0, 4.86, -4.05 }, WHITE, { joint = "Head" }),
	P("NoseTip", { 0.95, 0.3, 0.2 }, { 0, 5.55, -4.98 }, NAVY_DK, { joint = "Head" }),
	P("Crown", { 1.2, 0.25, 1.4 }, { 0, 6.3, -2.85 }, WHITE, { joint = "Head" }),
}
local function add(list: { Builder.PartSpec })
	for _, p in list do
		table.insert(petParts, p)
	end
end
-- ice spine ridge along the back + head crest
for k, z in { -1.3, -0.45, 0.4, 1.25, 2.0 } do
	add(
		S.shard(
			"Spine" .. k,
			cf({ 0, 4.15, z }, { 18, 0, 0 }),
			1.45 - math.abs(z - 0.3) * 0.25,
			0.48,
			ICE,
			o("Body", GLASS),
			ICE_LT
		)
	)
end
for k, z in { -3.4, -2.75 } do
	add(S.shard("Crest" .. k, cf({ 0, 6.35, z }, { 35, 0, 0 }), 0.75, 0.32, ICE, o("Head", GLASS), ICE_LT))
end
-- left side (mirrored): eyes, brows, horns, fangs, armour, legs, wings
local left: { Builder.PartSpec } = {
	P("EyeL", { 0.1, 0.26, 0.5 }, { -0.83, 5.72, -3.45 }, CYAN, { joint = "Head", material = "Neon" }),
	P("BrowL", { 0.55, 0.3, 1.0 }, { -0.62, 6.08, -3.3 }, WHITE, { joint = "Head", rot = { 0, 0, 18 } }),
	P("FangL", { 0.16, 0.3, 0.16 }, { -0.38, 4.98, -4.62 }, WHITE, { joint = "Head", studs = false }),
	P("ShoulderL", { 0.45, 1.15, 1.35 }, { -1.42, 3.35, -0.9 }, WHITE, { joint = "Body" }),
	P("HaunchL", { 0.45, 1.1, 1.3 }, { -1.42, 3.15, 1.35 }, WHITE, { joint = "Body" }),
	-- front leg (ArmL): hinge first
	P("FrontUpperL", { 0.88, 1.35, 0.98 }, { -1.08, 2.2, -1.25 }, NAVY, { joint = "ArmL" }),
	P("FrontLowerL", { 0.76, 1.05, 0.86 }, { -1.08, 0.98, -1.38 }, NAVY, { joint = "ArmL" }),
	P("FrontKneeL", { 0.16, 0.65, 0.75 }, { -1.56, 1.55, -1.32 }, WHITE, { joint = "ArmL" }),
	P("FrontFootL", { 1.0, 0.45, 1.2 }, { -1.08, 0.22, -1.55 }, WHITE, { joint = "ArmL" }),
	-- back leg (LegL)
	P("BackThighL", { 0.98, 1.55, 1.25 }, { -1.08, 2.3, 1.35 }, NAVY, { joint = "LegL" }),
	P("BackShinL", { 0.76, 1.05, 0.86 }, { -1.08, 0.95, 1.62 }, NAVY, { joint = "LegL" }),
	P("BackKneeL", { 0.16, 0.65, 0.75 }, { -1.6, 1.85, 1.4 }, WHITE, { joint = "LegL" }),
	P("BackFootL", { 1.0, 0.45, 1.2 }, { -1.08, 0.22, 1.42 }, WHITE, { joint = "LegL" }),
}
for k = 1, 3 do
	local x = -1.08 + (k - 2) * 0.32
	table.insert(
		left,
		P("FrontClawL" .. k, { 0.18, 0.2, 0.32 }, { x, 0.12, -2.25 }, ICE_LT, { joint = "ArmL", material = "Neon" })
	)
	table.insert(
		left,
		P("BackClawL" .. k, { 0.18, 0.2, 0.32 }, { x, 0.12, 0.72 }, ICE_LT, { joint = "LegL", material = "Neon" })
	)
end
-- horns: a long swept crystal horn and a short one
for _, p in S.shard("HornL", cf({ -0.55, 6.2, -2.55 }, { 58, 0, 22 }), 2.0, 0.5, ICE, o("Head", GLASS), ICE_LT) do
	table.insert(left, p)
end
for _, p in S.shard("HornSmallL", cf({ -0.8, 5.75, -2.3 }, { 70, 0, 50 }), 1.05, 0.34, ICE, o("Head", GLASS), ICE_LT) do
	table.insert(left, p)
end
-- wing: hinge at the shoulder, an arm bone up and out, five crystal panes fanning down from the wrist
local shoulder = cf({ -1.25, 4.15, -0.3 }, { 0, -18, 0 })
local arm = shoulder * CFrame.Angles(0, 0, math.rad(52))
local wrist = arm * CFrame.new(0, 2.3, 0)
table.insert(left, S.at("WingArmL", { 0.4, 2.4, 0.4 }, arm * CFrame.new(0, 1.15, 0), NAVY, { joint = "WingL" }))
table.insert(
	left,
	S.at(
		"WingTipL",
		{ 0.32, 1.7, 0.32 },
		wrist * CFrame.Angles(0, 0, math.rad(28)) * CFrame.new(0, 0.8, 0),
		NAVY,
		{ joint = "WingL" }
	)
)
for k = 1, 5 do
	local a = 92 + (k - 1) * 22
	local len = 3.0 - math.abs(k - 3) * 0.35
	local pane = wrist * CFrame.Angles(0, 0, math.rad(a)) * CFrame.new(0, len / 2, 0)
	table.insert(
		left,
		S.at("WingPaneL" .. k, { 0.95, len, 0.1 }, pane * CFrame.new(0.42, 0, 0), ICE, {
			joint = "WingL",
			material = "Glass",
			transparency = 0.25,
		})
	)
	table.insert(left, S.at("WingBoneL" .. k, { 0.2, len, 0.18 }, pane, NAVY_DK, { joint = "WingL" }))
end
for k, c in { { 0.6, 0.85 }, { 1.4, 0.7 }, { 2.25, 0.9 } } do
	for _, p in
		S.shard(
			"WingSpikeL" .. k,
			arm * CFrame.new(0, c[1], 0) * CFrame.Angles(0, 0, math.rad(55)),
			c[2],
			0.28,
			ICE_LT,
			o("WingL", { material = "Neon" })
		)
	do
		table.insert(left, p)
	end
end
add(S.both(left))
-- tail: back and down, then lifting; ice spikes on top, a crystal blade at the tip
local c = cf({ 0, 2.85, 2.0 }, { 115, 0, 0 })
for i = 1, 6 do
	local w = 1.25 - i * 0.14
	table.insert(
		petParts,
		S.at(
			"Tail" .. i,
			{ w, 0.85, w },
			c * CFrame.new(0, 0.4, 0),
			if i % 2 == 0 then NAVY_DK else NAVY,
			{ joint = "Tail" }
		)
	)
	if i % 2 == 1 then
		add(
			S.shard(
				"TailSpike" .. i,
				c
					* CFrame.new(0, 0.4, 0)
					* CFrame.new(0, 0, -w / 2)
					* CFrame.Angles(math.rad(-90), 0, 0)
					* CFrame.Angles(math.rad(-20), 0, 0),
				0.7,
				0.26,
				ICE,
				o("Tail", GLASS)
			)
		)
	end
	c = c * CFrame.new(0, 0.8, 0) * CFrame.Angles(math.rad(-12), 0, 0)
end
add(S.shard("TailBlade", c, 1.5, 0.55, ICE, o("Tail", GLASS), ICE_LT))
-- four ice shards orbiting the dragon
table.insert(petParts, core("Orbit", 4.6))
for k = 1, 4 do
	local a = math.rad(k * 90 + 45)
	add(
		S.shard(
			"Floater" .. k,
			cf({ math.sin(a) * 3.9, 4.0 + (k % 2) * 0.8, -math.cos(a) * 3.9 }, { 0, 0, 12 }),
			1.1,
			0.36,
			ICE_LT,
			o("Orbit", { material = "Neon" })
		)
	)
end
local pet: Builder.Spec = { parts = petParts }

return { egg = egg, pet = pet }
