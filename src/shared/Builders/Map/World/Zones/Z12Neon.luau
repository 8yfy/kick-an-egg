--!strict
-- Partner A. Zone 12, Neon City (z 1100..1200): a low slate city on both sides of the track: clean studded streets
-- with lane dashes running beside the banks, storefronts with striped awnings facing the track, city blocks of
-- coloured towers with lit windows and neon strips (grouped in blocks with alleys, never one row), the stepped
-- Neon Tower landmark with its billboard ring on the right, neon street lamps, billboards and a spinning hologram
-- egg. Bloom stays modest: neon is used for strips and signs only. Ambience: drifting neon pixels.
local Kit = require(script.Parent.Parent.Kit)
local Valley = require(script.Parent.Parent.Valley)
local Palettes = require(script.Parent.Parent.Palettes)
local Parts = require(script.Parent.Parent.Parts)

local rgb = Color3.fromRGB

return function(zone: any, parent: Instance)
	local PAL = Palettes.zones[12]
	local ctx = Valley.new(zone, parent, PAL)
	local function wall(): any
		return Palettes.cityWalls[ctx.rng:NextInteger(1, #Palettes.cityWalls)]
	end
	local H = 4
	for _, side in { -1, 1 } do
		Valley.plateau(ctx, side, H, PAL.Ground :: Color3, PAL.StoneDark :: Color3)
		Valley.banks(ctx, side, { "BankB" }, H, { depth = 12 })
		-- the street beside the bank: a studded road with yellow dashes and a sidewalk
		local len = ctx.z1 - ctx.z0
		local x = side * (Valley.INNER + 20)
		Parts.block(
			ctx.terrain,
			"Street",
			Vector3.new(12, 0.2, len),
			CFrame.new(x, H + 0.1, ctx.zm),
			rgb(46, 48, 64),
			{ collide = false, query = false }
		)
		Parts.block(
			ctx.terrain,
			"Sidewalk",
			Vector3.new(4, 0.5, len),
			CFrame.new(x + side * 8, H + 0.25, ctx.zm),
			rgb(150, 156, 180),
			{ collide = false, query = false }
		)
		for z = ctx.z0 + 4, ctx.z1 - 4, 10 do
			Parts.block(
				ctx.terrain,
				"Dash",
				Vector3.new(0.6, 0.24, 4),
				CFrame.new(x, H + 0.12, z),
				rgb(255, 214, 60),
				{ collide = false, query = false, shadow = false }
			)
		end
		-- neon lamps along the bank lip
		for z = ctx.z0 + 8, ctx.z1 - 4, 24 do
			local lamp = Valley.put(
				ctx,
				ctx.props,
				"NeonLamp",
				side * (Valley.INNER + 13),
				z,
				1,
				if side > 0 then 180 else 0,
				wall(),
				H
			)
			local glow = lamp and lamp:FindFirstChild("Neon")
			if glow and glow:IsA("BasePart") then
				Parts.light(glow, glow.Color, 16, 0.8)
			end
		end
	end

	-- the Neon Tower (right)
	local tx, tz = 120, 1150
	Valley.keepOut(ctx, tx, tz, 22)
	Kit.place(ctx.props, "NeonTower", Kit.at(tx, H, tz, 0), 1.3, PAL)
	Parts.light(
		Parts.anchor(ctx.props, "TowerGlow", Vector3.one, Vector3.new(tx - 18, H + 30, tz)),
		rgb(255, 80, 210),
		40,
		1
	)

	-- storefronts facing the track, then city blocks behind them (with alleys), billboards
	for _, side in { -1, 1 } do
		local yaw = if side > 0 then 90 else -90
		for i, z in { 1114, 1146, 1180 } do
			if not (side > 0 and math.abs(z - tz) < 24) then
				Valley.put(
					ctx,
					ctx.props,
					"Storefront",
					side * (Valley.INNER + 40),
					z + ctx.rng:NextNumber(-3, 3),
					1,
					yaw,
					wall(),
					H
				)
			end
			Valley.keepOut(ctx, side * (Valley.INNER + 40), z, 10 + i)
		end
		for _, block in { { 1112, 2 }, { 1150, 3 }, { 1188, 2 } } do
			local z0 = block[1]
			for k = 0, block[2] - 1 do
				local x = side * (Valley.INNER + 64 + k * 20 + ctx.rng:NextNumber(-2, 2))
				local z = z0 + ctx.rng:NextNumber(-6, 6)
				if (Vector3.new(x, 0, z) - Vector3.new(tx, 0, tz)).Magnitude > 26 then
					Valley.put(
						ctx,
						ctx.props,
						({ "BuildingA", "BuildingB", "BuildingC" })[ctx.rng:NextInteger(1, 3)],
						x,
						z,
						ctx.rng:NextNumber(1.0, 1.4),
						yaw,
						wall(),
						H
					)
				end
			end
		end
		Valley.put(ctx, ctx.props, "Billboard", side * (Valley.INNER + 30), 1130, 1, yaw, wall(), H)
	end
	local holo = Kit.place(ctx.props, "HologramEgg", Kit.at(-74, H, 1160, 0), 1.6, PAL)
	Valley.spin(holo, 30, true)
	Valley.bob(holo, 0.6, 0.25)

	-- far: a skyline of tall towers in two rows
	for _, side in { -1, 1 } do
		Valley.farRow(ctx, side, {
			{ "BuildingB", 230, 1120, 2.4 },
			{ "NeonTower", 300, 1170, 1.0 },
			{ "BuildingB", 270, 1190, 2.8 },
			{ "BuildingA", 340, 1130, 2.6 },
		}, wall())
	end

	-- ambience
	Valley.fx(ctx, "NeonDrift", -1, 80, 100, H + 3, 6, nil, 1.3)
	Valley.fx(ctx, "NeonDrift", 1, 80, 100, H + 3, 6, nil, 1.3)
	Valley.fx(ctx, "NeonDrift", 0, 0, 70, 3, 4, { rgb(255, 230, 80), rgb(80, 230, 255) }, 0.8)

	-- hand-over from the jungle at the start, to the graveyard at the end
	Valley.blend(ctx, { { "Fern", 2, 0.9, 1.2 } }, Palettes.zones[11], true, 2)
	Valley.blend(ctx, { { "GravestoneA", 2, 1, 1.2 }, { "CrookedTree", 1, 0.8, 1 } }, Palettes.zones[13], false, 3)
end
