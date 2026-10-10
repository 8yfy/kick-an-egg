--!strict
-- The single modal manager (UI handoff SCREEN-SPEC "Shared shell", MOTION-SPEC modal open/close):
--   * at most one large modal; opening another swaps instantly under the same scrim,
--   * dark scrim (tap to close), red close button, gamepad ButtonB closes,
--   * open 280 ms (scale .90 -> 1.025 -> 1, Y +14 -> 0, content fades in), close 160 ms (-> .96, Y +8, fade),
--     a generation counter drops stale completions so rapid open/close always settles on the latest request,
--   * focus: gamepad selection moves into the modal and returns to the launcher on close,
--   * screens are built lazily on first open; header/close/footer are fixed and only the body scrolls,
--   * size: 1200x760 design pixels under one device UIScale; narrow/short screens get a smaller logical
--     size (screens reflow via Ui.grid) instead of tiny text.
-- Also owns the transient reward layer (Motion bursts) and the toast queue (max 3).
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local Motion = require(script.Parent.Motion)
local Theme = require(script.Parent.Theme)
local Ui = require(script.Parent.Ui)

local C, L, M = Theme.Colors, Theme.Layout, Theme.Motion
local Modal = {}

export type Shell = {
	name: string,
	container: Frame, -- shadow + panel; animated
	panel: Frame,
	header: Frame,
	title: TextLabel,
	body: Frame, -- content area (padded); screens put their scroll surface here
	footer: Frame?,
	size: () -> Vector2, -- logical (design-pixel) size of the panel
}

export type Screen = {
	open: (() -> ())?, -- every time it opens: refresh from Data
	close: (() -> ())?,
	update: (() -> ())?, -- data changed while open
	resize: ((size: Vector2, compact: boolean) -> ())?,
	focus: (() -> GuiObject?)?,
}

export type Options = {
	title: string,
	gradient: Ui.Gradient,
	icon: string?, -- AssetIds key
	footer: boolean?,
}

type Entry = { options: Options, build: (shell: Shell) -> Screen, shell: Shell?, screen: Screen? }

local entries: { [string]: Entry } = {}
local gui: ScreenGui
local scrim: TextButton
local host: Frame
local hostScale: UIScale
local fxLayer: Frame
local toastLayer: Frame
local current: string? = nil
local launcher: GuiObject? = nil
local gen = 0
local logical = Vector2.new(L.modalW, L.modalH)
local listeners: { (name: string?) -> () } = {}

local SCRIM_ALPHA = 0.45

local function topInset(): number
	local ok, rect = pcall(function()
		return GuiService.TopbarInset
	end)
	if ok and typeof(rect) == "Rect" and rect.Height > 0 then
		return rect.Height
	end
	return 58
end

local function compact(): boolean
	return logical.Y < 600
end

local function relayout()
	local cam = workspace.CurrentCamera
	local vp = if cam then cam.ViewportSize else Vector2.new(1920, 1080)
	local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local s = math.min(vp.X / 1920, vp.Y / 1080) * (if touch then 1.35 else 1)
	s = math.clamp(s, 0.6, 1.4)
	local inset = topInset()
	local availW, availH = (vp.X - 32) / s, (vp.Y - inset - 20) / s
	logical = Vector2.new(math.floor(math.min(L.modalW, availW)), math.floor(math.min(L.modalH, availH)))
	hostScale.Scale = s
	host.Position = UDim2.new(0.5, 0, 0, inset + (vp.Y - inset) / 2)
	for _, entry in entries do
		local shell = entry.shell
		if shell then
			shell.container.Size = UDim2.fromOffset(logical.X, logical.Y)
			local screen = entry.screen
			if screen and screen.resize then
				screen.resize(logical, compact())
			end
		end
	end
end

-- Shell ----------------------------------------------------------------------------------------------------

