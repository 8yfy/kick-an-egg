--!strict
-- The kick pad (workspace.Map.KickPad): where the contextual KICK controls show (client, UI/Hud/KickPanel) and
-- where kicks are accepted (server, KickService). Both use the same pad part, so they can't drift apart; the
-- server allows a little more room for latency. Without a map (test places) everything counts as on the pad.
local KickPad = {}

KickPad.SHOW_RADIUS = 9 -- studs (XZ) from the pad centre: the client shows KICK inside this
KickPad.ACCEPT_RADIUS = 12 -- studs (XZ): the server accepts a kick inside this (latency slack)
KickPad.HEIGHT = 10 -- studs above / below the pad top that still count

function KickPad.part(): BasePart?
	local map = workspace:FindFirstChild("Map")
	local pad = map and map:FindFirstChild("KickPad")
	return if pad and pad:IsA("BasePart") then pad else nil
end

-- True when `pos` is within `radius` studs (XZ) of the pad centre and near its height.
function KickPad.contains(pos: Vector3, radius: number): boolean
	local pad = KickPad.part()
	if not pad then
		return true
	end
	local d = pos - pad.Position
	return Vector2.new(d.X, d.Z).Magnitude <= radius and math.abs(d.Y) <= KickPad.HEIGHT
end

-- Is this character standing on the pad (radius = SHOW_RADIUS on clients, ACCEPT_RADIUS on the server)?
function KickPad.has(character: Model?, radius: number): boolean
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return KickPad.part() == nil
	end
	return KickPad.contains(root.Position, radius)
end

return KickPad
