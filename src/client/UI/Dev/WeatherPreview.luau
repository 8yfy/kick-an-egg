--!strict
-- DEV ONLY (Roblox Studio; never built on live servers): the weather preview panel. A small "WEATHER DEV" button at
-- the top left opens a list:
--   * SERVER: start a REAL event through WeatherService's own Studio command (/weather <id> 60, random, off), so the
--     whole pipeline runs (server -> WeatherChanged -> visuals, HUD, toast).
--   * PREVIEW: a client-only look at any Registry weather, including the inactive concepts and local storms
--     (WeatherFx.State setGlobal / setLocal with preview = true; nothing reaches the server or other players).
--   * TESTS: rapid A -> B -> C, simulated late join, step into / out of the preview local storm, back to the
--     server's real state.
-- Also a BindableFunction "WeatherDevBridge" under the panel, so Studio tools (MCP execute_luau runs in the plugin's
-- own Lua VM, where a require() gives a separate module copy) can drive the game's real instance:
--   bridge:Invoke("preview", id[, seconds]) / ("local", id) / ("localHere", id) / ("into") / ("out") /
--   ("clearLocal") / ("restore") / ("join") / ("chat", "/weather Stormy 30") / ("state")
--   -> { debug, effective weather, widget attributes, last reason }
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

local Theme = require(script.Parent.Parent.System.Theme)

local WeatherFx = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VFX"):WaitForChild("WeatherFx")) :: any

local WeatherPreview = {}

local PREVIEW_SECONDS = 90
local LOCAL_KEY = "preview"

local function chat(text: string)
	local channels = TextChatService:FindFirstChild("TextChannels")
	local general = channels and channels:FindFirstChild("RBXGeneral")
	if general and general:IsA("TextChannel") then
		general:SendAsync(text)
	else
		warn("[WeatherPreview] no RBXGeneral channel: type " .. text .. " in chat")
	end
end

local function root(): BasePart?
	local char = Players.LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	return if hrp and hrp:IsA("BasePart") then hrp else nil
end

-- The preview local storm sits 60 studs ahead of you on the ground (you start outside it).
local function previewLocal(id: string)
	local hrp = root()
	if not hrp then
		return
	end
	local entry = WeatherFx.Registry.get(id)
	local size: Vector3 = if entry and entry.region then entry.region.size else Vector3.new(80, 60, 90)
	local flat = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
	local dir = if flat.Magnitude > 0.01 then flat.Unit else Vector3.zAxis
	local ground = hrp.Position.Y - 3
	local center = Vector3.new(hrp.Position.X, ground + size.Y / 2, hrp.Position.Z) + dir * (size.Z / 2 + 30)
	WeatherFx.State.setLocal(LOCAL_KEY, id, center, size, workspace:GetServerTimeNow() + 120, true)
end

local function stepInto(inside: boolean)
	local l = WeatherFx.State.locals()[LOCAL_KEY]
	local hrp = root()
	if not l or not hrp then
		return
	end
	local char = hrp.Parent :: Model
	local ground = l.center.Y - l.size.Y / 2 + 4
	local target = if inside
		then Vector3.new(l.center.X, ground, l.center.Z - l.size.Z / 4)
		else Vector3.new(l.center.X, ground, l.center.Z - l.size.Z / 2 - 40)
	char:PivotTo(CFrame.lookAt(target, Vector3.new(l.center.X, ground, l.center.Z)))
end

