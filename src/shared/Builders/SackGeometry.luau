--!strict
-- Sack geometry for the game (the gear sack and the base stands). The ORIGINAL meshes are used when the
-- 20 GLBs have been imported into ReplicatedStorage.SackAssets.Meshes as Sack_01..Sack_20 (Studio File >
-- Import; see tools/sacks/IMPORT.md); otherwise the part-built remodel (Builders/Models/Sacks) stands in.
-- Both come out in the same frame: origin = the hub where the four straps meet, front facing -Z, scaled at
-- Sacks.SCALE studs per metre, so SackController / MapLifeController / SackAura don't care which one it is.
-- Imported geometry is never edited: it is cloned, uniformly scaled from the source GLB bounds
-- (SackModules/SackGLBData), turned to face -Z and coloured with the original GLB materials (SackColors).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Builder = require(script.Parent.BlockBuilder)
local Sacks = require(script.Parent.Models.Sacks)

local SackGeometry = {}

export type Source = "GLB" | "Parts"

-- The imported original model for `tier`, if it is in the place.
function SackGeometry.template(tier: number): Model?
	local assets = ReplicatedStorage:FindFirstChild("SackAssets")
	local meshes = assets and assets:FindFirstChild("Meshes")
	local t = meshes and meshes:FindFirstChild(string.format("Sack_%02d", tier))
	return if t and t:IsA("Model") then t else nil
end

-- How many of the 20 GLB imports are present (Studio prints this once so a missing import is obvious).
function SackGeometry.imported(): number
	local n = 0
	for tier = 1, 20 do
		if SackGeometry.template(tier) then
			n += 1
		end
	end
	return n
end

local function fromGLB(tier: number, template: Model): Model
	local modules = ReplicatedStorage:WaitForChild("SackModules")
	local GLB = require(modules:WaitForChild("SackGLBData")) :: any
	local Colors = require(modules:WaitForChild("SackColors")) :: any
	local bounds = GLB[tier]
	local S = Sacks.SCALE

	local visual = template:Clone()
	visual.Name = "ImportedGeometry"
	visual:PivotTo(CFrame.new())
	local _, size = visual:GetBoundingBox()
	local height = (bounds.Max.Y - bounds.Min.Y) * S -- source metres -> studs
	if size.Y > 0.001 then
		visual:ScaleTo(visual:GetScale() * height / size.Y)
	end
	-- source frame (metres, y-up, +Z front, origin = bag bottom) -> our frame (origin = hub, front -Z)
	local root = Sacks.vfxRoot(tier)
	visual:PivotTo(root.Rotation)
	local box = visual:GetBoundingBox()
	local target = root:PointToWorldSpace((bounds.Min + bounds.Max) * 0.5 * S)
	visual:PivotTo(CFrame.new(target - box.Position) * visual:GetPivot())
	local matched = Colors.ApplyImported(visual, tier, true)

	local model = Instance.new("Model")
	model.Name = "Sack"
	model:SetAttribute("GeometrySource", "GLB")
	model:SetAttribute("MatchedGLBMaterials", matched)
	visual.Parent = model
	model.WorldPivot = CFrame.new()
	return model
end

-- A fresh sack model for `tier` (unparented, pivot at the hub) and where its geometry came from.
function SackGeometry.build(tier: number): (Model, Source)
	local template = SackGeometry.template(tier)
	if template then
		local ok, model = pcall(fromGLB, tier, template)
		if ok then
			return model, "GLB"
		end
		warn(`[SackGeometry] Sack_{string.format("%02d", tier)} import could not be used: {model}`)
	end
	local model = Builder.build(Sacks.spec(tier), "Sack")
	model:SetAttribute("GeometrySource", "Parts")
	return model, "Parts"
end

return SackGeometry
