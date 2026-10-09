--!strict
-- Partner A. Motor6D helpers for procedural animation on BlockBuilder rigs.
-- BlockBuilder puts one Motor6D per joint group (Body, Head, LegL, ...) under the model's Root.
-- Every pose is applied on top of the motor's original C0, which is remembered the first time.
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
	local b = baseC0[m]
	if not b then
		b = m.C0
		baseC0[m] = b
	end
	return b
end

-- Pose relative to the rest pose: C0 = base * offset.
function Rig.pose(m: Motor6D?, offset: CFrame)
	if m then
		m.C0 = Rig.base(m) * offset
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
