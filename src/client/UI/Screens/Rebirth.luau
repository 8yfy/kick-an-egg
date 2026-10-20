--!strict
-- Rebirth (UI handoff v2 01-Mockups/07-Rebirth.png). Purple header; a "REBIRTH n -> n+1" pill over the large
-- supplied rebirth hero (nav-rebirth.png, rays + glow, gentle float); REQUIREMENTS (the Kick Power this rebirth
-- needs, Economy.rebirthPower) and NEXT BONUS (pet income multiplier, Economy.Rebirth.multiplierPerRebirth)
-- panels; a status card on the right; the "Review what resets before rebirthing" box with the server's real
-- reset / keep lists (Economy.Rebirth.resets / keeps); one main action bar: REBIRTH when ready, otherwise
-- MORE POWER NEEDED / FINISH YOUR CHASE FIRST. Rebirthing is two steps: the confirmation lists exactly what
-- you lose (current -> after values) with Cancel as big as Confirm. Pending blocks repeats; success is
-- detected from DataChanged (rebirths + 1) and plays one ring + sparks. If the rules aren't fully known the
-- action shows UNAVAILABLE.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economy = require(Shared.Config.Economy)

local System = script.Parent.Parent.System
local Audio = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Audio")) :: any
local Data = require(System.Data)
local Modal = require(System.Modal)
local Motion = require(System.Motion)
local Theme = require(System.Theme)
local Ui = require(System.Ui)

local C = Theme.Colors
local Rebirth = {}

local PURPLE_EDGE = Color3.fromHex("B04BFF")
local GOLD_EDGE = Color3.fromHex("FFC21A")

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
			table.insert(lines, `{label}: {fmt(now)} → {fmt(after)}`)
		else
			table.insert(lines, label)
		end
	end
	return lines
end

-- A titled panel: coloured title bar + dark body (REQUIREMENTS / NEXT BONUS / RESETS / KEEPS).
local function panel(parent: Instance, name: string, title: string, bar: Theme.Pair, edge: Color3): (Frame, Frame)
	local p = Instance.new("Frame")
	p.Name = name
	p.BackgroundColor3 = C.card
	p.BorderSizePixel = 0
	Ui.corner(p)
	Ui.stroke(p, 4, edge)
	Ui.studs(p, Theme.Studs.body)
	p.Parent = parent
	local head = Instance.new("Frame")
	head.Name = "Title"
	head.Size = UDim2.new(1, -8, 0, 44)
	head.Position = UDim2.fromOffset(4, 4)
	head.BorderSizePixel = 0
	Ui.corner(head, 5)
	Ui.fill(head, bar)
	Ui.studs(head, Theme.Studs.header, 20)
	head.Parent = p
	local t = Ui.text(head, string.upper(title), 28, { align = Enum.TextXAlignment.Center, stroke = 3, name = "Label" })
	t.Size = UDim2.fromScale(1, 1)
	local content = Ui.frame(p, "Content", UDim2.new(1, -24, 1, -60), UDim2.fromOffset(12, 54))
	return p, content
end

local function fillList(items: Frame, lines: { string }, marker: string)
	for _, child in items:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for i, line in lines do
		local row = Ui.frame(items, "Line" .. i, UDim2.new(1, 0, 0, 32))
		row.LayoutOrder = i
		local m = Ui.frame(row, "Marker", UDim2.fromOffset(30, 30), UDim2.fromOffset(0, 2))
		if marker == "check" then
			Ui.art(m, "icon_check")
		else
			m.BackgroundColor3 = Theme.Buttons.red[2]
			m.BackgroundTransparency = 0
			Ui.corner(m, 15)
			Ui.stroke(m, 3)
			local dash = Instance.new("Frame")
			dash.BackgroundColor3 = C.text
			dash.BorderSizePixel = 0
			dash.AnchorPoint = Vector2.new(0.5, 0.5)
			dash.Position = UDim2.fromScale(0.5, 0.5)
			dash.Size = UDim2.new(0.55, 0, 0, 5)
			dash.Parent = m
		end
		local t = Ui.text(row, line, 22, { stroke = 2, name = "Text" })
		t.Position = UDim2.fromOffset(42, 0)
		t.Size = UDim2.new(1, -42, 1, 0)
	end
