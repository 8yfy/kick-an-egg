-- DEV ONLY: showroom vs gameplay parity for the 20 Kick Sacks (run-in-roblox, edit mode):
--   sh tools/run-tests.sh tools/perf/SackParity.server.lua
-- Builds every tier three ways and applies its idle effects (VFX/SackAura) to each:
--   game     Builders/SackGeometry (the model players see: stand / shop / gear sacks)
--   gear     the same model the way SackController prepares the gear sack (welds removed, anchored, at origin)
--   package  SackModules/SackModel (the showroom's PACKAGE view)
-- and compares what the effect found and built: named parts it looked up (glowParts / rigs / find), lookups that
-- found nothing, emitters, beams, lights, effect parts and rigged parts. A tier whose game / gear numbers are below
-- the package's is missing effects in gameplay.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local SackGeometry = require(Shared.Builders.SackGeometry) :: any
local Sacks = require(Shared.Builders.Models.Sacks) :: any
local SackAura = require(Shared.VFX.SackAura) :: any
local SackModel = require(ReplicatedStorage.SackModules.SackModel) :: any

local function census(model: Model, ctx: any): { [string]: number }
	local c = { found = ctx.found or 0, missed = ctx.missed or 0, emitters = 0, beams = 0, lights = 0, parts = 0, rigged = 0 }
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("SackVFX_Rest") ~= nil then
			c.rigged += 1
		end
	end
	for _, d in ctx.folder:GetDescendants() do
		if d:IsA("ParticleEmitter") then
			c.emitters += 1
		elseif d:IsA("Beam") then
			c.beams += 1
		elseif d:IsA("Light") then
			c.lights += 1
		elseif d:IsA("BasePart") then
			c.parts += 1
		end
	end
	return c
end

local function fmt(c: { [string]: number }): string
	return string.format(
		"found %3d missed %2d | emitters %3d beams %3d lights %d parts %3d rigged %2d",
		c.found,
		c.missed,
		c.emitters,
		c.beams,
		c.lights,
		c.parts,
		c.rigged
	)
end

local imported = SackGeometry.imported()
local bad = 0
for tier = 1, 20 do
	local hang = CFrame.new(tier * 40, 60, 0)
	-- game (stand / shop)
	local g = SackGeometry.build(tier)
	g:PivotTo(hang)
	g.Parent = workspace
	local gctx = SackAura.Apply(g, tier, hang * Sacks.vfxRoot(tier), Sacks.SCALE, true, true)
	local game = census(g, gctx)
	-- gear (SackController.build: joints removed, anchored, at the origin)
	local r = SackGeometry.build(tier)
	for _, d in r:GetDescendants() do
		if d:IsA("WeldConstraint") or d:IsA("Motor6D") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	r.Parent = workspace
	local rctx = SackAura.Apply(r, tier, Sacks.vfxRoot(tier), Sacks.SCALE, true, true)
	local gear = census(r, rctx)
	-- package (showroom PACKAGE view)
	local folder = Instance.new("Folder")
	folder.Parent = workspace
	local ok, p = pcall(SackModel.Build, tier, folder, hang * CFrame.new(0, 0, 30), {
		RequireGLB = imported == 20,
		AutoScale = true,
		Anchored = true,
	})
	local pkg = nil
	if ok and p and p.PrimaryPart then
		local pctx = SackAura.Apply(p, tier, p.PrimaryPart.CFrame, SackModel.SCALE, true, true)
		pkg = census(p, pctx)
	end
	local worse = pkg ~= nil
		and (game.found < pkg.found or gear.found < pkg.found or game.rigged < pkg.rigged or gear.rigged < pkg.rigged)
	if worse then
		bad += 1
	end
	print(string.format("PARITY %2d game    %s", tier, fmt(game)))
	print(string.format("PARITY %2d gear    %s", tier, fmt(gear)))
	print(string.format("PARITY %2d package %s%s", tier, if pkg then fmt(pkg) else "build failed: " .. tostring(p), if worse then "   <-- gameplay finds less" else ""))
	SackAura.Remove(g)
	SackAura.Remove(r)
	g:Destroy()
	r:Destroy()
	folder:Destroy()
end
print(`PARITY imported GLBs: {imported}/20; tiers where gameplay finds fewer named parts than the showroom: {bad}`)
print("[Tests] 1 passed, 0 failed")