function WeatherPreview.mount(parent: Instance)
	if not RunService:IsStudio() then
		return
	end
	local old = parent:FindFirstChild("WeatherDev")
	if old then
		old:Destroy()
	end
	local holder = Instance.new("Frame")
	holder.Name = "WeatherDev"
	holder.BackgroundTransparency = 1
	holder.Position = UDim2.fromOffset(16, 64)
	holder.Size = UDim2.fromOffset(230, 30)
	holder.ZIndex = 50
	holder.Parent = parent

	local function button(p: Instance, text: string, color: Color3, onClick: () -> ()): TextButton
		local b = Instance.new("TextButton")
		b.Name = text
		b.Size = UDim2.new(1, 0, 0, 26)
		b.BackgroundColor3 = color
		b.BorderSizePixel = 0
		b.Font = Theme.Font
		b.TextSize = 15
		b.TextColor3 = Color3.new(1, 1, 1)
		b.TextStrokeTransparency = 0.4
		b.Text = text
		b.AutoButtonColor = true
		b:SetAttribute("NoClickSound", true)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = b
		b.Activated:Connect(onClick)
		b.Parent = p
		return b
	end

	local list = Instance.new("ScrollingFrame")
	list.Name = "List"
	list.Position = UDim2.fromOffset(0, 32)
	list.Size = UDim2.fromOffset(230, 420)
	list.BackgroundColor3 = Color3.fromRGB(20, 22, 32)
	list.BackgroundTransparency = 0.15
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 6
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.Visible = false
	list.Parent = holder
	local pad = Instance.new("UIPadding")
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 6), UDim.new(0, 6)
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 6), UDim.new(0, 10)
	pad.Parent = list
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	local toggle = button(holder, "WEATHER DEV", Color3.fromRGB(70, 60, 140), function()
		list.Visible = not list.Visible
	end)
	toggle.Size = UDim2.new(1, 0, 0, 28)

	local n = 0
	local function add(text: string, color: Color3, fn: () -> ())
		n += 1
		button(list, text, color, fn).LayoutOrder = n
	end
	local function header(text: string)
		n += 1
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Size = UDim2.new(1, 0, 0, 20)
		l.Font = Theme.Font
		l.TextSize = 14
		l.TextColor3 = Color3.fromRGB(200, 205, 230)
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.Text = text
		l.LayoutOrder = n
		l.Parent = list
	end

	local SERVER, PREVIEW, TEST = Color3.fromRGB(40, 130, 90), Color3.fromRGB(60, 90, 170), Color3.fromRGB(150, 80, 60)
	header("SERVER (real event, /weather)")
	for _, e in WeatherFx.Registry.list() do
		if e.active then
			add(`{e.id} 60s`, SERVER, function()
				chat(`/weather {e.id} 60`)
			end)
		end
	end
	add("random 60s", SERVER, function()
		chat("/weather random 60")
	end)
	add("off", SERVER, function()
		chat("/weather off")
	end)
	header("PREVIEW (this client only)")
	for _, e in WeatherFx.Registry.list() do
		local tag = if e.active then "" elseif e.scope == "local" then " (local concept)" else " (concept)"
		add(`{e.id}{tag}`, PREVIEW, function()
			if e.scope == "local" then
				previewLocal(e.id)
			else
				WeatherFx.State.setGlobal(e.id, workspace:GetServerTimeNow() + PREVIEW_SECONDS, true)
			end
		end)
	end
	header("TESTS")
	add("A -> B -> C (0.6 s apart)", TEST, function()
		local now = workspace:GetServerTimeNow()
		WeatherFx.State.setGlobal("Sunny", now + 60, true)
		task.delay(0.6, function()
			WeatherFx.State.setGlobal("Snowy", now + 60, true)
		end)
		task.delay(1.2, function()
			WeatherFx.State.setGlobal("Rainbow", now + 60, true)
		end)
	end)
	add("simulate late join", TEST, function()
		WeatherFx.State.simulateJoin()
	end)
	add("step INTO local storm", TEST, function()
		stepInto(true)
	end)
	add("step OUT of local storm", TEST, function()
		stepInto(false)
	end)
	add("clear local storm", TEST, function()
		WeatherFx.State.clearLocal(LOCAL_KEY)
	end)
	add("back to server state", TEST, function()
		WeatherFx.State.clearLocal(LOCAL_KEY)
		WeatherFx.State.restoreServer()
	end)
	add("print debug", TEST, function()
		print("[WeatherPreview]", WeatherFx.debug())
	end)

	local bridge = Instance.new("BindableFunction")
	bridge.Name = "WeatherDevBridge"
	bridge.OnInvoke = function(cmd: string, a: any, b: any): any
		local State = WeatherFx.State
		if cmd == "preview" then
			State.setGlobal(a, if a then workspace:GetServerTimeNow() + (b or PREVIEW_SECONDS) else nil, true)
		elseif cmd == "local" then
			previewLocal(a)
		elseif cmd == "localHere" then -- a local storm that starts on top of you ("HAS STARTED", not "ENTERED")
			local hrp = root()
			local entry = WeatherFx.Registry.get(a)
			if hrp and entry then
				local size: Vector3 = if entry.region then entry.region.size else Vector3.new(80, 60, 90)
				local center = hrp.Position + Vector3.new(0, size.Y / 2 - 3, 0)
				State.setLocal(LOCAL_KEY, a, center, size, workspace:GetServerTimeNow() + 120, true)
			end
		elseif cmd == "into" or cmd == "out" then
			stepInto(cmd == "into")
		elseif cmd == "clearLocal" then
			State.clearLocal(LOCAL_KEY)
		elseif cmd == "restore" then
			State.clearLocal(LOCAL_KEY)
			State.restoreServer()
		elseif cmd == "join" then
			State.simulateJoin()
		elseif cmd == "chat" then
			chat(a)
		end
		local widget = parent:FindFirstChild("WeatherWidget")
		local attrs: { [string]: any } = if widget then widget:GetAttributes() else {}
		attrs.visible = if widget then widget.Visible else nil
		return { debug = WeatherFx.debug(), effective = State.effective(), widget = attrs, reason = State.lastReason() }
	end
	bridge.Parent = holder
end

return WeatherPreview
