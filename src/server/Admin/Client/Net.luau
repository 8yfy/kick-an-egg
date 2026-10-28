--!strict
-- The admin client's only way to the server: the per-admin RemoteFunction "Bridge" the server put next to this
-- code. The client sends a registered command id + params and gets the pipeline's safe result back. Nothing here
-- is trusted by the server; this module only adds a little politeness (no duplicate in-flight reads).

local Net = {}

local bridge: RemoteFunction = nil :: any
local inFlight: { [string]: boolean } = {}

function Net.init(remote: RemoteFunction)
	bridge = remote
end

export type Result = {
	ok: boolean,
	code: string,
	message: string,
	data: any?,
	delivery: any?,
	correlation: string?,
	at: number?,
}

-- Yields. Never throws: transport failures come back as { ok = false, code = "network" }.
function Net.request(command: string, params: { [string]: any }?): Result
	local ok, res = pcall(function()
		return bridge:InvokeServer(command, params or {})
	end)
	if not ok or typeof(res) ~= "table" then
		return { ok = false, code = "network", message = "The server didn't answer." }
	end
	return res :: Result
end

-- For polling reads: skips the call if the same read is still running (returns nil then).
function Net.poll(command: string, params: { [string]: any }?): Result?
	local key = command
	if inFlight[key] then
		return nil
	end
	inFlight[key] = true
	local res = Net.request(command, params)
	inFlight[key] = nil
	return res
end

return Net
