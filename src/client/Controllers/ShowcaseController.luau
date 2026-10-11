--!strict
-- Studio only: the /showcase sack showroom (SackService.showcase). Attaches the effects exactly once on this
-- client to every sack in workspace.SackShowcase (the server never creates effects, so nothing is duplicated):
-- SackModules/SackVFX for "/showcase", the package's SackVFXBasic for "/showcase basic", the game's own SackAura
-- for "/showcase game". Switches a sack's effects off beyond CULL studs from the camera and cleans up when a
-- sack or the showroom is removed.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local ShowcaseController = {}

local CULL = 180
local handles: { [Model]: any } = {}

local function quality(): number
	return if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then 0.5 else 0.75
end

local function attach(model: Instance)
	if not model:IsA("Model") or handles[model] then
		return
	end
	local tier = model:GetAttribute("SackTier")
	local folder = model.Parent
	if typeof(tier) ~= "number" or not folder then
		return
	end
	local ok, handle
	if folder:GetAttribute("Variant") == "game" then
		-- the game's own effects, as the gear sack and the base stands use them
		local Shared = ReplicatedStorage:WaitForChild("Shared")
		local SackAura = require(Shared:WaitForChild("VFX"):WaitForChild("SackAura")) :: any
		local Sacks = require(Shared:WaitForChild("Builders"):WaitForChild("Models"):WaitForChild("Sacks")) :: any
		ok, handle = pcall(SackAura.Apply, model, tier, model:GetPivot() * Sacks.vfxRoot(tier), Sacks.SCALE, false)
		if ok then
			handle = {
				enabled = true,
				ctx = handle,
				SetEnabled = function(self: any, on: boolean)
					self.enabled = on
					if on then
						self.ctx =
							SackAura.Apply(model, tier, model:GetPivot() * Sacks.vfxRoot(tier), Sacks.SCALE, false)
					else
						SackAura.Remove(model)
					end
				end,
				Destroy = function()
					SackAura.Remove(model)
				end,
			}
		end
	else
		if not model.PrimaryPart then
			return
		end
		local name = if folder:GetAttribute("Variant") == "basic" then "SackVFXBasic" else "SackVFX"
		local VFX = require(ReplicatedStorage:WaitForChild("SackModules"):WaitForChild(name)) :: any
		ok, handle = pcall(VFX.Attach, model, tier, { Quality = quality() })
	end
	if not ok then
		warn(`[showcase] VFX for {model:GetFullName()}: {handle}`)
		return
	end
	handles[model] = handle
	model.Destroying:Connect(function()
		local h = handles[model]
		if h then
			h:Destroy()
			handles[model] = nil
		end
	end)
end

local function watch(folder: Instance)
	if folder.Name ~= "SackShowcase" then
		return
	end
	for _, child in folder:GetChildren() do
		attach(child)
	end
	folder.ChildAdded:Connect(attach)
end

function ShowcaseController:Start()
	if not RunService:IsStudio() then
		return
	end
	for _, child in workspace:GetChildren() do
		watch(child)
	end
	workspace.ChildAdded:Connect(watch)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.5 or next(handles) == nil then
			return
		end
		acc = 0
		local cam = workspace.CurrentCamera
		if not cam then
			return
		end
		for model, h in handles do
			local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
			if root then
				local near = (root.Position - cam.CFrame.Position).Magnitude < CULL
				if near ~= h.enabled then
					h:SetEnabled(near)
				end
			end
		end
	end)
end

return ShowcaseController