local function buildShell(name: string, o: Options): Shell
	local container = Ui.frame(host, "Modal_" .. name, UDim2.fromOffset(logical.X, logical.Y))
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.Position = UDim2.fromScale(0.5, 0.5)
	container.Visible = false
	container.Active = true -- swallow clicks so they don't reach the scrim

	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.BackgroundColor3 = C.stroke
	shadow.BackgroundTransparency = 0.35
	shadow.BorderSizePixel = 0
	shadow.Size = UDim2.fromScale(1, 1)
	shadow.Position = UDim2.fromOffset(0, 10)
	Ui.corner(shadow, 16)
	shadow.Parent = container

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.BackgroundColor3 = C.panel
	panel.BorderSizePixel = 0
	panel.Size = UDim2.fromScale(1, 1)
	Ui.corner(panel, 16)
	Ui.stroke(panel)
	Ui.studs(panel)
	Ui.innerEdge(panel, 0.6)
	panel.Parent = container

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Position = UDim2.fromOffset(10, 10)
	header.Size = UDim2.new(1, -20, 0, L.header)
	header.ClipsDescendants = true
	Ui.corner(header, 12)
	Ui.gradient(header, o.gradient)
	Ui.stroke(header)
	Ui.studs(header, Theme.Studs.header)
	header.Parent = panel
	Motion.shine(header)

	local titleRow = Ui.frame(header, "TitleRow", UDim2.new(1, -110, 1, 0), UDim2.fromOffset(20, 0))
	Ui.list(titleRow, 12, true)
	if o.icon then
		Ui.icon(titleRow, o.icon, 60).LayoutOrder = 1
	end
	local title = Ui.text(titleRow, o.title, 46, { autoX = true, stroke = 4, name = "Title" })
	title.LayoutOrder = 2

	local close = Ui.closeButton(panel, function()
		Modal.close()
	end)
	close.AnchorPoint = Vector2.new(1, 0.5)
	close.Position = UDim2.new(1, -24, 0, 10 + L.header / 2)
	close.ZIndex = 5

	local footerH = if o.footer then L.footer else 0
	local body = Ui.frame(
		panel,
		"Body",
		UDim2.new(1, -2 * L.pad, 1, -(10 + L.header + 16 + footerH + L.pad)),
		UDim2.fromOffset(L.pad, 10 + L.header + 16)
	)
	local footer: Frame? = nil
	if o.footer then
		local f = Ui.frame(panel, "Footer", UDim2.new(1, -2 * L.pad, 0, footerH), UDim2.new(0, L.pad, 1, -footerH - 12))
		footer = f
	end

	local veil = Instance.new("Frame")
	veil.Name = "Veil"
	veil.BackgroundColor3 = C.panelDeep
	veil.BackgroundTransparency = 1
	veil.BorderSizePixel = 0
	veil.Size = UDim2.new(1, 8, 1, 18)
	veil.Position = UDim2.fromOffset(-4, -4)
	veil.ZIndex = 100
	veil.Active = false
	Ui.corner(veil, 16)
	veil.Parent = container

	return {
		name = name,
		container = container,
		panel = panel,
		header = header,
		title = title,
		body = body,
		footer = footer,
		size = function()
			return logical
		end,
	}
end

local function veilOf(shell: Shell): Frame
	return shell.container:FindFirstChild("Veil") :: Frame
end

local function ensure(name: string): Entry?
	local entry = entries[name]
	if not entry then
		warn(`[Modal] unknown screen {name}`)
		return nil
	end
	if not entry.shell then
		local shell = buildShell(name, entry.options)
		entry.shell = shell
		entry.screen = entry.build(shell)
		local screen = entry.screen
		if screen and screen.resize then
			screen.resize(logical, compact())
		end
	end
	return entry
end

local function notify()
	for _, fn in listeners do
		task.spawn(fn, current)
	end
end

-- Focus ----------------------------------------------------------------------------------------------------

local function usingGamepad(): boolean
	local t = UserInputService:GetLastInputType()
	return t.Name:sub(1, 7) == "Gamepad"
end

local function firstSelectable(root: Instance): GuiObject?
	for _, d in root:GetDescendants() do
		if d:IsA("GuiButton") and d.Selectable and d.Visible and d.Name ~= "Close" then
			return d
		end
	end
	return nil
end

