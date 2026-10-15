--!strict
-- The weather event card (top right, under the settings / sound buttons; on phones left of the Eggs / Pets
-- column): the weather's NAME on a coloured header plate, the COUNTDOWN to its end, and its ICON on a stud tile.
-- Presentation only. WeatherService (server) picks the weather, its duration and the boost, and fires
-- WeatherChanged(weather?, endsAt?) to everyone and to each player who joins mid-event; endsAt is server time
-- (workspace:GetServerTimeNow()), so every client counts down to the same moment, whatever the replication delay.
-- No weather (nil) hides the card: the game has no "clear" weather state between events.
--   * Same weather sent again: only the end time is updated, nothing animates.
--   * A different weather: the old card fades out, the new name / icon / colours / time go in, then a short
--     fade + scale-in, a soft icon bounce and one highlight sweep over the tile. Rapid changes settle on the latest.
--   * The countdown ticks once per whole second (task.delay, no per-frame loop), turns warm in the last 10 s and
--     holds 0:00 until the server ends the event (hidden after a few seconds if that message never comes).
--   * Reduced Motion (Settings): no scale, bounce, sweep or pulse; short fades only.
-- Looks (label, icon, colours) per weather: UI/System/WeatherLook (any Config/Mutations.Weather name works).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(script.Parent.Parent.Kit)
local System = script.Parent.Parent.System
local Motion = require(System.Motion)
local Theme = require(System.Theme)
local Ui = require(System.Ui)
local WeatherLook = require(System.WeatherLook)

local C = Theme.Colors

local W, H = 168, 226 -- design px (scaled with the rest of the HUD)
local MARGIN = 6 -- room for the 5 px border inside the fading group
local HEADER = 38
local TILE = 110
local WARN_SECONDS = 10
local GRACE_SECONDS = 4 -- hide this long after 0:00 if the server's "ended" never arrives
local PHONE_FIT = 0.82
local WARM = Color3.fromHex("FF8A6A")

local WeatherHud = {}

export type WeatherHud = {
	root: Frame,
	set: (weather: any, endsAt: any) -> (),
	current: () -> (string?, number?),
	listen: () -> (),
	destroy: () -> (),
}

export type Options = {
	clock: (() -> number)?, -- default workspace:GetServerTimeNow (the clock endsAt is in)
	layout: boolean?, -- false: the caller positions the card (design previews)
}

