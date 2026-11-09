-- FRONTLINE / Daily rewards: 7-day login calendar as a modal over a dimmed menu, with streak and claim states.
return function(K, parent: Instance, P: { [string]: any })
	K.use("frontline")
	local T = K.T
	local g, root = K.screen("FL_DailyRewards", parent)
	K.backdrop(root, { glow = T.accent2, glowAt = UDim2.fromScale(0.5, 0.5), glowSize = 1700, glowStrength = 0.86 })
	K.new("Frame", root, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0.35, BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = -5 })

	local m = K.panel(root, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(1400, 720) }, { alpha = 0.02, color = T.surface, chamfer = 24, corners = "tl br", borderAlpha = 0.8 })
	local band = K.new("Frame", m, { Position = UDim2.fromOffset(-52, -44), Size = UDim2.new(1, 104, 0, 220), BackgroundTransparency = 0, BackgroundColor3 = T.accent2 }) -- offsets cancel the padding
	K.grad(band, { T.accent2, T.accent2 }, 90, { 0.82, 1 })
	K.pad(m, 44, 52)
	local close = K.panel(m, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(48, 48) }, { alpha = 0.3, sheen = false })
	K.icon(close, "x", 22, T.text, { Position = UDim2.fromOffset(13, 13) })
	K.icon(m, "calendar", 40, T.accent2, {})
	K.text(m, "DAILY SUPPLY DROP", "display", { TextSize = 46, Position = UDim2.fromOffset(60, -6) })
	K.text(m, "Log in each day to keep the streak. Miss a day and it drops back one step, not to zero.", "body", { Position = UDim2.fromOffset(0, 60), TextColor3 = T.muted, TextSize = 18 })
	local streak = K.new("Frame", m, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -70, 0, 0), Size = UDim2.fromOffset(0, 48), AutomaticSize = Enum.AutomaticSize.X })
	K.list(streak, "x", 10, "Right", "Center")
	K.icon(streak, "flame", 26, T.accent, { LayoutOrder = 0 })
	K.text(streak, '<font size="30">12</font>  DAY STREAK', "title", { TextSize = 16, LayoutOrder = 1 })

	local days = K.new("Frame", m, { Position = UDim2.fromOffset(0, 130), Size = UDim2.new(1, 0, 0, 380) })
	K.list(days, "x", 14)
	local list = {
		{ "coins", "1,500", "common", "claimed" }, { "ticket", "XP boost 30m", "uncommon", "claimed" }, { "coins", "3,000", "common", "claimed" },
		{ "grenade", "Frag  ×5", "rare", "today", true }, { "gem", "100 gems", "rare", "locked" }, { "box", "Supply crate", "epic", "locked" }, { "revolver", "Magnum skin", "legendary", "locked", true },
	}
	for i, d in list do
		local today, claimed, big = d[4] == "today", d[4] == "claimed", i == 7
		local r = K.RARITY[d[3]][1]
		local col = K.new("Frame", days, { Size = UDim2.fromOffset(big and 262 or 158, 380), LayoutOrder = i })
		K.text(col, "DAY " .. i, "label", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), TextColor3 = today and T.accent or T.muted, TextXAlignment = Enum.TextXAlignment.Center })
		local s = K.slot(col, { Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, today and 320 or 300) }, { rarity = d[3], selected = today })
		if today then
			K.stroke(s, T.accent, 3, 0)
			K.new("Frame", s, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0.88, BackgroundColor3 = T.accent })
		end
		if d[5] then K.art(s, d[1], { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromScale(0.86, 0.5), ZIndex = 3, ImageTransparency = claimed and 0.6 or 0 })
		else K.icon(s, d[1], 60, r, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4), ZIndex = 3, ImageTransparency = claimed and 0.6 or 0 }) end
		K.text(s, d[2], "title", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, -82), TextSize = 17, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3, TextTransparency = claimed and 0.5 or 0 })
		K.text(s, K.RARITY[d[3]][2], "label", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, -54), TextSize = 10, TextColor3 = r, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3 })
		if claimed then
			local tick = K.new("Frame", s, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.fromOffset(56, 56), BackgroundTransparency = 0, BackgroundColor3 = T.good, ZIndex = 6 })
			K.corner(tick, 999); K.icon(tick, "check", 32, T.bg, { Position = UDim2.fromOffset(12, 12), ZIndex = 7 })
		elseif d[4] == "locked" then
			K.text(s, i == 5 and "Tomorrow" or ("In " .. (i - 4) .. " days"), "label", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 14), TextSize = 10, TextColor3 = T.muted, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3 })
		end
		if big then K.pill(s, "Week bonus", K.RARITY.legendary[1], { Position = UDim2.fromOffset(12, 12), ZIndex = 4 }, true) end
	end

	local foot = K.new("Frame", m, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1), Size = UDim2.fromOffset(0, 64), AutomaticSize = Enum.AutomaticSize.X })
	K.list(foot, "x", 16, "Center", "Center")
	K.button(foot, "Claim day 4", "primary", { LayoutOrder = 0, Size = UDim2.fromOffset(320, 64) }, { icon = "gift", textSize = 22, under = T.surface })
	K.text(foot, "Next drop in  <b>14:22:07</b>", "body", { LayoutOrder = 1, TextColor3 = T.muted })
	return g
end
