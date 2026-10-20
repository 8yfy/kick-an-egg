--!strict
-- Prize Wheel window (opened from the wheel's podium prompt, "OpenMenu:Wheel"). Gold header; left: every prize
-- with its icon, what it pays you right now and its exact chance (Config/Wheel weights); right: YOUR SPINS, the
-- SPIN button (closes the window so you watch the wall wheel; WheelController animates the server's roll) and
-- the Robux spin packs. Packs: BUY R$ n (price from Roblox), NOT ON SALE while the developer product id is 0,
-- and in Studio only a STUDIO TEST button for id-0 packs (WheelTestSpins; ignored by live servers).
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Wheel = require(Shared.Config.Wheel)

local System = script.Parent.Parent.System
local Data = require(System.Data)
local Modal = require(System.Modal)
local Theme = require(System.Theme)
local Ui = require(System.Ui)
local Kit = require(script.Parent.Parent.Kit)

local C = Theme.Colors
local WheelScreen = {}

local PACKS = { { "One", "1 SPIN" }, { "Three", "3 SPINS" }, { "Ten", "10 SPINS" } }

local function remote(name: string): RemoteEvent
	local Remotes = require(Shared:WaitForChild("Remotes")) :: any
	return Remotes.get(name)
end

local function cashFor(seg: Wheel.Segment): number
	local ips = Players.LocalPlayer and Players.LocalPlayer:GetAttribute("IncomePerSecond")
	local rate = if typeof(ips) == "number" and ips == ips and ips > 0 then ips else 0
	return math.max(seg.min or 0, math.floor(rate * (seg.seconds or 0)))
end

local function spinning(): boolean
	local controllers = script.Parent.Parent.Parent:FindFirstChild("Controllers")
	local module = controllers and controllers:FindFirstChild("WheelController")
	if module and module:IsA("ModuleScript") then
		local ok, wc = pcall(require, module)
		if ok and typeof(wc) == "table" and wc.spinning then
			return wc.spinning()
		end
	end
	return false
end

function WheelScreen.define()
	Modal.define("Wheel", { title = "Prize Wheel", header = Theme.Headers.eggs, icon = "hud_eggs" }, function(shell)
		local body = shell.body
		local total = 0
		for _, s in Wheel.Segments do
			total += s.weight
		end

		-- Prizes (left) -----------------------------------------------------------------------------------
		local left = Ui.surface(body, "Prizes", C.card, Theme.Studs.body, 4)
		left.Size = UDim2.new(0.56, -10, 1, 0)
		local title = Ui.text(left, "PRIZES", 30, { stroke = 3, name = "Title" })
		title.Position = UDim2.fromOffset(16, 10)
		title.Size = UDim2.new(1, -32, 0, 38)
		local list = Ui.scroll(left, "List")
		list.Position = UDim2.fromOffset(10, 56)
		list.Size = UDim2.new(1, -20, 1, -66)
		Ui.padding(list, 4)
		Ui.list(list, 8)
		local amounts: { [number]: TextLabel } = {}
		for i, seg in Wheel.Segments do
			local row = Instance.new("Frame")
			row.Name = seg.key
			row.LayoutOrder = i
			row.Size = UDim2.new(1, -8, 0, 64)
			row.BackgroundColor3 = C.body
			row.Parent = list
			Ui.corner(row)
			Ui.stroke(row, 3)
			local chip = Instance.new("Frame")
			chip.Name = "Colour"
			chip.Size = UDim2.new(0, 14, 1, -12)
			chip.Position = UDim2.fromOffset(6, 6)
			chip.BackgroundColor3 = seg.color
			chip.BorderSizePixel = 0
			chip.Parent = row
			Ui.corner(chip, 4)
			local icon = Ui.frame(row, "Icon", UDim2.fromOffset(52, 52), UDim2.fromOffset(28, 6))
			Ui.art(icon, if seg.kind == "Cash" then "hud_money" else "hud_eggs")
			local name = Ui.text(row, "", 26, { stroke = 3, name = "Name" })
			name.Position = UDim2.fromOffset(88, 0)
			name.Size = UDim2.new(1, -190, 1, 0)
			if seg.kind == "Egg" then
				name.Text = `{string.upper(seg.rarity or "")} EGG` .. (if seg.jackpot then "  (JACKPOT)" else "")
				name.TextColor3 = Theme.RarityText[seg.rarity or ""] or C.text
			else
				name.TextColor3 = C.cash
				amounts[i] = name
			end
			local chance = Ui.text(row, `{math.floor(seg.weight / total * 1000 + 0.5) / 10}%`, 26, {
				stroke = 3,
				align = Enum.TextXAlignment.Right,
				name = "Chance",
			})
			chance.AnchorPoint = Vector2.new(1, 0)
			chance.Position = UDim2.new(1, -14, 0, 0)
			chance.Size = UDim2.new(0, 96, 1, 0)
		end

		-- Spins + packs (right) ---------------------------------------------------------------------------
		local right = Ui.frame(body, "Right", UDim2.new(0.44, -10, 1, 0), UDim2.new(0.56, 10, 0, 0))
		local spinsBox = Ui.surface(right, "Spins", C.card, Theme.Studs.body, 4)
		spinsBox.Size = UDim2.new(1, 0, 0, 200)
		local spinsTitle = Ui.text(spinsBox, "YOUR SPINS", 28, { stroke = 3, align = Enum.TextXAlignment.Center })
		spinsTitle.Position = UDim2.fromOffset(0, 10)
		local spinsCount =
			Ui.text(spinsBox, "0", 56, { stroke = 4, align = Enum.TextXAlignment.Center, color = C.power })
		spinsCount.Position = UDim2.fromOffset(0, 44)
		local spin = Ui.button(spinsBox, {
			text = "SPIN!",
			style = "lime",
			size = UDim2.new(1, -32, 0, 64),
			textSize = 34,
			name = "Spin",
			onClick = function()
				remote("SpinWheel"):FireServer()
				Modal.close() -- watch the wheel on the wall
			end,
		})
		spin.gui.AnchorPoint = Vector2.new(0.5, 1)
		spin.gui.Position = UDim2.new(0.5, 0, 1, -14)

		local packsTitle = Ui.text(right, "GET SPINS", 30, { stroke = 3, name = "PacksTitle" })
		packsTitle.Position = UDim2.fromOffset(4, 214)
		local packs = Ui.frame(right, "Packs", UDim2.new(1, 0, 1, -258), UDim2.fromOffset(0, 258))
		Ui.list(packs, 12)
		type Pack = { key: string, label: string, button: Ui.Button, price: number? }
		local packList: { Pack } = {}
		for i, p in PACKS do
			local key, label = p[1], p[2]
			local product = Wheel.Products[key]
			local pack: Pack
			local button = Ui.button(packs, {
				text = label,
				style = "gold",
				size = UDim2.new(1, 0, 0, 60),
				textSize = 28,
				name = key,
				onClick = function()
					if product.id == 0 then
						if RunService:IsStudio() then
							remote("WheelTestSpins"):FireServer(key)
						end
					else
						MarketplaceService:PromptProductPurchase(Players.LocalPlayer, product.id)
					end
				end,
			})
			button.gui.LayoutOrder = i
			pack = { key = key, label = label, button = button }
			table.insert(packList, pack)
			if product.id == 0 then
				if RunService:IsStudio() then
					button.setText(`{label}  (STUDIO TEST)`)
				else
					button.setText(`{label}  NOT ON SALE`)
					button.setEnabled(false)
				end
			else
				button.setText(`{label}  ...`)
				task.spawn(function()
					local ok, info = pcall(function()
						return MarketplaceService:GetProductInfo(product.id, Enum.InfoType.Product)
					end)
					if ok and typeof(info) == "table" and typeof(info.PriceInRobux) == "number" then
						button.setText(`{label}  R$ {info.PriceInRobux}`)
					else
						button.setText(`{label}  NOT ON SALE`)
						button.setEnabled(false)
					end
				end)
			end
		end

		local function refresh()
			local spins = if typeof(Data.state.wheelSpins) == "number" then Data.state.wheelSpins else 0
			spinsCount.Text = tostring(spins)
			local busy = spinning() or typeof(Data.state.wheelPending) == "table"
			spin.setEnabled(spins > 0 and not busy)
			spin.setText(if busy then "SPINNING..." elseif spins > 0 then "SPIN!" else "BUY A SPIN")
			for i, label in amounts do
				label.Text = "$" .. Kit.formatNumber(cashFor(Wheel.Segments[i]))
			end
		end
		return { open = refresh, update = refresh }
	end)
end

return WheelScreen
