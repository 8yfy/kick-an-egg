--!strict
-- A's KICK button fires Shared.KickPressed(timing) → RequestKick. The kick itself (egg toss, front kick, impact
-- at launch) is KickLineController's cutscene, driven by the server's KickAt so every client sees it.
-- Studio only: press K for a perfect kick.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local CLIENT_COOLDOWN = 0.5 -- the server enforces the real rule; this just avoids spam

local KickController = {}

local requestKick: RemoteEvent
local lastPress = 0

local function kick(timing: number)
	local now = os.clock()
	if now - lastPress < CLIENT_COOLDOWN then
		return
	end
	lastPress = now
	requestKick:FireServer(math.clamp(timing, 0, 1))
end

function KickController:Init()
	requestKick = Remotes.get("RequestKick")
end

function KickController:Start()
	local kickPressed = Shared:WaitForChild("KickPressed") :: BindableEvent
	kickPressed.Event:Connect(function(timing: any)
		if typeof(timing) == "number" then
			kick(timing)
		end
	end)

	if RunService:IsStudio() then
		UserInputService.InputBegan:Connect(function(input, processed)
			if not processed and input.KeyCode == Enum.KeyCode.K then
				kickPressed:Fire(0.95)
			end
		end)
	end
end

return KickController
