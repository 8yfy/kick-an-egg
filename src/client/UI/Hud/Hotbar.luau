--!strict
-- Partner A. Custom hotbar (replaces Roblox's default Backpack bar; UI/SackGear turns that off). Your first
-- carried eggs / stored pets (UI/System/Backpack order) as slots that show the LIVE 3D model the game builds
-- (Ui.eggArt / Ui.petArt), on the item's rarity colours, with the key (1-8; hidden on touch) and an egg / pet tag.
-- The one in your hands glows gold and lifts. Click / tap / key holds it, again puts it away. The last slot is
-- BAG (B; gamepad DPad Up): your item count, opens the full backpack (UI/Screens/Bag). Gamepad L1 / R1 cycle.
-- Sits right of the Kick Sack quickslot; phones show 4 slots so it stays clear of the jump button. Hidden while
-- the kick controls show.
local UserInputService = game:GetService("UserInputService")

local Kit = require(script.Parent.Parent.Kit)
local System = script.Parent.Parent.System
local Backpack = require(System.Backpack)
local Modal = require(System.Modal)
local Motion = require(System.Motion)
local Theme = require(System.Theme)
local Ui = require(System.Ui)

local C = Theme.Colors
local GOLD = Color3.fromRGB(255, 215, 70)
local SLOT = 88
local GAP = 10
local SLOTS, SLOTS_COMPACT = 8, 4
local KEYS = {
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.Four,
	Enum.KeyCode.Five,
	Enum.KeyCode.Six,
	Enum.KeyCode.Seven,
	Enum.KeyCode.Eight,
}

local Hotbar = {}

type Slot = {
	gui: TextButton,
	art: Frame,
	rarity: Frame,
	tag: TextLabel,
	key: TextLabel,
	glow: UIStroke,
	lift: UIScale,
	shown: string, -- "<kind>:<modelKey>" currently drawn (rebuild the 3D model only when it changes)
	item: Backpack.Item?,
}

local function clearArt(art: Frame)
	for _, c in art:GetChildren() do
		if c:IsA("ViewportFrame") then
			c:Destroy()
		end
	end
end

local function makeSlot(parent: Instance, index: number, onClick: () -> ()): Slot
	local b = Instance.new("TextButton")
	b.Name = "Slot" .. index
	b.Text = ""
	b.AutoButtonColor = false
	b.LayoutOrder = index
	b.Size = UDim2.fromOffset(SLOT, SLOT)
	b.BackgroundColor3 = C.card
	b.BackgroundTransparency = 0.05
	b.Selectable = true
	b.Parent = parent
	Ui.corner(b, 16)
	Ui.stroke(b, 4)
	local glow = Ui.stroke(b, 0, GOLD)
	glow.Name = "Glow"
	local lift = Instance.new("UIScale")
	lift.Parent = b

	local rarity = Ui.frame(b, "Rarity", UDim2.new(1, -10, 1, -10), UDim2.fromOffset(5, 5))
	Ui.corner(rarity, 12)
	rarity.Visible = false
	local art = Ui.frame(b, "Art", UDim2.new(1, -8, 1, -8), UDim2.fromOffset(4, 4))
	art.ZIndex = 2

	local key = Ui.text(b, tostring(index), 20, { stroke = 3, name = "Key" })
	key.AnchorPoint = Vector2.new(0, 0)
	key.Position = UDim2.fromOffset(6, 2)
	key.Size = UDim2.fromOffset(22, 26)
	key.ZIndex = 4
	local tag = Ui.text(b, "", 14, { stroke = 2, name = "Tag" })
	tag.AnchorPoint = Vector2.new(0.5, 1)
	tag.Position = UDim2.new(0.5, 0, 1, -2)
	tag.Size = UDim2.new(1, -6, 0, 18)
	tag.ZIndex = 4

	Motion.interactive(b)
	b.Activated:Connect(onClick)
	return {
		gui = b,
		art = art,
		rarity = rarity,
		tag = tag,
		key = key,
		glow = glow,
		lift = lift,
		shown = "",
		item = nil,
	}
end

local function paint(slot: Slot, item: Backpack.Item?)
	slot.item = item
	local id = if item then item.kind .. ":" .. item.key else ""
	if id ~= slot.shown then
		slot.shown = id
		clearArt(slot.art)
		if item then
			if item.kind == "Egg" then
				Ui.eggArt(slot.art, item.key)
			else
				Ui.petArt(slot.art, item.key)
			end
		end
	end
	slot.gui.Visible = item ~= nil
	if not item then
		return
	end
	slot.rarity.Visible = true
	Ui.fill(slot.rarity, Theme.Rarity[item.rarity] or Theme.Rarity.Common)
	slot.rarity.BackgroundTransparency = 0.35
	slot.tag.Text = if item.kind == "Egg" then "EGG" else "PET"
	slot.tag.TextColor3 = if item.kind == "Egg" then C.power else C.text
	slot.glow.Thickness = if item.held then 4 else 0
	Motion.tween(slot.lift, 0.15, { Scale = if item.held then 1.08 else 1 })
end

export type Hotbar = { gui: Frame }

function Hotbar.new(parent: Instance, kickPanel: GuiObject?): Hotbar
	local root = Ui.frame(parent, "Hotbar", UDim2.fromOffset((SLOTS + 1) * (SLOT + GAP), SLOT + 16))
	root.AnchorPoint = Vector2.new(0, 1)
	local scale = Kit.autoScale(root)
	local row = Ui.frame(root, "Row")
	local layout = Ui.list(row, GAP, true)
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom

	local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local slots: { Slot } = {}
	local items: { Backpack.Item } = {}
	local maxSlots = SLOTS
	local cursor = 0 -- gamepad L1 / R1 position

	local function holdIndex(i: number)
		local slot = slots[i]
		if slot and slot.item and i <= maxSlots then
			Backpack.hold(slot.item)
		end
	end
	for i = 1, SLOTS do
		local index = i
		slots[i] = makeSlot(row, i, function()
			holdIndex(index)
		end)
		slots[i].key.Visible = not touch
	end

	-- BAG: opens the full backpack; shows how many items you carry.
	local bag = Instance.new("TextButton")
	bag.Name = "Bag"
	bag.Text = ""
	bag.AutoButtonColor = false
	bag.LayoutOrder = SLOTS + 1
	bag.Size = UDim2.fromOffset(SLOT, SLOT)
	bag.Selectable = true
	bag.Parent = row
	Ui.corner(bag, 16)
	Ui.fill(bag, Theme.Nav.Pets)
	Ui.stroke(bag, 4)
	local bagArt = Ui.art(bag, "hud_pets", UDim2.new(1, -24, 1, -34), Enum.ScaleType.Fit)
	bagArt.Position = UDim2.fromOffset(12, 4)
	local bagLabel = Ui.text(bag, "BAG", 18, { stroke = 3, name = "Label" })
	bagLabel.AnchorPoint = Vector2.new(0.5, 1)
	bagLabel.Position = UDim2.new(0.5, 0, 1, -3)
	bagLabel.Size = UDim2.new(1, 0, 0, 22)
	local bagKey = Ui.text(bag, "B", 20, { stroke = 3, name = "Key" })
	bagKey.Position = UDim2.fromOffset(6, 2)
	bagKey.Size = UDim2.fromOffset(22, 26)
	bagKey.Visible = not touch
	local badge, badgeText = Ui.badge(bag)
	Motion.interactive(bag)
	bag.Activated:Connect(function()
		Modal.toggle("Bag", bag)
	end)

	local function refresh()
		items = Backpack.items()
		for i, slot in slots do
			paint(slot, if i <= maxSlots then items[i] else nil)
		end
		badge.Visible = #items > 0
		badgeText.Text = tostring(#items)
	end

	local function place()
		local kicking = kickPanel ~= nil and kickPanel.Visible
		local compact = Kit.compact()
		maxSlots = if compact then SLOTS_COMPACT else SLOTS
		root.Visible = not kicking
		-- right of the Kick Sack tile (96 design px, centred), in screen pixels
		local s = scale.Scale
		root.Position = UDim2.new(0.5, math.floor((48 + 22) * s), 1, if compact then -18 else -40)
		refresh()
	end
	Kit.onLayout(place)
	if kickPanel then
		kickPanel:GetPropertyChangedSignal("Visible"):Connect(place)
	end
	Backpack.onChanged(refresh)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or UserInputService:GetFocusedTextBox() then
			return
		end
		local key = input.KeyCode
		local i = table.find(KEYS, key)
		if i then
			holdIndex(i)
		elseif key == Enum.KeyCode.B or key == Enum.KeyCode.DPadUp then
			Modal.toggle("Bag", bag)
		elseif key == Enum.KeyCode.ButtonR1 or key == Enum.KeyCode.ButtonL1 then
			local n = math.min(#items, maxSlots)
			if n > 0 then
				cursor = (cursor + (if key == Enum.KeyCode.ButtonR1 then 1 else -1) - 1) % n + 1
				holdIndex(cursor)
			end
		end
	end)

	return { gui = root }
end

return Hotbar
