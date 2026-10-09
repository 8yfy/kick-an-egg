--!strict
-- Trade: lists the other players in the server. Partner B defines the TradeService payloads (B8),
-- so the request buttons stay disabled ("SOON") until that lands; nothing is fired yet.
local Players = game:GetService("Players")
local Kit = require(script.Parent.Parent.Kit)
local Window = require(script.Parent.Window)

export type Menu = { window: Window.Window, update: (data: { [string]: any }) -> () }

local TradeMenu = {}

function TradeMenu.new(parent: Instance): Menu
	local window = Window.new(parent, "Trade", Kit.Colors.blue)
	local body = window.body
	Kit.label({
		name = "Hint",
		text = "Pick a player to trade pets with",
		size = UDim2.new(1, 0, 0, 34),
		parent = body,
		color = Color3.fromRGB(220, 215, 240),
	})
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Players"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Position = UDim2.fromOffset(0, 44)
	scroll.Size = UDim2.new(1, 0, 1, -44)
	scroll.ScrollBarThickness = 10
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new()
	scroll.Parent = body
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 10)
	list.Parent = scroll
	local empty = Kit.label({
		name = "Empty",
		text = "Nobody else is here yet!",
		size = UDim2.new(1, 0, 0, 60),
		parent = scroll,
		color = Color3.fromRGB(160, 155, 180),
	})

	local function rebuild()
		for _, c in scroll:GetChildren() do
			if c:IsA("Frame") then
				c:Destroy()
			end
		end
		local n = 0
		for _, p in Players:GetPlayers() do
			if p ~= Players.LocalPlayer then
				n += 1
				local row = Kit.panel({
					name = p.Name,
					size = UDim2.new(1, -16, 0, 84),
					parent = scroll,
					colors = { Color3.fromRGB(70, 65, 95), Color3.fromRGB(50, 46, 70) },
					radius = 18,
				})
				local face = Instance.new("ImageLabel")
				face.BackgroundTransparency = 1
				face.Size = UDim2.fromOffset(64, 64)
				face.Position = UDim2.fromOffset(12, 10)
				face.Image = `rbxthumb://type=AvatarHeadShot&id={p.UserId}&w=150&h=150`
				Kit.corner(face, 32)
				face.Parent = row
				Kit.label({
					name = "Name",
					text = p.DisplayName,
					size = UDim2.new(1, -300, 0, 40),
					position = UDim2.fromOffset(90, 22),
					parent = row,
					align = Enum.TextXAlignment.Left,
				})
				local button = Kit.button({
					name = "Request",
					text = "SOON",
					size = UDim2.fromOffset(170, 62),
					position = UDim2.new(1, -12, 0.5, 0),
					anchor = Vector2.new(1, 0.5),
					parent = row,
					colors = Kit.Colors.grey,
					onClick = function() end,
				})
				button.Active = false
			end
		end
		empty.Visible = n == 0
	end
	window.onOpen(rebuild)
	Players.PlayerAdded:Connect(function()
		if window.isOpen() then
			rebuild()
		end
	end)
	Players.PlayerRemoving:Connect(function()
		if window.isOpen() then
			task.defer(rebuild)
		end
	end)

	return { window = window, update = function(_data: { [string]: any }) end }
end

return TradeMenu
