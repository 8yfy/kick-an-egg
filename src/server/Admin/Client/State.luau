--!strict
-- Shared client state between the admin tabs: the session metadata from "session.hello", the action scope
-- chosen in the header, the selected lab model and the latest lab model list. Tabs subscribe with on().

local State = {}

State.meta = {} :: { [string]: any }
State.scope = "server"
State.selected = nil :: string?
State.models = {} :: { { [string]: any } }
State.prefs = { hotkey = "F2", reducedMotion = false, scale = 1 }

local listeners: { [string]: { (any) -> () } } = {}

function State.on(event: string, fn: (any) -> ())
	listeners[event] = listeners[event] or {}
	table.insert(listeners[event], fn)
end

function State.emit(event: string, value: any)
	for _, fn in listeners[event] or {} do
		task.spawn(fn, value)
	end
end

function State.can(permission: string): boolean
	return table.find(State.meta.permissions or {}, permission) ~= nil
end

function State.command(id: string): { [string]: any }?
	for _, c in State.meta.commands or {} do
		if c.id == id then
			return c
		end
	end
	return nil
end

-- Whether `id` may run with the current header scope ("global" needs that command's global permission).
function State.scopeFor(id: string): string
	local c = State.command(id)
	if State.scope == "global" and c and table.find(c.scopes, "global") then
		return "global"
	end
	return "server"
end

function State.select(id: string?)
	State.selected = id
	State.emit("selected", id)
end

function State.setModels(list: { { [string]: any } })
	State.models = list
	if State.selected then
		local still = false
		for _, m in list do
			if m.id == State.selected then
				still = true
				break
			end
		end
		if not still then
			State.selected = nil
			State.emit("selected", nil)
		end
	end
	State.emit("models", list)
end

function State.model(id: string?): { [string]: any }?
	for _, m in State.models do
		if m.id == id then
			return m
		end
	end
	return nil
end

return State
