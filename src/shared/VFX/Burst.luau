--!strict
-- Partner A. Ballistic burst of pooled pieces (shell shards, confetti, sparks) that spin,
-- bounce once and fade. Fire-and-forget; every piece returns to the pool.
local RunService = game:GetService("RunService")
local Pool = require(script.Parent.Pool)

local GRAVITY = Vector3.new(0, -60, 0)
local rng = Random.new()

local Burst = {}

-- Ballistic burst of pooled pieces that spin, bounce once and fade. Returns immediately.
function Burst.play(
	origin: Vector3,
	count: number,
	colors: { Color3 },
	sizes: NumberRange,
	power: number,
	seconds: number,
	flat: boolean?,
	neon: boolean?
)
	local bits = {}
	for _ = 1, count do
		local p = Pool.get(if rng:NextNumber() < 0.3 and not flat then "Wedge" else "Block")
		local s = rng:NextNumber(sizes.Min, sizes.Max)
		p.Size = if flat then Vector3.new(s, 0.08, s * 0.6) else Vector3.new(s, s * rng:NextNumber(0.5, 1), s)
		p.Color = colors[rng:NextInteger(1, #colors)]
		if neon then
			p.Material = Enum.Material.Neon
		end
		local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(0.6, 1.4), rng:NextNumber(-1, 1)).Unit
		table.insert(bits, {
			part = p,
			pos = origin,
			vel = dir * power * rng:NextNumber(0.6, 1.1),
			axis = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)).Unit,
			spin = rng:NextNumber(4, 12),
		})
	end
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function(dt)
		local k = (os.clock() - t0) / seconds
		if k >= 1 then
			conn:Disconnect()
			for _, b in bits do
				Pool.release(b.part)
			end
			return
		end
		for _, b in bits do
			local drag = if flat then 0.35 else 1 -- confetti flutters down slowly
			b.vel += GRAVITY * drag * dt
			if flat then
				b.vel *= 0.985
			end
			b.pos += b.vel * dt
			if b.pos.Y < 0.2 then
				b.pos = Vector3.new(b.pos.X, 0.2, b.pos.Z)
				b.vel = Vector3.new(b.vel.X * 0.5, math.abs(b.vel.Y) * 0.3, b.vel.Z * 0.5)
			end
			b.part.CFrame = CFrame.new(b.pos) * CFrame.fromAxisAngle(b.axis, b.spin * (os.clock() - t0))
			b.part.Transparency = math.clamp((k - 0.6) / 0.4, 0, 1)
		end
	end)
end

return Burst
