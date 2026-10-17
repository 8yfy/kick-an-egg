--!strict
-- The weather widget, bottom right: the ONE weather affecting this player (a local storm you stand in, else the
-- global event; WeatherFx.State decides), never a list or a history.
--     NAME     small outlined label
--     MM:SS    the countdown, ABOVE the icon (server end time via workspace:GetServerTimeNow(): no drift, late-join
--              safe, clamped at 00:00; hidden when the event has no end time - a countdown is never invented)
--     [icon]   the weather's PNG alone, unframed, 1:1. Two ImageLabels crossfade (0.3 s) when the weather changes,
--              then the old one is cleared. No icon in the Registry (or a failed load) -> a conspicuous MISSING ICON
--              marker + one warning, never a borrowed picture.
-- Hidden while there is no weather. Reduced Motion: fades only. Never sinks input (Interactable = false).
-- Phones (compact): the right column (rail, sound, settings) fills the right edge and Roblox's jump button the corner,
-- so the widget sits left of the jump button, right of the hotbar, a bit larger and without the name (the icon and
-- the toast carry it). Tablets: left of their bigger jump button. Attributes for tests: Weather, Scope, Seconds, Icon.
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Kit = require(script.Parent.Parent.Kit)
local System = script.Parent.Parent.System
local Motion = require(System.Motion)
local Theme = require(System.Theme)
local Ui = require(System.Ui)

local WeatherFx = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VFX"):WaitForChild("WeatherFx")) :: any

local C = Theme.Colors
local W, ICON = 132, 112 -- design px (scaled with the HUD); the voxel art fills ~70 % of its square PNG
local NAME_H, TIMER_H = 22, 38
local GRACE = 4 -- hide this long after 00:00 if the server's "ended" never arrives
local ICON_FADE = 0.3
-- Right / bottom offsets (design px are scaled; these are screen px): clear Roblox's touch jump button, which sits at
-- (1, -95, 1, -90) size 70 on phones and (1, -170, 1, -210) size 120 on tablets.
local PHONE_RIGHT, PHONE_BOTTOM, PHONE_FIT = 104, 10, 1.25
local TABLET_RIGHT, TABLET_BOTTOM = 180, 14
local DESKTOP_RIGHT, DESKTOP_BOTTOM = 18, 16

local WeatherWidget = {}

export type WeatherWidget = { root: Frame, destroy: () -> () }

-- 0 -> "00:00", 75 -> "01:15", 3725 -> "1:02:05"
function WeatherWidget.clock(seconds: number): string
	local s = math.max(0, math.floor(seconds))
	local h, m = s // 3600, (s // 60) % 60
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, s % 60)
	end
	return string.format("%02d:%02d", m, s % 60)
end

