--!strict
-- Registered feature flags (server). Only flags listed here exist; the admin panel can flip them (per server, or
-- on all live servers with an expiring MemoryStore copy so new servers pick them up). The game has no flag system
-- of its own yet, so every flag here only affects the admin tools; staging-only experiments are marked with
-- `environments`. Values are booleans.

export type Flag = {
	name: string,
	description: string,
	default: boolean,
	environments: { string }?,
}

local Flags = {}

Flags.Registry = table.freeze({
	["lab.labels"] = table.freeze({
		name = "Lab name tags",
		description = "Floating name and version tags over Model Lab models.",
		default = true,
	}),
	["announce.global"] = table.freeze({
		name = "Global announcements",
		description = "Kill switch: when off, announcements only reach the server that sent them.",
		default = true,
	}),
	["staging.labNight"] = table.freeze({
		name = "Experiment: lab night lighting",
		description = "Dims the compare spotlights to preview models in low light. Studio and staging only.",
		default = false,
		environments = table.freeze({ "studio", "staging" }),
	}),
}) :: { [string]: Flag }

local values: { [string]: boolean } = {}
local listeners: { (string, boolean) -> () } = {}

function Flags.ids(): { string }
	local ids = {}
	for id in Flags.Registry do
		table.insert(ids, id)
	end
	table.sort(ids)
	return ids
end

function Flags.get(id: string): boolean
	local v = values[id]
	if v ~= nil then
		return v
	end
	local f = Flags.Registry[id]
	return f ~= nil and f.default
end

function Flags.set(id: string, value: boolean): boolean
	if not Flags.Registry[id] or typeof(value) ~= "boolean" then
		return false
	end
	values[id] = value
	for _, fn in listeners do
		task.spawn(fn, id, value)
	end
	return true
end

function Flags.reset()
	for id in table.clone(values) do
		values[id] = nil
		for _, fn in listeners do
			task.spawn(fn, id, Flags.get(id))
		end
	end
end

function Flags.onChanged(fn: (string, boolean) -> ())
	table.insert(listeners, fn)
end

function Flags.list(): { { [string]: any } }
	local list = {}
	for _, id in Flags.ids() do
		local f = Flags.Registry[id]
		table.insert(list, {
			id = id,
			name = f.name,
			description = f.description,
			default = f.default,
			value = Flags.get(id),
			environments = f.environments,
		})
	end
	return list
end

return Flags
