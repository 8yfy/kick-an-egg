--!strict
-- Partner A. Zone compositions by Config/Zones id: fn(zone, zoneFolder) builds the valley around that zone's track
-- (World/Valley helpers + World/Kit brick models).
local Zones: { [number]: (any, Instance) -> () } = {
	[1] = require(script.Z01Meadow),
	[2] = require(script.Z02Beach),
	[3] = require(script.Z03Autumn),
	[4] = require(script.Z04Mushroom),
	[5] = require(script.Z05Desert),
	[6] = require(script.Z06Snow),
	[7] = require(script.Z07Candy),
	[8] = require(script.Z08Coral),
	[9] = require(script.Z09Volcano),
	[10] = require(script.Z10Crystal),
	[11] = require(script.Z11Jungle),
	[12] = require(script.Z12Neon),
	[13] = require(script.Z13Haunted),
	[14] = require(script.Z14Sky),
	[15] = require(script.Z15Swamp),
	[16] = require(script.Z16Clockwork),
	[17] = require(script.Z17Aurora),
	[18] = require(script.Z18LavaCore),
	[19] = require(script.Z19Galaxy),
	[20] = require(script.Z20Rainbow),
}

return Zones
