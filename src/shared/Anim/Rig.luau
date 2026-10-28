--!strict
-- Partner A. Motor6D helpers for procedural animation on BlockBuilder rigs.
-- BlockBuilder puts one Motor6D per joint group (Body, Head, LegL, ...) under the model's Root.
-- Every pose is applied on top of the motor's REST C0. BlockBuilder records it on the motor (attribute RestC0, at
-- the model's RestScale); it is scaled to the model's current scale, so a pose is always right whatever ScaleTo
-- did before (the old "remember C0 the first time" cached a shrunken C0 during the hatch reveal and pulled every
-- animated part of a fresh pet out of place). Motors without the record fall back to the first C0 seen.
local Rig = {}

local baseC0: { [Motor6D]: CFrame } = setmetatable({}, { __mode = "k" }) :: any

function Rig.motors(model: Model): { [string]: Motor6D }
	local out = {}
	local root = model.PrimaryPart
	if root then
		for _, m in root:GetChildren() do
			if m:IsA("Motor6D") then
				out[m.Name] = m
			end
		end
	end
	return out
end

function Rig.base(m: Motor6D): CFrame
	local b = baseC0[m] -- (an explicit override: Rig.setBase)
	if b then
		return b
	end
	local rest = m:GetAttribute("RestC0")
	local model = m:FindFirstAncestorOfClass("Model")
	if typeof(rest) == "CFrame" and model then
		local at = model:GetAttribute("RestScale")
		local k = model:GetScale() / (if typeof(at) == "number" and at > 0 then at else 1)
		return CFrame.new(rest.Position * k) * rest.Rotation
	end
	local first = m.C0
	baseC0[m] = first
	return first
end

-- Pose relative to the rest pose: C0 = base * offset.
function Rig.pose(m: Motor6D?, offset: CFrame)
	if m then
		m.C0 = Rig.base(m) * offset
	end
end

-- Pose in the root's frame: C0 = around * base * offset. `around` moves the whole group in root space (e.g. a
-- rotation about another group's pivot, so a head rides along when the body it sits on sways).
function Rig.poseAbout(m: Motor6D?, around: CFrame, offset: CFrame)
	if m then
		m.C0 = around * Rig.base(m) * offset
	end
end

function Rig.reset(m: Motor6D?)
	if m then
		m.C0 = Rig.base(m)
	end
end

-- Overrides the remembered rest pose (e.g. after LegsSprout lifts the body).
function Rig.setBase(m: Motor6D, c0: CFrame)
	baseC0[m] = c0
end

return Rig
