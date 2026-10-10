--!strict
-- Pet Index (UI handoff SCREEN-SPEC "Index"): one vertical list of zone sections (Config/Zones order), each
-- with a biome banner in the zone's own colours, completion count + bar and its pet cards. Discovered =
-- PlayerData.discovered (set by the server at hatch; owned pets count too). Undiscovered pets are black
-- silhouettes named "???". Desktop: fixed detail panel on the right; short screens: a detail sheet that
-- slides up over the list. Zone rewards (Economy.IndexRewards) show only when configured: locked until the
-- zone is complete, Claim when eligible, pending during the request, Claimed only after the server's
-- DataChanged confirms it. No World/Limited tabs: the game has no such collections.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local System = script.Parent.Parent.System
local Data = require(System.Data)
local Modal = require(System.Modal)
local Motion = require(System.Motion)
local Theme = require(System.Theme)
local Ui = require(System.Ui)

local C = Theme.Colors
local PetIndex = {}

local DETAIL_W = 340

local function remote(name: string): RemoteEvent
	local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes")) :: any
	return Remotes.get(name)
end

type PetCard = { pet: Data.IndexPet, zone: number, gui: TextButton, art: Frame, name: TextLabel, seen: boolean }
type Section = {
	zone: Data.IndexZone,
	count: TextLabel,
	bar: Ui.Progress,
	claim: Ui.Button?,
	claimNote: TextLabel?,
	cards: { PetCard },
}

local function zoneBanner(parent: Instance, zone: Data.IndexZone): Frame
	local banner = Instance.new("Frame")
	banner.Name = "Banner"
	banner.Size = UDim2.new(1, 0, 0, 84)
	banner.BorderSizePixel = 0
	banner.BackgroundColor3 = Color3.new(1, 1, 1)
	banner.ClipsDescendants = true
	Ui.corner(banner, 12)
	local g = Instance.new("UIGradient")
	g.Rotation = 0
	g.Color = ColorSequence.new(zone.ground, zone.accent)
	g.Parent = banner
	Ui.stroke(banner)
	Ui.studs(banner, Theme.Studs.header)
	-- Blocky "biome strip": a row of chunky hills in the zone colours (no image needed).
	for i = 0, 7 do
		local block = Instance.new("Frame")
		block.Name = "Hill"
		block.BorderSizePixel = 0
		block.BackgroundColor3 = if i % 2 == 0
			then zone.ground:Lerp(Color3.new(0, 0, 0), 0.18)
			else zone.accent:Lerp(Color3.new(0, 0, 0), 0.12)
		block.BackgroundTransparency = 0.35
		local h = 18 + ((i * 37) % 5) * 7
		block.AnchorPoint = Vector2.new(0, 1)
		block.Size = UDim2.new(0.125, 2, 0, h)
		block.Position = UDim2.new(i * 0.125, 0, 1, 0)
		block.ZIndex = 1
		block.Parent = banner
	end
	banner.Parent = parent
	return banner
end