function WeatherWidget.new(parent: Instance, opts: { clock: (() -> number)?, state: any? }?): WeatherWidget
	local now: () -> number = (opts and opts.clock) or function(): number
		return workspace:GetServerTimeNow()
	end
	local State = (opts and opts.state) or WeatherFx.State
	local old = parent:FindFirstChild("WeatherWidget")
	if old then
		old:Destroy()
	end

	local root = Ui.frame(parent, "WeatherWidget", UDim2.fromOffset(W, NAME_H + TIMER_H + ICON + 4))
	root.AnchorPoint = Vector2.new(1, 1)
	root.Visible = false
	root.Interactable = false
	Kit.autoScale(root)

	local fit = Ui.frame(root, "Fit")
	fit.AnchorPoint = Vector2.new(1, 1)
	fit.Position = UDim2.fromScale(1, 1)
	local fitScale = Instance.new("UIScale")
	fitScale.Parent = fit

	local group = Instance.new("CanvasGroup")
	group.Name = "Fade"
	group.BackgroundTransparency = 1
	group.Size = UDim2.fromScale(1, 1)
	group.GroupTransparency = 1
	group.Parent = fit
	local pop = Motion.scaleOf(group)

	local name = Ui.text(group, "", 17, { align = Enum.TextXAlignment.Center, stroke = 2, name = "Name" })
	name.Size = UDim2.new(1, 0, 0, NAME_H)
	name.TextScaled = true
	local nameFit = Instance.new("UITextSizeConstraint")
	nameFit.MaxTextSize = 17
	nameFit.MinTextSize = 10
	nameFit.Parent = name

	local timer = Ui.text(group, "", 32, { align = Enum.TextXAlignment.Center, stroke = 3, name = "Timer" })
	timer.Position = UDim2.fromOffset(0, NAME_H - 2)
	timer.Size = UDim2.new(1, 0, 0, TIMER_H)

	local holder = Ui.frame(group, "Icon", UDim2.fromOffset(ICON, ICON))
	holder.AnchorPoint = Vector2.new(0.5, 1)
	holder.Position = UDim2.fromScale(0.5, 1)
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1
	aspect.Parent = holder
	local function image(n: string): ImageLabel
		local img = Instance.new("ImageLabel")
		img.Name = n
		img.BackgroundTransparency = 1
		img.ScaleType = Enum.ScaleType.Fit
		img.Size = UDim2.fromScale(1, 1)
		img.ImageTransparency = 1
		img.Parent = holder
		return img
	end
	local imgs = { image("IconA"), image("IconB") }
	local front = 1

	-- MISSING ICON marker (Studio and live): named, loud, never a substitute picture
	local marker = Instance.new("Frame")
	marker.Name = "MissingIcon"
	marker.BackgroundColor3 = Color3.fromHex("2A0A24")
	marker.BackgroundTransparency = 0.15
	marker.Size = UDim2.fromScale(0.86, 0.86)
	marker.AnchorPoint = Vector2.new(0.5, 0.5)
	marker.Position = UDim2.fromScale(0.5, 0.5)
	marker.Visible = false
	Ui.corner(marker)
	Ui.stroke(marker, 3, C.missing)
	local markerText =
		Ui.text(marker, "MISSING\nICON", 14, { wrap = true, align = Enum.TextXAlignment.Center, color = C.missing })
	markerText.AnchorPoint = Vector2.new(0.5, 0.5)
	markerText.Position = UDim2.fromScale(0.5, 0.5)
	markerText.Size = UDim2.new(1, -6, 0, 0)
	marker.Parent = holder

	local function place()
		local compact = Kit.compact()
		local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
		if compact then
			root.Position = UDim2.new(1, -PHONE_RIGHT, 1, -PHONE_BOTTOM)
		elseif touch then
			root.Position = UDim2.new(1, -TABLET_RIGHT, 1, -TABLET_BOTTOM)
		else
			root.Position = UDim2.new(1, -DESKTOP_RIGHT, 1, -DESKTOP_BOTTOM)
		end
		fitScale.Scale = if compact then PHONE_FIT else 1
		name.Visible = not compact
	end
	Kit.onLayout(place)

	-- state ------------------------------------------------------------------------------------------------------
	local id: string? = nil
	local endsAt: number? = nil
	local token = 0
	local shownSeconds = -1
	local warned: { [string]: boolean } = {}

	local function warnOnce(key: string, text: string)
		if not warned[key] then
			warned[key] = true
			warn(text)
		end
	end

	local function setIcon(entryId: string, icon: string?)
		token += 1
		local tk = token
		local back = imgs[front]
		front = 3 - front
		local img = imgs[front]
		local t = if Motion.reduced() then Theme.Motion.reduced else ICON_FADE
		Motion.tween(back, t, { ImageTransparency = 1 })
		task.delay(t, function()
			if tk == token then
				back.Image = "" -- the old icon is gone once faded: one icon at a time
			end
		end)
		if not icon then
			img.Image = ""
			marker.Visible = true
			root:SetAttribute("Icon", "MISSING")
			warnOnce(
				entryId,
				`[WeatherWidget] no icon for weather "{entryId}": MISSING ICON marker shown (Registry icon = nil)`
			)
			return
		end
		marker.Visible = false
		img.Image = icon
		img.ImageTransparency = 1
		Motion.tween(img, t, { ImageTransparency = 0 })
		root:SetAttribute("Icon", icon)
		task.spawn(function()
			local ok = true
			pcall(function()
				ContentProvider:PreloadAsync({ img }, function(_c: string, status: Enum.AssetFetchStatus)
					if status == Enum.AssetFetchStatus.Failure then
						ok = false
					end
				end)
			end)
			if not ok and tk == token then
				img.Image = ""
				marker.Visible = true
				root:SetAttribute("Icon", "FAILED")
				warnOnce(
					icon,
					`[WeatherWidget] icon for "{entryId}" failed to load ({icon}): MISSING ICON marker shown`
				)
			end
		end)
	end

	local function paintTimer()
		if not endsAt then
			timer.Visible = false
			root:SetAttribute("Seconds", nil)
			return
		end
		timer.Visible = true
		local left = (endsAt :: number) - now()
		local s = math.max(0, math.ceil(left - 0.001))
		if s ~= shownSeconds then
			shownSeconds = s
			timer.Text = WeatherWidget.clock(s)
			root:SetAttribute("Seconds", s)
		end
	end

	local hideToken = 0
	local function show(snap: any)
		local nextId: string? = snap.id
		endsAt = snap.endsAt
		shownSeconds = -1
		hideToken += 1
		local ht = hideToken
		local reduced = Motion.reduced()
		if not nextId then
			id = nil
			root:SetAttribute("Weather", nil)
			root:SetAttribute("Scope", nil)
			Motion.tween(group, if reduced then Theme.Motion.reduced else 0.3, { GroupTransparency = 1 })
			task.delay(0.32, function()
				if ht == hideToken then
					root.Visible = false
				end
			end)
			return
		end
		local entry = WeatherFx.Registry.get(nextId)
		if not entry then
			warnOnce("entry:" .. nextId, `[WeatherWidget] weather "{nextId}" has no Registry entry: name only`)
		end
		name.Text = if entry then entry.label else string.upper(nextId)
		root:SetAttribute("Weather", nextId)
		root:SetAttribute("Scope", snap.scope)
		paintTimer()
		if nextId ~= id then
			setIcon(nextId, if entry then entry.icon else nil)
		end
		local wasHidden = not root.Visible or id == nil
		id = nextId
		root.Visible = true
		if wasHidden then
			if reduced then
				pop.Scale = 1
				Motion.tween(group, Theme.Motion.reduced, { GroupTransparency = 0 })
			else
				pop.Scale = 0.88
				Motion.tween(group, 0.3, { GroupTransparency = 0 })
				Motion.tween(pop, 0.38, { Scale = 1 }, Enum.EasingStyle.Back)
			end
		end
	end

	local conns: { RBXScriptConnection } = {}
	local unsubscribe = State.subscribe(function(snap: any)
		show(snap)
	end)
	table.insert(
		conns,
		RunService.Heartbeat:Connect(function()
			if id and endsAt then
				paintTimer()
				if now() - (endsAt :: number) > GRACE and root.Visible then
					-- the server's "ended" never came: stop showing a finished event
					show({ id = nil })
				end
			end
		end)
	)
	show(State.effective())

	local widget: WeatherWidget
	widget = {
		root = root,
		destroy = function()
			unsubscribe()
			for _, c in conns do
				c:Disconnect()
			end
			root:Destroy()
		end,
	}
	root.Destroying:Connect(function()
		unsubscribe()
		for _, c in conns do
			c:Disconnect()
		end
	end)
	return widget
end

return WeatherWidget
