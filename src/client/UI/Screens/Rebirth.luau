--!strict
-- Rebirth (UI handoff SCREEN-SPEC "Rebirth"). Shows the rebirth count, the requirement (Kick Power at the
-- current cap, Economy.maxKickPower), what the next rebirth gives (pet income multiplier, higher power cap)
-- and the server's real reset / keep lists (Economy.Rebirth.resets / keeps). Rebirthing is two steps: the
-- REBIRTH button opens a confirmation listing exactly what you lose (current -> after values); Cancel is as
-- big as Confirm. Pending blocks repeats; success is detected from DataChanged (rebirths + 1) and plays
-- one ring + sparks. If the rules aren't fully known the screen shows Unavailable instead of a button.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economy = require(Shared.Config.Economy)

local System = script.Parent.Parent.System
local Data = require(System.Data)
local Modal = require(System.Modal)
local Motion = require(System.Motion)
local Theme = require(System.Theme)
local Ui = require(System.Ui)

local C = Theme.Colors
local Rebirth = {}

local function remote(name: string): RemoteEvent
	local Remotes = require(Shared:WaitForChild("Remotes")) :: any
	return Remotes.get(name)
end

local function mult(x: number): string
	return "x" .. (if x % 1 == 0 then tostring(x) else string.format("%.1f", x))
end

-- Current -> after value for each reset key (UpgradeService applies these).
local RESET_TO: { [string]: number } = {
	money = Economy.StartingMoney,
	kickPower = Economy.KickPower.base,
	runSpeed = Economy.RunSpeed.base,
}
local LABEL: { [string]: string } = { money = "Cash", kickPower = "Kick Power", runSpeed = "Run Speed" }

local function lossLines(): { string }
	local lines = {}
	for _, key in Economy.Rebirth.resets do
		local now = Data.state[key]
		local after = RESET_TO[key]
		local label = LABEL[key] or key
		if typeof(now) == "number" and after then
			local fmt: (number) -> string = if key == "money" then Ui.money else Ui.number
			table.insert(lines, `{label}: {fmt(now)} -> {fmt(after)}`)
		else
			table.insert(lines, label)
		end
	end
	return lines
end

local function listBox(parent: Instance, name: string, title: string, key: Ui.Gradient): (Frame, Frame)
	local box = Ui.panel(parent, name, C.panelDeep)
	local head = Instance.new("Frame")
	head.Name = "Head"
	head.Size = UDim2.new(1, -16, 0, 44)
	head.Position = UDim2.fromOffset(8, 8)
	Ui.corner(head)
	Ui.gradient(head, key)
	Ui.stroke(head, 3)
	head.Parent = box
	local t = Ui.text(head, title, 24, { align = Enum.TextXAlignment.Center, name = "Title" })
	t.Size = UDim2.fromScale(1, 1)
	local items = Ui.frame(box, "Items", UDim2.new(1, -32, 1, -68), UDim2.fromOffset(16, 60))
	Ui.list(items, 6)
	return box, items
end

local function fill(items: Frame, lines: { string }, color: Color3)
	for _, child in items:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	for i, line in lines do
		Ui.text(items, "• " .. line, 22, { color = color, name = "Line" .. i, wrap = true }).LayoutOrder = i
	end
end