local function bindBack(on: boolean)
	if on then
		ContextActionService:BindActionAtPriority("KTE_CloseModal", function(_, state)
			if state == Enum.UserInputState.Begin then
				Modal.close()
			end
			return Enum.ContextActionResult.Sink
		end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.ButtonB)
	else
		ContextActionService:UnbindAction("KTE_CloseModal")
	end
end

-- Open / close ---------------------------------------------------------------------------------------------

local function hideNow(entry: Entry)
	local shell = entry.shell
	if not shell then
		return
	end
	Motion.stop(Motion.scaleOf(shell.container))
	Motion.stop(shell.container)
	shell.container.Visible = false
	local screen = entry.screen
	if screen and screen.close then
		screen.close()
	end
end

function Modal.open(name: string, from: GuiObject?)
	if current == name then
		return
	end
	local entry = ensure(name)
	if not entry then
		return
	end
	if current then
		local old = entries[current]
		if old then
			hideNow(old)
		end
	end
	gen += 1
	local my = gen
	current = name
	if from then
		launcher = from
	end
	local shell = entry.shell :: Shell
	local screen = entry.screen :: Screen
	if screen.open then
		screen.open()
	end

	local container = shell.container
	local scale = Motion.scaleOf(container)
	local veil = veilOf(shell)
	local home = UDim2.fromScale(0.5, 0.5)
	container.Visible = true
	scrim.Visible = true
	if Motion.reduced() then
		scale.Scale = 1
		container.Position = home
		veil.BackgroundTransparency = 0
		Motion.tween(veil, M.reduced, { BackgroundTransparency = 1 })
		Motion.tween(scrim, M.reduced, { BackgroundTransparency = SCRIM_ALPHA })
	else
		scale.Scale = 0.9
		container.Position = home + UDim2.fromOffset(0, 14)
		veil.BackgroundTransparency = 0
		Motion.tween(scrim, M.open, { BackgroundTransparency = SCRIM_ALPHA })
		Motion.tween(veil, 0.18, { BackgroundTransparency = 1 })
		Motion.tween(container, M.open, { Position = home }, Enum.EasingStyle.Quart)
		Motion.tween(scale, M.open * 0.65, { Scale = 1.025 }).Completed:Once(function(state)
			if state == Enum.PlaybackState.Completed and gen == my then
				Motion.tween(scale, M.open * 0.35, { Scale = 1 }, Enum.EasingStyle.Sine)
			end
		end)
	end
	bindBack(true)
	if usingGamepad() then
		local target = (screen.focus and screen.focus()) or firstSelectable(shell.panel)
		if target then
			GuiService.SelectedObject = target
		end
	end
	notify()
end

