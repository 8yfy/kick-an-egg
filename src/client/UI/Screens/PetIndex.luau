--!strict
-- Pet Index (UI handoff v2 01-Mockups/03-Pet-Index.png, 03-Specs/ZONE-CATALOG.md): one vertical list with all
-- 20 zones in the game's order (Config/Zones = the catalog order). Each zone section: the supplied zone
-- illustration as a tall strip with the zone name, its real pet roster (Config/Pets) as rarity-coloured
-- cards, and a found / total bar. Discovered = PlayerData.discovered (server, at hatch; owned pets count);
-- undiscovered pets are dark silhouettes named "???" (their rarity colour shows, as in the concept). Pets
-- have no supplied PNGs, so they stay live 3D previews of the game's own models.
-- Right: fixed selected-pet detail (big preview, name, rarity, zone, base income, status) and the zone's
-- completion panel. A zone reward (Economy.IndexRewards) shows only when configured: locked until complete,
-- CLAIM when eligible, pending during the request, claimed only after the server's DataChanged confirms
-- it. No reward is configured today, so the panel shows the zone's progress instead (never "$0" or "free").
-- Footer: DISCOVERED found / total. Short screens: the detail becomes a sheet that slides over the list.
-- Top of the list: COMPLETION REWARDS (Economy.IndexMilestones: 10 / 25 / 40 / 60 / all 79 discovered): total
-- found and %, a bar to the next milestone with its reward, and one chip per milestone (CLAIM when reached,
-- CLAIMED after the server confirms, LOCKED before). Claims go to Remotes.ClaimIndexMilestone (IndexService).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local System = script.Parent.Parent.System
local Audio = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Audio")) :: any
local AssetIds = require(System.AssetIds)
local Data = require(System.Data)
local Modal = require(System.Modal)
local Motion = require(System.Motion)
local Theme = require(System.Theme)
local Ui = require(System.Ui)

local C = Theme.Colors
local PetIndex = {}

local DETAIL_W = 370
local SECTION_H = 262
local STRIP_W = 200

local function remote(name: string): RemoteEvent
	local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes")) :: any
	return Remotes.get(name)
end

local function rarityFill(rarity: string): Theme.Pair
	if rarity == "Secret" then
		return { Color3.fromHex("FF6A8A"), Color3.fromHex("FFD34A"), Color3.fromHex("5BE07A"), Color3.fromHex("4FA8FF") }
	end
	return Theme.Rarity[rarity] or Theme.Rarity.Common
end

type PetCard = {
	pet: Data.IndexPet,
	zone: number,
	gui: TextButton,
	stroke: UIStroke,
	art: Frame,
	name: TextLabel,
	seen: boolean?,
}
type Section = { zone: Data.IndexZone, gui: Frame, bar: Ui.Progress, claim: Ui.Button?, cards: { PetCard } }

