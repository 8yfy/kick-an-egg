--!strict
-- Studio-only read-only measurements during actual walking. Install in PlayerScripts before using
-- TutorialWalk.client.lua or native movement. Never mapped into the production place.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio(), "Studio QA only")
local p = game.Players.LocalPlayer
local folder = workspace:WaitForChild("TutorialGuidance")
local marker = folder:WaitForChild("PathMarker1") :: Part
local root = p.Character:WaitForChild("HumanoidRootPart") :: BasePart
local previousRoot, previousMarker = root.Position, marker.Position
local report = { frames = 0, moving = 0, staleFrames = 0, minLead = 1000, maxGap = 0, maxStep = 0, maxDt = 0 }
RunService:BindToRenderStep("TutorialRouteMotionQA", Enum.RenderPriority.Camera.Value + 10, function(dt)
	local currentRoot = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	if not (currentRoot and currentRoot:IsA("BasePart")) then
		return
	end
	report.frames += 1
	report.maxDt = math.max(report.maxDt, dt)
	local moved = (currentRoot.Position - previousRoot).Magnitude
	if marker:GetAttribute("Active") and moved > 0.02 then
		report.moving += 1
		local distance = (marker.Position - previousMarker).Magnitude
		report.maxStep = math.max(report.maxStep, distance)
		if distance < 0.001 then
			report.staleFrames += 1
		end
		local offset = marker.Position - currentRoot.Position
		report.minLead = math.min(report.minLead, Vector3.new(offset.X, 0, offset.Z):Dot(marker.CFrame.UpVector))
		local last = marker
		for i = 2, 40 do
			local other = folder:FindFirstChild("PathMarker" .. i) :: Part
			if other:GetAttribute("Active") then
				last = other
			end
		end
		local delta = last.Position - (folder.WorldTarget :: Part).Position
		report.maxGap = math.max(report.maxGap, Vector3.new(delta.X, 0, delta.Z).Magnitude)
	end
	previousRoot, previousMarker = currentRoot.Position, marker.Position
end)
task.wait(10)
RunService:UnbindFromRenderStep("TutorialRouteMotionQA")
p:SetAttribute("TutorialRouteMotionQA", game:GetService("HttpService"):JSONEncode(report))
script:Destroy()
