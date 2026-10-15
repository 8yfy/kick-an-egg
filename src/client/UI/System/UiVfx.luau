--!strict
-- Reusable 2D UI effects built from the supplied textures (fx_sparkle, fx_ui_sparkle, fx_glow, fx_rays, fx_shine):
-- sparkle bursts, click impacts, shine sweeps, soft glow pulses, gradient flashes and celebrations. Everything is
-- one-shot TweenService work on a few pooled / short-lived ImageLabels (Motion.burst keeps the sparkle budget),
-- nothing loops, and Reduced Motion (Motion.reduced) skips the decorative parts.
local Players = game:GetService("Players")
local Motion = require(script.Parent.Motion)
local AssetIds = require(script.Parent.AssetIds)

local UiVfx = {}

local layers: { [string]: Frame } = {}

-- Full-screen transient layers (own ScreenGuis): "front" above the HUD for sparks and rings, "back" below it
-- for glows and rays, so they light up behind a button without joining its parent's list layout.
function UiVfx.layer(which: ("front" | "back")?): Frame
	local name = which or "front"
	local existing = layers[name]
	if existing and existing.Parent then
		return existing
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = if name == "front" then "UiVfx" else "UiVfxBack"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets -- same space as the HUD (UI/init), so AbsolutePositions match
	gui.DisplayOrder = if name == "front" then 40 else -1
	local player = Players.LocalPlayer
	if player then
		gui.Parent = player:WaitForChild("PlayerGui")
	else
		pcall(function() -- no LocalPlayer: Studio previews / headless tests (CoreGui where allowed)
			gui.Parent = game:GetService("CoreGui")
		end)
	end
	local f = Instance.new("Frame")
	f.Name = "Layer"
	f.BackgroundTransparency = 1
	f.Size = UDim2.fromScale(1, 1)
	f.Parent = gui
	layers[name] = f
	return f
end

-- An effect image centred on `gui`, on the back layer (absolute screen position).
local function behind(key: string, gui: GuiObject, size: Vector2): ImageLabel?
	local id = AssetIds.get(key)
	if not id then
		return nil
	end
	local l = UiVfx.layer("back")
	local at = gui.AbsolutePosition + gui.AbsoluteSize / 2 - l.AbsolutePosition
	local img = Instance.new("ImageLabel")
	img.Name = key
	img.BackgroundTransparency = 1
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	img.Image = id
	img.Position = UDim2.fromOffset(at.X, at.Y)
	img.Size = UDim2.fromOffset(size.X, size.Y)
	img.Parent = l
	return img
end

local function centre(gui: GuiObject): Vector2
	return gui.AbsolutePosition + gui.AbsoluteSize / 2
end

local function image(key: string): ImageLabel?
	local id = AssetIds.get(key)
	if not id then
		return nil
	end
	local img = Instance.new("ImageLabel")
	img.Name = key
	img.BackgroundTransparency = 1
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	img.Image = id
	img.ZIndex = 50
	return img
end

-- Small sparkle burst from the centre of `gui` (Motion.burst: pooled, budgeted).
function UiVfx.sparkleBurst(gui: GuiObject, count: number?)
	Motion.burst(UiVfx.layer("front"), centre(gui), "sparkle", count or 8)
end

-- Click impact: a quick ring that expands from the button and a few sparks.
function UiVfx.clickImpact(gui: GuiObject, color: Color3?)
	if Motion.reduced() then
		return
	end
	local l = UiVfx.layer()
	local at = centre(gui) - l.AbsolutePosition
	local ring = Instance.new("Frame")
	ring.Name = "Impact"
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.BackgroundTransparency = 1
	ring.Position = UDim2.fromOffset(at.X, at.Y)
	local s = math.min(gui.AbsoluteSize.X, gui.AbsoluteSize.Y)
	ring.Size = UDim2.fromOffset(s * 0.6, s * 0.6)
	ring.ZIndex = 50
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = ring
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 5
	stroke.Color = color or Color3.new(1, 1, 1)
	stroke.Parent = ring
	ring.Parent = l
	Motion.tween(ring, 0.35, { Size = UDim2.fromOffset(s * 1.5, s * 1.5) }, Enum.EasingStyle.Quart)
	Motion.tween(stroke, 0.35, { Transparency = 1, Thickness = 1 }).Completed:Once(function()
		ring:Destroy()
	end)
	Motion.burst(l, centre(gui), "sparkle", 5)
