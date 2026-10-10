--!strict
-- Generated from the Kick Sacks remodel (web/sacks.js): tier 4 "Pro Red" (Common).
-- 1 m = 6.5 studs; origin = the hub where the straps meet; front faces -Z. Do not edit by hand:
-- change the web model and re-run the port. Row: name, shape (B block, C cylinder, S ball), size,
-- position, rotation (degrees, XYZ), colour, material, transparency.
type Row = { any }
local function R(
	name: string,
	shape: string,
	size: { number },
	pos: { number },
	rot: { number },
	color: string,
	material: string,
	transparency: number
): Row
	return { name, shape, size, pos, rot, color, material, transparency }
end

-- stylua: ignore start
return {
	hub = 1.16,
	parts = {
		R("body", "C", { 5.59, 2.6, 2.6 }, { 0, -4.42, 0 }, { -180, 0, -90 }, "c81c26", "SmoothPlastic", 0),
		R("cap_bottom", "C", { 0.325, 2.701, 2.701 }, { 0, -7.378, 0 }, { -180, 0, -90 }, "f2f2ee", "SmoothPlastic", 0),
		R("cap_top", "C", { 0.325, 2.715, 2.715 }, { 0, -1.463, 0 }, { -180, 0, -90 }, "f2f2ee", "SmoothPlastic", 0),
		R("cap_top_disc", "C", { 0.091, 2.412, 2.412 }, { 0, -1.255, 0 }, { -180, 0, -90 }, "f2f2ee", "SmoothPlastic", 0),
		R("strap_0", "C", { 1.556, 0.084, 0.084 }, { -0.368, -0.656, -0.368 }, { -151.53, 7.36, -61.53 }, "f2f2ee", "SmoothPlastic", 0),
		R("strap_clip_0", "B", { 0.195, 0.143, 0.195 }, { -0.735, -1.209, -0.735 }, { -180, -45, -180 }, "a8aeb6", "Metal", 0),
		R("strap_1", "C", { 1.556, 0.084, 0.084 }, { -0.368, -0.656, 0.368 }, { 151.53, -7.36, -61.53 }, "f2f2ee", "SmoothPlastic", 0),
		R("strap_clip_1", "B", { 0.195, 0.143, 0.195 }, { -0.735, -1.209, 0.735 }, { 0, -45, 0 }, "a8aeb6", "Metal", 0),
		R("strap_2", "C", { 1.556, 0.084, 0.084 }, { 0.368, -0.656, 0.368 }, { 151.53, 7.36, -118.47 }, "f2f2ee", "SmoothPlastic", 0),
		R("strap_clip_2", "B", { 0.195, 0.143, 0.195 }, { 0.735, -1.209, 0.735 }, { 0, 45, 0 }, "a8aeb6", "Metal", 0),
		R("strap_3", "C", { 1.556, 0.084, 0.084 }, { 0.368, -0.656, -0.368 }, { -151.53, -7.36, -118.47 }, "f2f2ee", "SmoothPlastic", 0),
		R("strap_clip_3", "B", { 0.195, 0.143, 0.195 }, { 0.735, -1.209, -0.735 }, { -180, 45, -180 }, "a8aeb6", "Metal", 0),
		R("hub_ring", "B", { 0.436, 0.436, 0.098 }, { 0, 0, 0 }, { -180, 0, -180 }, "a8aeb6", "Metal", 0),
		R("swivel", "C", { 0.325, 0.189, 0.189 }, { 0, 0.26, 0 }, { -180, 0, -90 }, "a8aeb6", "Metal", 0),
		R("chain_link_0", "B", { 0.306, 0.443, 0.072 }, { 0, 0.585, 0 }, { -180, 0, -180 }, "a8aeb6", "Metal", 0),
		R("chain_link_1", "B", { 0.306, 0.443, 0.072 }, { 0, 0.926, 0 }, { 0, -90, 0 }, "a8aeb6", "Metal", 0),
		R("chain_link_2", "B", { 0.306, 0.443, 0.072 }, { 0, 1.268, 0 }, { -180, 0, -180 }, "a8aeb6", "Metal", 0),
		R("chain_link_3", "B", { 0.306, 0.443, 0.072 }, { 0, 1.609, 0 }, { 0, -90, 0 }, "a8aeb6", "Metal", 0),
		R("chain_link_4", "B", { 0.306, 0.443, 0.072 }, { 0, 1.95, 0 }, { -180, 0, -180 }, "a8aeb6", "Metal", 0),
		R("chain_link_5", "B", { 0.306, 0.443, 0.072 }, { 0, 2.291, 0 }, { 0, -90, 0 }, "a8aeb6", "Metal", 0),
		R("chain_link_6", "B", { 0.306, 0.443, 0.072 }, { 0, 2.633, 0 }, { -180, 0, -180 }, "a8aeb6", "Metal", 0),
		R("chain_link_7", "B", { 0.306, 0.443, 0.072 }, { 0, 2.974, 0 }, { 0, -90, 0 }, "a8aeb6", "Metal", 0),
		R("gold_band_0", "C", { 0.156, 2.808, 2.808 }, { 0, -6.11, 0 }, { -90, 90, 0 }, "e2b44a", "Metal", 0),
		R("gold_band_1", "C", { 0.156, 2.808, 2.808 }, { 0, -2.73, 0 }, { -90, 90, 0 }, "e2b44a", "Metal", 0),
		R("white_stripe_0", "C", { 0.195, 2.639, 2.639 }, { 0, -6.89, 0 }, { -180, 0, -90 }, "f2f2ee", "SmoothPlastic", 0),
		R("white_stripe_1", "C", { 0.195, 2.639, 2.639 }, { 0, -1.95, 0 }, { -180, 0, -90 }, "f2f2ee", "SmoothPlastic", 0),
		R("badge_ring", "C", { 0.078, 1.014, 1.014 }, { 0, -4.42, -1.352 }, { 90, 0, -90 }, "e2b44a", "Metal", 0),
		R("badge_disc", "C", { 0.104, 0.91, 0.91 }, { 0, -4.42, -1.365 }, { 90, 0, -90 }, "f2f2ee", "SmoothPlastic", 0),
		R("badge_star", "B", { 0.358, 0.179, 0.091 }, { 0, -4.241, -1.449 }, { -180, 0, -90 }, "c81c26", "SmoothPlastic", 0),
		R("badge_star", "B", { 0.45, 0.226, 0.091 }, { 0.17, -4.365, -1.449 }, { -180, 0, -18 }, "c81c26", "SmoothPlastic", 0),
		R("badge_star", "B", { 0.499, 0.251, 0.091 }, { 0.105, -4.565, -1.449 }, { -180, 0, 54 }, "c81c26", "SmoothPlastic", 0),
		R("badge_star", "B", { 0.499, 0.251, 0.091 }, { -0.105, -4.565, -1.449 }, { -180, 0, 126 }, "c81c26", "SmoothPlastic", 0),
		R("badge_star", "B", { 0.45, 0.226, 0.091 }, { -0.17, -4.365, -1.449 }, { -180, 0, -162 }, "c81c26", "SmoothPlastic", 0),
		R("badge_star", "C", { 0.091, 0.328, 0.328 }, { 0, -4.42, -1.449 }, { 0, 90, 0 }, "c81c26", "SmoothPlastic", 0),
		R("badge_core", "C", { 0.13, 0.234, 0.234 }, { 0, -4.42, -1.482 }, { 90, 0, -90 }, "e2b44a", "Metal", 0),
	},
}
-- stylua: ignore end
