--!strict
-- Player-visible server messages (admin announcements). The server writes the latest message as attributes on
-- ReplicatedStorage.ServerMessage (a Configuration); every client's UI/Hud/ServerMessage shows it as one line at the
-- top: [headshot] USERNAME: message. Attributes only replicate server -> client, so this adds no remote a
-- client could fire. Text must already be filtered (Commands/Controls filters it before calling show).

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Messages = {}

local channel: Configuration? = nil

function Messages.channel(): Configuration
	local c = channel
	if c and c.Parent then
		return c
	end
	local made = Instance.new("Configuration")
	made.Name = "ServerMessage"
	made.Parent = ReplicatedStorage
	channel = made
	return made
end

-- `id` identifies one message (the same on every server for a global announcement). Id is written last: clients
-- react to it and read the other attributes, which arrive first.
function Messages.show(text: string, userId: number, username: string, id: string?)
	local c = Messages.channel()
	c:SetAttribute("MsgText", text)
	c:SetAttribute("UserId", userId)
	c:SetAttribute("Username", username)
	c:SetAttribute("At", workspace:GetServerTimeNow())
	c:SetAttribute("Id", id or HttpService:GenerateGUID(false))
end

return Messages