end

function Rebirth.define()
	Modal.define(
		"Rebirth",
		{ title = "Rebirth", header = Theme.Headers.rebirth, icon = "premium_icons_nav_rebirth" },
		function(shell: Modal.Shell): Modal.Screen
			local body = shell.body
			local pending = false
			local errorText = ""

			-- Left: pill, hero, requirement + bonus panels.
			local left = Ui.frame(body, "Main", UDim2.new(0.7, -10, 0, 480))
			local pill = Instance.new("Frame")
			pill.Name = "Step"
			pill.AnchorPoint = Vector2.new(0.5, 0)
			pill.Position = UDim2.new(0.5, 0, 0, 0)
			pill.Size = UDim2.fromOffset(420, 58)
			pill.BackgroundColor3 = C.card
			Ui.corner(pill)
			Ui.stroke(pill, 4, PURPLE_EDGE)
			pill.Parent = left
			local pillText = Ui.text(pill, "", 40, { align = Enum.TextXAlignment.Center, stroke = 4, name = "Text" })
			pillText.Size = UDim2.fromScale(1, 1)
			pillText.RichText = true
			local heroBox = Ui.frame(left, "Hero", UDim2.new(1, 0, 0, 250), UDim2.fromOffset(0, 54))
			local glow = Ui.glow(heroBox, Color3.fromHex("D27BFF"), true, 1.0)
			local hero = Ui.frame(heroBox, "Art", UDim2.fromScale(0.95, 0.95), UDim2.fromScale(0.5, 0.5))
			hero.SizeConstraint = Enum.SizeConstraint.RelativeYY
			hero.AnchorPoint = Vector2.new(0.5, 0.5)
			hero.ZIndex = 2
			Ui.art(hero, "premium_icons_nav_rebirth").ZIndex = 2
			Motion.float(hero, glow)

			local req, reqContent = panel(left, "Requirements", "Requirements", Theme.Headers.rebirth, PURPLE_EDGE)
			req.Position = UDim2.fromOffset(0, 312)
			req.Size = UDim2.new(0.5, -8, 0, 166)
			local reqIcon = Ui.frame(reqContent, "Icon", UDim2.fromOffset(84, 84), UDim2.fromOffset(0, 6))
			Ui.art(reqIcon, "premium_icons_power_sneaker")
			local reqLabel = Ui.text(reqContent, "Kick power", 26, { stroke = 3, name = "Label" })
			reqLabel.Position = UDim2.fromOffset(96, 0)
			reqLabel.Size = UDim2.new(1, -96, 0, 34)
			local barHolder = Ui.frame(reqContent, "Bar", UDim2.new(1, -96, 0, 42), UDim2.fromOffset(96, 42))
			local bar = Ui.progress(barHolder, Theme.Buttons.lime, 42, 26)

			local bonus, bonusContent = panel(left, "NextBonus", "Next Bonus", Theme.Headers.rebirth, PURPLE_EDGE)
			bonus.Position = UDim2.new(0.5, 8, 0, 312)
			bonus.Size = UDim2.new(0.5, -8, 0, 166)
			local bonusLabel = Ui.text(
				bonusContent,
				"Pet income multiplier",
				24,
				{ align = Enum.TextXAlignment.Center, stroke = 3, name = "Label" }
			)
			bonusLabel.Size = UDim2.new(1, 0, 0, 32)
			local bonusValue =
				Ui.text(bonusContent, "", 48, { align = Enum.TextXAlignment.Center, stroke = 5, name = "Value" })
			bonusValue.RichText = true
			bonusValue.Position = UDim2.fromOffset(0, 36)
			bonusValue.Size = UDim2.new(1, 0, 0, 56)

			-- Right: status card.
			local card = Instance.new("Frame")
			card.Name = "Status"
			card.AnchorPoint = Vector2.new(1, 0)
			card.Position = UDim2.fromScale(1, 0)
			card.Size = UDim2.new(0.3, -10, 0, 480)
			card.BorderSizePixel = 0
			Ui.corner(card)
			Ui.fill(card, { Color3.fromHex("3A2A0A"), Color3.fromHex("1E1606") })
			Ui.stroke(card, 5, GOLD_EDGE)
			Ui.studs(card, Theme.Studs.body)
			card.Parent = body
			local cardHead = Instance.new("Frame")
			cardHead.Name = "Head"
			cardHead.Size = UDim2.new(1, -8, 0, 96)
			cardHead.Position = UDim2.fromOffset(4, 4)
			Ui.corner(cardHead, 5)
			Ui.fill(cardHead, Theme.Buttons.gold)
			cardHead.Parent = card
			local cardTitle = Ui.text(
				cardHead,
				"",
				34,
				{ align = Enum.TextXAlignment.Center, stroke = 4, wrap = true, name = "Title" }
			)
			cardTitle.AnchorPoint = Vector2.new(0, 0.5)
			cardTitle.Position = UDim2.fromScale(0, 0.5)
			local miniBox = Ui.frame(card, "Mini", UDim2.new(1, -20, 0, 220), UDim2.fromOffset(10, 108))
			Ui.glow(miniBox, Color3.fromHex("FFD86A"), true, 0.9)
			local mini = Ui.frame(miniBox, "Art", UDim2.fromScale(0.9, 0.9), UDim2.fromScale(0.5, 0.5))
			mini.SizeConstraint = Enum.SizeConstraint.RelativeYY
			mini.AnchorPoint = Vector2.new(0.5, 0.5)
			mini.ZIndex = 2
			Ui.art(mini, "premium_icons_nav_rebirth").ZIndex = 2
			local cardStep = Ui.text(card, "", 34, { align = Enum.TextXAlignment.Center, stroke = 4, name = "Step" })
			cardStep.RichText = true
			cardStep.Position = UDim2.fromOffset(10, 334)
			cardStep.Size = UDim2.new(1, -20, 0, 42)
			local cardNote =
				Ui.text(card, "", 22, { align = Enum.TextXAlignment.Center, wrap = true, stroke = 2, name = "Note" })
			cardNote.Position = UDim2.fromOffset(14, 384)
			cardNote.Size = UDim2.new(1, -28, 0, 0)

			-- Review box: resets / keeps.
			local review = Instance.new("Frame")
			review.Name = "Review"
			review.Position = UDim2.fromOffset(0, 536)
			review.Size = UDim2.new(1, 0, 0, 228)
			review.BorderSizePixel = 0
			Ui.corner(review)
			Ui.fill(review, { Color3.fromHex("2E2410"), Color3.fromHex("1D170A") })
			Ui.stroke(review, 5, GOLD_EDGE)
			review.Parent = body
			local warnIcon =
				Ui.text(review, "⚠", 34, { autoX = true, stroke = 3, color = Theme.Buttons.gold[1], name = "Warn" })
			warnIcon.Position = UDim2.fromOffset(16, 4)
			local reviewTitle =
				Ui.text(review, "Review what resets before rebirthing", 28, { stroke = 3, name = "Title" })
			reviewTitle.Position = UDim2.fromOffset(60, 6)
			reviewTitle.Size = UDim2.new(1, -80, 0, 36)
			local resets, resetItems = panel(review, "Resets", "Resets", Theme.Buttons.red, Theme.Buttons.red[2])
			resets.Position = UDim2.fromOffset(12, 48)
			resets.Size = UDim2.new(0.5, -18, 1, -60)
			local resetGrid = Instance.new("UIGridLayout")
			resetGrid.CellSize = UDim2.new(0.5, -6, 0, 32)
			resetGrid.CellPadding = UDim2.fromOffset(8, 4)
			resetGrid.SortOrder = Enum.SortOrder.LayoutOrder
			resetGrid.Parent = resetItems
			resetItems.ClipsDescendants = true
			local keeps, keepItems = panel(review, "Keeps", "Keeps", Theme.Buttons.lime, Theme.Buttons.lime[2])
			keeps.Position = UDim2.new(0.5, 6, 0, 48)
			keeps.Size = UDim2.new(0.5, -18, 1, -60)
			local keepGrid = Instance.new("UIGridLayout")
			keepGrid.CellSize = UDim2.new(0.5, -6, 0, 32)
			keepGrid.CellPadding = UDim2.fromOffset(8, 4)
			keepGrid.SortOrder = Enum.SortOrder.LayoutOrder
			keepGrid.Parent = keepItems
			keepItems.ClipsDescendants = true

			-- Main action bar.
			local confirm: Frame
			local action = Ui.button(body, {
				text = "REBIRTH",
				style = "lime",
				size = UDim2.new(0.62, 0, 0, 80),
				textSize = 46,
				name = "Rebirth",
				onClick = function()
					if not pending then
						confirm.Visible = true
						Motion.popIn(confirm:FindFirstChild("Box") :: GuiObject)
					end
				end,
			})
			action.gui.AnchorPoint = Vector2.new(0.5, 1)
			action.gui.Position = UDim2.new(0.5, 0, 1, 0)
			local actionLock = Ui.frame(action.gui:FindFirstChild("Content") :: Frame, "Lock", UDim2.fromOffset(50, 50))
			actionLock.LayoutOrder = 0
			Ui.art(actionLock, "icon_lock").ZIndex = 2
			local errorLabel = Ui.text(
				body,
				"",
				20,
				{ color = C.danger, align = Enum.TextXAlignment.Center, stroke = 2, name = "Error" }
			)
			errorLabel.AnchorPoint = Vector2.new(0.5, 1)
			errorLabel.Position = UDim2.new(0.5, 0, 1, -84)
			errorLabel.Size = UDim2.new(0.62, 0, 0, 26)

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
			dim.BackgroundTransparency = 0.45
			dim.Size = UDim2.fromScale(1, 1)
			Ui.corner(dim)
			dim.Parent = confirm
			local box = Ui.surface(confirm, "Box", C.body, Theme.Studs.body, 5)
			box.AnchorPoint = Vector2.new(0.5, 0.5)
			box.Position = UDim2.fromScale(0.5, 0.5)
			box.Size = UDim2.fromOffset(660, 470)
			Ui.header(box, Theme.Headers.rebirth, "Rebirth now?", "premium_icons_nav_rebirth", 76, 42)
			local loseTitle = Ui.text(
				box,
				"You will lose:",
				26,
				{ align = Enum.TextXAlignment.Center, color = C.muted, stroke = 3, name = "LoseTitle" }
			)
			loseTitle.Position = UDim2.fromOffset(20, 92)
			loseTitle.Size = UDim2.new(1, -40, 0, 34)
			local loseItems = Ui.frame(box, "Lose", UDim2.new(1, -80, 0, 190), UDim2.fromOffset(40, 132))
			Ui.list(loseItems, 6, false, Enum.HorizontalAlignment.Center)
			local row = Ui.frame(box, "Buttons", UDim2.new(1, -60, 0, 72), UDim2.new(0, 30, 1, -92))
			local refresh: () -> ()
			local cancel = Ui.button(row, {
				text = "CANCEL",
				style = "grey",
				size = UDim2.new(0.5, -10, 1, 0),
				textSize = 34,
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
				style = "lime",
				size = UDim2.new(0.5, -10, 1, 0),
				textSize = 34,
				name = "ConfirmRebirth",
				onClick = function()
					local info = Data.rebirth()
					if pending or not info.available or not info.ready or info.inChase then
						return
					end
					pending = true
					yes.setPending(true, "REBIRTHING...")
					cancel.setEnabled(false)
					action.setPending(true, "REBIRTHING...")
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
							action.setPending(false)
							confirm.Visible = false
							if ok then
								errorText = ""
								Audio.play("Rebirth")
								Modal.toast(
									`Rebirth {Data.state.rebirths}! Pet income {mult(Data.rebirth().multiplier)}`,
									"good"
								)
								Motion.ring(
									Modal.layer(),
									hero.AbsolutePosition + hero.AbsoluteSize / 2,
									Color3.fromHex("D27BFF")
								)
							else
								errorText = "Rebirth failed. Nothing changed."
							end
							refresh()
						end
					)
				end,
			})
			yes.gui.Position = UDim2.new(0.5, 10, 0, 0)

			refresh = function()
				local info = Data.rebirth()
				local step =
					`REBIRTH <font color="#FFD84A">{info.count}</font> → <font color="#FFD84A">{info.count + 1}</font>`
				pillText.Text = step
				cardStep.Text =
					`Rebirth <font color="#FFD84A">{info.count}</font> → <font color="#FFD84A">{info.count + 1}</font>`
				bar.set(info.power / math.max(1, info.required), `{Ui.number(info.power)} / {Ui.number(info.required)}`)
				bonusValue.Text = `{mult(info.multiplier)} → <font color="#B8FF19">{mult(info.nextMultiplier)}</font>`
				fillList(resetItems, info.resets, "minus")
				fillList(keepItems, info.keeps, "check")
				for _, child in loseItems:GetChildren() do
					if child:IsA("TextLabel") then
						child:Destroy()
					end
				end
				for i, line in lossLines() do
					Ui.text(
						loseItems,
						line,
						28,
						{ color = C.danger, align = Enum.TextXAlignment.Center, stroke = 3, name = "L" .. i }
					).LayoutOrder =
						i
				end
				local ready = info.available and info.ready and not info.inChase
				action.setEnabled(ready)
				actionLock.Visible = not ready
				if not info.available then
					action.setText("UNAVAILABLE")
				elseif info.inChase then
					action.setText("FINISH YOUR CHASE FIRST")
				elseif not info.ready then
					action.setText("MORE POWER NEEDED")
				else
					action.setText("REBIRTH")
				end
				cardTitle.Text = if ready then "READY TO REBIRTH!" else "NOT READY YET"
				cardNote.Text = if ready
					then "Confirmation required."
					elseif info.inChase then "Finish your chase first."
					else `Train {Ui.number(math.max(0, info.required - info.power))} more Kick Power on your boxing sack. Next rebirth after this needs: {Ui.number(
						info.nextCap
					)}.`
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
					-- short screens: drop the big hero so requirements, review and action stay on screen
					heroBox.Visible = not compact
					req.Position = UDim2.fromOffset(0, if compact then 64 else 312)
					bonus.Position = UDim2.new(0.5, 8, 0, if compact then 64 else 312)
					req.Size = UDim2.new(0.5, -8, 0, if compact then 150 else 166)
					bonus.Size = UDim2.new(0.5, -8, 0, if compact then 150 else 166)
					local mainH = if compact then 216 else 480
					left.Size = UDim2.new(0.7, -10, 0, mainH)
					card.Size = UDim2.new(0.3, -10, 0, mainH)
					miniBox.Visible = not compact
					cardStep.Position = UDim2.fromOffset(10, if compact then 106 else 334)
					cardNote.Position = UDim2.fromOffset(14, if compact then 150 else 384)
					review.Position = UDim2.fromOffset(0, mainH + 16)
					review.Size = UDim2.new(1, 0, 0, if compact then 188 else 228)
					-- three items per row on short screens so every reset / keep stays visible
					local cell = if compact then UDim2.new(1 / 3, -6, 0, 32) else UDim2.new(0.5, -6, 0, 32)
					resetGrid.CellSize = cell
					keepGrid.CellSize = cell
				end,
			}
		end
	)
end

return Rebirth