function WeatherHud.new(parent: Instance, opts: Options?): WeatherHud
	local clock: () -> number = (opts and opts.clock) or function(): number
		return workspace:GetServerTimeNow()
	end
	local old = parent:FindFirstChild("Weather")
	if old then
		old:Destroy()
	end

	local root = Ui.frame(parent, "Weather", UDim2.fromOffset(W, H))
	root.AnchorPoint = Vector2.new(1, 0)
	root.Visible = false
	root.ZIndex = 0 -- drawers and windows draw over it
	local screenScale = Kit.autoScale(root)
	local fit = Ui.frame(root, "Fit")
	fit.AnchorPoint = Vector2.new(1, 0)
	fit.Position = UDim2.fromScale(1, 0)
	local fitScale = Instance.new("UIScale")
	fitScale.Parent = fit

	local group = Instance.new("CanvasGroup")
	group.Name = "Card"
	group.AnchorPoint = Vector2.new(0.5, 0.5)
	group.Position = UDim2.fromScale(0.5, 0.5)
	group.Size = UDim2.fromScale(1, 1)
	group.BackgroundTransparency = 1
	group.GroupTransparency = 1
	group.Parent = fit
	local pop = Motion.scaleOf(group)

	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundColor3 = C.card
	body.BackgroundTransparency = 0.08
	body.BorderSizePixel = 0
	body.Position = UDim2.fromOffset(MARGIN, MARGIN)
	body.Size = UDim2.new(1, -2 * MARGIN, 1, -2 * MARGIN)
	Ui.corner(body)
	Ui.stroke(body, 5)
	Ui.studs(body, Theme.Studs.body)
	body.Parent = group

	-- NAME: a coloured header plate (gradient, quiet studs, two strips) like the windows' section headers
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.BorderSizePixel = 0
	header.ClipsDescendants = true
	header.Position = UDim2.fromOffset(5, 5)
	header.Size = UDim2.new(1, -10, 0, HEADER)
	Ui.corner(header, 5)
	header.Parent = body
	Ui.studs(header, Theme.Studs.header, 20)
	Ui.strips(header, 0.7)
	local name = Ui.text(header, "", 24, { align = Enum.TextXAlignment.Center, stroke = 3, name = "Name" })
	name.AnchorPoint = Vector2.new(0.5, 0.5)
	name.Position = UDim2.fromScale(0.5, 0.5)
	name.Size = UDim2.new(1, -14, 1, -10)
	name.TextScaled = true -- fills the plate at any screen scale; long names shrink instead of breaking the card
	name.ZIndex = 3

	-- COUNTDOWN: big outlined numbers with a gradient like the Cash / Power counters
	local timer = Ui.text(body, "", 44, { align = Enum.TextXAlignment.Center, stroke = 4, name = "Timer" })
	timer.Position = UDim2.fromOffset(0, HEADER + 8)
	timer.Size = UDim2.new(1, 0, 0, 46)
	local timerFill = Instance.new("UIGradient")
	timerFill.Rotation = 90
	timerFill.Parent = timer
	local timerScale = Motion.scaleOf(timer)

	-- ICON: a stud tile like the Eggs / Pets buttons (gradient, border, top highlight) with the weather's art
	local tile = Instance.new("Frame")
	tile.Name = "Tile"
	tile.BorderSizePixel = 0
	tile.ClipsDescendants = true
	tile.AnchorPoint = Vector2.new(0.5, 0)
	tile.Position = UDim2.new(0.5, 0, 0, HEADER + 58)
	tile.Size = UDim2.fromOffset(TILE, TILE)
	Ui.corner(tile)
	Ui.stroke(tile, 4)
	tile.Parent = body
	Ui.studs(tile, Theme.Studs.header, 20)
	local shade = Instance.new("Frame")
	shade.Name = "Highlight"
	shade.BackgroundColor3 = Color3.new(1, 1, 1)
	shade.BackgroundTransparency = 0.8
	shade.BorderSizePixel = 0
	shade.Position = UDim2.fromOffset(5, 5)
	shade.Size = UDim2.new(1, -10, 0.36, -5)
	shade.ZIndex = 1
	Ui.corner(shade, 5)
	shade.Parent = tile
	local iconHolder = Ui.frame(tile, "Icon", UDim2.fromScale(1.04, 1.04))
	iconHolder.AnchorPoint = Vector2.new(0.5, 0.5)
	iconHolder.Position = UDim2.fromScale(0.5, 0.52)
	iconHolder.ZIndex = 3
	local iconScale = Motion.scaleOf(iconHolder)
	local art: ImageLabel? = nil
	-- one highlight sweep across the tile when a weather appears
	local sweep = Instance.new("Frame")
	sweep.Name = "Sweep"
	sweep.BackgroundColor3 = Color3.new(1, 1, 1)
	sweep.BackgroundTransparency = 0.35
	sweep.BorderSizePixel = 0
	sweep.AnchorPoint = Vector2.new(0.5, 0.5)
	sweep.Rotation = 24
	sweep.Size = UDim2.new(0, 30, 2, 0)
	sweep.Visible = false
	sweep.ZIndex = 4
	local soft = Instance.new("UIGradient")
	soft.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	soft.Parent = sweep
	sweep.Parent = tile

	-- Layout ---------------------------------------------------------------------------------------------
	local function place()
		local s = screenScale.Scale
		if Kit.compact() then -- phones: left of the Eggs / Pets column (96 px tiles at the top right), smaller
			fitScale.Scale = PHONE_FIT
			root.Position = UDim2.new(1, -(10 + 96 * s + 10), 0, 4)
		else -- under the settings + sound buttons (58 px, 22 px from the top)
			fitScale.Scale = 1
			root.Position = UDim2.new(1, -24, 0, 22 + 58 * s + 10)
		end
	end
	if not (opts and opts.layout == false) then
		Kit.onLayout(place)
		screenScale:GetPropertyChangedSignal("Scale"):Connect(place)
	end

	-- State ----------------------------------------------------------------------------------------------
	local weather: string? = nil
	local endsAt: number? = nil
	local look: WeatherLook.Look? = nil
	local token = 0 -- bumps on every change of weather (cancels pending swaps)
	local tickToken = 0 -- bumps on every new end time (restarts the countdown)
	local warm = false

	local function paintTimer()
		local l = look
		if not l then
			return
		end
		timerFill.Color = ColorSequence.new(Color3.new(1, 1, 1), if warm then WARM else l.accent)
	end

	local function apply(w: string)
		local l = WeatherLook.get(w)
		look = l
		name.Text = l.label
		Ui.fill(header, l.header, if #l.header >= 3 then 0 else 90)
		Ui.fill(tile, l.tile)
		if art then
			art:Destroy()
		end
		local a = Ui.art(iconHolder, l.icon)
		a.ZIndex = 3
		art = a
		root:SetAttribute("Weather", w)
		root:SetAttribute("Label", l.label)
		root:SetAttribute("Icon", l.icon)
	end

	local function tick(t: number)
		if t ~= tickToken or not endsAt then
			return
		end
		local left = endsAt - clock()
		local shown = math.max(0, math.ceil(left - 0.001))
		timer.Text = WeatherLook.clock(shown)
		root:SetAttribute("SecondsLeft", shown)
		local nowWarm = shown <= WARN_SECONDS
		if nowWarm ~= warm then
			warm = nowWarm
			paintTimer()
		end
		if warm and shown > 0 and not Motion.reduced() then
			timerScale.Scale = 1.07
			Motion.tween(timerScale, 0.25, { Scale = 1 }, Enum.EasingStyle.Quad)
		end
		if left <= -GRACE_SECONDS then -- the event is over and the server's "ended" never came: stop showing it
			weather, endsAt = nil, nil
			root:SetAttribute("Weather", nil)
			token += 1
			local tk = token
			Motion.tween(group, Theme.Motion.close, { GroupTransparency = 1 })
			task.delay(Theme.Motion.close, function()
				if tk == token then
					root.Visible = false
				end
			end)
			return
		end
		-- wake just after the next whole second
		local wait = if left > 0 then left - math.floor(left) else 0.5
		task.delay(if wait < 0.02 then wait + 1 else wait + 0.01, tick, t)
	end

	local function restartClock()
		tickToken += 1
		if endsAt then
			timer.Visible = true
			tick(tickToken)
		else
			timer.Visible = false -- no end time: never show an invented countdown
		end
	end

	local function appear(reduced: boolean)
		root.Visible = true
		if reduced then
			pop.Scale, iconScale.Scale = 1, 1
			Motion.tween(group, Theme.Motion.reduced, { GroupTransparency = 0 })
			return
		end
		pop.Scale = 0.88
		Motion.tween(group, 0.22, { GroupTransparency = 0 })
		Motion.tween(pop, 0.32, { Scale = 1 }, Enum.EasingStyle.Back)
		iconScale.Scale = 0.6
		task.delay(0.06, function()
			Motion.tween(iconScale, 0.42, { Scale = 1 }, Enum.EasingStyle.Back)
		end)
		sweep.Position = UDim2.new(-0.3, 0, 0.5, 0)
		sweep.Visible = true
		task.delay(0.12, function()
			local t = Motion.tween(
				sweep,
				0.5,
				{ Position = UDim2.new(1.3, 0, 0.5, 0) },
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.InOut
			)
			t.Completed:Once(function()
				sweep.Visible = false
			end)
		end)
	end

	local function set(w: any, e: any)
		local nextWeather: string? = if typeof(w) == "string" and w ~= "" then w else nil
		local nextEnds: number? = if typeof(e) == "number" and e == e and math.abs(e) < math.huge then e else nil
		if not nextWeather then
			nextEnds = nil
		end
		if nextWeather == weather then -- the same weather again (or still none): just keep the time right
			if nextEnds ~= endsAt then
				endsAt = nextEnds
				restartClock()
			end
			return
		end
		token += 1
		local tk = token
		local had = weather ~= nil
		weather, endsAt = nextWeather, nextEnds
		local reduced = Motion.reduced()
		local out = if reduced then Theme.Motion.reduced else 0.14
		if not nextWeather then -- the event ended
			tickToken += 1
			Motion.tween(group, out, { GroupTransparency = 1 })
			if not reduced then
				Motion.tween(pop, out, { Scale = 0.92 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end
			task.delay(out, function()
				if tk == token then
					root.Visible = false
					root:SetAttribute("Weather", nil)
				end
			end)
			return
		end
		local function swapIn()
			if tk ~= token then
				return
			end
			warm = false
			apply(nextWeather)
			paintTimer()
			restartClock()
			appear(reduced)
		end
		if had and root.Visible then -- weather -> another weather: the old card goes first
			Motion.tween(group, out, { GroupTransparency = 1 })
			if not reduced then
				Motion.tween(pop, out, { Scale = 0.92 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end
			task.delay(out, swapIn)
		else
			swapIn()
		end
	end

	local conns: { RBXScriptConnection } = {}
	local hud: WeatherHud
	hud = {
		root = root,
		set = set,
		current = function()
			return weather, endsAt
		end,
		listen = function()
			if #conns > 0 then
				return
			end
			local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes")) :: any
			table.insert(conns, Remotes.get("WeatherChanged").OnClientEvent:Connect(set))
		end,
		destroy = function()
			for _, c in conns do
				c:Disconnect()
			end
			table.clear(conns)
			token += 1
			tickToken += 1
			root:Destroy()
		end,
	}
	root.Destroying:Connect(function()
		for _, c in conns do
			c:Disconnect()
		end
		table.clear(conns)
		tickToken += 1
	end)
	return hud
end

return WeatherHud
