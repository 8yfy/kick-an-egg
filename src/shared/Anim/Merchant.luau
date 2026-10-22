--!strict
-- Partner A. The shopkeepers (avatar NPCs from MerchantService), posed on this client against their own counters.
-- Rays find the real counter in front of each NPC (top height and back edge, whatever the remodel made of it); the
-- pose comes from the rig itself (joint layers in Anim/Mixer, leg / arm IK in Anim/Body), never from rotating or
-- sinking the model. Each MerchantKind has a style (STYLE):
--
-- LEAN (the Boxing Sack Coach, any kind not listed): leaning on the counter. A small search over the torso lean and
--   how far the NPC stands from the counter puts both forearms flat on the top with the upper arms hanging naturally;
--   feet planted, elbows and hands placed on the top, the torso never inside it.
--   Greeting: look up, straighten a little, a small wave, back to leaning.
--
-- LAZY (the Pet Merchant): sprawled in a tall lounge chair (Builders/Models/LazyChair, built to fit him) behind the
--   stand, leaning back, both feet up on the counter, hands clasped behind his head, elbows out. The feet stand on their
--   heels, toes up and turned out, just past the counter's back edge (leg IK, knees bending up); the hips are placed
--   back along the legs and the chair is fitted around him: the seat tilted up under his thighs, the back along his
--   reclined spine (he sinks a little into both cushions, never floats over them), a headrest behind his clasped hands.
--   He only ever slides back and up into the chair, never into the counter, which is left exactly as it is.
--   Greeting: he lifts his head toward the player and gives a tiny nod; he stays sprawled, feet up.
--
-- LIFE (both): slow breathing, unhurried bored glances (lazy: the odd head tilt too), slow posture / weight shifts,
-- a hand sliding along the counter (lean) or a foot that rocks a little on its heel (lazy); the head turns toward a
-- player who comes near (eased, limited), the body stays put. No faces to blink (these avatars have no FaceControls).
-- One Mixer layer per NPC from the rest pose (its Animate script never runs on an NPC); frozen when far or off screen.
local Body = require(script.Parent.Body)
local Clip = require(script.Parent.Clip)
local Mixer = require(script.Parent.Mixer)
local LazyChair = require(script.Parent.Parent.Builders.Models.LazyChair)

local Merchant = {}

-- MerchantKind -> pose style (kinds not listed lean on their counter)
Merchant.STYLE = { PetSeller = "lazy" } :: { [string]: string }

local LOD_FAR = 140 -- studs from the camera: beyond this the NPC is frozen
local GREET = 1.9 -- seconds
local NOD = 1.5 -- seconds (the lazy acknowledgement)
local LOOK_RANGE = 26

-- The lazy pose (degrees / studs)
local LAZY = {
	recline = 38, -- the torso leaning back (the pelvis carries most of it, the chest a little more)
	legRise = 20, -- legs up from horizontal toward the counter
	reach = 0.99, -- hip-to-ankle as a share of the straight leg (knees softly bent)
	toesUp = 80, -- feet standing on their heels
	splay = 16, -- toes turned out
	heelIn = 0.06, -- heels on the back edge of the top, the Achilles resting on it (the shins clear the top)
	gap = 0.44, -- ankles this far either side of the middle
	neck = -30, -- chin down against the recline: he looks out over his feet at the shop
	seatUnder = 4, -- the seat tilts this much less than his thighs (they rise off it a little toward the knees)
	sink = 0.06, -- into the cushions
}

