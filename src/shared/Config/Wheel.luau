--!strict
-- CONTRACT FILE: the Prize Wheel on the plaza's side wall (Builders/Map/Wheel, WheelService, UI Screens/Wheel).
-- Spins are bought with Robux (developer products below) and banked in the save (data.wheelSpins), so a
-- purchase is never lost; spending one spin is a normal server request. The server rolls the prize.
--
-- Segments go clockwise from the pointer at the top; `weight` is the relative chance (they sum to 100, so
-- weight = percent). Prize kinds:
--   Cash: `seconds` of the player's current pet income (PlotService.incomePerSecond), at least `min`
--   Egg:  an inventory egg of `rarity` from the zones the player has reached (else the earliest such zone)

export type Segment = {
	key: string,
	kind: "Cash" | "Egg",
	label: string, -- short text on the wheel
	weight: number,
	color: Color3,
	seconds: number?, -- Cash
	min: number?, -- Cash
	rarity: string?, -- Egg
	jackpot: boolean?, -- announced to the server
}

export type Product = { id: number, spins: number }

local rgb = Color3.fromRGB

local Wheel = {
	Segments = {
		{
			key = "Cash5",
			kind = "Cash",
			label = "CASH",
			seconds = 300,
			min = 2500,
			weight = 30,
			color = rgb(80, 200, 70),
		},
		{
			key = "EggUncommon",
			kind = "Egg",
			label = "EGG",
			rarity = "Uncommon",
			weight = 20,
			color = rgb(70, 170, 255),
		},
		{
			key = "Cash15",
			kind = "Cash",
			label = "CASH",
			seconds = 900,
			min = 10000,
			weight = 16,
			color = rgb(255, 200, 40),
		},
		{ key = "EggRare", kind = "Egg", label = "RARE EGG", rarity = "Rare", weight = 14, color = rgb(40, 110, 230) },
		{
			key = "Cash30",
			kind = "Cash",
			label = "CASH",
			seconds = 1800,
			min = 25000,
			weight = 9,
			color = rgb(255, 140, 30),
		},
		{ key = "EggEpic", kind = "Egg", label = "EPIC EGG", rarity = "Epic", weight = 7, color = rgb(170, 70, 235) },
		{
			key = "Cash60",
			kind = "Cash",
			label = "BIG CASH",
			seconds = 3600,
			min = 50000,
			weight = 3,
			color = rgb(235, 50, 60),
		},
		{
			key = "EggLegendary",
			kind = "Egg",
			label = "JACKPOT",
			rarity = "Legendary",
			weight = 1,
			color = rgb(255, 215, 60),
			jackpot = true,
		},
	} :: { Segment },

	-- Robux packs. id = 0 until the developer product is created (Creator Hub > your experience >
	-- Monetization > Developer Products), then paste its id here. Prices are set on Roblox, not in code
	-- (suggested: 1 spin 49 R$, 3 spins 129 R$, 10 spins 399 R$). In Studio, packs with id 0 can be
	-- test-granted from the wheel window (never on live servers).
	Products = {
		One = { id = 0, spins = 1 },
		Three = { id = 0, spins = 3 },
		Ten = { id = 0, spins = 10 },
	} :: { [string]: Product },

	SpinSeconds = 6, -- the wheel animation; the prize is granted when it stops
	Reach = 26, -- studs from the wheel's podium a player must be to spin
}

return Wheel
