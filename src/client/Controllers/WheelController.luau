--!strict
-- The Prize Wheel's client side (Config/Wheel, Builders/Map/Wheel, WheelService):
--   * decorates each segment's label part with its prize: an icon plus, for cash, the amount for YOUR current
--     income (refreshed when IncomePerSecond changes), for eggs the rarity;
--   * on WheelResult (the server's roll) turns the rotor locally (other players' wheels stay still), ticking past
--     each segment and easing to a stop on the won segment under the pointer, then reveals the prize.
-- The server grants the prize when the wheel stops; this only animates.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Wheel = require(Shared.Config.Wheel)
local Pets = require(Shared.Config.Pets)
local Audio = require(Shared.Audio) :: any
local WheelBuilder = require(Shared.Builders.Map.Wheel)

local UI = script.Parent.Parent:WaitForChild("UI")
local AssetIds = require(UI.System.AssetIds)
local Kit = require(UI.Kit)
local Fx = require(UI.Fx)
local Modal = require(UI.System.Modal)

local WheelController = {}

local player = Players.LocalPlayer
local angle = 0 -- the rotor's clockwise turn (radians), client-local
local rest: CFrame? = nil -- the rotor pivot at angle 0
local spinning = false

function WheelController.spinning(): boolean
	return spinning
end

-- The cash a segment pays right now (same rule as WheelService.prize).
function WheelController.cashFor(seg: Wheel.Segment): number
	local ips = player:GetAttribute("IncomePerSecond")
	local rate = if typeof(ips) == "number" and ips == ips and ips > 0 then ips else 0
	return math.max(seg.min or 0, math.floor(rate * (seg.seconds or 0)))
end

local function wheelModel(): Model?
	local map = workspace:FindFirstChild("Map")
	local m = map and map:FindFirstChild("SpinWheel", true)
	return if m and m:IsA("Model") then m else nil
end

local labels: { [number]: TextLabel } = {}

local function paintLabels()
	for i, text in labels do
		local seg = Wheel.Segments[i]
		text.Text = if seg.kind == "Cash" then "$" .. Kit.formatNumber(WheelController.cashFor(seg)) else seg.label
	end
end

local function decorate(model: Model)
	local rotor = model:FindFirstChild("Rotor")
	if not rotor then
		return
	end
	for _, part in rotor:GetChildren() do
		local i = part:GetAttribute("Segment")
		if not (part:IsA("BasePart") and typeof(i) == "number" and Wheel.Segments[i]) then
			continue
		end
		local seg = Wheel.Segments[i]
		local gui = Instance.new("SurfaceGui")
		gui.Name = "Prize"
		gui.Face = Enum.NormalId.Back -- the label's +Z faces the plaza
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud -- (default FixedSize stretches 800x600)
		gui.PixelsPerStud = 30
		gui.LightInfluence = 0
		gui.Parent = part
		local icon = Instance.new("ImageLabel")
		icon.BackgroundTransparency = 1
		icon.AnchorPoint = Vector2.new(0.5, 0)
		icon.Position = UDim2.fromScale(0.5, 0.36) -- inner: the icon (the slice narrows towards the hub)
		icon.Size = UDim2.fromScale(0.68, 0.5)
		icon.ScaleType = Enum.ScaleType.Fit
		icon.Image = AssetIds.get(if seg.kind == "Cash" then "hud_money" else "hud_eggs") or ""
		icon.Parent = gui
		local text = Instance.new("TextLabel")
		text.BackgroundTransparency = 1
		text.Position = UDim2.fromScale(0.02, 0.03) -- outer: the text, where the slice is widest
		text.Size = UDim2.fromScale(0.96, 0.27)
		text.Font = Enum.Font.FredokaOne
		text.TextScaled = true
		text.TextColor3 = Color3.new(1, 1, 1)
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 5
		stroke.Parent = text
		text.Parent = gui
		labels[i] = text
	end
	paintLabels()
end

local function reveal(result: { [string]: any })
	local seg = Wheel.Segments[result.segment]
	if not seg then
		return
	end
	local top, bottom = seg.color:Lerp(Color3.new(1, 1, 1), 0.35), seg.color
	if result.kind == "Cash" and typeof(result.amount) == "number" then
		Fx.callout("+$" .. Kit.formatNumber(result.amount), top, bottom)
		Audio.play("WheelWin")
	else
		local name = "an egg"
		for _, p in Pets do
			if p.id == result.petId then
				name = `a {p.name} egg`
			end
		end
		Fx.callout(if seg.jackpot then "JACKPOT!" else string.upper(seg.label) .. "!", top, bottom)
		Audio.play(if seg.jackpot then "WheelJackpot" else "WheelWin")
		Modal.toast(`You won {name}! It's in your hotbar: put it in your pen.`, "good")
	end
end

local function spin(result: { [string]: any })
	local model = wheelModel()
	local rotor = model and model:FindFirstChild("Rotor")
	local face = model and WheelBuilder.axis(model)
	if not (rotor and rotor:IsA("Model")) or not face or typeof(result.segment) ~= "number" then
		reveal(result)
		return
	end
	-- turn about the wheel's own axis, whatever pivot the model has on this client
	rest = rest or rotor:GetPivot()
	local axis: CFrame = face
	spinning = true
	Audio.play("WheelSpinStart")
	local n = #Wheel.Segments
	local step = 2 * math.pi / n
	local alpha = (result.segment - 1) * step -- where the won segment sits at rest (clockwise from the top)
	local jitter = (math.random() - 0.5) * step * 0.6 -- land somewhere inside it, not always dead centre
	local from = angle
	local target = from - (from % (2 * math.pi)) + 5 * 2 * math.pi + ((2 * math.pi - alpha) % (2 * math.pi)) + jitter
	local duration = if typeof(result.spinSeconds) == "number" then result.spinSeconds else Wheel.SpinSeconds
	local t0 = os.clock()
	local lastTick = math.floor((from + step / 2) / step)
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local t = math.clamp((os.clock() - t0) / duration, 0, 1)
		angle = from + (target - from) * (1 - (1 - t) ^ 4)
		rotor:PivotTo(axis * CFrame.Angles(0, 0, -angle) * axis:Inverse() * (rest :: CFrame))
		local tick = math.floor((angle + step / 2) / step)
		if tick ~= lastTick then
			lastTick = tick
			Audio.play("WheelTick")
		end
		if t >= 1 then
			conn:Disconnect()
			spinning = false
			reveal(result)
		end
	end)
end

function WheelController:Start()
	task.spawn(function()
		local map = workspace:WaitForChild("Map", 60)
		local model = map and map:WaitForChild("SafeZone", 30)
		local wheel = model and model:WaitForChild("SpinWheel", 30)
		if wheel and wheel:IsA("Model") then
			decorate(wheel)
		end
	end)
	player:GetAttributeChangedSignal("IncomePerSecond"):Connect(paintLabels)
	local Remotes = require(Shared:WaitForChild("Remotes")) :: any
	Remotes.get("WheelResult").OnClientEvent:Connect(spin)
end

return WheelController
