--!strict
-- Donate window (the TOP DONATORS board's podium, "OpenMenu:Donate"). Purple header, one thank-you line, what you
-- have donated so far, and one button per Config/Leaderboards donation (R$ n). A donation is a developer
-- product purchase; the server counts the receipt (MonetizationService -> LeaderboardService). Buttons whose
-- product id is still 0 read NOT ON SALE on live servers and STUDIO TEST in Studio (DonateTest).
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Leaderboards = require(Shared.Config.Leaderboards)

local System = script.Parent.Parent.System
local Data = require(System.Data)
local Modal = require(System.Modal)
local Theme = require(System.Theme)
local Ui = require(System.Ui)

local C = Theme.Colors
local Donate = {}

local function remote(name: string): RemoteEvent
	local Remotes = require(Shared:WaitForChild("Remotes")) :: any
	return Remotes.get(name)
end

function Donate.define()
	Modal.define("Donate", { title = "Donate", header = Theme.Headers.rebirth }, function(shell)
		local body = shell.body
		local intro = Ui.text(
			body,
			"Thank you for supporting Kick an Egg! Every donation puts you on the TOP DONATORS board.",
			30,
			{ stroke = 3, wrap = true, align = Enum.TextXAlignment.Center, name = "Intro" }
		)
		intro.Position = UDim2.fromOffset(0, 10)
		local total =
			Ui.text(body, "", 34, { stroke = 3, align = Enum.TextXAlignment.Center, color = C.power, name = "Total" })
		total.Position = UDim2.fromOffset(0, 120)
		local grid = Ui.frame(body, "Buttons", UDim2.new(1, -80, 1, -200), UDim2.fromOffset(40, 190))
		local layout = Instance.new("UIGridLayout")
		layout.CellSize = UDim2.new(1 / 3, -16, 0, 96)
		layout.CellPadding = UDim2.fromOffset(24, 24)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = grid
		for i, d in Leaderboards.Donations do
			local b = Ui.button(grid, {
				text = `R$ {d.robux}`,
				style = "purple",
				size = UDim2.fromScale(1, 1),
				textSize = 40,
				name = "Donate" .. d.robux,
				onClick = function()
					if d.id == 0 then
						if RunService:IsStudio() then
							remote("DonateTest"):FireServer(i)
						end
					else
						MarketplaceService:PromptProductPurchase(Players.LocalPlayer, d.id)
					end
				end,
			})
			b.gui.LayoutOrder = i
			if d.id == 0 then
				if RunService:IsStudio() then
					b.setText(`R$ {d.robux} (TEST)`)
				else
					b.setText("NOT ON SALE")
					b.setEnabled(false)
				end
			end
		end
		local function refresh()
			local n = if typeof(Data.state.donated) == "number" then Data.state.donated else 0
			total.Text = if n > 0 then `You have donated R$ {n}. Thank you!` else "Pick an amount:"
		end
		return { open = refresh, update = refresh }
	end)
end

return Donate
