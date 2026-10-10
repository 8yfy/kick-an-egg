--!strict
-- The single modal manager (UI handoff v2 VISUAL-CONTRACT "Desktop foundation", MOTION-SPEC modal motion):
--   * one large modal at a time; opening another swaps instantly under the same scrim,
--   * layout in a 1440 x 960 design space, scaled to fit 92% of the safe viewport; short (phone) screens get
--     a smaller logical height instead of unreadable text (screens reflow on `compact`),
--   * shell: 5 px near-black border, 8 px corners, 6 px drop shadow, full-width 92 px header (section
--     gradient, studs, two strips, shine, 52 px uppercase title, optional 64 px icon), 70 x 70 red close,
--     optional fixed 78 px footer; only the body scrolls,
--   * open 280 ms (scale .90 -> 1.025 -> 1, Y +14 -> 0, content fades in), close 160 ms (-> .96, Y +8, fade);
--     a generation counter drops stale completions so rapid open/close settles on the latest request,
--   * scrim tap / ButtonB / close button close it; gamepad focus moves in and returns to the launcher.
-- Also owns the transient reward layer, the toast lane (max 3, kept below the "Eggs secured" bar) and, in
-- Studio, the LOCAL ART banner while supplied PNGs have no uploaded ids.
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local AssetIds = require(script.Parent.AssetIds)
local Motion = require(script.Parent.Motion)
local Theme = require(script.Parent.Theme)
local Ui = require(script.Parent.Ui)

local C, L, M = Theme.Colors, Theme.Layout, Theme.Motion
local Modal = {}

export type Shell = {
	name: string,
	container: Frame, -- shadow + panel; animated
	panel: Frame,
	header: Ui.Header,
	body: Frame, -- content area (inset 20); screens put their scroll surface here
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
	header: Theme.Pair,
	icon: string?, -- AssetIds key (64 x 64 header icon)
	footer: boolean?,
}

type Entry = { options: Options, build: (shell: Shell) -> Screen, shell: Shell?, screen: Screen? }

local entries: { [string]: Entry } = {}
local root: GuiObject | LayerCollector
local scrim: TextButton
local host: Frame
local hostScale: UIScale
local fxLayer: Frame
local toastLayer: Frame
local toastScale: UIScale
local current: string? = nil
local launcher: GuiObject? = nil
local gen = 0
local logical = Vector2.new(L.designW, L.designH)
local listeners: { (name: string?) -> () } = {}
local toastAnchor: GuiObject? = nil
local preview: { size: Vector2, touch: boolean }? = nil

local SCRIM_ALPHA = 0.45

local function topInset(): number
	if preview then
		return 0
	end
	local ok, rect = pcall(function()
		return GuiService.TopbarInset
	end)
	if ok and typeof(rect) == "Rect" and rect.Height > 0 then
		return rect.Height
	end
	return 58
end

local function viewport(): (Vector2, boolean)
	if preview then
		return preview.size, preview.touch
	end
	local cam = workspace.CurrentCamera
	local vp = if cam then cam.ViewportSize else Vector2.new(1920, 1080)
	return vp, UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function compact(): boolean
	return logical.Y < 700
end