export type Live = {
	update: (dt: number, viewer: Vector3?, camera: Camera?) -> (),
	greet: () -> (),
	stop: () -> (),
	fit: { style: string, lean: number, slide: number, counter: number, high: boolean },
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

-- Head tracking shared by both styles: a nearby player, else an occasional unhurried glance (with an odd tilt).
type Look = { yaw: number, pitch: number, tilt: number, nextGlance: number, gYaw: number, gPitch: number, gTilt: number }

local function trackHead(look: Look, placed: CFrame, t: number, dt: number, viewer: Vector3?, tilts: boolean)
	local wantYaw, wantPitch, wantTilt = 0, 0, 0
	local tracking = false
	if viewer then
		local rel = placed:PointToObjectSpace(viewer)
		local dist = Vector2.new(rel.X, rel.Z).Magnitude
		if dist < LOOK_RANGE and rel.Z < 2 then
			tracking = true
			wantYaw = math.clamp(math.deg(math.atan2(-rel.X, -rel.Z)), -65, 65)
			wantPitch = math.clamp(math.deg(math.atan2(rel.Y - 1.4, dist)), -20, 22)
		end
	end
	if not tracking then
		if t > look.nextGlance then
			look.nextGlance = t + 3 + math.random() * 4
			local r = math.random()
			look.gYaw = if r < 0.35 then 0 elseif r < 0.65 then 18 + math.random() * 14 else -(18 + math.random() * 14)
			look.gPitch = if math.random() < 0.3 then -6 else 2
			look.gTilt = if tilts and math.random() < 0.45 then (math.random() < 0.5 and -7 or 7) else 0
		end
		wantYaw, wantPitch, wantTilt = look.gYaw, look.gPitch, look.gTilt
	end
	-- eased like a head (fast start, soft settle), never snapping to a new target
	local k = 1 - math.exp(-dt * (if tracking then 4.5 else 2.2))
	look.yaw += (wantYaw - look.yaw) * k
	look.pitch += (wantPitch - look.pitch) * k
	look.tilt += (wantTilt - look.tilt) * (1 - math.exp(-dt * 1.6))
end

-- Freezes an NPC far away or behind the camera. Returns true while frozen.
local function lod(npc: Model, placed: CFrame, camera: Camera?): boolean
	if not camera then
		return false
	end
	local rel = placed.Position - camera.CFrame.Position
	local far = rel.Magnitude > LOD_FAR or (rel.Magnitude > 20 and rel.Unit:Dot(camera.CFrame.LookVector) < 0.2)
	Mixer.pause(npc, far)
	return far
end

-- LEAN ------------------------------------------------------------------------------------------------------------

-- Pose for a lean `lean` (degrees forward): Root and Waist share it, the feet stay planted.
local function leanPose(lean: number): Clip.Pose
	return {
		Root = { -lean * 0.55, 0, 0, 0, -0.04, 0 },
		Waist = { -lean * 0.45, 0, 0 },
	}
end

local function attachLean(npc: Model, body: Body.Body, feetY: number, counterY: number?, edge: number?): Live
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
		local ey = counterY + thick + 0.04 -- the forearm's underside on the top, not in it
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
			-- the hands rest on the top too: the forearm dips a little toward them
			wrists[side] = e + dir * arm.l2 - Vector3.new(0, 0.16, 0)
		end
	end

	-- the head looks out over the counter: up against a forward lean, chin down onto folded arms
	local neckBase = if high then -8 else lean * 0.62
	local look: Look = { yaw = 0, pitch = 0, tilt = 0, nextGlance = 2, gYaw = 0, gPitch = 0, gTilt = 0 }
	local greetAt: number? = nil
	local shiftT = 0
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

	return {
		fit = { style = "lean", lean = lean, slide = slide, counter = (counterY or 0) - feetY, high = high },
		update = function(dt: number, viewer: Vector3?, camera: Camera?)
			if lod(npc, placed, camera) then
				return
			end
			shiftT += dt * 0.7
			trackHead(look, placed, os.clock() - t0, dt, viewer, false)
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
end

-- LAZY ------------------------------------------------------------------------------------------------------------

local function lazyPose(recline: number): (Clip.Value, Clip.Value)
	return { recline * 0.8, 0, 0, 0, 0, 0 }, { recline * 0.2, 0, 0 }
end

local function attachLazy(npc: Model, body: Body.Body, feetY: number, counterY: number, edge: number): Live?
	local leg, arm = body.limbs.RFoot, body.limbs.RHand
	local foot = npc:FindFirstChild("RightFoot")
	local lowerTorso, upperTorso = npc:FindFirstChild("LowerTorso"), npc:FindFirstChild("UpperTorso")
	local upperLeg = npc:FindFirstChild("RightUpperLeg")
	if
		not leg
		or not arm
		or not foot
		or not foot:IsA("BasePart")
		or not lowerTorso
		or not lowerTorso:IsA("BasePart")
		or not upperTorso
		or not upperTorso:IsA("BasePart")
		or not upperLeg
		or not upperLeg:IsA("BasePart")
	then
		return nil
	end
	local base = npc:GetPivot()
	local rest = Body.fk(body, {})
	local hipRest = rest.RHip.Position

	-- 1) the feet: standing on their heels on the counter top, toes up and turned out (root space, original spot)
	local function footRot(side: number): CFrame
		return CFrame.Angles(0, math.rad(-LAZY.splay * side), 0) * CFrame.Angles(math.rad(LAZY.toesUp), 0, 0)
	end
	local heelLocal = Vector3.new(0, -foot.Size.Y / 2, foot.Size.Z / 2) - body.joints.RAnkle.c1.Position
	local ankles: { [number]: Vector3 } = {}
	for _, side in { 1, -1 } do
		local heel = Vector3.new(LAZY.gap * side, counterY + 0.015, -(edge + LAZY.heelIn))
		ankles[side] = heel - footRot(side) * heelLocal
	end
	-- 2) the hips: back down the legs, which rise toward the counter with the knees softly bent
	local rise = math.rad(LAZY.legRise)
	local along = Vector3.new(0, math.sin(rise), -math.cos(rise))
	local ankleMid = (ankles[1] + ankles[-1]) / 2
	local hipMid = Vector3.new(0, ankleMid.Y, ankleMid.Z) - along * (leg.l1 + leg.l2) * LAZY.reach
	local delta = hipMid - Vector3.new(0, hipRest.Y, hipRest.Z) -- the NPC moves back / up into the chair
	local placed = base * CFrame.new(delta)
	for side, a in ankles do
		ankles[side] = a - delta
	end

	-- 3) the posed rig (root space, placed): recline, leg IK, then where the chair has to be
	local rootV, waistV = lazyPose(LAZY.recline)
	local kneeHints = { RFoot = Vector3.new(0.2, 1, -0.2), LFoot = Vector3.new(-0.2, 1, -0.2) }
	local transforms: { [string]: CFrame } = {
		Root = Body.toTransform(body.joints.Root, Clip.cframe(rootV, body.scale)),
		Waist = Body.toTransform(body.joints.Waist, Clip.cframe(waistV, body.scale)),
	}
	local ik: { [string]: CFrame } = {}
	local chain = Body.fk(body, transforms)
	for limb, side in { RFoot = 1, LFoot = -1 } do
		Body.solve(body, limb, chain, ankles[side], kneeHints[limb], footRot(side), ik)
	end
	for k, v in ik do
		transforms[k] = v
	end
	chain = Body.fk(body, transforms)
	local ltCF = chain.Root * body.joints.Root.c1:Inverse()
	local utCF = chain.Waist * body.joints.Waist.c1:Inverse()
	-- hands clasped behind his head, elbows out wide: the hands follow the head part of the way (its looks, tilts and
	-- nods turn it inside the hands) so they always cradle it and stay on the headrest
	local neckJoint = body.joints.Neck
	local head = npc:FindFirstChild("Head")
	local headDepth = if head and head:IsA("BasePart") then head.Size.Z / 2 else 0.5
	local function hand(side: number): Mixer.HandFn
		return function(ut: CFrame, values)
			local nv = values.Neck or { 0, 0, 0 }
			local pitch = LAZY.neck + ((nv[1] or 0) - LAZY.neck) * 0.5
			local cradle = { pitch, (nv[2] or 0) * 0.35, (nv[3] or 0) * 0.5 }
			local headCF = ut
				* neckJoint.c0
				* Body.toTransform(neckJoint, Clip.cframe(cradle, body.scale))
				* neckJoint.c1:Inverse()
			local wrist = headCF * Vector3.new(0.3 * side, -0.06, headDepth + 0.14)
			return wrist, headCF.Rotation * Vector3.new(side, 0.3, -0.35), nil
		end
	end

	-- the chair, fitted to him: the seat tilts up under his thighs, the back lies along his reclined spine, and he sinks
	-- a little into both cushions (soft: breathing and posture shifts never lift him off them)
	local function corners(cf: CFrame, size: Vector3, into: { Vector3 })
		for _, x in { -1, 1 } do
			for _, y in { -1, 1 } do
				for _, z in { -1, 1 } do
					table.insert(into, cf * (size * Vector3.new(x, y, z) / 2))
				end
			end
		end
	end
	local seatPts, backPts = {}, {}
	corners(ltCF, lowerTorso.Size, seatPts)
	corners(ltCF, lowerTorso.Size, backPts)
	corners(utCF, upperTorso.Size, backPts)
	for _, j in { "RHip", "LHip" } do
		corners(chain[j] * body.joints[j].c1:Inverse(), upperLeg.Size, seatPts)
	end
	local hipMidNow = (chain.RHip.Position + chain.LHip.Position) / 2
	local kneeMid = (chain.RKnee.Position + chain.LKnee.Position) / 2
	local thigh = kneeMid - hipMidNow
	local tilt = math.clamp(math.deg(math.atan2(thigh.Y, -thigh.Z)) - LAZY.seatUnder, 8, 40)
	local seatRot = CFrame.Angles(math.rad(tilt), 0, 0)
	local ns, nb = seatRot.YVector, utCF.Rotation.ZVector -- seat top up, back pad facing his back
	local ds, db = math.huge, -math.huge
	for _, p in seatPts do
		ds = math.min(ds, p:Dot(ns))
	end
	for _, p in backPts do
		db = math.max(db, p:Dot(nb))
	end
	ds += LAZY.sink
	db -= LAZY.sink
	local det = ns.Y * nb.Z - ns.Z * nb.Y -- (the two planes meet in a line across: the crease)
	local crease = CFrame.new(0, (ds * nb.Z - ns.Z * db) / det, (ns.Y * db - ds * nb.Y) / det) * seatRot
	local recline = math.deg(math.atan2(-nb.Y, nb.Z)) - tilt -- the back, past square to the seat
	local backFrame = crease * CFrame.Angles(math.rad(recline), 0, 0)
	local shoulder = (utCF * body.joints.RShoulder.c0).Position
	-- the headrest: just behind his clasped hands (they rest on it), measured on his arms in this pose
	transforms.Neck = Body.toTransform(neckJoint, Clip.cframe({ LAZY.neck, 0, 0 }, body.scale))
	chain = Body.fk(body, transforms)
	table.clear(ik)
	for limb, side in { RHand = 1, LHand = -1 } do
		local target, hint = hand(side)(utCF, { Neck = { LAZY.neck, 0, 0 } })
		Body.solve(body, limb, chain, target, hint or Vector3.xAxis * side, nil, ik, true)
	end
	for k, v in ik do
		transforms[k] = v
	end
	chain = Body.fk(body, transforms)
	local handSize = (npc:FindFirstChild("RightHand") :: BasePart).Size
	local pillow = { bottom = math.huge, top = -math.huge, front = -math.huge }
	for _, j in { "RWrist", "LWrist" } do
		local pts = {}
		corners(chain[j] * body.joints[j].c1:Inverse(), handSize, pts)
		for _, p in pts do
			local q = backFrame:PointToObjectSpace(p)
			pillow.bottom, pillow.top, pillow.front =
				math.min(pillow.bottom, q.Y), math.max(pillow.top, q.Y), math.max(pillow.front, q.Z)
		end
	end
	pillow.front -= LAZY.sink + 0.03 -- (a little deeper: his hands move a little with his looks and nods)
	local chair = LazyChair.build(placed, {
		seat = crease,
		floorY = feetY - delta.Y,
		width = 2.6,
		seatDepth = math.max(1, -crease:PointToObjectSpace(kneeMid).Z - 0.45),
		recline = recline,
		backHeight = backFrame:PointToObjectSpace(shoulder).Y - 0.6, -- up to his shoulder blades: his raised arms clear it
		headrest = pillow,
	})
	chair.Parent = npc.Parent
	npc:PivotTo(placed)
	-- the chair is this client's prop for this NPC: it goes when the NPC does (avatar refresh, streaming)
	local gone: RBXScriptConnection
	gone = npc.AncestryChanged:Connect(function(_, parent)
		if not parent then
			gone:Disconnect()
			chair:Destroy()
		end
	end)

	-- 4) life: breathing, bored glances and tilts, slow posture shifts, a foot rocking on its heel; the nod
	local look: Look = { yaw = 0, pitch = 0, tilt = 0, nextGlance = 2, gYaw = 0, gPitch = 0, gTilt = 0 }
	local posture = { yaw = 0, roll = 0, tYaw = 0, tRoll = 0, next = 6 }
	local rock = { now = 0, target = 0, next = 4 }
	local nodAt: number? = nil
	local t0 = os.clock()
	local footOffset: { [number]: Vector3 } = {}
	for side, a in ankles do
		local limb = if side == 1 then "RFoot" else "LFoot"
		footOffset[side] = (a - body.rest[limb]) / body.scale
	end

	local handle = Mixer.procedural(npc, "MerchantLazy", function(_, v)
		local now = os.clock()
		local t = now - t0
		local breath = math.sin(t * math.pi * 2 / 4.8)
		-- the nod: head up toward the customer, a small dip, back
		local nod, lift = 0, 0
		if nodAt then
			local k = (now - nodAt) / NOD
			if k >= 1 then
				nodAt = nil
			else
				lift = 7 * smooth(k / 0.25) * (1 - smooth((k - 0.75) / 0.25))
				nod = -9 * math.sin(math.clamp((k - 0.32) / 0.36, 0, 1) * math.pi)
			end
		end
		v.Root = { rootV[1] + breath * 0.2, posture.yaw, posture.roll, 0, breath * 0.008, 0 }
		v.Waist = { waistV[1] + breath * 0.6, look.yaw * 0.15, -posture.roll * 0.4 }
		v.Neck = { LAZY.neck + look.pitch + lift + nod - breath * 0.4, look.yaw * 0.6, look.tilt }
		for side, off in footOffset do
			local limb = if side == 1 then "RFoot" else "LFoot"
			local turn = if side == 1 then rock.now else 0
			v[limb] = { 1, off.X, off.Y, off.Z, -LAZY.splay * side + turn, LAZY.toesUp }
		end
		v.RHand, v.LHand = { 1 }, { 1 }
		v.RShoulder, v.LShoulder = { 150, 0, 40 }, { 150, 0, -40 } -- (only if the arm IK can't run)
		v.RElbow, v.LElbow = { 120 }, { 120 }
	end, {
		rest = true,
		fadeIn = 0.4,
		priority = Mixer.PRIORITY.Action,
		hands = { RHand = hand(1), LHand = hand(-1) },
		exactHands = true,
		kneeHints = kneeHints,
	})

	return {
		fit = { style = "lazy", lean = -LAZY.recline, slide = -delta.Z, counter = counterY - feetY, high = true },
		update = function(dt: number, viewer: Vector3?, camera: Camera?)
			if lod(npc, placed, camera) then
				return
			end
			local t = os.clock() - t0
			trackHead(look, placed, t, dt, viewer, true)
			-- every so often he settles differently in the chair, and one foot rocks a little on its heel
			if t > posture.next then
				posture.next = t + 9 + math.random() * 6
				posture.tYaw, posture.tRoll = (math.random() - 0.5) * 7, (math.random() - 0.5) * 4
			end
			local k = 1 - math.exp(-dt * 0.9)
			posture.yaw += (posture.tYaw - posture.yaw) * k
			posture.roll += (posture.tRoll - posture.roll) * k
			if t > rock.next then
				rock.next = t + 6 + math.random() * 6
				rock.target = if rock.target ~= 0 then 0 else (math.random() < 0.5 and -9 or 7)
			end
			rock.now += (rock.target - rock.now) * (1 - math.exp(-dt * 2.4))
		end,
		greet = function()
			local now = os.clock()
			if not nodAt or now - nodAt > NOD then
				nodAt = now
			end
		end,
		stop = function()
			handle.stop(0.3)
			gone:Disconnect()
			chair:Destroy()
			npc:PivotTo(base)
		end,
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
	local kind = npc:GetAttribute("MerchantKind")
	if typeof(kind) == "string" and Merchant.STYLE[kind] == "lazy" and counterY and edge then
		local live = attachLazy(npc, body, feetY, counterY, edge)
		if live then
			return live
		end
	end
	return attachLean(npc, body, feetY, counterY, edge)
end

return Merchant
