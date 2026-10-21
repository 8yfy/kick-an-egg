--!strict
-- Partner A. Zone 16, Clockwork Factory (z 1500..1600): brick and steel banks, the Clock Tower factory hall with its
-- saw-tooth roofs and giant clock on the right, huge brass gears turning on the banks (all decoration, beside the
-- track), copper pipe runs, boilers with glowing fireboxes and steam, conveyors carrying crates, pumping pistons,
-- chimneys. Nothing moves over the track. Ambience: steam puffs and sparks.
local Kit = require(script.Parent.Parent.Kit)
local Valley = require(script.Parent.Parent.Valley)
local Palettes = require(script.Parent.Parent.Palettes)
local Parts = require(script.Parent.Parent.Parts)
local Fx = require(script.Parent.Parent.Fx)

local rgb = Color3.fromRGB

local MACHINES = {
	{ "Boiler", 2, 1.0, 1.3 },
	{ "PipeRun", 2, 1.0, 1.2 },
	{ "Piston", 2, 1.0, 1.3 },
	{ "Crate", 2, 1, 1.4 },
	{ "Barrel", 1, 1, 1.3 },
}
local COVER = { { "Crate", 2, 0.6, 0.8 }, { "Barrel", 2, 0.6, 0.8 }, { "RockC", 1, 0.6, 0.9 } }

return function(zone: any, parent: Instance)
	local PAL = Palettes.zones[16]
	local ctx = Valley.new(zone, parent, PAL)
	local H = 8
	for _, side in { -1, 1 } do
		Valley.plateau(ctx, side, H, PAL.Ground :: Color3, PAL.StoneDark :: Color3)
		Valley.banks(ctx, side, { "BankA", "BankD" }, H)
		Valley.patches(ctx, side, { rgb(130, 104, 82), rgb(110, 112, 124), rgb(160, 128, 96) }, 5)
	end

	-- the Clock Tower factory (right), steam from its chimneys
	local fx, fz = 128, 1552
	Valley.keepOut(ctx, fx, fz, 34)
	Kit.place(ctx.props, "ClockTower", Kit.at(fx, H, fz, 90), 1.25, PAL)
	for _, s in { -1, 1 } do
		Fx.area(
			ctx.fx,
			"Steam",
			Vector3.new(3, 1, 3),
			(CFrame.new(fx, H, fz) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(s * 12.5, 48, 7.5)).Position,
			nil,
			0.9,
			360
		)
	end

	-- giant gears turning on both banks (upright, along the track, beside it)
	for i, g in { { -60, 1520, 1.6, 22 }, { -62, 1570, 1.1, -34 }, { 62, 1512, 1.2, -28 }, { -100, 1546, 2.0, 14 } } do
		local d = 14 * g[3]
		local gear = Kit.place(
			ctx.props,
			if i == 2 then "GearSmall" else "GearBig",
			Kit.at(g[1], H + d / 2 + 1, g[2], 90),
			g[3],
			PAL
		)
		Valley.spin(gear, g[4])
		Parts.block(
			ctx.props,
			"GearMount",
			Vector3.new(3, d / 2 + 1, 3),
			CFrame.new(g[1] + (if g[1] > 0 then 2 else -2), H + (d / 2 + 1) / 2, g[2]),
			PAL.Metal :: Color3,
			{
				collide = false,
				query = false,
			}
		)
		Valley.keepOut(ctx, g[1], g[2], d / 2 + 2)
	end

	-- conveyors and machines in yards, steam and sparks
	Kit.place(ctx.props, "Conveyor", Kit.at(80, H, 1590, 0), 1, PAL)
	Kit.place(ctx.props, "Conveyor", Kit.at(-80, H, 1590, 90), 1, PAL)
	for _, c in { { -150, 1520, 4 }, { -180, 1580, 4 }, { 200, 1520, 4 }, { 230, 1580, 3 }, { 70, 1550, 2 } } do
		local ms = Valley.cluster(ctx, ctx.props, c[1], c[2], MACHINES, c[3], 10, PAL)
		for _, m in ms do
			if m.Name == "Boiler" then
				Fx.area(
					ctx.fx,
					"Steam",
					Vector3.new(1.6, 1, 1.6),
					m.WorldPivot.Position + Vector3.new(0, 14, 0),
					nil,
					0.6,
					260
				)
			end
		end
	end
	for _, side in { -1, 1 } do
		Valley.scatter(ctx, ctx.props, side, MACHINES, 6, { Valley.INNER + 12, 220 }, 12, PAL)
	end
	Valley.shoulders(ctx, COVER, 14, PAL)
	Fx.area(ctx.fx, "Sparks", Vector3.new(2, 1, 2), Vector3.new(-150, H + 4, 1520), nil, 0.6, 200)
	Fx.area(ctx.fx, "Sparks", Vector3.new(2, 1, 2), Vector3.new(200, H + 4, 1520), nil, 0.6, 200)

	-- far: a factory skyline with chimneys
	for _, side in { -1, 1 } do
		Valley.farRow(ctx, side, {
			{ "ClockTower", 300, 1530, 0.9, side * 90 },
			{ "BuildingC", 340, 1580, 2.2 },
			{ "BuildingB", 260, 1590, 2 },
		}, PAL)
	end

	-- ambience
	Valley.fx(ctx, "Steam", 0, 0, 160, H + 2, 2, { rgb(230, 230, 236) }, 0.5, 260)

	-- hand-over: swamp at the start, frozen aurora at the end
	Valley.blend(ctx, { { "Cattails", 2, 1, 1.2 } }, Palettes.zones[15], true, 2)
	Valley.blend(ctx, { { "IceSpikes", 1, 0.6, 0.8 }, { "SnowLumps", 2, 1, 1.2 } }, Palettes.zones[17], false, 3)
end
