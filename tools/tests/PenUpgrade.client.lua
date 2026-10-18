-- Insert as LocalScript in PlayerScripts after PenUpgrade.server.lua. Results: LocalPlayer.PenQASuite.
assert(game:GetService("RunService"):IsStudio() and game.PlaceId == 0)
local P = game.Players.LocalPlayer
local RS = game.ReplicatedStorage
local UI = P.PlayerScripts.Client.UI
local Data = require(UI.System.Data)
local Audio = require(RS.Shared.Audio)
local F = require(UI.Hud.PenUpgradeFeedback)
local Remote = require(RS.Shared.Remotes).get("UpgradePen")
local QA = RS:WaitForChild("PenUpgradeQA")
local results = {}
local function check(name, ok, detail)
	table.insert(results, { name = name, passed = ok == true, detail = detail })
end
local function count()
	local n = 0
	for _, r in Audio.history do
		if r.event == "PenUpgrade" then
			n += 1
		end
	end
	return n
end
local function capture(action, duration)
	local seen, fxSeen, maxFX, emitterCount, colliding = false, false, 0, 0, false
	local scaleChanged = false
	local originals = {}
	local start = os.clock()
	local lastNotice = 0
	local connection = game:GetService("RunService").Heartbeat:Connect(function()
		if P.PlayerGui:FindFirstChild("PenUpgradeNotice", true) then
			seen = true
			lastNotice = os.clock() - start
		end
		local n = 0
		for _, f in workspace:GetChildren() do
			if f.Name == "PenUpgradeFX" then
				n += 1
				fxSeen = true
				local emitters = 0
				for _, p in f:GetDescendants() do
					if p:IsA("BasePart") then
						colliding = colliding or p.CanCollide or p.CanTouch or p.CanQuery
					end
					if p:IsA("ParticleEmitter") then
						emitters += 1
					end
				end
				emitterCount = math.max(emitterCount, emitters)
			end
		end
		maxFX = math.max(maxFX, n)
		local base = workspace.Map.SafeZone.Bases.Base1
		local pen = base:FindFirstChild("Pen")
		if pen then
			for _, p in pen:GetDescendants() do
				if p:IsA("BasePart") then
					local old = originals[p]
					if old and (p.Size ~= old.size or p.CFrame ~= old.cf) then
						scaleChanged = true
					end
					originals[p] = { size = p.Size, cf = p.CFrame }
				end
			end
		end
	end)
	action()
	task.wait(duration or 1.3)
	connection:Disconnect()
	return {
		notice = seen,
		fx = fxSeen,
		maxFX = maxFX,
		emitters = emitterCount,
		colliding = colliding,
		geometryMoved = scaleChanged,
		lastNotice = lastNotice,
		cleaned = workspace:FindFirstChild("PenUpgradeFX") == nil
			and P.PlayerGui:FindFirstChild("PenUpgradeNotice", true) == nil,
	}
end
local ok, err = xpcall(function()
	Audio.measure = true
	check("initial snapshot is silent", count() == 0 and not P.PlayerGui:FindFirstChild("PenUpgradeNotice", true))
	check(
		"level guards",
		not F.isIncrease(nil, 7)
			and not F.isIncrease(2, 2)
			and not F.isIncrease(2, 1)
			and not F.isIncrease(2, 3.5)
			and not F.isIncrease(2, 0 / 0)
			and F.isIncrease(2, 3)
	)
	QA:InvokeServer("empty")
	local before = count()
	local failed = capture(function()
		Remote:FireServer()
	end)
	check("insufficient money is silent", not failed.notice and not failed.fx and count() == before, failed)
	QA:InvokeServer("fund")
	QA:InvokeServer("pet")
	local petBefore = QA:InvokeServer("status").pet
	local success = capture(function()
		Remote:FireServer()
	end)
	check(
		"confirmed purchase / cleanup",
		success.notice and success.fx and success.cleaned and count() == before + 1,
		success
	)
	check("collision and original geometry unchanged", not success.colliding and not success.geometryMoved)
	local petAfter = QA:InvokeServer("status").pet
	check(
		"placed pet survives",
		petBefore and petBefore.placed and petAfter and petAfter.placed and petAfter.petId == petBefore.petId
	)
	local record = Audio.history[#Audio.history]
	for _, r in Audio.history do
		if r.event == "PenUpgrade" then
			record = r
		end
	end
	check("Creator Store audio loaded and audible", record.loaded and record.loudness > 0, record.loudness)
	before = count()
	local dup = capture(function()
		QA:InvokeServer("duplicate")
	end)
	check("duplicate and stale delivery silent", count() == before and not dup.notice and not dup.fx)
	local other = capture(function()
		QA:InvokeServer("other")
	end)
	check("other owner isolated", count() == before and not other.notice and not other.fx)
	P:SetAttribute("LowDetail", true)
	game.SoundService.Master.Volume = 0
	local low = capture(function()
		Remote:FireServer()
	end)
	check(
		"low detail + mute",
		low.notice and low.fx and low.emitters == 2 and low.cleaned and game.SoundService.Master.Volume == 0,
		low
	)
	game.SoundService.Master.Volume = 0.5
	P:SetAttribute("ReducedMotion", true)
	local reduced = capture(function()
		Remote:FireServer()
	end)
	check(
		"reduced motion has no particles",
		reduced.notice and reduced.fx and reduced.emitters == 0 and reduced.cleaned,
		reduced
	)
	P:SetAttribute("ReducedMotion", false)
	P:SetAttribute("LowDetail", false)
	local rapid = capture(function()
		Remote:FireServer()
		task.wait(0.28)
		Remote:FireServer()
	end, 1.4)
	check("rapid purchases bounded / cleanup", rapid.maxFX == 1 and rapid.cleaned and not rapid.colliding, rapid)
	local removal = capture(function()
		Remote:FireServer()
		task.wait(0.25)
		local pen = workspace.Map.SafeZone.Bases.Base1.Pen
		local parent = pen.Parent
		pen.Parent = nil
		task.wait(0.08)
		pen.Parent = parent
	end)
	check("pen removal cleans effect", removal.cleaned, removal)
	before = count()
	local maxed = capture(function()
		Remote:FireServer()
	end)
	check(
		"max-level purchase silent",
		QA:InvokeServer("status").cost == nil and count() == before and not maxed.notice and not maxed.fx,
		maxed
	)
end, debug.traceback)
if not ok then
	check("suite execution", false, tostring(err))
end
P:SetAttribute("PenQASuite", game:GetService("HttpService"):JSONEncode(results))
