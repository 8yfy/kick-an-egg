--!strict
-- Partner A. The custom hotbar (replaces Roblox's default Backpack bar and the separate Kick Sack quickslot):
-- one row at the bottom centre. Slot 1 is always your Boxing Sack (its approved art, its name, key 1 / Q /
-- gamepad Y; out = gold glow + raised, exactly like the old quickslot). After it come only the eggs / pets you
-- EQUIPPED in the Bag (UI/Screens/Bag, UI/System/Backpack): each slot renders the LIVE 3D model the game builds
-- (Ui.eggArt / Ui.petArt) on its rarity colours, with its key (2-7; hidden on touch) and name. Click / tap /
-- key holds it (again = put away); the held one glows gold and lifts. Gamepad L1 / R1 cycle the items.
-- Phones fit 3 items so the bar stays clear of the jump button. While the kick controls show, only the sack
-- stays, left of KICK. The Bag itself opens from the right rail (UI/Hud/Drawers).
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Kit = require(script.Parent.Parent.Kit)
local SackGear = require(script.Parent.Parent.SackGear)
local System = script.Parent.Parent.System
local AssetIds = require(System.AssetIds)
local Backpack = require(System.Backpack)
local Data = require(System.Data)
local Motion = require(System.Motion)
local Theme = require(System.Theme)
local Ui = require(System.Ui)

local C = Theme.Colors
local GOLD = Color3.fromRGB(255, 215, 70)
local SIZE = 96 -- same tile as the old Kick Sack quickslot
local GAP = 14
local LABEL = 34 -- name lines under each tile
local ITEMS, ITEMS_COMPACT = 6, 3
local ITEM_KEYS =
	{ Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six, Enum.KeyCode.Seven }

local Hotbar = {}

type Tile = {
	holder: Frame, -- tile + labels (one list cell)
	tile: TextButton,
	art: Frame,
	rarity: Frame,
	key: TextLabel,
	name: TextLabel,
	sub: TextLabel,
	edge: UIStroke,
}

local function keyBadge(parent: GuiObject, text: string): TextLabel
	local key = Instance.new("TextLabel")
	key.Name = "Key"
	key.BackgroundColor3 = C.border
	key.BackgroundTransparency = 0.1
	key.Size = UDim2.fromOffset(30, 30)
	key.Position = UDim2.fromOffset(-6, -6)
	key.Font = Theme.Font
	key.TextSize = 22
	key.TextColor3 = C.text
	key.Text = text
	key.ZIndex = 5
	key.Parent = parent
	Ui.corner(key, 8)
	Ui.stroke(key, 2, GOLD)
	return key
end

local function makeTile(parent: Instance, order: number, onClick: () -> ()): Tile
	local holder = Ui.frame(parent, "Slot" .. order, UDim2.fromOffset(SIZE + 20, SIZE + LABEL))
	holder.LayoutOrder = order
	local tile = Instance.new("TextButton")
	tile.Name = "Tile"
	tile.Text = ""
	tile.AutoButtonColor = false
	tile.AnchorPoint = Vector2.new(0.5, 0)
	tile.Position = UDim2.new(0.5, 0, 0, 6)
	tile.Size = UDim2.fromOffset(SIZE, SIZE)
	tile.BackgroundColor3 = C.card
	tile.BackgroundTransparency = 0.05
	tile.Selectable = true
	tile.Parent = holder
	Ui.corner(tile, 18)
	local edge = Ui.stroke(tile, 5) -- one outline: dark, gold while held / out
	Motion.interactive(tile)
	tile.Activated:Connect(onClick)

	local rarity = Ui.frame(tile, "Rarity", UDim2.new(1, -12, 1, -12), UDim2.fromOffset(6, 6))
	Ui.corner(rarity, 13)
	rarity.Visible = false
	local art = Ui.frame(tile, "Art", UDim2.fromScale(0.86, 0.86), UDim2.fromScale(0.5, 0.5))
	art.AnchorPoint = Vector2.new(0.5, 0.5)
	art.ZIndex = 2

	local name = Ui.text(holder, "", 16, { align = Enum.TextXAlignment.Center, stroke = 3, name = "ItemName" })
	name.AnchorPoint = Vector2.new(0.5, 1)
	name.Position = UDim2.new(0.5, 0, 1, -16)
	name.Size = UDim2.new(1, 0, 0, 14)
	name.TextScaled = true
	local sub = Ui.text(holder, "", 18, { align = Enum.TextXAlignment.Center, stroke = 3, name = "Sub" })
	sub.AnchorPoint = Vector2.new(0.5, 1)
	sub.Position = UDim2.new(0.5, 0, 1, -2)
	sub.Size = UDim2.new(1, 0, 0, 16)
	return {
		holder = holder,
		tile = tile,
		art = art,
		rarity = rarity,
		key = keyBadge(tile, ""),
		name = name,
		sub = sub,
		edge = edge,
	}
end

local function setLit(t: Tile, on: boolean)
	t.edge.Color = if on then GOLD else C.border
	t.edge.Thickness = if on then 6 else 5
	Motion.tween(t.tile, 0.15, { Position = UDim2.new(0.5, 0, 0, if on then 0 else 6) })
end

export type Hotbar = { gui: Frame, update: () -> () }

function Hotbar.new(parent: Instance, kickPanel: GuiObject?): Hotbar
	local root = Ui.frame(parent, "Hotbar", UDim2.fromOffset((ITEMS + 1) * (SIZE + 20 + GAP), SIZE + LABEL + 6))
	root.AnchorPoint = Vector2.new(0.5, 1)
	Kit.autoScale(root)
	local list = Ui.list(root, GAP, true, Enum.HorizontalAlignment.Center)
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom

	local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local function isPad(): boolean
		return UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled
	end

	-- Slot 1: the Boxing Sack ---------------------------------------------------------------------------------
	local sack = makeTile(root, 0, function()
		SackGear.toggle()
	end)
	sack.sub.Text = "BOXING SACK"
	sack.sub.TextColor3 = C.power
	local sackArt: ImageLabel? = nil
	local shownTier = 0
	local sackOut = false

	local function paintSackOut()
		local _, out = SackGear.tool()
		if out == sackOut then
			return
		end
		sackOut = out
		setLit(sack, out)
		if out then
			Motion.popIn(sack.tile)
		end
	end

	local function paintSack()
		local tier, sackName = 1, "Burlap Sack"
		for _, row in Data.sacks() do
			if row.state == "Equipped" then
				tier, sackName = row.tier, row.name
			end
		end
		if tier ~= shownTier then
			local first = shownTier == 0
			shownTier = tier
			if sackArt then
				sackArt:Destroy()
			end
			sackArt = Ui.art(sack.art, AssetIds.sack(sackName) or ("sack:" .. sackName))
			sack.name.Text = string.upper(sackName)
			if not first then
				Motion.popIn(sack.tile) -- a new sack
			end
		end
		sack.key.Visible = not touch
		sack.key.Text = if isPad() then "Y" else "1"
		paintSackOut()
	end

	-- Slots 2+: equipped eggs / pets ---------------------------------------------------------------------------
	local tiles: { Tile } = {}
	local shown: { string } = {} -- "<kind>:<modelKey>" drawn in each tile (rebuild the 3D model only on change)
	local items: { Backpack.Item } = {}
	local maxItems = ITEMS
	local cursor = 0

	local function holdIndex(i: number)
		local item = items[i]
		if item then
			Backpack.hold(item)
		end
	end
	for i = 1, ITEMS do
		local index = i
		tiles[i] = makeTile(root, i, function()
			holdIndex(index)
		end)
		shown[i] = ""
	end

	local function paintItems()
		local kicking = kickPanel ~= nil and kickPanel.Visible
		items = Backpack.equipped()
		for i, t in tiles do
			local item = if i <= maxItems and not kicking then items[i] else nil
			t.holder.Visible = item ~= nil
			-- Lets contextual guidance point at the actual live slot, even when its order changes.
			t.tile:SetAttribute("ItemUid", if item then item.uid else nil)
			t.tile:SetAttribute("ItemKind", if item then item.kind else nil)
			if item then
				local id = item.kind .. ":" .. item.key
				if id ~= shown[i] then
					shown[i] = id
					for _, c in t.art:GetChildren() do
						if c:IsA("ViewportFrame") then
							c:Destroy()
						end
					end
					if item.kind == "Egg" then
						Ui.eggArt(t.art, item.key)
					else
						Ui.petArt(t.art, item.key)
					end
				end
				t.rarity.Visible = true
				Ui.fill(t.rarity, Theme.Rarity[item.rarity] or Theme.Rarity.Common)
				t.rarity.BackgroundTransparency = 0.35
				t.key.Visible = not touch
				t.key.Text = tostring(i + 1)
				t.name.Text = string.upper(item.name)
				t.sub.Text = if item.kind == "Egg" then "EGG" else string.upper(item.rarity)
				local pair = Theme.Rarity[item.rarity] or Theme.Rarity.Common
				t.sub.TextColor3 = if item.kind == "Egg" then C.power else pair[1]
				setLit(t, item.held)
			end
		end
	end

	local function update()
		paintSack()
		paintItems()
	end

	-- layout: bottom centre; while the kick controls show only the sack stays, left of KICK
	local function place()
		local kicking = kickPanel ~= nil and kickPanel.Visible
		local compact = Kit.compact()
		maxItems = if compact then ITEMS_COMPACT else ITEMS
		Backpack.setCapacity(maxItems)
		local x = if kicking then (if compact then -150 else -250) else 0
		Motion.tween(root, 0.2, { Position = UDim2.new(0.5, x, 1, if compact then -4 else -10) })
		paintItems()
	end
	Kit.onLayout(place)
	if kickPanel then
		kickPanel:GetPropertyChangedSignal("Visible"):Connect(place)
	end
	root.Position = UDim2.new(0.5, 0, 1, -10)

	-- keeps the sack glow honest whatever took it out (Q, gamepad, the server putting it away mid-chase)
	local function watch(character: Model)
		character.ChildAdded:Connect(paintSackOut)
		character.ChildRemoved:Connect(paintSackOut)
		paintSackOut()
	end
	local me = Players.LocalPlayer
	me.CharacterAdded:Connect(watch)
	if me.Character then
		watch(me.Character)
	end
	UserInputService.LastInputTypeChanged:Connect(paintSack)
	Backpack.onChanged(paintItems)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or UserInputService:GetFocusedTextBox() then
			return
		end
		local key = input.KeyCode
		if key == Enum.KeyCode.One then
			SackGear.toggle() -- Q / gamepad Y keep working through UI/SackGear
			return
		end
		local i = table.find(ITEM_KEYS, key)
		if i and i <= maxItems then
			holdIndex(i)
		elseif key == Enum.KeyCode.ButtonR1 or key == Enum.KeyCode.ButtonL1 then
			local n = math.min(#items, maxItems)
			if n > 0 then
				cursor = (cursor + (if key == Enum.KeyCode.ButtonR1 then 1 else -1) - 1) % n + 1
				holdIndex(cursor)
			end
		end
	end)

	update()
	place()
	return { gui = root, update = update }
end

return Hotbar