function Modal.close()
	local name = current
	if not name then
		return
	end
	local entry = entries[name]
	current = nil
	gen += 1
	local my = gen
	bindBack(false)
	local shell = entry and entry.shell
	if entry and entry.screen and entry.screen.close then
		entry.screen.close()
	end
	if shell then
		local container = shell.container
		local scale = Motion.scaleOf(container)
		local veil = veilOf(shell)
		local seconds = if Motion.reduced() then M.reduced else M.close
		if not Motion.reduced() then
			Motion.tween(scale, seconds, { Scale = 0.96 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			Motion.tween(
				container,
				seconds,
				{ Position = UDim2.new(0.5, 0, 0.5, 8) },
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.In
			)
		end
		Motion.tween(veil, seconds, { BackgroundTransparency = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		Motion.tween(scrim, seconds, { BackgroundTransparency = 1 }).Completed:Once(function()
			if gen == my then
				container.Visible = false
				scrim.Visible = false
			end
		end)
	end
	-- Focus returns to the launcher.
	local selected = GuiService.SelectedObject
	if selected and shell and selected:IsDescendantOf(shell.container) then
		GuiService.SelectedObject = nil
	end
	local back = launcher
	if back and back.Parent and usingGamepad() then
		GuiService.SelectedObject = back
	end
	notify()
end

function Modal.toggle(name: string, from: GuiObject?)
	if current == name then
		Modal.close()
	else
		Modal.open(name, from)
	end
end

function Modal.current(): string?
	return current
end

-- Called after every DataChanged: only the open screen re-renders (closed ones refresh on open).
function Modal.refresh()
	local name = current
	local entry = name and entries[name]
	if entry and entry.screen and entry.screen.update then
		entry.screen.update()
	end
end

function Modal.define(name: string, options: Options, build: (shell: Shell) -> Screen)
	entries[name] = { options = options, build = build }
end

function Modal.onChanged(fn: (name: string?) -> ())
	table.insert(listeners, fn)
end

-- Full-screen transient layer for reward particles (above modals).
function Modal.layer(): Frame
	return fxLayer
end

-- Toasts: slide +12 -> 0 and fade in (180 ms), dwell 2.2 s, exit 140 ms; at most 3 at once.
local toasts: { Frame } = {}
local toastCount = 0
function Modal.toast(text: string, kind: ("info" | "good" | "error")?)
	while #toasts >= 3 do
		local oldest = table.remove(toasts, 1)
		if oldest then
			oldest:Destroy()
		end
	end
	local t = Instance.new("Frame")
	t.Name = "Toast"
	t.AutomaticSize = Enum.AutomaticSize.XY
	t.Size = UDim2.fromOffset(0, 0)
	t.BackgroundColor3 = C.panelDeep
	t.BackgroundTransparency = 0.05
	toastCount += 1
	t.LayoutOrder = toastCount
	Ui.corner(t, 12)
	local stroke = Ui.stroke(t)
	stroke.Color = if kind == "error"
		then Theme.Gradients.red[2]
		elseif kind == "good" then Theme.Gradients.lime[2]
		else C.stroke
	Ui.padding(t, 18, 10)
	local label = Ui.text(t, text, 24, { autoX = true })
	t.Parent = toastLayer
	table.insert(toasts, t)
	local scale = Motion.scaleOf(t)
	if not Motion.reduced() then
		scale.Scale = 0.94
		Motion.tween(scale, 0.18, { Scale = 1 })
	end
	label.TextTransparency = 1
	t.BackgroundTransparency = 1
	Motion.tween(label, 0.18, { TextTransparency = 0 })
	Motion.tween(t, 0.18, { BackgroundTransparency = 0.05 })
	task.delay(0.18 + 2.2, function()
		if not t.Parent then
			return
		end
		Motion.tween(label, 0.14, { TextTransparency = 1 })
		Motion.tween(t, 0.14, { BackgroundTransparency = 1 }).Completed:Once(function()
			local i = table.find(toasts, t)
			if i then
				table.remove(toasts, i)
			end
			t:Destroy()
		end)
	end)
end

function Modal.init(playerGui: Instance)
	gui = Instance.new("ScreenGui")
	gui.Name = "Modals"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 10
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	scrim = Instance.new("TextButton")
	scrim.Name = "Scrim"
	scrim.Text = ""
	scrim.AutoButtonColor = false
	scrim.Selectable = false
	scrim.BackgroundColor3 = C.scrim
	scrim.BackgroundTransparency = 1
	scrim.BorderSizePixel = 0
	scrim.Size = UDim2.fromScale(1, 1)
	scrim.Visible = false
	scrim.Activated:Connect(function()
		Modal.close()
	end)
	scrim.Parent = gui

	host = Instance.new("Frame")
	host.Name = "Host"
	host.BackgroundTransparency = 1
	host.AnchorPoint = Vector2.new(0.5, 0.5)
	host.Size = UDim2.fromOffset(0, 0)
	hostScale = Instance.new("UIScale")
	hostScale.Parent = host
	host.Parent = gui

	fxLayer = Ui.frame(gui, "Transient")
	fxLayer.ZIndex = 50

	toastLayer = Ui.frame(gui, "Toasts", UDim2.new(1, 0, 0, 300), UDim2.new(0, 0, 0, topInset() + 12))
	toastLayer.ZIndex = 60
	local list = Ui.list(toastLayer, 10, false, Enum.HorizontalAlignment.Center)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	local toastScale = Instance.new("UIScale")
	toastScale.Parent = toastLayer

	gui.Parent = playerGui
	relayout()
	local cam = workspace.CurrentCamera
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			relayout()
			toastScale.Scale = hostScale.Scale
		end)
	end
	toastScale.Scale = hostScale.Scale
end

return Modal
