--!strict
-- 2D animation for the approved HUD icons (the art is never changed, only moved): a gentle idle per icon, a click
-- reaction, and event reactions (money up, power up, sound toggled). One Heartbeat drives every idle, only for
-- icons on screen and never under Reduced Motion; clicks and events are short tweens (Motion cancels overlaps).
--   Shop: soft bob + an occasional shine        Index: small tilt          Rebirth: controlled sway, spin on click
--   Eggs: rocking                               Pets: playful hop          Settings: slow gear turn, fast on click
--   Sound / Money / Power: still until something happens (toggle pulse / money pop / power impact)
local RunService = game:GetService("RunService")
local Motion = require(script.Parent.Motion)
local UiVfx = require(script.Parent.UiVfx)

local IconMotion = {}

export type Style = "shop" | "index" | "rebirth" | "eggs" | "pets" | "settings" | "sound" | "money" | "power"

type Entry = {
	icon: GuiObject,
	style: Style,
	home: UDim2,
	phase: number,
	extra: NumberValue, -- additive rotation for click spins
	lift: NumberValue, -- additive Y offset (px) for click bounces
}

local entries: { Entry } = {}

local function idle(e: Entry, t: number): (number, number)
	local s = e.style
	local a = t + e.phase
	if s == "shop" then
		return math.sin(a * 2.1) * 2.5, math.sin(a * 1.05) * 3
	elseif s == "index" then
		return 0, math.sin(a * 1.4) * 4
	elseif s == "rebirth" then
		return 0, math.sin(a * 0.8) * 10
	elseif s == "eggs" then
		return 0, math.sin(a * 1.8) * 5
	elseif s == "pets" then
		local c = a % 2.6 -- a quick hop every 2.6 s
		return if c < 0.4 then -math.sin(c / 0.4 * math.pi) * 7 else 0, 0
	elseif s == "settings" then
		return 0, (a * 22) % 360
	end
	return 0, 0
end

RunService.Heartbeat:Connect(function()
	local t = os.clock()
	local reduced = Motion.reduced()
	for i = #entries, 1, -1 do
		local e = entries[i]
		if not e.icon.Parent then
			table.remove(entries, i)
			continue
		end
		if not Motion.onScreen(e.icon) then
			continue
		end
		local y, rot = 0, 0
		if not reduced then
			y, rot = idle(e, t)
		end
		e.icon.Position = e.home + UDim2.fromOffset(0, y + e.lift.Value)
		e.icon.Rotation = rot + e.extra.Value
	end
end)

-- Start animating `icon` (an ImageLabel or its holder). Returns a stop function.
function IconMotion.attach(icon: GuiObject, style: Style): () -> ()
	local extra = Instance.new("NumberValue")
	local lift = Instance.new("NumberValue")
	local e: Entry =
		{ icon = icon, style = style, home = icon.Position, phase = math.random() * 10, extra = extra, lift = lift }
	table.insert(entries, e)
	local stopShine: (() -> ())? = nil
	local holder = icon.Parent
	if style == "shop" and holder and holder:IsA("GuiObject") then
		holder.ClipsDescendants = true -- the shine stays on the icon, never streaks across the HUD
		stopShine = Motion.shine(holder)
	end
	return function()
		local i = table.find(entries, e)
		if i then
			table.remove(entries, i)
		end
		icon.Position = e.home
		icon.Rotation = 0
		if stopShine then
			stopShine()
		end
	end
end

local function entryOf(icon: GuiObject): Entry?
	for _, e in entries do
		if e.icon == icon then
			return e
		end
	end
	return nil
end

-- Squash-and-pop on the icon's own UIScale.
local function pop(icon: GuiObject, peak: number)
	local scale = Motion.scaleOf(icon)
	if Motion.reduced() then
		return
	end
	scale.Scale = 0.86
	Motion.tween(scale, 0.12, { Scale = peak }, Enum.EasingStyle.Quad).Completed:Once(function()
		Motion.tween(scale, 0.22, { Scale = 1 }, Enum.EasingStyle.Back)
	end)
end

-- Click reaction (call from the button's Activated).
function IconMotion.click(icon: GuiObject, style: Style)
	pop(icon, 1.15)
	UiVfx.clickImpact(icon)
	local e = entryOf(icon)
	if not e or Motion.reduced() then
		return
	end
	if style == "rebirth" or style == "settings" then
		e.extra.Value = 0
		Motion.tween(
			e.extra,
			if style == "rebirth" then 0.55 else 0.4,
			{ Value = if style == "rebirth" then 360 else 180 },
			Enum.EasingStyle.Quart
		).Completed
			:Once(function()
				e.extra.Value = 0
			end)
	elseif style == "index" or style == "pets" or style == "shop" or style == "eggs" then
		Motion.tween(e.lift, 0.1, { Value = -8 }, Enum.EasingStyle.Quad).Completed:Once(function()
			Motion.tween(e.lift, 0.25, { Value = 0 }, Enum.EasingStyle.Bounce)
		end)
	end
end

-- Money went up: a scale pulse and a few sparkles.
function IconMotion.moneyUp(icon: GuiObject)
	pop(icon, 1.18)
	UiVfx.sparkleBurst(icon, 6)
end

-- Kick Power went up: a punchy impact with a warm glow.
function IconMotion.powerUp(icon: GuiObject)
	pop(icon, 1.25)
	UiVfx.glowPulse(icon, Color3.fromRGB(255, 210, 90), 2)
	local e = entryOf(icon)
	if e and not Motion.reduced() then
		Motion.tween(e.extra, 0.06, { Value = -8 }).Completed:Once(function()
			Motion.tween(e.extra, 0.3, { Value = 0 }, Enum.EasingStyle.Elastic)
		end)
	end
end

-- Sound toggled: a short pulse (the button dims itself when muted).
function IconMotion.toggled(icon: GuiObject)
	pop(icon, 1.12)
end

return IconMotion
