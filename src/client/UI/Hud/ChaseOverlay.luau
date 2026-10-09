--!strict
-- Owner-only chase overlay: "distance to avalanche" bar (green -> red) under the quest bar and an
-- arrow above the KICK panel pointing to the egg, then HOME once you carry it.
-- Front position comes from Chase.frontZ (same as the server). The egg position is the egg model
-- if one named after eggUid exists in workspace, otherwise the server's run formula.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kit = require(script.Parent.Parent.Kit)
local Chase = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Chase"))

local FAR = 150 -- studs at which the bar is full / green

export type ChaseOverlay = {
	start: (payload: { [string]: any }) -> (),
	pickedUp: () -> (),
	stop: () -> (),
}

local ChaseOverlay = {}

function ChaseOverlay.new(parent: Instance): ChaseOverlay
	-- Distance bar
	local bar = Kit.panel({
		name = "AvalancheBar",
		size = UDim2.fromOffset(420, 58),
		position = UDim2.new(0.5, 0, 0.15, 86),
		anchor = Vector2.new(0.5, 0),
		parent = parent,
		colors = Kit.Colors.dark,
		radius = 16,
	})
	Kit.autoScale(bar)
	Kit.label({
		name = "Title",
		text = "AVALANCHE",
		size = UDim2.fromOffset(150, 24),
		position = UDim2.fromOffset(14, 4),
		parent = bar,
		align = Enum.TextXAlignment.Left,
		color = Kit.Colors.red[1],
	})
	local distText = Kit.label({
		name = "Distance",
		text = "",
		size = UDim2.fromOffset(150, 24),
		position = UDim2.new(1, -14, 0, 4),
		anchor = Vector2.new(1, 0),
		parent = bar,
		align = Enum.TextXAlignment.Right,
	})
	local track = Kit.panel({
		name = "Track",
		size = UDim2.new(1, -28, 0, 16),
		position = UDim2.fromOffset(14, 32),
		parent = bar,
		colors = { Color3.fromRGB(30, 25, 40), Color3.fromRGB(50, 45, 65) },
		radius = 8,
		stroke = false,
	})
	local fill = Kit.panel({
		name = "Fill",
		size = UDim2.fromScale(1, 1),
		parent = track,
		colors = Kit.Colors.green,
		radius = 8,
		stroke = false,
	})
	local fillGradient = fill:FindFirstChildOfClass("UIGradient") :: UIGradient

	-- Arrow (built from blocks: shaft + rotated-square head) inside a rotating holder.
	local holder = Kit.panel({
		name = "EggArrow",
		size = UDim2.fromOffset(110, 140),
		position = UDim2.new(0.5, 0, 0.15, 150),
		anchor = Vector2.new(0.5, 0),
		parent = parent,
	})
	Kit.autoScale(holder)
	local dial = Kit.panel({
		name = "Dial",
		size = UDim2.fromOffset(96, 96),
		position = UDim2.fromOffset(7, 0),
		parent = holder,
	})
	local shaft = Kit.panel({
		name = "Shaft",
		size = UDim2.fromOffset(22, 46),
		position = UDim2.fromOffset(37, 42),
		parent = dial,
		colors = Kit.Colors.yellow,
		radius = 6,
	})
	local head = Kit.panel({
		name = "Head",
		size = UDim2.fromOffset(46, 46),
		position = UDim2.fromOffset(25, 14),
		parent = dial,
		colors = Kit.Colors.yellow,
		radius = 8,
	})
	head.Rotation = 45
	shaft.ZIndex, head.ZIndex = 2, 2
	local arrowText = Kit.label({
		name = "Label",
		text = "EGG",
		size = UDim2.fromOffset(110, 34),
		position = UDim2.new(0, 0, 1, 0),
		anchor = Vector2.new(0, 1),
		parent = holder,
	})

	bar.Visible, holder.Visible = false, false
	local payload: { [string]: any }? = nil
	local carrying = false
	local conn: RBXScriptConnection? = nil
	local eggModel: Instance? = nil
	local lastLookup = 0

	local function eggPosition(p: { [string]: any }, now: number): Vector3
		if (not eggModel or not eggModel.Parent) and os.clock() - lastLookup > 1 then
			lastLookup = os.clock()
			eggModel = workspace:FindFirstChild(tostring(p.eggUid), true)
		end
		local m = eggModel
		if m and m:IsA("Model") then
			return m:GetPivot().Position
		end
		local startPos: Vector3 = p.eggStartPos or Vector3.zero
		local run = math.max(0, now - (p.eggRunStart or now))
		return Vector3.new(startPos.X, startPos.Y, startPos.Z - Chase.Egg.runSpeed * run)
	end

	local function update()
		local p = payload
		local cam = workspace.CurrentCamera
		local char = Players.LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not (p and cam and hrp and hrp:IsA("BasePart")) then
			return
		end
		local now = workspace:GetServerTimeNow()
		local front = Chase.frontZ(p.startZ, p.startTime, p.speed, now)
		local d = math.max(0, front - hrp.Position.Z)
		local k = math.clamp(d / FAR, 0, 1)
		fill.Size = UDim2.fromScale(math.max(k, 0.04), 1)
		local hot = Kit.Colors.red
		local mid = Kit.Colors.yellow
		local cool = Kit.Colors.green
		local pair = if k < 0.25 then hot elseif k < 0.6 then mid else cool
		fillGradient.Color = ColorSequence.new(pair[1], pair[2])
		distText.Text = `{math.floor(d)} studs`
		distText.TextColor3 = if k < 0.25 then hot[1] else Kit.Colors.white

		local target = if carrying then Vector3.new(0, 0, Chase.SafeLineZ - 4) else eggPosition(p, now)
		local rel = cam.CFrame:VectorToObjectSpace(target - hrp.Position)
		dial.Rotation = math.deg(math.atan2(rel.X, -rel.Z))
		local flat = Vector2.new(target.X - hrp.Position.X, target.Z - hrp.Position.Z).Magnitude
		arrowText.Text = `{if carrying then "HOME" else "EGG"} {math.floor(flat)}`
	end

	local function stop()
		payload = nil
		carrying = false
		eggModel = nil
		if conn then
			conn:Disconnect()
			conn = nil
		end
		bar.Visible, holder.Visible = false, false
	end

	return {
		start = function(p: { [string]: any })
			stop()
			payload = p
			bar.Visible, holder.Visible = true, true
			Kit.pop(bar)
			Kit.pop(holder)
			conn = RunService.RenderStepped:Connect(update)
		end,
		pickedUp = function()
			carrying = true
			Kit.pop(holder, 0.25)
		end,
		stop = stop,
	}
end

return ChaseOverlay
