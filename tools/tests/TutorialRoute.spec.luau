-- Real route geometry with Roblox vectors. No services, fake rewards or render-loop implementation mocks.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local Vector3, CFrame = roblox.Vector3, roblox.CFrame
local R = luau.load(
	fs.readFile("src/client/UI/Tutorial/Route.luau"),
	{ environment = { Vector3 = Vector3, CFrame = CFrame } }
)()
local checks = 0
local function check(name, condition)
	assert(condition, name)
	checks += 1
end
local function near(a, b)
	return (a - b).Magnitude < 0.001
end
local p = Vector3.new
local route = { p(0, 0, 0), p(10, 0, 0), p(10, 0, 30) }
check("full route length includes the turn", math.abs(R.length(route) - 40) < 0.001)
local at, direction = R.sample(route, 15)
check("samples by distance beyond first segment", near(at, p(10, 0, 5)))
check("arrow follows the turn", near(direction, p(0, 0, 1)))
local tail, deviation = R.ahead(p(10, 0, 12), route)
check("passed points disappear", #tail == 2 and near(tail[1], p(10, 0, 12)))
check("remaining route reaches its real endpoint", near(tail[#tail], route[#route]))
check("on-route player has no deviation", deviation < 0.001)
tail, deviation = R.ahead(p(13, 0, 12), route)
check("sideways walking reconnects immediately", near(tail[1], p(13, 0, 12)) and math.abs(deviation - 3) < 0.001)
local short = R.simplify(route, function()
	return true
end)
check("clear routes remove unnecessary waypoints", #short == 2)
local bent = R.simplify(route, function(a, b)
	return a.X == b.X or a.Z == b.Z
end)
check("blocked shortcuts preserve the actual corner", #bent == 3)
check(
	"clear route passes validation",
	R.valid(bent, function()
		return true
	end)
)
check("blocked adjacent segment never becomes a trail", not R.valid(bent, function()
	return false
end))
check("missing route is never considered connected", not R.valid({}, function()
	return true
end))
for _, length in { 2, 40, 160, 420 } do
	local lead, spacing = R.spacing(length, 40)
	local count = math.min(40, math.ceil((length - lead) / spacing) + 1)
	check(`route length {length} stays within budget`, count <= 40)
	check(`route length {length} reaches target`, math.min(length, lead + (count - 1) * spacing) >= length - 0.001)
	check(`route length {length} starts ahead of feet`, lead > 0 and lead <= length)
end
for _, toward in { p(1, 0, 0), p(-1, 0, 0), p(0, 0, 1), p(0, 0, -1), p(1, 0, 1).Unit } do
	local cf = R.frame(Vector3.zero, toward)
	check("front-face PNG points along route", cf.UpVector:Dot(toward) > 0.999)
	check("image surface faces upward", cf.LookVector:Dot(Vector3.yAxis) > 0.999)
end
at = R.sample({ p(0, 0, 0), p(0, 0, 0), p(0, 0, 5) }, 3)
check("duplicate waypoints never create NaN", near(at, p(0, 0, 3)))
check("missing route produces no arrows", R.sample({}, 3) == nil)
print(`Tutorial route: {checks} checks passed`)