end

-- One diagonal shine across `gui` (clipped by its own bounds).
function UiVfx.shineSweep(gui: GuiObject)
	if Motion.reduced() then
		return
	end
	local streak = image("fx_shine")
	if not streak then
		return
	end
	gui.ClipsDescendants = true
	streak.Size = UDim2.new(0.35, 0, 2.4, 0)
	streak.Rotation = 20
	streak.Position = UDim2.fromScale(-0.3, 0.5)
	streak.ImageTransparency = 0.25
	streak.ZIndex = gui.ZIndex + 5
	streak.Parent = gui
	Motion.tween(streak, 0.55, { Position = UDim2.fromScale(1.3, 0.5) }, Enum.EasingStyle.Sine).Completed
		:Once(function()
			streak:Destroy()
		end)
end

-- Soft glow that swells behind `gui` and fades.
function UiVfx.glowPulse(gui: GuiObject, color: Color3?, scale: number?)
	if Motion.reduced() then
		return
	end
	local size = gui.AbsoluteSize * 1.1
	local glow = behind("fx_glow", gui, size)
	if not glow then
		return
	end
	glow.ImageColor3 = color or Color3.new(1, 1, 1)
	glow.ImageTransparency = 0.15
	local k = scale or 1.9
	Motion.tween(glow, 0.6, { Size = UDim2.fromOffset(size.X * k, size.Y * k), ImageTransparency = 1 }).Completed
		:Once(function()
			glow:Destroy()
		end)
end

-- Colour sweep over a text label / image (`colors` left to right), then back to plain.
function UiVfx.gradientFlash(gui: GuiObject, colors: { Color3 }, seconds: number?)
	if Motion.reduced() or #colors < 2 then
		return
	end
	local g = Instance.new("UIGradient")
	local keys = {}
	for i, c in colors do
		table.insert(keys, ColorSequenceKeypoint.new((i - 1) / (#colors - 1), c))
	end
	g.Color = ColorSequence.new(keys)
	g.Offset = Vector2.new(-1, 0)
	g.Parent = gui
	Motion.tween(g, seconds or 0.8, { Offset = Vector2.new(1, 0) }, Enum.EasingStyle.Sine).Completed:Once(function()
		g:Destroy()
	end)
end

-- Big moment (perfect kick, upgrade, zone change): spinning rays + glow behind `gui`, a pop, and sparkles.
function UiVfx.celebrate(gui: GuiObject, color: Color3?, strength: number?)
	local k = strength or 1
	local scale = Motion.scaleOf(gui)
	scale.Scale = if Motion.reduced() then 1 else 0.7
	Motion.tween(scale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	if Motion.reduced() then
		return
	end
	local d = math.max(gui.AbsoluteSize.X, gui.AbsoluteSize.Y) * 1.6 * k
	local rays = behind("fx_rays", gui, Vector2.new(d * 0.6, d * 0.6))
	if rays then
		rays.ImageColor3 = color or Color3.fromRGB(255, 240, 160)
		rays.ImageTransparency = 0.2
		Motion.tween(rays, 0.9, { Size = UDim2.fromOffset(d, d), Rotation = 60, ImageTransparency = 1 }).Completed
			:Once(function()
				rays:Destroy()
			end)
	end
	UiVfx.glowPulse(gui, color, 1.6 + 0.4 * k)
	Motion.burst(UiVfx.layer(), centre(gui), "sparkle", math.floor(10 * k))
end

return UiVfx
