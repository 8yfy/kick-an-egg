--!strict
-- The bottom Kick Sack quickslot (equipment, not a shop): one classic tool-slot tile at the bottom centre with your
-- CURRENT sack's approved 2D art (UI/System/AssetIds.sack, mapped by the sack's name for all 20), its name under
-- a "BOXING SACK" label, and the key: [1] on keyboards, (Y) on gamepads, nothing on touch (just tap it). Click /
-- tap / key / button takes the sack out or puts it away (UI/SackGear, the same Tool the server gives every
-- character). Out = gold glow + raised; away = plain. Pops when your sack changes (an upgrade) and on every use.
-- While the kick controls show (on the kick pad) it slides left of KICK so both fit. Survives respawns.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Kit = require(script.Parent.Parent.Kit)
local SackGear = require(script.Parent.Parent.SackGear)
local System = script.Parent.Parent.System
local AssetIds = require(System.AssetIds)
local Data = require(System.Data)
local Motion = require(System.Motion)
local Theme = require(System.Theme)
local Ui = require(System.Ui)

local C = Theme.Colors
local GOLD = Color3.fromRGB(255, 215, 70)
local SIZE = 96

local SackSlot = {}

export type SackSlot = { update: () -> () }

function SackSlot.new(parent: Instance, kickPanel: GuiObject?): SackSlot
	local root = Instance.new("Frame")
	root.Name = "SackSlot"
	root.BackgroundTransparency = 1
	root.AnchorPoint = Vector2.new(0.5, 1)
	root.Size = UDim2.fromOffset(SIZE + 120, SIZE + 34)
	root.Parent = parent
	Kit.autoScale(root)

	local tile = Instance.new("TextButton")
	tile.Name = "Tile"
	tile.Text = ""
	tile.AutoButtonColor = false
	tile.AnchorPoint = Vector2.new(0.5, 1)
	tile.Position = UDim2.new(0.5, 0, 1, -30)
	tile.Size = UDim2.fromOffset(SIZE, SIZE)
	tile.BackgroundColor3 = C.card
	tile.BackgroundTransparency = 0.05
	tile.Parent = root
	Ui.corner(tile, 18)
	local edge = Ui.stroke(tile, 5)
	local glow = Ui.stroke(tile, 0)
	glow.Name = "Glow"
	glow.Color = GOLD
	glow.Transparency = 1
	Motion.interactive(tile)

	local artFrame = Ui.frame(tile, "Art", UDim2.fromScale(0.86, 0.86), UDim2.fromScale(0.5, 0.5))
	artFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	local art: ImageLabel? = nil

	local key = Instance.new("TextLabel")
	key.Name = "Key"
	key.BackgroundColor3 = C.border
	key.BackgroundTransparency = 0.1
	key.Size = UDim2.fromOffset(30, 30)
	key.Position = UDim2.fromOffset(-6, -6)
	key.Font = Theme.Font
	key.TextSize = 22
	key.TextColor3 = C.text
	key.Text = "1"
	key.ZIndex = 4
	key.Parent = tile
	Ui.corner(key, 8)
	Ui.stroke(key, 2, GOLD)

	local title = Ui.text(root, "BOXING SACK", 18, { align = Enum.TextXAlignment.Center, stroke = 3, color = C.power })
	title.Name = "Title"
	title.AnchorPoint = Vector2.new(0.5, 1)
	title.Position = UDim2.new(0.5, 0, 1, -2)
	title.Size = UDim2.new(1, 0, 0, 16)
	local name = Ui.text(root, "", 16, { align = Enum.TextXAlignment.Center, stroke = 3 })
	name.Name = "SackName"
	name.AnchorPoint = Vector2.new(0.5, 1)
	name.Position = UDim2.new(0.5, 0, 1, -16)
	name.Size = UDim2.new(1, 0, 0, 14)

	local shownTier = 0
	local out = false

	local function paintKey()
		local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
		local pad = UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled
		key.Visible = not touch
		key.Text = if pad then "Y" else "1"
	end

	local function paintOut()
		local _, isOut = SackGear.tool()
		if isOut == out then
			return
		end
		out = isOut
		glow.Thickness = if out then 6 else 0
		glow.Transparency = if out then 0 else 1
		edge.Transparency = if out then 0.6 else 0
		Motion.tween(tile, 0.15, { Position = UDim2.new(0.5, 0, 1, if out then -36 else -30) })
		if out then
			Motion.popIn(tile)
		end
	end

	local function update()
		local tier, sackName = 1, "Burlap Sack"
		for _, row in Data.sacks() do
			if row.state == "Equipped" then
				tier, sackName = row.tier, row.name
			end
		end
		if tier ~= shownTier then
			local first = shownTier == 0
			shownTier = tier
			if art then
				art:Destroy()
			end
			art = Ui.art(artFrame, AssetIds.sack(sackName) or ("sack:" .. sackName))
			name.Text = string.upper(sackName)
			if not first then
				Motion.popIn(tile) -- a new sack
			end
		end
		paintKey()
		paintOut()
	end

	tile.Activated:Connect(function()
		SackGear.toggle()
	end)
	-- keeps the glow honest whatever took the sack out (key 1, gamepad, the server putting it away mid-chase)
	local function watch(character: Model)
		character.ChildAdded:Connect(paintOut)
		character.ChildRemoved:Connect(paintOut)
		paintOut()
	end
	local me = Players.LocalPlayer
	if me then
		me.CharacterAdded:Connect(watch)
		if me.Character then
			watch(me.Character)
		end
	end
	UserInputService.LastInputTypeChanged:Connect(paintKey)

	-- layout: bottom centre; beside KICK while the kick controls show
	local function place()
		local kicking = kickPanel ~= nil and kickPanel.Visible
		local compact = Kit.compact()
		local x = if kicking then (if compact then -150 else -250) else 0
		Motion.tween(root, 0.2, { Position = UDim2.new(0.5, x, 1, if compact then -4 else -10) })
	end
	Kit.onLayout(function()
		place()
	end)
	if kickPanel then
		kickPanel:GetPropertyChangedSignal("Visible"):Connect(place)
	end
	root.Position = UDim2.new(0.5, 0, 1, -10)
	update()
	place()
	return { update = update }
end

return SackSlot
