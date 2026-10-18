-- Temporary multiplayer QA LocalScript; not part of the production Rojo tree.
assert(game:GetService("RunService"):IsStudio() and game.PlaceId == 0)
local P = game.Players.LocalPlayer
local RS = game.ReplicatedStorage
local QA = RS:WaitForChild("PenUpgradeMultiQA")
local scripts = P:WaitForChild("PlayerScripts")
local UI = scripts:WaitForChild("Client"):WaitForChild("UI")
local Data = require(UI.System.Data)
local Audio = require(RS.Shared.Audio)
local MyBase = require(UI.MyBase)
local dataLevelBefore, baseLevelBefore
local deadline = os.clock() + 22
repeat
	task.wait(0.1)
until (Data.loaded() and MyBase.get()) or os.clock() > deadline
QA:FireServer("ready")
repeat
	task.wait(0.05)
until workspace:GetAttribute("PenUpgradeMultiAt") or os.clock() > deadline
local at = workspace:GetAttribute("PenUpgradeMultiAt")
assert(at, "No multiplayer start time")
while workspace:GetServerTimeNow() < at do
	task.wait()
end
dataLevelBefore = Data.state.penLevel
baseLevelBefore = MyBase.get():GetAttribute("PenLevel")
local notices = {}
local ownFX, foreignFX = false, false
local base = MyBase.get()
local area = base.PenArea
local conn = game:GetService("RunService").Heartbeat:Connect(function()
	local notice = workspace:FindFirstChild("PenUpgradeNotice", true)
	if notice then
		notices[notice] = true
	end
	local fx = workspace:FindFirstChild("PenUpgradeFX")
	if fx then
		for _, p in fx:GetDescendants() do
			if p:IsA("BasePart") then
				local relative = area.CFrame:PointToObjectSpace(p.Position)
				if math.abs(relative.X) <= area.Size.X / 2 + 8 and math.abs(relative.Z) <= area.Size.Z / 2 + 8 then
					ownFX = true
				else
					foreignFX = true
				end
			end
		end
	end
end)
require(RS.Shared.Remotes).get("UpgradePen"):FireServer()
-- Start the cleanup window at confirmation; request-to-confirmation latency is not effect time.
local confirmationDeadline = os.clock() + 10
repeat
	task.wait(0.05)
until Data.state.penLevel == 2 or os.clock() > confirmationDeadline
task.wait(1.95)
conn:Disconnect()
local count, audio = 0, 0
for _ in notices do
	count += 1
end
for _, r in Audio.history do
	if r.event == "PenUpgrade" then
		audio += 1
	end
end
QA:FireServer("report", {
	dataLevelBefore = dataLevelBefore,
	baseLevelBefore = baseLevelBefore,
	notices = count,
	audio = audio,
	ownFX = ownFX,
	foreignFX = foreignFX,
	cleaned = workspace:FindFirstChild("PenUpgradeFX") == nil
		and workspace:FindFirstChild("PenUpgradeNotice", true) == nil,
})
