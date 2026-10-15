--!strict
-- Partner A. The player's carried eggs and stored pets, for the custom hotbar (UI/Hud/Hotbar) and the backpack
-- screen (UI/Screens/Bag). You EQUIP items in the Bag; only equipped ones sit on the hotbar (up to `capacity`,
-- set by the hotbar: fewer on phones). New items and a fresh session fill free hotbar slots automatically; the
-- equipped list lives for the session (saving it across rejoins would need a server field). They are the Tools PlotService.syncTools keeps in the Backpack (attributes EggUid /
-- PetUid, ModelKey, Rarity), so the server stays the only source of truth: this only reads them and holds /
-- puts them away like Roblox's own hotbar did (Humanoid:EquipTool). The Kick Sack is not here: it has its own
-- quickslot (UI/Hud/SackSlot) and is handed over by the server, so it is put away first before holding an item.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rarities = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Rarities"))
local SackGear = require(script.Parent.Parent.SackGear)

export type Item = {
	tool: Tool,
	kind: "Egg" | "Pet",
	uid: string,
	key: string, -- Builders/Models key (Config/Pets `model`)
	rarity: string,
	name: string,
	held: boolean,
}

local Backpack = {}

local listeners: { () -> () } = {}
local equipped: { string } = {} -- item uids on the hotbar, in slot order
local known: { [string]: boolean } = {} -- every uid seen this session (new ones auto-fill free slots)
local capacity = 6
local conns: { RBXScriptConnection } = {}
local started = false
local pending = false

local function itemOf(tool: Instance, held: boolean): Item?
	if not tool:IsA("Tool") then
		return nil
	end
	local eggUid, petUid = tool:GetAttribute("EggUid"), tool:GetAttribute("PetUid")
	local uid = eggUid or petUid
	if typeof(uid) ~= "string" then
		return nil
	end
	local key, rarity = tool:GetAttribute("ModelKey"), tool:GetAttribute("Rarity")
	return {
		tool = tool,
		kind = if eggUid then "Egg" else "Pet",
		uid = uid,
		key = if typeof(key) == "string" then key else "",
		rarity = if typeof(rarity) == "string" then rarity else "Common",
		name = tool.Name,
		held = held,
	}
end

local function rank(rarity: string): number
	local r = Rarities[rarity]
	return if r then r.order else 0
end

-- Eggs first, then pets; rarest first, then by name. Holding an item doesn't move it (stable hotbar keys).
function Backpack.items(): { Item }
	local me = Players.LocalPlayer
	local out: { Item } = {}
	local bag = me:FindFirstChildOfClass("Backpack")
	if bag then
		for _, t in bag:GetChildren() do
			local item = itemOf(t, false)
			if item then
				table.insert(out, item)
			end
		end
	end
	local character = me.Character
	if character then
		for _, t in character:GetChildren() do
			local item = itemOf(t, true)
			if item then
				table.insert(out, item)
			end
		end
	end
	table.sort(out, function(a: Item, b: Item)
		if a.kind ~= b.kind then
			return a.kind == "Egg"
		end
		if rank(a.rarity) ~= rank(b.rarity) then
			return rank(a.rarity) > rank(b.rarity)
		end
		if a.name ~= b.name then
			return a.name < b.name
		end
		return a.uid < b.uid
	end)
	return out
end

-- Hold `item` (in hand already = put it away). Nil = put away whatever is held.
function Backpack.hold(item: Item?)
	local me = Players.LocalPlayer
	local character = me.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	if item == nil or item.held then
		humanoid:UnequipTools()
		return
	end
	local tool = item.tool
	task.spawn(function()
		local _, sackOut = SackGear.tool()
		if sackOut then
			SackGear.toggle() -- the server takes the sack back; wait for it so the egg doesn't knock it into the Backpack
			local t0 = os.clock()
			repeat
				task.wait()
				_, sackOut = SackGear.tool()
			until not sackOut or os.clock() - t0 > 1.5
		end
		local bag = me:FindFirstChildOfClass("Backpack")
		if humanoid.Parent and (tool.Parent == bag or tool.Parent == character) then
			humanoid:EquipTool(tool)
		end
	end)
end

-- Drops equipped uids that are gone (placed, sold, traded) and puts new items into free slots.
local function reconcile()
	local present: { [string]: boolean } = {}
	local items = Backpack.items()
	for _, item in items do
		present[item.uid] = true
	end
	for i = #equipped, 1, -1 do
		if not present[equipped[i]] then
			table.remove(equipped, i)
		end
	end
	for _, item in items do
		if not known[item.uid] then
			known[item.uid] = true
			if #equipped < capacity and not table.find(equipped, item.uid) then
				table.insert(equipped, item.uid)
			end
		end
	end
end

local function fire()
	if pending then
		return
	end
	pending = true
	task.defer(function()
		pending = false
		reconcile()
		for _, fn in listeners do
			task.spawn(fn)
		end
	end)
end

-- How many items fit on the hotbar (the hotbar sets this; phones show fewer). Extra equipped items stay
-- equipped but only the first `n` are shown.
function Backpack.setCapacity(n: number)
	capacity = n
end

function Backpack.capacity(): number
	return capacity
end

-- The hotbar's items, in slot order (only items you still have).
function Backpack.equipped(): { Item }
	local byUid: { [string]: Item } = {}
	for _, item in Backpack.items() do
		byUid[item.uid] = item
	end
	local out: { Item } = {}
	for _, uid in equipped do
		local item = byUid[uid]
		if item and #out < capacity then
			table.insert(out, item)
		end
	end
	return out
end

-- Hotbar slot of an item (1-based among items), or nil if not equipped.
function Backpack.slotOf(uid: string): number?
	return table.find(equipped, uid)
end

-- Equip (put on the hotbar) / unequip. Returns false + a reason when the hotbar is full.
function Backpack.toggleEquip(item: Item): (boolean, string?)
	local i = table.find(equipped, item.uid)
	if i then
		table.remove(equipped, i)
		if item.held then
			Backpack.hold(nil) -- off the hotbar = out of your hands
		end
	elseif #equipped >= capacity then
		return false, `Your hotbar is full ({capacity}). Unequip something first.`
	else
		table.insert(equipped, item.uid)
	end
	fire()
	return true, nil
end

local function bind()
	for _, c in conns do
		c:Disconnect()
	end
	table.clear(conns)
	local me = Players.LocalPlayer
	for _, holder in { me:FindFirstChildOfClass("Backpack") :: Instance?, me.Character :: Instance? } do
		if holder then
			table.insert(conns, holder.ChildAdded:Connect(fire))
			table.insert(conns, holder.ChildRemoved:Connect(fire))
		end
	end
	fire()
end

-- Calls fn whenever an item is added, removed, held or put away (batched per frame), and after respawns.
function Backpack.onChanged(fn: () -> ())
	table.insert(listeners, fn)
	if started then
		return
	end
	started = true
	local me = Players.LocalPlayer
	me.CharacterAdded:Connect(function()
		task.defer(bind)
	end)
	me.ChildAdded:Connect(function(child)
		if child:IsA("Backpack") then
			bind()
		end
	end)
	bind()
end

return Backpack
