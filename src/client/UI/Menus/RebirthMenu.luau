--!strict
-- Rebirth: current rebirths and multiplier, the Kick Power requirement as a progress bar, and a
-- two-tap confirm that fires Rebirth (the server checks the requirement and resets progress).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kit = require(script.Parent.Parent.Kit)
local Window = require(script.Parent.Window)
local Economy = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Economy"))

export type Menu = { window: Window.Window, update: (data: { [string]: any }) -> () }

local RebirthMenu = {}

function RebirthMenu.new(parent: Instance): Menu
	local window = Window.new(parent, "Rebirth", Kit.Colors.yellow)
	local body = window.body

	local count = Kit.label({
		name = "Count",
		text = "",
		size = UDim2.new(1, 0, 0, 60),
		position = UDim2.fromOffset(0, 10),
		parent = body,
	})
	local mult = Kit.label({
		name = "Multiplier",
		text = "",
		size = UDim2.new(1, 0, 0, 40),
		position = UDim2.fromOffset(0, 76),
		parent = body,
		color = Kit.Colors.green[1],
	})
	local perks = Kit.label({
		name = "Perks",
		text = "",
		size = UDim2.new(1, -60, 0, 34),
		position = UDim2.fromOffset(30, 130),
		parent = body,
		color = Color3.fromRGB(220, 215, 240),
	})
	local req = Kit.label({
		name = "Requirement",
		text = "",
		size = UDim2.new(1, -60, 0, 34),
		position = UDim2.fromOffset(30, 196),
		parent = body,
	})
	local bar = Kit.panel({
		name = "Bar",
		size = UDim2.new(1, -120, 0, 30),
		position = UDim2.fromOffset(60, 240),
		parent = body,
		colors = { Color3.fromRGB(30, 25, 40), Color3.fromRGB(50, 45, 65) },
		radius = 14,
		stroke = false,
	})
	local fill = Kit.panel({
		name = "Fill",
		size = UDim2.fromScale(0, 1),
		parent = bar,
		colors = Kit.Colors.yellow,
		radius = 14,
		stroke = false,
	})

	local armedUntil = 0
	local ready = false
	local button: TextButton
	local gradient: UIGradient
	button, gradient = Kit.button({
		name = "Rebirth",
		text = "REBIRTH",
		size = UDim2.fromOffset(320, 90),
		position = UDim2.new(0.5, 0, 1, -10),
		anchor = Vector2.new(0.5, 1),
		parent = body,
		colors = Kit.Colors.purple,
		radius = 24,
		onClick = function()
			if not ready then
				return
			end
			local label = button:FindFirstChild("Label") :: TextLabel
			if os.clock() > armedUntil then
				armedUntil = os.clock() + 3
				label.Text = "TAP TO CONFIRM"
				task.delay(3, function()
					if os.clock() >= armedUntil then
						label.Text = "REBIRTH"
					end
				end)
				return
			end
			armedUntil = 0
			label.Text = "REBIRTH"
			local remotes = ReplicatedStorage:FindFirstChild("Remotes")
			local ev = remotes and remotes:FindFirstChild("Rebirth")
			if ev and ev:IsA("RemoteEvent") then
				ev:FireServer()
			end
		end,
	})

	return {
		window = window,
		update = function(data: { [string]: any })
			local rebirths = if typeof(data.rebirths) == "number" then data.rebirths else 0
			local power = if typeof(data.kickPower) == "number" then data.kickPower else Economy.KickPower.base
			local cfg = Economy.Rebirth
			count.Text = `Rebirths: {rebirths}`
			mult.Text =
				`Kick distance x{1 + rebirths * cfg.multiplierPerRebirth} → x{1 + (rebirths + 1) * cfg.multiplierPerRebirth}`
			perks.Text = `+{cfg.powerCapBonus} max Kick Power · progress resets`
			local need = Economy.KickPower.max + rebirths * cfg.powerCapBonus -- the cap grows each rebirth
			req.Text = `Needs max Kick Power: {Kit.formatNumber(power)} / {Kit.formatNumber(need)}`
			local k = math.clamp(power / need, 0, 1)
			Kit.tween(fill, 0.3, { Size = UDim2.fromScale(k, 1) })
			ready = k >= 1
			button.Active = ready
			gradient.Color = ColorSequence.new(table.unpack(if ready then Kit.Colors.purple else Kit.Colors.grey))
		end,
	}
end

return RebirthMenu
