--!strict
-- Arc-length sampling keeps a complete trail ahead of the player, independent of navmesh waypoint density.
local Route = {}

function Route.frame(position: Vector3, direction: Vector3): CFrame
	local forward = Vector3.new(direction.X, 0, direction.Z)
	forward = if forward.Magnitude > 0.001 then forward.Unit else Vector3.zAxis
	return CFrame.fromMatrix(position, Vector3.yAxis:Cross(forward), forward, -Vector3.yAxis)
end

function Route.length(points: { Vector3 }): number
	local length = 0
	for i = 2, #points do
		length += (points[i] - points[i - 1]).Magnitude
	end
	return length
end

function Route.sample(points: { Vector3 }, distance: number): (Vector3?, Vector3?)
	for i = 2, #points do
		local a, b = points[i - 1], points[i]
		local delta = b - a
		local length = delta.Magnitude
		if length > 0.001 then
			if distance <= length or i == #points then
				return a:Lerp(b, math.clamp(distance / length, 0, 1)), delta.Unit
			end
			distance -= length
		end
	end
	return nil, nil
end

-- Forget points already passed. Reconnect from today's position, never the last path request's origin.
function Route.ahead(origin: Vector3, points: { Vector3 }): ({ Vector3 }, number)
	local nearest, nextIndex = math.huge, 2
	for i = 2, #points do
		local a, b = points[i - 1], points[i]
		local ab = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
		local offset = Vector3.new(origin.X - a.X, 0, origin.Z - a.Z)
		local fraction = if ab:Dot(ab) > 0.001 then math.clamp(offset:Dot(ab) / ab:Dot(ab), 0, 1) else 0
		local distance = (offset - ab * fraction).Magnitude
		if distance <= nearest then
			nearest, nextIndex = distance, i
		end
	end
	local tail = { origin }
	for i = nextIndex, #points do
		if (points[i] - tail[#tail]).Magnitude > 0.05 then
			table.insert(tail, points[i])
		end
	end
	return tail, nearest
end

-- Only skip corners when the actual character-width corridor is clear.
function Route.simplify(points: { Vector3 }, clear: (Vector3, Vector3) -> boolean): { Vector3 }
	if #points < 3 then
		return points
	end
	local result, index = { points[1] }, 1
	while index < #points do
		local nextIndex = index + 1
		for j = #points, index + 2, -1 do
			if clear(points[index], points[j]) then
				nextIndex = j
				break
			end
		end
		table.insert(result, points[nextIndex])
		index = nextIndex
	end
	return result
end

function Route.valid(points: { Vector3 }, clear: (Vector3, Vector3) -> boolean): boolean
	if #points < 2 then
		return false
	end
	for i = 2, #points do
		if not clear(points[i - 1], points[i]) or not clear(points[i], points[i - 1]) then
			return false
		end
	end
	return true
end

-- Reserve space at the feet, then cover the entire route to its target within a fixed part budget.
function Route.spacing(length: number, capacity: number): (number, number)
	local lead = math.min(3.5, length)
	return lead, math.max(4.8, (length - lead) / math.max(1, capacity - 1))
end

return Route
