--!strict
-- Partner A. Zone 13, Haunted Graveyard (z 1200..1300): mossy grey-green banks, the crooked Haunted Manor with its
-- leaning tower and glowing windows on the left, fenced graveyards with tilted gravestones and a crypt, crooked
-- trees with a little glowing eye, jack-o'-lanterns and friendly ghosts floating up and down. Playful, kid-friendly:
-- purple roofs, green glow, never pitch dark. Ambience: ghost mist and green wisps.
local Kit = require(script.Parent.Parent.Kit)
local Valley = require(script.Parent.Parent.Valley)
local Palettes = require(script.Parent.Parent.Palettes)
local Parts = require(script.Parent.Parent.Parts)

local rgb = Color3.fromRGB

local GRAVES = { { "GravestoneA", 3, 1.0, 1.3 }, { "GravestoneB", 2, 1.0, 1.3 }, { "GravestoneC", 2, 1.0, 1.3 } }
local SPOOKY = { { "CrookedTree", 3, 1.0, 1.5 }, { "JackOLantern", 2, 1.0, 1.4 }, { "RockB", 1, 0.8, 1.1 } }
local COVER = {
	{ "GravestoneC", 1, 0.5, 0.7 },
	{ "JackOLantern", 1, 0.5, 0.7 },
	{ "GrassB", 3, 1, 1.3 },
	{ "RockC", 1, 0.6, 0.9 },
}

return function(zone: any, parent: Instance)
	local PAL = Palettes.zones[13]
	local ctx = Valley.new(zone, parent, PAL)
	local H = 8
	for _, side in { -1, 1 } do
		Valley.plateau(ctx, side, H, PAL.Ground :: Color3, PAL.StoneDark :: Color3)
		Valley.banks(ctx, side, { "BankA", "BankD" }, H)
		Valley.patches(ctx, side, { rgb(104, 132, 106), rgb(80, 104, 86), rgb(120, 110, 130) }, 5)
	end

	-- the Haunted Manor (left)
	local mx, mz = -122, 1252
	Valley.keepOut(ctx, mx, mz, 32)
	Kit.place(ctx.props, "HauntedManor", Kit.at(mx, H, mz, -90), 1.3, PAL)
	Parts.light(
		Parts.anchor(ctx.props, "ManorGlow", Vector3.one, Vector3.new(mx + 16, H + 14, mz)),
		rgb(150, 255, 140),
		30,
		1
	)

	-- fenced graveyards: an iron fence square around tilted gravestones, a crypt in the right one
	local function yard(cx: number, cz: number, w: number, d: number, crypt: boolean)
		Valley.keepOut(ctx, cx, cz, math.max(w, d) / 2 + 4)
		local function run(a: Vector3, b: Vector3)
			local len = (b - a).Magnitude
			local n = math.max(1, math.floor(len / 8 + 0.5))
			local dir = (b - a).Unit
			for k = 0, n - 1 do
				local q = a + dir * (len * (k + 0.5) / n)
				Kit.place(
					ctx.props,
					"IronFence",
					CFrame.lookAt(q, q + dir) * CFrame.Angles(0, math.rad(90), 0),
					Vector3.new(len / n / 8, 1, 1),
					PAL
				)
			end
		end
		local y = H
		local x0, x1, z0, z1 = cx - w / 2, cx + w / 2, cz - d / 2, cz + d / 2
		run(Vector3.new(x0, y, z0), Vector3.new(x1, y, z0))
		run(Vector3.new(x1, y, z0), Vector3.new(x1, y, z1))
		run(Vector3.new(x1, y, z1), Vector3.new(x0, y, z1))
		run(Vector3.new(x0, y, z1), Vector3.new(x0, y, cz + 4))
		run(Vector3.new(x0, y, cz - 4), Vector3.new(x0, y, z0))
		for gx = x0 + 4, x1 - 4, 6 do
			for gz = z0 + 4, z1 - 4, 6 do
				if not (crypt and math.abs(gx - cx) < 7 and math.abs(gz - cz) < 7) and ctx.rng:NextNumber() < 0.75 then
					Valley.put(
						ctx,
						ctx.props,
						({ "GravestoneA", "GravestoneB", "GravestoneC" })[ctx.rng:NextInteger(1, 3)],
						gx + ctx.rng:NextNumber(-1, 1),
						gz + ctx.rng:NextNumber(-1, 1),
						ctx.rng:NextNumber(0.9, 1.2),
						if cx > 0 then 90 else -90,
						PAL,
						H
					)
				end
			end
		end
		if crypt then
			Kit.place(ctx.props, "Crypt", Kit.at(cx, H, cz, if cx > 0 then 90 else -90), 1.2, PAL)
		end
	end
	yard(96, 1224, 34, 28, true)
	yard(-80, 1290, 22, 18, false)
	yard(150, 1282, 26, 20, false)

	-- friendly ghosts bobbing, lanterns, crooked groves
	for i, g in { { 76, 1262 }, { -96, 1214 }, { 130, 1206 }, { -160, 1290 } } do
		local ghost =
			Kit.place(ctx.props, "Ghost", Kit.at(g[1], H + 4 + i, g[2], if g[1] > 0 then 90 else -90), 2.2, PAL)
		Valley.bob(ghost, 1.6, 0.18 + i * 0.03)
	end
	for _, c in { { -66, 1220, 3 }, { -170, 1222, 4 }, { -200, 1280, 3 }, { 196, 1240, 4 }, { 70, 1292, 3 } } do
		Valley.cluster(ctx, ctx.nature, c[1], c[2], SPOOKY, c[3], 8, PAL)
	end
	for _, side in { -1, 1 } do
		Valley.scatter(ctx, ctx.nature, side, GRAVES, 5, { Valley.INNER + 10, 200 }, 10, PAL)
		Valley.scatter(ctx, ctx.nature, side, SPOOKY, 10, { Valley.INNER + 10, 220 }, 11, PAL)
	end
	Valley.shoulders(ctx, COVER, 18, PAL)

	-- far: crooked-tree ridges and a pale moon
	for _, side in { -1, 1 } do
		Valley.farRow(
			ctx,
			side,
			{ { "HillB", 300, 1240, 1.3 }, { "CrookedTree", 280, 1270, 4 }, { "CrookedTree", 330, 1220, 5 } },
			PAL
		)
	end
	local moon = Parts.block(ctx.far, "Moon", Vector3.new(26, 26, 2), CFrame.new(-260, 120, 1290), rgb(250, 246, 220), {
		material = Enum.Material.Neon,
		collide = false,
		query = false,
		shadow = false,
	})
	moon.Transparency = 0.15

	-- ambience
	Valley.fx(ctx, "GhostMist", -1, 110, 160, H + 1.5, 2, nil, 1.2)
	Valley.fx(ctx, "GhostMist", 1, 110, 160, H + 1.5, 2, nil, 1.2)
	Valley.fx(ctx, "Wisps", 0, 0, 160, H + 6, 8, nil, 1.4)

	-- hand-over: neon at the start, sky at the end
	Valley.blend(ctx, { { "NeonLamp", 1, 0.7, 0.9 } }, Palettes.zones[12], true, 2)
	Valley.blend(ctx, { { "CloudPillar", 1, 0.5, 0.7 }, { "FloatingRock", 1, 0.8, 1 } }, Palettes.zones[14], false, 2)
end
