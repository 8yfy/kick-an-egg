--!strict
-- Partner A. The two hub stores (world remodel 2026-10-15). Visual replacements only: same model names, same
-- footprints, the same counter ProximityPrompts (Action "OpenMenu:Store" / "OpenMenu:Inventory"), the same
-- "Approach" anchors (tutorial), the same merchant spots (Merchants.build, swapped for avatars by MerchantService),
-- the same "Sign" part on the shop (UI/Interact puts its alert there) and the six display sacks (Display = true).
--   Boxing Sack Shop: a gym hall under a red / white barrel-vault roof with gold ribs, a giant boxing glove turning on
--   the ridge, a glowing round gable window, chunky stone pillars, a striped awning, arched side windows, a
--   studded plinth, the mini ring with the display sacks inside, dumbbells, tyres and a speed bag.
--   Pet Selling Stand: a teal / cream market stall on carved posts, a big paw board on the ridge, bunting, egg
--   crates on shelves, pet beds and a carrier, lanterns.
local Kit = require(script.Parent.Kit)
local Parts = require(script.Parent.Parts)
local Palettes = require(script.Parent.Palettes)
local Fx = require(script.Parent.Fx)
local Merchants = require(script.Parent.Parent.Merchants)
local Sacks = require(script.Parent.Parent.Parent.Models.Sacks)
local SackGeometry = require(script.Parent.Parent.Parent.SackGeometry)
local Upgrades = require(script.Parent.Parent.Parent.Parent.Config.Upgrades)

local Shops = {}

local rgb = Color3.fromRGB
local block, light = Parts.block, Parts.light

local function prompt(parent: BasePart, action: string, text: string, object: string): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = text
	p.ObjectText = object
	p.MaxActivationDistance = 14
	p.RequiresLineOfSight = false
	p:SetAttribute("Action", action)
	p.Parent = parent
	return p
end

-- A Kick Sack hanging with its hub at `hang` (the original GLB sack when imported), anchored, Spin for MapLife.
local function hangSack(parent: Instance, tier: number, hang: CFrame, spin: number): Model
	local sack = SackGeometry.build(tier)
	sack:PivotTo(hang)
	for _, d in sack:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
		elseif d:IsA("WeldConstraint") or d:IsA("Motor6D") then
			d:Destroy()
		end
	end
	if sack.PrimaryPart then
		sack.PrimaryPart:Destroy()
	end
	sack.Name = "Sack"
	sack.Parent = parent
	local pivot = Parts.anchor(sack, "Pivot", Vector3.one * 0.2, hang.Position)
	pivot.CFrame = hang
	sack.PrimaryPart = pivot
	sack:SetAttribute("Tier", tier)
	sack:SetAttribute("Spin", spin)
	return sack
end

local SHOP_TIERS = { 9, 14, 18, 20, 1, 5 } -- gantry (premium) first, then the two wall brackets

