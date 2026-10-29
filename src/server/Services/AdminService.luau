--!strict
-- Admin system entry point (server). Everything lives in ServerScriptService.Server.Admin (docs/AdminPanel.md):
--   * Access comes ONLY from Admin/Allowlist (numeric UserIds -> Owner / Developer / Tester), read once at start.
--   * Only allowlisted players receive the admin client: a ScreenGui with its own RemoteFunction "Bridge" and a
--     copy of Admin/Client, parented into THAT player's PlayerGui (other clients never see the code or the remote).
--     Nothing admin-related is put in ReplicatedStorage. The GUI is not the security boundary: every request
--     goes through Admin/Pipeline (allowlist -> permission -> params -> scope/limits -> rate -> handler -> audit).
--   * Cross-server actions use MessagingService + MemoryStore (Admin/CrossServer), re-validated on every server.
--   * If the command registry fails its startup check, the admin system stays off (fails closed); the game runs.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Admin = script.Parent.Parent:WaitForChild("Admin")
local Allowlist = require(Admin.Allowlist)
local Config = require(Admin.Config)
local Authorization = require(Admin.Authorization)
local Schema = require(Admin.Schema)
local Limiter = require(Admin.Limiter)
local Audit = require(Admin.Audit)
local Pipeline = require(Admin.Pipeline)
local Environment = require(Admin.Environment)
local CrossServer = require(Admin.CrossServer)
local Catalog = require(Admin.Catalog)
local ModelLab = require(Admin.ModelLab)
local Flags = require(Admin.Flags)
local Diagnostics = require(Admin.Diagnostics)

local Services = script.Parent
local AdminService = {}

local auth = Authorization.new(Allowlist, Config.Roles, RunService:IsStudio())
local delivered: { [Player]: ScreenGui } = {}
local pipeline: any = nil
local enabled = false

local rawAudit = Audit.new(Config.Audit.capacity, os.time)
-- The same audit, mirroring global-scope entries to MemoryStore (expiring) for the all-servers log view.
local audit = table.freeze({
	add = function(entry: { [string]: any })
		local e = rawAudit.add(entry)
		if e.scope == "global" and e.origin == nil then
			CrossServer.recordGlobalAudit(e :: any)
		end
		return e
	end,
	query = rawAudit.query,
	latest = rawAudit.latest,
	size = rawAudit.size,
	failures = rawAudit.failures,
})

local function deliver(player: Player)
	if not enabled or delivered[player] or not auth.roleOf(player.UserId) then
		return
	end
	local playerGui = player:WaitForChild("PlayerGui", 60)
	if not playerGui or not player.Parent or delivered[player] then
		return
	end
	local screen = Instance.new("ScreenGui")
	screen.Name = "KTE_Admin"
	screen.ResetOnSpawn = false
	screen.DisplayOrder = 60
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.IgnoreGuiInset = true
	local bridge = Instance.new("RemoteFunction")
	bridge.Name = "Bridge"
	bridge.OnServerInvoke = function(caller: Player, commandId: any, params: any)
		if caller ~= player then
			return { ok = false, code = "unauthorized", message = "Not authorized.", correlation = "", at = os.time() }
		end
		return pipeline.execute(caller, commandId, params)
	end
	bridge.Parent = screen
	Admin.Client:Clone().Parent = screen
	delivered[player] = screen
	screen.Parent = playerGui
end

-- Servers that start later pick up global effects that haven't expired yet.
local function applyGlobalState()
	local weather = CrossServer.getState("weather")
	if typeof(weather) == "table" and typeof(weather.weather) == "string" and typeof(weather.endsAt) == "number" then
		local left = weather.endsAt - os.time()
		if left > 5 and left <= Config.Weather.maxSeconds then
			require(Services.WeatherService):StartEvent(weather.weather, left)
		end
	end
	for _, id in Flags.ids() do
		local value = CrossServer.getState(`flag:{id}`)
		if typeof(value) == "boolean" then
			Flags.set(id, value)
		end
	end
end

function AdminService:Init()
	local deps: { [string]: any } = {
		Config = Config,
		Catalog = Catalog,
		ModelLab = ModelLab,
		Flags = Flags,
		Diagnostics = Diagnostics,
		CrossServer = CrossServer,
		Environment = Environment,
		audit = audit,
		Services = {
			DataService = require(Services.DataService),
			PlotService = require(Services.PlotService),
			WeatherService = require(Services.WeatherService),
			AnnounceService = require(Services.AnnounceService),
			ChaseService = require(Services.ChaseService),
			KickService = require(Services.KickService),
		},
		can = auth.can,
		rank = auth.rank,
		roleOf = auth.roleOf,
		permissionsOf = auth.permissionsOf,
		sessionCount = function(): number
			local n = 0
			for _ in delivered do
				n += 1
			end
			return n
		end,
	}
	local commands: { [string]: any } = {}
	local problems: { string } = {}
	for _, module in Admin.Commands:GetChildren() do
		if module:IsA("ModuleScript") then
			for _, cmd in (require(module) :: any)(deps) do
				if commands[cmd.id] then
					table.insert(problems, `duplicate command {cmd.id}`)
				end
				commands[cmd.id] = table.freeze(cmd)
			end
		end
	end
	local known: { [string]: boolean } = {}
	for _, role in Config.Roles do
		for name in role.permissions do
			known[name] = true
		end
	end
	for _, p in Pipeline.checkRegistry(commands, known, Schema) do
		table.insert(problems, p)
	end
	for _, bad in auth.rejected do
		warn(`[AdminService] ignored invalid allowlist entry {bad}`)
	end
	if #problems > 0 then
		warn(`[AdminService] admin system disabled, registry problems: {table.concat(problems, "; ")}`)
		return
	end
	pipeline = Pipeline.new({
		auth = auth,
		commands = table.freeze(commands),
		schema = Schema,
		limiter = Limiter.new(Config.Limits.requestRate, Config.Limits.requestBurst, os.clock),
		audit = audit,
		limits = Config.Limits,
		environment = Environment.current,
		clock = os.clock,
		now = os.time,
		serverId = Environment.serverId(),
		newId = function(): string
			return HttpService:GenerateGUID(false)
		end,
		isConnected = function(player: any): boolean
			return typeof(player) == "Instance" and player.Parent == Players
		end,
		broadcast = CrossServer.broadcast,
		warn = warn,
		summarize = Audit.summarize,
	})
	deps.describe = pipeline.describe
	CrossServer.init(pipeline)
	AdminService.Pipeline = pipeline -- server-side only (tests and other server code)
	AdminService.CrossServer = CrossServer
	AdminService.Authorization = auth
	enabled = true
end

function AdminService:Start()
	if not enabled then
		return
	end
	Diagnostics.start()
	ModelLab.start()
	CrossServer.start()
	task.spawn(applyGlobalState)
	Players.PlayerAdded:Connect(function(player)
		task.spawn(deliver, player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(deliver, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		delivered[player] = nil
		pipeline.forget(player.UserId)
	end)
	print(`[AdminService] {auth.count()} admin(s) allowlisted, environment {Environment.current()}`)
end

return AdminService
