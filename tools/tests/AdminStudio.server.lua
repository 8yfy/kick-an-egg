--!strict
-- Live admin-system tests for a running Studio Play session (single player, Studio in-memory data).
-- Paste into a Script under ServerScriptService WHILE PLAYING (or let Studio MCP insert it): it uses the game's
-- real AdminService instance, the real player and the real services, then prints a summary and stores it in
-- the ServerScriptService attribute "AdminStudioResult". It cleans up the lab models and weather it creates.
-- What it can't cover: MessagingService/MemoryStore delivery (unpublished place) and multi-client remotes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")

local Server = SSS:WaitForChild("Server")
local AdminService = require(Server.Services.AdminService) :: any
local DataService = require(Server.Services.DataService) :: any
local WeatherService = require(Server.Services.WeatherService) :: any
local Envelope = require(Server.Admin.Envelope) :: any
local Config = require(Server.Admin.Config) :: any

local passed, failed = 0, 0
local fails = {}
local function check(name: string, ok: any)
	if ok then
		passed += 1
	else
		failed += 1
		table.insert(fails, name)
		warn(`[AdminStudio FAIL] {name}`)
	end
end

local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
DataService:WaitForData(player)
local pipe = AdminService.Pipeline
local X = AdminService.CrossServer
check("admin system enabled", pipe ~= nil)
local function run(cmd: string, params: any?): any
	task.wait(0.2) -- stay under the request rate while testing everything else
	return pipe.execute(player, cmd, params or {})
end

-- 1. identity and exposure ---------------------------------------------------------------------------------------
check("Studio player is allowlisted", AdminService.Authorization.roleOf(player.UserId) ~= nil)
check("unlisted UserId has no role", AdminService.Authorization.roleOf(1) == nil)
check("string UserId has no role", AdminService.Authorization.roleOf(tostring(player.UserId)) == nil)
local exposed = false
for _, d in ReplicatedStorage:GetDescendants() do
	if string.find(string.lower(d.Name), "admin") or d.Name == "Allowlist" then
		exposed = true
	end
end
check("nothing admin-related in ReplicatedStorage", not exposed)
local gui = player:WaitForChild("PlayerGui"):WaitForChild("KTE_Admin", 10)
check("admin client delivered to the admin's PlayerGui only", gui and gui:FindFirstChild("Bridge"))
check("allowlist not shipped to the client", gui and gui:FindFirstChild("Allowlist", true) == nil)

-- 2. unauthorized / spoofed / malformed --------------------------------------------------------------------------
local fake = { UserId = 123456, Name = "Intruder" }
check("non-admin request refused", pipe.execute(fake, "dashboard.get", {}).code == "unauthorized")
check("non-admin can't open a session", pipe.execute(fake, "session.hello", {}).code == "unauthorized")
check("spoofed UserId param refused", run("dashboard.get", { userId = 999 }).code == "invalid_params")
check("unknown command", run("admin.grantSelf", {}).code == "unknown_command")
check("path-like command id", run("../Allowlist", {}).code == "malformed")
check("number command id", run(42 :: any, {}).code == "malformed")
check("params as script source", run("lab.spawn", "loadstring('x')()" :: any).code == "invalid_params")
check("client asset id refused", run("lab.spawn", { source = "rbxassetid://1818" }).code == "invalid_params")
check("module path refused", run("lab.spawn", { source = "asset:../../ServerStorage" }).code == "invalid_params")
check("unknown preview asset refused", run("lab.spawn", { source = "asset:NotThere" }).code == "invalid_params")
check("nested table param refused", run("players.list", { query = { "x" } }).code == "invalid_params")
check("NaN param refused", run("lab.catalog", { page = 0 / 0 }).code == "invalid_params")
check(
	"out-of-range param refused",
	run("weather.start", { weather = "Rainy", seconds = 999999 }).code == "invalid_params"
)
check("unknown scope refused", run("weather.stop", { scope = "universe" }).code == "scope")
check("lab commands can't go global", run("lab.clearMine", { scope = "global", confirmed = true }).code == "scope")
check("confirmation required", run("lab.clearAll", {}).code == "confirm_required")
check(
	"can't kick yourself",
	run("players.kick", { userId = player.UserId, reason = "test", confirmed = true }).code == "forbidden"
)
check("bad target", run("players.inspect", { userId = 77 }).code == "not_found")