-- `dir` = +1 faces +Z, -1 faces -Z (the hub's shop faces -Z, toward the plaza).
function Shops.sackShop(parent: Instance, x: number, z: number, dir: number): Model
	local m = Instance.new("Model")
	m.Name = "BoxingSackShop"
	m.Parent = parent
	local origin = Vector3.new(x, 0, z)
	local frame = CFrame.lookAt(origin, origin + Vector3.new(0, 0, dir))
	local function at(lx: number, ly: number, lz: number, yaw: number?): CFrame
		return frame * CFrame.new(lx, ly, lz) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	end
	local PAL = Palettes.shop
	local red, redDark, white, cream = rgb(214, 44, 52), rgb(150, 28, 36), rgb(250, 248, 244), rgb(250, 244, 230)
	local gold, wood, mat, stone = rgb(255, 198, 56), rgb(156, 102, 62), rgb(44, 114, 214), rgb(214, 210, 222)
	local W, D, H = 34, 24, 16
	local FLOOR = 1 -- top of the ring mat
	local TOP = 0.8 + H -- wall top
	local art = Parts.folder(m, "Art")

	-- studded plinth with a two-step front, blue mat floor
	block(m, "Plinth", Vector3.new(W + 2, 0.8, D + 2), at(0, 0.4, 0), stone, { sideStuds = true })
	block(m, "Step", Vector3.new(W - 8, 0.45, 2.4), at(0, 0.225, -D / 2 - 2.2), stone, { studs = true })
	block(m, "Floor", Vector3.new(W - 2, 0.2, D - 2), at(0, 0.9, 0), mat)
	-- walls: red back wall with a white band, cream side walls with red bands (studded brick look)
	block(m, "BackWall", Vector3.new(W, H, 1), at(0, 0.8 + H / 2, D / 2 - 0.5), red, { sideStuds = true })
	block(m, "BackStripe", Vector3.new(W + 0.1, 1.2, 1.2), at(0, 4.6, D / 2 - 0.5), white)
	for _, sx in { -1, 1 } do
		block(
			m,
			"SideWall",
			Vector3.new(1, H, D - 3),
			at(sx * (W / 2 - 0.5), 0.8 + H / 2, 1.5),
			cream,
			{ sideStuds = true }
		)
		block(m, "SideStripe", Vector3.new(1.2, 1.2, D - 2.9), at(sx * (W / 2 - 0.5), 4.6, 1.5), red)
		block(m, "SideBase", Vector3.new(1.4, 1.4, D - 2.6), at(sx * (W / 2 - 0.5), 1.5, 1.5), redDark)
		-- arched window on the outside of each side wall
		Kit.place(art, "ShopWindow", at(sx * (W / 2 + 0.1), 5.2, 1.5, sx * -90), 1, PAL)
		-- chunky front pillars (collision proxy inside) with a lantern each
		Kit.place(
			art,
			"ShopPillar",
			at(sx * (W / 2 - 1.3), 0.8, -D / 2 + 1.3),
			Vector3.new(1, (H + 0.6) / 12.3, 1),
			PAL
		)
		Parts.proxy(m, "PillarProxy", Vector3.new(3, H, 3), at(sx * (W / 2 - 1.3), 0.8 + H / 2, -D / 2 + 1.3))
		local lantern = Kit.place(art, "Lantern", at(sx * (W / 2 - 1.3), 7.6, -D / 2 - 0.6), 1.1, PAL)
		local glow = lantern and lantern:FindFirstChild("Glow")
		if glow and glow:IsA("BasePart") then
			light(glow, rgb(255, 210, 150), 14, 0.7)
		end
		-- gloves hanging inside the side walls
		for _, lz in { 0, 5 } do
			local g = Kit.place(art, "GloveSmall", at(sx * (W / 2 - 1.7), 7.2, lz, sx * 90), 1, PAL)
			if g then
				g:PivotTo(g:GetPivot() * CFrame.Angles(math.rad(180), 0, 0) * CFrame.new(0, -2, 0))
			end
		end
	end
	-- front: a tall header beam carrying the sign board (the vault's gable with its round window stays clear above),
	-- a gold trim, the striped awning below it
	block(m, "Header", Vector3.new(W, 4.6, 2.2), at(0, TOP - 2.3, -D / 2 + 1.1), redDark)
	block(m, "HeaderTrim", Vector3.new(W + 0.2, 0.5, 2.4), at(0, TOP - 4.85, -D / 2 + 1.1), gold)
	local board = block(m, "Sign", Vector3.new(26, 3.8, 0.8), at(0, TOP - 2.3, -D / 2 - 0.4), red, { sideStuds = true })
	block(m, "SignFrame", Vector3.new(27.2, 4.6, 0.6), at(0, TOP - 2.3, -D / 2 + 0.2), gold)
	local signGui = Parts.text(board, Enum.NormalId.Front, {
		{ "Title", "BOXING SACK SHOP", 0.06, 0.62, white },
		{ "Sub", "TRAIN STRONGER - KICK FARTHER", 0.7, 0.24, rgb(255, 225, 120) },
	}, 24)
	signGui.Name = "SignGui"
	light(board, rgb(255, 196, 140), 16, 0.6)
	Kit.place(art, "ShopAwning", at(0, TOP - 5.1, -D / 2), Vector3.new((W - 4) / 26.4, 1, 1), PAL)
	-- roof: barrel vault on the walls, a giant glove turning on a gold plinth on the ridge
	Kit.place(art, "ShopRoof", at(0, TOP, 0.5), Vector3.new((W + 1.6) / 35.4, 1, (D + 4) / 29.9), PAL)
	block(
		m,
		"GlovePlinth",
		Vector3.new(5, 1.2, 5),
		at(0, TOP + 9.9, -D / 2 + 7),
		gold,
		{ collide = false, reflect = 0.2 }
	)
	local glove = Kit.place(m, "BoxingGlove", at(0, TOP + 10.5, -D / 2 + 7), 1.15, PAL, { name = "RoofGlove" })
	if glove then
		glove:SetAttribute("Speed", 18)
		glove:SetAttribute("Axis", "Y")
		game:GetService("CollectionService"):AddTag(glove, "WorldSpin") -- VFX/Ambient turns it
	end
	-- the mini boxing ring at the back: corner posts and red / white / blue ropes on three sides (open to the front)
	local ringZ0, ringZ1, ringX = 0.5, D / 2 - 1.5, 11
	for _, px in { -ringX, ringX } do
		for _, pz in { ringZ0, ringZ1 } do
			block(m, "RingPost", Vector3.new(0.9, 5.4, 0.9), at(px, FLOOR + 2.7, pz), white)
			block(m, "RingPad", Vector3.new(1.2, 1.4, 1.2), at(px, FLOOR + 4.6, pz), red, { collide = false })
		end
	end
	for k, c in { rgb(230, 50, 60), white, rgb(50, 110, 230) } do
		local y = FLOOR + 1.4 + k * 1.2
		block(m, "Rope", Vector3.new(2 * ringX, 0.3, 0.3), at(0, y, ringZ1), c, { collide = false })
		for _, px in { -ringX, ringX } do
			block(
				m,
				"Rope",
				Vector3.new(0.3, 0.3, ringZ1 - ringZ0),
				at(px, y, (ringZ0 + ringZ1) / 2),
				c,
				{ collide = false }
			)
		end
	end
	local poster = block(m, "Poster", Vector3.new(9, 4.6, 0.3), at(0, 12.4, D / 2 - 1.15), rgb(32, 38, 52))
	Parts.text(poster, Enum.NormalId.Front, {
		{ "Top", "THE CHAMP", 0.08, 0.4, rgb(255, 215, 60) },
		{ "Bottom", "HIT HARDER", 0.55, 0.32 },
	}, 24)
	-- display sacks: four on a gantry inside the ring, two on wall brackets by the counter. Props only.
	local hubY = FLOOR + Sacks.HANG
	local beamY = hubY + Sacks.CHAIN_TOP + 0.45
	local ringMid = (ringZ0 + ringZ1) / 2
	block(m, "Gantry", Vector3.new(2 * ringX + 1, 0.9, 1.2), at(0, beamY, ringMid), wood)
	for _, gx in { -ringX, ringX } do
		block(
			m,
			"GantryPost",
			Vector3.new(0.9, beamY - FLOOR - 0.45, 0.9),
			at(gx, (beamY + FLOOR - 0.45) / 2, ringMid + 0.9),
			wood
		)
	end
	local displays = Parts.folder(m, "Displays")
	for i, tier in SHOP_TIERS do
		local d = Instance.new("Model")
		d.Name = "Display" .. i
		d:SetAttribute("Tier", tier)
		d.Parent = displays
		local hang: CFrame
		if i <= 4 then
			hang = at(-7.5 + (i - 1) * 5, hubY, ringMid)
		else
			local sx = if i == 5 then -1 else 1
			block(d, "Bracket", Vector3.new(4.4, 0.7, 0.9), at(sx * (W / 2 - 2.2), beamY, -3.5), wood)
			hang = at(sx * (W / 2 - 4.2), hubY, -3.5)
		end
		local sack = hangSack(d, tier, hang, 8)
		sack:SetAttribute("Display", true) -- a prop: no idle effects (MapLifeController)
		if i <= 4 then
			local plate = block(
				d,
				"Plate",
				Vector3.new(4, 1.2, 0.4),
				hang * CFrame.new(0, -hubY + FLOOR + 0.7, -(ringMid - ringZ0) - 0.6),
				rgb(32, 38, 52)
			)
			Parts.text(
				plate,
				Enum.NormalId.Front,
				{ { "Name", string.upper(Upgrades.Sack.tiers[tier].name), 0.1, 0.8 } },
				30
			)
		end
	end
	-- gym props
	Kit.place(art, "DumbbellRack", at(-12.5, FLOOR, 3.5, 90), 0.85, PAL)
	Kit.place(art, "SpeedBag", at(13.2, 6.5, 6.5, -90), 0.9, PAL)
	Kit.place(art, "TireStack", at(-W / 2 - 3.2, 0, -D / 2 - 1.5, 15), 1, PAL)
	Kit.place(art, "TireStack", at(W / 2 + 3, 0, -D / 2 + 3, -30), 0.85, PAL)
	Parts.proxy(m, "TireProxy", Vector3.new(4, 3, 4), at(-W / 2 - 3.2, 1.5, -D / 2 - 1.5))
	Parts.proxy(m, "TireProxy", Vector3.new(3.4, 3, 3.4), at(W / 2 + 3, 1.5, -D / 2 + 3))
	-- one soft ceiling light
	light(
		Parts.anchor(m, "CeilingLight", Vector3.new(1, 0.4, 1), at(0, 0.8 + H - 1, 0).Position),
		rgb(255, 240, 220),
		26,
		0.7
	)
	-- the counter at the front with the Coach behind it; its prompt opens the existing sack screen
	local counter = block(m, "Counter", Vector3.new(18, 3, 2.6), at(0, FLOOR + 1.5, -6.5), wood, { sideStuds = true })
	block(m, "CounterTop", Vector3.new(18.6, 0.4, 3.2), at(0, FLOOR + 3.2, -6.5), white)
	block(m, "CounterStripe", Vector3.new(18.1, 0.7, 0.1), at(0, FLOOR + 1.9, -7.85), red)
	Kit.place(art, "GloveSmall", at(-6, FLOOR + 3.4, -6.5, -20), 1, PAL)
	Kit.place(art, "GloveSmall", at(-4.4, FLOOR + 3.4, -6.3, 25), 1, PAL)
	block(m, "Bell", Vector3.new(1.2, 0.8, 1.2), at(6, FLOOR + 3.8, -6.5), gold, { reflect = 0.3 })
	block(m, "MerchantStep", Vector3.new(12, 1.2, 3.6), at(0, FLOOR + 0.6, -3.2), wood)
	Merchants.build("Coach", m, at(0, FLOOR + 1.2, -3.2))
	prompt(counter, "OpenMenu:Store", "Browse sacks", "Boxing Sack Shop")
	-- where to walk to (tutorial trail / arrow): in front of the storefront, on the ground
	Parts.anchor(m, "Approach", Vector3.new(2, 1, 2), at(0, 1.5, -D / 2 - 5).Position)
	Fx.area(
		art,
		"Sparkle",
		Vector3.new(24, 3, 2),
		at(0, TOP + 0.6, -D / 2 - 1.2).Position,
		{ rgb(255, 230, 150) },
		1.2,
		140
	)
	return m
end

function Shops.petStand(parent: Instance, x: number, z: number, dir: number): Model
	local m = Instance.new("Model")
	m.Name = "PetSellingStand"
	m.Parent = parent
	local origin = Vector3.new(x, 0, z)
	local frame = CFrame.lookAt(origin, origin + Vector3.new(0, 0, dir))
	local function at(lx: number, ly: number, lz: number, yaw: number?): CFrame
		return frame * CFrame.new(lx, ly, lz) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	end
	local PAL = Palettes.stand
	local wood, woodDark, cream = rgb(186, 126, 72), rgb(120, 76, 44), rgb(252, 244, 224)
	local teal, coral = rgb(40, 196, 178), rgb(255, 128, 110)
	local art = Parts.folder(m, "Art")
	local POST = 12.4
	-- planked deck (studded) and a front step
	block(m, "Deck", Vector3.new(24, 0.8, 18), at(0, 0.4, 0), rgb(214, 172, 118), { studs = true })
	block(m, "DeckEdge", Vector3.new(24.6, 0.5, 18.6), at(0, 0.25, 0), woodDark, { collide = false })
	block(m, "Step", Vector3.new(14, 0.4, 2.2), at(0, 0.2, -10.1), rgb(214, 172, 118), { studs = true })
	-- carved posts + the striped canopy + the paw board on the ridge
	for _, sx in { -10.5, 10.5 } do
		for _, sz in { -7.5, 7.5 } do
			Kit.place(art, "StandPost", at(sx, 0.8, sz), Vector3.new(1, POST / 11.4, 1), PAL)
			Parts.proxy(m, "PostProxy", Vector3.new(1.8, POST, 1.8), at(sx, 0.8 + POST / 2, sz))
		end
	end
	Kit.place(art, "StandCanopy", at(0, 0.8 + POST, 0), Vector3.new(1, 1, 1), PAL)
	Kit.place(art, "PawSign", at(0, 0.8 + POST + 4.6, 0), 1, PAL)
	-- back board with two shelves of egg crates
	block(m, "BackBoard", Vector3.new(19.2, 7, 0.8), at(0, 4.3, 7.5), cream, { sideStuds = true })
	block(m, "BackBoardTrim", Vector3.new(19.8, 0.6, 1.2), at(0, 7.9, 7.5), teal)
	for row = 0, 1 do
		block(m, "Shelf", Vector3.new(16, 0.4, 2.0), at(0, 2.6 + row * 2.9, 6.4), wood)
		for col = -1, 1 do
			Kit.place(art, "EggCrate", at(col * 5, 2.8 + row * 2.9, 6.4), 0.62, PAL)
		end
	end
	-- the sign under the canopy front: SELL PETS between two paws (the approved icon)
	local sign = block(m, "Sign", Vector3.new(14, 3, 0.6), at(0, POST - 1.4, -8.4), coral, { sideStuds = true })
	block(m, "SignFrame", Vector3.new(14.8, 3.8, 0.4), at(0, POST - 1.4, -7.95), woodDark)
	local gui = Parts.text(sign, Enum.NormalId.Front, { { "Title", "SELL PETS", 0.1, 0.8 } }, 24)
	local title = gui:FindFirstChild("Title") :: TextLabel
	title.Position, title.Size = UDim2.fromScale(0.2, 0.1), UDim2.fromScale(0.6, 0.8)
	for _, px in { 0.03, 0.81 } do
		local paw = Instance.new("ImageLabel")
		paw.BackgroundTransparency = 1
		paw.Image = "rbxassetid://84890738919357" -- UI/System/AssetIds hud_pets (the approved Pets icon)
		paw.ScaleType = Enum.ScaleType.Fit
		paw.Position, paw.Size = UDim2.fromScale(px, 0.05), UDim2.fromScale(0.16, 0.9)
		paw.Parent = gui
	end
	light(sign, rgb(255, 196, 120), 16, 0.8)
	-- bunting between the front posts, lanterns hanging off them
	Kit.place(art, "Bunting", at(0, POST - 0.3, -8.2), Vector3.new(21 / 20.1, 1, 1), PAL)
	for _, sx in { -1, 1 } do
		local lantern = Kit.place(art, "Lantern", at(sx * 11.6, POST - 4.2, -8.3), 1, PAL)
		local glow = lantern and lantern:FindFirstChild("Glow")
		if glow and glow:IsA("BasePart") then
			light(glow, rgb(255, 210, 140), 14, 0.9)
		end
	end
	-- the counter, the pet merchant behind it
	local counter = block(m, "Counter", Vector3.new(16, 3.4, 2.4), at(0, 2.5, -4.6), wood, { sideStuds = true })
	block(m, "CounterTop", Vector3.new(16.6, 0.4, 3), at(0, 4.4, -4.6), cream)
	block(m, "CounterStripe", Vector3.new(16.1, 0.6, 0.1), at(0, 3.2, -5.85), teal)
	Kit.place(art, "PetCarrier", at(5.6, 4.6, -4.6, -15), 0.7, PAL)
	Kit.place(art, "Lantern", at(-6.2, 4.6, -4.6), 0.7, PAL)
	Merchants.build("PetSeller", m, at(0, 0.8, 1.2))
	prompt(counter, "OpenMenu:Inventory", "Sell pets", "Pet Selling Stand")
	-- dressing outside: crates of eggs, pet beds, a price board
	for _, sx in { -1, 1 } do
		Kit.place(art, "Crate", at(sx * 10.2, 0, -12.2, sx * 12), 1.1, PAL)
		Kit.place(art, "EggCrate", at(sx * 10.2, 3.1, -12.2, sx * 12), 0.75, PAL)
		Parts.proxy(m, "CrateProxy", Vector3.new(3.4, 3.4, 3.4), at(sx * 10.2, 1.7, -12.2))
	end
	Kit.place(art, "PetBed", at(-13.6, 0, 3, 0), 1, PAL)
	Kit.place(art, "PetBed", at(14, 0, -1, 0), 0.85, Palettes.merge(PAL, { Cloth = rgb(255, 150, 190) }))
	Kit.place(art, "Chalkboard", at(15.6, 0, -9, -30), 1, PAL)
	Parts.anchor(m, "Approach", Vector3.new(2, 1, 2), at(0, 1.5, -14).Position)
	Fx.area(art, "Sparkle", Vector3.new(12, 2, 2), at(0, 5.6, -4.6).Position, { rgb(255, 240, 200) }, 1, 120)
	return m
end

return Shops
