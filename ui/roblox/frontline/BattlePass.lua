-- FRONTLINE / Battle pass: season header, tier track with free and premium rows, claimed/next/locked states, upsell.
return function(K, parent: Instance, P: { [string]: any })
	K.use("frontline")
	local T = K.T
	local g, root = K.screen("FL_BattlePass", parent)
	K.backdrop(root, { glow = T.accent, glowAt = UDim2.fromScale(0.78, 0.25), glowSize = 1400, glowStrength = 0.82 })
	K.topbar(root, "FRONTLINE", { "Play", "Loadout", "Armory", "Store", "Pass" }, 5,
		{ { "coins", "84,210", T.accent, false }, { "gem", "2,400", T.accent2, true } }, P)

	-- season header
	local head = K.new("Frame", root, { Position = UDim2.fromOffset(56, 124), Size = UDim2.fromOffset(1808, 230) })
	K.pill(head, "Season 4  ·  31 days left", T.accent, { Position = UDim2.fromOffset(0, 0) }, true)
	K.text(head, "IRON TIDE", "display", { TextSize = 80, Position = UDim2.fromOffset(-4, 34) })
	K.text(head, "Dockyard operations. 60 tiers, 2 operators, 1 mythic finisher.", "body", { Position = UDim2.fromOffset(0, 136), TextColor3 = T.muted, TextSize = 19 })
	local tier = K.new("Frame", head, { Position = UDim2.fromOffset(0, 176), Size = UDim2.fromOffset(780, 50) })
	K.text(tier, 'TIER <font size="34">23</font>', "display", { TextSize = 20 })
	K.bar(tier, { Size = UDim2.fromOffset(500, 8), Position = UDim2.fromOffset(170, 20) }, 0.64, T.accent, { round = false, ticks = 10 })
	K.text(tier, "6,400 / 10,000 XP", "mono", { Position = UDim2.fromOffset(690, 10), TextSize = 14, TextColor3 = T.muted })
	local up = K.panel(head, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(520, 220) }, { alpha = 0.08, color = T.raised, chamfer = 18, corners = "tl br", borderColor = T.accent, borderAlpha = 0.3 })
	K.pad(up, 24, 28)
	K.icon(up, "crown", 34, T.accent, {})
	K.text(up, "PREMIUM PASS", "title", { Position = UDim2.fromOffset(48, 2), TextSize = 26 })
	K.text(up, "Unlock every premium reward you have already\nearned (22 items) and 60 more as you level.", "body", { Position = UDim2.fromOffset(0, 48), TextSize = 16, TextColor3 = T.muted })
	local ub = K.new("Frame", up, { Position = UDim2.fromOffset(0, 112), Size = UDim2.new(1, 0, 0, 56) })
	K.list(ub, "x", 12, "Left", "Center")
	K.button(ub, "950", "primary", { LayoutOrder = 0, Size = UDim2.fromOffset(200, 56) }, { icon = "gem", under = T.raised })
	K.button(ub, "+25 tiers", "secondary", { LayoutOrder = 1, Size = UDim2.fromOffset(200, 56) }, { textSize = 16, under = T.raised })

	-- tier track
	local track = K.new("Frame", root, { Position = UDim2.fromOffset(56, 384), Size = UDim2.fromOffset(1808, 560), ClipsDescendants = true })
	K.text(track, "FREE", "label", { Position = UDim2.fromOffset(0, 150), TextColor3 = T.muted, Rotation = -90 })
	K.text(track, "PREMIUM", "label", { Position = UDim2.fromOffset(-10, 380), TextColor3 = T.accent, Rotation = -90 })
	local cols = K.new("Frame", track, { Position = UDim2.fromOffset(60, 0), Size = UDim2.new(1, -60, 1, 0) })
	K.list(cols, "x", 12)
	local rewards = {
		{ 20, { "coins", "2,000", "common" }, { "shirt", "Ghillie", "epic" } },
		{ 21, { "ticket", "XP boost", "uncommon" }, { "skull", "Calling card", "rare" } },
		{ 22, { "coins", "2,500", "common" }, { "launcher", "RK-7 Rust", "epic", true } },
		{ 23, { "box", "Supply crate", "rare" }, { "sparkles", "Tracers", "legendary" } },
		{ 24, nil, { "gem", "300 gems", "rare" } },
		{ 25, { "medal", "Emblem", "uncommon" }, { "user", "Operator: Vela", "legendary" } },
		{ 26, { "coins", "3,000", "common" }, { "grenade", "Frag Tiger", "rare", true } },
		{ 27, { "ticket", "XP boost", "uncommon" }, { "flame", "Kill effect", "epic" } },
	}
	for i, r in rewards do
		local n, cur = r[1], r[1] == 23
		local done, locked = n < 23, n > 23
		local c = K.new("Frame", cols, { Size = UDim2.fromOffset(206, 560), LayoutOrder = i })
		local num = K.new("Frame", c, { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = cur and 0 or 1, BackgroundColor3 = T.accent })
		K.text(num, tostring(n), "display", { TextSize = 20, Size = UDim2.fromScale(1, 1), AutomaticSize = Enum.AutomaticSize.None, TextXAlignment = Enum.TextXAlignment.Center,
			TextColor3 = cur and T.accentInk or (done and T.text or T.muted) })
		local function cell(y: number, h: number, rew: { any }?, premium: boolean)
			if not rew then
				K.panel(c, { Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, 0, 0, h) }, { alpha = 0.75, sheen = false, borderAlpha = 0.94 })
				return
			end
			local isArt = rew[4]
			local s = K.slot(c, { Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, 0, 0, h) },
				{ art = isArt and rew[1] or nil, icon = not isArt and rew[1] or nil, rarity = rew[3], iconColor = K.RARITY[rew[3]][1], iconSize = 52, selected = cur, equipped = done and not premium,
					badgeLock = premium, artScale = rew[1] == "grenade" and 0.5 or 0.9 })
			K.text(s, rew[2], "label", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12), TextColor3 = T.text, TextSize = 12, ZIndex = 7 })
		end
		cell(52, 200, r[2], false)
		cell(264, 280, r[3], true)
	end
	-- progress rail under the tier numbers
	local rail = K.new("Frame", track, { Position = UDim2.fromOffset(60, 44), Size = UDim2.new(1, -60, 0, 3), BackgroundTransparency = 0.8, BackgroundColor3 = T.text })
	K.new("Frame", rail, { Size = UDim2.fromOffset(3 * 218 + 103, 3), BackgroundTransparency = 0, BackgroundColor3 = T.accent })
	local fadeR = K.new("Frame", track, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 200, 1, 0), BackgroundTransparency = 0, BackgroundColor3 = T.bg, ZIndex = 20 })
	K.grad(fadeR, { T.bg, T.bg }, 0, { 1, 0 })

	local nav = K.new("Frame", root, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -40), Size = UDim2.fromOffset(0, 40), AutomaticSize = Enum.AutomaticSize.X })
	K.list(nav, "x", 14, "Center", "Center")
	K.key(nav, "Q", { LayoutOrder = 0 }); K.text(nav, "Tiers 20 – 27  of 60", "label", { LayoutOrder = 1, TextColor3 = T.muted }); K.key(nav, "E", { LayoutOrder = 2 })
	return g
end
