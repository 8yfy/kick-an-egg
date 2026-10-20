--!strict
-- Catalog emote IDs wrap Animation assets. Resolve only a winner's equipped emotes; never parent
-- imported catalog containers into the game. NPC playback uses a server-created Animator.
local AssetService = game:GetService("AssetService")
local PodiumEmotes = {}
type Choice = { name: string, id: number }
local random = Random.new()
local resolved: { [number]: string } = {}
local pending: { [number]: BindableEvent } = {}
local order: { number } = {}

function PodiumEmotes.choices(description: HumanoidDescription): { Choice }
	local emotes = description:GetEmotes()
	local choices: { Choice } = {}
	for _, equipped in description:GetEquippedEmotes() do
		local ids = emotes[equipped.Name]
		if typeof(ids) == "table" then
			for _, id in ids do
				if typeof(id) == "number" and id > 0 then
					table.insert(choices, { name = equipped.Name, id = id })
				end
			end
		end
	end
	return choices
end

local function resolve(id: number): string?
	if resolved[id] then
		return resolved[id]
	end
	if pending[id] then
		pending[id].Event:Wait()
		return resolved[id]
	end
	local signal = Instance.new("BindableEvent")
	pending[id] = signal
	local ok, asset = pcall(AssetService.LoadAssetAsync, AssetService, id)
	if ok then
		local animation = asset:FindFirstChildWhichIsA("Animation", true)
		if animation then
			resolved[id] = animation.AnimationId
			table.insert(order, id)
			if #order > 64 then
				resolved[table.remove(order, 1)] = nil
			end
		end
		asset:Destroy()
	end
	pending[id] = nil
	signal:Fire()
	signal:Destroy()
	return resolved[id]
end

function PodiumEmotes.Play(avatar: Model)
	local humanoid = avatar:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local choices = PodiumEmotes.choices(humanoid:GetAppliedDescription())
	if #choices == 0 then
		avatar:SetAttribute("EmoteStatus", "NoneEquipped")
		return
	end
	-- Shuffle the equipped list, so an unavailable asset can fall back to another equipped emote.
	for i = #choices, 2, -1 do
		local j = random:NextInteger(1, i)
		choices[i], choices[j] = choices[j], choices[i]
	end
	avatar:SetAttribute("EmoteStatus", "Loading")
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	for _, choice in choices do
		local animationId = resolve(choice.id)
		if not avatar:IsDescendantOf(workspace) then
			return
		end
		if not animationId then
			continue
		end
		local animation = Instance.new("Animation")
		animation.Name = "PodiumEquippedEmote"
		animation.AnimationId = animationId
		animation.Parent = avatar
		local ok, track = pcall(animator.LoadAnimation, animator, animation)
		if ok then
			track.Looped = true
			track.Priority = Enum.AnimationPriority.Action
			track:Play(0.25)
			local deadline = os.clock() + 5
			while avatar.Parent and track.Length == 0 and os.clock() < deadline do
				task.wait(0.1)
			end
			if avatar.Parent and track.Length > 0 then
				avatar:SetAttribute("EmoteName", choice.name)
				avatar:SetAttribute("EmoteAssetId", choice.id)
				avatar:SetAttribute("EmoteStatus", "Playing")
				-- Different copies can perform the same equipped dance at different phases.
				track.TimePosition = random:NextNumber() * track.Length
				local connection: RBXScriptConnection? = nil
				connection = avatar.Destroying:Connect(function()
					track:Stop(0)
					track:Destroy()
					if connection then
						connection:Disconnect()
					end
				end)
				return
			end
			track:Stop(0)
			track:Destroy()
		end
		animation:Destroy()
	end
	if avatar.Parent then
		avatar:SetAttribute("EmoteStatus", "Unavailable")
	end
end

return PodiumEmotes
