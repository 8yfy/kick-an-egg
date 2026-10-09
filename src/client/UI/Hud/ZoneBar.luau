--!strict
-- Zone progress bar on the left edge: one segment per zone (bottom = zone 1, top = zone 20), coloured
-- by the zone, with the player's avatar head as a marker at their current position along the runway.
-- Entering a new zone pops a big "ZONE n · NAME" banner (replaces the old zone arches/signs).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kit = require(script.Parent.Parent.Kit)
local Fx = require(script.Parent.Parent.Fx)
local Zones = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Zones"))

local ZoneBar = {}

local HEIGHT, WIDTH = 520, 46
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
	local root = Kit.panel({
		name = "ZoneBar",
		size = UDim2.fromOffset(WIDTH, HEIGHT),
		position = UDim2.new(0, 14, 0.45, 0),
		anchor = Vector2.new(0, 0.5),
		parent = parent,
		colors = Kit.Colors.dark,
		radius = 14,
	})
	Kit.autoScale(root)
	local track = Instance.new("Frame")
	track.Name = "Track"
	track.BackgroundTransparency = 1
	track.Position = UDim2.fromOffset(5, 5)
	track.Size = UDim2.new(1, -10, 1, -10)
	track.ClipsDescendants = true
	track.Parent = root
	local n = #Zones
	for i, zone in Zones do
		local seg = Instance.new("Frame")
		seg.Name = "Zone" .. i
		seg.BorderSizePixel = 0
		seg.AnchorPoint = Vector2.new(0, 1)
		seg.Position = UDim2.fromScale(0, 1 - (i - 1) / n)
		seg.Size = UDim2.new(1, 0, 1 / n, -2)
		Kit.gradient(seg, { zone.ground:Lerp(Color3.new(1, 1, 1), 0.15), zone.ground:Lerp(zone.accent, 0.35) })
		Kit.corner(seg, 6)
		seg.Parent = track
		local num = Kit.label({
			name = "Number",
			text = tostring(i),
			size = UDim2.fromScale(0.8, 0.8),
			position = UDim2.fromScale(0.1, 0.1),
			parent = seg,
			stroke = 2,
		})
		num.TextTransparency = 0.15
	end

	-- Avatar marker (headshot in a ring) + current zone name next to it.
	local marker = Kit.panel({
		name = "Marker",
		size = UDim2.fromOffset(56, 56),
		position = UDim2.new(0.5, 0, 1, 0),
		anchor = Vector2.new(0.5, 0.5),
		parent = root,
		colors = Kit.Colors.yellow,
		radius = 28,
	})
	marker.ZIndex = 5
	local face = Instance.new("ImageLabel")
	face.BackgroundTransparency = 1
	face.Size = UDim2.new(1, -10, 1, -10)
	face.Position = UDim2.fromOffset(5, 5)
	face.Image = `rbxthumb://type=AvatarHeadShot&id={Players.LocalPlayer.UserId}&w=150&h=150`
	face.ZIndex = 6
	Kit.corner(face, 23)
	face.Parent = marker

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

	local runEnd = Zones[n].start + Zones[n].length
	RunService.RenderStepped:Connect(function()
		local char = Players.LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not (hrp and hrp:IsA("BasePart")) then
			return
		end
		local z = hrp.Position.Z
		local k = math.clamp(z / runEnd, 0, 1)
		marker.Position = UDim2.new(0.5, 0, 1 - k, 0)
		local inRunway = z >= 0
		local id = if inRunway then zoneAt(z) else 0
		if id ~= current then
			current = id
			if id > 0 then
				announce(id)
			end
		end
	end)
end

return ZoneBar
