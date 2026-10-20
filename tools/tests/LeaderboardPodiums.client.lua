--!strict
-- Temporary Studio-only LocalScript. Run after filling the six podiums with playtest fixtures.
-- Does not restart any production controller. Camera, character and HUD are restored on completion.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local root = (player.Character or player.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart") :: BasePart
local camera = workspace.CurrentCamera :: Camera
local oldRoot, oldAnchored = root.CFrame, root.Anchored
local oldCamera, oldType = camera.CFrame, camera.CameraType
local target = CFrame.lookAt(Vector3.new(-140, 35, -155), Vector3.new(-192, 33, -155))
local results = {}
local function check(name: string, condition: boolean)
	table.insert(results, { name = name, passed = condition })
	assert(condition, name)
end
local function settle()
	task.wait(0.8)
end
RunService:BindToRenderStep("PodiumBadgeQA", Enum.RenderPriority.Camera.Value + 3, function()
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = target
end)
root.Anchored = true
local ok, err = pcall(function()
	root.CFrame = CFrame.new(-165, 14, -155)
	settle()
	local avatars = {}
	local visible, styled = 0, true
	for _, key in { "Power", "Donations" } do
		for rank = 1, 3 do
			local podium =
				workspace.Map.SafeZone:FindFirstChild("Leaderboard_" .. key).Winners:FindFirstChild("Rank" .. rank)
			local avatar = podium:FindFirstChild("Avatar")
			assert(avatar, "six populated podiums required for this visual fixture")
			table.insert(avatars, avatar)
			local badge = avatar.Head:FindFirstChild("LeaderboardRankBadge")
			if badge and badge.Enabled then
				visible += 1
			end
			styled = styled
				and badge ~= nil
				and badge.Medal.Rank.Text == "#" .. rank
				and not badge.AlwaysOnTop
				and badge.MaxDistance == 85
				and badge.Medal.BackgroundTransparency < 0.2
		end
	end
	check("six rank badges appear close to the boards", visible == 6)
	check("badges show matching ranks with readable medal styling", styled)
	local playing, equippedOnly, moving = 0, true, false
	local poses: { [Instance]: CFrame } = {}
	for _, avatar in avatars do
		local humanoid = avatar.Humanoid
		if avatar:GetAttribute("EmoteStatus") == "Playing" then
			playing += 1
			local d = humanoid:GetAppliedDescription()
			local name, id = avatar:GetAttribute("EmoteName"), avatar:GetAttribute("EmoteAssetId")
			local equipped = false
			for _, entry in d:GetEquippedEmotes() do
				equipped = equipped or entry.Name == name
			end
			equippedOnly = equippedOnly and equipped and table.find(d:GetEmotes()[name], id) ~= nil
			local tracks = humanoid.Animator:GetPlayingAnimationTracks()
			local looped = false
			for _, track in tracks do
				looped = looped or (track.IsPlaying and track.Looped and track.Length > 0)
			end
			equippedOnly = equippedOnly and looped
			for _, part in avatar:GetChildren() do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					poses[part] = avatar.HumanoidRootPart.CFrame:ToObjectSpace(part.CFrame)
				end
			end
		end
	end
	check("real equipped emotes loop on the display avatars", playing > 0 and equippedOnly)
	task.wait(0.35)
	for part, before in poses do
		local after = part.Parent.HumanoidRootPart.CFrame:ToObjectSpace(part.CFrame)
		local _, angle = before:ToObjectSpace(after):ToAxisAngle()
		moving = moving or (before.Position - after.Position).Magnitude > 0.02 or math.abs(angle) > 0.02
	end
	check("replicated emotes visibly move the avatar joints", moving)
	root.CFrame = CFrame.new(0, 14, -72)
	settle()
	local hidden = true
	for _, avatar in avatars do
		hidden = hidden and not avatar.Head.LeaderboardRankBadge.Enabled
	end
	check("badges hide when the player is far even with the camera nearby", hidden)
	root.CFrame = CFrame.new(-165, 14, -155)
	target = CFrame.lookAt(Vector3.new(-60, 35, -155), Vector3.new(-192, 33, -155))
	settle()
	hidden = true
	for _, avatar in avatars do
		hidden = hidden and not avatar.Head.LeaderboardRankBadge.Enabled
	end
	check("badges hide when the camera is too far away", hidden)
	target = CFrame.lookAt(Vector3.new(-140, 35, -155), Vector3.new(0, 35, -155))
	settle()
	hidden = true
	for _, avatar in avatars do
		hidden = hidden and not avatar.Head.LeaderboardRankBadge.Enabled
	end
	check("badges fade out when the boards leave view", hidden)
end)
RunService:UnbindFromRenderStep("PodiumBadgeQA")
root.CFrame, root.Anchored = oldRoot, oldAnchored
camera.CameraType, camera.CFrame = oldType, oldCamera
player:SetAttribute(
	"PodiumBadgeQAResults",
	game:GetService("HttpService")
		:JSONEncode({ passed = ok, checks = results, error = if ok then nil else tostring(err) })
)
if not ok then
	error(err)
end
print(`[PodiumBadgeQA] {#results} checks passed`)