local function relayout()
	local vp, touch = viewport()
	local inset = topInset()
	local availW, availH = vp.X * 0.92, (vp.Y - inset) * 0.92
	local s = math.min(availW / L.designW, availH / L.designH)
	s = math.clamp(s, if touch then 0.55 else 0.5, 1.5)
	logical = Vector2.new(math.floor(math.min(L.designW, availW / s)), math.floor(math.min(L.designH, availH / s)))
	hostScale.Scale = s
	host.Position = UDim2.new(0.5, 0, 0, inset + (vp.Y - inset) / 2)
	toastScale.Scale = math.clamp(s, 0.6, 1.2)
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

	for i, spec in { { 6, 0.35 }, { 14, 0.75 } } do -- 6 px shadow + a broad low-opacity one
		local shadow = Instance.new("Frame")
		shadow.Name = "Shadow" .. i
		shadow.BackgroundColor3 = C.border
		shadow.BackgroundTransparency = spec[2]
		shadow.BorderSizePixel = 0
		shadow.Size = UDim2.new(1, 0, 1, 0)
		shadow.Position = UDim2.fromOffset(0, spec[1])
		Ui.corner(shadow, L.radius + 2)
		shadow.Parent = container
	end

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.BackgroundColor3 = C.body
	panel.BorderSizePixel = 0
	panel.Size = UDim2.fromScale(1, 1)
	panel.ClipsDescendants = false
	Ui.corner(panel)
	Ui.stroke(panel, L.border)
	Ui.studs(panel, Theme.Studs.body)
	panel.Parent = container

	local header = Ui.header(panel, o.header, o.title, o.icon, L.header, L.title)
	local divider = Instance.new("Frame") -- squares off the header's lower corners against the body
	divider.Name = "HeaderEdge"
	divider.BackgroundColor3 = C.border
	divider.BorderSizePixel = 0
	divider.Position = UDim2.fromOffset(0, L.header - 2)
	divider.Size = UDim2.new(1, 0, 0, 5)
	divider.ZIndex = 4
	divider.Parent = panel

	local close = Ui.closeButton(panel, function()
		Modal.close()
	end)
	close.AnchorPoint = Vector2.new(1, 0.5)
	close.Position = UDim2.new(1, -12, 0, L.header / 2)
	close.ZIndex = 5

	local footerH = if o.footer then L.footer else 0
	local top = L.header + 3 + L.pad
	local body =
		Ui.frame(panel, "Body", UDim2.new(1, -2 * L.pad, 1, -(top + footerH + L.pad)), UDim2.fromOffset(L.pad, top))
	local footer: Frame? = nil
	if o.footer then
		local f = Instance.new("Frame")
		f.Name = "Footer"
		f.BackgroundColor3 = C.footer
		f.BorderSizePixel = 0
		f.AnchorPoint = Vector2.new(0, 1)
		f.Position = UDim2.new(0, 0, 1, 0)
		f.Size = UDim2.new(1, 0, 0, footerH)
		Ui.corner(f)
		Ui.studs(f, Theme.Studs.body)
		f.Parent = panel
		local edge = Instance.new("Frame")
		edge.Name = "FooterEdge"
		edge.BackgroundColor3 = C.border
		edge.BorderSizePixel = 0
		edge.Size = UDim2.new(1, 0, 0, 4)
		edge.Parent = f
		footer = Ui.frame(f, "Content", UDim2.new(1, -2 * L.pad, 1, -8), UDim2.fromOffset(L.pad, 6))
	end

	local veil = Instance.new("Frame")
	veil.Name = "Veil"
	veil.BackgroundColor3 = C.card
	veil.BackgroundTransparency = 1
	veil.BorderSizePixel = 0
	veil.Size = UDim2.new(1, 10, 1, 20)
	veil.Position = UDim2.fromOffset(-5, -5)
	veil.ZIndex = 100
	Ui.corner(veil, L.radius + 2)
	veil.Parent = container

	return {
		name = name,
		container = container,
		panel = panel,
		header = header,
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

local function firstSelectable(node: Instance): GuiObject?
	for _, d in node:GetDescendants() do
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

-- Toasts ---------------------------------------------------------------------------------------------------

-- Toasts sit in their own lane at least 20 px below this HUD element (the "Eggs secured" bar).
function Modal.setToastAnchor(gui: GuiObject?)
	toastAnchor = gui
end

local function placeToasts()
	local y = topInset() + 16
	local anchor = toastAnchor
	if anchor and anchor.Parent and anchor.Visible then
		local rootY = if root:IsA("GuiObject") then root.AbsolutePosition.Y else 0
		local anchorTop = anchor.AbsolutePosition.Y - rootY
		local insetFix = if root:IsA("ScreenGui") and root.IgnoreGuiInset then GuiService:GetGuiInset().Y else 0
		y = math.max(y, anchorTop + insetFix + anchor.AbsoluteSize.Y + 20)
	end
	toastLayer.Position = UDim2.new(0.5, 0, 0, y)
end

-- Slide +12 -> 0 and fade in (180 ms), dwell 2.2 s, exit 140 ms; at most 3 at once.
local toasts: { Frame } = {}
local toastCount = 0
function Modal.toast(text: string, kind: ("info" | "good" | "error")?)
	placeToasts()
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
	t.BackgroundColor3 = C.card
	toastCount += 1
	t.LayoutOrder = toastCount
	Ui.corner(t)
	local stroke = Ui.stroke(t, 4)
	stroke.Color = if kind == "error"
		then Theme.Buttons.red[2]
		elseif kind == "good" then Theme.Buttons.lime[2]
		else C.border
	Ui.padding(t, 20, 10)
	local label = Ui.text(t, text, 26, { autoX = true, stroke = 3 })
	t.Parent = toastLayer
	table.insert(toasts, t)
	local inner = Motion.scaleOf(t)
	if not Motion.reduced() then
		inner.Scale = 0.94
		Motion.tween(inner, 0.18, { Scale = 1 })
	end
	label.TextTransparency = 1
	t.BackgroundTransparency = 1
	Motion.tween(label, 0.18, { TextTransparency = 0 })
	Motion.tween(t, 0.18, { BackgroundTransparency = 0.04 })
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

-- Init -----------------------------------------------------------------------------------------------------

-- `parent`: PlayerGui (game) or a preview frame (tools/preview). `opts.viewport` pins the layout size.
function Modal.init(parent: Instance, opts: { viewport: Vector2?, touch: boolean? }?)
	if opts and opts.viewport then
		preview = { size = opts.viewport, touch = opts.touch == true }
	end
	if parent:IsA("GuiObject") then
		local f = Ui.frame(parent, "Modals")
		f.ZIndex = 50
		root = f
	else
		local gui = Instance.new("ScreenGui")
		gui.Name = "Modals"
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.DisplayOrder = 10
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.Parent = parent
		root = gui
	end

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
	scrim.Parent = root

	host = Instance.new("Frame")
	host.Name = "Host"
	host.BackgroundTransparency = 1
	host.AnchorPoint = Vector2.new(0.5, 0.5)
	host.Size = UDim2.fromOffset(0, 0)
	hostScale = Instance.new("UIScale")
	hostScale.Parent = host
	host.Parent = root

	fxLayer = Ui.frame(root, "Transient")
	fxLayer.ZIndex = 50

	toastLayer = Ui.frame(root, "Toasts", UDim2.fromOffset(0, 0))
	toastLayer.AnchorPoint = Vector2.new(0.5, 0)
	toastLayer.AutomaticSize = Enum.AutomaticSize.XY
	toastLayer.ZIndex = 60
	Ui.list(toastLayer, 10, false, Enum.HorizontalAlignment.Center)
	toastScale = Instance.new("UIScale")
	toastScale.Parent = toastLayer

	-- Studio: say loudly that supplied art is shown from local copies until its ids are uploaded.
	local missing = #AssetIds.missing()
	if RunService:IsStudio() and missing > 0 then
		local banner = Instance.new("Frame")
		banner.Name = "LocalArtBanner"
		banner.AnchorPoint = Vector2.new(1, 1)
		banner.Position = UDim2.new(1, -8, 1, -8)
		banner.AutomaticSize = Enum.AutomaticSize.XY
		banner.BackgroundColor3 = Color3.fromHex("2A0A24")
		banner.BackgroundTransparency = 0.15
		banner.ZIndex = 70
		Ui.corner(banner, 6)
		Ui.stroke(banner, 2, C.missing)
		Ui.padding(banner, 10, 4)
		Ui.text(
			banner,
			`LOCAL ART (Studio only): {missing} images not uploaded`,
			17,
			{ autoX = true, color = C.missing }
		).ZIndex =
			71
		banner.Parent = root
	end

	relayout()
	placeToasts()
	local cam = workspace.CurrentCamera
	if cam and not preview then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(relayout)
	end
end

return Modal
