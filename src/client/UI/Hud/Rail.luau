--!strict
-- HUD navigation (UI handoff v2 01-Mockups/01-Gameplay-HUD.png). Left edge: SHOP (green), INDEX (cyan),
-- REBIRTH (purple), TRAINING (purple, sack icon) as horizontal icon + label buttons with the supplied
-- Premium-Icons PNGs. Phones (Kit.compact) shrink them to icon-only squares in the top-left corner, clear of
-- the thumbstick (each keeps its Name for accessibility). Badges only when something is true: Index = a zone
-- reward to claim, Rebirth = ready, Training = the next sack is affordable. The open screen's button stays
-- highlighted. Rail.tile is the square Eggs / Pets button used by the right rail (UI/Hud/Drawers).
local Kit = require(script.Parent.Parent.Kit)
local System = script.Parent.Parent.System
local Data = require(System.Data)
local Modal = require(System.Modal)
local Motion = require(System.Motion)
local Theme = require(System.Theme)
local Ui = require(System.Ui)

local C = Theme.Colors
local Rail = {}

local NAV = Vector2.new(250, 86)
local NAV_COMPACT = 92
local GAP = 12

export type RailButton = {
	gui: TextButton,
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
	onClick: (b: TextButton) -> ()
): RailButton
	local b, stroke = base(parent, name, fill, onClick)
	b.Size = UDim2.fromOffset(NAV.X, NAV.Y)
	local holder = Ui.frame(b, "Icon", UDim2.fromOffset(80, 80))
	holder.AnchorPoint = Vector2.new(0, 0.5)
	holder.ZIndex = 2
	Ui.art(holder, icon).ZIndex = 2
	local label = Ui.text(b, string.upper(name), 36, { stroke = 4, name = "Label" })
	label.AnchorPoint = Vector2.new(0, 0.5)
	label.ZIndex = 3
	return {
		gui = b,
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
	onClick: (b: TextButton) -> ()
): RailButton
	local b, stroke = base(parent, name, fill, onClick)
	b.Size = UDim2.fromOffset(120, 120)
	local holder = Ui.frame(b, "Icon", UDim2.fromOffset(84, 84))
	holder.AnchorPoint = Vector2.new(0.5, 0)
	holder.Position = UDim2.new(0.5, 0, 0, 2)
	holder.ZIndex = 2
	Ui.art(holder, icon).ZIndex = 2
	local label = Ui.text(b, string.upper(name), 28, { align = Enum.TextXAlignment.Center, stroke = 4, name = "Label" })
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.new(0.5, 0, 1, -2)
	label.Size = UDim2.new(1, 4, 0, 34)
	label.ZIndex = 3
	return {
		gui = b,
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

export type LeftRail = { update: () -> () }

function Rail.new(parent: Instance): LeftRail
	local root = Ui.frame(parent, "LeftRail", UDim2.fromOffset(NAV.X, 4 * NAV.Y + 3 * GAP))
	Kit.autoScale(root)
	Ui.list(root, GAP)

	local buttons: { [string]: RailButton } = {}
	local entries = {
		{ "Shop", "premium_icons_nav_shop" },
		{ "Index", "premium_icons_nav_index" },
		{ "Rebirth", "premium_icons_nav_rebirth" },
		{ "Training", "premium_icons_nav_training" },
	}
	for i, e in entries do
		local screen = e[1]
		local btn = Rail.nav(root, screen, Theme.Nav[screen], e[2], function(gui: TextButton)
			Modal.toggle(screen, gui)
		end)
		btn.gui.LayoutOrder = i
		buttons[screen] = btn
	end

	Kit.onLayout(function(compact: boolean)
		local h = if compact then NAV_COMPACT else NAV.Y
		root.Size = UDim2.fromOffset(if compact then NAV_COMPACT else NAV.X, 4 * h + 3 * GAP)
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

	return {
		update = function()
			local claimable = Data.claimableZones()
			buttons.Index.setBadge(if claimable > 0 then tostring(claimable) else nil)
			local rebirth = Data.rebirth()
			buttons.Rebirth.setBadge(if rebirth.available and rebirth.ready and not rebirth.inChase then "!" else nil)
			local canBuy = false
			for _, row in Data.sacks() do
				if row.state == "Buy" then
					canBuy = true
				end
			end
			buttons.Training.setBadge(if canBuy then "!" else nil)
		end,
	}
end

return Rail