function PetIndex.define()
	Modal.define(
		"Index",
		{ title = "Pet Index", header = Theme.Headers.index, icon = "premium_icons_nav_index", footer = true },
		function(shell: Modal.Shell): Modal.Screen
			local body = shell.body
			local footer = shell.footer :: Frame
			local sections: { Section } = {}
			local cards: { [string]: PetCard } = {}
			local selected: string? = nil
			local claiming: { [number]: boolean } = {}
			local failed: { [number]: number } = {}
			local compact = false

			local list = Ui.scroll(body, "Zones")
			Ui.padding(list, 4)
			Ui.list(list, 14)

			-- Completion rewards (milestones) ------------------------------------------------------------------
			local mPanel = Instance.new("Frame")
			mPanel.Name = "Milestones"
			mPanel.LayoutOrder = -1
			mPanel.Size = UDim2.new(1, -8, 0, 196)
			mPanel.BackgroundColor3 = C.card
			Ui.corner(mPanel)
			Ui.stroke(mPanel, 4)
			mPanel.Parent = list
			local mTitle = Ui.text(mPanel, "COMPLETION REWARDS", 30, { stroke = 4, color = C.power, name = "Title" })
			mTitle.Position = UDim2.fromOffset(16, 8)
			mTitle.Size = UDim2.new(0.6, 0, 0, 36)
			local mTotal = Ui.text(mPanel, "", 26, { align = Enum.TextXAlignment.Right, stroke = 3, name = "Total" })
			mTotal.AnchorPoint = Vector2.new(1, 0)
			mTotal.Position = UDim2.new(1, -16, 0, 10)
			mTotal.Size = UDim2.new(0.4, -16, 0, 32)
			local mBarHolder = Ui.frame(mPanel, "Bar", UDim2.new(1, -32, 0, 34), UDim2.fromOffset(16, 50))
			local mBar = Ui.progress(mBarHolder, Theme.Buttons.cyan, 34, 22)
			local mNext = Ui.text(mPanel, "", 20, { stroke = 3, color = C.muted, name = "Next" })
			mNext.Position = UDim2.fromOffset(16, 88)
			mNext.Size = UDim2.new(1, -32, 0, 24)
			local chips = Ui.frame(mPanel, "Chips", UDim2.new(1, -32, 0, 70), UDim2.fromOffset(16, 118))
			local chipList = Ui.list(chips, 10, true)
			chipList.VerticalAlignment = Enum.VerticalAlignment.Center
			type Chip = { gui: Frame, label: TextLabel, button: Ui.Button }
			local chipUi: { [number]: Chip } = {}
			local milestonePending: { [number]: boolean } = {}
			local paintMilestones: () -> ()
			local function claimMilestone(count: number)
				if milestonePending[count] then
					return
				end
				milestonePending[count] = true
				paintMilestones()
				remote("ClaimIndexMilestone"):FireServer(count)
				Data.expect(
					function()
						local claimed = Data.state.indexMilestones
						return typeof(claimed) == "table" and claimed[tostring(count)] == true
					end,
					5,
					function(ok: boolean)
						milestonePending[count] = nil
						if ok then
							local _, all = Data.milestones() -- every pet discovered: the big one
							Audio.play(if count >= all then "GrandReward" else "MilestoneClaim")
							Modal.toast(`Index reward claimed: {count} pets!`, "good")
						else
							Modal.toast("Couldn't claim that reward. Try again.", "error")
						end
						paintMilestones()
					end
				)
			end
			paintMilestones = function()
				local found, all, rows = Data.milestones()
				mTotal.Text = `{found} / {all}  ({math.floor(found / math.max(1, all) * 100)}%)`
				local nextRow: Data.Milestone? = nil
				for _, r in rows do
					if not nextRow and r.state ~= "Claimed" then
						nextRow = r
					end
				end
				if nextRow then
					mBar.set(math.min(1, found / nextRow.count), `{math.min(found, nextRow.count)} / {nextRow.count}`)
					mNext.Text = `Next: {nextRow.count} pets = {Ui.money(nextRow.money)}{if nextRow.incomeBonus
						then ` + {math.floor(nextRow.incomeBonus * 100)}% pet income forever`
						else ""}`
				else
					mBar.set(1, "ALL CLAIMED")
					mNext.Text = "Every completion reward claimed!"
				end
				for i, r in rows do
					local chip = chipUi[r.count]
					if not chip then
						local f = Instance.new("Frame")
						f.Name = "Milestone" .. r.count
						f.LayoutOrder = i
						f.Size = UDim2.new(0.2, -8, 1, 0)
						f.BackgroundColor3 = C.body
						Ui.corner(f, 10)
						Ui.stroke(f, 3)
						f.Parent = chips
						local l = Ui.text(f, "", 18, { align = Enum.TextXAlignment.Center, stroke = 3, name = "Label" })
						l.Position = UDim2.fromOffset(4, 2)
						l.Size = UDim2.new(1, -8, 0, 22)
						local count = r.count
						local b = Ui.button(f, {
							text = "CLAIM",
							style = "lime",
							size = UDim2.new(1, -10, 0, 36),
							textSize = 20,
							name = "Claim",
							onClick = function()
								claimMilestone(count)
							end,
						})
						b.gui.AnchorPoint = Vector2.new(0.5, 1)
						b.gui.Position = UDim2.new(0.5, 0, 1, -4)
						chip = { gui = f, label = l, button = b }
						chipUi[r.count] = chip
					end
					local c = chip :: Chip
					c.label.Text = `{r.count} PETS`
					c.button.setText(
						if r.state == "Claimed"
							then "CLAIMED"
							elseif r.state == "Claim" then "CLAIM"
							else Ui.money(r.money)
					)
					c.button.setEnabled(r.state == "Claim" and not milestonePending[r.count])
					c.button.setPending(milestonePending[r.count] == true, "...")
				end
			end

			-- Footer: DISCOVERED + overall bar.
			local fIcon = Ui.frame(footer, "Icon", UDim2.fromOffset(64, 64), UDim2.fromOffset(0, 1))
			Ui.art(fIcon, "premium_icons_nav_index")
			local fLabel = Ui.text(footer, "DISCOVERED", 34, { autoX = true, stroke = 4, name = "Label" })
			fLabel.Position = UDim2.fromOffset(78, 12)
			local fBarHolder = Ui.frame(footer, "Bar", UDim2.new(1, -330, 0, 44), UDim2.fromOffset(320, 12))
			local fBar = Ui.progress(fBarHolder, Theme.Buttons.cyan, 44, 30)

			-- Detail column.
			local detail = Ui.surface(body, "Detail", C.card, Theme.Studs.body, 4)
			detail.ZIndex = 10
			local spot = Instance.new("Frame")
			spot.Name = "Spot"
			spot.BorderSizePixel = 0
			spot.Position = UDim2.fromOffset(10, 10)
			spot.Size = UDim2.new(1, -20, 0, 300)
			spot.ClipsDescendants = true
			Ui.corner(spot)
			Ui.fill(spot, { Color3.fromHex("4A4F63"), Color3.fromHex("23262F") })
			spot.Parent = detail
			local dGlow = Ui.glow(spot, C.text, true, 0.95)
			local dArt = Ui.frame(spot, "ArtFrame", UDim2.fromScale(0.86, 0.86), UDim2.fromScale(0.5, 0.52))
			dArt.AnchorPoint = Vector2.new(0.5, 0.5)
			dArt.ZIndex = 2
			local dName = Ui.text(detail, "", 40, { align = Enum.TextXAlignment.Center, stroke = 4, name = "Name" })
			dName.Position = UDim2.fromOffset(10, 316)
			dName.Size = UDim2.new(1, -20, 0, 48)
			local dRarity = Ui.text(detail, "", 28, { align = Enum.TextXAlignment.Center, stroke = 3, name = "Rarity" })
			dRarity.Position = UDim2.fromOffset(10, 362)
			dRarity.Size = UDim2.new(1, -20, 0, 34)
			local dInfo = Ui.text(
				detail,
				"",
				21,
				{ align = Enum.TextXAlignment.Center, wrap = true, color = C.muted, name = "Info" }
			)
			dInfo.Position = UDim2.fromOffset(16, 400)
			dInfo.Size = UDim2.new(1, -32, 0, 0)

			-- Zone panel (reward when configured, else progress).
			local zonePanel = Instance.new("Frame")
			zonePanel.Name = "ZonePanel"
			zonePanel.AnchorPoint = Vector2.new(0, 1)
			zonePanel.Position = UDim2.new(0, 10, 1, -10)
			zonePanel.Size = UDim2.new(1, -20, 0, 196)
			zonePanel.BorderSizePixel = 0
			Ui.corner(zonePanel)
			Ui.fill(zonePanel, { Color3.fromHex("10391F"), Color3.fromHex("0B2214") })
			Ui.stroke(zonePanel, 4, Theme.Buttons.lime[2])
			zonePanel.Parent = detail
			local zTitle = Ui.text(
				zonePanel,
				"",
				28,
				{ align = Enum.TextXAlignment.Center, stroke = 3, color = Theme.Buttons.lime[1], name = "Title" }
			)
			zTitle.Position = UDim2.fromOffset(8, 8)
			zTitle.Size = UDim2.new(1, -16, 0, 34)
			local zValue =
				Ui.text(zonePanel, "", 40, { align = Enum.TextXAlignment.Center, stroke = 4, name = "Value" })
			zValue.Position = UDim2.fromOffset(8, 46)
			zValue.Size = UDim2.new(1, -16, 0, 48)
			local zNote =
				Ui.text(zonePanel, "", 19, { align = Enum.TextXAlignment.Center, color = C.muted, name = "Note" })
			zNote.Position = UDim2.fromOffset(8, 96)
			zNote.Size = UDim2.new(1, -16, 0, 26)
			local zoneOfDetail = 0
			local zClaim = Ui.button(zonePanel, {
				text = "CLAIM",
				style = "lime",
				size = UDim2.new(1, -20, 0, 58),
				textSize = 28,
				name = "Claim",
				onClick = function() end,
			})
			zClaim.gui.AnchorPoint = Vector2.new(0.5, 1)
			zClaim.gui.Position = UDim2.new(0.5, 0, 1, -10)
			local sheetBack = Ui.button(detail, {
				text = "BACK",
				style = "grey",
				size = UDim2.fromOffset(160, 52),
				textSize = 24,
				name = "Back",
				onClick = function()
					detail.Visible = false
				end,
			})
			sheetBack.gui.AnchorPoint = Vector2.new(1, 0)
			sheetBack.gui.Position = UDim2.new(1, -16, 0, 16)
			sheetBack.gui.ZIndex = 12

			local function zoneById(id: number): Section?
				for _, s in sections do
					if s.zone.id == id then
						return s
					end
				end
				return nil
			end

			local function paintZonePanel()
				local s = zoneById(zoneOfDetail)
				if not s then
					return
				end
				local zone = s.zone
				local n = #zone.pets
				local complete = zone.found == n
				local reward = zone.reward
				if reward then
					zTitle.Text = "ZONE REWARD"
					zonePanel.Size = UDim2.new(1, -20, 0, 196)
					zValue.Text = Ui.money(reward.money)
					zClaim.gui.Visible = not zone.claimed
					if zone.claimed then
						zNote.Text = "Claimed"
					elseif claiming[zone.id] then
						zClaim.setPending(true, "CLAIMING...")
					else
						zClaim.setPending(false)
						zClaim.setEnabled(complete)
						zClaim.setText(if complete then "CLAIM" else `{n - zone.found} MORE TO UNLOCK`)
						zNote.Text = if (failed[zone.id] or 0) > os.clock()
							then "Claim failed. Try again."
							else zone.name
					end
				else
					zTitle.Text = "ZONE PROGRESS"
					zonePanel.Size = UDim2.new(1, -20, 0, 134)
					zValue.Text = `{zone.found} / {n}`
					zNote.Text = if complete
						then `{zone.name} complete!`
						else `{n - zone.found} more to find in {zone.name}`
					zClaim.gui.Visible = false
				end
			end

			local function showDetail(petId: string)
				local card = cards[petId]
				if not card then
					return
				end
				if selected and cards[selected] then
					local old = cards[selected]
					old.stroke.Color = C.border
					old.stroke.Thickness = 4
				end
				selected = petId
				card.stroke.Color = C.text
				card.stroke.Thickness = 5
				local pet = card.pet
				local seen = pet.discovered
				for _, child in dArt:GetChildren() do
					child:Destroy()
				end
				Ui.petArt(dArt, pet.model, not seen)
				if dGlow then
					dGlow.ImageColor3 = if seen then (rarityFill(pet.rarity))[1] else C.cardEdge
				end
				local s = zoneById(card.zone)
				local zoneName = if s then s.zone.name else ""
				dName.Text = if seen then pet.name else "???"
				dRarity.Text = string.upper(pet.rarity)
				dRarity.TextColor3 = Theme.RarityText[pet.rarity] or C.text
				dInfo.Text = if seen
					then `Zone {card.zone}: {zoneName}\n{Ui.money(pet.income)}/s base income`
					else `Not found yet.\nKick eggs into {zoneName} to find it.`
				zoneOfDetail = card.zone
				paintZonePanel()
				detail.Visible = true
				Motion.popIn(dArt)
			end

			local function claim(zoneId: number)
				if claiming[zoneId] then
					return
				end
				claiming[zoneId] = true
				paintZonePanel()
				remote("ClaimIndexReward"):FireServer(zoneId)
				Data.expect(
					function()
						local claims = Data.state.indexClaims
						return typeof(claims) == "table" and claims[tostring(zoneId)] == true
					end,
					5,
					function(ok: boolean)
						claiming[zoneId] = nil
						if ok then
							Audio.play("MilestoneClaim")
							Modal.toast("Index reward claimed!", "good")
							Motion.burst(Modal.layer(), zonePanel.AbsolutePosition + zonePanel.AbsoluteSize / 2, "cash")
						else
							failed[zoneId] = os.clock() + 3
						end
						local s = zoneById(zoneId)
						if s then
							s.zone.claimed = ok or s.zone.claimed
						end
						paintZonePanel()
					end
				)
			end
			zClaim.gui.Activated:Connect(function()
				if zClaim.enabled() and zoneOfDetail > 0 then
					claim(zoneOfDetail)
				end
			end)

			-- Build every section once; refresh only repaints.
			for order, zone in Data.index() do
				local sec = Ui.surface(list, "Zone" .. zone.id, C.card, Theme.Studs.body, 4)
				sec.LayoutOrder = order
				sec.Size = UDim2.new(1, -8, 0, SECTION_H)
				local strip = Instance.new("Frame")
				strip.Name = "ZoneArt"
				strip.Position = UDim2.fromOffset(10, 10)
				strip.Size = UDim2.new(0, STRIP_W, 1, -20)
				strip.BorderSizePixel = 0
				strip.BackgroundColor3 = zone.ground
				strip.ClipsDescendants = true
				Ui.corner(strip)
				Ui.stroke(strip, 4)
				strip.Parent = sec
				Ui.cover(strip, AssetIds.zone(zone.id) or ("zone:" .. zone.id))
				local shade = Instance.new("Frame")
				shade.Name = "Shade"
				shade.BackgroundColor3 = Color3.new(0, 0, 0)
				shade.BorderSizePixel = 0
				shade.Size = UDim2.new(1, 0, 0.5, 0)
				local sg = Instance.new("UIGradient")
				sg.Rotation = 90
				sg.Transparency = NumberSequence.new(0.35, 1)
				sg.Parent = shade
				shade.Parent = strip
				local zName = Ui.text(strip, string.upper(zone.name), 30, { wrap = true, stroke = 4, name = "Name" })
				zName.Position = UDim2.fromOffset(10, 8)
				zName.Size = UDim2.new(1, -16, 0, 0)
				zName.ZIndex = 2
				local zNum = Ui.text(strip, `ZONE {zone.id}`, 18, { stroke = 3, name = "Number" })
				zNum.AnchorPoint = Vector2.new(0, 1)
				zNum.Position = UDim2.new(0, 10, 1, -6)
				zNum.Size = UDim2.new(1, -16, 0, 24)
				zNum.ZIndex = 2

				local cardsBox =
					Ui.frame(sec, "Pets", UDim2.new(1, -(STRIP_W + 34), 0, 186), UDim2.fromOffset(STRIP_W + 22, 10))
				local barHolder =
					Ui.frame(sec, "Bar", UDim2.new(1, -(STRIP_W + 34), 0, 44), UDim2.new(0, STRIP_W + 22, 1, -54))
				local bar = Ui.progress(barHolder, Theme.Buttons.lime, 44, 30)
				local s: Section = { zone = zone, gui = sec, bar = bar, cards = {} }
				local n = math.max(4, #zone.pets)
				for i, pet in zone.pets do
					local b = Instance.new("TextButton")
					b.Name = pet.petId
					b.Text = ""
					b.AutoButtonColor = false
					b.Selectable = true
					b.Size = UDim2.new(1 / n, -10, 1, 0)
					b.Position = UDim2.new((i - 1) / n, 5, 0, 0)
					Ui.corner(b)
					Ui.fill(b, rarityFill(pet.rarity))
					local stroke = Ui.stroke(b, 4)
					Ui.studs(b, Theme.Studs.card, 20)
					local art = Ui.frame(b, "ArtFrame", UDim2.new(1, -10, 1, -40), UDim2.fromOffset(5, 34))
					art.ZIndex = 2
					local label = Ui.text(b, "", 22, { align = Enum.TextXAlignment.Center, stroke = 3, name = "Name" })
					label.Position = UDim2.fromOffset(4, 4)
					label.Size = UDim2.new(1, -8, 0, 30)
					label.ZIndex = 3
					Motion.interactive(b)
					local petId = pet.petId
					b.Activated:Connect(function()
						showDetail(petId)
					end)
					b.Parent = cardsBox
					local card: PetCard =
						{ pet = pet, zone = zone.id, gui = b, stroke = stroke, art = art, name = label, seen = nil }
					cards[pet.petId] = card
					table.insert(s.cards, card)
				end
				table.insert(sections, s)
			end

			local function refresh()
				local found, all = 0, 0
				local selectedChanged = false
				for i, zone in Data.index() do
					local s = sections[i]
					if s then
						s.zone = zone
						for j, pet in zone.pets do
							local card = s.cards[j]
							if card and card.seen ~= pet.discovered then
								selectedChanged = selectedChanged or pet.petId == selected
								card.seen = pet.discovered
								card.pet = pet
								for _, child in card.art:GetChildren() do
									child:Destroy()
								end
								Ui.petArt(card.art, pet.model, not pet.discovered)
								card.name.Text = if pet.discovered then pet.name else "???"
							end
						end
						local n = #zone.pets
						s.bar.set(zone.found / math.max(1, n), `{zone.found} / {n}`)
					end
					found += zone.found
					all += #zone.pets
				end
				fBar.set(found / math.max(1, all), `{found} / {all}`)
				paintZonePanel()
				paintMilestones()
				local keep = selected
				if keep and selectedChanged and detail.Visible then -- only rebuild the preview when it changed
					showDetail(keep)
				end
			end

			local function place()
				if compact then
					list.Size = UDim2.fromScale(1, 1)
					detail.AnchorPoint = Vector2.new(1, 0)
					detail.Position = UDim2.fromScale(1, 0)
					detail.Size = UDim2.new(0, DETAIL_W, 1, 0)
					sheetBack.gui.Visible = true
					detail.Visible = false
				else
					list.Size = UDim2.new(1, -(DETAIL_W + 20), 1, 0)
					detail.AnchorPoint = Vector2.new(1, 0)
					detail.Position = UDim2.fromScale(1, 0)
					detail.Size = UDim2.new(0, DETAIL_W, 1, 0)
					sheetBack.gui.Visible = false
					detail.Visible = true
				end
			end

			return {
				open = function()
					refresh()
					if not selected and not compact then
						local first: string? = nil
						for _, s in sections do
							for _, card in s.cards do
								if not first and card.pet.discovered then
									first = card.pet.petId
								end
							end
						end
						first = first or (sections[1] and sections[1].cards[1] and sections[1].cards[1].pet.petId)
						if first then
							showDetail(first)
						end
					end
					local visible = {}
					for i = 1, math.min(3, #sections) do
						table.insert(visible, sections[i].gui :: GuiObject)
					end
					Motion.reveal(visible, C.body)
				end,
				update = refresh,
				resize = function(_size: Vector2, isCompact: boolean)
					compact = isCompact
					place()
				end,
			}
		end
	)
end

return PetIndex
