--!strict
-- Left HUD rail (UI handoff SCREEN-SPEC "HUD"; Figma "HUD / NavButton"): Shop, Index, Rebirth, Training as
-- big gradient tiles with icon + label, stacked under the zone bar. Phones (Kit.compact) drop the labels and
-- shrink the tiles into the top-left corner, clear of the thumbstick. Badges only when something is true:
-- Index = a zone reward to claim, Rebirth = ready, Training = the next sack is affordable. The tile of the
-- open screen stays highlighted. Replaces A's 2x2 menu tiles (Settings and Trade stay A's windows).
local Kit = require(script.Parent.Parent.Kit)
local System = script.Parent.Parent.System
local Data = require(System.Data)
local Modal = require(System.Modal)
local Motion = require(System.Motion)
local Theme = require(System.Theme)
local Ui = require(System.Ui)

local C = Theme.Colors
local Rail = {}

local TILE, TILE_COMPACT, GAP = 104, 88, 12

export type RailButton = {
	gui: TextButton,
	label: TextLabel,
	setBadge: (text: string?) -> (),
	setActive: (on: boolean) -> (),
	setCompact: (on: boolean) -> (),
}

-- One HUD tile: gradient square, icon, caption under the icon, optional badge. Used by both rails.
function Rail.button(
	parent: Instance,
	name: string,
	caption: string,
	key: Ui.Gradient,
	icon: string,
	glyph: string,
	onClick: (b: TextButton) -> ()
): RailButton
	local b = Instance.new("TextButton")
	b.Name = name
	b.Text = ""
	b.AutoButtonColor = false
	b.Selectable = true
	b.Size = UDim2.fromOffset(TILE, TILE)
	Ui.corner(b, 16)
	Ui.gradient(b, key)
	local stroke = Ui.stroke(b)
	Ui.studs(b, Theme.Studs.header)
	Ui.innerEdge(b, 0.45)
	local img = Ui.icon(b, icon, 70, glyph)
	img.AnchorPoint = Vector2.new(0.5, 0)
	img.Position = UDim2.new(0.5, 0, 0, 4)
	img.Size = UDim2.fromScale(0.68, 0.68)
	img.ZIndex = 2
	local label = Ui.text(b, caption, 22, { align = Enum.TextXAlignment.Center, name = "Caption" })
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.new(0.5, 0, 1, -2)
	label.Size = UDim2.new(1, 8, 0, 28)
	label.ZIndex = 3
	local badge, badgeText = Ui.badge(b)
	local stopPulse: (() -> ())? = nil
	Motion.interactive(b)
	b.Activated:Connect(function()
		onClick(b)
	end)
	b.Parent = parent
	return {
		gui = b,
		label = label,
		setBadge = function(text: string?)
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
		end,
		setActive = function(on: boolean)
			stroke.Color = if on then C.text else C.stroke
			stroke.Thickness = if on then 5 else Theme.Layout.stroke
		end,
		setCompact = function(on: boolean)
			local size = if on then TILE_COMPACT else TILE
			b.Size = UDim2.fromOffset(size, size)
			label.Visible = not on -- phones: icon only (the tile keeps its Name for accessibility)
			img.Size = if on then UDim2.fromScale(0.8, 0.8) else UDim2.fromScale(0.68, 0.68)
			img.Position = if on then UDim2.new(0.5, 0, 0, 8) else UDim2.new(0.5, 0, 0, 4)
		end,
	}
end

export type LeftRail = { update: () -> () }

function Rail.new(parent: Instance): LeftRail
	local root = Ui.frame(parent, "LeftRail", UDim2.fromOffset(TILE, 4 * TILE + 3 * GAP))
	Kit.autoScale(root)
	Ui.list(root, GAP)

	local buttons: { [string]: RailButton } = {}
	local entries = {
		{ "Shop", "Shop", "gold", "icon/shop", "$" },
		{ "Index", "Index", "cyan", "icon/index", "?" },
		{ "Rebirth", "Rebirth", "violet", "icon/rebirth", "R" },
		{ "Training", "Training", "orange", "icon/training", "!" },
	}
	for i, e in entries do
		local screen = e[1]
		local btn = Rail.button(root, screen, e[2], e[3] :: any, e[4], e[5], function(gui: TextButton)
			Modal.toggle(screen, gui)
		end)
		btn.gui.LayoutOrder = i
		buttons[screen] = btn
	end

	Kit.onLayout(function(compact: boolean)
		local tile = if compact then TILE_COMPACT else TILE
		root.Size = UDim2.fromOffset(tile, 4 * tile + 3 * GAP)
		root.AnchorPoint = Vector2.new(0, 0)
		root.Position = if compact then UDim2.fromOffset(10, 8) else UDim2.new(0, 30, 0.333, 0)
		for _, btn in buttons do
			btn.setCompact(compact)
		end
	end)

	Modal.onChanged(function(name: string?)
		for screen, btn in buttons do
			btn.setActive(screen == name)
		end
	end)

	local function update()
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
	end
	return { update = update }
end

return Rail
