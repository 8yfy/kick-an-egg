--!strict
-- Zone track (approved HUD variant A): current zone name over a row of 20 bricks in the zone colours.
-- Entering a new zone pops a big "ZONE n · NAME" banner (replaces the old zone arches/signs).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kit = require(script.Parent.Parent.Kit)
local Fx = require(script.Parent.Parent.Fx)
local Zones = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Zones"))

local ZoneBar = {}

local BRICK, GAP = 13, 3
local EMOJI = {
	"🌼",
	"🏖️",
	"🍂",
	"🍄",
	"🌵",
	"❄️",
	"🍭",
	"🐠",
	"🌋",
	"💎",
	"🗿",
	"🌃",
	"👻",
	"☁️",
	"☣️",
	"⚙️",
	"🌌",
	"🔥",
	"🪐",
	"🌈",
}

local function zoneAt(z: number): number
	for _, zone in Zones do
		if z < zone.start + zone.length then
			return zone.id
		end
	end
	return #Zones
end

function ZoneBar.new(parent: Instance)
	-- Zone track: "Zone 3  Autumn Forest" over a row of small bricks in the zone colours. Zones up to the
	-- current one are solid, the current one is taller with a white outline. Above the menu tiles on
	-- desktop, under the quest on phones.
	local n = #Zones
	local root = Kit.panel({ name = "ZoneTrack", size = UDim2.fromOffset(n * (BRICK + GAP) + 12, 72), parent = parent })
	Kit.autoScale(root)
	Kit.onLayout(function(compact: boolean)
		root.AnchorPoint = if compact then Vector2.new(0.5, 0) else Vector2.new(0, 1)
		root.Position = if compact then UDim2.new(0.5, 0, 0, 50) else UDim2.new(0, 30, 0.333, -34)
	end)
	local caption = Instance.new("Frame")
	caption.Name = "Caption"
	caption.BackgroundTransparency = 1
	caption.Size = UDim2.new(1, 0, 0, 32)
	local capList = Instance.new("UIListLayout")
	capList.FillDirection = Enum.FillDirection.Horizontal
	capList.Padding = UDim.new(0, 10)
	capList.SortOrder = Enum.SortOrder.LayoutOrder
	capList.Parent = caption
	caption.Parent = root
	local zoneText = Kit.text(caption, "Zone", "Base", 26, 3)
	zoneText.LayoutOrder = 1
	local nameText = Kit.text(caption, "Name", "", 26, 3)
	nameText.LayoutOrder = 2

	local row = Instance.new("Frame")
	row.Name = "Bricks"
	row.BackgroundTransparency = 1
	row.Position = UDim2.fromOffset(0, 36)
	row.Size = UDim2.new(1, 0, 0, 34)
	local rowList = Instance.new("UIListLayout")
	rowList.FillDirection = Enum.FillDirection.Horizontal
	rowList.VerticalAlignment = Enum.VerticalAlignment.Bottom
	rowList.Padding = UDim.new(0, GAP)
	rowList.SortOrder = Enum.SortOrder.LayoutOrder
	rowList.Parent = row
	row.Parent = root
	local bricks: { { frame: Frame, stroke: UIStroke } } = {}
	for i, zone in Zones do
		local brick = Instance.new("Frame")
		brick.Name = "Zone" .. i
		brick.LayoutOrder = i
		brick.BorderSizePixel = 0
		brick.BackgroundColor3 = zone.ground
		Kit.corner(brick, 3)
		local st = Instance.new("UIStroke")
		st.Thickness = 2
		st.Color = Color3.new(0, 0, 0)
		st.Parent = brick
		brick.Parent = row
		bricks[i] = { frame = brick, stroke = st }
	end
	local function paint(id: number)
		for i, b in bricks do
			local here = i == id
			b.frame.Size = if here then UDim2.fromOffset(BRICK + 4, 30) else UDim2.fromOffset(BRICK, 20)
			b.frame.BackgroundTransparency = if i <= id then 0 else 0.55
			b.stroke.Color = if here then Color3.new(1, 1, 1) else Color3.new(0, 0, 0)
			b.stroke.Thickness = if here then 3 else 2
		end
		if id > 0 then
			zoneText.Text = `Zone {id}`
			nameText.Text = Zones[id].name
			nameText.TextColor3 = Zones[id].accent:Lerp(Color3.new(1, 1, 1), 0.35)
		else
			zoneText.Text = "Base"
			nameText.Text = ""
		end
	end
	paint(0)

	-- Big zone banner (top centre, under the quest bar)
	local banner = Kit.label({
		name = "ZoneBanner",
		text = "",
		size = UDim2.fromOffset(900, 90),
		position = UDim2.new(0.5, 0, 0.3, 0),
		anchor = Vector2.new(0.5, 0.5),
		parent = parent,
		stroke = 5,
	})
	-- rays sit behind the banner as a sibling (children would draw over the label's text)
	local bannerRays = Fx.rays(parent, 340, nil, 30)
	bannerRays.Position = banner.Position
	bannerRays.Visible = false

	banner.Visible = false
	Kit.autoScale(banner)
	local bannerGrad = Instance.new("UIGradient")
	bannerGrad.Rotation = 90
	bannerGrad.Parent = banner

	local current = 0
	local function announce(id: number)
		local zone = Zones[id]
		banner.Text = `{zone.name} {EMOJI[id] or ""}`
		-- left-to-right gradient from the zone's accent to its ground colour, kept bright
		local a = zone.accent:Lerp(Color3.new(1, 1, 1), 0.25)
		local b = zone.ground:Lerp(Color3.new(1, 1, 1), 0.35)
		bannerGrad.Rotation = 0
		bannerRays.ImageColor3 = a
		bannerGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, a),
			ColorSequenceKeypoint.new(0.5, a:Lerp(b, 0.5):Lerp(Color3.new(1, 1, 1), 0.2)),
			ColorSequenceKeypoint.new(1, b),
		})
		banner.Visible = true
		bannerRays.Visible = true
		banner.TextTransparency = 0
		Kit.pop(banner, 0.4)
		local token = id
		task.delay(2.2, function()
			if current == token then
				Kit.tween(banner, 0.35, { TextTransparency = 1 })
				task.wait(0.35)
				if current == token then
					banner.Visible = false
					bannerRays.Visible = false
				end
			end
		end)
	end

	RunService.RenderStepped:Connect(function()
		local char = Players.LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not (hrp and hrp:IsA("BasePart")) then
			return
		end
		local z = hrp.Position.Z
		local id = if z >= 0 then zoneAt(z) else 0
		if id ~= current then
			current = id
			paint(id)
			if id > 0 then
				announce(id)
			end
		end
	end)
end

return ZoneBar
