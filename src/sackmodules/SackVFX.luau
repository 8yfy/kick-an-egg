--!strict
-- SackModules/SackVFX: the Kick Sacks package's client VFX API (Attach / SetEnabled / Destroy), backed by the
-- game's faithful port of the three.js sacks.js effects (ReplicatedStorage.Shared.VFX.SackAura: 20 tier-specific
-- recipes of particles, sprites, beams, rings, orbiters, lights and animated wings/arms). Side-by-side renders
-- against the original viewer showed it closer than the package's own approximations, which stay available as
-- SackModules/SackVFXBasic.
--
--   local handle = SackVFX.Attach(model, tier, { Quality = 0.75 })  -- on the CLIENT, once per sack
--   handle:SetEnabled(false)  -- culling: removes the effects (rebuilt on true)
--   handle:Destroy()
--
-- Works on both sack frames: SackModel builds (PrimaryPart "SackRoot" at the GLB origin = bag bottom, +Z front,
-- SackModel.SCALE studs per metre) and the game's Builders/SackGeometry sacks (pivot at the hub, front -Z,
-- Sacks.SCALE). options.Root / options.Scale override the frame.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VFX = {}

export type Options = { Quality: number?, Enabled: boolean?, Root: CFrame?, Scale: number? }
export type Handle = {
	model: Model,
	tier: number,
	enabled: boolean,
	SetEnabled: (self: Handle, on: boolean) -> (),
	Destroy: (self: Handle) -> (),
}

local function aura(): any
	return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VFX"):WaitForChild("SackAura"))
end

-- The bag-bottom frame (+Z = the sack's front) and studs per metre for `model`.
local function frame(model: Model, tier: number, options: Options): (CFrame, number)
	local root = model.PrimaryPart
	if root and root.Name == "SackRoot" then
		local SackModel = require(script.Parent:WaitForChild("SackModel")) :: any
		return options.Root or root.CFrame, options.Scale or SackModel.SCALE
	end
	local Sacks = require(
		ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Builders"):WaitForChild("Models"):WaitForChild("Sacks")
	) :: any
	return options.Root or model:GetPivot() * Sacks.vfxRoot(tier), options.Scale or Sacks.SCALE
end

local Handle = {}
Handle.__index = Handle

function Handle.SetEnabled(self: Handle, on: boolean)
	local wanted = on == true
	if wanted == self.enabled then
		return
	end
	self.enabled = wanted
	local SackAura = aura()
	if wanted then
		local cf, scale = frame(self.model, self.tier, (self :: any).options)
		SackAura.Apply(self.model, self.tier, cf, scale, false)
	else
		SackAura.Remove(self.model)
	end
end

function Handle.Destroy(self: Handle)
	self.enabled = false
	aura().Remove(self.model)
end

function VFX.Attach(model: Model, tier: number?, options: Options?): Handle
	local o: Options = options or {}
	local t = tier or model:GetAttribute("SackTier")
	assert(typeof(t) == "number" and t >= 1 and t <= 20, "SackVFX.Attach: tier 1..20 expected")
	local SackAura = aura()
	if o.Quality then
		SackAura.Quality = math.clamp(o.Quality, 0.1, 2)
	end
	local self = setmetatable({ model = model, tier = t, enabled = false, options = o }, Handle) :: any
	if o.Enabled ~= false then
		self:SetEnabled(true)
	end
	return self
end

return VFX
