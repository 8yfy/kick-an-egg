--!strict
-- The weather notice: a short card in the game's toast lane (top centre, under the quest / zone bar; Modal owns the
-- lane, so it never overlaps other toasts). Once per event revision (WeatherFx.State revKey), never per duplicate
-- server message:
--   "<NAME> HAS STARTED!"     a weather began while it affects you (or replaced another)
--   "CURRENT WEATHER: <NAME>" you joined mid-event, or stepped out of a local storm into an event you were not told about
--   "ENTERED <NAME>"          you walked into a local storm that was already running
-- Small weather icon on the left, sparkle accents (images, not font glyphs), the name in the weather's colour.
-- In 0.22 s (pop + fade), holds 2.6 s, out 0.3 s. Reduced Motion: fades only. Plays the weather's start cue (2D, UI
-- group) for a start or an entry, nothing for a mid-event hint. Never sinks input.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local System = script.Parent.Parent.System
local Motion = require(System.Motion)
local Theme = require(System.Theme)
local Ui = require(System.Ui)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local WeatherFx = require(Shared:WaitForChild("VFX"):WaitForChild("WeatherFx")) :: any
local WorldSprites = require(Shared:WaitForChild("VFX"):WaitForChild("WorldSprites")) :: any

local C = Theme.Colors
local HOLD = 2.6

local WeatherToast = {}

export type WeatherToast = { destroy: () -> (), shown: { [string]: string } }

function WeatherToast.text(reason: string, label: string, accent: Color3): string?
	local name = `<font color="#{accent:ToHex()}">{label}</font>`
	if reason == "start" or reason == "switch" then
		return `{name} HAS STARTED!`
	elseif reason == "join" or reason == "leave" or reason == "end" then
		return `CURRENT WEATHER: {name}`
	elseif reason == "enter" then
		return `ENTERED {name}`
	end
	return nil -- "extend": same event, new end time
end

-- `lane`: Modal.toastLane() in the game (a list layout), or any container in previews.
function WeatherToast.new(lane: () -> GuiObject, opts: { state: any? }?): WeatherToast
	local State = (opts and opts.state) or WeatherFx.State
	local shown: { [string]: string } = {}
	local order = 0

	local function post(snap: any, reason: string)
		if not snap.id or not snap.revKey or shown[snap.revKey] then
			return
		end
		local entry = WeatherFx.Registry.get(snap.id)
		local label = if entry then entry.label else string.upper(snap.id)
		local accent = if entry then entry.accent else Color3.fromRGB(180, 230, 255)
		local text = WeatherToast.text(reason, label, accent)
		if not text then
			return
		end
		shown[snap.revKey] = text
		order += 1

		local card = Instance.new("CanvasGroup")
		card.Name = "WeatherToast"
		card.AutomaticSize = Enum.AutomaticSize.XY
		card.Size = UDim2.fromOffset(0, 0)
		card.BackgroundColor3 = C.card
		card.BackgroundTransparency = 0.04
		card.GroupTransparency = 1
		card.LayoutOrder = -100000 + order -- above the game's own toasts in the lane
		card.Interactable = false
		Ui.corner(card)
		local stroke = Ui.stroke(card, 4)
		stroke.Color = accent:Lerp(C.border, 0.35)
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		Ui.padding(card, 14, 8)
		local row = Ui.list(card, 8, true, Enum.HorizontalAlignment.Center)
		row.VerticalAlignment = Enum.VerticalAlignment.Center

		local function sparkle(n: number)
			local s = Instance.new("ImageLabel")
			s.Name = "Sparkle"
			s.BackgroundTransparency = 1
			s.Image = WorldSprites.sparkle
			s.ImageColor3 = accent
			s.Size = UDim2.fromOffset(22, 22)
			s.LayoutOrder = n
			s.Parent = card
		end
		sparkle(1)
		if entry and entry.icon then
			local icon = Instance.new("ImageLabel")
			icon.Name = "Icon"
			icon.BackgroundTransparency = 1
			icon.Image = entry.icon
			icon.ScaleType = Enum.ScaleType.Fit
			icon.Size = UDim2.fromOffset(40, 40)
			icon.LayoutOrder = 2
			icon.Parent = card
		end
		local label_ = Ui.text(card, "", 24, { autoX = true, stroke = 3, name = "Text" })
		label_.RichText = true
		label_.Text = text
		label_.LayoutOrder = 3
		sparkle(4)

		card.Parent = lane()
		local reduced = Motion.reduced()
		local pop = Motion.scaleOf(card)
		if not reduced then
			pop.Scale = 0.86
			Motion.tween(pop, 0.32, { Scale = 1 }, Enum.EasingStyle.Back)
		end
		Motion.tween(card, if reduced then Theme.Motion.reduced else 0.22, { GroupTransparency = 0 })
		if reason == "start" or reason == "switch" or reason == "enter" then
			local key = entry and entry.sounds.start
			if key then
				WeatherFx.Sound.play(key)
			end
		end
		task.delay(HOLD + 0.22, function()
			if not card.Parent then
				return
			end
			if not reduced then
				Motion.tween(pop, 0.3, { Scale = 0.94 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end
			Motion.tween(card, 0.3, { GroupTransparency = 1 }).Completed:Once(function()
				card:Destroy()
			end)
		end)
	end

	local unsubscribe = State.subscribe(function(snap: any, reason: string)
		post(snap, reason)
	end)
	-- a weather already known before this HUD existed (the late-join message can beat the UI): announce it once
	local now = State.effective()
	if now.id then
		post(now, State.lastReason() or "join")
	end
	return {
		shown = shown,
		destroy = unsubscribe,
	}
end

return WeatherToast
