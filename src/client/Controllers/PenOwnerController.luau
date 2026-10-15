--!strict
-- Pen owner display: over every OCCUPIED pen, only the owner's Roblox avatar headshot (rbxthumb AvatarHeadShot,
-- Roblox's supported thumbnail content) with their Roblox username under it. Nothing else: no panel, banner,
-- border or "free pen" text; a free pen shows nothing. Transparent BillboardGui high above the pen's centre
-- (Base<i>.PenArea), sized in studs so it shrinks with distance (displays of neighbouring pens don't pile up),
-- hidden beyond MAX_DISTANCE. Follows Base<i>.OwnerUserId (PlotService): a new owner swaps it, a player leaving
-- (0) hides it. If the headshot can't load, only the username shows.

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")

local MAX_DISTANCE = 220
local HEIGHT = 22 -- studs above the pen's floor
local WIDTH = 9 -- studs

local PenOwnerController = {}

type Display = {
	base: Model,
	gui: BillboardGui,
	photo: ImageLabel,
	username: TextLabel,
	shown: number?, -- userId on display
}

local displays: { [Model]: Display } = {}

local function build(base: Model, center: BasePart): Display
	local gui = Instance.new("BillboardGui")
	gui.Name = "PenOwner"
	gui.Size = UDim2.fromScale(WIDTH, WIDTH * 0.95) -- studs
	gui.StudsOffsetWorldSpace = Vector3.new(0, HEIGHT, 0)
	gui.LightInfluence = 0
	gui.MaxDistance = MAX_DISTANCE
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.Adornee = center
	local photo = Instance.new("ImageLabel")
	photo.Name = "Avatar"
	photo.BackgroundTransparency = 1
	photo.AnchorPoint = Vector2.new(0.5, 0)
	photo.Position = UDim2.fromScale(0.5, 0)
	photo.Size = UDim2.fromScale(0.75, 0.75)
	photo.ScaleType = Enum.ScaleType.Fit
	photo.Parent = gui
	local username = Instance.new("TextLabel")
	username.Name = "Username"
	username.BackgroundTransparency = 1
	username.AnchorPoint = Vector2.new(0.5, 1)
	username.Position = UDim2.fromScale(0.5, 1)
	username.Size = UDim2.fromScale(1, 0.22)
	username.Font = Enum.Font.FredokaOne
	username.TextScaled = true
	username.TextColor3 = Color3.new(1, 1, 1)
	local stroke = Instance.new("UIStroke") -- (plain readable outline on any sky or ground)
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(20, 22, 35)
	stroke.Parent = username
	username.Parent = gui
	gui.Parent = center
	return { base = base, gui = gui, photo = photo, username = username, shown = nil }
end

local function paint(display: Display)
	local uid = display.base:GetAttribute("OwnerUserId")
	local userId = if typeof(uid) == "number" then uid else 0
	if display.shown == userId then
		return
	end
	display.shown = userId
	if userId <= 0 then
		display.gui.Enabled = false -- a free pen shows nothing
		display.photo.Image = ""
		display.username.Text = ""
		return
	end
	local owner = Players:GetPlayerByUserId(userId)
	display.username.Text = if owner then owner.Name else ""
	display.photo.Image = `rbxthumb://type=AvatarHeadShot&id={userId}&w=150&h=150`
	display.gui.Enabled = true
	task.spawn(function()
		local ok = pcall(function()
			ContentProvider:PreloadAsync({ display.photo }, function(_, status)
				if status == Enum.AssetFetchStatus.Failure and display.shown == userId then
					display.photo.Image = "" -- (just the username then)
				end
			end)
		end)
		if not ok and display.shown == userId then
			display.photo.Image = ""
		end
	end)
	if not owner then -- the server set the owner before this client knows the player: name it when it arrives
		task.spawn(function()
			local name = ""
			pcall(function()
				name = Players:GetNameFromUserIdAsync(userId)
			end)
			if display.shown == userId then
				display.username.Text = name
			end
		end)
	end
end

local function track(base: Instance)
	if not base:IsA("Model") or displays[base] then
		return
	end
	local center = base:WaitForChild("PenArea", 30)
	if not center or not center:IsA("BasePart") then
		return
	end
	local display = build(base, center)
	displays[base] = display
	paint(display)
	base:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
		paint(display)
	end)
end

function PenOwnerController:Start()
	task.spawn(function()
		local map = workspace:WaitForChild("Map", 60)
		local safeZone = map and map:WaitForChild("SafeZone", 30)
		local bases = safeZone and safeZone:WaitForChild("Bases", 30)
		if not bases then
			return
		end
		for _, base in bases:GetChildren() do
			task.spawn(track, base)
		end
		bases.ChildAdded:Connect(function(base)
			task.spawn(track, base)
		end)
	end)
	-- a player who leaves never stays on display, even before the server clears OwnerUserId
	Players.PlayerRemoving:Connect(function(left)
		for _, display in displays do
			if display.shown == left.UserId then
				display.shown = 0
				display.gui.Enabled = false
			end
		end
	end)
end

return PenOwnerController