function Rebirth.define()
	Modal.define(
		"Rebirth",
		{ title = "Rebirth", gradient = "violet", icon = "icon/rebirth", footer = true },
		function(shell: Modal.Shell): Modal.Screen
			local body, footer = shell.body, shell.footer :: Frame
			local pending = false
			local errorText = ""

			-- Left: emblem + count + requirement. Right: next benefits, resets and keeps.
			local left = Ui.panel(body, "Status", C.panelDeep)
			left.Size = UDim2.new(0.42, -10, 1, 0)
			local emblem = Ui.frame(left, "Emblem", UDim2.fromOffset(200, 200), UDim2.new(0.5, 0, 0, 20))
			emblem.AnchorPoint = Vector2.new(0.5, 0)
			Ui.glow(emblem, Theme.Gradients.violet[1], true)
			local icon = Ui.icon(emblem, "icon/rebirth", 150, "R")
			icon.Size = UDim2.fromScale(0.75, 0.75)
			icon.AnchorPoint = Vector2.new(0.5, 0.5)
			icon.Position = UDim2.fromScale(0.5, 0.5)
			icon.ZIndex = 2
			Motion.float(icon)
			local count = Ui.text(left, "", 40, { align = Enum.TextXAlignment.Center, stroke = 4, name = "Count" })
			count.Position = UDim2.new(0, 16, 0, 230)
			count.Size = UDim2.new(1, -32, 0, 48)
			local reqTitle = Ui.text(
				left,
				"Requirement: max Kick Power",
				22,
				{ color = C.muted, align = Enum.TextXAlignment.Center, name = "ReqTitle" }
			)
			reqTitle.Position = UDim2.new(0, 16, 0, 290)
			reqTitle.Size = UDim2.new(1, -32, 0, 30)
			local barHolder = Ui.frame(left, "Bar", UDim2.new(1, -40, 0, 36), UDim2.new(0, 20, 0, 328))
			local bar = Ui.progress(barHolder, "violet", 36)
			local status =
				Ui.text(left, "", 20, { align = Enum.TextXAlignment.Center, wrap = true, name = "StatusNote" })
			status.Position = UDim2.new(0, 20, 0, 378)
			status.Size = UDim2.new(1, -40, 0, 0)

			local right = Ui.frame(body, "Lists", UDim2.new(0.58, -10, 1, 0), UDim2.new(0.42, 10, 0, 0))
			local next, nextItems = listBox(right, "Next", "Next rebirth", "violet")
			next.Size = UDim2.new(1, 0, 0.34, -8)
			local resets, resetItems = listBox(right, "Resets", "Resets", "red")
			resets.Position = UDim2.new(0, 0, 0.34, 8)
			resets.Size = UDim2.new(0.5, -8, 0.66, -8)
			local keeps, keepItems = listBox(right, "Keeps", "You keep", "lime")
			keeps.Position = UDim2.new(0.5, 8, 0.34, 8)
			keeps.Size = UDim2.new(0.5, -8, 0.66, -8)

			-- Footer: main button / unavailable pill + error line.
			local errorLabel = Ui.text(footer, "", 20, { color = Theme.Gradients.red[1], name = "Error" })
			errorLabel.Size = UDim2.new(0.5, 0, 1, 0)
			local confirm: Frame
			local go = Ui.button(footer, {
				text = "REBIRTH",
				gradient = "violet",
				size = UDim2.fromOffset(340, 68),
				textSize = 30,
				icon = "icon/rebirth",
				name = "Rebirth",
				onClick = function()
					if not pending then
						confirm.Visible = true
					end
				end,
			})
			go.gui.AnchorPoint = Vector2.new(1, 0.5)
			go.gui.Position = UDim2.new(1, 0, 0.5, 0)
			local unavailable = Ui.pill(footer, "UNAVAILABLE", "disabled", UDim2.fromOffset(340, 68), 28)
			unavailable.AnchorPoint = Vector2.new(1, 0.5)
			unavailable.Position = UDim2.new(1, 0, 0.5, 0)

			-- Step 2: confirmation.
			confirm = Ui.frame(shell.panel, "Confirm")
			confirm.ZIndex = 40
			confirm.Visible = false
			local dim = Instance.new("TextButton")
			dim.Name = "Dim"
			dim.Text = ""
			dim.AutoButtonColor = false
			dim.Selectable = false
			dim.BackgroundColor3 = C.scrim
			dim.BackgroundTransparency = 0.4
			dim.Size = UDim2.fromScale(1, 1)
			Ui.corner(dim, 16)
			dim.Parent = confirm
			local box = Ui.panel(confirm, "Box", C.panel)
			box.AnchorPoint = Vector2.new(0.5, 0.5)
			box.Position = UDim2.fromScale(0.5, 0.5)
			box.Size = UDim2.fromOffset(640, 420)
			local q = Ui.text(box, "Rebirth now?", 34, { align = Enum.TextXAlignment.Center, name = "Question" })
			q.Position = UDim2.fromOffset(20, 24)
			q.Size = UDim2.new(1, -40, 0, 44)
			local loseTitle = Ui.text(
				box,
				"You will lose:",
				22,
				{ color = C.muted, align = Enum.TextXAlignment.Center, name = "LoseTitle" }
			)
			loseTitle.Position = UDim2.fromOffset(20, 80)
			loseTitle.Size = UDim2.new(1, -40, 0, 30)
			local loseItems = Ui.frame(box, "Lose", UDim2.new(1, -80, 0, 170), UDim2.fromOffset(40, 116))
			Ui.list(loseItems, 6, false, Enum.HorizontalAlignment.Center)
			local row = Ui.frame(box, "Buttons", UDim2.new(1, -60, 0, 68), UDim2.new(0, 30, 1, -92))
			Ui.list(row, 20, true, Enum.HorizontalAlignment.Center)

			local refresh: () -> ()
			local cancel = Ui.button(row, {
				text = "CANCEL",
				gradient = "grey",
				size = UDim2.fromOffset(260, 68),
				textSize = 28,
				name = "Cancel",
				onClick = function()
					if not pending then
						confirm.Visible = false
					end
				end,
			})
			local yes: Ui.Button
			yes = Ui.button(row, {
				text = "REBIRTH",
				gradient = "violet",
				size = UDim2.fromOffset(260, 68),
				textSize = 28,
				name = "ConfirmRebirth",
				onClick = function()
					local info = Data.rebirth()
					if pending or not info.available or not info.ready or info.inChase then
						return
					end
					pending = true
					yes.setPending(true, "REBIRTHING...")
					cancel.setEnabled(false)
					go.setPending(true, "REBIRTHING...")
					local before = info.count
					remote("Rebirth"):FireServer()
					Data.expect(
						function()
							return (Data.state.rebirths or 0) > before
						end,
						6,
						function(ok: boolean)
							pending = false
							yes.setPending(false)
							cancel.setEnabled(true)
							go.setPending(false)
							confirm.Visible = false
							if ok then
								errorText = ""
								Modal.toast(
									`Rebirth {Data.state.rebirths}! Pet income {mult(Data.rebirth().multiplier)}`,
									"good"
								)
								local at = icon.AbsolutePosition + icon.AbsoluteSize / 2
								Motion.ring(Modal.layer(), at, Theme.Gradients.violet[1])
							else
								errorText = "Rebirth failed. Nothing changed."
							end
							refresh()
						end
					)
				end,
			})

			refresh = function()
				local info = Data.rebirth()
				count.Text = `Rebirths: {info.count}`
				bar.set(info.power / math.max(1, info.required), `{Ui.number(info.power)} / {Ui.number(info.required)}`)
				fill(nextItems, {
					`Pet income {mult(info.multiplier)} -> {mult(info.nextMultiplier)}`,
					`Kick Power cap {Ui.number(info.required)} -> {Ui.number(info.nextCap)}`,
				}, C.text)
				fill(resetItems, info.resets, Theme.Gradients.red[1])
				fill(keepItems, info.keeps, Theme.Gradients.lime[1])
				for _, child in loseItems:GetChildren() do
					if child:IsA("TextLabel") then
						child:Destroy()
					end
				end
				for i, line in lossLines() do
					Ui.text(
						loseItems,
						line,
						24,
						{ color = Theme.Gradients.red[1], align = Enum.TextXAlignment.Center, name = "L" .. i }
					).LayoutOrder =
						i
				end
				go.gui.Visible = info.available
				unavailable.Visible = not info.available
				go.setEnabled(info.ready and not info.inChase)
				if not info.available then
					status.Text = "Rebirth isn't available right now."
				elseif info.inChase then
					status.Text = "Finish your chase first."
				elseif info.ready then
					status.Text = "Ready to rebirth!"
				else
					status.Text = `Train {Ui.number(info.required - info.power)} more Kick Power on your boxing sack.`
				end
				status.TextColor3 = if info.ready and not info.inChase then Theme.Gradients.lime[1] else C.muted
				errorLabel.Text = errorText
			end

			return {
				open = function()
					errorText = ""
					refresh()
				end,
				close = function()
					if not pending then
						confirm.Visible = false
					end
				end,
				update = refresh,
				resize = function(_size: Vector2, compact: boolean)
					emblem.Size = if compact then UDim2.fromOffset(120, 120) else UDim2.fromOffset(200, 200)
					local y = if compact then 140 else 230
					count.Position = UDim2.new(0, 16, 0, y)
					reqTitle.Position = UDim2.new(0, 16, 0, y + 58)
					barHolder.Position = UDim2.new(0, 20, 0, y + 96)
					status.Position = UDim2.new(0, 20, 0, y + 146)
				end,
			}
		end
	)
end

return Rebirth
