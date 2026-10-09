--!strict
-- Partner A. Pooled, anchored, non-colliding parts for effects (client only).
-- Parts live in workspace.VFX while in use and are parked in nil-parent storage when released,
-- so repeated effects never grow memory.
local Pool = {}

local free: { [string]: { BasePart } } = {}
local folder: Folder? = nil

function Pool.folder(): Folder
	local f = folder
	if f and f.Parent then
		return f
	end
	local existing = workspace:FindFirstChild("VFX")
	if existing and existing:IsA("Folder") then
		folder = existing
		return existing
	end
	local nf = Instance.new("Folder")
	nf.Name = "VFX"
	nf.Parent = workspace
	folder = nf
	return nf
end

local function make(kind: string): BasePart
	local p: BasePart
	if kind == "Wedge" then
		p = Instance.new("WedgePart")
	else
		local part = Instance.new("Part")
		if kind == "Ball" then
			part.Shape = Enum.PartType.Ball
		elseif kind == "Cylinder" then
			part.Shape = Enum.PartType.Cylinder
		end
		p = part
	end
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p:SetAttribute("PoolKind", kind)
	return p
end

-- kind: "Block" | "Wedge" | "Ball" | "Cylinder"
function Pool.get(kind: string?): BasePart
	local k = kind or "Block"
	local list = free[k]
	local p = if list and #list > 0 then table.remove(list) :: BasePart else make(k)
	p.Transparency = 0
	p.Material = Enum.Material.SmoothPlastic
	p.CastShadow = false
	p.Parent = Pool.folder()
	return p
end

function Pool.release(p: BasePart)
	local k = p:GetAttribute("PoolKind")
	if typeof(k) ~= "string" then
		p:Destroy()
		return
	end
	for _, c in p:GetChildren() do
		c:Destroy() -- lights/emitters added by an effect
	end
	p.Parent = nil
	local list = free[k]
	if not list then
		list = {}
		free[k] = list
	end
	if #list < 400 then
		table.insert(list, p)
	else
		p:Destroy()
	end
end

-- Invisible anchor part for emitters/lights/beams (also pooled).
function Pool.anchor(cf: CFrame, size: Vector3?): BasePart
	local p = Pool.get("Block")
	p.Transparency = 1
	p.Size = size or Vector3.one
	p.CFrame = cf
	return p
end

function Pool.stats(): { [string]: number }
	local s = {}
	for k, list in free do
		s[k] = #list
	end
	return s
end

return Pool
