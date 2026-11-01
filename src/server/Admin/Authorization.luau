--!strict
-- Pure (no Roblox services, no requires): who is an admin and what they may do. Built once at server start from
-- the server-only Allowlist and Config.Roles, then frozen. Unknown UserId, unknown role or unknown permission
-- => deny. There is no setter: roles can't be granted, edited or escalated while the server runs.

export type Role = { rank: number, permissions: { [string]: boolean }, color: string }
export type Allowlist = { users: { [number]: string }, studioTestUsers: { [number]: string }? }

export type Authorization = {
	roleOf: (userId: any) -> string?,
	can: (role: string?, permission: string) -> boolean,
	rank: (role: string?) -> number,
	permissionsOf: (role: string?) -> { string },
	count: () -> number,
	rejected: { string },
}

local Authorization = {}

local function isUserId(value: any): boolean
	return typeof(value) == "number" and value == value and value % 1 == 0 and math.abs(value) < 2 ^ 53
end

-- `isStudio` must come from the server's own RunService:IsStudio(); it only unlocks the negative test ids.
function Authorization.new(allowlist: Allowlist, roles: { [string]: Role }, isStudio: boolean): Authorization
	local users: { [number]: string } = {}
	local rejected: { string } = {}
	local count = 0
	local function add(list: { [number]: string }?, testIds: boolean)
		for id, role in list or {} do
			local valid = isUserId(id) and typeof(role) == "string" and roles[role] ~= nil
			local rightSign = if testIds then (id :: number) < 0 else (id :: number) > 0
			if valid and rightSign then
				users[id :: number] = role
				count += 1
			else
				table.insert(rejected, `{tostring(id)}={tostring(role)}`)
			end
		end
	end
	add(allowlist.users, false)
	if isStudio then
		add(allowlist.studioTestUsers, true)
	end
	table.freeze(users)

	local auth = {}
	auth.rejected = table.freeze(rejected)
	function auth.roleOf(userId: any): string?
		if not isUserId(userId) then
			return nil
		end
		return users[userId]
	end
	function auth.can(role: string?, permission: string): boolean
		if typeof(role) ~= "string" or typeof(permission) ~= "string" then
			return false
		end
		local r = roles[role]
		return r ~= nil and r.permissions[permission] == true
	end
	function auth.rank(role: string?): number
		local r = if typeof(role) == "string" then roles[role] else nil
		return if r then r.rank else 0
	end
	function auth.permissionsOf(role: string?): { string }
		local r = if typeof(role) == "string" then roles[role] else nil
		local list = {}
		for name in if r then r.permissions else {} do
			table.insert(list, name)
		end
		table.sort(list)
		return list
	end
	function auth.count(): number
		return count
	end
	return table.freeze(auth) :: any
end

return table.freeze(Authorization)
