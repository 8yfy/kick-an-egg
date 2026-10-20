--!strict
-- HUD navigation (UI handoff v2 01-Mockups/01-Gameplay-HUD.png). Left edge: SHOP (green), INDEX (cyan),
-- REBIRTH (purple), TRADE (teal) as horizontal icon + label buttons with the final approved icons (Shop = egg
-- basket, Index = open egg book, Trade = two eggs swapping; UI/System/AssetIds "hud_*"), animated by
-- UI/System/IconMotion. TRADE is a normal nav button like the others (teal); it opens the existing trade window
-- (Rail.openTrade, set by UI/init). No TRAINING button:
-- sacks are bought at the physical Boxing Sack Shop in the world (MapBuilder sackShop -> the same screen).
-- Phones (Kit.compact) shrink them to icon-only squares in the top-left corner, clear of the thumbstick (each
-- keeps its Name for accessibility). Badges only when something is true: Index = a zone reward to claim,
-- Rebirth = ready. The open screen's button stays highlighted. Rail.tile is the square Eggs / Pets button used
-- by the right rail (UI/Hud/Drawers).
local Kit = require(script.Parent.Parent.Kit)
local System = script.Parent.Parent.System
local Data = require(System.Data)
local Modal = require(System.Modal)
local Motion = require(System.Motion)
local IconMotion = require(System.IconMotion)
local Theme = require(System.Theme)
local Ui = require(System.Ui)

local C = Theme.Colors
local Rail = {}

local NAV = Vector2.new(250, 86)
local NAV_COMPACT = 80 -- four icon-only squares fit a phone's height
local GAP = 12

export type RailButton = {
	gui: TextButton,
	icon: ImageLabel,
	setBadge: (text: string?) -> (),
	setActive: (on: boolean) -> (),
	setCompact: (on: boolean) -> (),
}

local function base(
	parent: Instance,
	name: string,
	fill: Theme.Pair,
	onClick: (b: TextButton) -> ()
): (TextButton, UIStroke)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Text = ""
	b.AutoButtonColor = false
	b.Selectable = true
	Ui.corner(b)
	Ui.fill(b, fill)
	local stroke = Ui.stroke(b, 5)
	Ui.studs(b, Theme.Studs.header, 20)
	local hi = Instance.new("Frame")
	hi.Name = "Highlight"
	hi.BackgroundColor3 = Color3.new(1, 1, 1)
	hi.BackgroundTransparency = 0.8
	hi.BorderSizePixel = 0
	hi.Position = UDim2.fromOffset(5, 5)
	hi.Size = UDim2.new(1, -10, 0.36, -5)
	Ui.corner(hi, 5)
	hi.Parent = b
	Motion.interactive(b)
	b.Activated:Connect(function()
		onClick(b)
	end)
	b.Parent = parent
	return b, stroke
end

local function badgeFns(b: TextButton): (text: string?) -> ()
	local badge, badgeText = Ui.badge(b)
	local stopPulse: (() -> ())? = nil
	return function(text: string?)
		local show = text ~= nil
		if show ~= badge.Visible then
			badge.Visible = show
			if show then
				Motion.popIn(badge)
				stopPulse = Motion.pulse(badge, 0.08, 1.4)
			elseif stopPulse then
				stopPulse()
				stopPulse = nil
			end
		end
		badgeText.Text = text or ""
	end
end

-- Horizontal nav button: icon left, big uppercase label right.
function Rail.nav(
	parent: Instance,
	name: string,
	fill: Theme.Pair,
	icon: string,
	onClick: (b: TextButton) -> (),
	style: IconMotion.Style?
): RailButton
	local art: ImageLabel
	local b, stroke = base(parent, name, fill, function(gui: TextButton)
		if style then
			IconMotion.click(art, style)
		end
		onClick(gui)
	end)
	b.Size = UDim2.fromOffset(NAV.X, NAV.Y)
	local holder = Ui.frame(b, "Icon", UDim2.fromOffset(80, 80))
	holder.AnchorPoint = Vector2.new(0, 0.5)
	holder.ZIndex = 2
	art = Ui.art(holder, icon)
	art.ZIndex = 2
	if style then
		IconMotion.attach(art, style)
	end
	local label = Ui.text(b, string.upper(name), 36, { stroke = 4, name = "Label" })
	label.AnchorPoint = Vector2.new(0, 0.5)
	label.ZIndex = 3
	return {
		gui = b,
		icon = art,
		setBadge = badgeFns(b),
		setActive = function(on: boolean)
			stroke.Color = if on then C.text else C.border
		end,
		setCompact = function(on: boolean)
			b.Size = if on then UDim2.fromOffset(NAV_COMPACT, NAV_COMPACT) else UDim2.fromOffset(NAV.X, NAV.Y)
			label.Visible = not on
			holder.Size = if on then UDim2.fromOffset(78, 78) else UDim2.fromOffset(80, 80)
			holder.AnchorPoint = if on then Vector2.new(0.5, 0.5) else Vector2.new(0, 0.5)
			holder.Position = if on then UDim2.fromScale(0.5, 0.5) else UDim2.new(0, 6, 0.5, 0)
			label.Position = UDim2.new(0, 92, 0.5, 0)
			label.Size = UDim2.new(1, -98, 0, 44)
		end,
	}
end

