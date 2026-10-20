--!strict
-- Partner A. Zone 19, Galaxy Void (z 1800..1900): an indigo star-field plateau (readable, never black) with star
-- lamps along the banks, a giant ringed planet with its moon hanging in the sky on the left, a cosmic portal ring
-- with swirling energy on the right, floating void platforms carrying celestial crystals, meteors with burning
-- trails drifting overhead, distant planets. Ambience: twinkling stars and cosmic dust.
local Kit = require(script.Parent.Parent.Kit)
local Valley = require(script.Parent.Parent.Valley)
local Palettes = require(script.Parent.Parent.Palettes)
local Parts = require(script.Parent.Parent.Parts)
local Fx = require(script.Parent.Parent.Fx)

local rgb = Color3.fromRGB

local CRYSTALS = { { "CelestialCrystal", 3, 1.0, 1.6 }, { "RockB", 1, 0.8, 1.1 } }
local COVER = { { "CelestialCrystal", 1, 0.4, 0.6 }, { "RockC", 2, 0.6, 0.9 } }

return function(zone: any, parent: Instance)
	local PAL = Palettes.zones[19]
	local ctx = Valley.new(zone, parent, PAL)
	local H = 6
	for _, side in { -1, 1 } do
		Valley.plateau(ctx, side, H, PAL.Ground :: Color3, PAL.StoneDark :: Color3)
		Valley.banks(ctx, side, { "BankA", "BankB" }, H)
		Valley.patches(ctx, side, { rgb(70, 58, 128), rgb(46, 38, 92), rgb(90, 70, 150) }, 7)
		for z = ctx.z0 + 8, ctx.z1 - 4, 30 do
			local lamp = Valley.put(ctx, ctx.props, "StarLamp", side * (Valley.INNER + 12), z, 1, 0, PAL, H)
			local g = lamp and lamp:FindFirstChild("Glow")
			if g and g:IsA("BasePart") then
				Parts.light(g, rgb(170, 220, 255), 14, 0.8)
			end
		end
	end

	-- the ringed planet (left, in the sky) and the cosmic portal (right)
	local planet = Kit.place(ctx.far, "RingedPlanet", Kit.at(-150, 78, 1850, 30), 1.4, PAL)
	Valley.spin(planet, 4, true)
	Valley.keepOut(ctx, 110, 1850, 20)
	Kit.place(ctx.props, "CosmicPortal", Kit.at(110, H, 1850, 90), 1.4, PAL)
	Fx.area(ctx.fx, "CosmicDust", Vector3.new(4, 24, 24), Vector3.new(110, H + 18, 1850), nil, 2, 300)
	Parts.light(
		Parts.anchor(ctx.props, "PortalGlow", Vector3.one, Vector3.new(96, H + 18, 1850)),
		rgb(190, 120, 255),
		40,
		1.4
	)

	-- floating void platforms with crystals, bobbing
	for i, p in { { -80, 20, 1820 }, { -120, 32, 1880 }, { 80, 26, 1890 }, { 180, 18, 1820 }, { -220, 26, 1840 } } do
		local plat = Kit.place(ctx.terrain, "VoidPlatform", Kit.at(p[1], p[2], p[3], i * 40), 1, PAL)
		if plat then
			local c = Kit.place(ctx.terrain, "CelestialCrystal", Kit.at(p[1], p[2], p[3], i * 70), 1.3, PAL)
			if c then
				for _, part in c:GetChildren() do
					part.Parent = plat
				end
				c:Destroy()
			end
			Valley.bob(plat, 1.2 + (i % 2) * 0.5, 0.1 + i * 0.015)
		end
	end
	-- meteors drifting overhead
	for _ = 1, 6 do
		local side = if ctx.rng:NextNumber() < 0.5 then -1 else 1
		local met = Valley.put(
			ctx,
			ctx.props,
			"Meteor",
			side * ctx.rng:NextNumber(70, 240),
			ctx.rng:NextNumber(ctx.z0 + 6, ctx.z1 - 6),
			ctx.rng:NextNumber(0.8, 1.6),
			nil,
			PAL,
			H + ctx.rng:NextNumber(30, 60)
		)
		Valley.bob(met, ctx.rng:NextNumber(1, 2), ctx.rng:NextNumber(0.08, 0.14))
	end
	for _, c in { { -70, 1880, 3 }, { -180, 1880, 4 }, { 70, 1810, 3 }, { 210, 1880, 3 } } do
		Valley.cluster(ctx, ctx.nature, c[1], c[2], CRYSTALS, c[3], 9, PAL)
	end
	for _, side in { -1, 1 } do
		Valley.scatter(ctx, ctx.nature, side, CRYSTALS, 6, { Valley.INNER + 20, 220 }, 12, PAL)
	end
	Valley.shoulders(ctx, COVER, 14, PAL)

	-- far: distant planets
	Valley.farRow(
		ctx,
		1,
		{ { "RingedPlanet", 340, 1830, 0.6 } },
		Palettes.merge(PAL, { Planet = rgb(240, 140, 90), Planet2 = rgb(250, 190, 120) })
	)
	Kit.place(
		ctx.far,
		"RingedPlanet",
		Kit.at(300, 130, 1890, 0),
		0.4,
		Palettes.merge(PAL, { Planet = rgb(90, 200, 160), Planet2 = rgb(150, 230, 200) }),
		{ shadow = false }
	)

	-- ambience
	Valley.fx(ctx, "Stars", -1, 150, 220, 70, 60, nil, 2, 420)
	Valley.fx(ctx, "Stars", 1, 150, 220, 70, 60, nil, 2, 420)
	Valley.fx(ctx, "CosmicDust", 0, 0, 160, H + 6, 8, nil, 1.4)

	-- hand-over: lava core at the start, rainbow at the end
	Valley.blend(ctx, { { "MagmaPillar", 1, 0.6, 0.8 } }, Palettes.zones[18], true, 2)
	Valley.blend(ctx, { { "CloudPavilion", 1, 0.4, 0.5 }, { "GoldLamp", 1, 0.8, 1 } }, Palettes.zones[20], false, 2)
end