function PetIndex.define()
	Modal.define(
		"Index",
		{ title = "Pet Index", gradient = "cyan", icon = "icon/index" },
		function(shell: Modal.Shell): Modal.Screen
			local body = shell.body
			local sections: { Section } = {}
			local cards: { [string]: PetCard } = {}
			local selected: string? = nil
			local claiming: { [number]: boolean } = {}
			local failed: { [number]: number } = {}
			local compact = false

			-- Header row: total discovered.
			local total = Ui.text(body, "", 26, { name = "Total" })
			total.Size = UDim2.new(1, 0, 0, 34)

			local list = Ui.scroll(body, "Zones")
			Ui.padding(list, 6)
			Ui.list(list, 28)

			-- Detail panel (fixed on desktop, sheet on short screens).
			local detail = Ui.panel(body, "Detail", C.panelDeep)
			detail.ZIndex = 10
			local dArt = Instance.new("Frame")
			dArt.Name = "ArtHolder"
			dArt.BackgroundColor3 = C.panel
			dArt.BorderSizePixel = 0
			dArt.ClipsDescendants = true
			Ui.corner(dArt)
			Ui.stroke(dArt, 3)
			dArt.Parent = detail
			local dGlow = Ui.glow(dArt, C.text, true)
			local dArtFrame = Ui.frame(dArt, "ArtFrame", UDim2.fromScale(0.9, 0.9), UDim2.fromScale(0.5, 0.5))
			dArtFrame.AnchorPoint = Vector2.new(0.5, 0.5)
			local dInfo = Ui.frame(detail, "Info")
			Ui.list(dInfo, 8)
			local dName = Ui.text(dInfo, "", 30, { name = "Name", wrap = true })
			dName.LayoutOrder = 1
			local dChipRow = Ui.frame(dInfo, "ChipRow", UDim2.new(1, 0, 0, 30))
			dChipRow.LayoutOrder = 2
			local dZone = Ui.text(dInfo, "", 20, { color = C.muted, name = "Zone", wrap = true })
			dZone.LayoutOrder = 3
			local dIncome = Ui.text(dInfo, "", 22, { color = C.cash, name = "Income" })
			dIncome.LayoutOrder = 4
			local dStatus = Ui.text(dInfo, "", 20, { color = C.muted, name = "Status", wrap = true })
			dStatus.LayoutOrder = 5
			local dClose = Ui.button(detail, {
				text = "BACK",
				gradient = "grey",
				size = UDim2.new(1, -28, 0, 52),
				textSize = 22,
				name = "Back",
				onClick = function()
					detail.Visible = false
				end,
			})
			dClose.gui.AnchorPoint = Vector2.new(0.5, 1)
			dClose.gui.Position = UDim2.new(0.5, 0, 1, -14)

			local stopDetailFloat: (() -> ())? = nil
			local function showDetail(petId: string)
				local card = cards[petId]
				if not card then
					return
				end
				if selected and cards[selected] then
					local old = cards[selected].gui:FindFirstChildOfClass("UIStroke")
					if old then
						old.Color = C.stroke
					end
				end
				selected = petId
				local stroke = card.gui:FindFirstChildOfClass("UIStroke")
				if stroke then
					stroke.Color = C.text
				end
				local pet = card.pet
				local seen = card.seen
				for _, child in dArtFrame:GetChildren() do
					child:Destroy()
				end
				Ui.petArt(dArtFrame, pet.model, not seen)
				for _, child in dChipRow:GetChildren() do
					child:Destroy()
				end
				if seen then
					Ui.chip(dChipRow, pet.rarity)
				end
				if dGlow then
					dGlow.ImageColor3 = if seen then (Theme.Rarity :: any)[pet.rarity] or C.text else C.innerEdge
				end
				local zoneName = ""
				for _, s in sections do
					if s.zone.id == card.zone then
						zoneName = s.zone.name
					end
				end
				dName.Text = if seen then pet.name else "???"
				dZone.Text = `Zone {card.zone}: {zoneName}`
				dIncome.Text = if seen then `{Ui.money(pet.income)}/s base income` else ""
				dStatus.Text = if seen then "Discovered" else `Not found yet. Kick eggs into {zoneName} to find it.`
				if stopDetailFloat then
					stopDetailFloat()
				end
				stopDetailFloat = Motion.float(dArtFrame)
				detail.Visible = true
				Motion.popIn(dArtFrame)
			end

			local function paintSection(s: Section)
				local zone = s.zone
				local n = #zone.pets
				s.count.Text = `{zone.found} / {n}`
				s.bar.set(zone.found / math.max(1, n), if zone.found == n then "Complete!" else "")
				local claim, note = s.claim, s.claimNote
				if claim and note and zone.reward then
					local complete = zone.found == n
					claim.gui.Visible = not zone.claimed
					if zone.claimed then
						note.Text = `Reward claimed: {Ui.money(zone.reward.money)}`
					elseif claiming[zone.id] then
						claim.setPending(true, "CLAIMING...")
					else
						claim.setPending(false)
						claim.setEnabled(complete)
						claim.setText(if complete then "CLAIM" else "LOCKED")
						note.Text = if (failed[zone.id] or 0) > os.clock()
							then "Claim failed. Try again."
							else `Find every pet: {Ui.money(zone.reward.money)}`
					end
				end
			end

			local function claim(zoneId: number)
				if claiming[zoneId] then
					return
				end
				claiming[zoneId] = true
				for _, s in sections do
					if s.zone.id == zoneId then
						paintSection(s)
					end
				end
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
							Modal.toast("Index reward claimed!", "good")
						else
							failed[zoneId] = os.clock() + 3
						end
						for _, s in sections do
							if s.zone.id == zoneId then
								if ok then
									local at = s.count.AbsolutePosition + s.count.AbsoluteSize / 2
									Motion.burst(Modal.layer(), at, "cash")
								end
								s.zone.claimed = ok or s.zone.claimed
								paintSection(s)
							end
						end
					end
				)
			end

			-- Build every section once; refresh only repaints.
			local zones = Data.index()
			for order, zone in zones do
				local sec = Ui.frame(list, "Zone" .. zone.id, UDim2.new(1, 0, 0, 0))
				sec.AutomaticSize = Enum.AutomaticSize.Y
				sec.LayoutOrder = order
				Ui.list(sec, 12)
				local banner = zoneBanner(sec, zone)
				banner.LayoutOrder = 1
				local name = Ui.text(banner, `{zone.id}. {zone.name}`, 34, { stroke = 4, name = "Name" })
				name.Position = UDim2.fromOffset(18, 6)
				name.Size = UDim2.new(0.6, 0, 0, 42)
				name.ZIndex = 3
				local count = Ui.text(banner, "", 26, { align = Enum.TextXAlignment.Right, name = "Count" })
				count.AnchorPoint = Vector2.new(1, 0)
				count.Position = UDim2.new(1, -18, 0, 8)
				count.Size = UDim2.new(0.3, 0, 0, 36)
				count.ZIndex = 3
				local barHolder = Ui.frame(banner, "BarHolder", UDim2.new(1, -36, 0, 22), UDim2.new(0, 18, 1, -30))
				barHolder.ZIndex = 3
				local bar = Ui.progress(barHolder, "lime", 22)
				bar.gui.ZIndex = 3

				local s: Section = { zone = zone, count = count, bar = bar, cards = {} }
				if zone.reward then
					local row = Ui.frame(sec, "Reward", UDim2.new(1, 0, 0, 56))
					row.LayoutOrder = 2
					local note = Ui.text(row, "", 22, { color = C.cash, name = "Note" })
					note.Size = UDim2.new(1, -240, 1, 0)
					local zoneId = zone.id
					local btn = Ui.button(row, {
						text = "CLAIM",
						gradient = "lime",
						size = UDim2.fromOffset(220, 52),
						textSize = 24,
						name = "Claim",
						onClick = function()
							claim(zoneId)
						end,
					})
					btn.gui.AnchorPoint = Vector2.new(1, 0.5)
					btn.gui.Position = UDim2.fromScale(1, 0.5)
					s.claim, s.claimNote = btn, note
				end

				local gridHolder = Ui.frame(sec, "Pets", UDim2.new(1, 0, 0, 0))
				gridHolder.AutomaticSize = Enum.AutomaticSize.Y
				gridHolder.LayoutOrder = 3
				Ui.grid(gridHolder, 150, 1.22, 14, 8)
				for i, pet in zone.pets do
					local b = Instance.new("TextButton")
					b.Name = pet.petId
					b.Text = ""
					b.AutoButtonColor = false
					b.LayoutOrder = i
					b.BackgroundColor3 = C.panel
					b.Selectable = true
					Ui.corner(b)
					Ui.stroke(b, 3)
					Ui.studs(b)
					local art = Ui.frame(b, "ArtFrame", UDim2.new(1, -16, 1, -48), UDim2.fromOffset(8, 6))
					local label = Ui.text(b, "", 18, { align = Enum.TextXAlignment.Center, name = "Name" })
					label.AnchorPoint = Vector2.new(0, 1)
					label.Position = UDim2.new(0, 4, 1, -6)
					label.Size = UDim2.new(1, -8, 0, 26)
					Motion.interactive(b)
					local petId = pet.petId
					b.Activated:Connect(function()
						showDetail(petId)
					end)
					b.Parent = gridHolder
					local card: PetCard = { pet = pet, zone = zone.id, gui = b, art = art, name = label, seen = false }
					-- art is built by refresh() (silhouette or real) the first time
					card.seen = not pet.discovered -- force a first paint
					cards[pet.petId] = card
					table.insert(s.cards, card)
				end
				table.insert(sections, s)
			end

			local function refresh()
				local fresh = Data.index()
				local found, all = 0, 0
				for i, zone in fresh do
					local s = sections[i]
					if s then
						s.zone = zone
						for j, pet in zone.pets do
							local card = s.cards[j]
							if card and card.seen ~= pet.discovered then
								card.seen = pet.discovered
								card.pet = pet
								for _, child in card.art:GetChildren() do
									child:Destroy()
								end
								Ui.petArt(card.art, pet.model, not pet.discovered)
								card.name.Text = if pet.discovered then pet.name else "???"
								card.name.TextColor3 = if pet.discovered
									then (Theme.Rarity :: any)[pet.rarity] or C.text
									else C.muted
							end
						end
						paintSection(s)
					end
					found += zone.found
					all += #zone.pets
				end
				total.Text = `Discovered {found} / {all}`
				if selected then
					local keep = selected
					selected = nil
					if detail.Visible or not compact then
						showDetail(keep)
					end
				end
			end

			local function place()
				local size = shell.size()
				local bodyH = size.Y - (10 + Theme.Layout.header + 16 + Theme.Layout.pad)
				if compact then
					list.Position = UDim2.fromOffset(0, 42)
					list.Size = UDim2.new(1, 0, 1, -42)
					detail.AnchorPoint = Vector2.new(0.5, 1)
					detail.Position = UDim2.new(0.5, 0, 1, 0)
					detail.Size = UDim2.new(1, 0, 0, math.min(bodyH, 420))
					dArt.Position = UDim2.fromOffset(14, 14)
					dArt.Size = UDim2.new(0, 220, 1, -96)
					dInfo.Position = UDim2.fromOffset(250, 14)
					dInfo.Size = UDim2.new(1, -264, 1, -96)
					dClose.gui.Visible = true
					detail.Visible = false
				else
					list.Position = UDim2.fromOffset(0, 42)
					list.Size = UDim2.new(1, -(DETAIL_W + Theme.Layout.gap), 1, -42)
					detail.AnchorPoint = Vector2.new(1, 0)
					detail.Position = UDim2.fromScale(1, 0)
					detail.Size = UDim2.new(0, DETAIL_W, 1, 0)
					dArt.Position = UDim2.fromOffset(14, 14)
					dArt.Size = UDim2.new(1, -28, 0, DETAIL_W - 28)
					dInfo.Position = UDim2.fromOffset(16, DETAIL_W)
					dInfo.Size = UDim2.new(1, -32, 1, -DETAIL_W - 16)
					dClose.gui.Visible = false
					detail.Visible = true
				end
			end

			return {
				open = function()
					refresh()
					if not selected then
						-- pre-select the first discovered pet (or the very first) so the panel isn't empty
						local first: string? = nil
						for _, s in sections do
							for _, card in s.cards do
								if card.seen and not first then
									first = card.pet.petId
								end
							end
						end
						local initial = first
							or (sections[1] and sections[1].cards[1] and sections[1].cards[1].pet.petId)
						if initial and not compact then
							showDetail(initial)
						end
					end
					local visible = {}
					for i = 1, math.min(2, #sections) do
						for _, card in sections[i].cards do
							table.insert(visible, card.gui :: GuiObject)
						end
					end
					Motion.reveal(visible, C.panel)
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
