--!strict
-- Run as a temporary server Script in a single-player Studio playtest. Never maps into a production build.
-- Uses isolated fixtures: no live DataStore reads/writes, no replacement of the production leaderboard service.
local HttpService = game:GetService("HttpService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Boards = require(Shared.Builders.Map.Boards)
local Podiums = require(game:GetService("ServerScriptService").Server.Util.LeaderboardPodiums)
local Emotes = require(game:GetService("ServerScriptService").Server.Util.PodiumEmotes)
local results = {}
local function check(name: string, condition: boolean)
	table.insert(results, { name = name, passed = condition })
	assert(condition, name)
end
local function settle(test: () -> boolean, seconds: number?)
	local deadline = os.clock() + (seconds or 5)
	repeat
		if test() then
			return
		end
		task.wait()
	until os.clock() > deadline
	error("timed out waiting for avatar update")
end
local fixture = Instance.new("Folder")
fixture.Name = "PodiumQA"
fixture.Parent = workspace
local function board(key: string, offset: number): Model
	return Boards.build(fixture, CFrame.new(0, -500, offset), key, Color3.fromRGB(255, 190, 40), -525)
end
local function rig(): Model
	local model = Instance.new("Model")
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Transparency = 1
	root.Parent = model
	local body = Instance.new("Part")
	body.Name = "Torso"
	body.Size = Vector3.new(12, 14, 10) -- intentionally oversized: verify uniform fitting
	body.Parent = model
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1 = root, body
	weld.Parent = root
	Instance.new("Humanoid").Parent = model
	Instance.new("Script").Parent = model
	Instance.new("Tool").Parent = model
	return model
end

local ok, err = pcall(function()
	local description = Instance.new("HumanoidDescription")
	check("no equipped emotes produces no invented dance", #Emotes.choices(description) == 0)
	description:SetEmotes({ Salute = { 3360689775 }, Agree = { 4849487550 }, Point = { 3576823880 } })
	description:SetEquippedEmotes({ "Salute", "Agree" })
	local choices = Emotes.choices(description)
	local equippedOnly = #choices == 2
	for _, choice in choices do
		equippedOnly = equippedOnly and (choice.name == "Salute" or choice.name == "Agree") and choice.id ~= 3576823880
	end
	check("emote candidates exclude owned but unequipped emotes", equippedOnly)
	description:Destroy()
	local power, donations = board("Power", 0), board("Donations", 40)
	check("three rank podiums per board", #power.Winners:GetChildren() == 3 and #donations.Winners:GetChildren() == 3)
	local first, second, third = power.Winners.Rank1, power.Winners.Rank2, power.Winners.Rank3
	check(
		"gold center is tallest, silver left, bronze right",
		first.AvatarAnchor.Position.Y > second.AvatarAnchor.Position.Y
			and second.AvatarAnchor.Position.Y > third.AvatarAnchor.Position.Y
			and second.AvatarAnchor.Position.X < first.AvatarAnchor.Position.X
			and third.AvatarAnchor.Position.X > first.AvatarAnchor.Position.X
	)
	check("avatars face out from the board", first.AvatarAnchor.CFrame.LookVector:Dot(Vector3.zAxis) > 0.99)
	local prompt = donations.Podium:FindFirstChildOfClass("ProximityPrompt")
	local bronze = donations.Winners.Rank3.Cap
	local donationTrim = donations.PodiumTrim
	local side = bronze.CFrame:PointToObjectSpace(donationTrim.Position)
	check(
		"Donate prompt sits beside winners with a clear gap",
		prompt ~= nil
			and prompt:GetAttribute("Action") == "OpenMenu:Donate"
			and side.X - donationTrim.Size.X / 2 - bronze.Size.X / 2 >= 2
			and math.abs(side.Z) < 0.1
	)

	local calls: { [number]: number } = {}
	local gates: { [number]: BindableEvent } = {}
	local fail = true
	gates[101] = Instance.new("BindableEvent")
	local renderer = Podiums.new(function(id: number): Model
		calls[id] = (calls[id] or 0) + 1
		local gate = gates[id]
		if gate then
			gate.Event:Wait()
		end
		if id == 404 and fail then
			error("expected QA fetch failure")
		end
		return rig()
	end)
	local entries =
		{ { userId = 101, name = "First" }, { userId = 102, name = "Second" }, { userId = 103, name = "Third" } }
	renderer:Update(power, entries)
	renderer:Update(donations, entries)
	check(
		"pending avatar requests do not block board updates",
		first:GetAttribute("AvatarStatus") == "Loading" and donations.Winners.Rank3:GetAttribute("UserId") == 103
	)
	gates[101]:Fire()
	settle(function()
		return first:GetAttribute("AvatarStatus") == "Ready"
			and donations.Winners.Rank1:GetAttribute("AvatarStatus") == "Ready"
	end)
	check("shared winners fetched once across both boards", calls[101] == 1 and calls[102] == 1 and calls[103] == 1)
	check("both boards own separate avatar copies", first.Avatar ~= donations.Winners.Rank1.Avatar)
	local safe, feet, fitted = true, true, true
	for _, b in { power, donations } do
		for _, podium in b.Winners:GetChildren() do
			local avatar = podium.Avatar
			local box, size = avatar:GetBoundingBox()
			feet = feet and math.abs(box.Position.Y - size.Y / 2 - podium.AvatarAnchor.Position.Y) < 0.01
			fitted = fitted and size.X <= 6.21 and size.Y <= 6.81 and size.Z <= 5.61
			safe = safe and avatar.HumanoidRootPart.Anchored
			for _, item in avatar:GetDescendants() do
				if item:IsA("BaseScript") or item:IsA("Tool") then
					safe = false
				elseif item:IsA("BasePart") then
					safe = safe and not item.CanCollide and not item.CanTouch and not item.CanQuery
				end
			end
		end
	end
	check("six safe anchored avatars without executable scripts or tools", safe)
	check("avatars without equipped emotes remain standing", first.Avatar:GetAttribute("EmoteStatus") == "NoneEquipped")
	local physics = game:GetService("PhysicsService")
	check(
		"display group ignores players, eggs and default targeting rays",
		not physics:CollisionGroupsAreCollidable("LeaderboardDisplay", "Players")
			and not physics:CollisionGroupsAreCollidable("LeaderboardDisplay", "Eggs")
			and not physics:CollisionGroupsAreCollidable("LeaderboardDisplay", "Default")
	)
	check("feet stand on all six podium caps", feet)
	check("oversized avatars fit the podiums without distortion", fitted)
	local original = first.Avatar
	entries[1].name = "Updated name"
	renderer:Update(power, entries)
	check(
		"unchanged rankings reuse avatars while updating names",
		first.Avatar == original and first.Body.Display.PlayerName.Text == "Updated name" and calls[101] == 1
	)

	gates[201] = Instance.new("BindableEvent")
	renderer:Update(power, { { userId = 201, name = "Slow winner" }, entries[2], entries[3] })
	check("old winner cleared immediately when rank changes", first:FindFirstChild("Avatar") == nil)
	renderer:Update(power, { { userId = 104, name = "New winner" }, entries[3], entries[2] })
	gates[201]:Fire()
	task.wait(0.1)
	check("late fetch cannot replace a newer winner", first.Avatar:GetAttribute("AvatarUserId") == 104)
	check(
		"second and third avatars swap with their ranks",
		second.Avatar:GetAttribute("AvatarUserId") == 103 and third.Avatar:GetAttribute("AvatarUserId") == 102
	)

	gates[202] = Instance.new("BindableEvent")
	renderer:Update(power, { { userId = 202, name = "Pending" } })
	renderer:Update(power, {})
	gates[202]:Fire()
	task.wait(0.1)
	check(
		"empty rankings clear all avatars and pending loads",
		first:FindFirstChild("Avatar") == nil
			and second:FindFirstChild("Avatar") == nil
			and third:FindFirstChild("Avatar") == nil
			and first.Body.Display.PlayerName.Text == "UNCLAIMED"
			and first:GetAttribute("AvatarStatus") == "Empty"
	)
	renderer:Update(power, { { userId = 404, name = "Unavailable winner" } })
	settle(function()
		return first:GetAttribute("AvatarStatus") == "Unavailable"
	end)
	check(
		"fetch failure leaves an honest empty slot",
		first:FindFirstChild("Avatar") == nil and first.Body.Display.PlayerName.Text == "Unavailable winner"
	)
	fail = false
	renderer:Update(power, { { userId = 404, name = "Recovered winner" } })
	settle(function()
		return first:GetAttribute("AvatarStatus") == "Ready"
	end)
	check(
		"failed avatars retry on the next refresh",
		calls[404] == 2 and first.Avatar:GetAttribute("AvatarUserId") == 404
	)
	renderer:Update(power, { { userId = -1, name = "Studio guest" } })
	check(
		"invalid Studio guest IDs never request a fake avatar",
		calls[-1] == nil and first:FindFirstChild("Avatar") == nil
	)

	gates[205] = Instance.new("BindableEvent")
	renderer:Update(power, { { userId = 205, name = "Removed board" } })
	power:Destroy()
	gates[205]:Fire()
	task.wait(0.1)
	check("removed boards reject pending avatars", first.Parent == nil)
	-- Native avatars can initially include detached accessory parts hundreds of studs away. This
	-- catches measuring before private WorldModel assembly, which would shrink the display to a speck.
	local player = game:GetService("Players"):GetPlayers()[1]
	if player and player.UserId > 0 then
		local native = Podiums.new()
		native:Update(donations, { { userId = player.UserId, name = player.DisplayName } })
		settle(function()
			return donations.Winners.Rank1:GetAttribute("AvatarStatus") == "Ready"
		end, 30)
		local nativeAvatar = donations.Winners.Rank1.Avatar
		check(
			"native avatar accessories assemble before measuring display size",
			nativeAvatar.HumanoidRootPart.Size.Y > 0.5 and nativeAvatar.Head.Size.Y > 0.1
		)
	end
	for _, gate in gates do
		gate:Destroy()
	end
end)
fixture:Destroy()
workspace:SetAttribute(
	"PodiumQAResults",
	HttpService:JSONEncode({ passed = ok, checks = results, error = if ok then nil else tostring(err) })
)
if not ok then
	error(err)
end
print(`[PodiumQA] {#results} checks passed`)