-- 3. real reads ---------------------------------------------------------------------------------------------------
local hello = run("session.hello")
check("session.hello ok", hello.ok and hello.data.role ~= nil)
check("hello has commands, no allowlist", hello.ok and #hello.data.commands > 20 and hello.data.users == nil)
check("dashboard ok", run("dashboard.get").ok)
local catalog = run("lab.catalog", { kind = "pet", page = 1 })
check("catalog lists pets", catalog.ok and catalog.data.total == 79)
check("catalog lists eggs", run("lab.catalog", { kind = "egg" }).data.total == 79)
check("catalog lists sacks", run("lab.catalog", { kind = "sack" }).data.total == 20)
local inspect = run("players.inspect", { userId = player.UserId })
check("inspect player", inspect.ok and typeof(inspect.data.money) == "number")

-- 4. Model Lab ----------------------------------------------------------------------------------------------------
local first = run("lab.spawn", { source = "pet:sprout_pup", placement = "platform" })
check("spawn a pet", first.ok)
local labId = first.ok and first.data.model.id
local lab = workspace:FindFirstChild("AdminLab")
check("lab platform built", lab ~= nil)
local model = lab and lab.Models:FindFirstChild(`Lab_{labId}`)
check("model in workspace.AdminLab.Models", model ~= nil)
local unsafe = 0
for _, d in if model then model:GetDescendants() else {} do
	if d:IsA("LuaSourceContainer") or (d:IsA("BasePart") and (d.CanCollide or d.CanTouch)) then
		unsafe += 1
	end
end
check("no scripts / collisions on lab model", unsafe == 0)
local m = run("lab.inspect", { labId = labId })
check("measure from the actual model", m.ok and m.data.info.parts > 5 and m.data.info.bbox[2] > 0)
check("rotate", run("lab.transform", { labId = labId, op = "rotate", yaw = 90 }).ok)
check("scale", run("lab.transform", { labId = labId, op = "scale", scale = 2 }).ok)
check(
	"scale above bound refused",
	run("lab.transform", { labId = labId, op = "scale", scale = 50 }).code == "invalid_params"
)
check("move", run("lab.transform", { labId = labId, op = "move", dx = 5, dy = 2, dz = -5 }).ok)
check("reset", run("lab.transform", { labId = labId, op = "reset" }).ok)
check("model scale back to 1", model and math.abs(model:GetScale() - 1) < 0.01)
check("play animation", run("lab.anim", { labId = labId, anim = "Waddle", op = "play", speed = 1.5 }).ok)
check(
	"anim attribute set",
	model and model:GetAttribute("LabAnim") == "Waddle" and model:GetAttribute("AnimSpeed") == 1.5
)
check(
	"egg animation on a pet refused",
	run("lab.anim", { labId = labId, anim = "EggWobble", op = "play" }).code == "invalid_params"
)
check(
	"speed above bound refused",
	run("lab.anim", { labId = labId, anim = "Idle", speed = 10 }).code == "invalid_params"
)
local sack = run("lab.spawn", { source = "sack:5", placement = "platform" })
check("spawn a sack", sack.ok)
check(
	"unrigged sack can't animate",
	sack.ok and run("lab.anim", { labId = sack.data.model.id, anim = "Idle" }).code == "unrigged"
)
check("vfx enable", run("lab.vfx", { labId = labId, op = "enable", effect = "Frost", seconds = 5 }).ok)
task.wait(0.6) -- lab.vfx has a 0.5 s cooldown
check("vfx one-shot", run("lab.vfx", { labId = labId, op = "oneshot", effect = "PetReveal" }).ok)
check(
	"egg one-shot on a pet refused",
	run("lab.vfx", { labId = labId, op = "oneshot", effect = "HatchBurst" }).code == "invalid_params"
)
check(
	"vfx duration bound",
	run("lab.vfx", { labId = labId, op = "enable", effect = "Frost", seconds = 9999 }).code == "invalid_params"
)
local cmp = run("lab.compare", { sourceA = "pet:ice_dragon", sourceB = "egg:ice_dragon" })
check("compare two models", cmp.ok)
local pair = run("lab.pair", { petId = "frost_penguin" })
check("spawn pair", pair.ok or pair.code == "limit")
local limited = false
for _ = 1, 10 do
	local r = run("lab.spawn", { source = "egg:sprout_pup" })
	if r.code == "limit" then
		limited = true
		break
	end
end
check("per-admin model limit", limited)
check("test pen add", run("lab.pen.add", { petId = "sprout_pup", size = "Big" }).ok)
task.wait(0.6) -- lab.pen.add has a 0.5 s cooldown
check("test pen add 2", run("lab.pen.add", { petId = "meadow_stag" }).ok)
task.wait(1)
local penCheck = run("lab.pen.check")
check("test pen check", penCheck.ok and #penCheck.data.pets == 2)
local penPet = lab and lab.Pen:GetChildren()[1]
check(
	"pen pets have no owner / income",
	penPet and penPet:GetAttribute("OwnerUserId") == nil and penPet:GetAttribute("Income") == nil
)
check("vfx demo", run("vfx.demo", { effect = "HatchBurst" }).ok)
task.wait(1.1)
check("clear my models", run("lab.clearMine").ok and #lab.Models:GetChildren() == 0)
local hatchPair = run("lab.pair", { petId = "sprout_pup" })
check("pair for hatching", hatchPair.ok)
if hatchPair.ok then
	local eggId = hatchPair.data.egg.id
	check("hatch only works on eggs", run("lab.hatch", { labId = hatchPair.data.pet.id }).code == "invalid_params")
	task.wait(4.1)
	check("hatch sequence starts", run("lab.hatch", { labId = eggId }).ok)
	task.wait(4)
	local revealed = 0
	for _, mm in lab.Models:GetChildren() do
		if mm:GetAttribute("LabReveal") and mm:GetAttribute("LabKind") == "pet" then
			revealed += 1
		end
	end
	check("egg replaced by its pet with the reveal", lab.Models:FindFirstChild(`Lab_{eggId}`) == nil and revealed == 1)
end

-- 5. weather / events / controls ---------------------------------------------------------------------------------
check("weather start (server)", run("weather.start", { weather = "Rainy", seconds = 30 }).ok)
check("weather really running", WeatherService:GetActive() == "Rainy")
local global = run("weather.start", { weather = "Snowy", seconds = 30, scope = "global", confirmed = true })
check("global weather runs locally", global.ok and WeatherService:GetActive() == "Snowy")
-- an unpublished Studio place has no MessagingService: the result must say so instead of claiming delivery
check(
	"global delivery is honest",
	global.delivery and (global.delivery.status == "unavailable" or global.delivery.status == "failed")
)
print(
	`[AdminStudio] global delivery: {global.delivery and global.delivery.status} ({global.delivery and global.delivery.detail})`
)
check(
	"global cooldown",
	run("weather.start", { weather = "Snowy", seconds = 30, scope = "global", confirmed = true }).code == "cooldown"
)
check(
	"event start (random resolved)",
	run("events.start", { event = "WeatherEvent", variant = "Random", seconds = 20 }).ok
)
check("event stop", run("events.stop", { event = "WeatherEvent" }).ok and WeatherService:GetActive() == nil)
check("flag set", run("flags.set", { flag = "lab.labels", value = false }).ok)
task.wait(1.1) -- flags.set has a 1 s cooldown
check("staging-only flag in Studio ok", run("flags.set", { flag = "staging.labNight", value = true }).ok)
check("unknown flag refused", run("flags.set", { flag = "god.mode", value = true }).code == "invalid_params")

-- 5b. announcements: filtered text + sender on the replicated ServerMessage channel
local channel = ReplicatedStorage:WaitForChild("ServerMessage", 5)
check("message channel exists", channel ~= nil)
check(
	"announcement needs confirmation",
	run("announce.send", { text = "Hello egg kickers!" }).code == "confirm_required"
)
check(
	"client can't set the sender",
	run("announce.send", { text = "Hi", displayName = "Spoofed", confirmed = true }).code == "invalid_params"
)
local ann = run("announce.send", { text = "Hello egg kickers!", confirmed = true })
check("announcement sent", ann.ok)
check(
	"channel carries text and the real sender",
	channel
		and channel:GetAttribute("MsgText") == "Hello egg kickers!"
		and channel:GetAttribute("UserId") == player.UserId
		and channel:GetAttribute("Username") == player.Name
		and channel:GetAttribute("Id") == ann.correlation
)
check(
	"announcement length bound",
	run("announce.send", { text = string.rep("x", 200), confirmed = true }).code == "invalid_params"
)

-- 6. progression (Studio in-memory only) ------------------------------------------------------------------------
local before = DataService:Get(player).money
local persistent = DataService:IsPersistent(player)
local set = run("players.setStat", { userId = player.UserId, stat = "money", value = 12345, confirmed = true })
if persistent then
	check("persistent Studio data is protected", set.code == "data_safety" and DataService:Get(player).money == before)
else
	check("in-memory progression edit", set.ok and DataService:Get(player).money == 12345)
end
check(
	"pen level bound",
	run("players.setStat", { userId = player.UserId, stat = "penLevel", value = 99, confirmed = true }).code ~= "ok"
)
local eggs = #DataService:Get(player).eggs
local g = run("players.giveEgg", { userId = player.UserId, petId = "sprout_pup", confirmed = true })
check("give egg", persistent or (g.ok and #DataService:Get(player).eggs == eggs + 1))

-- 7. cross-server receiver ---------------------------------------------------------------------------------------
local now = os.time()
local function env(over: { [string]: any }?): { [string]: any }
	local e = Envelope.build({
		id = game:GetService("HttpService"):GenerateGUID(false),
		at = now,
		src = "other-server",
		uid = player.UserId,
		name = player.Name,
		cmd = "weather.start",
		p = { weather = "Stormy", seconds = 20 },
	}, Config.CrossServer.ttl)
	for k, v in over or {} do
		e[k] = v
	end
	return e
end
local good = env()
local ok1, why1 = X.receive(good)
check("valid broadcast applied", ok1 and WeatherService:GetActive() == "Stormy")
local _, why2 = X.receive(good)
check("duplicate broadcast rejected", why2 == "duplicate")
local _, why3 = X.receive(env({ at = now - 500, exp = now - 440 }))
check("expired broadcast rejected", why3 == "expired")
local _, why4 = X.receive(env({ uid = 42 }))
check("broadcast from a non-admin rejected", why4 == "unauthorized")
local _, why5 = X.receive(env({ cmd = "lab.clearAll" }))
check("non-global command rejected", why5 == "scope")
local _, why6 = X.receive(env({ cmd = "made.up" }))
check("unknown broadcast command rejected", why6 == "unknown_command")
local _, why7 = X.receive({ v = 1, id = "x", nope = true })
check("malformed broadcast rejected", why7 == "malformed")
local _, why8 = X.receive(env({ p = { weather = "Lava", seconds = 20 } }))
check("broadcast params re-validated", why8 == "invalid_params")
local _, why9 = X.receive(env({ src = require(Server.Admin.Environment).serverId() }))
check("own broadcast ignored", why9 == "self")
local annEnv = env({ cmd = "announce.send", p = { text = "From another server" } })
local okAnn = X.receive(annEnv)
check(
	"global announcement shown on a receiving server",
	okAnn
		and channel
		and channel:GetAttribute("MsgText") == "From another server"
		and channel:GetAttribute("Username") == player.Name
)
print(`[AdminStudio] receiver: {why1} / {why2} / {why3} / {why4} / {why5} / {why6} / {why7} / {why8} / {why9}`)

-- 8. spam ---------------------------------------------------------------------------------------------------------
task.wait(3)
local limitedSpam = 0
for _ = 1, 40 do
	if pipe.execute(player, "lab.list", {}).code == "rate_limited" then
		limitedSpam += 1
	end
end
check("spam rate limited", limitedSpam >= 20)

-- 9. audit --------------------------------------------------------------------------------------------------------
task.wait(3)
local logs = run("logs.query", { outcome = "fail" })
check("failures are audited", logs.ok and logs.data.total > 10)
local unauth = run("logs.query", { text = "Intruder" })
check("unauthorized attempt audited", unauth.ok and unauth.data.total >= 1)

-- cleanup ---------------------------------------------------------------------------------------------------------
task.wait(1)
run("lab.clearAll", { confirmed = true })
run("weather.reset", {})
run("flags.set", { flag = "lab.labels", value = true })
task.wait(1.1)
run("flags.set", { flag = "staging.labNight", value = false })
check("cleanup removed lab models", #lab.Models:GetChildren() == 0 and #lab.Pen:GetChildren() == 0)

local summary = `{passed} passed, {failed} failed{if failed > 0 then ": " .. table.concat(fails, "; ") else ""}`
print(`[AdminStudio] {summary}`)
SSS:SetAttribute("AdminStudioResult", summary)
