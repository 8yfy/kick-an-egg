--!strict
-- Admin client entry. The server only parents this (inside the ScreenGui "KTE_Admin", next to the per-admin
-- RemoteFunction "Bridge") into an allowlisted player's PlayerGui; other players never receive it.
-- It asks the server for this session's metadata, then builds the panel and the lab renderer.

local Net = require(script.Parent.Net)
local State = require(script.Parent.State)

local screen = script.Parent.Parent
local bridge = screen:WaitForChild("Bridge", 30)
if not (bridge and bridge:IsA("RemoteFunction")) then
	return
end
Net.init(bridge)

local hello = Net.request("session.hello")
if not hello.ok then
	warn(`[Admin] session refused: {hello.code}`)
	return
end
State.meta = hello.data

require(script.Parent.App).start(screen :: ScreenGui, script.Parent)
require(script.Parent.LabView).start()
