--!strict
-- Partner A. The shopkeepers (avatar NPCs from MerchantService) leaning on their own counters, on this client.
--
-- FIT (once per NPC): rays find the real counter top in front of the NPC (height and back edge, whatever the
-- remodel made of it). A small search over the torso lean and how far the NPC stands from the counter puts both
-- forearms flat on the top with the upper arms hanging naturally, for this NPC's own proportions:
--   * a counter about hip high (the Boxing Sack Coach): a real lean, back angled forward, forearms on the top,
--     shoulders dropped, hands loosely together, head up toward the shop floor
--   * a counter at shoulder height (the Pet Merchant): no lean is possible, so the arms fold on the top and the
--     chin rests just above them, body upright against the counter
-- The model is placed once (only along its own facing, never into the counter); the pose comes from the rig:
-- planted feet (leg IK), elbows and hands placed on the counter (arm IK), the torso never below the top inside it.
-- LIFE: slow breathing, the weight drifting from leg to leg, unhurried glances, a hand that sometimes slides along
-- the counter; the head turns toward a player who comes near (eased, limited, the body stays on the counter).
-- GREETING (the speech bubble's proximity, MapLifeController): look up at the player, straighten a little, a small
-- wave, back to leaning. No faces to blink (these avatars have no FaceControls).
-- One Mixer layer per NPC from the rest pose (its Animate script never runs on an NPC); paused when far or off
-- screen.
local Body = require(script.Parent.Body)
local Clip = require(script.Parent.Clip)
local Mixer = require(script.Parent.Mixer)

local Merchant = {}

local LOD_FAR = 140 -- studs from the camera: beyond this the NPC is frozen
local GREET = 1.9 -- seconds
local LOOK_RANGE = 26

export type Live = {
	update: (dt: number, viewer: Vector3?, camera: Camera?) -> (),
	greet: () -> (),
	stop: () -> (),
	fit: { lean: number, slide: number, counter: number, high: boolean },
}

local function smooth(a: number): number
	a = math.clamp(a, 0, 1)
	return a * a * (3 - 2 * a)
end

-- Smooth value noise in -1..1 (for glances and weight shifts that never repeat exactly).
local function wander(t: number, seed: number): number
	return math.noise(t, seed, seed * 0.37) * 1.6
end

-- The counter in front of `root`: its top's height (root space) and the distance to its back edge.
local function findCounter(npc: Model, root: BasePart, feetY: number): (number?, number?)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { npc }
	local fwd = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	fwd = if fwd.Magnitude > 0.1 then fwd.Unit else Vector3.new(0, 0, -1)
	local function topAt(d: number): number?
		local origin = root.Position + fwd * d + Vector3.new(0, 6, 0)
		local hit = workspace:Raycast(origin, Vector3.new(0, -10, 0), params)
		if hit and hit.Normal.Y > 0.8 and hit.Instance.CanCollide then
			local y = hit.Position.Y - root.Position.Y
			if y - feetY > 1.2 and y - feetY < 4.8 then
				return y
			end
		end
		return nil
	end
	for d = 0.3, 6.5, 0.2 do
		local y = topAt(d)
		if y then
			local lo, hi = d - 0.2, d -- refine the back edge
			for _ = 1, 6 do
				local mid = (lo + hi) / 2
				if topAt(mid) then
					hi = mid
				else
					lo = mid
				end
			end
			return y, hi
		end
	end
	return nil, nil
end

-- Pose for a lean `lean` (degrees forward): Root and Waist share it, the feet stay planted.
local function leanPose(lean: number): Clip.Pose
	return {
		Root = { -lean * 0.55, 0, 0, 0, -0.04, 0 },
		Waist = { -lean * 0.45, 0, 0 },
	}
end

function Merchant.attach(npc: Model): Live?
	local root = npc:FindFirstChild("HumanoidRootPart")
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	local body = Mixer.body(npc)
	if not root or not root:IsA("BasePart") or not humanoid or not body or body.r6 then
		return nil
	end
	local feetY = -(humanoid.HipHeight + root.Size.Y / 2)
	local counterY, edge = findCounter(npc, root, feetY)
	local lowerArm = npc:FindFirstChild("RightLowerArm")
	local thick = if lowerArm and lowerArm:IsA("BasePart") then lowerArm.Size.X / 2 else 0.35
	local arm = body.limbs.RHand
	local base = npc:GetPivot()

	-- search: lean (degrees) x slide (studs toward the counter) -> elbows on the top, upper arms near vertical
	local best: { cost: number, lean: number, slide: number, elbow: Vector3 }? = nil
	local high = false
	if counterY and edge and arm then
		local rest = Body.fk(body, {})
		local shoulderRest = rest.RShoulder.Position
		local hr = (counterY - feetY) / (shoulderRest.Y - feetY)
		high = hr > 0.9
		local leanPref = math.clamp((0.95 - hr) * 90, 0, 40)
		local ut = npc:FindFirstChild("UpperTorso") :: BasePart?
		local utHalf = if ut then ut.Size / 2 else Vector3.new(0.7, 0.77, 0.43)
		local ey = counterY + thick + 0.02
		for lean = 0, 46, 1 do
			local p = leanPose(lean)
			local chain = Body.fk(body, {
				Root = Body.toTransform(body.joints.Root, Clip.cframe(p.Root, body.scale)),
				Waist = Body.toTransform(body.joints.Waist, Clip.cframe(p.Waist, body.scale)),
			})
			local s = chain.RShoulder.Position
			local utCF = chain.Waist * body.joints.Waist.c1:Inverse()
			local dx = 0.1
			local dy = s.Y - ey
			local reach2 = arm.l1 * arm.l1 - dy * dy - dx * dx
			if reach2 <= 0.01 then
				continue -- the elbow can't get down to the top at this lean
			end
			local h = math.sqrt(reach2)
			local ez = s.Z - h
			-- slide so the elbow sits 0.15-0.5 past the back edge, keeping the hips 0.55 behind it
			for slide = 0, math.min(4.6, edge - 0.55), 0.05 do
				local e = edge - slide -- the edge in the new root space (forward distance)
				local inside = -ez - e
				if inside < 0.12 or inside > 0.75 then
					continue
				end
				-- the chest below the top must stay behind the edge
				local lowFront = utCF * Vector3.new(0, -utHalf.Y, -utHalf.Z)
				local midFront = utCF * Vector3.new(0, 0, -utHalf.Z)
				local blocked = (lowFront.Y < counterY and -lowFront.Z > e - 0.05)
					or (midFront.Y < counterY and -midFront.Z > e - 0.05)
				if blocked then
					continue
				end
				local theta = math.deg(math.atan2(math.sqrt(h * h + dx * dx), dy)) -- upper arm from vertical
				local cost = (theta - 22) ^ 2 / 80
					+ (lean - leanPref) ^ 2 / 12
					+ (inside - 0.32) ^ 2 * 20
					+ slide * 0.05
				if not best or cost < best.cost then
					best = { cost = cost, lean = lean, slide = slide, elbow = Vector3.new(s.X + dx, ey, ez) }
				end
			end
		end
	end

	local lean = if best then best.lean else 0
	local slide = if best then best.slide else 0
	npc:PivotTo(base * CFrame.new(0, 0, -slide))
	local placed = npc:GetPivot()

	-- arm targets (root space): elbows on the top, forearms flat and angled in, hands loosely together
	local elbows, wrists = {}, {}
	if best and arm then
		for _, side in { 1, -1 } do
			local e = Vector3.new(best.elbow.X * side, best.elbow.Y, best.elbow.Z)
			local inward = if high then 0.95 else 0.5 -- folded arms on a high counter, an easy V on a low one
			local dir = Vector3.new(-side * inward, 0, -1).Unit
			elbows[side] = e
			wrists[side] = e + dir * arm.l2
		end
	end

	-- the head looks out over the counter: up against a forward lean, chin down onto folded arms
	local neckBase = if high then -8 else lean * 0.62
	local look = { yaw = 0, pitch = 0 } -- eased head target (degrees)
	local greetAt: number? = nil
	local shiftT = 0
	local live: Live
	local t0 = os.clock()
	local seed = (#npc.Name * 7.31) % 10

	local function greetWeight(now: number): number
		if not greetAt then
			return 0
		end
		local k = (now - greetAt) / GREET
		if k >= 1 then
			greetAt = nil
			return 0
		end
		return smooth(k / 0.18) * (1 - smooth((k - 0.72) / 0.28))
	end

	local function hand(side: number): Mixer.HandFn
		local shoulderJoint = body.joints[if side == 1 then "RShoulder" else "LShoulder"]
		return function(ut: CFrame)
			local w = wrists[side]
			local e = elbows[side]
			-- now and then the right hand slides a little along the top and back
			if side == 1 then
				w += Vector3.new(0, 0, -0.14 * smooth(math.sin(shiftT) * 1.5 - 0.5))
			end
			-- the elbow bends toward its spot on the counter
			local shoulder = (ut * shoulderJoint.c0).Position
			local hint = (e - (shoulder + w) * 0.5).Unit
			local dir = (w - e).Unit
			local x = if side == 1 then Vector3.yAxis else -Vector3.yAxis -- palm (the hand's inner side) down
			local y = -dir
			local rot = CFrame.fromMatrix(Vector3.zero, x, y, x:Cross(y))
			return w, hint, rot
		end
	end

	local handle = Mixer.procedural(npc, "MerchantLean", function(_, v)
		local now = os.clock()
		local t = now - t0
		local g = greetWeight(now)
		local breath = math.sin(t * math.pi * 2 / 4.3)
		local sway = wander(t * 0.11, seed)
		local straighten = lean * 0.35 * g
		local l = lean - straighten
		local p = leanPose(l)
		local root, waist = p.Root, p.Waist
		v.Root = { root[1], 0, sway * 1.4, sway * 0.03, -0.04 + breath * 0.012, 0 }
		v.Waist = { waist[1] + breath * 1.1, look.yaw * 0.25, -sway * 0.6 }
		v.Neck = { neckBase + straighten * 0.4 + look.pitch + breath * -0.4, look.yaw * 0.75, sway * 0.5 }
		v.RFoot = { 1, 0.03, 0, 0.06, 7, 0 }
		v.LFoot = { 1, -0.03, 0, -0.04, -4, 0 }
		-- the greeting wave: the right arm lifts off the counter, a small wave, and settles back
		local wave = smooth((g - 0.25) / 0.5)
		v.RHand = { if best then 1 - wave else 0 }
		v.LHand = { if best then 1 else 0 }
		local swing = math.sin((now - (greetAt or now)) * math.pi * 2 * 2.6)
		v.RShoulder = { 30 + 95 * wave, 0, 14 + 6 * wave * swing }
		v.RElbow = { 60 + 50 * wave }
		v.RWrist = { 0, 0, 22 * wave * swing }
		v.LShoulder = { 30, 0, -14 }
		v.LElbow = { 60 }
	end, {
		rest = true,
		fadeIn = 0.4,
		priority = Mixer.PRIORITY.Action,
		hands = { RHand = hand(1), LHand = hand(-1) },
	})

	local nextGlance, glanceYaw, glancePitch = 2, 0, 0
	live = {
		fit = { lean = lean, slide = slide, counter = (counterY or 0) - feetY, high = high },
		update = function(dt: number, viewer: Vector3?, camera: Camera?)
			local now = os.clock()
			-- level of detail: frozen when far away or behind the camera
			if camera then
				local rel = placed.Position - camera.CFrame.Position
				local far = rel.Magnitude > LOD_FAR
					or (rel.Magnitude > 20 and rel.Unit:Dot(camera.CFrame.LookVector) < 0.2)
				Mixer.pause(npc, far)
				if far then
					return
				end
			end
			shiftT += dt * 0.7
			-- where the head wants to look: a nearby player, else an occasional unhurried glance
			local wantYaw, wantPitch = 0, 0
			local tracking = false
			if viewer then
				local rel = placed:PointToObjectSpace(viewer)
				local dist = Vector2.new(rel.X, rel.Z).Magnitude
				if dist < LOOK_RANGE and rel.Z < 2 then
					tracking = true
					wantYaw = math.clamp(math.deg(math.atan2(-rel.X, -rel.Z)), -70, 70)
					wantPitch = math.clamp(math.deg(math.atan2(rel.Y - 1.4, dist)), -20, 22)
				end
			end
			if not tracking then
				if now - t0 > nextGlance then
					nextGlance = now - t0 + 3 + math.random() * 4
					local r = math.random()
					glanceYaw = if r < 0.35
						then 0
						elseif r < 0.65 then 18 + math.random() * 14
						else -(18 + math.random() * 14)
					glancePitch = if math.random() < 0.3 then -6 else 2
				end
				wantYaw, wantPitch = glanceYaw, glancePitch
			end
			-- eased like a head (fast start, soft settle), never snapping to a new target
			local k = 1 - math.exp(-dt * (if tracking then 4.5 else 2.2))
			look.yaw += (wantYaw - look.yaw) * k
			look.pitch += (wantPitch - look.pitch) * k
		end,
		greet = function()
			local now = os.clock()
			if not greetAt or now - greetAt > GREET then
				greetAt = now
			end
		end,
		stop = function()
			handle.stop(0.3)
			npc:PivotTo(base)
		end,
	}
	return live
end

return Merchant
