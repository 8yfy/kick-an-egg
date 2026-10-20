--!strict
-- Studio-only Kick Sack showroom: inspect the 20 sacks ONE AT A TIME (the Kick Sacks brief's "switch between all
-- 20 sacks and inspect their effects"). Everything is local to this client: a display spot in front of the
-- player, the sack and its effects, and a panel:
--   < PREV | "18 · GALAXY VOID" | NEXT >     (also , and . keys)
--   VFX ON/OFF · VIEW GAME/PACKAGE · ORBIT ON/OFF · CLOSE
-- VIEW GAME = exactly what players see (Builders/SackGeometry at game scale + the game effects); VIEW PACKAGE =
-- the Kick Sacks package model (SackModules/SackModel at 10 studs/m). Both use SackModules/SackVFX, so effects can
-- be switched off and on. The info line says where the geometry came from (original GLB import or the part
-- remodel while the import is pending) and how many parts matched their original GLB material.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local System = script.Parent.Parent.System
local Theme = require(System.Theme)
local Ui = require(System.Ui)

local C = Theme.Colors
local SackShowroom = {}

export type Showroom = {
	open: (anchor: CFrame) -> (),
	close: () -> (),
	show: (tier: number) -> (),
	step: (delta: number) -> (),
	isOpen: () -> boolean,
	gui: Frame,
}

local function modules(): (any, any, any, any, any)
	local Shared = ReplicatedStorage:WaitForChild("Shared")
	local SackModules = ReplicatedStorage:WaitForChild("SackModules")
	return require(Shared:WaitForChild("Builders"):WaitForChild("SackGeometry")) :: any,
		require(Shared:WaitForChild("Builders"):WaitForChild("Models"):WaitForChild("Sacks")) :: any,
		require(SackModules:WaitForChild("SackModel")) :: any,
		require(SackModules:WaitForChild("SackVFX")) :: any,
		require(Shared:WaitForChild("Config"):WaitForChild("Upgrades")) :: any
end

-- `parent`: the ScreenGui / frame for the panel. `camera`: orbit the camera (false in the preview harness).
function SackShowroom.new(parent: Instance, camera: boolean?): Showroom
	local panel = Ui.surface(parent, "SackShowroom", C.body, Theme.Studs.body, 5)
	panel.AnchorPoint = Vector2.new(0.5, 0)
	panel.Position = UDim2.new(0.5, 0, 0, 130) -- top centre, below the quest bar: the sack stays in view
	panel.Size = UDim2.fromOffset(820, 196)
	panel.Visible = false
	panel.ZIndex = 20
	local head = Ui.header(panel, Theme.Headers.training, "Sack Showroom", nil, 58, 30)
	head.gui.ZIndex = 21

	local tier, view, vfxOn, orbitOn = 1, "game", true, camera ~= false
	local anchor = CFrame.new()
	local folder: Folder? = nil
	local model: Model? = nil
	local handle: any = nil
	local orbitConn: RBXScriptConnection? = nil
	local orbitT = 0
	local opened = false

	local row = Ui.frame(panel, "Row", UDim2.new(1, -24, 0, 62), UDim2.fromOffset(12, 68))
	local title = Ui.text(row, "", 34, { align = Enum.TextXAlignment.Center, stroke = 4, name = "Title" })
	title.Position = UDim2.fromOffset(150, 6)
	title.Size = UDim2.new(1, -300, 0, 44)
	local info =
		Ui.text(panel, "", 18, { align = Enum.TextXAlignment.Center, color = C.muted, name = "Info", stroke = 2 })
	info.Position = UDim2.fromOffset(12, 124)
	info.Size = UDim2.new(1, -24, 0, 24)

	local show: (n: number) -> ()
	local prev = Ui.button(row, {
		text = "< PREV",
		style = "purple",
		size = UDim2.fromOffset(140, 56),
		textSize = 24,
		name = "Prev",
		onClick = function()
			show(tier - 1)
		end,
	})
	prev.gui.Position = UDim2.fromOffset(0, 0)
	local nxt = Ui.button(row, {
		text = "NEXT >",
		style = "purple",
		size = UDim2.fromOffset(140, 56),
		textSize = 24,
		name = "Next",
		onClick = function()
			show(tier + 1)
		end,
	})
	nxt.gui.AnchorPoint = Vector2.new(1, 0)
	nxt.gui.Position = UDim2.fromScale(1, 0)

	local bar = Ui.frame(panel, "Toggles", UDim2.new(1, -24, 0, 40), UDim2.new(0, 12, 1, -48))
	Ui.list(bar, 10, true, Enum.HorizontalAlignment.Center)
	local function toggle(name: string, order: number, onClick: () -> ()): Ui.Button
		local b = Ui.button(bar, {
			text = name,
			style = "dark",
			size = UDim2.fromOffset(176, 40),
			textSize = 18,
			name = name,
			onClick = onClick,
		})
		b.gui.LayoutOrder = order
		return b
	end
	local vfxButton: Ui.Button, viewButton: Ui.Button, orbitButton: Ui.Button
	local close: () -> ()

	local function paintToggles()
		vfxButton.setText(if vfxOn then "VFX ON" else "VFX OFF")
		vfxButton.setStyle(if vfxOn then "lime" else "dark")
		viewButton.setText(if view == "game" then "VIEW: GAME" else "VIEW: PACKAGE")
		orbitButton.setText(if orbitOn then "ORBIT ON" else "ORBIT OFF")
		orbitButton.setStyle(if orbitOn then "cyan" else "dark")
	end

	local function clear()
		if handle then
			handle:Destroy()
			handle = nil
		end
		if model then
			model:Destroy()
			model = nil
		end
	end

	show = function(n: number)
		tier = (n - 1) % 20 + 1
		clear()
		local SackGeometry, Sacks, SackModel, SackVFX, Upgrades = modules()
		if not folder then
			local f = Instance.new("Folder")
			f.Name = "SackShowroom"
			f.Parent = workspace
			folder = f
		end
		local m: Model
		local source: string
		if view == "game" then
			local built, src = SackGeometry.build(tier)
			m, source = built, src
			m:PivotTo(anchor * CFrame.new(0, Sacks.HANG, 0)) -- front (-Z) faces the viewer
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored = true
					d.CanCollide = false
					d.CanQuery = false
					d.CanTouch = false
				elseif d:IsA("WeldConstraint") or d:IsA("Motor6D") then
					d:Destroy()
				end
			end
			m.Parent = folder
		else
			m = SackModel.Build(tier, folder, anchor * CFrame.Angles(0, math.pi, 0) * CFrame.new(0, 0.6, 0), {
				RequireGLB = false,
				AutoScale = true,
				ForceOriginalColors = true,
				Anchored = true,
			})
			source = if m:GetAttribute("GeometrySource") == "GLB" then "GLB" else "Parts"
		end
		model = m
		m:SetAttribute("SackTier", tier)
		handle = SackVFX.Attach(m, tier, { Quality = 1, Enabled = vfxOn })
		local t = Upgrades.Sack.tiers[tier]
		title.Text = `{tier} · {string.upper(t.name)}`
		local matched = m:GetAttribute("MatchedGLBMaterials")
		info.Text = (
			if source == "GLB"
				then `Original GLB import{if typeof(matched) == "number"
					then ` · {matched} parts on original materials`
					else ""}`
				else "Part-built remodel · GLB import pending (tools/sacks/IMPORT.md)"
		) .. ` · effects: {t.fx} · {if view == "game" then "game scale" else "package 10 studs/m"}`
	end

	vfxButton = toggle("VFX", 1, function()
		vfxOn = not vfxOn
		if handle then
			handle:SetEnabled(vfxOn)
		end
		paintToggles()
	end)
	viewButton = toggle("VIEW", 2, function()
		view = if view == "game" then "package" else "game"
		paintToggles()
		show(tier)
	end)
	orbitButton = toggle("ORBIT", 3, function()
		orbitOn = not orbitOn
		paintToggles()
	end)
	toggle("CLOSE", 4, function()
		close()
	end).setStyle("red")
	paintToggles()

	local function orbit(dt: number)
		local cam = workspace.CurrentCamera
		if not (opened and orbitOn and cam and model) then
			if cam and cam.CameraType == Enum.CameraType.Scriptable and opened and not orbitOn then
				cam.CameraType = Enum.CameraType.Custom
			end
			return
		end
		orbitT += dt
		cam.CameraType = Enum.CameraType.Scriptable
		local center = (anchor * CFrame.new(0, 6, 0)).Position
		local a = orbitT * 0.35
		cam.CFrame = CFrame.lookAt(center + Vector3.new(math.sin(a) * 22, 4, math.cos(a) * 22), center)
	end

	close = function()
		opened = false
		panel.Visible = false
		clear()
		if folder then
			folder:Destroy()
			folder = nil
		end
		if orbitConn then
			orbitConn:Disconnect()
			orbitConn = nil
		end
		local cam = workspace.CurrentCamera
		if cam and camera ~= false then
			cam.CameraType = Enum.CameraType.Custom
		end
	end

	return {
		gui = panel,
		open = function(at: CFrame)
			anchor = at
			opened = true
			panel.Visible = true
			if camera ~= false and not orbitConn then
				orbitT = 0
				orbitConn = RunService.Heartbeat:Connect(orbit)
			end
			show(tier)
		end,
		close = close,
		show = show,
		step = function(delta: number)
			show(tier + delta)
		end,
		isOpen = function()
			return opened
		end,
	}
end

return SackShowroom
