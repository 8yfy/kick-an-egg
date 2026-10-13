--!strict
-- Contextual kick controls (bottom centre), a small state machine:
--   hidden  : off the kick pad, in flight / chase, no character. Nothing kick-related is on screen.
--   idle    : on the pad (KickPad.SHOW_RADIUS; the server re-checks with KickPad.ACCEPT_RADIUS). KICK and
--             AUTO KICK pop in with their supplied art; "Press KICK!".
--   timing  : KICK pressed. ONE vertical timing meter from the supplied layers (kick_meter_track behind, the
--             tintable kick_meter_fill clipped to the level, kick_meter_frame on top): the single fill is coloured
--             by the timing band (red Miss, orange Okay, yellow Good, light green Great, bright green Excellent,
--             cyan Perfect), blending smoothly. No second bar slides over it. "Tap anywhere to kick!": while (and
--             only while) the meter waits, a click / tap ANYWHERE on the game view locks it (input a GUI took,
--             e.g. Settings or a close button, and any open window are ignored), as do E / Enter and gamepad R2 / X.
--             One lock per attempt; the listener is disconnected the moment the meter stops.
--   result  : the rating art (Perfect / Excellent / Great / Good / Okay / Miss) plays, the kick is sent
--             (Shared.KickPressed(timing) -> KickController -> RequestKick), then the controls hide while the
--             chase runs (setBusy) and come back only when you're on the pad and free again.
-- The server decides everything: it scores timing with its own bands (KickService.timingBonus: perfect >= 0.9,
-- good >= 0.6, else weak). The six ratings only split those bands for the display; no threshold changes.
-- AUTO KICK is a session toggle (LocalPlayer attribute "AutoKick"): while on and idle on the pad it starts the
-- meter itself and lets go at a random moment (no free perfects). No product gates it: the game has none.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Kit = require(script.Parent.Parent.Kit)
local Fx = require(script.Parent.Parent.Fx)
local System = script.Parent.Parent.System
local Motion = require(System.Motion)
local Ui = require(System.Ui)
local UiVfx = require(System.UiVfx)
local AssetIds = require(System.AssetIds)
local Modal = require(System.Modal)
local KickPad = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("KickPad"))

local SWING_HZ = 1.1 -- the indicator goes bottom -> top -> bottom this many times per second
local TIMING_TIMEOUT = 6 -- seconds of meter with no tap: back to idle
local PENDING_TIMEOUT = 3 -- unlock if the server never answers (rejected kick)
local BUSY_TIMEOUT = 240 -- failsafe if a chase-end event is missed
local AUTO_DELAY = 0.9 -- AUTO KICK: idle seconds before it starts the meter
local RESULT_HOLD = 1.1
local TAP_GUARD = 0.15 -- the click that pressed KICK never also locks the meter
-- the fill art's opaque span on its canvas (kick_meter_fill.png): level 0 = empty, 1 = exactly full
local FILL_BOTTOM, FILL_SPAN = 97 / 1040, 849 / 1040
local METER = Vector2.new(102, 252) -- the meter layers' 414 x 1024 proportions

-- Display ratings inside the server's bands (top first). `band` = which KickService band it belongs to.
local RATINGS: { { at: number, key: string, band: string, color: Color3 } } = {
	{ at = 0.9, key = "rating_perfect", band = "perfect", color = Color3.fromRGB(255, 120, 230) },
	{ at = 0.8, key = "rating_excellent", band = "good", color = Color3.fromRGB(120, 230, 255) },
	{ at = 0.7, key = "rating_great", band = "good", color = Color3.fromRGB(120, 255, 140) },
	{ at = 0.6, key = "rating_good", band = "good", color = Color3.fromRGB(255, 230, 110) },
	{ at = 0.3, key = "rating_okay", band = "weak", color = Color3.fromRGB(255, 180, 90) },
	{ at = 0, key = "rating_miss", band = "weak", color = Color3.fromRGB(230, 80, 80) },
}