-- Square tile: icon on top, label at the bottom (Eggs / Pets).
function Rail.tile(
	parent: Instance,
	name: string,
	fill: Theme.Pair,
	icon: string,
	onClick: (b: TextButton) -> (),
	style: IconMotion.Style?
): RailButton
	local art: ImageLabel
	local b, stroke = base(parent, name, fill, function(gui: TextButton)
		if style then
			IconMotion.click(art, style)
		end
		onClick(gui)
	end)
	b.Size = UDim2.fromOffset(120, 120)
	local holder = Ui.frame(b, "Icon", UDim2.fromOffset(84, 84))
	holder.AnchorPoint = Vector2.new(0.5, 0)
	holder.Position = UDim2.new(0.5, 0, 0, 2)
	holder.ZIndex = 2
	art = Ui.art(holder, icon)
	art.ZIndex = 2
	if style then
		IconMotion.attach(art, style)
	end
	local label = Ui.text(b, string.upper(name), 28, { align = Enum.TextXAlignment.Center, stroke = 4, name = "Label" })
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.new(0.5, 0, 1, -2)
	label.Size = UDim2.new(1, 4, 0, 34)
	label.ZIndex = 3
	return {
		gui = b,
		icon = art,
		setBadge = badgeFns(b),
		setActive = function(on: boolean)
			stroke.Color = if on then C.text else C.border
		end,
		setCompact = function(on: boolean)
			local s = if on then 96 else 120
			b.Size = UDim2.fromOffset(s, s)
			label.Visible = not on
			holder.Size = if on then UDim2.fromOffset(80, 80) else UDim2.fromOffset(84, 84)
			holder.Position = if on then UDim2.new(0.5, 0, 0, 8) else UDim2.new(0.5, 0, 0, 2)
		end,
	}
end

-- The TRADE button: the supplied Trade_Button art IS the button (its own pill, swap arrows and lettering), so no
-- base, label or outline is added. Hover / press like every rail button. On phones it stays a readable pill
-- (two rail slots wide) instead of shrinking to an unreadable square.
function Rail.artNav(parent: Instance, name: string, key: string, onClick: (b: TextButton) -> ()): RailButton
	local b = Instance.new("TextButton")
	b.Name = name
	b.Text = ""
	b.AutoButtonColor = false
	b.BackgroundTransparency = 1
	b.Size = UDim2.fromOffset(NAV.X, NAV.Y)
	b.Selectable = true
	b.Parent = parent
	local art = Ui.art(b, key, UDim2.fromScale(1, 1), Enum.ScaleType.Fit)
	art.ZIndex = 2
	Motion.interactive(b)
	b.Activated:Connect(function()
		onClick(b)
	end)
	return {
		gui = b,
		icon = art,
		setBadge = function(_text: string?) end,
		setActive = function(_on: boolean) end,
		setCompact = function(on: boolean)
			b.Size = if on
				then UDim2.fromOffset(NAV_COMPACT * 2, NAV_COMPACT * 0.62)
				else UDim2.fromOffset(NAV.X, NAV.Y)
		end,
	}
end

-- Set by UI/init: opens the existing trade window (UI/Menus TradeMenu, TradeService).
function Rail.openTrade() end

export type LeftRail = { update: () -> () }

function Rail.new(parent: Instance): LeftRail
	local root = Ui.frame(parent, "LeftRail", UDim2.fromOffset(NAV.X, 4 * NAV.Y + 3 * GAP))
	Kit.autoScale(root)
	Ui.list(root, GAP)

	local buttons: { [string]: RailButton } = {}
	local entries: { { any } } = {
		{ "Shop", "hud_shop", "shop" },
		{ "Index", "hud_index", "index" },
		{ "Rebirth", "hud_rebirth", "rebirth" },
		{ "Trade", "hud_trade", "eggs" },
	}
	for i, e in entries do
		local screen = e[1]
		local btn = Rail.nav(root, screen, Theme.Nav[screen], e[2], function(gui: TextButton)
			if screen == "Trade" then
				Rail.openTrade()
			else
				Modal.toggle(screen, gui)
			end
		end, e[3])
		btn.gui.LayoutOrder = i
		buttons[screen] = btn
	end

	Kit.onLayout(function(compact: boolean)
		local h = if compact then NAV_COMPACT else NAV.Y
		root.Size = UDim2.fromOffset(if compact then NAV_COMPACT * 2 else NAV.X, 4 * h + 3 * GAP)
		root.Position = if compact then UDim2.fromOffset(10, 8) else UDim2.new(0, 24, 0.333, 0)
		for _, btn in buttons do
			btn.setCompact(compact)
		end
	end)

	Modal.onChanged(function(name: string?)
		for screen, btn in buttons do
			btn.setActive(screen == name)
		end
	end)

	local wasReady: boolean? = nil -- (nil until the first update: joining with a rebirth ready stays quiet)
	return {
		update = function()
			local claimable = Data.claimableZones() + Data.claimableMilestones()
			buttons.Index.setBadge(if claimable > 0 then tostring(claimable) else nil)
			local rebirth = Data.rebirth()
			local ready = rebirth.available and rebirth.ready and not rebirth.inChase
			buttons.Rebirth.setBadge(if ready then "!" else nil)
			if ready and wasReady == false then
				Modal.sfx("StrengthMax") -- strength just reached the rebirth requirement
			end
			wasReady = ready
			-- (an affordable sack is flagged over the Boxing Sack Shop's sign in the world: UI/Interact)
		end,
	}
end

return Rail
