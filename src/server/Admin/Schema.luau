--!strict
-- Pure (no Roblox services, no requires): parameter schemas for admin commands. Everything a client sends is
-- untrusted: only declared keys, only scalar values of the declared type, numbers finite and inside their bounds,
-- strings short with no control characters, enums only from the server's own option list. Out-of-range values
-- are rejected (never silently clamped), so the audit log always shows what was really run.

export type Spec = {
	type: "number" | "string" | "boolean" | "enum" | "userId",
	label: string?,
	description: string?,
	optional: boolean?,
	default: any?,
	order: number?,
	min: number?,
	max: number?,
	integer: boolean?,
	step: number?,
	minLength: number?,
	maxLength: number?,
	pattern: string?, -- Lua pattern the whole string must match (anchor it with ^ and $)
	options: ({ string } | () -> { string })?,
	searchable: boolean?, -- UI hint: long enum lists get a search box
}
export type Specs = { [string]: Spec }
export type Limits = { maxKeys: number, maxString: number }

local Schema = {}

Schema.RESERVED = table.freeze({ scope = true, confirmed = true })
local MAX_OPTIONS = 400

local function finite(n: any): boolean
	return typeof(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

function Schema.options(spec: Spec): { string }
	local o = spec.options
	if typeof(o) == "function" then
		local ok, list = pcall(o)
		return if ok and typeof(list) == "table" then list else {}
	end
	return if typeof(o) == "table" then o else {}
end

local function checkOne(name: string, spec: Spec, value: any, limits: Limits): (boolean, any)
	local kind = spec.type
	if kind == "number" or kind == "userId" then
		if not finite(value) then
			return false, `{name} must be a number`
		end
		if (spec.integer or kind == "userId") and value % 1 ~= 0 then
			return false, `{name} must be a whole number`
		end
		if kind == "userId" and (value == 0 or math.abs(value) >= 2 ^ 53) then
			return false, `{name} is not a valid UserId`
		end
		if spec.min and value < spec.min then
			return false, `{name} must be at least {spec.min}`
		end
		if spec.max and value > spec.max then
			return false, `{name} must be at most {spec.max}`
		end
		return true, value
	elseif kind == "boolean" then
		if typeof(value) ~= "boolean" then
			return false, `{name} must be true or false`
		end
		return true, value
	elseif kind == "string" or kind == "enum" then
		if typeof(value) ~= "string" then
			return false, `{name} must be text`
		end
		local cap = math.min(spec.maxLength or limits.maxString, limits.maxString)
		if #value > cap or utf8.len(value) == nil then
			return false, `{name} is too long or not valid text`
		end
		if string.find(value, "%c") then
			return false, `{name} contains control characters`
		end
		if kind == "enum" then
			for _, option in Schema.options(spec) do
				if option == value then
					return true, value
				end
			end
			return false, `{name} is not one of the allowed values`
		end
		if spec.minLength and (utf8.len(value) :: number) < spec.minLength then
			return false, `{name} must be at least {spec.minLength} characters`
		end
		if spec.pattern and not string.match(value, spec.pattern) then
			return false, `{name} has an invalid format`
		end
		return true, value
	end
	return false, `{name} has an unknown type`
end

-- Returns (true, clean) with defaults applied, or (false, message). Reserved keys (scope, confirmed) are
-- skipped here; the Pipeline reads them itself.
function Schema.validate(specs: Specs?, params: any, limits: Limits): (boolean, any)
	if params == nil then
		params = {}
	end
	if typeof(params) ~= "table" or getmetatable(params) ~= nil then
		return false, "parameters must be a plain table"
	end
	local declared: Specs = specs or {}
	local clean = {}
	local keys = 0
	for key, value in params do
		keys += 1
		if keys > limits.maxKeys then
			return false, "too many parameters"
		end
		if typeof(key) ~= "string" or #key > 32 then
			return false, "invalid parameter name"
		end
		if Schema.RESERVED[key] then
			continue
		end
		local spec = declared[key]
		if not spec then
			return false, `unknown parameter "{key}"`
		end
		local ok, result = checkOne(key, spec, value, limits)
		if not ok then
			return false, result
		end
		clean[key] = result
	end
	for name, spec in declared do
		if clean[name] == nil then
			if spec.default ~= nil then
				clean[name] = spec.default
			elseif not spec.optional then
				return false, `{name} is required`
			end
		end
	end
	return true, clean
end

-- Client-safe description of a schema (types, bounds, labels and resolved enum options).
function Schema.describe(specs: Specs?): { { [string]: any } }
	local list = {}
	for name, spec in specs or {} do
		local options: { string }? = nil
		if spec.type == "enum" then
			local all = Schema.options(spec)
			options = table.move(all, 1, math.min(#all, MAX_OPTIONS), 1, {})
		end
		table.insert(list, {
			name = name,
			type = spec.type,
			label = spec.label or name,
			description = spec.description,
			optional = spec.optional == true,
			default = spec.default,
			order = spec.order or 100,
			min = spec.min,
			max = spec.max,
			integer = spec.integer,
			step = spec.step,
			maxLength = spec.maxLength,
			options = options,
			searchable = spec.searchable or (options ~= nil and #options > 12),
		})
	end
	table.sort(list, function(a, b)
		if a.order ~= b.order then
			return a.order < b.order
		end
		return a.name < b.name
	end)
	return list
end

-- Startup check of a command's schema (a programming error here stops the admin system, not the game).
function Schema.check(specs: Specs?): (boolean, string?)
	for name, spec in specs or {} do
		if Schema.RESERVED[name] then
			return false, `{name} is reserved`
		end
		local t = spec.type
		if t ~= "number" and t ~= "string" and t ~= "boolean" and t ~= "enum" and t ~= "userId" then
			return false, `{name}: unknown type {tostring(t)}`
		end
		if t == "number" and not (finite(spec.min) and finite(spec.max)) then
			return false, `{name}: numbers need finite min and max`
		end
		if t == "string" and not finite(spec.maxLength) then
			return false, `{name}: strings need maxLength`
		end
		if t == "enum" and spec.options == nil then
			return false, `{name}: enums need options`
		end
	end
	return true, nil
end

return table.freeze(Schema)