-- The meter fill's colour per display band (top first; same bands as RATINGS). Configurable.
local METER_COLORS: { { at: number, color: Color3 } } = {
	{ at = 0.9, color = Color3.fromRGB(70, 235, 255) }, -- Perfect: cyan
	{ at = 0.8, color = Color3.fromRGB(60, 235, 90) }, -- Excellent: bright green
	{ at = 0.7, color = Color3.fromRGB(160, 245, 100) }, -- Great: light green
	{ at = 0.6, color = Color3.fromRGB(255, 225, 60) }, -- Good: yellow
	{ at = 0.3, color = Color3.fromRGB(255, 150, 40) }, -- Okay: orange
	{ at = 0, color = Color3.fromRGB(240, 60, 60) }, -- Miss: red
}

local function meterColor(level: number): Color3
	for _, band in METER_COLORS do
		if level >= band.at then
			return band.color
		end
	end
	return METER_COLORS[#METER_COLORS].color
end

export type KickPanel = {
	setBusy: (busy: boolean) -> (),
	pin: (mode: Mode?, level: number?) -> (), -- previews / tests: hold a state (nil = live again)
}
export type Mode = "hidden" | "idle" | "timing" | "result"

local KickPanel = {}

function KickPanel.rating(timing: number): (string, string, Color3)
	for _, r in RATINGS do
		if timing >= r.at then
			return r.key, r.band, r.color
		end
	end
	local last = RATINGS[#RATINGS]
	return last.key, last.band, last.color
end

local function artButton(parent: Instance, name: string, key: string, size: Vector2): (TextButton, ImageLabel)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Text = ""
	b.AutoButtonColor = false
	b.BackgroundTransparency = 1
	b.Size = UDim2.fromOffset(size.X, size.Y)
	b.AnchorPoint = Vector2.new(0.5, 1)
	b.Selectable = true
	b.Parent = parent
	local art = Ui.art(b, key)
	art.ZIndex = 2
	Motion.interactive(b)
	return b, art
end

function KickPanel.new(parent: Instance): KickPanel
	local player = Players.LocalPlayer
	local root = Instance.new("Frame")
	root.Name = "KickPanel"
	root.BackgroundTransparency = 1
	root.AnchorPoint = Vector2.new(0.5, 1)
	root.Position = UDim2.new(0.5, 0, 1, -12)
	root.Size = UDim2.fromOffset(900, 380)
	root.Visible = false
	root.Parent = parent
	Kit.autoScale(root)

	local kickBtn = artButton(root, "Kick", "kick_button", Vector2.new(400, 120))
	kickBtn.Position = UDim2.new(0.5, 0, 1, 0)
	-- the supplied Auto Kick art (its own lettering + outline: nothing drawn over it); ON / OFF reads from its
	-- brightness and a small chip just outside its corner
	local autoBtn, autoArt = artButton(root, "AutoKick", "kick_auto", Vector2.new(240, 66))
	local autoOn = Kit.label({
		name = "State",
		text = "OFF",
		size = UDim2.fromOffset(60, 26),
		position = UDim2.new(1, 6, 0.5, 0), -- beside the art (never over its lettering or the hint above)
		anchor = Vector2.new(0, 0.5),
		parent = autoBtn,
		stroke = 3,
	})

	local meter = Instance.new("Frame")
	meter.Name = "Meter"
	meter.BackgroundTransparency = 1
	meter.AnchorPoint = Vector2.new(0.5, 1)
	meter.Size = UDim2.fromOffset(METER.X, METER.Y)
	meter.Visible = false
	meter.Parent = root
	local trackArt = Ui.art(meter, "kick_meter_track") -- back layer: the empty track
	trackArt.ZIndex = 2
	local frameArt = Ui.art(meter, "kick_meter_frame") -- front layer: the frame and tick marks
	frameArt.Name = "Frame"
	frameArt.ZIndex = 4
	-- middle layer: the one fill, clipped from the bottom to the level and tinted by the band colour
	local fillClip = Instance.new("Frame")
	fillClip.Name = "Fill"
	fillClip.BackgroundTransparency = 1
	fillClip.ClipsDescendants = true
	fillClip.AnchorPoint = Vector2.new(0, 1)
	fillClip.Position = UDim2.fromScale(0, 1)
	fillClip.Size = UDim2.fromScale(1, 0)
	fillClip.ZIndex = 3
	fillClip.Parent = meter
	local fillArt = Ui.art(fillClip, "kick_meter_fill")
	fillArt.Name = "FillArt"
	fillArt.AnchorPoint = Vector2.new(0, 1)
	fillArt.Position = UDim2.fromScale(0, 1)
	fillArt.Size = UDim2.fromOffset(METER.X, METER.Y) -- the meter's own size: stays aligned while the clip moves
	fillArt.ZIndex = 3
	local fillColor = meterColor(0)
	local function setFill(level: number, dt: number?)
		local l = math.clamp(level, 0, 1)
		fillClip.Size = UDim2.fromScale(1, if l <= 0 then 0 else FILL_BOTTOM + l * FILL_SPAN)
		local target = meterColor(l)
		fillColor = if dt then fillColor:Lerp(target, math.min(1, dt * 14)) else target
		fillArt.ImageColor3 = fillColor
	end
	local perfectTag = Kit.label({
		name = "PerfectTag",
		text = "PERFECT",
		size = UDim2.fromOffset(110, 22),
		position = UDim2.new(1, 8, 1 - (FILL_BOTTOM + 0.95 * FILL_SPAN), 0), -- the Perfect band (0.9 .. 1)
		anchor = Vector2.new(0, 0.5),
		parent = meter,
		color = Color3.fromRGB(140, 255, 120),
		stroke = 3,
	})
	perfectTag.ZIndex = 3

	local hint = Kit.label({
		name = "Hint",
		text = "",
		size = UDim2.fromOffset(440, 44),
		position = UDim2.new(0.5, 0, 1, -128),
		anchor = Vector2.new(0.5, 1),
		parent = root,
		stroke = 4,
	})
	local rating = Instance.new("Frame")
	rating.Name = "Rating"
	rating.BackgroundTransparency = 1
	rating.AnchorPoint = Vector2.new(0.5, 0.5)
	rating.Position = UDim2.new(0.5, 0, 0, 40)
	rating.Size = UDim2.fromOffset(460, 130)
	rating.Visible = false
	rating.Parent = root
	local ratingArt = Ui.art(rating, "rating_good")
	ratingArt.ZIndex = 5

	Kit.onLayout(function(compact: boolean)
		-- desktop: AUTO KICK right of KICK, the meter right of that; phones: stacked in the centre, clear of the
		-- thumbstick (left) and jump button (right)
		autoBtn.AnchorPoint = if compact then Vector2.new(0.5, 1) else Vector2.new(0, 1)
		autoBtn.Position = if compact then UDim2.new(0.5, 0, 1, -128) else UDim2.new(0.5, 214, 1, -30)
		meter.Position = if compact then UDim2.new(0.5, -250, 1, -6) else UDim2.new(0.5, 300, 1, -100)
		hint.Position = if compact then UDim2.new(0.5, 0, 1, -196) else UDim2.new(0.5, 0, 1, -128)
	end)

	local state = {
		mode = "hidden" :: Mode,
		busy = false,
		busySince = 0,
		pendingUntil = 0,
		timingSince = 0,
		idleSince = 0,
		autoReleaseAt = 0,
		resultUntil = 0,
		level = 0,
		pinned = false,
	}
	local stopShimmer: (() -> ())? = nil
	local auto = player ~= nil and player:GetAttribute("AutoKick") == true

	local function setHint(text: string)
		if hint.Text ~= text then
			hint.Text = text
			if text ~= "" then
				Kit.pop(hint, 0.2)
			end
		end
	end

	local function showControls(on: boolean)
		if on == root.Visible then
			return
		end
		if on then
			root.Visible = true
			Motion.popIn(kickBtn)
			Motion.popIn(autoBtn)
			if not stopShimmer then
				stopShimmer = Motion.shine(kickBtn) -- subtle shimmer only while KICK is available
			end
		else
			root.Visible = false
			if stopShimmer then
				stopShimmer()
				stopShimmer = nil
			end
		end
	end

	-- Tap / click anywhere: a global listener that exists only while the meter waits for the tap.
	local setTapListener: (on: boolean) -> ()
	local tapConn: RBXScriptConnection? = nil
	local release: () -> ()
	setTapListener = function(on: boolean)
		if on and not tapConn then
			tapConn = UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
				if processed or state.mode ~= "timing" or os.clock() - state.timingSince < TAP_GUARD then
					return -- a GUI took it (Settings, close buttons, menus), or the KICK press itself
				end
				if Modal.current() ~= nil or GuiService.MenuIsOpen then
					return -- a window / the Roblox menu is open: not the game view
				end
				local t = input.UserInputType
				if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
					release()
				end
			end)
		elseif not on and tapConn then
			tapConn:Disconnect()
			tapConn = nil
		end
	end

	local function enter(mode: Mode)
		if state.mode == mode then
			return
		end
		state.mode = mode
		local now = os.clock()
		if mode == "hidden" then
			meter.Visible = false
			rating.Visible = false
			setHint("")
			showControls(false)
		elseif mode == "idle" then
			state.idleSince = now
			meter.Visible = false
			kickBtn.Visible, autoBtn.Visible = true, true
			showControls(true)
			setHint(if auto then "AUTO KICK is on" else "Press KICK!")
		elseif mode == "timing" then
			state.timingSince = now
			state.autoReleaseAt = now + 0.5 + math.random() * 1.3
			meter.Visible = true
			Motion.popIn(meter)
			setHint(
				if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
					then "Tap anywhere to kick!"
					else "Click anywhere to kick!"
			)
		elseif mode == "result" then
			state.resultUntil = now + RESULT_HOLD
			kickBtn.Visible, autoBtn.Visible = false, false
			setHint("")
			-- the locked level stays a moment with a flash on the fill (successful timing), then the meter goes
			fillArt.ImageColor3 = Color3.new(1, 1, 1)
			Motion.tween(fillArt, 0.25, { ImageColor3 = fillColor })
			if not Motion.reduced() then
				Motion.popIn(meter)
			end
			task.delay(0.35, function()
				if state.mode == "result" then
					meter.Visible = false
				end
			end)
		end
		setTapListener(mode == "timing")
		if player then
			player:SetAttribute("KickTiming", mode == "timing") -- (KickLineController: brace + camera ease-in)
		end
	end

	local function playRating(timing: number)
		local key, band, color = KickPanel.rating(timing)
		local id = AssetIds.get(key)
		if id then
			ratingArt.Image = id
		end
		rating.Visible = true
		rating.Rotation = if Motion.reduced() then 0 else math.random(-6, 6)
		rating.Position = UDim2.new(0.5, 0, 0, 40)
		ratingArt.ImageTransparency = 0
		local scale = Motion.scaleOf(rating)
		scale.Scale = if Motion.reduced() then 1 else 0.3
		Motion.tween(scale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
		UiVfx.gradientFlash(ratingArt, { Color3.new(1, 1, 1), color, Color3.new(1, 1, 1) }, 0.7)
		if band == "perfect" then
			UiVfx.celebrate(rating, color, 1.4)
			Fx.flash(Color3.fromRGB(255, 250, 220), 0.3)
		elseif band == "good" then
			UiVfx.sparkleBurst(rating, if key == "rating_excellent" then 12 else 7)
		elseif key == "rating_miss" and not Motion.reduced() then
			Motion.tween(rating, 0.08, { Rotation = -10 }).Completed:Once(function()
				Motion.tween(rating, 0.3, { Rotation = 0 }, Enum.EasingStyle.Elastic)
			end)
		end
		task.delay(RESULT_HOLD - 0.3, function()
			if state.pinned then
				return -- previews hold the rating on screen
			end
			Motion.tween(rating, 0.3, { Position = UDim2.new(0.5, 0, 0, 0) })
			Motion.tween(ratingArt, 0.3, { ImageTransparency = 1 })
		end)
	end

	release = function()
		if state.mode ~= "timing" then
			return
		end
		local t = state.level
		state.pendingUntil = os.clock() + PENDING_TIMEOUT
		enter("result")
		playRating(t)
		local shared = ReplicatedStorage:FindFirstChild("Shared")
		local ev = shared and shared:FindFirstChild("KickPressed")
		if ev and ev:IsA("BindableEvent") then
			ev:Fire(t)
		else
			warn("[HUD] Shared.KickPressed is missing (created by Partner B's client loader)")
		end
	end

	local function press()
		if state.mode == "idle" then
			UiVfx.clickImpact(kickBtn, Color3.fromRGB(140, 255, 90))
			enter("timing")
		elseif state.mode == "timing" then
			release()
		end
	end
	kickBtn.Activated:Connect(press)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not root.Visible then
			return
		end
		local k = input.KeyCode
		if
			k == Enum.KeyCode.E
			or k == Enum.KeyCode.Return
			or k == Enum.KeyCode.ButtonR2
			or k == Enum.KeyCode.ButtonX
		then
			press()
		end
	end)

	local stopAutoPulse: (() -> ())? = nil
	local function paintAuto()
		-- ON: the art at full colour with a gentle pulse; OFF: dimmed. The chip names the state.
		autoArt.ImageColor3 = if auto then Color3.new(1, 1, 1) else Color3.fromRGB(150, 150, 165)
		autoArt.ImageTransparency = if auto then 0 else 0.15
		autoOn.Text = if auto then "ON" else "OFF"
		autoOn.TextColor3 = if auto then Color3.fromRGB(140, 255, 90) else Color3.fromRGB(220, 220, 230)
		if auto and not stopAutoPulse and not Motion.reduced() then
			stopAutoPulse = Kit.pulse(autoBtn, 1.04)
		elseif not auto and stopAutoPulse then
			stopAutoPulse()
			stopAutoPulse = nil
		end
	end
	paintAuto()
	autoBtn.Activated:Connect(function()
		auto = not auto
		if player then
			player:SetAttribute("AutoKick", auto)
		end
		paintAuto()
		Kit.pop(autoOn, 0.2)
		UiVfx.clickImpact(autoBtn, if auto then Color3.fromRGB(255, 225, 80) else Color3.new(1, 1, 1))
		if state.mode == "idle" then
			setHint(if auto then "AUTO KICK is on" else "Press KICK!")
			state.idleSince = os.clock()
		end
	end)

	if player then
		player.CharacterRemoving:Connect(function()
			enter("hidden") -- respawn / reset: no ghost buttons or half-done meters
		end)
	end

	RunService.RenderStepped:Connect(function()
		if state.pinned then
			return
		end
		local now = os.clock()
		if state.busy and now - state.busySince > BUSY_TIMEOUT then
			state.busy = false
		end
		local pending = now < state.pendingUntil
		local onPad = player ~= nil and KickPad.has(player.Character, KickPad.SHOW_RADIUS)
		local mode = state.mode
		if mode == "result" then
			if now < state.resultUntil then
				return
			end
			rating.Visible = false
			mode = "hidden"
			state.mode = "hidden"
			showControls(false)
		end
		if state.busy or pending or not onPad then
			enter("hidden")
			return
		end
		if mode == "hidden" then
			enter("idle")
		elseif mode == "idle" then
			if auto and now - state.idleSince >= AUTO_DELAY then
				enter("timing")
			end
		elseif mode == "timing" then
			if now - state.timingSince > TIMING_TIMEOUT then
				enter("idle")
				return
			end
			local level = 0.5 - 0.5 * math.cos(2 * math.pi * SWING_HZ * (now - state.timingSince))
			state.level = level
			setFill(level, 1 / 60)
			if auto and now >= state.autoReleaseAt then
				release()
			end
		end
	end)

	return {
		setBusy = function(busy: boolean)
			state.busy = busy
			state.busySince = os.clock()
			state.pendingUntil = 0
		end,
		pin = function(mode: Mode?, level: number?)
			state.pinned = mode ~= nil
			if not mode then
				return
			end
			enter("hidden")
			if mode == "hidden" then
				return
			end
			enter("idle")
			if mode == "timing" or mode == "result" then
				enter("timing")
				state.level = level or 0.5
				setFill(state.level)
			end
			if mode == "result" then
				enter("result")
				playRating(state.level)
			end
		end,
	}
end

return KickPanel
