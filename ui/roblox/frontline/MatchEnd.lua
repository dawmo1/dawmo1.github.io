-- FRONTLINE / Match end: victory banner, MVP card with the player's avatar, scoreboard, XP breakdown, weapon level-up.
return function(K, parent: Instance, P: { [string]: any })
	K.use("frontline")
	local T = K.T
	local g, root = K.screen("FL_MatchEnd", parent)
	K.backdrop(root, { glow = T.accent2, glowAt = UDim2.fromScale(0.5, 0.15), glowSize = 2000, glowStrength = 0.8, floor = T.surface2 })

	local ban = K.new("Frame", root, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(960, 46), Size = UDim2.fromOffset(1000, 170) })
	K.text(ban, "VICTORY", "display", { TextSize = 110, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = T.accent2 })
	local sub = K.new("Frame", ban, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(500, 132), Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X })
	K.list(sub, "x", 14, "Center", "Center")
	K.text(sub, "DOMINATION  ·  DOCKYARD", "label", { LayoutOrder = 0, TextColor3 = T.text })
	K.text(sub, '<font color="#8FD6B4">200</font>  –  <font color="#E5484D">164</font>', "display", { TextSize = 22, LayoutOrder = 1 })
	K.text(sub, "11:42", "mono", { LayoutOrder = 2, TextSize = 14, TextColor3 = T.muted })

	-- MVP card
	local mvp = K.panel(root, { Position = UDim2.fromOffset(96, 250), Size = UDim2.fromOffset(460, 720), ClipsDescendants = true }, { alpha = 0.05, color = T.surface2, chamfer = 20, corners = "tl br", borderColor = T.accent, borderAlpha = 0.3 })
	local mg = K.new("Frame", mvp, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0, BackgroundColor3 = T.accent })
	K.grad(mg, { T.accent, T.accent }, 90, { 1, 0.78 })
	if P.viewport then P.viewport(K.new("Frame", mvp, { Size = UDim2.new(1, 0, 0, 540), Name = "AvatarHolder" })) else K.new("ImageLabel", mvp, { Image = P.fullbody or "", Position = UDim2.fromOffset(30, 40), Size = UDim2.fromOffset(400, 470), ScaleType = Enum.ScaleType.Fit }) end
	K.pill(mvp, "Match MVP", T.accent, { Position = UDim2.fromOffset(26, 26), ZIndex = 5 }, true)
	K.text(mvp, string.upper(P.name), "display", { TextSize = 36, Position = UDim2.fromOffset(26, 540), ZIndex = 5 })
	local ms = K.new("Frame", mvp, { Position = UDim2.fromOffset(26, 600), Size = UDim2.new(1, -52, 0, 80), ZIndex = 5 })
	K.list(ms, "x", 0)
	for i, s in { { "Kills", "27" }, { "Deaths", "9" }, { "Captures", "6" } } do
		local c = K.new("Frame", ms, { Size = UDim2.fromScale(1 / 3, 1), LayoutOrder = i })
		K.text(c, s[1], "label", { ZIndex = 5 })
		K.text(c, s[2], "display", { TextSize = 38, Position = UDim2.fromOffset(0, 22), ZIndex = 5 })
	end

	-- scoreboard
	local sb = K.panel(root, { Position = UDim2.fromOffset(584, 250), Size = UDim2.fromOffset(780, 720) }, { alpha = 0.2 })
	K.pad(sb, 22, 26)
	K.header(sb, "Scoreboard", { Size = UDim2.new(1, 0, 0, 22) }, "Your team")
	local hdr = K.new("Frame", sb, { Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 0, 24) })
	for _, c in { { "#", 0 }, { "Player", 40 }, { "Score", 380 }, { "K", 490 }, { "D", 550 }, { "A", 610 }, { "Obj", 670 } } do K.text(hdr, c[1], "label", { Position = UDim2.fromOffset(c[2], 0), TextSize = 11, TextColor3 = T.faint }) end
	local rows = K.new("Frame", sb, { Position = UDim2.fromOffset(0, 72), Size = UDim2.new(1, 0, 1, -72) })
	K.list(rows, "y", 3)
	local data = { { P.name, "4,920", 27, 9, 6, 6, true }, { "Ploopz", "3,810", 19, 12, 9, 4 }, { "turbo_tess", "3,355", 15, 10, 14, 5 }, { "R1V3R", "2,480", 12, 15, 6, 3 }, { "mxlo", "1,960", 9, 13, 7, 2 }, { "slowpoke", "1,105", 4, 16, 5, 1 } }
	for i, r in ipairs(data) do
		local me = r[7]
		local row = K.new("Frame", rows, { Size = UDim2.new(1, 0, 0, 64), BackgroundTransparency = me and 0.85 or (i % 2 == 0 and 0.96 or 1), BackgroundColor3 = me and T.accent or T.text, LayoutOrder = i })
		if me then K.new("Frame", row, { Size = UDim2.new(0, 3, 1, 0), BackgroundTransparency = 0, BackgroundColor3 = T.accent }) end
		K.text(row, tostring(i), "display", { TextSize = 18, Position = UDim2.fromOffset(10, 0), Size = UDim2.fromOffset(0, 64), TextColor3 = i == 1 and T.accent or T.muted })
		local av = K.new("Frame", row, { Position = UDim2.fromOffset(40, 14), Size = UDim2.fromOffset(36, 36), BackgroundTransparency = 0, BackgroundColor3 = T.raised })
		if me and P.thumb then K.new("ImageLabel", av, { Image = P.thumb, Size = UDim2.fromScale(1, 1) }) else K.icon(av, "user", 22, T.muted, { Position = UDim2.fromOffset(7, 7) }) end
		K.text(row, r[1], "body", { Position = UDim2.fromOffset(90, 0), Size = UDim2.fromOffset(0, 64), FontFace = me and T.bodyBold or T.body, TextSize = 18 })
		K.text(row, r[2], "mono", { Position = UDim2.fromOffset(380, 0), Size = UDim2.fromOffset(0, 64), TextSize = 16 })
		for j, x in { 490, 550, 610, 670 } do K.text(row, tostring(r[2 + j]), "mono", { Position = UDim2.fromOffset(x, 0), Size = UDim2.fromOffset(0, 64), TextSize = 16, TextColor3 = j == 2 and T.muted or T.text }) end
	end

	-- XP breakdown + unlocks
	local xp = K.panel(root, { Position = UDim2.fromOffset(1392, 250), Size = UDim2.fromOffset(432, 470) }, { alpha = 0.2, chamfer = 16, corners = "tr bl" })
	K.pad(xp, 22, 26)
	K.header(xp, "Experience", { Size = UDim2.new(1, 0, 0, 22) })
	local lines = K.new("Frame", xp, { Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 0, 230) })
	K.list(lines, "y", 4)
	for i, l in { { "Match complete", "+1,500" }, { "Victory", "+2,000" }, { "Objective play", "+1,240" }, { "Top of team", "+800" }, { "Double XP weekend", "×2" } } do
		local r = K.new("Frame", lines, { Size = UDim2.new(1, 0, 0, 40), LayoutOrder = i })
		K.text(r, l[1], "body", { Size = UDim2.fromOffset(0, 40), TextSize = 17 })
		K.text(r, l[2], "mono", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(0, 40), TextSize = 16, TextColor3 = i == 5 and T.accent or T.text })
	end
	K.new("Frame", xp, { Position = UDim2.fromOffset(0, 284), Size = UDim2.new(1, 0, 0, 1), BackgroundTransparency = 0.85, BackgroundColor3 = T.text })
	K.text(xp, "+11,080 XP", "display", { TextSize = 36, Position = UDim2.fromOffset(0, 300), TextColor3 = T.accent })
	K.text(xp, "Rank 47  →  48", "label", { Position = UDim2.fromOffset(0, 352), TextColor3 = T.text })
	K.bar(xp, { Size = UDim2.new(1, 0, 0, 8), Position = UDim2.fromOffset(0, 380) }, 0.22, T.accent, { round = false, preview = 1, previewColor = T.accent, ticks = 8 })
	local lv = K.panel(root, { Position = UDim2.fromOffset(1392, 740), Size = UDim2.fromOffset(432, 230), ClipsDescendants = true }, { alpha = 0.06, color = T.surface2, borderColor = K.RARITY.legendary[1], borderAlpha = 0.4 })
	K.pad(lv, 22, 26)
	K.pill(lv, "Weapon level up", K.RARITY.legendary[1], {}, true)
	K.art(lv, "revolver", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 20, 0.55, 0), Size = UDim2.fromOffset(240, 140) })
	K.text(lv, "MAGNUM .44", "title", { Position = UDim2.fromOffset(0, 44), TextSize = 24 })
	K.text(lv, 'Lv 30  →  <font color="#FFB524">31</font>', "mono", { Position = UDim2.fromOffset(0, 80), TextSize = 16 })
	K.text(lv, "Unlocked: Holosight X4", "small", { Position = UDim2.fromOffset(0, 120), TextColor3 = T.text })

	return g
end
