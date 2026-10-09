--!strict
-- KICK button + timing meter (bottom centre). Pressing KICK fires Shared.KickPressed(timing);
-- Partner B's KickController sends RequestKick. The meter is cosmetic: the server decides the bonus.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Kit = require(script.Parent.Parent.Kit)
local Economy = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Economy"))

-- Bands match KickService's timingBonus (perfect >= 0.9, good >= 0.6) unless Economy defines them.
local PERFECT_AT: number = (Economy.TimingBonus :: any).perfectAt or 0.9
local GOOD_AT: number = (Economy.TimingBonus :: any).goodAt or 0.6
local SWING_HZ = 1.2 -- needle goes 0 -> 1 -> 0 this many times per second
local PAD_RANGE = 9 -- studs from the kick pad centre where KICK is enabled
local PENDING_TIMEOUT = 3 -- unlock if the server never answers (rejected kick)
local BUSY_TIMEOUT = 240 -- failsafe if a chase-end event is missed

export type KickPanel = { setBusy: (busy: boolean) -> () }

local KickPanel = {}

local function nearPad(): boolean
	local map = workspace:FindFirstChild("Map")
	local pad = map and map:FindFirstChild("KickPad")
	local char = Players.LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not (pad and pad:IsA("BasePart")) then
		return true -- no map yet (e.g. UI test place): don't block
	end
	if not (hrp and hrp:IsA("BasePart")) then
		return false
	end
	local d = hrp.Position - pad.Position
	return Vector2.new(d.X, d.Z).Magnitude <= PAD_RANGE
end

function KickPanel.new(parent: Instance): KickPanel
	local root = Kit.panel({
		name = "KickPanel",
		size = UDim2.fromOffset(460, 200),
		position = UDim2.new(0.5, 0, 1, -20),
		anchor = Vector2.new(0.5, 1),
		parent = parent,
	})
	Kit.autoScale(root)

	-- Timing meter: miss / good / perfect bands and a swinging needle.
	local meter = Kit.panel({
		name = "Meter",
		size = UDim2.fromOffset(440, 46),
		position = UDim2.fromOffset(10, 48),
		parent = root,
		colors = Kit.Colors.dark,
		radius = 12,
	})
	local track = Kit.panel({
		name = "Track",
		size = UDim2.new(1, -10, 1, -10),
		position = UDim2.fromOffset(5, 5),
		parent = meter,
	})
	local function band(name: string, from: number, to: number, colors: { Color3 })
		local b = Kit.panel({
			name = name,
			size = UDim2.new(to - from, -2, 1, 0),
			position = UDim2.new(from, 1, 0, 0),
			parent = track,
			colors = colors,
			radius = 8,
			stroke = false,
		})
		return b
	end
	band("Miss", 0, GOOD_AT, Kit.Colors.red)
	band("Good", GOOD_AT, PERFECT_AT, Kit.Colors.yellow)
	local perfect = band("Perfect", PERFECT_AT, 1, Kit.Colors.green)
	Kit.label({
		name = "Tag",
		text = "PERFECT",
		size = UDim2.new(1, 24, 0, 18),
		position = UDim2.new(0.5, 0, 0, -22),
		anchor = Vector2.new(0.5, 0),
		parent = perfect,
		stroke = 2,
	})
	local needle = Kit.panel({
		name = "Needle",
		size = UDim2.fromOffset(10, 62),
		position = UDim2.fromScale(0, 0.5),
		anchor = Vector2.new(0.5, 0.5),
		parent = track,
		colors = { Color3.new(1, 1, 1), Color3.fromRGB(220, 220, 230) },
		radius = 4,
	})
	needle.ZIndex = 3

	local feedback = Kit.label({
		name = "Feedback",
		text = "",
		size = UDim2.fromOffset(360, 40),
		position = UDim2.new(0.5, 0, 0, 0),
		anchor = Vector2.new(0.5, 0),
		parent = root,
	})

	local state = { busy = false, busySince = 0, pendingUntil = 0, frozenUntil = 0, t0 = os.clock(), timing = 0 }
	local mode = ""

	local function flash(text: string, color: Color3)
		feedback.Text = text
		feedback.TextColor3 = color
		feedback.TextTransparency = 0
		Kit.pop(feedback)
		task.delay(0.9, function()
			if feedback.Text == text then
				Kit.tween(feedback, 0.3, { TextTransparency = 1 })
			end
		end)
	end

	local button: TextButton
	local gradient: UIGradient
	local function kick()
		if mode ~= "ready" then
			return
		end
		local t = state.timing
		state.frozenUntil = os.clock() + 0.6
		state.pendingUntil = os.clock() + PENDING_TIMEOUT
		if t >= PERFECT_AT then
			flash("PERFECT!", Kit.Colors.green[1])
		elseif t >= GOOD_AT then
			flash("GOOD!", Kit.Colors.yellow[1])
		else
			flash("WEAK KICK", Kit.Colors.red[1])
		end
		local shared = ReplicatedStorage:FindFirstChild("Shared")
		local ev = shared and shared:FindFirstChild("KickPressed")
		if ev and ev:IsA("BindableEvent") then
			ev:Fire(t)
		else
			warn("[HUD] Shared.KickPressed is missing (created by Partner B's client loader)")
		end
	end
	button, gradient = Kit.button({
		name = "Kick",
		text = "KICK!",
		size = UDim2.fromOffset(240, 86),
		position = UDim2.new(0.5, 0, 1, 0),
		anchor = Vector2.new(0.5, 1),
		parent = root,
		colors = { Color3.fromRGB(135, 245, 70), Color3.fromRGB(60, 190, 40) },
		radius = 20,
		onClick = kick,
	})
	local buttonLabel = button:FindFirstChild("Label") :: TextLabel
	buttonLabel.Size = UDim2.new(1, -96, 0.7, 0)
	buttonLabel.Position = UDim2.new(0.5, 34, 0.5, 0)
	local kickIcon = require(script.Parent.Parent.Icons).view(button, "Power", UDim2.fromOffset(76, 76))
	kickIcon.Position = UDim2.fromOffset(8, 5)

	local function setMode(m: string)
		if m == mode then
			return
		end
		mode = m
		local ready = m == "ready"
		button.Active = ready
		gradient.Color = if ready
			then ColorSequence.new(Color3.fromRGB(135, 245, 70), Color3.fromRGB(60, 190, 40))
			else ColorSequence.new(table.unpack(Kit.Colors.grey))
		kickIcon.ImageTransparency = if ready then 0 else 0.4
		buttonLabel.Text = if m == "busy" then "CHASE!" else "KICK!"
		meter.Visible = ready
		if m == "far" then
			feedback.Text = "Walk onto the kick pad!"
			feedback.TextColor3 = Kit.Colors.white
			feedback.TextTransparency = 0
		elseif feedback.Text == "Walk onto the kick pad!" then
			feedback.Text = ""
		end
		if ready then
			Kit.pop(meter, 0.3)
		end
	end

	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		local pending = now < state.pendingUntil
		if state.busy and now - state.busySince > BUSY_TIMEOUT then
			state.busy = false
		end
		setMode(if state.busy or pending then "busy" elseif nearPad() then "ready" else "far")
		if mode == "ready" and now >= state.frozenUntil then
			state.timing = 0.5 - 0.5 * math.cos(2 * math.pi * SWING_HZ * (now - state.t0))
			needle.Position = UDim2.fromScale(state.timing, 0.5)
		end
	end)

	return {
		setBusy = function(busy: boolean)
			state.busy = busy
			state.busySince = os.clock()
			state.pendingUntil = 0
		end,
	}
end

return KickPanel
